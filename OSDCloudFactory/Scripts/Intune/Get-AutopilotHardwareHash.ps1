[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../../Logs'),
    [string]$GroupTag,
    [switch]$InstallScript,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Get-AutopilotHardwareHash'

try {
    $scriptCommand = Get-Command -Name 'Get-WindowsAutopilotInfo.ps1' -ErrorAction SilentlyContinue
    if (-not $scriptCommand -and $InstallScript) {
        Invoke-FactoryAction -Description "Install Get-WindowsAutopilotInfo script from PowerShell Gallery." -DryRun:$DryRun -Action {
            Install-Script -Name Get-WindowsAutopilotInfo -Scope CurrentUser -Force
        }
        $scriptCommand = Get-Command -Name 'Get-WindowsAutopilotInfo.ps1' -ErrorAction SilentlyContinue
    }

    if (-not $scriptCommand -and -not $DryRun) {
        throw "Get-WindowsAutopilotInfo.ps1 was not found. Rerun with -InstallScript or install it manually."
    }

    $serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
    $file = Join-Path $OutputDirectory ("AutopilotHWID-{0}-{1}.csv" -f ($serial -replace '[^a-zA-Z0-9_.-]', '_'), (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $args = @('-OutputFile', $file)
    if ($GroupTag) {
        $args += @('-GroupTag', $GroupTag)
    }

    Invoke-FactoryAction -Description "Capture Autopilot hardware hash to '$file'." -DryRun:$DryRun -Action {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        & $scriptCommand.Source @args
    }
}
finally {
    Stop-FactoryTranscript
}
