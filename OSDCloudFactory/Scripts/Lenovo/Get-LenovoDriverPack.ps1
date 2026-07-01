[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ModelConfigPath,
    [string]$CacheRoot,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Get-LenovoDriverPack'

try {
    if (-not $CacheRoot) {
        $CacheRoot = Join-FactoryPath -Root $Root -ChildPath @('Cache', 'Drivers', 'Lenovo')
    }

    if (-not (Test-Path -LiteralPath $ModelConfigPath)) {
        throw "Model config not found: $ModelConfigPath"
    }

    $model = Get-Content -LiteralPath $ModelConfigPath -Raw | ConvertFrom-Json
    foreach ($name in @('Manufacturer', 'ModelName', 'MachineTypes', 'DriverPackUrl')) {
        if (-not $model.PSObject.Properties.Name.Contains($name)) {
            throw "Model config '$ModelConfigPath' is missing '$name'."
        }
    }

    if ($model.Manufacturer -notmatch 'Lenovo') {
        throw "This downloader only supports Lenovo model configs."
    }

    $targetDir = Join-Path $CacheRoot (($model.ModelName -replace '[^a-zA-Z0-9_.-]', '_'))
    $fileName = Split-Path -Path ([uri]$model.DriverPackUrl).AbsolutePath -Leaf
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = "$($model.ModelName)-driverpack.exe"
    }
    $targetFile = Join-Path $targetDir $fileName

    Invoke-FactoryAction -Description "Download Lenovo driver pack for $($model.ModelName) to '$targetFile'." -DryRun:$DryRun -Action {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        Invoke-WebRequest -Uri $model.DriverPackUrl -OutFile $targetFile -UseBasicParsing
        $manifest = [ordered]@{
            Manufacturer = $model.Manufacturer
            ModelName = $model.ModelName
            MachineTypes = $model.MachineTypes
            DriverPackUrl = $model.DriverPackUrl
            DownloadedAt = (Get-Date).ToString('o')
            File = $targetFile
        }
        Save-FactoryJson -InputObject $manifest -Path (Join-Path $targetDir 'manifest.json')
    }
}
finally {
    Stop-FactoryTranscript
}
