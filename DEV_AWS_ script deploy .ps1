# Enter to REmote Server
$credential =Get-Credential
Enter-PSSession -ComputerName 3.135.137.226 -Credential $credential
# Create web server
 Install-WindowsFeature -Name web-server -IncludeManagementTools -IncludeAllSubFeature
 Import-Module -Name WebAdministration
 # Create website
 cd c:\
 cd .\inetpub
 New-Item -ItemType directory -Path testtask
 Write-Output '<head>HTML Example</head><br><body>testtask (Dev_AWS)</body>' |out-file .\testtask\index.html
 New-Website -Name testtask -PhysicalPath C:\inetpub\testtask -Port 80
 New-WebAppPool -Name testtask
 Start-IISSite -Name testtask
 Install-WindowsFeature rsat-dns-server
 Exit-PSSession

