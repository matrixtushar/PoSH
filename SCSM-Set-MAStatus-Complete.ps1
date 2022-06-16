# --------------------------------------------------------------------------------------------
# Script Name: SCSM-Set-MAStatus-Complete.ps1
# Script Version: 1.00.00
# Script Author: Tushar Singh
# Script Purpose: To mark a list of MAs as Complete
# Requirement Background: Some dormant MAs might exist in the system that are not skipped / complete.
#                         this script can take an input of the list of MAs and marks them completed.
# Change Log:
# Version               Changes
# -------               --------
# 1.00.00               Initial Version
# ---------------------------------------------------------------------------------------------

$maClass = Get-SCSMClass -Name System.WorkItem.Activity.ManualActivity

# change the file path
$MAList = Get-Content -Path <Drive>:<Folder>\In_MAsToClose.txt

foreach($MAListItem in $MAList)
{
    $MAobjects = Get-SCSMObject -Class $maClass -Filter "Id -eq $MAListItem"
    foreach ($objMA in $MAobjects)
    {
        $objMA.Name
        $objMA | Set-SCSMObject -Property Status -Value "Completed"
    }
}
