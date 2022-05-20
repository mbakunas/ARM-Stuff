# run this script as an VM extension during ARM template deployment
$destinationPath = 'C:\inetpub\wwwroot\Default.htm'
$newLine = "<h1 style=`"color:white`">$($env:COMPUTERNAME)</h1>"

# add in a line with the server's hostname
$defaultContent = Get-Content -Path $destinationPath
@($defaultContent[0..28]; $newLine; $defaultContent[29..31]) | Set-Content -Path $destinationPath
