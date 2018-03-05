# Install Scripts for UST and Dev
You should set the execution policy for powershell to allow your VM to run scripts temporarily

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

### Install UST / Python Only:
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vABrB","${PWD}\inst.ps1"); ./inst.ps1 -py 2; rm -Force ./inst.ps1;</code>

### Install full dev environment (Java, LDAP):
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADiN","${PWD}\inst.ps1"); ./inst.ps1 -py 2; rm -Force ./inst.ps1;</code>

### Exection notes:
Development installs the dev tools first, and automatically calls the UST script upon finishing -- no need to use both!!
Installation may fail on python 3 if windows server 2012 is not udpated.  You can choose which version to use by changing the -py flag
on the call. Values of 2 and 3 are allowed.  For example:

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); ./inst.ps1 <b>-py 2</b>; rm -Force ./inst.ps1;</code>

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); ./inst.ps1 <b>-py 3</b>; rm -Force ./inst.ps1;</code>

You can also use the -retry flag in order to automaticall install python 2 if python 3 fails to install

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); ./inst.ps1 <b>-retry</b>; rm -Force ./inst.ps1;</code>

