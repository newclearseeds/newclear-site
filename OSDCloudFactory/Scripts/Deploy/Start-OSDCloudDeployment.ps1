[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [switch]$ApplyLenovoDrivers,
    [switch]$CaptureHardwareHash,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Start-OSDCloudDeployment'

try {
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    Assert-FactoryModule -Name 'OSD' | Out-Null
    $missing = Test-FactoryCommand -Name @('Start-OSDCloud')
    if ($missing.Count -gt 0) {
        throw "OSD module is missing Start-OSDCloud."
    }

    $params = @{
        OSVersion = [string]$config.Windows.Version
        OSEdition = [string]$config.Windows.Edition
        OSLanguage = [string]$config.Windows.Language
        OSLicense = [string]$config.Windows.License
        ZTI = $true
    }
    if ($config.Windows.Build -and $config.Windows.Build -ne 'Latest') {
        $params.OSBuild = [string]$config.Windows.Build
    }

    Invoke-FactoryAction -Description "Start OSDCloud deployment for $($config.ClientName)." -DryRun:$DryRun -Action {
        Start-OSDCloud @params
    }

    if ($ApplyLenovoDrivers) {
        & (Join-Path $PSScriptRoot 'Invoke-LenovoDriverApply.ps1') -DryRun:$DryRun
    }

    if ($config.SetupComplete.Enabled -and $config.SetupComplete.SourceDirectory) {
        & (Join-Path $PSScriptRoot 'Invoke-SetupComplete.ps1') -SourceDirectory $config.SetupComplete.SourceDirectory -DryRun:$DryRun
    }

    if ($CaptureHardwareHash) {
        & (Join-Path $PSScriptRoot '../Intune/Get-AutopilotHardwareHash.ps1') -OutputDirectory (Join-FactoryPath -Root $Root -ChildPath @('Logs')) -GroupTag $config.Autopilot.GroupTag -DryRun:$DryRun
    }
}
catch {
    Write-FactoryLog "Deployment failed. Review the transcript and rerun the failed stage after correcting the cause." -Level ERROR
    throw
}
finally {
    Stop-FactoryTranscript
}
