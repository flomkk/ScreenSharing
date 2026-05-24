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

Write-Host -ForegroundColor White "                         Made by flomkk - " -NoNewline
Write-Host -ForegroundColor Magenta "github.com/flomkk"
Write-Host ""
Write-Host -ForegroundColor DarkGray "   Prueft ob dieses System fuer den Einsatz einer DMA-Karte konfiguriert wurde."
Write-Host -ForegroundColor DarkGray "   Gedacht fuer FiveM Server-Admins waehrend Screen-Sharing Sessions."
Write-Host ""

$findings = [System.Collections.Generic.List[string]]::new()

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "   -------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   $Text" -ForegroundColor Cyan
    Write-Host "   -------------------------------------------------------" -ForegroundColor DarkGray
}

function Write-Find {
    param([string]$Label, [bool]$Suspicious, [string]$Value, [string]$Note)
    if ($Suspicious) {
        Write-Host "   [!] " -NoNewline -ForegroundColor Red
    } else {
        Write-Host "   [+] " -NoNewline -ForegroundColor Green
    }
    Write-Host "$Label" -NoNewline -ForegroundColor White
    Write-Host " : $Value" -ForegroundColor Gray
    if ($Note) {
        Write-Host "       $Note" -ForegroundColor DarkGray
    }
}

function Add-Finding {
    param([string]$Msg)
    $findings.Add($Msg)
}

# ===========================================================================
# HARDWARE INFO
# ===========================================================================
Write-Section "HARDWARE INFORMATIONEN"

$mb = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue
Write-Host "   [?] Mainboard..." -ForegroundColor Yellow
Write-Host "       Hersteller : $($mb.Manufacturer)" -ForegroundColor Gray
Write-Host "       Modell     : $($mb.Product)" -ForegroundColor Gray
Write-Host "       Version    : $($mb.Version)" -ForegroundColor Gray

$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "   [?] BIOS / UEFI..." -ForegroundColor Yellow
Write-Host "       Hersteller : $($bios.Manufacturer)" -ForegroundColor Gray
Write-Host "       Version    : $($bios.SMBIOSBIOSVersion)" -ForegroundColor Gray
Write-Host "       Datum      : $($bios.ReleaseDate)" -ForegroundColor Gray

$cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
Write-Host ""
Write-Host "   [?] CPU..." -ForegroundColor Yellow
Write-Host "       Modell     : $($cpu.Name.Trim())" -ForegroundColor Gray
Write-Host "       Kerne      : $($cpu.NumberOfCores) Kerne / $($cpu.NumberOfLogicalProcessors) Threads" -ForegroundColor Gray
Write-Host "       Sockel     : $($cpu.SocketDesignation)" -ForegroundColor Gray

$ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
$ramTotal   = ($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB
Write-Host ""
Write-Host "   [?] RAM (gesamt: $([math]::Round($ramTotal,1)) GB)..." -ForegroundColor Yellow
foreach ($mod in $ramModules) {
    $sizeGB   = [math]::Round($mod.Capacity / 1GB, 0)
    $speedMHz = $mod.ConfiguredClockSpeed
    $slot     = $mod.DeviceLocator
    $type     = switch ($mod.SMBIOSMemoryType) { 26{"DDR4"} 34{"DDR5"} 24{"DDR3"} default{"Typ $($mod.SMBIOSMemoryType)"} }
    Write-Host "       Slot $slot : $sizeGB GB $type @ $speedMHz MHz  |  $($mod.Manufacturer.Trim())" -ForegroundColor Gray
}

$gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "   [?] GPU(s)..." -ForegroundColor Yellow
foreach ($gpu in $gpus) {
    $vram = if ($gpu.AdapterRAM -gt 0) { "$([math]::Round($gpu.AdapterRAM/1GB,0)) GB" } else { "n/v" }
    Write-Host "       $($gpu.Name)  |  VRAM: $vram  |  Treiber: $($gpu.DriverVersion)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "   [?] PCI / PCIe Geraete..." -ForegroundColor Yellow
$pciAll = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
          Where-Object { $_.DeviceID -like "PCI\*" } | Sort-Object Name
foreach ($dev in $pciAll) {
    $loc = ""
    if ($dev.DeviceID -match "BUS_(\w+)&DEV_(\w+)&FUNC_(\w+)") {
        $loc = "Bus $([Convert]::ToInt32($Matches[1],16))  Slot $([Convert]::ToInt32($Matches[2],16))  Func $([Convert]::ToInt32($Matches[3],16))"
    }
    Write-Host "       $($dev.Name.PadRight(52)) $loc" -ForegroundColor Gray
}

Write-Host ""
Write-Host "   [?] Mainboard-Steckplaetze (SMBIOS)..." -ForegroundColor Yellow
$slots = Get-CimInstance -ClassName Win32_SystemSlot -ErrorAction SilentlyContinue
if ($slots) {
    foreach ($sl in $slots) {
        $usageTxt  = switch ($sl.CurrentUsage) { 2{"Frei"} 3{"Belegt"} 4{"Verfuegbar"} default{"Unbekannt ($($sl.CurrentUsage))"} }
        $slTypeTxt = switch ($sl.SlotType) { 6{"PCI"} 16{"PCIe"} 17{"PCIe x1"} 18{"PCIe x2"} 19{"PCIe x4"} 20{"PCIe x8"} 21{"PCIe x16"} 22{"PCIe x1 Gen2"} 23{"PCIe x16 Gen2"} default{"Typ $($sl.SlotType)"} }
        Write-Host ("       {0,-20} | {1,-15} | {2}" -f $sl.SlotDesignation, $slTypeTxt, $usageTxt) -ForegroundColor Gray
    }
} else {
    Write-Host "       [!] SMBIOS liefert keine Slot-Daten - physische Pruefung erforderlich." -ForegroundColor DarkYellow
}

# ===========================================================================
# FORENSIK CHECKS
# ===========================================================================
Write-Section "FORENSIK CHECKS"

# --- IOMMU / Kernel-DMA-Schutz ---
Write-Host "   [?] Pruefe IOMMU und Kernel-DMA-Schutz..." -ForegroundColor Yellow
try {
    $dg          = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
    $kdmaRunning = ($dg.SecurityServicesRunning -band 0x10) -ne 0
    Write-Find "Kernel-DMA-Schutz" (-not $kdmaRunning) `
        $(if ($kdmaRunning) { "Aktiv - System geschuetzt" } else { "DEAKTIVIERT - DMA-Zugriff auf RAM moeglich" }) `
        $(if (-not $kdmaRunning) { "Verdaechtig: Schutzmechanismus gezielt abgeschaltet." } else { "" })
    if (-not $kdmaRunning) { Add-Finding "Kernel-DMA-Schutz ist deaktiviert" }
} catch {
    Write-Host "   [!] DeviceGuard WMI nicht verfuegbar - Komponente entfernt oder deaktiviert." -ForegroundColor DarkYellow
    Add-Finding "DeviceGuard WMI nicht verfuegbar - moegliche OS-Manipulation"
}

# --- VBS ---
Write-Host "   [?] Pruefe Virtualization Based Security (VBS)..." -ForegroundColor Yellow
try {
    $dg        = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
    $vbsStatus = $dg.VirtualizationBasedSecurityStatus
    $vbsText   = switch ($vbsStatus) { 0{"DEAKTIVIERT"} 1{"Aktiviert, nicht laufend"} 2{"Aktiv"} default{"Unbekannt ($vbsStatus)"} }
    Write-Find "VBS Status" ($vbsStatus -eq 0) $vbsText `
        $(if ($vbsStatus -eq 0) { "Verdaechtig: VBS schuetzt Kernel-Speicher - Deaktivierung ermoeglicht DMA-Reads." } else { "" })
    if ($vbsStatus -eq 0) { Add-Finding "VBS ist deaktiviert - Kernel-Speicher ungeschuetzt" }
} catch {
    Write-Host "   [!] VBS WMI nicht verfuegbar." -ForegroundColor DarkYellow
}

# --- HVCI / Memory Integrity ---
Write-Host "   [?] Pruefe Memory Integrity (HVCI)..." -ForegroundColor Yellow
$hvciKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$hvciVal = (Get-ItemProperty -Path $hvciKey -ErrorAction SilentlyContinue).Enabled
Write-Find "Memory Integrity (HVCI)" ($hvciVal -ne 1) `
    $(if ($hvciVal -eq 1) { "Aktiv - System geschuetzt" } else { "DEAKTIVIERT (Wert: $hvciVal)" }) `
    $(if ($hvciVal -ne 1) { "Verdaechtig: Verhindert normalerweise DMA-Angriffe auf Kernel-Code." } else { "" })
if ($hvciVal -ne 1) { Add-Finding "HVCI/Memory Integrity ist deaktiviert" }

# --- Secure Boot ---
Write-Host "   [?] Pruefe Secure Boot..." -ForegroundColor Yellow
try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    Write-Find "Secure Boot" (-not $sb) `
        $(if ($sb) { "Aktiv" } else { "DEAKTIVIERT" }) `
        $(if (-not $sb) { "Hinweis: Haeufig Teil der DMA-Vorbereitung." } else { "" })
    if (-not $sb) { Add-Finding "Secure Boot ist deaktiviert" }
} catch {
    Write-Find "Secure Boot" $true "Nicht verfuegbar / deaktiviert" ""
    Add-Finding "Secure Boot nicht verfuegbar oder deaktiviert"
}

# --- Credential Guard ---
Write-Host "   [?] Pruefe Credential Guard..." -ForegroundColor Yellow
try {
    $dg        = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
    $cgRunning = ($dg.SecurityServicesRunning -band 0x1) -ne 0
    Write-Find "Credential Guard" (-not $cgRunning) `
        $(if ($cgRunning) { "Aktiv" } else { "DEAKTIVIERT" }) `
        $(if (-not $cgRunning) { "Schuetzt LSASS - Deaktivierung erleichtert Speicherzugriff." } else { "" })
    if (-not $cgRunning) { Add-Finding "Credential Guard ist deaktiviert" }
} catch {
    Write-Host "   [!] Credential Guard WMI nicht verfuegbar." -ForegroundColor DarkYellow
}

# --- Hypervisor ---
Write-Host "   [?] Pruefe Hypervisor und Hyper-V..." -ForegroundColor Yellow
$bcdOut      = & bcdedit /enum | Out-String
$hyperLaunch = if ($bcdOut -match "hypervisorlaunchtype\s+(\S+)") { $Matches[1] } else { "nicht gefunden" }
$hvSusp      = ($hyperLaunch -ieq "Off" -or $hyperLaunch -eq "nicht gefunden")
Write-Find "Hypervisor Launch Type" $hvSusp $hyperLaunch `
    $(if ($hvSusp) { "Verdaechtig: Hypervisor gezielt deaktiviert - verhindert VBS-Start." } else { "" })
if ($hvSusp) { Add-Finding "HypervisorLaunchType ist '$hyperLaunch' - gezielt deaktiviert" }

$hvFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($hvFeature) {
    Write-Find "Hyper-V Feature" ($hvFeature.State -ne "Enabled") $hvFeature.State ""
} else {
    Write-Find "Hyper-V Feature" $true "Nicht installiert / nicht verfuegbar" ""
}

# --- Windows Defender ---
Write-Host "   [?] Pruefe Windows Defender..." -ForegroundColor Yellow
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    Write-Find "Echtzeit-Schutz (Defender)" (-not $mp.RealTimeProtectionEnabled) `
        $(if ($mp.RealTimeProtectionEnabled) { "Aktiv" } else { "DEAKTIVIERT" }) `
        $(if (-not $mp.RealTimeProtectionEnabled) { "Verdaechtig: Defender deaktiviert verhindert Erkennung von DMA-Software." } else { "" })
    if (-not $mp.RealTimeProtectionEnabled) { Add-Finding "Windows Defender Echtzeit-Schutz ist deaktiviert" }
} catch {
    Write-Find "Windows Defender" $true "Nicht verfuegbar - wahrscheinlich deaktiviert" ""
    Add-Finding "Windows Defender nicht verfuegbar - moeglicherweise entfernt"
}

# --- Spectre/Meltdown Mitigations ---
Write-Host "   [?] Pruefe Spectre/Meltdown Mitigations..." -ForegroundColor Yellow
$specKey    = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$fsOverride = (Get-ItemProperty -Path $specKey -ErrorAction SilentlyContinue).FeatureSettingsOverride
$fsMask     = (Get-ItemProperty -Path $specKey -ErrorAction SilentlyContinue).FeatureSettingsOverrideMask
$specSusp   = ($fsOverride -eq 3 -and $fsMask -eq 3)
Write-Find "Spectre/Meltdown Schutz" $specSusp `
    $(if ($specSusp) { "DEAKTIVIERT (Override=3, Mask=3)" } else { "Standard (Override=$fsOverride, Mask=$fsMask)" }) `
    $(if ($specSusp) { "Verdaechtig: Gezielte Registry-Manipulation - gaengiger DMA-Tweak." } else { "" })
if ($specSusp) { Add-Finding "Spectre/Meltdown Mitigationen manuell deaktiviert" }

# --- NetworkThrottlingIndex ---
Write-Host "   [?] Pruefe Netzwerk-Tweaks..." -ForegroundColor Yellow
$mmKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$nti   = (Get-ItemProperty -Path $mmKey -ErrorAction SilentlyContinue).NetworkThrottlingIndex
$ntiSusp = ($nti -eq 0xFFFFFFFF)
Write-Find "NetworkThrottlingIndex" $ntiSusp `
    $(if ($null -ne $nti) { "0x$([Convert]::ToString([int]$nti,16).ToUpper())" } else { "Standard" }) `
    $(if ($ntiSusp) { "Hinweis: Typischer Gaming/DMA-Tweak - allein kein Beweis." } else { "" })
if ($ntiSusp) { Add-Finding "NetworkThrottlingIndex auf 0xFFFFFFFF gesetzt" }

# ===========================================================================
# ERGEBNIS
# ===========================================================================
Write-Host ""
Write-Host "   -------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "   ERGEBNIS" -ForegroundColor Cyan
Write-Host "   -------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

if ($findings.Count -eq 0) {
    Write-Host "   [+] Keine Auffaelligkeiten gefunden." -ForegroundColor Green
    Write-Host "       Dieses System zeigt keine Anzeichen fuer DMA-Karten-Vorbereitung." -ForegroundColor DarkGray
} else {
    Write-Host "   [!] $($findings.Count) verdaechtige(r) Befund(e) gefunden:" -ForegroundColor Red
    Write-Host ""
    foreach ($f in $findings) {
        Write-Host "   [!] $f" -ForegroundColor Red
    }
    Write-Host ""
    if ($findings.Count -ge 4) {
        Write-Host "   BEWERTUNG: HOHES RISIKO" -ForegroundColor Red
        Write-Host "   Mehrere Sicherheitsmechanismen wurden gezielt deaktiviert." -ForegroundColor DarkGray
        Write-Host "   Starker Hinweis auf Vorbereitung fuer eine DMA-Karte." -ForegroundColor DarkGray
    } elseif ($findings.Count -ge 2) {
        Write-Host "   BEWERTUNG: AUFFAELLIG" -ForegroundColor Yellow
        Write-Host "   Einige Einstellungen weichen vom Windows-Standard ab." -ForegroundColor DarkGray
        Write-Host "   Koennte Gaming-Tweaks oder gezielte DMA-Vorbereitung sein." -ForegroundColor DarkGray
    } else {
        Write-Host "   BEWERTUNG: LEICHT AUFFAELLIG" -ForegroundColor Yellow
        Write-Host "   Ein einzelner Befund - allein kein sicherer Beweis." -ForegroundColor DarkGray
    }
}

Write-Host ""
Read-Host -Prompt "   Druecke ENTER zum Beenden"