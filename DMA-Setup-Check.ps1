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

Write-Host "                         Made by flomkk - " -NoNewline -ForegroundColor White
Write-Host "github.com/flomkk" -ForegroundColor Magenta
Write-Host ""
 
$findings = [System.Collections.Generic.List[string]]::new()
 
function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "   $Text" -ForegroundColor Cyan
    Write-Host "   $("=" * 55)" -ForegroundColor DarkGray
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
    $sizeGB   = [math]::Round($mod.Capacity / 1GB, 0)
    $type     = switch ($mod.SMBIOSMemoryType) { 26{"DDR4"} 34{"DDR5"} 24{"DDR3"} default{"DDR?"} }
    Write-Result "  Slot $($mod.DeviceLocator)" $false "$sizeGB GB $type @ $($mod.ConfiguredClockSpeed) MHz  ($($mod.Manufacturer.Trim()))"
}
 
$gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
foreach ($gpu in $gpus) {
    # Win32_VideoController.AdapterRAM ist 32-bit - max 4 GB darstellbar
    # Korrekte VRAM-Abfrage ueber Registry (DXGI-Eintrag von Windows befuellt)
    $vram = "n/v"
    try {
        $regBase = "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $subkeys = Get-ChildItem -Path $regBase -ErrorAction SilentlyContinue |
                   Where-Object { $_.GetValue("DriverDesc") -like "*$($gpu.Name.Split(" ")[2..10] -join " ")*" -or
                                  $_.GetValue("DriverDesc") -eq $gpu.Name }
        if (-not $subkeys) {
            # Fallback: alle Subkeys nach passendem Treiber durchsuchen
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
    # Letzter Fallback: DXDIAG-Wert aus WMI mit uint64-Cast
    if ($vram -eq "n/v" -and $gpu.AdapterRAM -gt 0) {
        $vram = "$([math]::Round([uint64][uint32]$gpu.AdapterRAM / 1GB, 0)) GB (approx.)"
    }
    Write-Result "GPU" $false "$($gpu.Name)  VRAM: $vram  Treiber: $($gpu.DriverVersion)"
}
 
# PCIe Slots
Write-Host ""
Write-Host "   PCIe Steckplaetze (SMBIOS)" -ForegroundColor White
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
 
# Alle PCI Geraete
Write-Host ""
Write-Host "   PCI / PCIe Geraete" -ForegroundColor White
 
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
    $vid    = ""
    $did    = ""
    $loc    = ""
    $vendor = ""
 
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
 
# Kernel-DMA-Schutz
try {
    $dg          = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
    $kdmaRunning = ($dg.SecurityServicesRunning -band 0x10) -ne 0
    Write-Result "Kernel-DMA-Schutz" (-not $kdmaRunning) $(if ($kdmaRunning) { "Aktiv" } else { "Deaktiviert" })
    if (-not $kdmaRunning) { Add-Finding "Kernel-DMA-Schutz deaktiviert" }
 
    $vbsStatus = $dg.VirtualizationBasedSecurityStatus
    $vbsText   = switch ($vbsStatus) { 0{"Deaktiviert"} 1{"Aktiviert, nicht laufend"} 2{"Aktiv"} default{"Unbekannt ($vbsStatus)"} }
    Write-Result "VBS" ($vbsStatus -eq 0) $vbsText
    if ($vbsStatus -eq 0) { Add-Finding "VBS deaktiviert" }
 
    $cgRunning = ($dg.SecurityServicesRunning -band 0x1) -ne 0
    Write-Result "Credential Guard" (-not $cgRunning) $(if ($cgRunning) { "Aktiv" } else { "Deaktiviert" })
    if (-not $cgRunning) { Add-Finding "Credential Guard deaktiviert" }
} catch {
    Write-Result "DeviceGuard WMI" $true "Nicht verfuegbar (OS-Komponente entfernt)"
    Add-Finding "DeviceGuard WMI nicht verfuegbar - moegliche OS-Manipulation"
}
 
# HVCI
$hvciKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$hvciVal = (Get-ItemProperty -Path $hvciKey -ErrorAction SilentlyContinue).Enabled
Write-Result "Memory Integrity (HVCI)" ($hvciVal -ne 1) $(if ($hvciVal -eq 1) { "Aktiv" } else { "Deaktiviert" })
if ($hvciVal -ne 1) { Add-Finding "HVCI/Memory Integrity deaktiviert" }
 
# Secure Boot
try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    Write-Result "Secure Boot" (-not $sb) $(if ($sb) { "Aktiv" } else { "Deaktiviert" })
    if (-not $sb) { Add-Finding "Secure Boot deaktiviert" }
} catch {
    Write-Result "Secure Boot" $true "Nicht verfuegbar / deaktiviert"
    Add-Finding "Secure Boot nicht verfuegbar"
}
 
# Hypervisor
$bcdOut      = & bcdedit /enum | Out-String
$hyperLaunch = if ($bcdOut -match "hypervisorlaunchtype\s+(\S+)") { $Matches[1] } else { "Off" }
$hvSusp      = ($hyperLaunch -ieq "Off")
$hvText      = if ($hyperLaunch -ieq "Off") { "Deaktiviert" } elseif ($hyperLaunch -ieq "Auto") { "Aktiviert (Auto)" } else { $hyperLaunch }
Write-Result "Hypervisor Launch Type" $hvSusp $hvText
if ($hvSusp) { Add-Finding "Hypervisor deaktiviert - Hyper-V/VBS nicht aktiv" }
 
$hvFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($hvFeature) {
    $hvAktiv  = ($hvFeature.State -eq "Enabled")
    $hvText   = if ($hvAktiv) { "Aktiviert" } else { "Deaktiviert" }
    Write-Result "Hyper-V Feature" (-not $hvAktiv) $hvText
} else {
    Write-Result "Hyper-V Feature" $true "Nicht installiert"
}
 
# Defender
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    Write-Result "Defender Echtzeit-Schutz" (-not $mp.RealTimeProtectionEnabled) $(if ($mp.RealTimeProtectionEnabled) { "Aktiv" } else { "Deaktiviert" })
    if (-not $mp.RealTimeProtectionEnabled) { Add-Finding "Defender Echtzeit-Schutz deaktiviert" }
} catch {
    Write-Result "Defender Echtzeit-Schutz" $true "Nicht verfuegbar"
    Add-Finding "Defender nicht verfuegbar - moeglicherweise entfernt"
}
 
# Spectre/Meltdown
$specKey    = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$fsOverride = (Get-ItemProperty -Path $specKey -ErrorAction SilentlyContinue).FeatureSettingsOverride
$fsMask     = (Get-ItemProperty -Path $specKey -ErrorAction SilentlyContinue).FeatureSettingsOverrideMask
$specSusp   = ($fsOverride -eq 3 -and $fsMask -eq 3)
Write-Result "Spectre/Meltdown Schutz" $specSusp $(if ($specSusp) { "Deaktiviert (Override=3, Mask=3)" } else { "Standard" })
if ($specSusp) { Add-Finding "Spectre/Meltdown Mitigationen manuell deaktiviert" }
 
# ===========================================================================
# PCIE VENDOR ID CHECK
# ===========================================================================
Write-Section "PCIE VENDOR ID CHECK"
 
# Bekannte Vendor IDs von FPGA/DMA-Karten-Herstellern
$knownDmaVendors = @{
    "10EE" = "Xilinx FPGA (PCILeech, ScreamerM2, kompatible DMA-Karten)"
    "1172" = "Altera / Intel FPGA (Stratix, Cyclone)"
    "1204" = "Lattice Semiconductor FPGA (ECP5)"
    "0BDA" = "Realtek / LambdaConcept (SQRL Acorn, Screamer)"
    "11E3" = "QuickLogic FPGA"
    "1D6C" = "Artix-7 basierte DMA-Karten (generisch)"
}
 
$allPci = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
          Where-Object { $_.DeviceID -like "PCI\VEN_*" }
 
$vendorHits = 0
foreach ($dev in $allPci) {
    if ($dev.DeviceID -match "VEN_([0-9A-Fa-f]{4})") {
        $vid = $Matches[1].ToUpper()
        if ($knownDmaVendors.ContainsKey($vid)) {
            Write-Result "Verdaechtiges Geraet gefunden" $true "$($dev.Name)"
            Write-Host "   $("VendorID: 0x$vid".PadRight(35)) $($knownDmaVendors[$vid])" -ForegroundColor DarkYellow
            Add-Finding "Verdaechtiges PCIe-Geraet: $($dev.Name) (VendorID: 0x$vid - $($knownDmaVendors[$vid]))"
            $vendorHits++
        }
    }
}
 
if ($vendorHits -eq 0) {
    Write-Result "Vendor ID Check" $false "Keine bekannten DMA-Karten-Hersteller gefunden"
}
 
# ===========================================================================
# ERGEBNIS
# ===========================================================================
Write-Host ""
Write-Host "   $("=" * 55)" -ForegroundColor DarkGray
Write-Host "   ERGEBNIS" -ForegroundColor Cyan
Write-Host "   $("=" * 55)" -ForegroundColor DarkGray
Write-Host ""
 
if ($findings.Count -eq 0) {
    Write-Host "   [+] Keine Auffaelligkeiten - System zeigt keine DMA-Vorbereitung." -ForegroundColor Green
} else {
    foreach ($f in $findings) {
        Write-Host "   [!] $f" -ForegroundColor Red
    }
    Write-Host ""
    if ($findings.Count -ge 4) {
        Write-Host "   BEWERTUNG: HOHES RISIKO" -ForegroundColor Red
        Write-Host "   Mehrere Sicherheitsmechanismen wurden gezielt deaktiviert." -ForegroundColor DarkGray
    } elseif ($findings.Count -ge 2) {
        Write-Host "   BEWERTUNG: AUFFAELLIG" -ForegroundColor Yellow
        Write-Host "   Einige Einstellungen weichen vom Windows-Standard ab." -ForegroundColor DarkGray
    } else {
        Write-Host "   BEWERTUNG: LEICHT AUFFAELLIG" -ForegroundColor Yellow
        Write-Host "   Einzelner Befund - kein eindeutiger Beweis." -ForegroundColor DarkGray
    }
}
 
Write-Host ""
Read-Host -Prompt "   Druecke ENTER zum Beenden"
