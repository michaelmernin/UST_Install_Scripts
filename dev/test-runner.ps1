#param([String]$py="xxx")
$ErrorActionPreference = "Stop"

$link = "http://www.7-zip.org/a/7za920.zip"

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Import-Module BitsTransfer
#Start-BitsTransfer -Source "https://github.com/janssenda/vm_resources/raw/master/vm_common_resources.tar.gz" -Description "test.tar.gz"

#$link = "https://git.io/vADrk"
#Write-Host $py
#$setvar = "55555"; iex ((New-Object System.Net.WebClient).DownloadString($link))


#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
#
#$(New-Object System.Net.WebClient).DownloadFile($link,"test.zip");



function doThing ($input, $in2){
    return "xxx $input $in2"
}

function surround{
    Param(
        [String]$type="Info",
        [String[]]$fArgs,
        [scriptblock]$functionToCall,
        [String]$color="Green"
    )



    switch ($type) {
        "Info" {$color = "Green"; break;}
        "Warning" {$color = "Yellow"; break}
        "Error" {$color = "Red"; break}
    }

    $msgChar = "="
    $charLen = 20

    $messageTop = ("`n" + $msgChar*$charLen + " ${type} " + $msgChar*$charLen)
    $messageBottom = $msgChar*($messageTop.length-1)

    printColor $messageTop $color
    $result = $functionToCall.Invoke($fArgs)
    #Write-Host $messageBottom

    return $result
}


function printColor ($msg, $color) {
    Write-Host $msg -ForegroundColor $color
}


function banner {
    Param(
        [String]$message,
        [String]$type="Info",
        [String]$color="Green"
    )

    $message = If ($message) {$message} Else {$type}

    if ($color -eq "Green"){
        switch ($type) {
            "Warning" { $color = "Yellow"; break }
            "Error" { $color = "Red"; break }
        }
    }

    $msgChar = "="
    $charLen = 20

    $messageTop = ("`n" + $msgChar*$charLen + " ${message} " + $msgChar*$charLen)
    $messageBottom = $msgChar*($messageTop.length-1)

    printColor $messageTop $color
}


#$var = surround -type Warning -functionToCall $function:doThing -fArgs 1,2

banner -type Info -message "Installing"


#(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADiN","inst.ps1"); ./inst.ps1 -py 3; rm -Force ./inst.ps1;


#$pythonInstalled = Get-CimInstance -ClassName 'Win32_Product' -Filter "Name like 'Python% (64-bit)'"
##$pyver = ($pythonInstalled.Version | Measure -Max).Maximum
##Write-Host $pythonInstalled.Version
#
#
#foreach ($v in $pythonInstalled.Version){
#    $vers = $v.Substring(0,3)
#
#    if ($vers -eq "2.7") {$p2_installed = $true}
#    elseif ($vers -eq "3.6") {$p3_installed = $true}
#
#}
#
#if($p3_installed) {Write-Host "P3 Is installed"}
#if($p2_installed) {Write-Host "P2 Is installed"}


#Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  ? {$_.displayname -like "Python*(64-Bit)"} |  Select-Object DisplayVersion
#$pythonInstalled = Get-CimInstance -ClassName 'Win32_Product' -Filter "Name like 'Python% (64-bit)'"

#foreach ($vr in $inst){
#    Write-Host $vr
#    $x = $vr | Select-String -pattern "((3.6)|(2.7))(.)" | foreach-object {
#        switch ($_.Matches[0].Groups[1].Value){
#            "2.7" {$p2_installed = $true; break}
#            "3.6" {$p3_installed = $true; break}
#        }
#    }
#}
#if($p3_installed) {Write-Host "P3 Is installed"}
#if($p2_installed) {Write-Host "P2 Is installed"}


#$UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
#$reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
#$regkey = $reg.OpenSubkey($UninstallKey)
#$subkeys = $regkey.GetSubkeyNames()
#
#foreach ($k in $subkeys){
#    $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")
#    if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Python).+(\(64-Bit\))" -Quiet)    {
#        $thisKey.GetValue("DisplayVersion") | Select-String -pattern "((3.6)|(2.7))(.)" | foreach-object {
#            switch ($_.Matches[0].Groups[1].Value) {
#                "2.7" {$p2_installed = $true; break}
#                "3.6" {$p3_installed = $true; break}
#            }
#        }
#    }
#}
#
#if($p3_installed) {Write-Host "P3 Is installed"}
#if($p2_installed) {Write-Host "P2 Is installed"}

#    | foreach-object {
#        #Write-Host $_.Matches[0] #$_.Matches[0].Groups[1].Value
##        switch ($_.Matches[0].Groups[1].Value){
##            "2.7" {$p2_installed = $true; break}
##            "3.6" {$p3_installed = $true; break}
#        }
