#param([String]$py="xxx")
$ErrorActionPreference = "Stop"

$link = "https://raw.githubusercontent.com/janssenda/UST_Install_Scripts/master/dev/UST_quick_install_windows.ps1"

#Write-Host $py
#$setvar = "55555"; iex ((New-Object System.Net.WebClient).DownloadString($link))



(new-object net.webclient).DownloadFile($link,'local.ps1')
./local.ps1 -py yyyy