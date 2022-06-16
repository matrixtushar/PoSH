# --------------------------------------------------------------------------------------------
# Script Name: Get-MAs_with_Desc_False.ps1
# Script Version: 1.00.00
# Script Author: Tushar Singh
# Script Purpose: To fetch All Manual Activities (MAs) with description false
# Requirement Background: MAs with description false are generated automatically and they are supposed to be cleaned up.
# Instructions: Change the file path to save the output of the MAs
# Change Log:
# Version               Changes
# -------               --------
# 1.00.00               Initial Version
# ---------------------------------------------------------------------------------------------


$MAStatusCompleted = Get-SCSMEnumeration -Name ActivityStatusEnum.Completed
$Filter = "Status = $MAStatusCompleted.Id"
$maClass = Get-SCSMClass -Name System.WorkItem.Activity.ManualActivity

Write-Host $MAStatusCompleted

$objects = Get-SCSMObject -Class $maClass -Filter "Description -eq 'false'" -SortBy LastModified
foreach ($object in $objects)
{
   #$objectProp = $object.GetProperties()
   #$objectProp.Item(3).Name.Value
   $stringBuilder = "$($object.Name,',',$object.Title,',',$object.CreatedDate,',',$object.Description,',', $object.Status)"
   $stringBuilder
   
   # Change the file path
   $stringBuilder | Out-File -FilePath DRIVE:\<FOLDER>\MAFalse.txt -Append -Force -NoClobber
}
