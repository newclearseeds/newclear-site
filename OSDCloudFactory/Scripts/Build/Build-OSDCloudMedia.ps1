[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [ValidateSet('ISO', 'USB')]
    [string]$MediaType = 'ISO',
    [int]$DiskNumber = -1,
    [switch]$InstallModules,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
. (Join-Path $PSScriptRoot '../Deploy/Confirm-SafeDisk.ps1')

$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Build-OSDCloudMedia'

try {
    Assert-FactoryAdministrator
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    Assert-FactoryModule -Name 'OSD' -Install:$InstallModules | Out-Null

    $workspace = [string]$config.WorkspacePath
    if (-not (Test-Path -LiteralPath $workspace) -and -not $DryRun) {
        throw "OSDCloud workspace does not exist: $workspace. Run Update-OSDCloudWorkspace.ps1 first."
    }

    $commonCommands = @('Edit-OSDCloudWinPE')
    $mediaCommand = if ($MediaType -eq 'ISO') { 'New-OSDCloudISO' } else { 'New-OSDCloudUSB' }
    $missing = Test-FactoryCommand -Name ($commonCommands + $mediaCommand)
    if ($missing.Count -gt 0) {
        throw "OSD module is missing expected command(s): $($missing -join ', ')"
    }

    Invoke-FactoryAction -Description "Validate workspace before writing $MediaType media." -DryRun:$DryRun -Action {
        $required = @('Media', 'OS')
        foreach ($child in $required) {
            $path = Join-Path $workspace $child
            if (-not (Test-Path -LiteralPath $path)) {
                Write-FactoryLog "Workspace path not found yet: $path" -Level WARN
            }
        }
    }

    if ($MediaType -eq 'ISO') {
        Invoke-FactoryAction -Description "Build bootable OSDCloud ISO from '$workspace'." -DryRun:$DryRun -Action {
            New-OSDCloudISO -WorkspacePath $workspace
        }
    }
    else {
        if ($DiskNumber -lt 0) {
            throw "USB media requires -DiskNumber. Use Get-Disk and verify the target first."
        }
        Confirm-SafeDisk -DiskNumber $DiskNumber -ExpectedBusType 'USB' -RequireTypedConfirmation -DryRun:$DryRun
        Invoke-FactoryAction -Description "Build bootable OSDCloud USB on disk $DiskNumber." -DryRun:$DryRun -Action {
            New-OSDCloudUSB -WorkspacePath $workspace -DiskNumber $DiskNumber
        }
    }
}
catch {
    Write-FactoryLog "Media build failed. Recovery: $((Get-FactoryRecoverySteps -Area USB) -join ' ')" -Level ERROR
    throw
}
finally {
    Stop-FactoryTranscript
}
