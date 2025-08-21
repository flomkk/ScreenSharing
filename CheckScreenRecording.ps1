param(
    [string[]]$ProcessNames = @(
        'obs64', 'obs',
        'MedalClient', 'MedalEncoder',
        'Streamlabs', 'StreamlabsOBS',
        'XboxGameBar','GameBar','GameBarFTService',
        'NVIDIA Share', 'nvspcap64', 'nvcontainer',
        'AMDRSServ', 'RadeonSoftware',
        'FlashBackAgent','FlashBackRecorder',
        'CamtasiaStudio','CamRecorder',
        'bandicam','bdcam',
        'fraps',
        'ApowerREC',
        'Ezvid',
        'XSplitBroadcaster','XSplit.Core','XSplitGamecaster',
        'Screenrec',
        'LoiLoGameRecorder',
        'krisp'
    )
)

$host.ui.RawUI.WindowTitle = "Check Screen Recording - Made by flomkk"
Clear-Host

Write-Host ""
Write-Host -ForegroundColor Magenta @"
   ███╗   ██╗ █████╗ ██████╗  ██████╗ ██████╗      ██████╗██╗████████╗██╗   ██╗
   ████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔═══██╗    ██╔════╝██║╚══██╔══╝╚██╗ ██╔╝
   ██╔██╗ ██║███████║██████╔╝██║     ██║   ██║    ██║     ██║   ██║    ╚████╔╝
   ██║╚██╗██║██╔══██║██╔══██╗██║     ██║   ██║    ██║     ██║   ██║     ╚██╔╝
   ██║ ╚████║██║  ██║██║  ██║╚██████╗╚██████╔╝    ╚██████╗██║   ██║      ██║
   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝      ╚═════╝╚═╝   ╚═╝      ╚═╝
"@

Write-Host -ForegroundColor White "        Made by flomkk - " -NoNewLine
Write-Host -ForegroundColor White "discord.gg/narcocity"
Write-Host ""

$ProcessDescriptions = @{
    'obs64' = 'OBS Studio (64-bit)'
    'obs' = 'OBS Studio'
    'MedalClient' = 'Medal Screen Recorder'
    'Streamlabs' = 'Streamlabs'
    'StreamlabsOBS' = 'Streamlabs OBS'
    'XboxGameBar' = 'Xbox Game Bar'
    'GameBar' = 'Xbox Game Bar'
    'GameBarFTService' = 'Xbox Game Bar'
    'NVIDIA Share' = 'NVIDIA Share'
    'nvspcap64' = 'NVIDIA Share / ShadowPlay'
    'nvcontainer' = 'NVIDIA ShadowPlay / NVIDIA App Screen Recorder'
    'AMDRSServ' = 'AMD ReLive'
    'RadeonSoftware' = 'AMD Radeon Software'
    'FlashBackAgent' = 'FlashBack Recorder'
    'FlashBackRecorder' = 'FlashBack Recorder'
    'CamtasiaStudio' = 'Camtasia Studio'
    'CamRecorder' = 'Camtasia Recorder'
    'bandicam' = 'Bandicam'
    'bdcam' = 'Bandicam'
    'fraps' = 'Fraps'
    'ApowerREC' = 'ApowerREC'
    'Ezvid' = 'Ezvid'
    'XSplitBroadcaster' = 'XSplit Broadcaster'
    'XSplit.Core' = 'XSplit Core'
    'XSplitGamecaster' = 'XSplit Gamecaster'
    'Screenrec' = 'ScreenRec'
    'LoiLoGameRecorder' = 'LoiLo Game Recorder'
}

function Get-ActiveScreenRecordingProcesses {
    param (
        [string[]]$Names
    )
    $found = @()
    foreach ($name in $Names) {
        try {
            $procs = Get-Process -Name $name -ErrorAction Stop
            $found += $procs
        } catch {
            # Process not found, ignore
        }
    }
    return $found
}

$activeProcs = Get-ActiveScreenRecordingProcesses -Names $ProcessNames

if ($activeProcs) {
    Write-Host "Gefundene aktive Bildschirmaufnahme-Prozesse:" -ForegroundColor Red
    $activeProcs | ForEach-Object {
        $desc = $ProcessDescriptions[$_.Name]
        if (-not $desc) { $desc = "Unbekannt / Nicht zugeordnet" }
        [PSCustomObject]@{
            Beschreibung = $desc
            Prozess      = $_.Name
            PID          = $_.Id
            # Pfad         = $_.Path
        }
    } | Format-Table -AutoSize
} else {
    Write-Host "Keine aktiven Bildschirmaufnahme-Prozesse gefunden." -ForegroundColor Green
}
