[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SerialNumber,
    [Parameter(Mandatory)]
    [string]$GroupTag,
    [switch]$InstallModules,
    [switch]$DryRun
)

Import-Module (Join-Path $PSScriptRoot '../OSDCloudFactory.Common.psm1') -Force
$Root = Get-FactoryRoot -StartPath $PSScriptRoot
$transcript = Start-FactoryTranscript -Root $Root -Name 'Set-AutopilotGroupTag'

try {
    Assert-FactoryModule -Name 'Microsoft.Graph.Authentication' -Install:$InstallModules | Out-Null
    Assert-FactoryModule -Name 'Microsoft.Graph.DeviceManagement.Enrollment' -Install:$InstallModules | Out-Null

    if (-not (Get-MgContext)) {
        Invoke-FactoryAction -Description "Connect to Microsoft Graph for Autopilot management." -DryRun:$DryRun -Action {
            Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.ReadWrite.All'
        }
    }

    Invoke-FactoryAction -Description "Assign Autopilot Group Tag '$GroupTag' to serial '$SerialNumber'." -DryRun:$DryRun -Action {
        $device = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq '$SerialNumber'" -ErrorAction Stop
        if (-not $device) {
            throw "Autopilot device with serial '$SerialNumber' was not found."
        }
        Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $device.Id -GroupTag $GroupTag
        Invoke-MgDeviceManagementWindowsAutopilotSettingSync
    }
}
finally {
    Stop-FactoryTranscript
}
