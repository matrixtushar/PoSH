$OuName = "ou=<OUNAME>-Users,ou=<OUNAME>,dc=abc,dc=com"
$users = Get-ADUser -Server "<DCServername>" -Filter '*' -SearchBase $OuName -Properties *
foreach ($user in $users)
{
    $user
}
