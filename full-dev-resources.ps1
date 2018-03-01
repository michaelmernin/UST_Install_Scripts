param([String]$py="3", [Switch]$retry=$false)

if ($py -eq "2"){
    $pythonVersion = "2"
} else {$pythonVersion = "3"}

$ErrorActionPreference = "Stop"

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

        $wc = New-Object net.webclient
        $wc.DownloadFile($7zURL,$7zDownload)

        #Invoke-WebRequest -Uri $7zURL -OutFile $7zDownload

        if(Test-Path $7zDownload){
            #Extract downloaded 7-zip to 7-zip temp folder
            Unzip -zipfile $7zDownload -outdir $7zipTempPath
        }

    }

    if ($ArchiveType -eq "tar")    {
        Start-Process cmd.exe -ArgumentList ("/c $7zipTempPath\7za.exe x $Path -so  | $7zipTempPath\7za.exe x -y -si -aoa -ttar -o`"$OutPut`"") -Wait

    } else {
        Start-Process cmd.exe -ArgumentList ("/c $7zipTempPath\7za.exe x $Path -y -tzip -aoa -o`"$OutPut`"") -Wait
    }
}

function SetDirectory(){

    $TARGETDIR = (Get-Item -Path ".\" -Verbose).FullName + "\LDAP_test_server"
    Write-Host "Creating directory $TARGETDIR... "
    New-Item -ItemType Directory -Force -Path $TARGETDIR | Out-Null

    return $TARGETDIR

}


function GetJava ($DownloadFolder){
    $JREURL = "https://github.com/janssenda/vm_resources/raw/master/jre-8u161-windows-x64.exe"


    $javaInstalled = Get-CimInstance -ClassName 'Win32_Product' -Filter "Name like 'Java%'"

    if ($javaInstalled){
        Write-Host "Java already installed! Skipping...  "
        return $false
    }


    $filename = $JREURL.Split('/')[-1]
    $javaExecutable = "$DownloadFolder\$filename"

    #Download file
    Write-Host "Downloading $filename from $JREURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($JREURL, $javaExecutable)

    if (Test-Path $javaExecutable)
    {
        Write-Host "Begin Java Installation"
        $javaProcess = Start-Process $javaExecutable -ArgumentList @('/s') -Wait -PassThru
        if ($javaProcess.ExitCode -eq 0)
        {
            Write-Host "Java Installation Completed"
            [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Java\jre1.8.0_161\bin", [EnvironmentVariableTarget]::Machine)
            return $true

        }
        else
        {
            Write-Host "Python Installation Completed/Error with ExitCode: $( $javaProcess.ExitCode )"
        }
    }
    return $false

}


function GetFiles ($LDAPFolder, $DownloadFolder) {
    $DownloadList = @()
    $DownloadList += "https://github.com/janssenda/vm_resources/raw/master/vm_common_resources.tar.gz"

    foreach($download in $DownloadList){
        $filename = $download.Split('/')[-1]
        $downloadfile = "$DownloadFolder\$filename"

        #Download file
        Write-Host "Downloading $filename from $download"

        $wc = New-Object net.webclient
        $wc.DownloadFile($download,$downloadfile)

        #Invoke-WebRequest -Uri $download -OutFile $downloadfile


        if(Test-Path $downloadfile){
            #Extract downloaded file to UST Folder
            Write-Host "Extracting $downloadfile to $LDAPFolder"
            Expand-Archive -Path $downloadfile -OutPut $LDAPFolder -ArchiveType tar
        }
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
    Write-Host "Elevated."

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $DownloadFolder = "$env:TEMP\LDAPDownload"
    $LDAPFolder = SetDirectory

    #Create Temp download folder
    New-Item -Path $DownloadFolder -ItemType "Directory" -Force | Out-Null

    GetFiles $LDAPFolder $DownloadFolder
    $requireRestart = GetJava $DownloadFolder

    Cleanup $DownloadFolder
    Write-Host "Completed - You can run the server from $LDAPFolder"

    $link = "https://raw.githubusercontent.com/janssenda/UST_Install_Scripts/master/UST_quick_install_windows.ps1"
    (New-Object System.Net.WebClient).DownloadFile($link,"instd.ps1"); ./instd.ps1 -py $pythonVersion; rm -Force ./instd.ps1;

    if ($requireRestart){
        Write-Host "`n`n(GUI mode only) You must restart the computer before you can run java -jar on the LDAP server...`n`n"
    }

}else{
    Write-host "Not elevated. Re-run the script with elevated permission"
}


