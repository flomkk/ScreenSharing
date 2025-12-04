$inputFile1 = [System.IO.Path]::Combine($env:APPDATA, 'Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
$inputFile2 = [System.IO.Path]::Combine($env:APPDATA, 'Roaming\Microsoft\Windows\PowerShell\PSReadLine\Windows Powershell ISE Host_history.txt')

$host.ui.RawUI.WindowTitle = "CHH Viewer - Made by flomkk"
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

Write-Host -ForegroundColor White "                    Made by flomkk - " -NoNewLine
Write-Host -ForegroundColor White "discord.gg/narcocity"
Write-Host ""

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Warning " Please Run This Script as Admin."
    Start-Sleep 10
    Exit
}

try {
    $data1 = Get-Content -Path $inputFile1 -ErrorAction Stop
    if ($data1) {
        Write-Host "`n[ConsoleHost History] $($data1.Count) Einträge geladen." -ForegroundColor Cyan
        $data1 | Out-GridView -Title "ConsoleHost History - $env:USERNAME"
    } else {
        Write-Host "Keine Daten in ConsoleHost History gefunden." -ForegroundColor Yellow
    }
} catch {
    Write-Host -ForegroundColor Red "Fehler beim Lesen der ConsoleHost-Datei: $_"
}

try {
    $data2 = Get-Content -Path $inputFile2 -ErrorAction Stop
    if ($data2) {
        Write-Host "`n[ISE Host History] $($data2.Count) Einträge geladen." -ForegroundColor Cyan
        $data2 | Out-GridView -Title "ISE Host History - $env:USERNAME"
    } else {
        Write-Host "Keine Daten in ISE Host History gefunden." -ForegroundColor Yellow
    }
} catch {
    Write-Host -ForegroundColor Red "Fehler beim Lesen der ISE-Datei: $_"
}


