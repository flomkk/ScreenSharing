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
    [PSCustomObject]@{ Id = 1; Name = "CHH Viewer"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/CHHViewer.ps1" }
    [PSCustomObject]@{ Id = 2; Name = "Check Screen Recording"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/CheckScreenRecording.ps1" }
    [PSCustomObject]@{ Id = 3; Name = "PCIE Device View"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/PCIEDeviceView.ps1" }
    [PSCustomObject]@{ Id = 4; Name = "Windows Defender Events"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/WinDefEvt.ps1" }
    [PSCustomObject]@{ Id = 5; Name = "Windows Serials Check"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/WinSerialsCheck.ps1" }
    [PSCustomObject]@{ Id = 6; Name = "Analyse Starter"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/analyse_starter.ps1" }
    [PSCustomObject]@{ Id = 7; Name = "Clean FiveM Cache"; Url = "https://raw.githubusercontent.com/flomkk/ScreenSharing/refs/heads/main/clean_fivem_cache.ps1" }
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
    Write-Host ""
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

    if ($null -eq $input) { return $null }

    $inputTrim = $input.Trim()

    if ($inputTrim -eq '') { return $null }

    $lower = $inputTrim.ToLowerInvariant()

    if ($lower -in @('q','quit','exit')) {
        return 'quit'
    }

    # if ($lower -in @('a','all')) {
    #     foreach ($opt in $options) {
    #         Run-RemoteScript -Url $opt.Url -Label $opt.Name
    #     }
    #     return $null
    # }

    # if ($lower -in @('m','multi','multiple')) {
    #     $multi = Read-Host "Enter comma separated option numbers (example: 1,3,5)"
    #     if ($null -eq $multi) { return $null }
    #     $inputTrim = $multi.Trim()
    # }

    $tokens = $inputTrim -split '[,\s]+' | Where-Object { $_ -ne '' }

    $ids = [System.Collections.ArrayList]::New()

    foreach ($t in $tokens) {
        if ($t -match '^\d+$') {
            $n = [int]$t
            $match = $options | Where-Object { $_.Id -eq $n } | Select-Object -First 1
            if ($null -ne $match) {
                $ids.Add($n) | Out-Null
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

    $uniqueIds = @()
    foreach ($i in $ids) {
        if ($uniqueIds -notcontains $i) { $uniqueIds += $i }
    }

    foreach ($id in $uniqueIds) {
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
