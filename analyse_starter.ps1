$host.ui.RawUI.WindowTitle = "Analyse Starter - Made by flomkk"
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

Write-Host -ForegroundColor White "                  Made by flomkk - " -NoNewLine
Write-Host -ForegroundColor White "discord.gg/narcocity"
Write-Host ""

$browserQueries = @(
    "brave.exe","chrome.exe","firefox.exe","msedge.exe","opera.exe",
    "operagx.exe","safari.exe","tor.exe","avastbrowser.exe","vivaldi.exe",
    "maxthon.exe","iexplore.exe","chromium.exe","epicbrowser.exe","yandex.exe",
    "seamonkey.exe","palemoon.exe","waterfox.exe","lunascape.exe",
    "comodo_dragon.exe","slimbrowser.exe","mullvadbrowser.exe"
)

$discordQueries = @("Discord.exe","DiscordPTB.exe","DiscordCanary.exe")

# For products whose on-disk EXE name differs from the query name, try these additional candidates.
# Wildcards are supported and will resolve to the newest file by LastWriteTime.
$extraCandidates = @{
  "opera.exe"          = @("$env:ProgramFiles\Opera\launcher.exe", "$env:ProgramFiles(x86)\Opera\launcher.exe")
  "operagx.exe"        = @("$env:ProgramFiles\Opera GX\launcher.exe", "$env:ProgramFiles(x86)\Opera GX\launcher.exe")
  "yandex.exe"         = @("$env:ProgramFiles\Yandex\YandexBrowser\Application\browser.exe", "$env:ProgramFiles(x86)\Yandex\YandexBrowser\Application\browser.exe")
  "epicbrowser.exe"    = @("$env:ProgramFiles\Epic Privacy Browser\Application\epic.exe", "$env:ProgramFiles(x86)\Epic Privacy Browser\Application\epic.exe")
  "comodo_dragon.exe"  = @("$env:ProgramFiles\Comodo\Dragon\dragon.exe", "$env:ProgramFiles(x86)\Comodo\Dragon\dragon.exe")
  "maxthon.exe"        = @("$env:ProgramFiles\Maxthon\Bin\Maxthon.exe", "$env:ProgramFiles(x86)\Maxthon\Bin\Maxthon.exe")
  "slimbrowser.exe"    = @("$env:ProgramFiles\SlimBrowser\slimbrowser.exe", "$env:ProgramFiles(x86)\SlimBrowser\slimbrowser.exe")
  "safari.exe"         = @("$env:ProgramFiles\Safari\Safari.exe", "$env:ProgramFiles(x86)\Safari\Safari.exe")
  "tor.exe"            = @("$env:LocalAppData\Tor Browser\Browser\firefox.exe", "$env:ProgramFiles\Tor Browser\Browser\firefox.exe", "$env:ProgramFiles(x86)\Tor Browser\Browser\firefox.exe")
  "chromium.exe"       = @("$env:ProgramFiles\Chromium\Application\chrome.exe", "$env:ProgramFiles(x86)\Chromium\Application\chrome.exe")
  "mullvadbrowser.exe" = @(
      "$env:LocalAppData\Mullvad\MullvadBrowser\Release\mullvadbrowser.exe",
      "$env:LocalAppData\MullvadBrowser\mullvadbrowser.exe",
      "$env:LocalAppData\Mullvad Browser\mullvadbrowser.exe",
      "$env:LocalAppData\Mullvad Browser\Browser\firefox.exe",
      "$env:LocalAppData\MullvadBrowser\Browser\firefox.exe",
      "$env:ProgramFiles\Mullvad Browser\mullvadbrowser.exe",
      "$env:ProgramFiles(x86)\Mullvad Browser\mullvadbrowser.exe",
      "$env:ProgramFiles\Mullvad Browser\Browser\firefox.exe",
      "$env:ProgramFiles(x86)\Mullvad Browser\Browser\firefox.exe"
  )
  # Discord variants often use Squirrel; include direct exe in versioned folders
  "Discord.exe"        = @("$env:LocalAppData\Discord\Discord.exe", "$env:LocalAppData\Discord\app-*\Discord.exe")
  "DiscordPTB.exe"     = @("$env:LocalAppData\DiscordPTB\DiscordPTB.exe", "$env:LocalAppData\DiscordPTB\app-*\DiscordPTB.exe")
  "DiscordCanary.exe"  = @("$env:LocalAppData\DiscordCanary\DiscordCanary.exe", "$env:LocalAppData\DiscordCanary\app-*\DiscordCanary.exe")
}

# Some apps require launching via a helper (Squirrel Update.exe).
# Each entry is "path|args". The first existing path wins.
$specialLaunchers = @{
  "Discord.exe"       = @(
      "$env:LocalAppData\Discord\Update.exe|--processStart `"Discord.exe`"",
      "$env:ProgramFiles\Discord\Update.exe|--processStart `"Discord.exe`"",
      "$env:ProgramFiles(x86)\Discord\Update.exe|--processStart `"Discord.exe`""
  )
  "DiscordPTB.exe"    = @(
      "$env:LocalAppData\DiscordPTB\Update.exe|--processStart `"DiscordPTB.exe`""
  )
  "DiscordCanary.exe" = @(
      "$env:LocalAppData\DiscordCanary\Update.exe|--processStart `"DiscordCanary.exe`""
  )
}

# -------------------- Helpers --------------------

function Expand-CandidatePath {
  param([Parameter(Mandatory=$true)][string]$PathSpec)
  $expanded = [Environment]::ExpandEnvironmentVariables($PathSpec)
  if ($expanded -match '[\*\?]') {
    $items = Get-ChildItem -Path $expanded -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($items -and $items[0].FullName) { return $items[0].FullName }
  } else {
    if (Test-Path -LiteralPath $expanded) {
      return (Resolve-Path -LiteralPath $expanded).Path
    }
  }
  return $null
}

function Get-AppPathFromRegistry {
  param([Parameter(Mandatory=$true)][string]$ExecutableName)
  $regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExecutableName",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\$ExecutableName",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExecutableName"
  )
  foreach ($key in $regKeys) {
    if (Test-Path -LiteralPath $key) {
      try {
        $item = Get-Item -LiteralPath $key -ErrorAction Stop
        $defaultPath = $item.GetValue('')
        if ($defaultPath -and (Test-Path -LiteralPath $defaultPath)) { return $defaultPath }
        $folderPath = $item.GetValue('Path')
        if ($folderPath) {
          $candidate = Join-Path $folderPath $ExecutableName
          if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
      } catch { }
    }
  }
  return $null
}

function Resolve-AppPath {
  param([Parameter(Mandatory=$true)][string]$ExecutableName)

  # 1) Try PATH / registered app paths (Get-Command consults both)
  $cmd = Get-Command -Name $ExecutableName -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }

  # 2) Try App Paths registry keys directly
  $regPath = Get-AppPathFromRegistry -ExecutableName $ExecutableName
  if ($regPath) { return $regPath }

  # 3) Try known alternate paths for this query (if any)
  if ($extraCandidates.ContainsKey($ExecutableName)) {
    foreach ($cand in $extraCandidates[$ExecutableName]) {
      $resolved = Expand-CandidatePath -PathSpec $cand
      if ($resolved) { return $resolved }
    }
  }

  # 4) Last resort: attempt common install roots (quick direct check)
  $quickFolders = @("$env:ProgramFiles","$env:ProgramFiles(x86)","$env:LocalAppData","$env:AppData") |
                  Where-Object { $_ -and (Test-Path -LiteralPath $_) }
  foreach ($root in $quickFolders) {
    $direct = Join-Path $root $ExecutableName
    if (Test-Path -LiteralPath $direct) { return $direct }
  }

  return $null
}

function Is-ProcessRunning {
  param([Parameter(Mandatory=$true)][string]$ExecutableName)
  $procName = [System.IO.Path]::GetFileNameWithoutExtension($ExecutableName)
  try { $null = Get-Process -Name $procName -ErrorAction Stop; return $true } catch { return $false }
}

function Start-AppIfAvailable {
  param([Parameter(Mandatory=$true)][string]$ExecutableName)

  if (Is-ProcessRunning -ExecutableName $ExecutableName) {
    Write-Host "[SKIP] Already running: $ExecutableName" -ForegroundColor Yellow
    return $true
  }

  # 0) Special launchers (e.g., Discord via Update.exe)
  if ($specialLaunchers.ContainsKey($ExecutableName)) {
    foreach ($entry in $specialLaunchers[$ExecutableName]) {
      $parts = $entry -split '\|', 2
      $launcherPath = [Environment]::ExpandEnvironmentVariables($parts[0])
      $launcherArgs = if ($parts.Count -gt 1) { $parts[1] } else { $null }
      if ($launcherPath -and (Test-Path -LiteralPath $launcherPath)) {
        try {
          Start-Process -FilePath $launcherPath -ArgumentList $launcherArgs | Out-Null
          Write-Host "[ OK ] Launched (special): $ExecutableName via $launcherPath $launcherArgs" -ForegroundColor Green
          return $true
        } catch { }
      }
    }
  }

  # 1) Direct path resolution
  $path = Resolve-AppPath -ExecutableName $ExecutableName
  if ($path) {
    try {
      Start-Process -FilePath $path | Out-Null
      Write-Host "[ OK ] Launched: $ExecutableName ($path)" -ForegroundColor Green
      return $true
    } catch { }
  }

  # 2) Try by name (PATH/App Paths resolution might still succeed)
  try {
    Start-Process -FilePath $ExecutableName -ErrorAction Stop | Out-Null
    Write-Host "[ OK ] Launched by name: $ExecutableName" -ForegroundColor Green
    return $true
  } catch {
    Write-Host "[FAIL] Not found or couldn't start: $ExecutableName" -ForegroundColor Red
    return $false
  }
}

# -------------------- Main --------------------

Write-Host "=== Launching browsers ==="
$browserLaunched = 0
foreach ($exe in $browserQueries) {
  if (Start-AppIfAvailable -ExecutableName $exe) { $browserLaunched++ }
}

Write-Host "`n=== Launching Discord variants ==="
$discordLaunched = 0
foreach ($exe in $discordQueries) {
  if (Start-AppIfAvailable -ExecutableName $exe) { $discordLaunched++ }
}

Write-Host "`n=== Summary ==="
Write-Host ("Browsers launched/skipped running: {0}/{1}" -f $browserLaunched, $browserQueries.Count)
Write-Host ("Discord launched/skipped running: {0}/{1}"  -f $discordLaunched, $discordQueries.Count)
