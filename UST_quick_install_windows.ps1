param([String]$py="3", [Switch]$retry=$false)

if ($py -eq "2"){
    $pythonVersion = "2"
} else {$pythonVersion = "3"}

$ErrorActionPreference = "Stop"

# URL's Combined for convenience here
$7zURL = 'http://www.7-zip.org/a/7za920.zip'
$USTPython2URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py2714.tar.gz"
$USTPython3URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py363.tar.gz"
$USTExamplesURL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
$openSSLBinURL = "https://indy.fulgan.com/SSL/openssl-1.0.2l-x64_86-win64.zip"
$adobeIOCertScriptURL = "https://raw.githubusercontent.com/bhunut-adobe/user-sync-quick-install/master/adobe_io_certgen.ps1"
$Python2URL = "https://www.python.org/ftp/python/2.7.14/python-2.7.14.amd64.msi"
$Python3URL = "https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe"




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
        Write-Host "Creating temp 7zip Path - $7zipTempPath"
        New-Item -Path $7zipTempPath -ItemType 'Directory' -Force | Out-Null

        $7Zfilename = $7zURL.Split('/')[-1]
        $7zDownload = "$7zipTempPath\$7Zfilename"

        #Download 7z Command Line from 7-zip.org
        Write-Host "- Downloading 7-zip Standalone ($7zURL)"

        (New-Object net.webclient).DownloadFile($7zURL, $7zDownload)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($7zDownload, $7zipTempPath)
    } else {
        Write-Host "7 zip already found! Skipping..."
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

    $TARGETDIR = (Get-Item -Path ".\" -Verbose).FullName + "\UST_Install"
    Write-Host "Creating directory $TARGETDIR... "
    New-Item -ItemType Directory -Force -Path $TARGETDIR | Out-Null

    return $TARGETDIR

}

function GetUSTFiles ($USTFolder, $DownloadFolder) {

    if ($pythonVersion -eq 2){
        $URL = $USTPython2URL
    } else {
        $URL = $USTPython3URL
    }

    #Download UST 2.2.2 and Extract
    $USTdownloadList = @()
    $USTdownloadList += $URL
    $USTdownloadList += $USTExamplesURL

    foreach($download in $USTdownloadList){
        $filename = $download.Split('/')[-1]
        $downloadfile = "$DownloadFolder\$filename"

        #Download file
        Write-Host "- Downloading $filename from $download"

        #Invoke-WebRequest -Uri $download -OutFile $downloadfile

        $wc = New-Object net.webclient
        $wc.DownloadFile($download,$downloadfile)

        if(Test-Path $downloadfile){
            #Extract downloaded file to UST Folder
            Write-Host "- Extracting $downloadfile to $USTFolder"
            Expand-Archive -Path $downloadfile -OutPut $USTFolder -ArchiveType tar
        }
    }


    #Make example config files readable in windows and Copy "config files - basic" to root
    $configExamplePath = "$USTFolder\examples"
    if(Test-Path -Path $configExamplePath){
        Get-ChildItem -Path $configExamplePath -Recurse -Filter '*.yml' | % { ( $_ |  Get-Content ) | Set-Content $_.pspath -Force }
        #Copy config files
        $configBasicPath = "$configExamplePath\config files - basic"
        Copy-Item -Path "$configBasicPath\3 connector-ldap.yml" -Destination $USTFolder\connector-ldap.yml -Force
        Copy-Item -Path "$configBasicPath\2 connector-umapi.yml" -Destination $USTFolder\connector-umapi.yml -Force
        Copy-Item -Path "$configBasicPath\1 user-sync-config.yml" -Destination $USTFolder\user-sync-config.yml -Force

    }
}


function GetOpenSSL ($USTFolder, $DownloadFolder) {

    #Download OpenSSL 1.0.2l binary for Windows and extract to utils folder
    $openSSLBinFileName = $openSSLBinURL.Split('/')[-1]
    $openSSLOutputPath = "$DownloadFolder\$openSSLBinFileName"
    $openSSLUSTFolder = "$USTFolder\Utils\openSSL"
    Write-Host "- Downloading OpenSSL Win32 Binary from $openSSLBinURL"
    #Invoke-WebRequest -Uri $openSSLBinURL -OutFile $openSSLOutputPath

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLBinURL,$openSSLOutputPath)

    if(Test-Path $openSSLOutputPath){
        #- Extracting downloaded file to UST folder.
        Write-Host "- Extracting $openSSLBinFileName to $openSSLUSTFolder"
        try{
            New-Item -Path $openSSLUSTFolder -ItemType Directory -Force | Out-Null
            Expand-Archive -Path $openSSLOutputPath -OutPut $openSSLUSTFolder -ArchiveType zip
            Write-Host "Completed extracting $openSSLBinFileName to $openSSLUSTFolder"
        }catch{
            Write-Error "Unable to extract openSSL"
        }
    }

    #Download Default Openssl.cfg configuration file
    $openSSLConfigURL = 'http://web.mit.edu/crypto/openssl.cnf'
    $openSSLConfigFileName = $openSSLConfigURL.Split('/')[-1]
    $openSSLConfigOutputPath = "$USTFolder\Utils\openSSL\$openSSLConfigFileName"
    Write-Host "- Downloading default openssl.cnf config file from $openSSLConfigURL"
    #Invoke-WebRequest -Uri $openSSLConfigURL -OutFile $openSSLConfigOutputPath

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLConfigURL,$openSSLConfigOutputPath)

}

function FinalizeInstallation ($USTFolder, $DownloadFolder) {

    #Download Adobe.IO Cert generation Script and put it into utils\openSSL folder
    $adobeIOCertScript = $adobeIOCertScriptURL.Split('/')[-1]
    $adobeIOCertScriptOutputPath = "$USTFolder\Utils\openSSL\$adobeIOCertScript"
    Write-Host "- Downloading Adobe.IO Cert Generation Script from $adobeIOCertScriptURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($adobeIOCertScriptURL,$adobeIOCertScriptOutputPath)

    if(Test-Path $adobeIOCertScriptOutputPath){

        $batchfile = '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -file ' + $adobeIOCertScriptOutputPath
        $batchfile | Out-File "$openSSLUSTFolder\Adobe_IO_Cert_Generation.bat" -Force -Encoding ascii

    }

    #Create Test-Mode and Live-Mode UST Batch file
    if(Test-Path $USTFolder){
        $test_mode_batchfile = @"
REM "Running UST in TEST-MODE"
cd $USTFolder
python user-sync.pex --process-groups --users mapped -t
pause
"@
        $test_mode_batchfile | Out-File "$USTFolder\Run_UST_Test_Mode.bat" -Force -Encoding ascii

        $live_mode_batchfile = @"
REM "Running UST"
cd $USTFolder
python user-sync.pex --process-groups --users mapped
"@
        $live_mode_batchfile | Out-File "$USTFolder\Run_UST_Live.bat" -Force -Encoding ascii
    }

}



function GetPython ($USTFolder, $DownloadFolder) {

    $install = $FALSE
    $UST_version = 3
    $inst_version = $pythonVersion

    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
    $subkeys = $reg.OpenSubkey($UninstallKey).GetSubkeyNames()

    foreach ($k in $subkeys){
        $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")
        if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Python).+(\(64-Bit\))" -Quiet)    {
            $thisKey.GetValue("DisplayVersion") | Select-String -pattern "((3.6)|(2.7))(.)" | foreach-object {
                switch ($_.Matches[0].Groups[1].Value) {
                    "2.7" {$p2_installed = $true; break}
                    "3.6" {$p3_installed = $true; break}
                }
            }
        }
    }

    if ($pythonVersion -eq "3" -and -not $p3_installed) { $install = $true }
    elseif ($pythonVersion -eq "2" -and -not $p2_installed) { $install = $true }
    else {
        Write-Host "Python version $pythonVersion is already installed...".
    }

    if ($install){
        Write-Host "Python $inst_version will be updated/installed...".
        if ($inst_version -eq 2){
            $pythonURL = $Python2URL
            $UST_version = 2
        } else {
            $pythonURL = $Python3URL
            $UST_version = 3
        }

        $pythonInstaller = $pythonURL.Split('/')[-1]
        $pythonInstallerOutput = "$DownloadFolder\$pythonInstaller"

        Write-Host "- Downloading Python from $pythonURL"


        $wc = New-Object net.webclient
        $wc.DownloadFile($pythonURL,$pythonInstallerOutput)

        if(Test-Path $pythonInstallerOutput){

            #Passive Install of Python. This will show progressbar and error.
            Write-Host "- Begin Python Installation"
            $pythonProcess = Start-Process $pythonInstallerOutput -ArgumentList @('/passive', 'InstallAllUsers=1', 'PrependPath=1') -Wait -PassThru
            if($pythonProcess.ExitCode -eq 0){
                Write-Host "Python Installation Completed"
            }else{
                if ($inst_version -eq 3){
                    Write-Host "Error: Python may have failed to install Windows updates for this version of Windows.`nUpdate Windows manually or try installing Python 2 instead..."

                    if ($retry) {
                        Write-Host "Retry flag specified, defaulting to install Python 2.7 for compatability.... "
                        $pythonVersion = "2"
                        GetPython ($USTFolder, $DownloadFolder)
                        return
                    }

                }

                Write-Host "Python Installation Completed/Error with ExitCode: $($pythonProcess.ExitCode)"
            }
        }
    }

    #Set Environment Variable
    Write-Host "Set PEX_ROOT System Environment Variable"
    [Environment]::SetEnvironmentVariable("PEX_ROOT", "$env:SystemDrive\PEX", "Machine")

}

function Cleanup($DownloadFolder) {

    #Delete Temp DownloadFolder for UST, Python and Config files
    Remove-Item -Path $DownloadFolder -Recurse -Confirm:$false -Force
    #Delete 7-zip temp folder
    Remove-Item -Path "$env:TEMP\7zip" -Recurse -Confirm:$false -Force
}

# Main
if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){

    $introbanner = "`n
  _   _                 ___
 | | | |___ ___ _ _    / __|_  _ _ _  __
 | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|
  \___//__/\___|_|     |___/\_, |_||_\__|
                            |__/
    "

    printColor $introbanner White
    banner -message "User Sync Tool Quick Install" -color White
    Write-Host ""

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $DownloadFolder = "$env:TEMP\USTDownload"

    banner -message "Creating UST directory"
    $USTFolder = SetDirectory

    #Create Temp download folder
    New-Item -Path $DownloadFolder -ItemType "Directory" -Force | Out-Null

    # Install Process
    banner -message "Install 7 zip x64"
    $7zipTempPath = Get7Zip

    try    {
        banner -message "Install Python $pythonVersion"
        GetPython $USTFolder $DownloadFolder
    } catch {
        banner -type Error
        Write-Host "Failed to install Python with error:"
        Write-Host $PSItem.ToString()
    }

    try    {
        banner -message "Download UST Files"
        GetUSTFiles $USTFolder $DownloadFolder $pythonVersion
    } catch {
        banner -type Error
        Write-Host "Failed to download UST resources with error:"
        Write-Host $PSItem.ToString()
    }

    # Try loop as connection occasionally fails the first time
    banner -message "Download OpenSSL"
    $i = 0
    while ($true)  {
        $i++
        try {
            GetOpenSSL $USTFolder $DownloadFolder
            break
        }
        catch {
            printColor "Connection failed... retrying... ctrl-c to abort..." Yellow
        }
        if ($i -eq 5) {
            banner -type Warning
            printColor "Open SSL failed to download... retry or download manually..." Red
            break
        }
    }

    FinalizeInstallation $USTFolder $DownloadFolder
    Cleanup $DownloadFolder

    banner -message "Install Finish" -color Blue
    Write-Host "Completed - You can begin to edit configuration files in:"
    printColor $USTFolder Green
    Write-Host "`n"

}else{
    Write-host "Not elevated. Re-run the script with elevated permission"
}


