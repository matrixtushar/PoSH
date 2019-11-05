#Script Name:     Export-CMQueryOutput.ps1
#Script Ver:      1.01.00
#Script Author:   Tushar Singh, matrixtushar@gmail.com
#Script Purpose:  This script can export the results of the specified SCCM query into a formatted CSV File
#Script Usage:    GUI Based Script, launch to view a form.
#                 Fill in the FQDN of the SCCM server
#                 Fill in the Site Code
#                 Key in the approximate name of the query you want to execute.
#                     This should correspond to the actual name of the query created in SCCM.
#                     The name may or may not be the exact name. e.g if you have a query in SCCM called "Bitlocker Machines"
#                                                                    then you can key in Bitlocker or the full name Bitlocker Machines.
#                 Click on Validate to get the matching queries in SCCM to the name you specified.
#                      This will fetch the matching queries and provide them in the list.
#                 Select the query that you wish to execute from the list.
#                 Click on browse to specify a filename of the CSV file and the location.
#                 Click on Export to begin the export of the results in the query.
#                 Status of the operation being performed will be visible in the status area.
# Dependencies:   1. Script must be executed on the same system where the SMS Provider is installed.
#                 2. User executing the script must have query execution rights on the SCCM server.
#                 3. User executing the script must have write permissions on the folder where the csv file will be exported.
# Feedback:       To write in to matrixtushar@gmail.com for feedback, improvements, issues and ofcourse, appreciations.
# Change Log:     1.00.00       Initial Version
#                 1.01.00       Improvement with CSV Formatting. Removed space before and after ','
Function Connect-SCCM
{
    $SiteCode = ""
    $ProviderMachineName = ""
    $fReturn = $false
    try
    {
        # Global SCCM Variables

        $SiteCode = $TextBox2.Text # Site code 
        $ProviderMachineName = $TextBox1.Text # SMS Provider machine name
        $initParams = @{}

        # Import the ConfigurationManager.psd1 module 
        if((Get-Module ConfigurationManager) -eq $null) {
            Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
        }

        # Connect to the site's drive if it is not already present
        if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
        }

        # Set the current location to be the site code.
        Set-Location "$($SiteCode):\" @initParams
        $fReturn = $true
    }
    catch {
        $fReturn = $false
    }
    return $fReturn
}

Function Write-OutFile
{
    Param([string] $sContent)
    $sFilename = ""
    $bReturn = $false
    $sFilename = $TextBox4.Text

    try
    {
        if(!(Test-Path -Path $sFilename))
        {
            #create the file
            New-Item -Path $sFilename -ItemType File
        }
        Add-Content -Path $sFilename -Value $sContent -Force
        $bReturn = $true
    }
    catch {
        #$Label7.Text = "Status: Failed to Export"
        $bReturn = $false
    }

    return $bReturn
}

Function Export-QueryResult
{
    $bSuccess = $false
    $sQueryName = ""
    $sFilename = ""

    $sQueryName = $ComboBox1.Text
    $sFilename = $TextBox4.Text
    try
    {
        $strQuery = Get-CMQuery -Name $sQueryName
        $sQueryAttrib = -split $strQuery.ResultColumnsNames
        $Label7.Text = "Status: Query has $($sQueryAttrib.Count) attributes. Fetching Data"
        Start-Sleep -Seconds 2
        $sAttrib = New-Object System.Collections.ArrayList($null)
        for($i=0; $i -le $sQueryAttrib.GetUpperBound(0); $i++)
        {
            $pos = $sQueryAttrib[$i].IndexOf(".")
            #add the elements in an array list to get header string (coloumn names)
            $sAttrib.Add($sQueryAttrib[$i].SubString($pos+1)) 
        }
        $sAttrib = [string]$sAttrib -replace(" ",',')
        #write the headers in the file
        $bWrite = Write-OutFile $sAttrib
        if($bWrite)
        {
            $Label7.Text = "Status: Exporting Results. Header Set Successfully..."
            Start-Sleep -Seconds 2
        }
        else {
            $Label7.Text = "Status: Failed to write file"
        }
        $Label7.Text = "Status: Executing Query, Fetching Results..."
        $queryout = Invoke-CMQuery -Name $sQueryName
        $i = ""
        $j = ""
        for($j = 0; $j -le $queryout.GetUpperBound(0); $j++)
        {
            $out = New-Object System.Collections.ArrayList($null)

            for($i = 0; $i -le $sQueryAttrib.GetUpperBound(0); $i++)
            {
                $val = ""
                $pIndex = ""
                $sTableName = ""
                $sPropName = ""
                $val = $sQueryAttrib[$i]
                $pIndex = $val.IndexOf('.')
                $sTableName = $val.Substring(0,$pIndex)
                $sPropName = $val.Substring($pIndex+1)
                $out.Add($queryout[$j]."$sTableName"."$sPropName")
                if(!($i -eq $sQueryAttrib.GetUpperBound(0)))
                {
                    $out.Add(',')
                }
            }
            $Label7.Text = "Status: Fetched $j of $($queryout.GetUpperBound(0)) rows"
            Write-OutFile $out
        }
        $bSuccess = $true
    }
    catch {
        $bSuccess = $false
    }
    return $bSuccess
}

#Form UI Structure Creation

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '590,309'
$Form.text = "SCCM Query Export Tool"
$Form.TopMost = $false

$Label1 = New-Object system.Windows.Forms.Label
$Label1.text = "Site Server FQDN:"
$Label1.AutoSize = $true
$Label1.width = 25
$Label1.height = 10
$Label1.location = New-Object System.Drawing.Point(31,30)
$Label1.Font = 'Microsoft Sans Serif,10'

$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline = $false
$TextBox1.width = 330.739990234375
$TextBox1.height = 20
$TextBox1.location = New-Object System.Drawing.Point(190,26)
$TextBox1.Font = 'Microsoft Sans Serif,10'

$Label2 = New-Object system.Windows.Forms.Label
$Label2.text = "Site Code:"
$Label2.AutoSize = $true
$Label2.width = 25
$Label2.height = 10
$Label2.location = New-Object System.Drawing.Point(31,75)
$Label2.Font = 'Microsoft Sans Serif,10'

$TextBox2 = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline = $false
$TextBox2.width = 41.9000244140625
$TextBox2.height = 20
$TextBox2.location = New-Object System.Drawing.Point(190,72)
$TextBox2.Font = 'Microsoft Sans Serif,10'
$TextBox2.MaxLength = 3

$Label3 = New-Object system.Windows.Forms.Label
$Label3.text = "Query Name:"
$Label3.AutoSize = $true
$Label3.width = 25
$Label3.height = 10
$Label3.location = New-Object System.Drawing.Point(31,121)
$Label3.Font = 'Microsoft Sans Serif,10'

$TextBox3 = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline = $false
$TextBox3.width = 254.95001220703125
$TextBox3.height = 20
$TextBox3.location = New-Object System.Drawing.Point(190,118)
$TextBox3.Font = 'Microsoft Sans Serif,10'

$Label4 = New-Object system.Windows.Forms.Label
$Label4.text = "May not be full name"
$Label4.AutoSize = $true
$Label4.width = 25
$Label4.height = 10
$Label4.location = New-Object System.Drawing.Point(31,142)
$Label4.Font = 'Microsoft Sans Serif,6'

$Label5 = New-Object system.Windows.Forms.Label
$Label5.text = "Query List"
$Label5.AutoSize = $true
$Label5.width = 25
$Label5.height = 10
$Label5.location = New-Object System.Drawing.Point(31,171)
$Label5.Font = 'Microsoft Sans Serif,10'

$ComboBox1 = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text = "Queries Available"
$ComboBox1.width = 255.78997802734375
$ComboBox1.height = 20
$ComboBox1.location = New-Object System.Drawing.Point(190,170)
$ComboBox1.Font = 'Microsoft Sans Serif,8'

$Label6 = New-Object system.Windows.Forms.Label
$Label6.text = "Export Path"
$Label6.AutoSize = $true
$Label6.width = 25
$Label6.height = 10
$Label6.location = New-Object System.Drawing.Point(31,220)
$Label6.Font = 'Microsoft Sans Serif,10'

$TextBox4 = New-Object system.Windows.Forms.TextBox
$TextBox4.multiline = $false
$TextBox4.width = 304.6300048828125
$TextBox4.height = 20
$TextBox4.location = New-Object System.Drawing.Point(190,216)
$TextBox4.Font = 'Microsoft Sans Serif,10'

$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "Browse"
$Button1.width = 73
$Button1.height = 30
$Button1.location = New-Object System.Drawing.Point(500,214)
$Button1.Font = 'Microsoft Sans Serif,8'
$Button1.Add_Click(
{
    $fDialog = New-Object System.Windows.Forms.SaveFileDialog
    $fDialog.Filter = "CSV File *.csv |*.csv"
    $fDialog.ShowDialog()
    $Textbox4.Text = $fDialog.FileName
})

$Button2 = New-Object system.Windows.Forms.Button
$Button2.text = "Validate"
$Button2.width = 73
$Button2.height = 30
$Button2.location = New-Object System.Drawing.Point(450,115)
$Button2.Font = 'Microsoft Sans Serif,8'

$Button2.Add_Click(
{
    #Search Button is clicked
    #check if fields is not empty
    If ($TextBox3.Text -eq "")
    {
        $Label7.Text = "Status: Query Name cannot be empty"
    }
    elseIf ($TextBox1.Text -eq "")
    {
        $Label7.Text = "Status: Server Name cannot be empty"
    }
    elseIf ($TextBox2.Text -eq "")
    {
        $Label7.Text = "Status: Site Code cannot be empty"
    }
    else {
        $Label7.Text = "Status: Connecting to SCCM..."
        Start-Sleep -Seconds 5
        $conSCCM = Connect-SCCM
        if ($conSCCM)
        {
            $Label7.Text = "Status: Connection Succeeded"
            #Fetch the query names
            Start-Sleep -Seconds 2
            $Label7.Text = "Status: Searching Queries..."
            $sQuery = $TextBox3.Text
            $colQueries = Get-CMQuery -Name "*$($sQuery)*"
            ForEach ($query in $colQueries)
            {
                $ComboBox1.Items.Add($query.Name)
            }
            $Label7.Text = "Status: $($colQueries.Count) query match(es) found"
            $ComboBox1.Text = $ComboBox1.Items[0]
        }
        else {
            $Label7.Text = "Status: Failed to Connect to SCCM"
        }
    }
})

$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "Export"
$Button3.width = 73
$Button3.height = 30
$Button3.location = New-Object System.Drawing.Point(219,260)
$Button3.Font = 'Microsoft Sans Serif,10'
$Button3.Add_Click(
{
    #Check filename should not be empty and there must be a query selected
    if(($ComboBox1.Text -eq "Queries Available") -or ($ComboBox1.Text -eq ""))
    {
        $Label7.Text = "Status: Select a valid query"
    }
    elseif ($TextBox4.Text -eq "") {
        $Label7.Text = "Status: Provide a filename to export the result"
    }
    else {
        $Label7.Text = "Status: Executing Query...."
        $execQuery = Export-QueryResult
        if($execQuery)
        {
            $Label7.Text = "Status: Export Complete. Formatting Output, please wait."
            $fPath = $TextBox4.Text
            $fileContent = Get-Content -Path $fpath
            Remove-Item -Path $fpath -Force
            New-Item -Path $fpath -ItemType File -Force
            Foreach ($line in $fileContent)
            {
                $outline = $line.Replace(' , ' , ',')
                Add-Content -Path $fpath -Value $outline -Force
            }
            $Label7.Text = "Status: File Ready. You can close the tool."
        }
        else {
            $Label7.Text = "Status: Error Exporting. Try Again."
        }
    }
})

$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "Close"
$Button4.width = 70
$Button4.height = 30
$Button4.location = New-Object System.Drawing.Point(300,260)
$Button4.Font = 'Microsoft Sans Serif,10'

$Button4.Add_Click(
{
    $Form.Close()
})

$Label7 = New-Object system.Windows.Forms.Label
$Label7.text = "Status : Idle"
$Label7.AutoSize = $true
$Label7.width = 10
$Label7.height = 5
$Label7.location = New-Object System.Drawing.Point(2,290)
$Label7.Font = 'Microsoft Sans Serif,8'

$Label8 = New-Object system.Windows.Forms.Label
$Label8.text = "matrixtushar@gmail.com"
$Label8.AutoSize = $true
$Label8.width = 10
$Label8.height = 5
$Label8.location = New-Object System.Drawing.Point(460,290)
$Label8.Font = 'Microsoft Sans Serif,8'

$Form.controls.AddRange(@($Label1,$TextBox1,$Label2,$TextBox2,$Label3,$TextBox3,$Label4,$Label5,$ComboBox1,$Label6,$Label7,$Label8,$TextBox4,$Button1,$Button2,$Button3,$Button4))
$Form.ShowDialog()
