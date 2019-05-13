Initialize-Tpm
$blv = Get-BitlockerVolume -MountPoint C:
Add-BitlockerKeyProtector -MountPoint C: -TpmProtector

For ([int] $i = 0; $i -le 1; $i++)
{
	$keytype = $blv.KeyProtector[$i].KeyProtectorType
	Write-Host $keytype
	
	If ($keytype -match "RecoveryPassword")
	{
		Remove-BitlockerKeyProtector -MountPoint C: -KeyProtectorId $blv.KeyProtector[$i].KeyProtectorId
	}
}
Add-BitlockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
C:\WINDOWS\System32\manage-bde.exe -on C:
$blv = Get-BitLockerVolume -MountPoint C:
Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $blv.KeyProtector[1].KeyProtectorId
