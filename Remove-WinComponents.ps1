# Script to Remove Games & Non-Enterprize Components from Windows 10 Endpoints
# Script Version 1.00.00
# Author: Tushar Singh

Function Write-Log()
{
  param([string] [Parameter (Mandatory = $true)]$strLogType , [string] [Parameter (Mandatory = $true)]$strMessage)
  $date = Get-Date -Format "ddMMyyyy"
  $sLogPath = "C:\Logs\"
  
  if(!(Test-Path -Path $sLogPath))
  {
    New-Item -Path $sLogPath -ItemType Directory
  }

  $sLogFilePath = "C:\Logs\OSD_WinComponentRemoval.log"
  
  if(!(Test-Path -Path $sLogFilePath))
  {
    New-Item -Path $sLogFilePath -ItemType File
  }
  
  $sLogMsg = "$(Get-Date) :: [$strLogType] ::    $strMessage"
  Add-Content -Path $sLogFilePath -Value $sLogMsg
}


Write-Log "Info" "Attempting to Remove Solitaire Collection"
#Remove Solitaire Collection
try 
    {

        Get-AppxPackage *solitairecollection* | Remove-AppxPackage -AllUsers
        Write-Log "Success" "Successfully Removed Solitaire from the machine"
    }
    catch
    {
        Write-Log "Error" "Failed to Remove Solitaire"
    }


Write-Log "Info" "Attempting to Remove XBOX"
#Remove XBOX
try 
    {

        Get-AppxPackage Microsoft.XBoxapp | Remove-AppxPackage -AllUsers
        #Get-AppxPackage *xbox* | Remove-AppxPackage -AllUsers
        Write-Log "Success" "Successfully Removed XBOX from the machine"
    }
    catch
    {
        Write-Log "Error" "Failed to Remove XBOX"
    }

Write-Log "Info" "Removing Microsoft OneNote Component"

#Remove OneNote since we see duplicate applications, one from office and one as a Windows component.
# Removing Windows Component
try 
    {

        Get-AppxPackage *microsoft.office.onenote* | Remove-AppxPackage
        Write-Log "Success" "Successfully Removed OneNote from the machine"
    }
    catch
    {
        Write-Log "Error" "Failed to Remove XBOX"
    }
