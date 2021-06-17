$userlist = Get-Content -Path "Path to text file containing user names"
foreach ($user in $userlist)
{
    #Write-Host $user
    $email = Get-ADUser -Identity $user -Properties * | Select-Object EmailAddress
    Write-Host $user,',',$email.EmailAddress
    }
