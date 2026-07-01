[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [switch]$InstallModules,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Cache-WindowsImage'

try {
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    Assert-FactoryModule -Name 'OSD' -Install:$InstallModules | Out-Null

    $missing = Test-FactoryCommand -Name @('Get-OSDCloudOperatingSystems', 'Save-OSDCloudOperatingSystem')
    if ($missing.Count -gt 0) {
        throw "OSD module is missing expected command(s): $($missing -join ', ')"
    }

    $osCache = Join-FactoryPath -Root $Root -ChildPath @('Cache', 'OS')
    $windows = $config.Windows
    $osParams = @{
        OSVersion = [string]$windows.Version
        OSEdition = [string]$windows.Edition
        OSLanguage = [string]$windows.Language
        OSLicense = [string]$windows.License
    }
    if ($windows.Build -and $windows.Build -ne 'Latest') {
        $osParams.OSBuild = [string]$windows.Build
    }

    Invoke-FactoryAction -Description "Cache Windows image into '$osCache'." -DryRun:$DryRun -Action {
        New-Item -Path $osCache -ItemType Directory -Force | Out-Null
        $available = Get-OSDCloudOperatingSystems @osParams
        if (-not $available) {
            throw "No matching Windows image found for requested config."
        }
        $selected = $available | Sort-Object ReleaseDate -Descending | Select-Object -First 1
        $selected | Save-OSDCloudOperatingSystem -DownloadPath $osCache
    }
}
catch {
    Write-FactoryLog "Windows cache failed. Recovery: $((Get-FactoryRecoverySteps -Area OSD) -join ' ')" -Level ERROR
    throw
}
finally {
    Stop-FactoryTranscript
}
