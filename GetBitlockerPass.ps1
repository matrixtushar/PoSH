Function GetPass([string] $strMachineName)
{
    $adcomputer = Get-ADComputer -Identity $strMachineName -Property 'msTPM-TpmInformationForComputer'
    $oBitlocker = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $adcomputer.DistinguishedName -Properties 'msFVE-RecoveryPassword' | Select-Object -Last 1
    $bitLockerPass = $oBitlocker.'msFVE-RecoveryPassword'

    $tb_pass.Text = $bitLockerPass
}

Function ClearForm()
{
   $tb_pcname.Text = ""
   $tb_pass.Text = ""
}


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '506,262'
$Form.text                       = "Bitlocker Recovery Password"
$Form.TopMost                    = $false

$WinForm1                        = New-Object system.Windows.Forms.Form
$WinForm1.ClientSize             = '629,219'
$WinForm1.text                   = "Form"
$WinForm1.TopMost                = $false

$l_MachineName                   = New-Object system.Windows.Forms.Label
$l_MachineName.text              = "Machine Name"
$l_MachineName.AutoSize          = $true
$l_MachineName.width             = 25
$l_MachineName.height            = 10
$l_MachineName.location          = New-Object System.Drawing.Point(33,28)
$l_MachineName.Font              = 'Microsoft Sans Serif,10'

$tb_pcname                       = New-Object system.Windows.Forms.TextBox
$tb_pcname.multiline             = $false
$tb_pcname.width                 = 199
$tb_pcname.height                = 20
$tb_pcname.location              = New-Object System.Drawing.Point(194,23)
$tb_pcname.Font                  = 'Microsoft Sans Serif,10'

$l_pass                          = New-Object system.Windows.Forms.Label
$l_pass.text                     = "BitLocker Pass"
$l_pass.AutoSize                 = $true
$l_pass.width                    = 25
$l_pass.height                   = 10
$l_pass.location                 = New-Object System.Drawing.Point(33,92)
$l_pass.Font                     = 'Microsoft Sans Serif,10'

$tb_pass                         = New-Object system.Windows.Forms.TextBox
$tb_pass.multiline               = $true
$tb_pass.width                   = 202
$tb_pass.height                  = 85
$tb_pass.location                = New-Object System.Drawing.Point(194,85)
$tb_pass.Font                    = 'Microsoft Sans Serif,10'

$b_ok                            = New-Object system.Windows.Forms.Button
$b_ok.text                       = "Submit"
$b_ok.width                      = 100
$b_ok.height                     = 30
$b_ok.location                   = New-Object System.Drawing.Point(196,203)
$b_ok.Font                       = 'Microsoft Sans Serif,10'

$b_clear                         = New-Object system.Windows.Forms.Button
$b_clear.text                    = "Clear"
$b_clear.width                   = 100
$b_clear.height                  = 30
$b_clear.location                = New-Object System.Drawing.Point(310,203)
$b_clear.Font                    = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($l_MachineName,$tb_pcname,$l_pass,$tb_pass,$b_ok,$b_clear))


$b_ok.Add_Click({GetPass($tb_pcname.Text)})
$b_clear.Add_Click({ClearForm})

$Form.ShowDialog()
