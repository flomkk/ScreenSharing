$host.ui.RawUI.WindowTitle = "WinSerials - Made by flomkk"
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

# ==== UUIDs and Unique Identifiers ====
$winuuid       = (Get-WmiObject Win32_ComputerSystemProduct).UUID
$biosUUID      = (Get-WmiObject Win32_BIOS).SerialNumber
$baseboardSN   = (Get-WmiObject Win32_BaseBoard).SerialNumber
$cpuID         = (Get-WmiObject Win32_Processor | Select-Object -First 1).ProcessorId
$productID     = (Get-WmiObject Win32_OperatingSystem).SerialNumber
$mac           = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -ne $null -and $_.IPEnabled } | Select-Object -First 1).MACAddress
$sid           = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$machineGuid   = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid'

# ==== Output ====
Write-Host -ForegroundColor Cyan " Windows UUID           : $winuuid"
Write-Host -ForegroundColor Cyan " BIOS UUID              : $biosUUID"
Write-Host -ForegroundColor Cyan " Baseboard Serial       : $baseboardSN"
Write-Host -ForegroundColor Cyan " Processor ID (CPU ID)  : $cpuID"

# ==== Disk Serial Numbers ====
Write-Host -ForegroundColor Cyan " Disk Serial Numbers    :"
$disks = Get-WmiObject Win32_PhysicalMedia
$i = 0
foreach ($disk in $disks) {
    if ($disk.SerialNumber) {
        $serial = $disk.SerialNumber.Trim()
        Write-Host -ForegroundColor DarkCyan ("  Disk $($i):`t$serial")
        $i++
    }
}

Write-Host -ForegroundColor Cyan " Windows Product ID     : $productID"
Write-Host -ForegroundColor Cyan " MAC Address            : $mac"
Write-Host -ForegroundColor Cyan " System SID             : $sid"
Write-Host -ForegroundColor Cyan " Machine GUID           : $machineGuid"

Write-Host ""
Pause
