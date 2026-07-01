Set-StrictMode -Version 2.0

function Get-FactoryRoot {
    [CmdletBinding()]
    param(
        [string]$StartPath = $PSScriptRoot
    )

    $candidate = (Resolve-Path -LiteralPath $StartPath -ErrorAction Stop).Path
    while ($candidate) {
        $hasConfig = Test-Path -LiteralPath (Join-Path $candidate 'Config') -PathType Container
        $hasScripts = Test-Path -LiteralPath (Join-Path $candidate 'Scripts') -PathType Container
        if ($hasConfig -and $hasScripts) {
            return $candidate
        }

        $parent = Split-Path -Path $candidate -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $candidate) {
            break
        }
        $candidate = $parent
    }

    throw "Unable to locate OSDCloudFactory root from '$StartPath'."
}

function Join-FactoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [Parameter(Mandatory)]
        [string[]]$ChildPath
    )

    $path = $Root
    foreach ($child in $ChildPath) {
        $path = Join-Path -Path $path -ChildPath $child
    }
    return $path
}

function Write-FactoryLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DRYRUN')]
        [string]$Level = 'INFO'
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$stamp][$Level] $Message"
    switch ($Level) {
        'WARN' { Write-Warning $line }
        'ERROR' { Write-Error $line }
        default { Write-Host $line }
    }
}

function Start-FactoryTranscript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [Parameter(Mandatory)]
        [string]$Name
    )

    $logDir = Join-FactoryPath -Root $Root -ChildPath @('Logs')
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $safeName = $Name -replace '[^a-zA-Z0-9_.-]', '_'
    $path = Join-Path $logDir ("{0}-{1}.log" -f $safeName, (Get-Date -Format 'yyyyMMdd-HHmmss'))
    try {
        Start-Transcript -Path $path -Force -ErrorAction Stop | Out-Null
        Write-FactoryLog "Transcript started: $path"
    }
    catch {
        Write-FactoryLog "Unable to start transcript: $($_.Exception.Message)" -Level WARN
    }
    return $path
}

function Stop-FactoryTranscript {
    [CmdletBinding()]
    param()

    try {
        Stop-Transcript -ErrorAction Stop | Out-Null
    }
    catch {
        # Transcript may not be active in WinPE or constrained hosts.
    }
}

function Import-FactoryClientConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Client config not found: $Path"
    }

    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $required = @('ClientName', 'WorkspacePath', 'Windows', 'Autopilot', 'HybridJoin')
    foreach ($name in $required) {
        if (-not $config.PSObject.Properties.Name.Contains($name)) {
            throw "Client config '$Path' is missing required property '$name'."
        }
    }

    if ($config.Autopilot.PSObject.Properties.Name -contains 'TenantSecret') {
        throw "Config must not contain tenant secrets. Use interactive Graph authentication or managed identity outside this file."
    }

    return $config
}

function Assert-FactoryAdministrator {
    [CmdletBinding()]
    param()

    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "Run this script from an elevated PowerShell session."
        }
    }
}

function Assert-FactoryModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [switch]$Install,
        [string]$MinimumVersion
    )

    $module = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $module -and $Install) {
        Write-FactoryLog "Installing PowerShell module '$Name'."
        $params = @{ Name = $Name; Scope = 'CurrentUser'; Force = $true; AllowClobber = $true }
        if ($MinimumVersion) { $params.MinimumVersion = $MinimumVersion }
        Install-Module @params
        $module = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    }

    if (-not $module) {
        throw "Required PowerShell module '$Name' is not installed. Install it from PowerShell Gallery."
    }

    Import-Module $Name -Force
    return $module
}

function Invoke-FactoryAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Description,
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-FactoryLog $Description -Level DRYRUN
        return $null
    }

    Write-FactoryLog $Description
    try {
        return & $Action
    }
    catch {
        Write-FactoryLog $_.Exception.Message -Level ERROR
        throw
    }
}

function Test-FactoryCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Name
    )

    $missing = @()
    foreach ($commandName in $Name) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $missing += $commandName
        }
    }
    return $missing
}

function New-FactoryDirectorySet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [switch]$DryRun
    )

    $paths = @(
        'Config/clients',
        'Config/models',
        'Scripts/Build',
        'Scripts/Deploy',
        'Scripts/Intune',
        'Scripts/Lenovo',
        'Scripts/Reports',
        'Cache/OS',
        'Cache/Drivers',
        'Cache/Updates',
        'Logs'
    )

    foreach ($relative in $paths) {
        $target = Join-Path $Root $relative
        Invoke-FactoryAction -Description "Ensure directory exists: $target" -DryRun:$DryRun -Action {
            New-Item -Path $target -ItemType Directory -Force | Out-Null
        }
    }
}

function Save-FactoryJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$DryRun
    )

    Invoke-FactoryAction -Description "Write JSON file: $Path" -DryRun:$DryRun -Action {
        $parent = Split-Path -Path $Path -Parent
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -Path $parent -ItemType Directory -Force | Out-Null
        }
        $InputObject | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
    }
}

function Get-FactoryRecoverySteps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Area
    )

    switch ($Area) {
        'OSD' {
            @(
                'Run PowerShell as Administrator.',
                'Install or update the OSD module: Install-Module OSD -Scope CurrentUser -Force.',
                'Confirm Windows ADK and WinPE add-on are installed on build workstations when creating media.',
                'Run the script again with -DryRun to validate paths and parameters.'
            )
        }
        'USB' {
            @(
                'Disconnect non-target removable drives.',
                'Use Get-Disk to verify disk number, bus type, size, and friendly name.',
                'Rerun with -DiskNumber and confirm the typed safety prompt.'
            )
        }
        'Intune' {
            @(
                'Connect to Microsoft Graph with an account allowed to read Intune and Autopilot objects.',
                'Verify Intune Connector for AD health in Intune admin center.',
                'Confirm Autopilot deployment and domain join profiles are assigned to the target group.',
                'Check that the configured OU exists and delegated join permissions are in place.'
            )
        }
        default {
            @('Review the transcript under Logs and rerun with -Verbose or -DryRun.')
        }
    }
}

Export-ModuleMember -Function *
