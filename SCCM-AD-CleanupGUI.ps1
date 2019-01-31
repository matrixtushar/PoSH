$PSScriptDir = Split-Path $Script:MyInvocation.MyCommand.Path
$log = "$PSScriptDir\ClientRemoval.log"
$date = Get-Date -Format "dd-MM-yyyy hh:mm:ss"

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '539,389'
$Form.text                       = "Computer Object Cleanup Utility - " + [char]0x00A9 + "IBM"
$Form.TopMost                    = $false

$Title                           = New-Object system.Windows.Forms.Label
$Title.text                      = "Computer Object Cleanup Utility"
$Title.AutoSize                  = $true
$Title.width                     = 25
$Title.height                    = 10
$Title.location                  = New-Object System.Drawing.Point(157,26)
$Title.Font                      = 'Microsoft Sans Serif,14'

$PictureBox1                     = New-Object system.Windows.Forms.PictureBox
$PictureBox1.width               = 129
$PictureBox1.height              = 52
$PictureBox1.location            = New-Object System.Drawing.Point(-15,9)
$PictureBox1.imageLocation       = "$PSScriptDir\Tata.png"
$PictureBox1.SizeMode            = [System.Windows.Forms.PictureBoxSizeMode]::zoom
$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Machine Name:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(17,104)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Clean-up From:"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(20,254)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "SCCM"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 95
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(157,254)
$CheckBox1.Font                  = 'Microsoft Sans Serif,10'

$CheckBox2                       = New-Object system.Windows.Forms.CheckBox
$CheckBox2.text                  = "AD"
$CheckBox2.AutoSize              = $false
$CheckBox2.width                 = 107
$CheckBox2.height                = 20
$CheckBox2.location              = New-Object System.Drawing.Point(291,254)
$CheckBox2.Font                  = 'Microsoft Sans Serif,10'

$Submit                          = New-Object system.Windows.Forms.Button
$Submit.text                     = "Submit"
$Submit.width                    = 91
$Submit.height                   = 30
$Submit.location                 = New-Object System.Drawing.Point(183,310)
$Submit.Font                     = 'Microsoft Sans Serif,10'

$Cancel                          = New-Object system.Windows.Forms.Button
$Cancel.text                     = "Cancel"
$Cancel.width                    = 88
$Cancel.height                   = 30
$Cancel.location                 = New-Object System.Drawing.Point(330,310)
$Cancel.Font                     = 'Microsoft Sans Serif,10'

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $true
$TextBox1.width                  = 328
$TextBox1.height                 = 128
$TextBox1.location               = New-Object System.Drawing.Point(156,98)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($Title,$PictureBox1,$Label1,$Label2,$CheckBox1,$CheckBox2,$Submit,$Cancel,$TextBox1))

$Submit.Add_Click({ OnClick })
$Cancel.Add_Click({ OnCancel })
$Form.ShowDialog()


function OnClick {
 Try{
   #[System.Windows.MessageBox]::Show($TextBox1.Text)
   
    "=========== Script Executed on Date $date =========================" | Out-File $log -Append

   $bSCCM = 0
   $bAD = 0

   #Get the state of the checkboxes
   $SCCM = $CheckBox1.CheckState
   $AD = $CheckBox2.CheckState

   [string[]] $pcname = $TextBox1.Lines
   
   #check if empty
   If ($Textbox1.Lines.Count -eq 0)
   {
        [System.Windows.MessageBox]::Show("No machine name provided.","Error") 
        $this.quit()
   }

   If (($SCCM -ne "Checked") -and ($AD -ne "Checked"))
   {
    [System.Windows.MessageBox]::Show("Select atleast one system to remove object from.","Error")
    $this.quit()
   }
   
   #Actual Execution begins here-on

   Set-Location "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin"
   Import-Module .\ConfigurationManager -ErrorAction Stop
   Set-Location "<SiteCode>" -OutVariable $Location

   #[System.Windows.MessageBox]::Show("$Location")

   For ($i=0; $i -lt $pcname.Length; $i++)
   {
    #[System.Windows.MessageBox]::Show($pcname[$i])
    
    #Code for logging and deletion from SCCM and AD

    If ($SCCM -eq "Checked")
    {
        #write the code to delete from SCCM
        Remove-CMDevice -DeviceName $pcname[$i] -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-File $log -Append
        "$date [INFO] $pcname[$i] Removed from SCCM" | Out-File $log -Append

        #[System.Windows.MessageBox]::Show("Machine " + $pcname[$i] + " is deleted from SCCM")
        $bSCCM = 1
    }

    If ($AD -eq "Checked")
    {
        #write the code to delete from AD
        Get-ADComputer -Identity $pcname[$i] | Remove-ADObject -Recursive -Confirm:$false -ErrorAction SilentlyContinue
        "$date [INFO] $pcname[$i] Removed from AD" | Out-File $log -Append
        #[System.Windows.MessageBox]::Show("Machine " + $pcname[$i] + " is deleted from AD")
        $bAD = 1
    }

    }
    
    If (($SCCM -and $bSCCM) -or ($AD -and $bAD))
    {
        [System.Windows.MessageBox]::Show("All Tasks Completed Successfully", "Completed")
        $Form.Close()
    }
   }
   Catch
   {
    
   }
  }


function OnCancel {

    #[System.Windows.MessageBox]::Show('Cancel')
    $Form.Close()

}
