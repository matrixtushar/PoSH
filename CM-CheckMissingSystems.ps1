#
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '1/3/2023 11:31:32 AM'.

# Site configuration
$SiteCode = "<Site_Code>" # Site code 
$ProviderMachineName = "<sccm_server_name>" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$sysList = Get-Content -Path ".\SCCM_Missing_Devices.txt"

#Create a csv file to load the data
New-Item -Path ".\MissingSystemReport.csv" -ItemType File

foreach ($system in $sysList)
{
    $cmDevice = Get-CMDevice -Name $system -Resource | Select-Object Name, ClientVersion
    $output= "$($system),$($cmDevice.Name),$($cmDevice.ClientVersion)" | Out-File -FilePath ".\MissingSystemReport.csv" -Append
    
    
}
