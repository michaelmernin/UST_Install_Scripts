# Install Scripts for UST and Dev

### Install UST / Python Only:
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADrY","inst.ps1"); ./inst.ps1 -py 2; rm -Force ./inst.ps1;</code>

### Install full dev environment (Java, LDAP):
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADrk","inst.ps1"); ./inst.ps1 -py 2; rm -Force ./inst.ps1;</code>

### Exection notes:
Development installs the dev tools first, and automatically calls the UST script upon finishing -- no need to use both!!
Installation may fail on python 3 if windows server 2012 is not udpated.  You can choose which version to use by changing the -py flag
on the call.  For example:

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADrY","inst.ps1"); ./inst.ps1 <b>-py 2</b>; rm -Force ./inst.ps1;</code>
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADrY","inst.ps1"); ./inst.ps1 <b>-py 3</b>; rm -Force ./inst.ps1;</code>

You can also use the -retry flag in order to automaticall install python 2 if python 3 fails to install

<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADrY","inst.ps1"); ./inst.ps1 <b>-retry</b>; rm -Force ./inst.ps1;</code>