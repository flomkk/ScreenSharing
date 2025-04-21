$host.ui.RawUI.WindowTitle = "CHH Viewer - Made by flomkk"
Clear-Host
Write-Host ""
Write-Host -ForegroundColor Magenta @"
    _       ___      _____           _       __    
   | |     / (_)___ / ___/___  _____(_)___ _/ /____
   | | /| / / / __ \\__ \/ _ \/ ___/ / __ `/ / ___/
   | |/ |/ / / / / /__/ /  __/ /  / / /_/ / (__  ) 
   |__/|__/_/_/ /_/____/\___/_/  /_/\__,_/_/____/  
"@

Write-Host -ForegroundColor White "        Made by flomkk - " -NoNewLine
Write-Host -ForegroundColor White "discord.gg/narcocity"
Write-Host ""

$winuuid = (Get-WmiObject Win32_ComputerSystemProduct).UUID
$systemuuid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

Write-Host -ForegroundColor Cyan " Windows UUID     : $winuuid"
Write-Host -ForegroundColor Cyan " System User UUID : $systemuuid"

Write-Host ""
Pause
