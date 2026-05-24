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
    $vram = if ($gpu.AdapterRAM -gt 0) { "$([math]::Round($gpu.AdapterRAM/1GB,0)) GB" } else { "n/v" }
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
$pciAll = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
          Where-Object { $_.DeviceID -like "PCI\*" } | Sort-Object Name
foreach ($dev in $pciAll) {
    $loc = ""
    if ($dev.DeviceID -match "BUS_(\w+)&DEV_(\w+)&FUNC_(\w+)") {
        $loc = "Bus $([Convert]::ToInt32($Matches[1],16)) Slot $([Convert]::ToInt32($Matches[2],16)) Func $([Convert]::ToInt32($Matches[3],16))"
    }
    Write-Host "   $($dev.Name.PadRight(50)) $loc" -ForegroundColor Gray
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
Write-Result "Hypervisor Launch Type" $hvSusp $hyperLaunch
if ($hvSusp) { Add-Finding "HypervisorLaunchType ist Off - Hyper-V/VBS deaktiviert" }

$hvFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($hvFeature) {
    Write-Result "Hyper-V Feature" ($hvFeature.State -ne "Enabled") $hvFeature.State
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

# NetworkThrottlingIndex - Fix: UInt32 statt Int32
$mmKey  = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$ntiRaw = (Get-ItemProperty -Path $mmKey -ErrorAction SilentlyContinue).NetworkThrottlingIndex
$ntiSusp = ($null -ne $ntiRaw -and [uint32]$ntiRaw -eq 0xFFFFFFFF)
$ntiTxt  = if ($null -ne $ntiRaw) { "0x$([Convert]::ToString([int64][uint32]$ntiRaw, 16).ToUpper())" } else { "Standard" }
Write-Result "NetworkThrottlingIndex" $ntiSusp $ntiTxt
if ($ntiSusp) { Add-Finding "NetworkThrottlingIndex auf 0xFFFFFFFF gesetzt" }

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
