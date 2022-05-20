# run this script as an VM extension during ARM template deployment
# copy the script from the GitHub repo
$gitHubRepo = 'https://raw.githubusercontent.com/mbakunas/ARM-Stuff/main/0-Common/DSC/Default.htm'
$destinationPath = 'C:\inetpub\wwwroot\Default.htm'
Invoke-WebRequest -Uri $gitHubRepo -OutFile $destinationPath

# replace "hostname" with the VM's computername
(Get-Content -Path $destinationPath) -replace 'hostname', "$($env:COMPUTERNAME)" | Set-Content -Path $destinationPath