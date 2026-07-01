[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ClientConfigPath,
    [switch]$InstallModules,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Update-OSDCloudWorkspace'

try {
    Assert-FactoryAdministrator
    $config = Import-FactoryClientConfig -Path $ClientConfigPath
    Assert-FactoryModule -Name 'OSD' -Install:$InstallModules | Out-Null

    $missing = Test-FactoryCommand -Name @('New-OSDCloudTemplate', 'New-OSDCloudWorkspace', 'Edit-OSDCloudWinPE')
    if ($missing.Count -gt 0) {
        throw "OSD module is missing expected command(s): $($missing -join ', ')"
    }

    $workspace = [string]$config.WorkspacePath
    $templateName = if ($config.WorkspaceTemplateName) { [string]$config.WorkspaceTemplateName } else { "$($config.ClientName)-Win11" }

    Invoke-FactoryAction -Description "Create or update OSDCloud template '$templateName'." -DryRun:$DryRun -Action {
        if (-not (Test-Path -LiteralPath $workspace)) {
            New-OSDCloudTemplate -Name $templateName | Out-Null
            New-OSDCloudWorkspace -WorkspacePath $workspace | Out-Null
        }
        else {
            New-OSDCloudWorkspace -WorkspacePath $workspace | Out-Null
        }
    }

    $editParams = @{
        WorkspacePath = $workspace
        StartOSDCloudGUI = [bool]$config.Media.StartOSDCloudGUI
    }
    if ($config.Media.CloudDrivers) {
        $editParams.CloudDriver = $config.Media.CloudDrivers
    }

    Invoke-FactoryAction -Description "Update WinPE content for workspace '$workspace'." -DryRun:$DryRun -Action {
        Edit-OSDCloudWinPE @editParams
    }
}
catch {
    Write-FactoryLog "Workspace update failed. Recovery: $((Get-FactoryRecoverySteps -Area OSD) -join ' ')" -Level ERROR
    throw
}
finally {
    Stop-FactoryTranscript
}
