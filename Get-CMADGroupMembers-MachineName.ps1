# Script to extract members of an AD Group and then get their SCCM machine names
$server = "cm_dbserver"
$database = "CM_SiteCode"
$users = Get-ADGroup "AD_Group_Name" -Properties Member | Select-Object -Expand Member | Get-ADUser -Property UserPrincipalName

ForEach ($user in $users)
{

    Write-Host $user.SamAccountName -ErrorAction Ignore
    $username = $user.SamAccountName
    $query = "select  all SMS_R_System.Name0 from vSMS_R_System AS SMS_R_System INNER JOIN Computer_System_DATA AS SMS_G_System_COMPUTER_SYSTEM ON SMS_G_System_COMPUTER_SYSTEM.MachineID = SMS_R_System.ItemKey   where (SMS_R_System.Client0 = 1 AND SMS_G_System_COMPUTER_SYSTEM.UserName00 like N'%$username%')"
    $result = Invoke-SqlCmd -ServerInstance $server -Database $database -Query $query
    $result | Format-Table -AutoSize
}
