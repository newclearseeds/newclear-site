[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [switch]$InstallModules,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Preload-WindowsUpdates'

try {
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    Assert-FactoryModule -Name 'OSD' -Install:$InstallModules | Out-Null

    $updatesCache = Join-FactoryPath -Root $Root -ChildPath @('Cache', 'Updates')
    $missing = Test-FactoryCommand -Name @('Save-OSDCloudUpdate')
    if ($missing.Count -gt 0) {
        Write-FactoryLog "Save-OSDCloudUpdate is unavailable in this OSD module version. Update preloading will be skipped." -Level WARN
        return
    }

    Invoke-FactoryAction -Description "Preload supported Windows updates into '$updatesCache'." -DryRun:$DryRun -Action {
        New-Item -Path $updatesCache -ItemType Directory -Force | Out-Null
        Save-OSDCloudUpdate -OSVersion $config.Windows.Version -OSBuild $config.Windows.Build -DownloadPath $updatesCache
    }
}
finally {
    Stop-FactoryTranscript
}
