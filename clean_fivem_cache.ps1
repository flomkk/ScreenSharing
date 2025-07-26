$host.ui.RawUI.WindowTitle = "FiveM Cache Cleaner - Made by flomkk"
Clear-Host

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

Write-Host "Beende FiveM Prozesse..." -ForegroundColor Cyan
Get-Process FiveM, FXServer -ErrorAction SilentlyContinue | Stop-Process -Force

$cachePath = Join-Path $env:LocalAppData "FiveM\FiveM.app\cache"

if (Test-Path $cachePath) {
    Write-Host "Leere Cache-Verzeichnis: $cachePath" -ForegroundColor Green
    Remove-Item $cachePath -Recurse -Force
    Write-Host "Cache erfolgreich geleert." -ForegroundColor Green
} else {
    Write-Host "Cache-Verzeichnis nicht gefunden: $cachePath" -ForegroundColor Yellow
}

Write-Host ""
Read-Host -Prompt "Drücke ENTER zum Beenden"
