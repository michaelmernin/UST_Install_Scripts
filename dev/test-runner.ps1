$ErrorActionPreference = "Stop"

$link = "https://raw.githubusercontent.com/janssenda/UST_Install_Scripts/master/dev/UST_quick_install_windows.ps1"
$setvar = "55555"
Write-Host $setvar
iex ((New-Object System.Net.WebClient).DownloadString($link))



