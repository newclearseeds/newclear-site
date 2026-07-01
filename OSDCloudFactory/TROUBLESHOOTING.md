# Troubleshooting

## OSD module command not found

Install or update the official module:

```powershell
Install-Module OSD -Scope CurrentUser -Force
Import-Module OSD -Force
```

If commands still differ, inspect available commands:

```powershell
Get-Command -Module OSD | Sort-Object Name
```

## ISO or USB build fails

- Run PowerShell as Administrator.
- Confirm Windows ADK and WinPE add-on are installed.
- Run `Update-OSDCloudWorkspace.ps1` before media build.
- Use `-DryRun` to validate paths and parameters.
- For USB, disconnect unrelated removable drives and verify `Get-Disk`.

## Windows image cache fails

- Confirm internet access to Microsoft endpoints.
- Confirm the requested Windows edition/language/license exists.
- Use `"Build": "Latest"` in JSON unless you intentionally pin a release.
- Update the OSD module if `Get-OSDCloudOperatingSystems` or `Save-OSDCloudOperatingSystem` is unavailable.

## Lenovo driver pack does not match

- Confirm the model JSON contains Lenovo machine types, not only marketing names.
- Compare WMI values from the target:

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model
Get-CimInstance Win32_ComputerSystemProduct | Select-Object Name, Version
```

- Confirm the cached driver pack has a `manifest.json`.
- Replace the example Lenovo URL with the current Lenovo Enterprise/SCCM driver pack URL.

## Autopilot hardware hash capture fails

- Install the script with:

```powershell
Install-Script Get-WindowsAutopilotInfo -Scope CurrentUser -Force
```

- In WinPE, make sure networking is initialized.
- If uploading directly is blocked, capture CSV locally and import from Intune admin center later.

## Hybrid join readiness check fails

- Connect to Graph with an account that can read Intune configuration and Autopilot service config.
- Confirm the Intune Connector for AD is installed and healthy in Intune admin center.
- Confirm the OU path in JSON exists.
- Confirm delegated OU permissions allow computer object creation.
- Confirm the Autopilot deployment profile and Domain Join profile are assigned to the target group.
- Run an Autopilot device sync after import or Group Tag changes.

## SetupComplete does not run

- Confirm files are copied to `C:\Windows\Setup\Scripts`.
- Confirm the main file is named `SetupComplete.cmd`.
- Avoid interactive prompts in SetupComplete.
- Log actions from SetupComplete to a local file such as `C:\Windows\Temp\SetupComplete.log`.
