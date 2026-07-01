[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Resolve-Path -LiteralPath $Root
$transcript = Start-FactoryTranscript -Root $Root -Name 'Initialize-OSDCloudFactory'

try {
    New-FactoryDirectorySet -Root $Root -DryRun:$DryRun
    Write-FactoryLog "Factory initialized at $Root"
}
finally {
    Stop-FactoryTranscript
}
