#param([String]$py="xxx")
$ErrorActionPreference = "Stop"

$link = "https://raw.githubusercontent.com/janssenda/UST_Install_Scripts/master/dev/UST_quick_install_windows.ps1"

#Write-Host $py
#$setvar = "55555"; iex ((New-Object System.Net.WebClient).DownloadString($link))


(New-Object System.Net.WebClient).DownloadFile($link,"inst.ps1"); ./inst.ps1 -py 3; rm -Force ./inst.ps1;


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