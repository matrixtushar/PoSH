
# Uncomment the line below if running in an environment where script signing is 
# required.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Site configuration
$SiteCode = "<Put Site Code Here>" # Site code 
$ProviderMachineName = "<Put FQDN of Site Server Name here>" # SMS Provider machine name

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

Function Write-Log($strMessage)
{
    $strLogfilePath = "$PSScriptRoot\SCCM_MassLoad.log"
    $date = (Get-Date).ToString()
    $strMessage = $date + "    " + $strMessage

    If (Test-Path $strLogfilePath)
    {
        Add-Content -Path $strLogfilePath -Value "$strMessage"
    }
    Else
    {
        New-Item -Path $strLogfilePath -ItemType file
        Add-Content -Path $strLogfilePath -Value "$strMessage"
    }
}

Function CheckDeviceinAD ($strDeviceName)
{
    $isDeviceinAD = $false

    try
    {
    
        if ($isDeviceinAD = Get-ADComputer -Identity $strDeviceName -ErrorAction Ignore)
        {
            $isDeviceinAD = $true
        }
    }
   catch
   {
     $isDeviceinAD = $false
   }
    return $isDeviceinAD
}

Function CheckDeviceinCM ($strDeviceName)
{
    $isDeviceinCM = $false
    if ($isDeviceinCM = Get-CMDevice -Name $strDeviceName)
    {
        #Write-Host $isDeviceinCM
        $isDeviceinCM = $true
        
    }
    else{
        
        $isDeviceinCM = $false
    }
    return $isDeviceinCM

}

#Begin execution of script
Write-Log "-------------- BEGIN SCRIPT -------------------------"
Write-Log "Script for Device MassLoad started by user $ENV:USERNAME"
Write-Log "Fetching Configuration Settings from Config.xml"
#Read XML to generate variables

try
{

    [xml] $xDoc = Get-Content -Path "$PSScriptRoot/Config.xml" -ErrorAction Stop

    #Read Configs
    [string] $strInputFile = $xDoc.xml.Section.SiteConfig.InputFile
    [string] $ou = $xDoc.xml.Section.SiteConfig.OU
    [string] $site = $xdoc.xml.Section.SiteConfig.Site
    [string] $adgroup = $xdoc.xml.Section.SiteConfig.AdGroup
    [string] $sccmcol = $xDoc.xml.Section.SiteConfig.SCCMCol

    $strDeviceInfo = Import-csv -Path $strInputFile.Trim()
    $ou = $ou.Trim()
    $site = $site.Trim()
    $adgroup = $adgroup.Trim()
    $sccmcol = $sccmcol.Trim()

    Write-Log "Input File Specified Path is :: $strInputFile"
    Write-Log "OU Specified is :: $ou"
    Write-Log "Site Specified is :: $site"
    Write-Log "AD Group Specified is :: $adgroup"
    Write-Log "SCCM OSD Collection Specified is :: $sccmcol"

    Foreach ($deviceinfo in $strDeviceInfo)
    {
        $strDevice = $($deviceinfo.MachineName)
        $uuid = $($deviceinfo.UUID)

        Write-Log "Operation Starting for Device   ::::::::: $strDevice :::::::::"
        Write-Log "Device UUID :: $uuid"
        Write-Log "Checking if $strDevice exists in AD"
        $bDeviceinAD = CheckDeviceinAD($strDevice)

        #if machine already exists in AD, do nothing
        if($bDeviceinAD)
        {
            Write-Log "Computer $strDevice found in AD :: No need to create object. Proceed with Group Membership"
        }

        Else
        {
            try
            {
                Write-Log "Computer $strDevice NOT found in AD :: Proceeding to create AD Computer object."
                New-ADComputer -Name $strDevice -Path $ou -Enabled:$true
                Write-Log "Computer $strDevice created in AD at location $ou :: Proceeding to assign Group Membership."
                $bDeviceinAD = $true
                Write-Log "Device in AD flag [bDeviceinAD] set to :: TRUE"
            }
            catch
            {
                Write-Log "FAILED :: Computer $strDevice could not be created."
                $bDeviceinAD = $false
                Write-Log "Device in AD flag [bDeviceinAD] set to :: FALSE"
            }
        }

        try
        {
            if ($bDeviceinAD)
            {
                Add-ADGroupMember -Identity $adgroup -Members $strDevice"$" -Confirm:$false
                Write-Log "Computer $strDevice added to AD group $adgroup."
            }
        }
        catch
        {
            Write-Log "FAILED :: Computer $strDevice could not be added to AD group $adgroup."
        }

        $bDeviceinCM = CheckDeviceinCM($strDevice)
        Write-Log "Checking if $strDevice exists in SCCM"
        If ($bDeviceinCM)
        {
            Write-Log "Machine Already Exists in SCCM."
        }
        Else 
        {
            Write-Log "Machine not found in SCCM :: Proceeding to create computer object in SCCM."

            try
            {
                #Import-CMComputerInformation -ComputerName $strDevice -SMBiosGuid $uuid -CollectionName "All Systems"
                Import-CMComputerInformation -ComputerName $strDevice -SMBiosGuid $uuid -CollectionName $sccmcol
                Write-Log "SUCCESS :: $strDevice Imported in SCCM and added Membership to OSD Collection $sccmcol"
            }

            Catch
            {
                Write-Log "ERROR :: Failed to import $strDevice into SCCM."
            }
    
        }
     }
 } #end of main try block
 Catch
 {
    Write-Log "FATAL ERROR :: Configuration File Not Found. Script will Terminate."
    Exit-PSSession
 }
