[CmdletBinding()]
param(
    [string]$DriverCacheRoot = 'C:\OSDCloudFactory\Cache\Drivers\Lenovo',
    [string]$TargetWindowsPath = 'C:\Windows',
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Invoke-LenovoDriverApply'

try {
    $system = Get-CimInstance -ClassName Win32_ComputerSystem
    $csProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct
    if ($system.Manufacturer -notmatch 'Lenovo') {
        Write-FactoryLog "Manufacturer '$($system.Manufacturer)' is not Lenovo. Skipping Lenovo driver apply."
        return
    }

    $modelHints = @($system.Model, $csProduct.Version, $csProduct.Name) | Where-Object { $_ }
    Write-FactoryLog "Detected Lenovo model hints: $($modelHints -join ', ')"

    $manifests = Get-ChildItem -Path $DriverCacheRoot -Filter manifest.json -Recurse -ErrorAction SilentlyContinue
    $match = $null
    foreach ($manifestFile in $manifests) {
        $manifest = Get-Content -LiteralPath $manifestFile.FullName -Raw | ConvertFrom-Json
        foreach ($machineType in $manifest.MachineTypes) {
            if ($modelHints -match [regex]::Escape($machineType)) {
                $match = $manifest
                break
            }
        }
        if ($match) { break }
    }

    if (-not $match) {
        throw "No Lenovo driver pack manifest matched detected model hints: $($modelHints -join ', ')"
    }

    $packFile = [string]$match.File
    if (-not (Test-Path -LiteralPath $packFile)) {
        throw "Matched driver pack file is missing: $packFile"
    }

    $extractDir = Join-Path (Split-Path -Path $packFile -Parent) 'Extracted'
    Invoke-FactoryAction -Description "Extract and stage Lenovo drivers from '$packFile'." -DryRun:$DryRun -Action {
        New-Item -Path $extractDir -ItemType Directory -Force | Out-Null
        Start-Process -FilePath $packFile -ArgumentList "/VERYSILENT /DIR=`"$extractDir`"" -Wait -NoNewWindow
        $infRoot = if (Test-Path $extractDir) { $extractDir } else { Split-Path -Path $packFile -Parent }
        pnputil.exe /add-driver (Join-Path $infRoot '*.inf') /subdirs /install
    }
}
finally {
    Stop-FactoryTranscript
}
