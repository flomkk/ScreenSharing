$host.ui.RawUI.WindowTitle = "DMA Scanner - Made by flomkk"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

Write-Host ""
Write-Host -ForegroundColor Magenta @"
   ██████╗ ███╗   ███╗ █████╗     ███████╗ ██████╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██████╗
   ██╔══██╗████╗ ████║██╔══██╗    ██╔════╝██╔════╝██╔══██╗████╗  ██║████╗  ██║██╔════╝██╔══██╗
   ██║  ██║██╔████╔██║███████║    ███████╗██║     ███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
   ██║  ██║██║╚██╔╝██║██╔══██║    ╚════██║██║     ██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
   ██████╔╝██║ ╚═╝ ██║██║  ██║    ███████║╚██████╗██║  ██║██║ ╚████║██║ ╚████║███████╗██║  ██║
   ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
"@
Write-Host "                               Made by flomkk - " -NoNewline -ForegroundColor White
Write-Host "github.com/flomkk" -ForegroundColor Magenta
Write-Host ""
 
$findings = [System.Collections.Generic.List[string]]::new()
 
function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "   $Text" -ForegroundColor Cyan
    Write-Host "   $("=" * 80)" -ForegroundColor DarkGray
}
 
function Write-Result {
    param([string]$Label, [bool]$Suspicious, [string]$Value)
    Write-Host "   $($Label.PadRight(35))" -NoNewline -ForegroundColor White
    if ($Suspicious) {
        Write-Host $Value -ForegroundColor Red
    } else {
        Write-Host $Value -ForegroundColor Green
    }
}
 
function Add-Finding {
    param([string]$Msg)
    $findings.Add($Msg)
}
 
# ===========================================================================
# HARDWARE
# ===========================================================================
Write-Section "HARDWARE"
 
$mb   = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue
$bios = Get-CimInstance -ClassName Win32_BIOS      -ErrorAction SilentlyContinue
$cpu  = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
 
Write-Result "Mainboard"            $false "$($mb.Manufacturer) $($mb.Product) $($mb.Version)"
Write-Result "BIOS"                 $false "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate.ToString('yyyy-MM-dd')))"
Write-Result "CPU"                  $false "$($cpu.Name.Trim())"
Write-Result "CPU Kerne / Threads"  $false "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
 
$ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
$ramTotal   = ($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB
Write-Result "RAM Gesamt"           $false "$([math]::Round($ramTotal,1)) GB"
foreach ($mod in $ramModules) {
    $sizeGB  = [math]::Round($mod.Capacity / 1GB, 0)
    $type    = switch ($mod.SMBIOSMemoryType) { 26{"DDR4"} 34{"DDR5"} 24{"DDR3"} default{"DDR?"} }
    Write-Result "  Slot $($mod.DeviceLocator)" $false "$sizeGB GB $type @ $($mod.ConfiguredClockSpeed) MHz  ($($mod.Manufacturer.Trim()))"
}
 
$gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
foreach ($gpu in $gpus) {
    $vram = "n/v"
    try {
        $regBase = "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $subkeys = Get-ChildItem -Path $regBase -ErrorAction SilentlyContinue |
                   Where-Object { $_.GetValue("DriverDesc") -like "*$($gpu.Name.Split(" ")[2..10] -join " ")*" -or
                                  $_.GetValue("DriverDesc") -eq $gpu.Name }
        if (-not $subkeys) {
            $subkeys = Get-ChildItem -Path $regBase -ErrorAction SilentlyContinue |
                       Where-Object { $_.GetValue("HardwareInformation.MemorySize") -gt 0 }
        }
        foreach ($key in $subkeys) {
            $memRaw = $key.GetValue("HardwareInformation.MemorySize")
            if ($memRaw -and [uint64]$memRaw -gt 0) {
                $vram = "$([math]::Round([uint64]$memRaw / 1GB, 0)) GB"
                break
            }
        }
    } catch { }
    if ($vram -eq "n/v" -and $gpu.AdapterRAM -gt 0) {
        $vram = "$([math]::Round([uint64][uint32]$gpu.AdapterRAM / 1GB, 0)) GB (approx.)"
    }
    Write-Result "GPU" $false "$($gpu.Name)  VRAM: $vram  Treiber: $($gpu.DriverVersion)"
}
 
# PCIe Slots
Write-Host ""
Write-Host "   PCIe Steckplätze (SMBIOS)" -ForegroundColor White
$slots = Get-CimInstance -ClassName Win32_SystemSlot -ErrorAction SilentlyContinue
if ($slots) {
    foreach ($sl in $slots) {
        $usageTxt  = switch ($sl.CurrentUsage) { 2{"Frei"} 3{"Belegt"} 4{"Verfuegbar"} default{"Unbekannt"} }
        $slTypeTxt = switch ($sl.SlotType) { 6{"PCI"} 16{"PCIe"} 17{"PCIe x1"} 18{"PCIe x2"} 19{"PCIe x4"} 20{"PCIe x8"} 21{"PCIe x16"} 22{"PCIe x1 Gen2"} 23{"PCIe x16 Gen2"} default{"Typ $($sl.SlotType)"} }
        $slotSusp  = ($sl.CurrentUsage -eq 3)
        Write-Result "  $($sl.SlotDesignation)" $slotSusp "$slTypeTxt  |  $usageTxt"
    }
} else {
    Write-Host "   Keine SMBIOS Slot-Daten verfuegbar." -ForegroundColor DarkGray
}
 
# Alle PCI Geräte
Write-Host ""
Write-Host "   PCI / PCIe Geräte" -ForegroundColor White
 
$vendorNames = @{
    "1002" = "AMD"
    "1022" = "AMD"
    "10DE" = "NVIDIA"
    "10EC" = "Realtek"
    "10EE" = "Xilinx FPGA"
    "1172" = "Altera / Intel FPGA"
    "1204" = "Lattice Semiconductor FPGA"
    "11E3" = "QuickLogic FPGA"
    "1217" = "O2 Micro"
    "1234" = "QEMU / generisches FPGA-Board"
    "1414" = "Microsoft"
    "14E4" = "Broadcom"
    "168C" = "Qualcomm Atheros"
    "1814" = "Ralink Technology"
    "1912" = "Renesas"
    "1B21" = "ASMedia"
    "1B73" = "Fresco Logic"
    "1C5C" = "SK Hynix"
    "1D6C" = "Artix-7 DMA-Karte (generisch)"
    "1F40" = "Chelsio"
    "2646" = "Kingston"
    "8086" = "Intel"
    "0BDA" = "LambdaConcept (SQRL Acorn / Screamer)"
    "0B05" = "ASUS"
}
 
$dmaVendors = @("10EE","1172","1204","11E3","1234","1D6C","0BDA")
 
$pciAll = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
          Where-Object { $_.DeviceID -like "PCI\*" } | Sort-Object Name
 
foreach ($dev in $pciAll) {
    $vid = ""; $did = ""; $loc = ""; $vendor = ""
    if ($dev.DeviceID -match "VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})") {
        $vid    = $Matches[1].ToUpper()
        $did    = $Matches[2].ToUpper()
        $vendor = if ($vendorNames.ContainsKey($vid)) { $vendorNames[$vid] } else { "Unbekannt" }
    }
    if ($dev.DeviceID -match "BUS_(\w+)&DEV_(\w+)&FUNC_(\w+)") {
        $loc = "Bus $([Convert]::ToInt32($Matches[1],16)) Slot $([Convert]::ToInt32($Matches[2],16)) Func $([Convert]::ToInt32($Matches[3],16))"
    }
    $isDma  = $dmaVendors -contains $vid
    $color  = if ($isDma) { "Yellow" } else { "Gray" }
    $prefix = if ($isDma) { "   [!]" } else { "      " }
    Write-Host "$prefix $($dev.Name.PadRight(45))" -NoNewline -ForegroundColor $color
    Write-Host " VEN:$vid DEV:$did  $($vendor.PadRight(30)) $loc" -ForegroundColor $color
}
 
# ===========================================================================
# FORENSIK CHECKS
# ===========================================================================
Write-Section "FORENSIK CHECKS"
 
# Registry Quellen einmalig laden
$dgReg1  = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceGuard" -ErrorAction SilentlyContinue
$dgReg2  = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"          -ErrorAction SilentlyContinue
$dgWmi   = $null
try { $dgWmi = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop } catch { }
 
Write-Host ""
 
# --- 1. IOMMU ---
# HypervisorEnforcedDmaProtection = 1 bedeutet Hardware-IOMMU aktiv und genutzt
$iommuVal     = $dgReg1.HypervisorEnforcedDmaProtection
$iommuEnabled = ($iommuVal -eq 1)
Write-Result "IOMMU" (-not $iommuEnabled) $(if ($iommuEnabled) { "Aktiv" } else { "Deaktiviert" })
if (-not $iommuEnabled) { Add-Finding "IOMMU deaktiviert - Hardware-DMA-Schutz nicht aktiv" }
 
# --- 2. Kernel-DMA-Schutz ---
# Separater Check: SecurityServicesRunning Bit 0x10 via WMI, sonst Registry
$kdmaAktiv = $false
if ($dgWmi) {
    $svcSum    = ($dgWmi.SecurityServicesRunning | Measure-Object -Sum).Sum
    $kdmaAktiv = ([int]$svcSum -band 0x10) -ne 0
} else {
    # Fallback: wenn VBS + IOMMU aktiv, gilt Kernel-DMA-Schutz als aktiv
    $kdmaAktiv = ($iommuEnabled -and $dgReg2.EnableVirtualizationBasedSecurity -eq 1)
}
Write-Result "Kernel-DMA-Schutz" (-not $kdmaAktiv) $(if ($kdmaAktiv) { "Aktiv" } else { "Deaktiviert" })
if (-not $kdmaAktiv) { Add-Finding "Kernel-DMA-Schutz deaktiviert - DMA-Zugriff auf RAM möglich" }
 
# --- 3. VBS ---
$vbsStatus = 0
if ($dgWmi) {
    $vbsStatus = [int]$dgWmi.VirtualizationBasedSecurityStatus
} elseif ($dgReg2.EnableVirtualizationBasedSecurity -eq 1) {
    $vbsStatus = 1
}
$vbsText = switch ($vbsStatus) { 0{"Deaktiviert"} 1{"Aktiviert, nicht laufend"} 2{"Aktiv"} default{"Unbekannt"} }
Write-Result "VBS (Virtualization Based Security)" ($vbsStatus -eq 0) $vbsText
if ($vbsStatus -eq 0) { Add-Finding "VBS deaktiviert - Kernel-Speicher nicht isoliert" }
 
# --- 4. Memory Integrity / HVCI ---
$hvciKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$hvciVal = (Get-ItemProperty -Path $hvciKey -ErrorAction SilentlyContinue).Enabled
Write-Result "Memory Integrity (HVCI)" ($hvciVal -ne 1) $(if ($hvciVal -eq 1) { "Aktiv" } else { "Deaktiviert" })
if ($hvciVal -ne 1) { Add-Finding "Memory Integrity (HVCI) deaktiviert" }
 
# --- 5. Credential Guard ---
$cgAktiv = $false
if ($dgWmi) {
    $svcSum  = ($dgWmi.SecurityServicesRunning | Measure-Object -Sum).Sum
    $cgAktiv = ([int]$svcSum -band 0x1) -ne 0
} else {
    $cgReg   = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -ErrorAction SilentlyContinue).LsaCfgFlags
    $cgAktiv = ($cgReg -eq 1 -or $cgReg -eq 2)
}
Write-Result "Credential Guard" (-not $cgAktiv) $(if ($cgAktiv) { "Aktiv" } else { "Deaktiviert" })
if (-not $cgAktiv) { Add-Finding "Credential Guard deaktiviert - LSASS-Speicher ungeschuetzt" }
 
# --- 6. Secure Boot ---
try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    Write-Result "Secure Boot" (-not $sb) $(if ($sb) { "Aktiv" } else { "Deaktiviert" })
    if (-not $sb) { Add-Finding "Secure Boot deaktiviert" }
} catch {
    Write-Result "Secure Boot" $true "Nicht verfuegbar / deaktiviert"
    Add-Finding "Secure Boot nicht verfuegbar"
}
 
# --- 7. Hypervisor Launch Type ---
$bcdOut      = & bcdedit /enum | Out-String
$hyperLaunch = if ($bcdOut -match "hypervisorlaunchtype\s+(\S+)") { $Matches[1] } else { "Off" }
$hvSusp      = ($hyperLaunch -ieq "Off")
$hvText      = if ($hyperLaunch -ieq "Off") { "Deaktiviert" } elseif ($hyperLaunch -ieq "Auto") { "Aktiviert (Auto)" } else { $hyperLaunch }
Write-Result "Hypervisor Launch Type" $hvSusp $hvText
if ($hvSusp) { Add-Finding "Hypervisor Launch Type deaktiviert (Off)" }
 
# --- 8. Hyper-V Windows Feature ---
$hvFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($hvFeature) {
    $hvAktiv = ($hvFeature.State -eq "Enabled")
    Write-Result "Hyper-V Feature" (-not $hvAktiv) $(if ($hvAktiv) { "Aktiviert" } else { "Deaktiviert" })
} else {
    Write-Result "Hyper-V Feature" $true "Nicht installiert"
}
 
# --- 9. Defender Echtzeit-Schutz ---
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    $rtAktiv = $mp.RealTimeProtectionEnabled
    Write-Result "Defender Echtzeit-Schutz" (-not $rtAktiv) $(if ($rtAktiv) { "Aktiv" } else { "Deaktiviert" })
    if (-not $rtAktiv) { Add-Finding "Defender Echtzeit-Schutz deaktiviert" }
} catch {
    Write-Result "Defender Echtzeit-Schutz" $true "Nicht verfuegbar"
    Add-Finding "Defender nicht verfuegbar - möglicherweise entfernt"
}
 
# --- 10. Spectre / Meltdown Mitigationen ---
$specKey    = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$fsOverride = (Get-ItemProperty -Path $specKey -ErrorAction SilentlyContinue).FeatureSettingsOverride
$fsMask     = (Get-ItemProperty -Path $specKey -ErrorAction SilentlyContinue).FeatureSettingsOverrideMask
$specSusp   = ($fsOverride -eq 3 -and $fsMask -eq 3)
Write-Result "Spectre / Meltdown Mitigationen" $specSusp $(if ($specSusp) { "Deaktiviert (Override=3, Mask=3)" } else { "Aktiv (Standard)" })
if ($specSusp) { Add-Finding "Spectre / Meltdown Mitigationen manuell deaktiviert" }
 
# ===========================================================================
# PCIE DEVICE CHECK
# ===========================================================================
Write-Section "PCIE DEVICE CHECK"
 
# Bekannte VEN+DEV Kombinationen von DMA-Karten
$knownDmaDevices = @{
    "10EE:0666" = "PCILeech FPGA (Standard)"
    "10EE:7021" = "Screamer M2"
    "10EE:7022" = "Screamer PCIe"
    "10EE:7868" = "PCIeScreamer R02"
    "10EE:4250" = "Enigma X1 DMA"
    "10EE:0505" = "ZDMA / generisch Xilinx"
    "10EE:9038" = "Xilinx AXI DMA"
    "10EE:8011" = "Xilinx PCIe DMA"
    "1172:E001" = "Altera FPGA DMA"
    "1172:0004" = "Altera PCIe MegaCore"
    "1D6C:1337" = "Artix-7 DMA (häufige ID)"
    "1234:1111" = "QEMU generisches FPGA"
    "0BDA:8153" = "SQRL Acorn CLE-215+"
}
 
# Bekannte Vendor IDs (nur Hersteller, ohne spezifische Device ID)
$knownDmaVendors = @{
    "10EE" = "Xilinx FPGA"
    "1172" = "Altera / Intel FPGA"
    "1204" = "Lattice Semiconductor FPGA"
    "11E3" = "QuickLogic FPGA"
    "1D6C" = "Artix-7 DMA-Karte (generisch)"
    "1234" = "QEMU / generisches FPGA-Board"
    "0BDA" = "LambdaConcept (SQRL Acorn / Screamer)"
}
 
$allPci    = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
             Where-Object { $_.DeviceID -like "PCI\VEN_*" }
$totalHits = 0
 
Write-Host ""
Write-Host "   Exakte Geräte-IDs (VEN+DEV)" -ForegroundColor White
 
$deviceHits = 0
foreach ($dev in $allPci) {
    if ($dev.DeviceID -match "VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})") {
        $vid    = $Matches[1].ToUpper()
        $did    = $Matches[2].ToUpper()
        $key    = "$vid`:$did"
        if ($knownDmaDevices.ContainsKey($key)) {
            Write-Result "  TREFFER" $true "$($dev.Name)"
            Write-Host "   $("  VEN:$vid DEV:$did".PadRight(35)) $($knownDmaDevices[$key])" -ForegroundColor DarkYellow
            Add-Finding "Bekannte DMA-Karte gefunden: $($dev.Name) (VEN:$vid DEV:$did - $($knownDmaDevices[$key]))"
            $deviceHits++
            $totalHits++
        }
    }
}
if ($deviceHits -eq 0) {
    Write-Result "  Exakte Device ID" $false "Keine bekannten DMA-Karten gefunden"
}
 
Write-Host ""
Write-Host "   Vendor ID (Hersteller-basiert)" -ForegroundColor White
 
$vendorHits = 0
foreach ($dev in $allPci) {
    if ($dev.DeviceID -match "VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})") {
        $vid = $Matches[1].ToUpper()
        $did = $Matches[2].ToUpper()
        $key = "$vid`:$did"
        if ($knownDmaVendors.ContainsKey($vid) -and -not $knownDmaDevices.ContainsKey($key)) {
            Write-Result "  Verdächtiger Hersteller" $true "$($dev.Name)"
            Write-Host "   $("  VEN:$vid DEV:$did".PadRight(35)) $($knownDmaVendors[$vid])" -ForegroundColor DarkYellow
            Add-Finding "Verdächtiger FPGA-Hersteller: $($dev.Name) (VEN:$vid DEV:$did - $($knownDmaVendors[$vid]))"
            $vendorHits++
            $totalHits++
        }
    }
}
if ($vendorHits -eq 0) {
    Write-Result "  Vendor ID" $false "Keine verdächtigen FPGA-Hersteller gefunden"
}
 
# ===========================================================================
# UNBEKANNTE / FEHLERHAFTE GERÄTE
# ===========================================================================
Write-Section "UNBEKANNTE UND FEHLERHAFTE GERÄTE"
 
# Geräte ohne Treiber oder mit Fehler sind verdächtig - DMA-Karten erscheinen
# häufig als "Unbekanntes Gerät" wenn kein passender Treiber installiert ist
$unknownDevices = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
                  Where-Object {
                      $_.DeviceID -like "PCI\*" -and (
                          $_.ConfigManagerErrorCode -ne 0 -or
                          $_.Name -match "Unbekannt|Unknown|Base System Device" -or
                          $_.PNPClass -eq $null -or
                          $_.PNPClass -eq ""
                      )
                  }
 
$unknownHits = 0
foreach ($dev in $unknownDevices) {
    $errCode = $dev.ConfigManagerErrorCode
    $errText = switch ($errCode) {
        1  { "Kein Treiber" }
        10 { "Gerät kann nicht starten" }
        18 { "Treiber neu installieren" }
        28 { "Treiber nicht installiert" }
        43 { "Windows hat Gerät angehalten" }
        default { "Fehlercode $errCode" }
    }
    $vid = ""
    $did = ""
    if ($dev.DeviceID -match "VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})") {
        $vid = $Matches[1].ToUpper()
        $did = $Matches[2].ToUpper()
    }
    Write-Result "  $($dev.Name)" $true "$errText  |  VEN:$vid DEV:$did"
    Add-Finding "Unbekanntes / fehlerhaftes PCIe-Gerät: $($dev.Name) VEN:$vid DEV:$did ($errText)"
    $unknownHits++
    $totalHits++
}
 
if ($unknownHits -eq 0) {
    Write-Result "  Geräte ohne Treiber" $false "Keine unbekannten PCIe-Geräte gefunden"
}
 
# ===========================================================================
# BYPASS-ERKENNUNG & FORENSIK
# ===========================================================================
Write-Section "BYPASS-ERKENNUNG UND FORENSIK"
 
# --- USN Journal ---
$usnStatus = & fsutil usn queryjournal C: 2>&1 | Out-String
$usnDeleted = $usnStatus -match "ungueltig|invalid|nicht gefunden|not found|error"
Write-Result "USN Journal (C:)" $usnDeleted $(if ($usnDeleted) { "Gelöscht oder deaktiviert" } else { "Vorhanden" })
if ($usnDeleted) { Add-Finding "USN Journal gelöscht - häufige Bypass-Methode" }
 
# --- Prefetch ---
$pfPath    = "$env:SystemRoot\Prefetch"
$pfExists  = Test-Path $pfPath
$pfFiles   = if ($pfExists) { (Get-ChildItem $pfPath -ErrorAction SilentlyContinue).Count } else { 0 }
$pfSusp    = (-not $pfExists -or $pfFiles -eq 0)
Write-Result "Prefetch Ordner" $pfSusp $(if (-not $pfExists) { "Ordner fehlt - gelöscht oder umbenannt" } elseif ($pfFiles -eq 0) { "Leer ($pfFiles Dateien) - möglicherweise geleert" } else { "Vorhanden ($pfFiles Dateien)" })
if ($pfSusp) { Add-Finding "Prefetch Ordner gelöscht oder geleert - Bypass-Verdacht" }
 
# --- Prefetch deaktiviert per Registry ---
$pfReg  = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -ErrorAction SilentlyContinue).EnablePrefetcher
$pfDis  = ($pfReg -eq 0)
Write-Result "Prefetch aktiviert (Registry)" $pfDis $(if ($pfDis) { "Deaktiviert (EnablePrefetcher=0)" } else { "Aktiv (Wert: $pfReg)" })
if ($pfDis) { Add-Finding "Prefetch per Registry deaktiviert - verhindert Ausfuehrungs-Logging" }
 
# --- Event Logs (System + Security) geleert ---
$evtSusp = $false
$evtLogs = @("System", "Security", "Application")
foreach ($log in $evtLogs) {
    try {
        $evt    = Get-WinEvent -ListLog $log -ErrorAction Stop
        $leert  = ($evt.RecordCount -eq 0)
        Write-Result "Event Log: $log" $leert $(if ($leert) { "LEER - möglicherweise geleert" } else { "$($evt.RecordCount) Einträge" })
        if ($leert) {
            Add-Finding "Event Log '$log' ist leer - möglicherweise gezielt geleert"
            $evtSusp = $true
        }
    } catch {
        Write-Result "Event Log: $log" $true "Nicht zugreifbar"
    }
}
 
# --- Systemzeit Manipulation (Uptime vs. letzte Aenderung kritischer Logs) ---
$bootTime   = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$now        = Get-Date
$uptimeMins = ($now - $bootTime).TotalMinutes
$sysLog     = Get-WinEvent -ListLog "System" -ErrorAction SilentlyContinue
$timeSusp   = $false
if ($sysLog -and $sysLog.LastWriteTime) {
    $logAge    = ($now - $sysLog.LastWriteTime).TotalMinutes
    $timeSusp  = ($logAge -gt ($uptimeMins + 60))
    Write-Result "Systemzeit Konsistenz" $timeSusp $(if ($timeSusp) { "Auffällig - Log-Zeitstempel passt nicht zur Uptime" } else { "OK (Uptime: $([math]::Round($uptimeMins,0)) Min)" })
    if ($timeSusp) { Add-Finding "Systemzeit wurde möglicherweise vor Screen-Share manipuliert" }
} else {
    Write-Result "Systemzeit Konsistenz" $false "Nicht pruefbar"
}
 
# --- BAM - Ausgefuehrte Dateien seit letztem Boot ---
Write-Host ""
Write-Host "   BAM - Ausgefuehrte Dateien (seit letztem Boot)" -ForegroundColor White
 
$bamBase   = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
$bamSids   = Get-ChildItem -Path $bamBase -ErrorAction SilentlyContinue
$bamSusp   = @(
    "pcileech", "memprocfs", "vivado", "zadig", "dmacheck",
    "winpmem", "arsenal", "squirrel", "leechcore", "screamer",
    "fpga", "jtagprogrammer", "openocd", "pcie_injector"
)
$bamHits   = 0
$bamAll    = [System.Collections.Generic.List[string]]::new()
 
foreach ($sid in $bamSids) {
    $entries = $sid.GetValueNames() | Where-Object { $_ -like "*.exe" -or $_ -like "*.dll" }
    foreach ($entry in $entries) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($entry).ToLower()
        $bamAll.Add($entry)
        foreach ($susp in $bamSusp) {
            if ($name -match $susp) {
                Write-Result "  BAM TREFFER" $true "$entry"
                Add-Finding "BAM: Verdächtiges Tool ausgefuehrt: $entry"
                $bamHits++
            }
        }
    }
}
if ($bamHits -eq 0) {
    Write-Result "  BAM Scan" $false "Keine bekannten DMA-Tools gefunden ($($bamAll.Count) Einträge geprueft)"
}
 
# --- Mehrere Mäuse (KMBox / Eingabegeräte) ---
$mice     = Get-CimInstance -ClassName Win32_PointingDevice -ErrorAction SilentlyContinue |
            Where-Object { $_.PNPClass -eq "Mouse" -or $_.Description -match "mouse|maus" }
$miceCount = ($mice | Measure-Object).Count
$miceSusp  = ($miceCount -gt 1)
Write-Result "Angeschlossene Mäuse" $miceSusp "$miceCount erkannt$(if ($miceSusp) { ' - mehrere Eingabegeräte (KMBox?)' } else { '' })"
if ($miceSusp) { Add-Finding "Mehrere Maus-Geräte erkannt ($miceCount) - möglicherweise KMBox oder zweite Maus" }
 
# --- USB Capture Cards / Video Fuser ---
Write-Host ""
Write-Host "   USB Capture Cards und Video Fuser" -ForegroundColor White
 
$captureVids = @{
    "07CA" = "AVerMedia Capture Card"
    "1CEA" = "AVerMedia"
    "1E4E" = "Elgato / Corsair Capture"
    "0FD9" = "Elgato"
    "2040" = "Hauppauge"
    "EB1A" = "eMPIA Technology (Capture)"
    "1164" = "YUAN Capture Card"
    "1822" = "Twinhan Capture"
    "04BB" = "I-O Data Capture"
    "2935" = "Magewell Capture"
    "1D27" = "XIMEA Capture"
}
 
$usbDevices  = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
               Where-Object { $_.DeviceID -like "USB\VID_*" }
$captureHits = 0
 
foreach ($dev in $usbDevices) {
    if ($dev.DeviceID -match "VID_([0-9A-Fa-f]{4})") {
        $vid = $Matches[1].ToUpper()
        if ($captureVids.ContainsKey($vid)) {
            Write-Result "  Capture Device" $true "$($dev.Name)  (VID: $vid - $($captureVids[$vid]))"
            Add-Finding "Capture Card / Video Fuser gefunden: $($dev.Name) (VID:$vid) - wird fuer DMA-Dual-Screen genutzt"
            $captureHits++
        }
    }
}
if ($captureHits -eq 0) {
    Write-Result "  Capture Cards" $false "Keine bekannten Capture Cards gefunden"
}
 
# --- Defender Ausnahmen ---
Write-Host ""
Write-Host "   Windows Defender Ausnahmen" -ForegroundColor White
 
$defExclPaths   = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"    -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
$defExclProcs   = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes" -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
$defExclExt     = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Extensions" -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
$defHits        = 0
 
foreach ($excl in $defExclPaths) {
    Write-Result "  Pfad-Ausnahme" $true "$($excl.Name)"
    Add-Finding "Defender Pfad-Ausnahme: $($excl.Name)"
    $defHits++
}
foreach ($excl in $defExclProcs) {
    Write-Result "  Prozess-Ausnahme" $true "$($excl.Name)"
    Add-Finding "Defender Prozess-Ausnahme: $($excl.Name)"
    $defHits++
}
foreach ($excl in $defExclExt) {
    Write-Result "  Erweiterungs-Ausnahme" $true "$($excl.Name)"
    Add-Finding "Defender Erweiterungs-Ausnahme: $($excl.Name)"
    $defHits++
}
if ($defHits -eq 0) {
    Write-Result "  Defender Ausnahmen" $false "Keine Ausnahmen konfiguriert"
}
 
# ===========================================================================
# ERGEBNIS
# ===========================================================================
Write-Host ""
Write-Host "   $("=" * 80)" -ForegroundColor DarkGray
Write-Host "   ERGEBNIS" -ForegroundColor Cyan
Write-Host "   $("=" * 80)" -ForegroundColor DarkGray
Write-Host ""
 
if ($findings.Count -eq 0) {
    Write-Host "   [+] Keine Auffälligkeiten - System zeigt keine DMA-Vorbereitung." -ForegroundColor Green
} else {
    foreach ($f in $findings) {
        Write-Host "   [!] $f" -ForegroundColor Red
    }
    Write-Host ""
    if ($findings.Count -ge 4) {
        Write-Host "   BEWERTUNG: HOHES RISIKO" -ForegroundColor Red
        Write-Host "   Mehrere Sicherheitsmechanismen wurden gezielt deaktiviert." -ForegroundColor DarkGray
    } elseif ($findings.Count -ge 2) {
        Write-Host "   BEWERTUNG: AUFFÄLLIG" -ForegroundColor Yellow
        Write-Host "   Einige Einstellungen weichen vom Windows-Standard ab." -ForegroundColor DarkGray
    } else {
        Write-Host "   BEWERTUNG: LEICHT AUFFÄLLIG" -ForegroundColor Yellow
        Write-Host "   Einzelner Befund - kein eindeutiger Beweis." -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Check PCIe Geräte via https://devicehunt.com/" -ForegroundColor DarkGray
Write-Host ""

Write-Host ""
Read-Host -Prompt "   Drücke ENTER zum Beenden"
