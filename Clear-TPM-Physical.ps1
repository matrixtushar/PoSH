# Script Name:           Clear-TPM-Physical.ps1
# Script Purpose:        To Clear the TPM from BIOS (User Assisted)
# Script Version:        1.00.00
# Script Author:         Tushar Singh, IBM Malaysia

# Function Declarations
Function Write-Log
{
    Param([string] $sLogType,[string] $message)
    $sLogFilePath = "C:\Logs\ClearTPM.log"

    #Check if directory exists
    $sLogDir = Split-Path -Path $sLogFilePath -Parent
    If(Test-Path -Path $sLogDir)
    {
        #Directory exists
        #Check for Log file
        if (Test-Path -Path $sLogFilePath) {
            #File also exists. Start writing to the log file without creating a new one
        }
        else {
            #Directory exists but log file does not exist. Create one.
            New-Item -Path $sLogFilePath -ItemType File -Force
        }
    }
    else {
        #Directory and Log file do not exist. Create them.
        New-Item -Path $sLogDir -ItemType Directory -Force
        New-Item -Path $sLogFilePath -ItemType File -Force
    }

    #Write to the log file
    $sDate = Get-Date -Format "dd-MM-yyyy HH:mm"
    $sEntry = "$sDate [$sLogType] :: $message"
    Add-Content -Path $sLogFilePath -Value $sEntry -Force
}
Function Get-BitlockerStatus()
{
    $sProtectionStatus = 'Off'
    try {
        $oBitlocker = Get-BitLockerVolume
        $sProtectionStatus = $oBitlocker.ProtectionStatus
        return $sProtectionStatus
    }
    catch {
        return $sProtectionStatus
    }
}

Function fCheckFirstRun()
{
    $sRegPath = "HKLM:\SOFTWARE\BLEnabler"
    $bReturnFlag = $false
    try {
         if (Test-Path -Path $sRegPath) {
             $bReturnFlag = $true
         }   
        else {
            $bReturnFlag = $false
        }
        return $bReturnFlag
    }
    catch {
        return $bReturnFlag
    }
}
Function Write-Reg
{
    Param([string] $sRegName , [string] $sRegVal)
    $sRegKeyPath = "HKLM:\SOFTWARE\BLEnabler"
    New-ItemProperty -Path $sRegKeyPath -Name $sRegName -Value $sRegVal -Force
}

Function Set-ClearTPM
{
    $oTPM = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftTpm" -Class "Win32_TPM"
    $retSetOper = $oTPM.SetPhysicalPresenceRequest(14)
    return $retSetOper.ReturnValue
}

Function Get-Response
{
    $oTPM = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftTpm" -Class "Win32_TPM"
    $resReturn = $oTPM.GetPhysicalPresenceResponse()
    return $resReturn.Response
}

Function Execute-BitLockerEnable
{
    try
    {
        Initialize-Tpm
        $blv = Get-BitlockerVolume -MountPoint C:
        Add-BitlockerKeyProtector -MountPoint C: -TpmProtector

        For ([int] $i = 0; $i -le 1; $i++)
        {
	        $keytype = $blv.KeyProtector[$i].KeyProtectorType
	        Write-Host $keytype
	
	        If ($keytype -match "RecoveryPassword")
	        {
		        Remove-BitlockerKeyProtector -MountPoint C: -KeyProtectorId $blv.KeyProtector[$i].KeyProtectorId
	        }
        }
        Add-BitlockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
        C:\WINDOWS\System32\manage-bde.exe -on C:
        $blv = Get-BitLockerVolume -MountPoint C:
        Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $blv.KeyProtector[1].KeyProtectorId
        return 0
    }
    Catch {
        return 1
    }
}

#Main Script
Write-Log "Info" "Begin Executing Script"
Write-Log "Info" "Checking Bitlocker Status"
$BitlockerStatus = Get-BitlockerStatus
Write-Log "Output" "Bitlocker Protection Status is $($BitlockerStatus.ToString())"
If ($BitlockerStatus -eq 'On')
{
    Write-Log "Info" "Bitlocker Protection is On. Script will exit."
    $this.Quit
}
else {
    #The logic begins here
    # Check if the program is running for the first time
    Write-Log "Info" "Bitlocker Protection is found to be Off. Proceeding..."
    Write-Log "Info" "Check if script running for the first time."
    $bisFirstRun = fCheckFirstRun
    Write-Log "Output" "First Run Check $($bIsFirstRun.ToString())"
    if ($bisFirstRun) {
        Write-Log "Info" "Script is NOT running for the first time"
        
        try {
            #Check if the user cleared the TPM GetPhysicalPresenceResponse()
            Write-Log "Info" "Check if the user has cleared the TPM"
            Write-Log "Info" "Executing Function GetPhysicalPresenceResponse()"
            $retResponse = Get-Response
            Write-Log "Output" "GetPhysicalPresenceReponse() returned $retResponse"
            if($retResponse -eq 0)
            {
                #The user cleared the TPM
                #Need to proceed with enabling bitlocker
                Write-Log "Info" "User cleared the TPM"
                try
                {
                    Write-Log "Info" "Initiating Bitlocker Enable Step"
                    $outBitLockerEnable = Execute-BitLockerEnable
                    Write-Log "Output" "Bitlocker Enable Step Returned : $outBitLockerEnable"
                    if ($outBitLockerEnable -eq 0)
                    {
                        #enable went fine
                        Write-Log "Info" "Bitlocker Enabled Successfully"
                        #Remove every registry setting
                        Write-Log "Info" "Removing the Registry Keys HKLM\SOFTWARE\BLEnabler"
                        Remove-Item -Path "HKLM:\SOFTWARE\BLEnabler" -Force
                        #Remove the Run key as its no longer needed
                        Write-Log "Info" "Removing the Run Key Value as it is not longer needed to execute the script again"
                        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "ClearTPM" -Force
                    }
                    else {
                        #problem with Bitlocker
                        Write-Log "Error" "Problem Starting Bitlocker Encryption"
                        throw "Problem Starting Bitlocker Encryption"
                    }
                }
                catch {
                    Write-Log "Error" "An Exception Occurred while attempting to enable Bitlocker"
                    #Write-Host "Problem Starting Bitlocker Encryption"
                }
            }
            else {
                # The user cancelled the request
                Write-Log "Info" "The user has Cancelled the request to Clear the TPM"
                # Set request again to clear the TPM if RunCount is less than equal to 5
                Write-Log "Info" "Raising Request Flag to Clear TPM if Count less than 6 attempts"
                $sRunCount = Get-ItemProperty -Path "HKLM:\SOFTWARE\BLEnabler" -Name "RunCount"
                $sRunCount = $sRunCount.RunCount
                $sRunCount = $sRunCount.RunCount
                Write-Log "Output" "The total number of times the script has run is $sRunCount"
                [int]$intRunCount = [convert]::ToInt32($sRunCount,10)
                if($intRunCount -le 5)
                {
                    Write-Log "Info" "Setting Clear TPM Request Flag. User will get prompt in BIOS at next reboot"
                    $ReSetClear = Set-ClearTPM
                    Write-Log "Output" "Status from Raised flag $ReSetClear"
                    if($ReSetClear -eq 0)
                    {
                        Write-Log "Info" "Clear TPM Request flag raised successfully."
                        Write-Log "Info" "Setting Registry Value SetClearTPM to 14"
                        Write-Reg "SetClearTPM" "14"
                        $intRunCount = $intRunCount + 1
                        Write-Reg "RunCount" $intRunCount
                        Write-Log "Info" "Updated RunCount to $intRunCount"
                    }
                    else {
                        #Write-Host "Mar Gaya"
                        Write-Log "Error" "An Error Occurred in Raising the Request Flag to Clear TPM"
                    }

                }
                else{
                    #Exceeded maximum number of trials
                    Write-Log "Info" "Exceeded the number of trials to clear TPM. Script will exit."
                    $this.Quit
                }
            }
        }
        catch {
            Write-Log "Error" "An Exception Occurred after the machine rebooted."
            #Write-Host "Something went wrong after reboot"
        }
    }
    else {
        #Program running for the first time
        Write-Log "Info" "The script is running for the first time."
        #Create the registry entry
        Write-Log "Info" "Creating Registry Structure"
        try {
            New-Item -Path "HKLM:\SOFTWARE" -Name "BLEnabler" -Force
            New-ItemProperty -Path "HKLM:\SOFTWARE\BLEnabler" -Name "IsRun" -Value "1"
            Write-Log "Info" "Registry structure created. Proceeding to set the request flag to Clear TPM."
            #Write-Host "Setting Bitlocker Flag"
            $RetSetClear = Set-ClearTPM
            Write-Log "Output" "Set-ClearTPM returned value $RetSetClear"
            if ($RetSetClear -eq 0) {
                Write-Log "Info" "Creating registry SetClearTPM with value 14 (Clear - Enable - Activate)"
                Write-Reg "SetClearTPM" "14"
                Write-Log "Info" "Updating RunCount to 1"
                Write-Reg "RunCount" "1"
                #write the Run key
                Write-Log "Info" "Creating a Run Key to ensure the script starts again after reboot."
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "ClearTPM" -Value "C:\Temp\Clear-TPM-Physicalv1.1.CMD" -Force
            }
            else {
                #Write-Host "Mar gaya"
                Write-Log "Error" "An Error Occurred while Setting the Request Flag to Clear the TPM for the first time."
            }
        }
        catch {
            #Write-Host "Something went wrong"
            Write-Log "Error" "An Exception Occurred while executing the script."
        }
    }
}
