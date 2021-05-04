# Enter to REmote Server
$credential =Get-Credential
Enter-PSSession -ComputerName 3.135.137.226 -Credential $credential
# Create web server
 Get-WindowsFeature -Name web*
 Install-WindowsFeature -Name web-server -IncludeManagementTools -IncludeAllSubFeature
 Import-Module -Name WebAdministration
#Get-PSProvider
 # Create website
 cd c:\
#ls .\inetpub
 cd .\inetpub
# C:\inetpub> 
 New-Item -ItemType directory -Path testtask
 Write-Output '<head>HTML Example</head><br><body>testtask (Dev_AWS)</body>' |out-file .\testtask\index.html
 New-Website -Name testtask -PhysicalPath C:\inetpub\testtask -Port 80
 New-WebAppPool -Name testtask
 Start-IISSite -Name testtask
 Install-WindowsFeature rsat-dns-server
 Exit-PSSession

