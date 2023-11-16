$domains = Get-ADForest | Select-Object -ExpandProperty Domains
$userData = @()
 
foreach ($domain in $domains) {
    Write-Host "Getting users from $domain"
    $list = Get-Content -Path "C:\Users\vivek.kumar\Desktop\aduser.txt"
    foreach ($emailAddress in $list){
        $user = Get-ADUser -Filter "EmailAddress -eq '$emailAddress'" -Properties Name, EmailAddress, DirectReports -Server $domain
 
        if ($user -ne $null) {
            # Create a custom object to store the required user data
            $userObject = [PSCustomObject]@{
                Domain         = $domain
                Name           = $user.Name
                EmailAddress   = $user.EmailAddress
                DirectReports  = $user.DirectReports.Count
            }
 
            # Add the user data to the array
            $userData += $userObject
        }
 
    }
}
 
# Export the user data to CSV
$userData | Export-Csv -Path "C:\Users\vivek.kumar\Desktop\ADUsers1.csv" -NoTypeInformation
