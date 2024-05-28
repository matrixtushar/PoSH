<# 
.NAME
    SCCM Input Locale
.AUTHOR
    Tushar Singh
#>

$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(635,424)
$Form.text                       = "Locale Input - SCCM"
$Form.TopMost                    = $false

$Groupbox1                       = New-Object system.Windows.Forms.Groupbox
$Groupbox1.height                = 291
$Groupbox1.width                 = 613
$Groupbox1.text                  = "Select the Appropriate Options"
$Groupbox1.location              = New-Object System.Drawing.Point(13,77)

$title                           = New-Object system.Windows.Forms.Label
$title.text                      = "Locale Input - SCCM"
$title.AutoSize                  = $true
$title.width                     = 25
$title.height                    = 10
$title.location                  = New-Object System.Drawing.Point(185,19)
$title.Font                      = New-Object System.Drawing.Font('Microsoft Sans Serif',15)

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Select OS Language"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(9,43)
$Label2.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.width                 = 317
$ComboBox1.height                = 20
@('English','French','Spanish','Portuguese','German', 'Japanese','Russian', 'Slovak') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}
$ComboBox1.location              = New-Object System.Drawing.Point(264,43)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)


$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Select Location"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(9,103)
$Label3.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.width                 = 317
$ComboBox2.height                = 20
@('EMEA-FR-Harnes','EMEA-FR-GondeCourt','EMEA-FR-Herouville', 'EMEA-FR-Le Plessis', 'EMEA-FR-Rougegoutte', 'EMEA-MA-Tangier', 'EMEA-RU-Kaluga', 'EMEA-ES-Igualada', 'EMEA-SK-Nitra', 'EMEA-ES-Medina', 'EMEA-ES-Salceda','EMEA-ES-El Prat', 'NCSA-BR-Arbor', 'NCSA-BR-Gravatai', 'NCSA-AR-Otto Krause', 'APAC-IN-Pune', 'APAC-JP-Yokohama', 'APAC-TH-Rayong') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$ComboBox2.location              = New-Object System.Drawing.Point(264,103)
$ComboBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Label4                          = New-Object system.Windows.Forms.Label
$Label4.text                     = "Computer Name"
$Label4.AutoSize                 = $true
$Label4.width                    = 25
$Label4.height                   = 10
$Label4.location                 = New-Object System.Drawing.Point(9,163)
$Label4.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$textbox1                        = New-Object System.Windows.Forms.TextBox
$textbox1.text                   = ""
$textbox1.AutoSize               = $false
$textbox1.width                  = 317
$textbox1.height                 = 25
$textbox1.location               = New-Object System.Drawing.Point(264,163)
$textbox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$checkBox1                       = New-Object System.Windows.Forms.CheckBox
$checkBox1.Location              = New-Object System.Drawing.Point(9,183)
$checkBox1.Text                  = "Install Office 2019"
$checkBox1.AutoSize              = $false
$checkBox1.Width                 = 200
$checkBox1.Height                = 100
$checkBox1.Visible               = $true
$checkBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$button1                         = New-Object System.Windows.Forms.Button
$button1.Location                = New-Object System.Drawing.Point(480,215)
$button1.Text                    = "Install"
$button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$button1.Width                   = 100
$button1.Height                  = 30

$Form.controls.AddRange(@($Groupbox1,$title))
$Groupbox1.controls.AddRange(@($Label2,$ComboBox1,$Label3, $ComboBox2, $Label4, $textbox1, $checkBox1, $button1))

Function Get-SystemSerialNb ()

{
    $SerialNumber = (Get-WmiObject -class win32_bios).SerialNumber
    return $SerialNumber
}


Function Get-Region([string]$strSelectedString)
{
    $region = $strSelectedString.Substring(0,4)
    return $region
}

Function Get-Country([string]$strSelectedString)
{
    $country = $strSelectedString.Substring(5,2)
    return $country
}

Function Get-CountrySite([string]$selectedString)
{
    $countrysite = $selectedString.Substring(5)
    return $countrysite
}

Function Check-MachineType ()
{
    $hasBattery = @(Get-CimInstance -ClassName Win32_Battery).Count -gt 0
    if ($hasBattery)
    {
        $machineType = "L"
    }
    else
    {
        $ComputerSystemInfo = (Get-WmiObject -Class Win32_ComputerSystem).Model
        if ($ComputerSystemInfo -eq "VMware Virtual Platform")
        {
            $machineType = "V"
        }

        else 
        {
            $machineType = "D"
        }
    }
    
    return $machineType
}

#events

$ComboBox2.Add_TextChanged({  
    
    $country = Get-Country $ComboBox2.SelectedItem.ToString()
    $serialnumber = Get-SystemSerialNb
    $machineType = Check-MachineType
    $textbox1.Text = "$country$machineType$serialnumber"

})

$Button1.Add_Click({  
    
    
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $tsenv.Value("language") = "English"
    
    $installOffice2019 = $checkBox1.CheckState
    if($installOffice2019 -eq "Checked")
    {
        $installOffice2019 = $true
    }

    else
    {
        $installOffice2019 = $false
    }

    $region = Get-Region $ComboBox2.SelectedItem.ToString()
    $country = Get-Country $ComboBox2.SelectedItem.ToString()
    $countrysite = Get-CountrySite $ComboBox2.SelectedItem.ToString()
    $language = $ComboBox1.Text
    $hostname = $textbox1.Text

    <#Write-Host $installOffice2019
    Write-Host $region
    Write-Host $textbox1.Text
    Write-Host $country
    Write-Host $language
    Write-Host $countrysite
    #>

    #Set the Task Sequence Variables here

    $tsenv.Value("OSDCOMPUTERNAME") = $hostname    #validated setting the global variable
    $tsenv.Value("regionvalue") = $language             #validated
    $tsenv.Value("Office2019") = $installOffice2019     #doesn't exist - added as a provision
    $tsenv.Value("sitecode") = $countrysite             #validated - used for installing site specific software


    if(($language -ne $null) -and ($countrysite -ne $null) -and ($hostname.Length -ne 0) -and ($hostname.Length -le 15))
    {
        $Form.Close()
    }
})

#region Logic 

#endregion

[void]$Form.ShowDialog()
