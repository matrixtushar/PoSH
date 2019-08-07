#Displays the approved patches on a specific target group from a specific date along with its .cab file path
#Replace WSUSServerName with actual server name and Target_Group_Name with WSUS Target Group Name

[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer("WSUSServerName",$false)
$group = $wsus.GetComputerTargetGroups() | ? {$_.Name -like '*<Target_Group_Name*'}
Write-Host $group.Name

$updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$updatescope.ApprovedStates = "LatestRevisionApproved"
$updatescope.ApprovedComputerTargetGroups.Add($group)
$approvals = $wsus.GetUpdateApprovals($updatescope)
Write-Host "I am here"
Write-Host $approvals.Count

foreach ($approval in $approvals)
{
    if(($wsus.GetUpdate($approval.UpdateId).Title -like '*Windows 8.1*') -and ($wsus.GetUpdate($approval.UpdateId).Title -like '*Update*') -and ($wsus.GetUpdate($approval.UpdateId).ArrivalDate -gt '01/07/2019 12:00:00 AM'))
    {
        Write-Host "I am here now"
        Write-Host $wsus.GetUpdate($approval.UpdateId).Title
        $uris = $wsus.GetUpdate($approval.UpdateId).GetInstallableItems() | select -Expand Files
        foreach ($uri in $uris)
        {
            if ($uri.FileUri -like '*.cab')
            {
                Write-Host $uri.FileUri
            }
        }
    }
}
