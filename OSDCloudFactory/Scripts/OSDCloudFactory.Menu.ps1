[CmdletBinding()]
param(
    [string]$ClientConfigPath = (Join-Path $PSScriptRoot '../Config/clients/example-client.json'),
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot 'OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot

function Invoke-MenuItem {
    param([string]$Script, [string[]]$Arguments)

    $path = Join-Path $PSScriptRoot $Script
    & $path @Arguments
}

do {
    Clear-Host
    Write-Host 'OSDCloudFactory'
    Write-Host '==============='
    Write-Host "Client config: $ClientConfigPath"
    Write-Host "Dry run:       $DryRun"
    Write-Host ''
    Write-Host '1. Initialize folder structure'
    Write-Host '2. Create/update OSDCloud workspace'
    Write-Host '3. Cache Windows 11 image'
    Write-Host '4. Cache Lenovo driver pack from model JSON'
    Write-Host '5. Preload Windows updates'
    Write-Host '6. Build ISO media'
    Write-Host '7. Build USB media'
    Write-Host '8. Test hybrid join readiness'
    Write-Host '9. Capture Autopilot hardware hash'
    Write-Host '10. Generate deployment report'
    Write-Host 'Q. Quit'
    Write-Host ''
    $choice = Read-Host 'Select an option'

    $dry = if ($DryRun) { @('-DryRun') } else { @() }
    switch ($choice) {
        '1' { Invoke-MenuItem -Script 'Build/Initialize-OSDCloudFactory.ps1' -Arguments $dry }
        '2' { Invoke-MenuItem -Script 'Build/Update-OSDCloudWorkspace.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath) + $dry) }
        '3' { Invoke-MenuItem -Script 'Build/Cache-WindowsImage.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath) + $dry) }
        '4' {
            $modelPath = Read-Host 'Model JSON path'
            Invoke-MenuItem -Script 'Lenovo/Get-LenovoDriverPack.ps1' -Arguments (@('-ModelConfigPath', $modelPath) + $dry)
        }
        '5' { Invoke-MenuItem -Script 'Build/Preload-WindowsUpdates.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath) + $dry) }
        '6' { Invoke-MenuItem -Script 'Build/Build-OSDCloudMedia.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath, '-MediaType', 'ISO') + $dry) }
        '7' {
            Get-Disk | Format-Table -AutoSize
            $diskNumber = Read-Host 'Target USB disk number'
            Invoke-MenuItem -Script 'Build/Build-OSDCloudMedia.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath, '-MediaType', 'USB', '-DiskNumber', $diskNumber) + $dry)
        }
        '8' { Invoke-MenuItem -Script 'Intune/Test-HybridJoinReadiness.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath) + $dry) }
        '9' {
            $config = Import-FactoryClientConfig -Path $ClientConfigPath
            Invoke-MenuItem -Script 'Intune/Get-AutopilotHardwareHash.ps1' -Arguments (@('-GroupTag', $config.Autopilot.GroupTag) + $dry)
        }
        '10' { Invoke-MenuItem -Script 'Reports/New-DeploymentReport.ps1' -Arguments (@('-ClientConfigPath', $ClientConfigPath) + $dry) }
        { $_ -match '^[qQ]$' } { break }
        default { Write-Warning 'Unknown option.' }
    }

    if ($choice -notmatch '^[qQ]$') {
        Read-Host 'Press Enter to continue'
    }
} while ($true)
