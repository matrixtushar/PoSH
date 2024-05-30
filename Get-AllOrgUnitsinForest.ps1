$forest = Get-ADForest
$domains = $forest.Domains
 
New-Item -ItemType File -Path ".\oulist.txt"
 
foreach($domain in $domains)
{
    $dc = Get-ADDomainController -Discover -DomainName $domain
    $dc.HostName
    foreach($srv in $dc.HostName)
    {
        $dn = Get-ADOrganizationalUnit -Filter * -Server $srv
        Add-Content -Value $dn.DistinguishedName -Path ".\oulist.txt"

 
    }
}
