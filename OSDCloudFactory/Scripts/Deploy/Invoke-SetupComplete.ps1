[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceDirectory,
    [string]$TargetWindowsPath = 'C:\Windows',
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Invoke-SetupComplete'

try {
    if (-not (Test-Path -LiteralPath $SourceDirectory -PathType Container)) {
        throw "SetupComplete source directory not found: $SourceDirectory"
    }

    $target = Join-Path $TargetWindowsPath 'Setup\Scripts'
    Invoke-FactoryAction -Description "Copy SetupComplete scripts to '$target'." -DryRun:$DryRun -Action {
        New-Item -Path $target -ItemType Directory -Force | Out-Null
        Copy-Item -Path (Join-Path $SourceDirectory '*') -Destination $target -Recurse -Force
    }
}
finally {
    Stop-FactoryTranscript
}
