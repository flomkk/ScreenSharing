$host.ui.RawUI.WindowTitle = "PCIE Device Check - Made by flomkk"
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

Write-Host "   [-] Checking for devices..." -ForegroundColor Yellow
$drivers = Get-CimInstance Win32_PnPSignedDriver | Select-Object DeviceID, DriverVersion

Write-Host "   [-] Generating results..." -ForegroundColor Yellow
$results = Get-CimInstance Win32_PnPEntity |
    Where-Object { $_.Caption -match "PCI" -or $_.DeviceID -match "PCI" } |
    ForEach-Object {
        $deviceID = $_.DeviceID
        $caption = $_.Caption
        $driverVersion = ($drivers | Where-Object { $_.DeviceID -eq $deviceID }).DriverVersion

        if ($deviceID -match "VEN_([0-9A-Fa-f]+).*DEV_([0-9A-Fa-f]+)") {
            $vendorID = $matches[1]
            $devID = $matches[2]
        } else {
            $vendorID = "N/A"
            $devID = "N/A"
        }

        $deviceType = $_.PNPClass
        $manufacturer = $_.Manufacturer
        # $location = $_.Location

        [PSCustomObject]@{
            "Device Name"    = $caption
            "Vendor ID"      = $vendorID
            "Device ID"      = $devID
            "Driver Version" = $driverVersion
            "Device Type"    = $deviceType
            "Manufacturer"   = $manufacturer
        #     "Location"       = $location
        }
    }
	
Write-Host "   [!] Done" -ForegroundColor Green 
$results | Out-GridView -Title "PCI Devices with Vendor, Device Info, and Location"

Read-Host -Prompt "`n`n   [>] Press Enter to exit"

