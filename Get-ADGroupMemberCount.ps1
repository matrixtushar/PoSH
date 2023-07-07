# Prepared by Akshita Kukreja 7-July-2023

Import-Module ActiveDirectory
$ADUserGroup = '<DomainName>\<ADGroupName>'
$ADGroupName =  $ADUserGroup.Split('\')[1]
$Domain = (Get-ADDomainController -DomainName $ADUserGroup.Split('\')[0]  -Discover).Domain
$ADGroupMembers = (Get-ADGroup -Identity $ADGroupName -Server $Domain -properties Member).Member
$ADGroupMembers.count
