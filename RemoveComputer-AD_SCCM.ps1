$PSScriptDir = Split-Path $Script:MyInvocation.MyCommand.Path
$log = "$PSScriptDir\ClientRemoval.log"
$date = Get-Date -Format "dd-MM-YYYY hh:mm:ss"

"=========== Script Executed on Date $date =========================" | Out-File $log -Append
Set-Location "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin"
Import-Module .\ConfigurationManager
Set-Location "<SiteName>:"

ForEach ($client in Get-Content $PSScriptDir"\ClientList.txt")
{
    Remove-CMDevice -DeviceName $client -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-File $log -Append
    "$date [INFO] $client Removed from SCCM" | Out-File $log -Append

    Get-ADComputer -Identity $client | Remove-ADObject -Recursive -Confirm:$false -ErrorAction SilentlyContinue
    "$date [INFO] $client Removed from AD" | Out-File $log -Append
}
