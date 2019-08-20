# Script Name: Get-WSUSApprGroupsbyKB.ps1
# Script Author: Tushar Singh [matrixtushar@gmail.com]
# Script Purpose: Gets the Computer Target Groups in WSUS where the specified KB has been approved
# Script Business Usage: The script can be used to monitor whether selected KBs have been approved on desired target groups
# ----------------------

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer('WSUS_Server_Name',$false)

Function Get-TargetGrpName
{
Param([string]$sTargetID)
$group = $wsus.GetComputerTargetGroups() | ? {$_.ID -eq $sTargetID}
$sTargetGroupName = $group | Select -ExpandProperty Name
return $sTargetGroupName
}



$updates = $wsus.SearchUpdates('4512489')
#$approval = $updates[0].GetUpdateApprovals()

$approvals = $updates[0].GetUpdateApprovals()
    ForEach ($approval in $approvals)
    {
        $groupname = Get-TargetGrpName $approval.ComputerTargetGroupID
        Write-Host $groupname
    }
