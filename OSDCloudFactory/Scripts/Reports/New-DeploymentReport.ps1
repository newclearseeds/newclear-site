[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [string]$OutputPath,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'New-DeploymentReport'

try {
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    if (-not $OutputPath) {
        $OutputPath = Join-FactoryPath -Root $Root -ChildPath @('Logs', "DeploymentSummary-$($config.ClientName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').md")
    }

    $logs = Get-ChildItem -Path (Join-FactoryPath -Root $Root -ChildPath @('Logs')) -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 20

    $content = @(
        "# Deployment Summary - $($config.ClientName)",
        '',
        "- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
        "- Windows: $($config.Windows.Version) $($config.Windows.Build) $($config.Windows.Edition) $($config.Windows.Language)",
        "- Autopilot Group Tag: $($config.Autopilot.GroupTag)",
        "- Autopilot Profile: $($config.Autopilot.DeploymentProfileName)",
        "- Domain Join Profile: $($config.HybridJoin.DomainJoinProfileName)",
        "- OU Path: $($config.HybridJoin.OUPath)",
        '',
        "## Recent Logs",
        ''
    )

    foreach ($log in $logs) {
        $content += "- $($log.Name) ($($log.LastWriteTime))"
    }

    Invoke-FactoryAction -Description "Write deployment report to '$OutputPath'." -DryRun:$DryRun -Action {
        $parent = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -Path $parent -ItemType Directory -Force | Out-Null
        }
        $content | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    }
}
finally {
    Stop-FactoryTranscript
}
