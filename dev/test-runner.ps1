#param([String]$py="xxx")
$ErrorActionPreference = "Stop"

$link = "https://raw.githubusercontent.com/janssenda/UST_Install_Scripts/master/dev/UST_quick_install_windows.ps1"

#Write-Host $py
#$setvar = "55555"; iex ((New-Object System.Net.WebClient).DownloadString($link))



(New-Object System.Net.WebClient).DownloadFile($link,'sync.ps1'); ./sync.ps1 -py 2; rm -Force ./local.ps1;