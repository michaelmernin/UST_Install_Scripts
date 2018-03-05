param([String]$py="3", [Switch]$retry=$false)

if ($py -eq "2"){
    $pythonVersion = "2"
} else {$pythonVersion = "3"}

$ErrorActionPreference = "Stop"

# URL's Combined for convenience here
$JREURL = "https://github.com/janssenda/vm_resources/raw/master/jre-8u161-windows-x64.exe"
$7zURL = 'http://www.7-zip.org/a/7za920.zip'
$VMResourceURL = "https://github.com/janssenda/vm_resources/raw/master/vm_common_resources.tar.gz"
$USTScriptURL = "https://raw.githubusercontent.com/janssenda/UST_Install_Scripts/master/UST_quick_install_windows.ps1"

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


function Get7Zip {
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $7zipTempPath = "$env:TEMP\7zip"

    if (-not (Test-Path $7zipTempPath))
    {
        #Create Temporary 7zip folder
        Write-Host "- Creating temp 7zip Path - $7zipTempPath"
        New-Item -Path $7zipTempPath -ItemType 'Directory' -Force | Out-Null

        $7Zfilename = $7zURL.Split('/')[-1]
        $7zDownload = "$7zipTempPath\$7Zfilename"

        #Download 7z Command Line from 7-zip.org
        Write-Host "- Downloading 7-zip Standalone ($7zURL)"

        (New-Object net.webclient).DownloadFile($7zURL, $7zDownload)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($7zDownload, $7zipTempPath)
    } else {
        Write-Host "- 7 zip already found! Skipping..."
    }
    return $7zipTempPath

}


function Expand-Archive() {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $OutPut,
        $ArchiveType
    )

    if ($ArchiveType -eq "tar")    {
        Start-Process cmd.exe -ArgumentList ("/c $7zipTempPath\7za.exe x $Path -so  | $7zipTempPath\7za.exe x -y -si -aoa -ttar -o`"$OutPut`"") -Wait

    } else {
        Start-Process cmd.exe -ArgumentList ("/c $7zipTempPath\7za.exe x $Path -y -tzip -aoa -o`"$OutPut`"") -Wait
    }
}

function SetDirectory(){

    $TARGETDIR = (Get-Item -Path ".\" -Verbose).FullName + "\LDAP_test_server"
    Write-Host "- Creating directory $TARGETDIR... "
    New-Item -ItemType Directory -Force -Path $TARGETDIR | Out-Null

    return $TARGETDIR

}


function GetJava ($DownloadFolder){
    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
    $subkeys = $reg.OpenSubkey($UninstallKey).GetSubkeyNames()

    foreach ($k in $subkeys){
        $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")
        if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Java).+" -Quiet)    {
            $javaInstalled = $true
        }
    }

    if ($javaInstalled){
        Write-Host "- Java already installed! Skipping...  "
        return $false
    }


    $filename = $JREURL.Split('/')[-1]
    $javaExecutable = "$DownloadFolder\$filename"

    #Download file
    Write-Host "- Downloading $filename from $JREURL"

    (New-Object net.webclient).DownloadFile($JREURL, $javaExecutable)

    if (Test-Path $javaExecutable){
        Write-Host "- Begin Java Installation"
        $javaProcess = Start-Process $javaExecutable -ArgumentList @('/s') -Wait -PassThru
        if ($javaProcess.ExitCode -eq 0)        {
            Write-Host "- Java Installation - Completed"
            [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Java\jre1.8.0_161\bin", [EnvironmentVariableTarget]::Machine)
            return $true
        }
        else        {
            Write-Host "- Java Installation - Completed/Error with ExitCode: $( $javaProcess.ExitCode )"
        }
    }
    return $false

}

function GetFiles ($LDAPFolder, $DownloadFolder) {
    $DownloadList = @()
    $DownloadList += $VMResourceURL

    foreach($download in $DownloadList){

        $filename = $download.Split('/')[-1]
        $downloadfile = "$DownloadFolder\$filename"

        #Download file
        Write-Host "- Downloading $filename from $download"

        (New-Object net.webclient).DownloadFile($download,$downloadfile)

        Write-Host "- Extracting $downloadfile to $LDAPFolder"
        Expand-Archive -Path $downloadfile -OutPut $LDAPFolder -ArchiveType tar

    }

}

function Cleanup($DownloadFolder) {

    try {
        #Delete Temp DownloadFolder
        Remove-Item -Path $DownloadFolder -Recurse -Confirm:$false -Force
    } catch {}

    try {
        #Delete 7-zip temp folder
        Remove-Item -Path "$env:TEMP\7zip" -Recurse -Confirm:$false -Force
    } catch {}

}

# Main
if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){

    $introbanner = "`n
  _   _ ___ _____      ___               ___
 | | | / __|_   _|    |   \ _____ __    | _ \___ ___ ___ _  _ _ _ __ ___ ___
 | |_| \__ \ | |      | |) / -_) V /    |   / -_|_-</ _ \ || | '_/ _/ -_|_-<
  \___/|___/ |_|      |___/\___|\_/     |_|_\___/__/\___/\_,_|_| \__\___/__/
    "

    printColor $introbanner Blue
    banner -message "UST Dev Resources Install" -color White
    Write-Host ""

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    banner -message "- Creating tools directory"
    $DownloadFolder = "$env:TEMP\LDAPDownload"
    $LDAPFolder = SetDirectory

    #Create Temp download folder
    New-Item -Path $DownloadFolder -ItemType "Directory" -Force | Out-Null
    banner -message "Install 7 zip x64"
    $7zipTempPath = Get7Zip

    try    {
        banner -message "Download VM Resources"
        GetFiles $LDAPFolder $DownloadFolder
    } catch {
        Write-Host "Failed to download resources with error:"
        Write-Host $PSItem.ToString()
    }

    try    {
        banner -message "Install Java"
        $requireRestart = GetJava $DownloadFolder
    } catch {
        Write-Host "Failed to install Java with error:"
        Write-Host $PSItem.ToString()
    }

    Cleanup $DownloadFolder

    banner -message "Install Finish" -color Blue
    Write-Host "- Completed - You can run the server from:"
    printColor $LDAPFolder Green



    if ($retry){
        (New-Object System.Net.WebClient).DownloadFile($USTScriptURL,"${PWD}\instd.ps1"); ./instd.ps1 -py $pythonVersion -retry; rm -Force ./instd.ps1;
        #./UST_quick_install_windows-dev.ps1 -py $pythonVersion -retry;
    } else {
        (New-Object System.Net.WebClient).DownloadFile($USTScriptURL,"${PWD}\instd.ps1"); ./instd.ps1 -py $pythonVersion; rm -Force ./instd.ps1;
        #./UST_quick_install_windows-dev.ps1 -py $pythonVersion;
    }

    if ($requireRestart){
        printColor "- You must restart the computer before you can run java -jar on the LDAP server...`n`n" Yellow
    }

}else{
    printColor "- Not elevated. Re-run the script with elevated permission" Red
}


