Function Write-Log()
{
  param([string] [Parameter (Mandatory = $true)]$strLogType , [string] [Parameter (Mandatory = $true)]$strMessage
  $date = Get-Date -Format "ddMMyyyy"
  $sLogPath = "LogfilePath\$date.log"
  
  if(!(Test-Path -Path $sLogPath))
  {
    New-Item -Path $sLogPath -ItemType File
  }
  
  $sLogMsg = "$(Get-Date) :: [$strLogType] ::    $strMessage"
  Add-Content -Path $sLogPath -Value $sLogMsg
}
