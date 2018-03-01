param([String]$py="xxx")
$ErrorActionPreference = "Stop"
Write-Host $py
# Run from powershell
# Set-ExecutionPolicy Bypass -Scope Process; iex ((New-Object System.Net.WebClient).DownloadString('https://git.io/vABrB'))

# Run from CMD
# @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://git.io/vABrB'))"


function Unzip($zipfile, $outdir){
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
    foreach ($entry in $archive.Entries)
    {
        $entryTargetFilePath = [System.IO.Path]::Combine($outdir, $entry.FullName)
        $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)

        #Ensure the directory of the archive entry exists
        if(!(Test-Path $entryDir )){
            New-Item -ItemType Directory -Path $entryDir | Out-Null
        }

        #If the entry is not a directory entry, then extract entry
        if(!$entryTargetFilePath.EndsWith("\")){
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
        }
    }

    $archive.Dispose()
}

function Expand-Archive {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $OutPut,
        $ArchiveType
    )

    $7zipTempPath = "$env:TEMP\7zip"

    if( -not (Test-Path "$7zipTempPath\7za.exe")){
        #Create Temporary 7zip folder
        Write-Host "Creating temp 7zip Path - $7zipTempPath"
        New-Item -Path $7zipTempPath -ItemType 'Directory' -Force | Out-Null

        #Latest stable version of 7-zip standalone 9.2.0
        $7zURL = 'http://www.7-zip.org/a/7za920.zip'
        $7Zfilename = $7zURL.Split('/')[-1]
        $7zDownload = "$7zipTempPath\$7Zfilename"

        #Download 7z Command Line from 7-zip.org
        Write-Host "Downloading 7-zip Standalone ($7zURL)"
        #Invoke-WebRequest -Uri $7zURL -OutFile $7zDownload

        $wc = New-Object net.webclient
        $wc.DownloadFile($7zURL,$7zDownload)

        if(Test-Path $7zDownload){
            #Extract downloaded 7-zip to 7-zip temp folder
            Unzip -zipfile $7zDownload -outdir $7zipTempPath
        }

    }
    #Unzip -zipfile $openSSLOutputPath -outdir $openSSLUSTFolder

    if ($ArchiveType -eq "tar")    {
        Start-Process cmd.exe -ArgumentList ("/c $7zipTempPath\7za.exe x $Path -so  | $7zipTempPath\7za.exe x -y -si -aoa -ttar -o`"$OutPut`"") -Wait
    } else {
        Start-Process cmd.exe -ArgumentList ("/c $7zipTempPath\7za.exe x $Path -y -tzip -aoa -o`"$OutPut`"") -Wait
    }
}

function SetDirectory(){

    $TARGETDIR = "C:\AdobeSSO\UST_Install"
    Write-Host "Creating directory $TARGETDIR... "
    New-Item -ItemType Directory -Force -Path $TARGETDIR | Out-Null

    return $TARGETDIR

}

function GetUSTFiles ($USTFolder, $DownloadFolder, $Version) {
    #Download UST 2.2.2 and Extract
    $USTdownloadList = @()
    $USTdownloadList += "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py$Version.tar.gz"
    $USTdownloadList += "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"

    foreach($download in $USTdownloadList){
        $filename = $download.Split('/')[-1]
        $downloadfile = "$DownloadFolder\$filename"
        #Download file
        Write-Host "Downloading $filename from $download"

        #Invoke-WebRequest -Uri $download -OutFile $downloadfile

        $wc = New-Object net.webclient
        $wc.DownloadFile($download,$downloadfile)

        if(Test-Path $downloadfile){
            #Extract downloaded file to UST Folder
            Write-Host "Extracting $downloadfile to $USTFolder"
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
    $openSSLBinURL = "https://indy.fulgan.com/SSL/openssl-1.0.2l-x64_86-win64.zip"
    $openSSLBinFileName = $openSSLBinURL.Split('/')[-1]
    $openSSLOutputPath = "$DownloadFolder\$openSSLBinFileName"
    $openSSLUSTFolder = "$USTFolder\Utils\openSSL"
    Write-Host "Downloading OpenSSL Win32 Binary from $openSSLBinURL"
    #Invoke-WebRequest -Uri $openSSLBinURL -OutFile $openSSLOutputPath

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLBinURL,$openSSLOutputPath)

    if(Test-Path $openSSLOutputPath){
        #Extracting downloaded file to UST folder.
        Write-Host "Extracting $openSSLBinFileName to $openSSLUSTFolder"
        try{
            New-Item -Path $openSSLUSTFolder -ItemType Directory -Force | Out-Null
            #Unzip -zipfile $openSSLOutputPath -outdir $openSSLUSTFolder
            Expand-Archive -Path $openSSLOutputPath -OutPut $openSSLUSTFolder -ArchiveType zip
            Write-Host "Completed extracting $openSSLBinFileName to $openSSLUSTFolder"
        }catch{

            Write-Error "Unable to extract openSSL"
        }
    }

#    #Download Default Openssl.cfg configuration file
    $openSSLConfigURL = 'http://web.mit.edu/crypto/openssl.cnf'
    $openSSLConfigFileName = $openSSLConfigURL.Split('/')[-1]
    $openSSLConfigOutputPath = "$USTFolder\Utils\openSSL\$openSSLConfigFileName"
    Write-Host "Downloading default openssl.cnf config file from $openSSLConfigURL"
    #Invoke-WebRequest -Uri $openSSLConfigURL -OutFile $openSSLConfigOutputPath

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLConfigURL,$openSSLConfigOutputPath)

}

function FinalizeInstallation ($USTFolder, $DownloadFolder) {

    #Download Adobe.IO Cert generation Script and put it into utils\openSSL folder
    $adobeIOCertScriptURL = "https://raw.githubusercontent.com/bhunut-adobe/user-sync-quick-install/master/adobe_io_certgen.ps1"
    $adobeIOCertScript = $adobeIOCertScriptURL.Split('/')[-1]
    $adobeIOCertScriptOutputPath = "$USTFolder\Utils\openSSL\$adobeIOCertScript"
    Write-Host "Downloading Adobe.IO Cert Generation Script from $adobeIOCertScriptURL"
    #Invoke-WebRequest -Uri $adobeIOCertScriptURL -OutFile $adobeIOCertScriptOutputPath

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
    $inst_version = 3
    $UST_version = 3

    $pythonInstalled = Get-CimInstance -ClassName 'Win32_Product' -Filter "Name like 'Python%'"
    #$pyver = $pythonInstalled.Version
    $pyver = ($pythonInstalled.Version | Measure -Max).Maximum

    if (-Not ($pythonInstalled) -Or ($pyver -lt [Version]"3.0")  )  {

        $install = $TRUE
        $inst_version = 3

    } else {
        Write-Host "Python version $pyver is currently installed".
    }

    if ($install){
        Write-Host "Python $inst_version will be updated/installed...".
        if ($inst_version -eq 2){
            $pythonURL = "https://www.python.org/ftp/python/2.7.14/python-2.7.14.amd64.msi"
            $UST_version = 2
        } else {
            $pythonURL = "https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe"
            $UST_version = 3
        }

        $pythonInstaller = $pythonURL.Split('/')[-1]
        $pythonInstallerOutput = "$DownloadFolder\$pythonInstaller"

        Write-Host "Downloading Python from $pythonURL"

        #Invoke-WebRequest -Uri $pythonURL -OutFile $pythonInstallerOutput

        $wc = New-Object net.webclient
        $wc.DownloadFile($pythonURL,$pythonInstallerOutput)

        if(Test-Path $pythonInstallerOutput){
            #Passive Install of Python. This will show progressbar and error.
            Write-Host "Begin Python Installation"
            $pythonProcess = Start-Process $pythonInstallerOutput -ArgumentList @('/passive', 'InstallAllUsers=1', 'PrependPath=1') -Wait -PassThru
            if($pythonProcess.ExitCode -eq 0){
                Write-Host "Python Installation Completed"
            }else{
                if ($inst_version -eq 3){
                    Write-Host "Error: Python may have failed to install dependencies for this version of windows.`nTry installing Python 2.7 instead..."
                }

                Write-Host "Python Installation Completed/Error with ExitCode: $($pythonProcess.ExitCode)"
            }
        }
    }


     #Set Environment Variable
     Write-Host "Set PEX_ROOT System Environment Variable"
     [Environment]::SetEnvironmentVariable("PEX_ROOT", "$env:SystemDrive\PEX", "Machine")

    if ($UST_version -eq 2){
        return "2714"
    } else {
        return "363"
    }
}

function Cleanup($DownloadFolder) {
    #Cleanup
    #Delete Temp DownloadFolder for UST, Python and Config files
    Remove-Item -Path $DownloadFolder -Recurse -Confirm:$false -Force
    #Delete 7-zip temp folder
    Remove-Item -Path "$env:TEMP\7zip" -Recurse -Confirm:$false -Force
}

# Main
if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Write-Host "Elevated."

    Write-Host $py

#    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#
#    $DownloadFolder = "$env:TEMP\USTDownload"
#    $USTFolder = SetDirectory
#    #Create Temp download folder
#    New-Item -Path $DownloadFolder -ItemType "Directory" -Force | Out-Null
#
#    # Install Process
#    $Version = GetPython $USTFolder $DownloadFolder
#    GetUSTFiles $USTFolder $DownloadFolder $Version
#
#    # Try loop as connection occasionally fails the first time
#    while ($true)  {
#        try {
#            GetOpenSSL $USTFolder $DownloadFolder
#            break
#        }
#        catch {
#            Write-Host "Connection failed... retrying... ctrl-c to abort..."
#        }
#    }
#
#    FinalizeInstallation $USTFolder $DownloadFolder
#    Cleanup $DownloadFolder
#
#    Write-Host "Completed - You can begin to edit configuration files in $USTFolder"
#    Set-Location -Path $USTFolder
#
#    try{
#        #Open UST Install Folder
#        & explorer.exe $USTFolder
#    }catch {}

}else{
    Write-host "Not elevated. Re-run the script with elevated permission"
}


