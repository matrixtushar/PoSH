# Gets a complete list of approved patches from a WSUS server.
# Execute the script on the target WSUS server else use different parameters in getUpdateServer() method.


$Group = 'All Computers'
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
$ComputerTargetGroups = $wsus.GetComputerTargetGroups()

$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
#$UpdateScope.ApprovedStates = 'Approved'
$UpdateScope.ApprovedStates = 'LatestRevisionApproved'
$UpdateScope.IncludedInstallationStates = 'Installed'

##Classifications
#Get all Classifications for specific Classifications
$updateClassifications = $wsus.GetUpdateClassifications() | Where {
  $_.Title -Match "Critical Updates|Security Updates"
}
$UpdateScope.Classifications.AddRange($updateClassifications)

$ComputerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$TargetGroup = $ComputerTargetGroups | Where {$_.Name -eq $Group}
[void]$computerscope.ComputerTargetGroups.Add($TargetGroup)

$Clients = $WSUS.GetComputerTargets($computerscope)
$Updates = $Clients.GetUpdateInstallationInfoPerUpdate($UpdateScope) | Select -Unique -ExpandProperty UpdateID
$strFilePath = "C:\Users\psaxena\Desktop\ApprovedKBs.txt"
New-Item -Path $strFilePath -ItemType File

ForEach ($Item in $Updates) {    
    $Update = $wsus.GetUpdate($Item)
    Add-Content -Path $strFilePath -Value $Update.KnowledgebaseArticles
    Write-Host $Update.KnowledgebaseArticles
    
}
