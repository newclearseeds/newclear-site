# OSDCloudFactory

PowerShell toolkit for MSP/client Windows 11 deployment media based on official OSD/OSDCloud tooling. It keeps client-specific values in JSON, caches Windows and Lenovo content, prepares Autopilot/hybrid join checks, and uses dry-run plus transcript logging for repeatable operation.

## Layout

```text
OSDCloudFactory/
  Config/
    clients/
    models/
  Scripts/
    Build/
    Deploy/
    Intune/
    Lenovo/
    Reports/
  Cache/
    OS/
    Drivers/
    Updates/
  Logs/
```

## Prerequisites

- Windows build workstation for media creation.
- PowerShell 7 for build and Intune administration scripts.
- Windows PowerShell support for WinPE deployment scripts where PowerShell 7 is not available.
- Windows ADK and Windows PE add-on installed on the build workstation.
- Official OSD PowerShell module from PowerShell Gallery.
- Microsoft Graph PowerShell modules for Intune checks.
- No tenant secrets in JSON. Use interactive Graph login, managed identity, or your MSP secret vault outside this repository.

Install the core module:

```powershell
Install-Module OSD -Scope CurrentUser -Force
```

Optional Intune modules:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module Microsoft.Graph.DeviceManagement.Enrollment -Scope CurrentUser -Force
```

## Quick Start

Copy `Config/clients/example-client.json` for each client and update:

- `WorkspacePath`
- Windows edition, language, and license
- Autopilot group tag and deployment profile name
- Hybrid join domain join profile name and OU path
- Optional SetupComplete source path

Then run from an elevated PowerShell session:

```powershell
pwsh
cd C:\OSDCloudFactory
.\Scripts\Build\Initialize-OSDCloudFactory.ps1
.\Scripts\Build\Update-OSDCloudWorkspace.ps1 -ClientConfigPath .\Config\clients\contoso.json
.\Scripts\Build\Cache-WindowsImage.ps1 -ClientConfigPath .\Config\clients\contoso.json
.\Scripts\Build\Build-OSDCloudMedia.ps1 -ClientConfigPath .\Config\clients\contoso.json -MediaType ISO
```

Use dry-run first when changing a client or build host:

```powershell
.\Scripts\OSDCloudFactory.Menu.ps1 -ClientConfigPath .\Config\clients\contoso.json -DryRun
```

## Lenovo Driver Packs

Create one model JSON per Lenovo model in `Config/models`. Use Lenovo's current SCCM/Enterprise driver pack URL for the exact machine type.

```powershell
.\Scripts\Lenovo\Get-LenovoDriverPack.ps1 -ModelConfigPath .\Config\models\thinkpad-t14-gen5.json
```

During deployment, `Invoke-LenovoDriverApply.ps1` detects Lenovo model hints from WMI/CIM and matches them against cached manifests. Matching drivers are extracted and staged with `pnputil`.

## USB Safety

USB builds require an explicit disk number and typed confirmation. The script refuses boot/system disks and can require `BusType = USB`.

```powershell
Get-Disk
.\Scripts\Build\Build-OSDCloudMedia.ps1 -ClientConfigPath .\Config\clients\contoso.json -MediaType USB -DiskNumber 3
```

You must type:

```text
WIPE DISK 3
```

## Autopilot and Hybrid Join

Capture hardware hash:

```powershell
.\Scripts\Intune\Get-AutopilotHardwareHash.ps1 -GroupTag CONTOSO-LENOVO-HYBRID -InstallScript
```

Assign or update Group Tag after import:

```powershell
.\Scripts\Intune\Set-AutopilotGroupTag.ps1 -SerialNumber PF123ABC -GroupTag CONTOSO-LENOVO-HYBRID
```

Run readiness checks:

```powershell
.\Scripts\Intune\Test-HybridJoinReadiness.ps1 -ClientConfigPath .\Config\clients\contoso.json
```

The readiness check verifies visible signals for:

- Intune Connector for AD
- Domain Join profile
- OU path configured in JSON
- Autopilot deployment profile assignment
- Autopilot sync status visibility

The Graph checks use Microsoft Graph beta resources for Intune domain join connectors and Autopilot deployment profile assignments. Recheck Microsoft Learn before production hardening because beta Graph APIs can change.

## Example Lenovo ThinkPad Flow

1. Copy `example-client.json` to `contoso.json` and set Group Tag to `CONTOSO-LENOVO-HYBRID`.
2. Create `thinkpad-t14-gen5.json` with the current Lenovo driver pack URL and machine types such as `21ML` and `21MM`.
3. Run the Lenovo cache script for that model.
4. Update the OSDCloud workspace and cache the Windows 11 image.
5. Build ISO first and test in a lab VM.
6. Build USB only after `Get-Disk` confirms the removable target.
7. Boot ThinkPad from OSDCloud media.
8. Start deployment with Lenovo driver apply and hardware hash capture.
9. Import hardware hash into Autopilot or assign the Group Tag to an existing imported device.
10. Confirm the device receives the hybrid Autopilot deployment profile and domain join profile before production rollout.

## Reports and Logs

Every script starts a transcript under `Logs` where the host supports transcripts. Generate a summary report:

```powershell
.\Scripts\Reports\New-DeploymentReport.ps1 -ClientConfigPath .\Config\clients\contoso.json
```

## Recovery Pattern

Most scripts support `-DryRun`. When a step fails:

1. Open the latest transcript in `Logs`.
2. Fix the failed prerequisite or config value.
3. Rerun the same script with `-DryRun`.
4. Rerun without `-DryRun`.

See `TROUBLESHOOTING.md` for common issues.
