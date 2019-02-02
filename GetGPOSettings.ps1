
# ---------------------------------------------------------------------------------------------------------
# Script Name:                    GetGPOSettings.ps1
# Script Version:                 1.00.01
# Purpose:                        GUI to extract an HTML based report of all configured settings for a GPO
# Script Author:                  Tushar Singh (matrixtushar@gmail.com)
# Revision History:               1.00.00            Initial Build   03-Feb-2019
#                                 1.00.01            Error Handling in case machine not in domain
# ---------------------------------------------------------------------------------------------------------

$PSScriptDir = Split-Path $Script:MyInvocation.MyCommand.Path
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '719,328'
$Form.text                       = "GPO Extractor"
$Form.TopMost                    = $false

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Group Policy Setting Extraction Tool"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(104,40)
$Label1.Font                     = 'Microsoft Sans Serif,24'

$PictureBox1                     = New-Object system.Windows.Forms.PictureBox
$PictureBox1.width               = 420
$PictureBox1.height              = 135
$PictureBox1.location            = New-Object System.Drawing.Point(150,-50)
$PictureBox1.imageLocation       = "Yourcompanylogo.jpg"
$PictureBox1.SizeMode            = [System.Windows.Forms.PictureBoxSizeMode]::zoom
$Domain                          = New-Object system.Windows.Forms.Label
$Domain.text                     = "Domain"
$Domain.AutoSize                 = $true
$Domain.width                    = 25
$Domain.height                   = 10
$Domain.location                 = New-Object System.Drawing.Point(37,110)
$Domain.Font                     = 'Microsoft Sans Serif,10'

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Select Domain"
$ComboBox1.width                 = 205
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(158,110)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'


$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Group Policy"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(37,173)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Select GPO"
$ComboBox2.width                 = 420
$ComboBox2.height                = 20
$ComboBox2.location              = New-Object System.Drawing.Point(158,173)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'
$ComboBox2.Enabled               = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Extract"
$Button1.width                   = 151
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(158,249)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "Cancel"
$Button2.width                   = 142
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(366,249)
$Button2.Font                    = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($Label1,$PictureBox1,$Domain,$ComboBox1,$Label2,$ComboBox2,$Button1,$Button2))

try
  {
    $sDomains = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() | Select-Object -ExpandProperty domains
    foreach ($sDomain in $sDomains)
    {
        $ComboBox1.Items.Add($sDomain)
    }


  }
  catch
  {
    $Combobox1.Enabled = $false
    $Combobox2.Enabled = $false
    [System.Windows.Forms.MessageBox]::Show("Error Enumerating Domains of the forest. Ensure that the computer is joined to a domain or has network connectivity.","Error")
   }

    $ComboBox1.Add_TextChanged({ domainselect })
    $Button1.Add_Click({ Extract })
    $Button2.Add_Click({ Cancel })


$Form.ShowDialog()


function domainselect
{
    if($ComboBox1.Text.Length -ne $null)
{
    $ComboBox2.Enabled = $true
    #populate combobox2 with GPOs
    $selDomain = $ComboBox1.SelectedItem
    #[System.Windows.Forms.MessageBox]::Show($sDomain)
    try{
        $GPOs = Get-GPO -All -Domain $selDomain | Select-Object -ExpandProperty DisplayName
        foreach ($GPO in $GPOs)
        {
            $ComboBox2.Items.Add($GPO)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error Connecting to Domain.")
        $Combobox2.Enabled = $false
    }
    
 }
}

function Extract
{
    if($ComboBox2.Text.Length -ne $null)
    {
        #[System.Windows.Forms.MessageBox]::Show($ComboBox2.Text)
        try
        {
            Get-GPO -Domain $ComboBox1.SelectedItem -Name $ComboBox2.SelectedItem | % {$_.GenerateReport('html') | Out-File "$($_.DisplayName).htm"}
            [System.Windows.Forms.MessageBox]::Show("Report Extracted Successfully for " + $ComboBox2.SelectedItem, "Task Completed")
        }
        catch
        {
            [System.Windows.Forms.MessageBox]::Show("Error Extracting Report for " + $ComboBox2.SelectedItem, "Error")
        }
    }
}

function Cancel
{
    $Form.Close()
}
