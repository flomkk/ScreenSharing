$host.ui.RawUI.WindowTitle = "Screen Sharing Assistant - by flomkk"
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

$options = @(
    @{ Id = 1; Name = "ConsoleHost History Viewer"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/CHHViewer.ps1" }
    @{ Id = 2; Name = "Check Screen Recording"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/CheckScreenRecording.ps1" }
    @{ Id = 3; Name = "PCIE Device View"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/PCIEDeviceView.ps1" }
    @{ Id = 4; Name = "Windows Defender Events"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/WinDefEvt.ps1" }
    @{ Id = 5; Name = "Windows Serials Check"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/WinSerialsCheck.ps1" }
    @{ Id = 6; Name = "Analyse Starter"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/analyse_starter.ps1" }
    @{ Id = 7; Name = "Clean FiveM Cache"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/clean_fivem_cache.ps1" }
)

function Show-Menu {
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
    foreach ($opt in $options) {
        Write-Host (" [{0}] {1}" -f $opt.Id, $opt.Name)
    }
    # Write-Host " [A] Run ALL scripts"
    # Write-Host " [M] Multiple selection (e.g., 1,3,5)"
    Write-Host " [Q] Quit"
    Write-Host ""
}

function Run-RemoteScript {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Label = $null
    )

    if ($Label) {
        Write-Host ""
        Write-Host "-> Executing: $Label" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "-> Executing remote script: $Url" -ForegroundColor Cyan
    }

    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

        $scriptText = Invoke-RestMethod -Uri $Url -UseBasicParsing
        if (-not $scriptText) {
            throw "Downloaded script is empty or failed."
        }

        & {
            Invoke-Expression $scriptText
        }

        Write-Host "-> Finished: $Label" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR running remote script ($Label): $_" -ForegroundColor Red
    }
    finally {
        Write-Host ""
        Write-Host "Press Enter to continue..." -NoNewLine
        [void][System.Console]::ReadLine()
    }
}

function Parse-And-RunSelection {
    param([string]$input)

    $inputTrim = $input.Trim().ToLowerInvariant()

    if ($inputTrim -in @('q','quit','exit')) {
        return 'quit'
    }

    # if ($inputTrim -in @('a','all')) {
    #     foreach ($opt in $options) {
    #         Run-RemoteScript -Url $opt.Url -Label $opt.Name
    #     }
    #     return $null
    # }

    # if ($inputTrim -in @('m','multi','multiple')) {
    #     $multi = Read-Host "Enter comma separated option numbers (example: 1,3,5)"
    #     $inputTrim = $multi.Trim()
    # }

    $tokens = $inputTrim -split '[,\s]+' | Where-Object { $_ -ne '' }

    $ids = @()
    foreach ($t in $tokens) {
        if ($t -match '^\d+$') {
            $n = [int]$t
            if ($options.Id -contains $n) {
                $ids += $n
            } else {
                Write-Host "Invalid option number: $n" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Invalid token skipped: '$t'" -ForegroundColor Yellow
        }
    }

    if ($ids.Count -eq 0) {
        Write-Host "No valid selections were made." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return $null
    }

    $ids = $ids | Get-Unique

    foreach ($id in $ids) {
        $opt = $options | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($null -ne $opt) {
            Run-RemoteScript -Url $opt.Url -Label $opt.Name
        }
    }

    return $null
}

while ($true) {
    Show-Menu
    $selection = Read-Host "Choose an option (number, A for all, M for multiple, Q to quit)"
    $result = Parse-And-RunSelection -input $selection
    if ($result -eq 'quit') {
        Write-Host "Exiting... Goodbye!" -ForegroundColor Cyan
        break
    }
}
