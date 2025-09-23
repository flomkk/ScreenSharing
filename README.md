# 📺 FiveM, alt:V and RAGE:MP Screensharing Scripts

[![PowerShell](https://img.shields.io/badge/PowerShell-5%2B-blue.svg)](https://learn.microsoft.com/en-us/powershell/)  
A curated collection of **Windows PowerShell scripts** for **system analysis, monitoring, and utilities**.  
These scripts provide lightweight solutions for inspecting hardware, analyzing logs, verifying configurations, and cleaning caches.

---

## 📑 Table of Contents

- [📂 Repository Overview](#-repository-overview)
- [⚙️ Requirements](#️-requirements)
- [🚀 Installation](#-installation)
- [▶️ Usage Examples](#️-usage-examples)
- [🔒 Security Considerations](#-security-considerations)
- [👤 Author](#-author)

---

## 📂 Repository Overview

| Script                     | Description                                                                 |
|-----------------------------|-----------------------------------------------------------------------------|
| **CHHViewer.ps1**           | View or analyze CHH-related logs or datasets                               |
| **CheckScreenRecording.ps1**| Detect whether screen recording is active or allowed                       |
| **PCIEDeviceView.ps1**      | List and display PCIe device information                                   |
| **WinDefEvt.ps1**           | Extract and analyze Windows Defender event logs                            |
| **WinSerialsCheck.ps1**     | Retrieve system, BIOS, and hardware serial numbers                         |
| **analyse_starter.ps1**     | Launcher for analysis-related scripts                                      |
| **clean_fivem_cache.ps1**   | Clear cached data for FiveM (GTA V multiplayer/modding utility)            |

> ⚠️ *Descriptions are inferred from file names. Please check the script source for full details and supported parameters.*

---

## ⚙️ Requirements

- **Operating System:** Windows 10 / Windows 11 / Windows Server  
- **PowerShell:** Version 5.1 or later (PowerShell 7+ recommended)  
- Some scripts require **Administrator privileges**  

---

## ▶️ Usage Examples

Run directly from command line:

```powershell
# Example: Run CheckScreenRecording.ps1
endlocal & powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/CheckScreenRecording.ps1)
```
- Swap the `CheckScreenRecording.ps1` to your desired script name from my repository.

> 💡 Check the `param(...)` block or comments inside each script for supported arguments.

---

## 🔒 Security Considerations

- Scripts execute with the current user's privileges  
- Always **review scripts before running**  
- Be mindful of outputs that may expose sensitive data (e.g., serial numbers, event logs)  

---

## 👤 Author

Maintained by **[flomkk](https://github.com/flomkk/)**  
💬 For issues or suggestions, please open an [issue here](https://github.com/flomkk/ScreenSharing/issues).  
