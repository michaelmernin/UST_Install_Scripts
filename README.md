# Install Scripts for UST and Dev
You should set the execution policy for powershell to allow your VM to run scripts temporarily

<code>Set-ExecutionPolicy Bypass -Scope Process;</code> 

### Install UST / Python Only:
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vABrB","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

### Install full dev environment (Java, LDAP):
<code>(New-Object System.Net.WebClient).DownloadFile("https://git.io/vADiN","${PWD}\inst.ps1"); .\inst.ps1; rm -Force .\inst.ps1;</code>

### Execution notes:
Development installs the dev tools first, and automatically calls the UST script upon finishing -- no need to use both!! The dev
environment includes a Spring Boot based mock LDAP server which can be used to simulate the directory side of User Sync. The LDAP server
can be configured using the provided properties and .ldif files.  The external ldif must be specified in the properties file
to be used (by default, the packaged version is used instead).  To run the server, call:

<code>java -jar ldap-test-server.jar</code>

To verify that the server contains users, visit <code>localhost:8080/index</code> in your browser.  Note that the port
may differ depending on your properties file.

##### Arguments

<code>-py <2 | 3></code>

You can choose which Python version to use by changing the -py flag
on the call. Values of 2 and 3 are allowed.  Note that Adobe recommends using at least Python 3.6.3 for future
support.

<code>-cleanpy</code>

This feature is useful! When used, the script will remove <b>all existing Python installations for all versions</b>, which
leaves the VM clean so that the correct versions can be used.  User Sync <b>requires</b> that the installed Python version be
64 bit! This flag helps to smooth and clean up the install process.


Example calls with flags:

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); .\inst.ps1 <b>-py 2</b>; rm -Force .\inst.ps1;</code>

<code>(New-Object System.Net.WebClient).DownloadFile("url-here","${PWD}\inst.ps1"); .\inst.ps1 <b>-cleanpy -retry</b>; rm -Force .\inst.ps1;</code>

