[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [switch]$InstallModules,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Test-HybridJoinReadiness'

try {
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    Assert-FactoryModule -Name 'Microsoft.Graph.Authentication' -Install:$InstallModules | Out-Null

    if (-not (Get-MgContext)) {
        Invoke-FactoryAction -Description "Connect to Microsoft Graph for Intune readiness checks." -DryRun:$DryRun -Action {
            Connect-MgGraph -Scopes @(
                'DeviceManagementConfiguration.Read.All',
                'DeviceManagementServiceConfig.Read.All',
                'Device.Read.All',
                'Group.Read.All'
            )
        }
    }

    $results = [ordered]@{
        ClientName = $config.ClientName
        CheckedAt = (Get-Date).ToString('o')
        IntuneConnectorForADInstalled = $false
        DomainJoinProfileExists = $false
        OUPathConfigured = -not [string]::IsNullOrWhiteSpace([string]$config.HybridJoin.OUPath)
        AutopilotDeploymentProfileAssigned = $false
        DeviceSyncStatusVisible = $false
        Notes = @()
    }

    Invoke-FactoryAction -Description "Run hybrid join readiness checks for $($config.ClientName)." -DryRun:$DryRun -Action {
        $connectors = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/domainJoinConnectors'
        $results.IntuneConnectorForADInstalled = @($connectors.value).Count -gt 0
        if (-not $results.IntuneConnectorForADInstalled) {
            $results.Notes += 'No Intune Connector for AD domainJoinConnector object was visible to this Graph session.'
        }

        $configs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations'
        $domainJoinName = [string]$config.HybridJoin.DomainJoinProfileName
        $domainJoin = @($configs.value) | Where-Object {
            $_.'@odata.type' -match 'DomainJoin' -and $_.displayName -eq $domainJoinName
        }
        $results.DomainJoinProfileExists = [bool]$domainJoin

        $profiles = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles'
        $profileName = [string]$config.Autopilot.DeploymentProfileName
        $profile = @($profiles.value) | Where-Object { $_.displayName -eq $profileName } | Select-Object -First 1
        if ($profile) {
            $assignments = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/$($profile.id)/assignments"
            $results.AutopilotDeploymentProfileAssigned = @($assignments.value).Count -gt 0
        }

        $sync = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotSettings'
        $results.DeviceSyncStatusVisible = [bool]$sync

        $reportPath = Join-FactoryPath -Root $Root -ChildPath @('Logs', "HybridJoinReadiness-$($config.ClientName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').json")
        Save-FactoryJson -InputObject $results -Path $reportPath
        $results
    }
}
catch {
    Write-FactoryLog "Hybrid join readiness check failed. Recovery: $((Get-FactoryRecoverySteps -Area Intune) -join ' ')" -Level ERROR
    throw
}
finally {
    Stop-FactoryTranscript
}
