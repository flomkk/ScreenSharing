$host.ui.RawUI.WindowTitle = "FiveM Cache Cleaner - Made by flomkk"
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

Write-Host "  Beende FiveM Prozesse..." -ForegroundColor Yellow
Get-Process FiveM, FXServer -ErrorAction SilentlyContinue | Stop-Process -Force

$cachePath = Join-Path $env:LocalAppData "FiveM\FiveM.app\cache"
Write-Host "  Suche nach FiveM in $cachePath" -ForegroundColor Yellow

if (Test-Path $cachePath) {
    Write-Host "  Leere Cache-Verzeichnis: $cachePath" -ForegroundColor Yellow
    Remove-Item $cachePath -Recurse -Force
    Write-Host "  Cache erfolgreich geleert." -ForegroundColor Green
} else {
    Write-Host "  Cache-Verzeichnis nicht gefunden. Hast du FiveM wo anders Installiert?" -ForegroundColor Red
}

Write-Host ""
Read-Host -Prompt "  Drücke ENTER zum Beenden"
