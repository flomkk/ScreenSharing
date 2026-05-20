<div align="center">

# ScreenSharing

**A collection of PowerShell scripts for FiveM server admins to run during screen sharing sessions.**  
Covers everything from detecting screen recorders and inspecting hardware to reading Windows Defender logs and clearing FiveM cache.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows)

</div>

---

## About

This repo is a toolkit built around the `ScreenSharingAssistant.ps1` launcher, which lets you run any of the included scripts remotely without needing to download them manually. Scripts are fetched directly from GitHub at runtime, so they are always up to date.

All scripts require administrator privileges.

---

## Scripts

| Script | Description |
|---|---|
| `ScreenSharingAssistant.ps1` | Interactive menu launcher - run any script individually, in combination, or all at once |
| `CheckScreenRecording.ps1` | Scans running processes for known screen recording software (OBS, Medal, ShadowPlay, Bandicam, Fraps, XSplit, and more) |
| `CHHViewer.ps1` | Displays CHH-related data for analysis during a session |
| `PCIEDeviceView.ps1` | Lists PCIe devices connected to the system |
| `WinDefEvt.ps1` | Pulls and displays recent Windows Defender event log entries |
| `WinSerialsCheck.ps1` | Retrieves system, BIOS, and hardware serial numbers |
| `analyse_starter.ps1` | Starter script that kicks off a broader system analysis |
| `clean_fivem_cache.ps1` | Clears FiveM cache directories |

---

## Usage

**Recommended - run the assistant launcher directly from PowerShell (no download needed):**

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/flomkk/ScreenSharing/main/ScreenSharingAssistant.ps1)
```

The assistant menu lets you:

- Run a single script by number
- Run multiple scripts at once (e.g. `1,3,5`)
- Run all scripts with `A`

**Alternatively, run any individual script the same way:**

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/flomkk/ScreenSharing/main/CheckScreenRecording.ps1)
```

Just swap `CheckScreenRecording.ps1` for whichever script you want.

---

## Requirements

- Windows 10 / 11
- PowerShell 5.1 or newer (included with Windows by default)
- Administrator privileges (the assistant will warn and exit if not elevated)

---

## Contributing

Pull requests are welcome. If something is broken or you want a new script added, open an issue.
