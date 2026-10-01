<#
    .NOTES
	Created by:		Russell Hamker
	Date:			September 29, 2026
	Version:		2.0.1
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903

	.SYNOPSIS
	This script automates the generation of certificates for VMware. This script can be used to create Web or Subordinate CA Certificates.
	This includes generating all certificates using a Windows CA and CA Template. You must open this script and change the variables 
	to match your environment and then execute the PS1 file.

	.DESCRIPTION
	Use this script to build the certificate for your VMware Environment. Fill in the variables and then simply run this
	script to automate the process of generating the certificate.

	.EXAMPLE
	#Example - VCF Installer
	$Shortname = "vcfinstaller" # Short Name for FQDN
	$IPAddress = "10.10.1.66" # IP Address of FQDN
	$Domain = "hamker.local" # Domain FQDN
	$CertTemplate = "CertificateTemplate:VMwareWebServer" # To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName
	$CertType = "WebServer" # Pick from VCSA, Operations, WebServer, or SubordinateCA
	$Country = "US" # 2 Letter Country Code
	$State = "KS" # Your State
	$City = "Wichita" # Your City
	$Company = "Hamker Tech" # Your Company
	$Department = "IT VMware Team" # Your Department
	$EmailAddress = "YourGroupEmailAddressHere@me.com" # Department Email								  
	$CAFolder = "C:\certs\CAs\Combined" # Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from
	$CertificateServer = "hamca01.hamker.local" # FQDN of the Certificate server you are getting your certs from
	./generate-certificate-files.ps1 `
	-Shortname $Shortname `
	-IPAddress $IPAddress `
	-Domain $Domain `
	-CertTemplate $CertTemplate `
	-CertType $CertType `
	-Country $Country `
	-State $State `
	-City $City `
	-Company $Company `
	-Department $Department `
	-EmailAddress $EmailAddress `
	-CAFolder $CAFolder `
	-CertificateServer $CertificateServer

	.EXAMPLE
	#Example - VCSA Machine SSL Certificate
	$Shortname = "hamvc02" # Short Name for FQDN
	$IPAddress = "192.168.1.66" # IP Address of FQDN
	$Domain = "hamker.local" # Domain FQDN
	$CertTemplate = "CertificateTemplate:VMwareWebServer" # To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName
	$CertType = "VCSA" # Pick from VCSA, Operations, WebServer, or SubordinateCA
	$Country = "US" # 2 Letter Country Code
	$State = "KS" # Your State
	$City = "Wichita" # Your City
	$Company = "Hamker Tech" # Your Company
	$Department = "IT VMware Team" # Your Department
	$EmailAddress = "YourGroupEmailAddressHere@me.com" # Department Email								  
	$CAFolder = "C:\certs\CAs\Combined" # Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from
	$CertificateServer = "hamca01.hamker.local" # FQDN of the Certificate server you are getting your certs from
	./generate-certificate-files.ps1 `
	-Shortname $Shortname `
	-IPAddress $IPAddress `
	-Domain $Domain `
	-CertTemplate $CertTemplate `
	-CertType $CertType `
	-Country $Country `
	-State $State `
	-City $City `
	-Company $Company `
	-Department $Department `
	-EmailAddress $EmailAddress `
	-CAFolder $CAFolder `
	-CertificateServer $CertificateServer

	.EXAMPLE
	#Example - VCSASubordinate CA Certificate
	$Shortname = "hamvc02" # Short Name for FQDN
	$IPAddress = "192.168.1.66" # IP Address of FQDN
	$Domain = "hamker.local" # Domain FQDN
	$CertTemplate = "CertificateTemplate:SubCA" # To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName
	$CertType = "SubordinateCA" # Pick from VCSA, Operations, WebServer, or SubordinateCA
	$Country = "US" # 2 Letter Country Code
	$State = "KS" # Your State
	$City = "Wichita" # Your City
	$Company = "Hamker Tech" # Your Company
	$Department = "IT VMware Team" # Your Department
	$EmailAddress = "YourGroupEmailAddressHere@me.com" # Department Email								  
	$CAFolder = "C:\certs\CAs\Combined" # Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from
	$CertificateServer = "hamca01.hamker.local" # FQDN of the Certificate server you are getting your certs from
	./generate-certificate-files.ps1 `
	-Shortname $Shortname `
	-IPAddress $IPAddress `
	-Domain $Domain `
	-CertTemplate $CertTemplate `
	-CertType $CertType `
	-Country $Country `
	-State $State `
	-City $City `
	-Company $Company `
	-Department $Department `
	-EmailAddress $EmailAddress `
	-CAFolder $CAFolder `
	-CertificateServer $CertificateServer

	.EXAMPLE
	#Example - VCF Operations - Multinode Operations Deployment 
	$Shortname = "vcfops1" # Short Name for Primary Node FQDN
	$IPAddress = "192.168.1.161" # IP Address of Primary Node FQDN
	$Shortname2 = "vcfops2" # Short Name for Node 2 FQDN
	$IPAddress2 = "192.168.1.162" # IP Address of Node 2 FQDN
	$Shortname3 = "vcfops3" # Short Name for Node 3 FQDN
	$IPAddress3 = "192.168.1.163" # IP Address of Node 3 FQDN
	$Domain = "hamker.local" # Domain FQDN
	$CertTemplate = "CertificateTemplate:VMwareWebServer" # To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName
	$CertType = "Operations" # Pick from VCSA, Operations, WebServer, or SubordinateCA
	$Country = "US" # 2 Letter Country Code
	$State = "KS" # Your State
	$City = "Wichita" # Your City
	$Company = "Hamker Tech" # Your Company
	$Department = "IT VMware Team" # Your Department
	$EmailAddress = "YourGroupEmailAddressHere@me.com" # Department Email								  
	$CAFolder = "C:\certs\CAs\Combined" # Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from
	$CertificateServer = "hamca01.hamker.local" # FQDN of the Certificate server you are getting your certs from
	./generate-certificate-files.ps1 `
	-Shortname $Shortname `
	-IPAddress $IPAddress `
	-Shortname2 $Shortname2 `
	-IPAddress2 $IPAddress2 `
	-Shortname3 $Shortname3 `
	-IPAddress3 $IPAddress3 `
	-Domain $Domain `
	-CertTemplate $CertTemplate `
	-CertType $CertType `
	-Country $Country `
	-State $State `
	-City $City `
	-Company $Company `
	-Department $Department `
	-EmailAddress $EmailAddress `
	-CAFolder $CAFolder `
	-CertificateServer $CertificateServer

#>

param(
	[Parameter(Mandatory=$true)][string]$Shortname,
	[Parameter(Mandatory=$true)][string]$IPAddress,
	[Parameter(Mandatory=$true)][string]$Domain,
	[Parameter(Mandatory=$true)][string]$CertTemplate,
	[Parameter(Mandatory=$true)][ValidateSet('VCSA','SubordinateCA','Operations','WebServer')][string]$CertType,
	[Parameter(Mandatory=$true)][string]$Country,
	[Parameter(Mandatory=$true)][string]$State,
	[Parameter(Mandatory=$true)][string]$City,
	[Parameter(Mandatory=$true)][string]$Company,
	[Parameter(Mandatory=$true)][string]$Department,
	[Parameter(Mandatory=$true)][string]$EmailAddress,
	[Parameter(Mandatory=$true)][string]$CAFolder,
	[Parameter(Mandatory=$true)][string]$CertificateServer,
	[Parameter(Mandatory=$false)][string]$Shortname2,
	[Parameter(Mandatory=$false)][string]$IPAddress2,
	[Parameter(Mandatory=$false)][string]$Shortname3,
	[Parameter(Mandatory=$false)][string]$IPAddress3,
	[Parameter(Mandatory=$false)][string]$Shortname4,
	[Parameter(Mandatory=$false)][string]$IPAddress4,
	[Parameter(Mandatory=$false)][string]$Shortname5,
	[Parameter(Mandatory=$false)][string]$IPAddress5,
	[Parameter(Mandatory=$false)][string]$Shortname6,
	[Parameter(Mandatory=$false)][string]$IPAddress6,
	[Parameter(Mandatory=$false)][string]$Shortname7,
	[Parameter(Mandatory=$false)][string]$IPAddress7,
	[Parameter(Mandatory=$false)][string]$Shortname8,
	[Parameter(Mandatory=$false)][string]$IPAddress8,
	[Parameter(Mandatory=$false)][string]$Shortname9,
	[Parameter(Mandatory=$false)][string]$IPAddress9,
	[Parameter(Mandatory=$false)][string]$Shortname10,
	[Parameter(Mandatory=$false)][string]$IPAddress10,
	[Parameter(Mandatory=$false)][string]$Shortname11,
	[Parameter(Mandatory=$false)][string]$IPAddress11,
	[Parameter(Mandatory=$false)][string]$Shortname12,
	[Parameter(Mandatory=$false)][string]$IPAddress12,
	[Parameter(Mandatory=$false)][string]$Shortname13,
	[Parameter(Mandatory=$false)][string]$IPAddress13,
	[Parameter(Mandatory=$false)][string]$Shortname14,
	[Parameter(Mandatory=$false)][string]$IPAddress14,
	[Parameter(Mandatory=$false)][string]$Shortname15,
	[Parameter(Mandatory=$false)][string]$IPAddress15,
	[Parameter(Mandatory=$false)][string]$Shortname16,
	[Parameter(Mandatory=$false)][string]$IPAddress16,
	[Parameter(Mandatory=$false)][string]$Shortname17,
	[Parameter(Mandatory=$false)][string]$IPAddress17,
	[Parameter(Mandatory=$false)][string]$Shortname18,
	[Parameter(Mandatory=$false)][string]$IPAddress18,
	[Parameter(Mandatory=$false)][string]$Shortname19,
	[Parameter(Mandatory=$false)][string]$IPAddress19,
	[Parameter(Mandatory=$false)][string]$Shortname20,
	[Parameter(Mandatory=$false)][string]$IPAddress20
)

# Get Present Location
$LOCATION = Get-Location

# Standardize formatting
$Shortname = $Shortname.ToLower()
$FQDN = ("$Shortname.$Domain").ToLower()

# Standard Variables
$CERTLOCATION = "C:\Certs"
$CertLocationGet = Get-Item "$CERTLOCATION\$CertType\$FQDN" -ErrorAction SilentlyContinue
$CertLocation = "$CERTLOCATION\$CertType\$FQDN"
$KEYGET = Get-Item "$CertLocation\$Shortname.key" -ErrorAction SilentlyContinue
$KEY = "$CertLocation\$Shortname.key" # This is in RSA format
$KEYPEMGET = Get-Item "$CertLocation\$Shortname-key.pem" -ErrorAction SilentlyContinue
$KEYPEMNAME = "$Shortname-key.pem"
$KEYPEM = "$CertLocation\$KEYPEMNAME" # This is in PEM format
$CSRGET = Get-Item "$CertLocation\$Shortname.csr" -ErrorAction SilentlyContinue
$CSR = "$CertLocation\$Shortname.csr"
$CERGET = Get-Item "$CertLocation\$Shortname.cer" -ErrorAction SilentlyContinue
$CER = "$CertLocation\$Shortname.cer" #This is in DER format
$PEMGET = Get-Item "$CertLocation\$Shortname.pem" -ErrorAction SilentlyContinue
$PEM = "$CertLocation\$Shortname.pem" # This is in PEM format
$COMBINEDPEMNAME = "$Shortname-sslCertificateChain.pem"
$COMBINEDPEM = "$CertLocation\$COMBINEDPEMNAME" # This is in PEM format. This is the file you use to install the certificate with.

# Certificate Variables
$CACERT = "$CertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

# Logging Info
# Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
# Specify Log File Info
$LOGFILENAME = "Log_" + $Shortname + "_" + $LOGDATE + ".txt"
# Create Log Folder
$LogFolder = $CertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
# Specify Log File
$LOGFILE = $CertLocation+"\Log\"+$LOGFILENAME

# Starting Logging
Start-Transcript -path $LOGFILE -Append

# Test if OpenSSL is Installed
# Specify OpenSSL version. If you have a 64-bit OS, use the x64 version. If you have a 32-bit OS, use the x86 version
$OPENSSL = Get-Item "C:\Program Files\OpenSSL-Win64\bin\OpenSSL.exe" -ErrorAction SilentlyContinue ##x64 version 
IF(!$OPENSSL){
	Write-Warning "OpenSSL is not installed"
	Write-Warning "Please download and install OpenSSL"
	Write-Warning "Download similar to version Win64 OpenSSL v1.1.1b Light"
	Write-Warning "https://slproweb.com/products/Win32OpenSSL.html"
	Write-Warning "Example downlod would be https://slproweb.com/download/Win64OpenSSL_Light-1_1_1b.msi"
	write-host "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
}Else{
	Write-Host "Verified: OpenSSL has been properly installed" -ForegroundColor Green
}

# Verify that OpenSSL is installed
If($OPENSSL){

	#CNF Config

If($CertType -eq "SubordinateCA"){
$REQ = @'
[ req ]
default_md = sha256
default_bits = 4096
default_keyfile = key.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_ca
'@ -replace "(?m)^\s+", ""

$V3 = @"
[ v3_ca ]
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
extendedKeyUsage = critical, serverAuth, clientAuth
subjectAltName = @alt_names
subjectKeyIdentifier = hash
"@ -replace "(?m)^\s+", ""
}
If($CertType -eq "VCSA"){
$REQ = @'
[ req ]
default_md = sha256
default_bits = 2048
default_keyfile = key.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req
'@ -replace "(?m)^\s+", ""

$V3 = @"
[ v3_req ]
basicConstraints = CA:false
keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
subjectKeyIdentifier = hash
"@ -replace "(?m)^\s+", ""
}
If($CertType -eq "Operations"){
$REQ = @'
[ req ]
default_md = sha256
default_bits = 2048
default_keyfile = key.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req
'@ -replace "(?m)^\s+", ""

$V3 = @"
[ v3_req ]
basicConstraints = CA:false
keyUsage = keyEncipherment, digitalSignature, keyAgreement
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
"@ -replace "(?m)^\s+", ""
}
If($CertType -eq "WebServer"){
$REQ = @'
[ req ]
default_md = sha256
default_bits = 2048
default_keyfile = key.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req
'@ -replace "(?m)^\s+", ""

$V3 = @"
[ v3_req ]
basicConstraints = CA:false
keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
extendedKeyUsage = clientAuth
subjectAltName = @alt_names
subjectKeyIdentifier = hash
"@ -replace "(?m)^\s+", ""
}

# Add line after REQ
$REQ += "`n"

# Add line after V3
$V3 += "`n"
		
$ALTNAMES = @"
[ alt_names ]
email = $EmailAddress
IP.1 = $IPAddress
DNS.1 = $FQDN
"@ -replace "(?m)^\s+", ""

If($IPAddress2){
	$ALTNAMES += "`nIP.2 = $IPAddress2"
}
If($Shortname2){
	$FQDN2 = $Shortname2 + "." + $Domain
	$ALTNAMES += "`nDNS.2 = $FQDN2"
}
If($IPAddress3){
	$ALTNAMES += "`nIP.3 = $IPAddress3"
}
If($Shortname3){
	$FQDN3 = $Shortname3 + "." + $Domain
	$ALTNAMES += "`nDNS.3 = $FQDN3"
}
If($IPAddress4){
	$ALTNAMES += "`nIP.4 = $IPAddress4"
}
If($Shortname4){
	$FQDN4 = $Shortname4 + "." + $Domain
	$ALTNAMES += "`nDNS.4 = $FQDN4"
}
If($IPAddress5){
	$ALTNAMES += "`nIP.5 = $IPAddress5"
}
If($Shortname5){
	$FQDN5 = $Shortname5 + "." + $Domain
	$ALTNAMES += "`nDNS.5 = $FQDN5"
}
If($IPAddress6){
	$ALTNAMES += "`nIP.6 = $IPAddress6"
}
If($Shortname6){
	$FQDN6 = $Shortname6 + "." + $Domain
	$ALTNAMES += "`nDNS.6 = $FQDN6"
}
If($IPAddress7){
	$ALTNAMES += "`nIP.7 = $IPAddress7"
}
If($Shortname7){
	$FQDN7 = $Shortname7 + "." + $Domain
	$ALTNAMES += "`nDNS.7 = $FQDN7"
}
If($IPAddress8){
	$ALTNAMES += "`nIP.8 = $IPAddress8"
}
If($Shortname8){
	$FQDN8 = $Shortname8 + "." + $Domain
	$ALTNAMES += "`nDNS.8 = $FQDN8"
}
If($IPAddress9){
	$ALTNAMES += "`nIP.9 = $IPAddress9"
}
If($Shortname9){
	$FQDN9 = $Shortname9 + "." + $Domain
	$ALTNAMES += "`nDNS.9 = $FQDN9"
}
If($IPAddress10){
	$ALTNAMES += "`nIP.10 = $IPAddress10"
}
If($Shortname10){
	$FQDN10 = $Shortname10 + "." + $Domain
	$ALTNAMES += "`nDNS.10 = $FQDN10"
}
If($IPAddress11){
	$ALTNAMES += "`nIP.11 = $IPAddress11"
}
If($Shortname11){
	$FQDN11 = $Shortname11 + "." + $Domain
	$ALTNAMES += "`nDNS.11 = $FQDN11"
}
If($IPAddress12){
	$ALTNAMES += "`nIP.12 = $IPAddress12"
}
If($Shortname12){
	$FQDN12 = $Shortname12 + "." + $Domain
	$ALTNAMES += "`nDNS.12 = $FQDN12"
}
If($IPAddress13){
	$ALTNAMES += "`nIP.13 = $IPAddress13"
}
If($Shortname13){
	$FQDN13 = $Shortname13 + "." + $Domain
	$ALTNAMES += "`nDNS.13 = $FQDN13"
}
If($IPAddress14){
	$ALTNAMES += "`nIP.14 = $IPAddress14"
}
If($Shortname14){
	$FQDN14 = $Shortname14 + "." + $Domain
	$ALTNAMES += "`nDNS.14 = $FQDN14"
}
If($IPAddress15){
	$ALTNAMES += "`nIP.15 = $IPAddress15"
}
If($Shortname15){
	$FQDN15 = $Shortname15 + "." + $Domain
	$ALTNAMES += "`nDNS.15 = $FQDN15"
}
If($IPAddress16){
	$ALTNAMES += "`nIP.16 = $IPAddress16"
}
If($Shortname16){
	$FQDN16 = $Shortname16 + "." + $Domain
	$ALTNAMES += "`nDNS.16 = $FQDN16"
}
If($IPAddress17){
	$ALTNAMES += "`nIP.17 = $IPAddress17"
}
If($Shortname17){
	$FQDN17 = $Shortname17 + "." + $Domain
	$ALTNAMES += "`nDNS.17 = $FQDN17"
}
If($IPAddress18){
	$ALTNAMES += "`nIP.18 = $IPAddress18"
}
If($Shortname18){
	$FQDN18 = $Shortname18 + "." + $Domain
	$ALTNAMES += "`nDNS.18 = $FQDN18"
}
If($IPAddress19){
	$ALTNAMES += "`nIP.19 = $IPAddress19"
}
If($Shortname19){
	$FQDN19 = $Shortname19 + "." + $Domain
	$ALTNAMES += "`nDNS.19 = $FQDN19"
}
If($IPAddress20){
	$ALTNAMES += "`nIP.20 = $IPAddress20"
}
If($Shortname20){
	$FQDN20 = $Shortname20 + "." + $Domain
	$ALTNAMES += "`nDNS.20 = $FQDN20"
}
	
# Add line after ALTNAMES
$ALTNAMES += "`n"

$DISTINGUISHEDNAME =@"
[ req_distinguished_name ]
CN = $FQDN
C = $Country
ST = $State
L = $City
O = $Company
OU = $Department
emailAddress = $EmailAddress
"@ -replace "(?m)^\s+", ""

	# Combine all variables into 1 full CNF Request
	$CNF = $REQ + $V3 + $ALTNAMES + $DISTINGUISHEDNAME

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certificate Creation Process"
	Set-Location $OpenSSLLocation
	
	# Make new Cert Folder for storing all the Cert files
	If(!$CertLocationGet){
		New-Item -Path $CertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "$CertType Folder already created at" $CertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	# Make Certificate Config file
	$CFGFILE = New-Item -Path $CertLocation -Name "$Shortname.cfg" -ItemType "file" -Force
	
	# Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$KEYGET){
		# Open OpenSSL EXE Location
		Set-Location $OpenSSLLocation
		.\openssl genrsa -out $KEY 4096

		# Update output for Unix format
		[IO.File]::WriteAllText("$KEY", ([IO.File]::ReadAllText("$KEY") -replace "`r`n","`n"))

		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $KEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$KEYPEMGET){
		Write-Host "$KEYPEM file does not exist"
		Write-Host "Generating $KEYPEM file"
		# Open OpenSSL EXE Location
		Set-Location $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $KEY -outform PEM -nocrypt -out $KEYPEM
		# Update output for Unix format
		[IO.File]::WriteAllText("$KEYPEM", ([IO.File]::ReadAllText("$KEYPEM") -replace "`r`n","`n"))
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $KEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$CSRGET){
		Write-Host "CSR File Not Found"
		Write-Host "Generating CSR"
		#Open OpenSSL EXE Location
		Set-Location $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $KEY -out $CSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}Else{
		Write-Host "Server.csr already generated at" $CSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	# Read CSR
	Write-Host "CSR Info is:" $CSR -ForegroundColor Blue
	.\openssl req -in $CSR -noout -text
	
	$CA = certutil -config $CertificateServer -ping
	$CA = $CA[1]
	$CA = $CA.Replace("Server "," ")
	$CA = $CA.SubString(0, $CA.IndexOf('ICertRequest2'))
	$CA = $CA.Replace('"','')
	$CA = $CA.Replace(' ','')

	# To List the Certificate Templates to get the right 1
	# certutil -template | Select-String -Pattern TemplatePropCommonName
	# Detailed Example certutil -template | Select-String -Pattern Vmware6.0WebServer
	
	# Generate CER
	If(!$CERGET){
		certreq -submit -attrib $CertTemplate -Kerberos -config $CertificateServer\$CA $CSR $CER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $CER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	# Checking if CER was Generated
	$CERGETVALIDATE = Get-Item "$CertLocation\$Shortname.cer" -ErrorAction SilentlyContinue
	
	If($CERGETVALIDATE){
		Write-Host "CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($CERGETVALIDATE.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		If(!$PEMGET){
			#Open OpenSSL EXE Location
			Set-Location $OpenSSLLocation
			.\openssl x509 -in $CER -outform PEM -out $PEM

			#Update output for Unix format
			[IO.File]::WriteAllText("$PEM", ([IO.File]::ReadAllText("$PEM") -replace "`r`n","`n"))

			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}Else{
			Write-Host "Server.pem already generated at" $PEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		# Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFolder | Where-Object {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1){
			# Place your CA Cert to the proper folder
			Write-Host "Copying CA PEM File to Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")

			If($CertType -match "VCSA|SubordinateCA|WebServer"){
				# Create Full Chain PEM File
				Write-Host "Creating Full Chain PEM File" -ForegroundColor Green
				Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
				$STEP1 = Get-Content $PEM 
				$STEP2 = Get-Content $CACERT 
				$COMBINESTEPS = $STEP1 + $STEP2
				$COMBINESTEPS | Set-Content $COMBINEDPEM
			}
			If($CertType -match "Operations"){
				# Create Full Chain VCF Operations PEM File
				Write-Host "Creating Full Chain PEM File"
				Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
				# Reference https://knowledge.broadcom.com/external/article?legacyId=2046591
				# Reference 2 https://docs.vmware.com/en/vRealize-Operations-Manager/8.0/com.vmware.vcom.core.doc/GUID-D476DD8F-0CCA-460D-BE94-9AC3F677B1EA.html
				$STEP1 = Get-Content $PEM
				$STEP2 = Get-Content $KEY
				$STEP3 = Get-Content $CACERT 
				$COMBINESTEPS = $STEP1 + $STEP2 + $STEP3
				$COMBINESTEPS | Set-Content $COMBINEDPEM
			}

			# Update output for Unix format
			[IO.File]::WriteAllText("$COMBINEDPEM", ([IO.File]::ReadAllText("$COMBINEDPEM") -replace "`r`n","`n"))
			
			# Output name of pem full chain
			Set-Location $OpenSSLLocation
			# openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $COMBINEDPEM -text -noout
			
			# Verify Certificate Files
			Write-Host "Displaying Certificate Issuer Chain"
			./openssl crl2pkcs7 -nocrl -certfile $PEM | ./openssl pkcs7 -print_certs -noout
			Write-Host "Displaying MD5 of the $PEM"
			$PEMMD5 = ./openssl x509 -modulus -noout -in $PEM | ./openssl md5
			$PEMMD5 = $PEMMD5.replace("(stdin)= ","")
			Write-Host $PEMMD5
			Write-Host "Displaying MD5 of the $KEYPEM"
			$KEYPEMMD5 = ./openssl rsa -modulus -noout -in $KEYPEM | ./openssl md5
			$KEYPEMMD5 = $KEYPEMMD5.replace("(stdin)= ","")
			Write-Host $KEYPEMMD5
			If($PEMMD5 -eq $KEYPEMMD5)
			{
				Write-Host "MD5s Match for PEM and KEYPEM" -foreground green
			}Else{
				Write-Error "MD5 DO NOT MATCH FOR PEM and KEYPEM"
			}
			Write-Host "  "
			Write-Host "Getting Certificate SHA-1 Thumbprint"
			$THUMBPRINTSHA1 = ./openssl x509 -noout -fingerprint -sha1 -inform pem -in $PEM
			$THUMBPRINTSHA1 = $THUMBPRINTSHA1.replace("SHA1 Fingerprint=","")
			Write-Host $THUMBPRINTSHA1
			Write-Host "  "
			Write-Host "Getting Certificate SHA-256 Thumbprint (Needed for NSX-T)"
			$THUMBPRINTSHA256 = ./openssl x509 -noout -fingerprint -sha256 -inform pem -in $PEM
			$THUMBPRINTSHA256 = $THUMBPRINTSHA256.replace("SHA256 Fingerprint=","")
			Write-Host $THUMBPRINTSHA256
			Write-Host "  "
			Write-Host "$FQDN Certificate Generation Process Completed" $COMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			If($CertType -eq "SubordinateCA"){
				Write-Host "-----------------------------------------------------------------------------------------------------------------------"
				Write-Host "Certificate Type - $CertType"
				Write-Host "Use this file to install the Cert on your VCSA" $COMBINEDPEM -ForegroundColor Green
				Write-Host "Use this file to install the Key on your VCSA" $KEYPEM -ForegroundColor Green
				Write-Host "Use this file to install the CA cert on your VCSA" $CACERT -ForegroundColor Green
				Write-Host "#######################################################################################################################"
				Write-Host "Directions:"	
Write-Host @"
SSH to your VCSA using the root login

#Create a \certs folder
mkdir \certs

#Copy Certificates listed below to \certs. Use WinSCP or some other means to copy files over.
$COMBINEDPEM
$KEYPEM
$CACERT

#Start Certificate Manager
cd /
./usr/lib/vmware-vmca/bin/certificate-manager

#An Option box like Below will Appear:
				_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
				|                                                                     |
				|      *** Welcome to the vSphere 6.7 Certificate Manager  ***        |
				|                                                                     |
				|                   -- Select Operation --                            |
				|                                                                     |
				|      1. Replace Machine SSL certificate with Custom Certificate     |
				|                                                                     |
				|      2. Replace VMCA Root certificate with Custom Signing           |
				|         Certificate and replace all Certificates                    |
				|                                                                     |
				|      3. Replace Machine SSL certificate with VMCA Certificate       |
				|                                                                     |
				|      4. Regenerate a new VMCA Root Certificate and                  |
				|         replace all certificates                                    |
				|                                                                     |
				|      5. Replace Solution user certificates with                     |
				|         Custom Certificate                                          |
				|                                                                     |
				|      6. Replace Solution user certificates with VMCA certificates   |
				|                                                                     |
				|      7. Revert last performed operation by re-publishing old        |
				|         certificates                                                |
				|                                                                     |
				|      8. Reset all Certificates                                      |
				|_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _|

#Select Option 2
#2. Replace VMCA Root certificate with Custom Signing Certificate and replace all Certificates

#It will ask for credenitials like below
Please provide valid SSO and VC privileged user credential to perform certificate operations.
Enter username [Administrator@vsphere.local]:
Enter password:

#Use the administrator@vsphere.local Account
administrator@vsphere.local

#Type in the administrator@vsphere.local password

#An Option box like Below will Appear:
Please provide valid SSO and VC privileged user credential to perform certificate operations.
Enter username [Administrator@vsphere.local]:
Enter password:
		1. Generate Certificate Signing Request(s) and Key(s) for Machine SSL certificate

		2. Import custom certificate(s) and key(s) to replace existing Machine SSL certificate

Option [1 or 2]:

#Select Option 2
#2. Import custom certificate(s) and key(s) to replace existing VMCA Root Signing certificate
2

#Specify the name of the file below for
#Please provide valid custom certificate for Root.
/certs/$COMBINEDPEMNAME

#Specify the name of the file below for
#Please provide valid custom key for Root.
/certs/$KEYPEMNAME

#Specify Y for the below
#You are going to replace Root Certificate with custom certificate and regenerate all other certificates
#Continue operation : Option[Y/N] ? :
Y

#After clicking Y, this will take some time to complete. You MUST wait for the process to complete.
#This will take 5-10 minutes. Services will stop and start as part of this process.

#Example Output
#Status : 60% Completed [Replace vpxd-extension Cert...]
#Updating new vpxd-extension certificate for VC extended solutions

#Updating the certificate for VC extension com.vmware.vim.eam

#Updating the certificate for VC extension com.vmware.rbd

#Updating the certificate for VC extension com.vmware.imagebuilder
#Status : 100% Completed [All tasks completed successfully]

#Verify all services are update
service-control --status --all

#Validate you have no Self-Signed CA Certificates
#https://knowledge.broadcom.com/external/article/312677/a-general-system-error-occurred-unable-t.html
/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store TRUSTED_ROOTS --text | egrep 'Alias|Issuer|Key Usage' -A 1 | grep -v "Entry type"

#If you have Self-Signed CA Certificates, remove them
#Backup Self-Signed CA Certificated
/usr/lib/vmware-vmafd/bin/vecs-cli entry getcert --store TRUSTED_ROOTS --alias <alias name> --output /certs/<aliasname.crt>
#Unpublish Certificate
/usr/lib/vmware-vmafd/bin/dir-cli trustedcert unpublish --cert /certs/<aliasname.crt> --login administrator
#delete the certificate from TRUSTED_ROOTS store if it is published
/usr/lib/vmware-vmafd/bin/vecs-cli entry delete --store TRUSTED_ROOTS --alias <alias name> -y

#You must either wait 24 hours to renew certificates on Hosts, or change an advanced setting on the VCSA to allow to renew the certificates on the hosts earlier
#Updated VCSA Advanced Setting vpxd.certmgmt.certs.minutesBefore from 1440 (24 hours) to 10
"@ -replace "(?m)^\s+", ""
				Write-Host "#######################################################################################################################"
			}
			If($CertType -eq "VCSA"){
				Write-Host "-----------------------------------------------------------------------------------------------------------------------"
				Write-Host "Certificate Type - $CertType"
				Write-Host "VCSA Certificate Generation Process Completed" $COMBINEDPEM -ForegroundColor Green
				Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
				Write-Host "-----------------------------------------------------------------------------------------------------------------------"
				Write-Host "Use this file to install the Cert on your VCSA" $COMBINEDPEM -ForegroundColor Green
				Write-Host "Use this file to install the Key on your VCSA" $KEYPEM -ForegroundColor Green
				Write-Host "Use this file to install the CA cert on your VCSA" $CACERT -ForegroundColor Green
				Write-Host "#######################################################################################################################"
				Write-Host "Directions:"
				$VAMIURL = "https://$FQDN"+":5480/login"
Write-Host @"
SSH to your VCSA using the root login

#Create a \certs folder
mkdir \certs

#Copy Certificates listed below to \certs. Use WinSCP or some other means to copy files over.
$COMBINEDPEM
$KEYPEM
$CACERT

#Start Certificate Manager
cd /
./usr/lib/vmware-vmca/bin/certificate-manager

#An Option box like Below will Appear:
				 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
				|                                                                     |
				|      *** Welcome to the vSphere 9.0 Certificate Manager  ***        |
				|                                                                     |
				|                   -- Select Operation --                            |
				|                                                                     |
				|      1. Replace Machine SSL certificate with Custom Certificate     |
				|                                                                     |
				|      2. Replace VMCA Root certificate with Custom Signing           |
				|         Certificate and replace all Certificates                    |
				|                                                                     |
				|      3. Replace Machine SSL certificate with VMCA Certificate       |
				|                                                                     |
				|      4. Regenerate a new VMCA Root Certificate and                  |
				|         replace all certificates                                    |
				|                                                                     |
				|      5. Replace Solution user certificates with                     |
				|         Custom Certificate                                          |
				|                                                                     |
				|      6. Replace Solution user certificates with VMCA certificates   |
				|                                                                     |
				|      7. Revert last performed operation by re-publishing old        |
				|         certificates                                                |
				|                                                                     |
				|      8. Reset all Certificates                                      |
				|_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _|

#Select Option 1
#1. Replace Machine SSL certificate with Custom Certificate
1

#It will ask for credenitials like below
Please provide valid SSO and VC privileged user credential to perform certificate operations.
Enter username [Administrator@vsphere.local]:
Enter password:

#Use the administrator@vsphere.local Account
administrator@vsphere.local

#Type in the administrator@vsphere.local password

#An Option box like Below will Appear:
Please provide valid SSO and VC privileged user credential to perform certificate operations.
Enter username [Administrator@vsphere.local]:
Enter password:
		 1. Generate Certificate Signing Request(s) and Key(s) for Machine SSL certificate

		 2. Import custom certificate(s) and key(s) to replace existing Machine SSL certificate

Option [1 or 2]:

#Select Option 2
#2. Import custom certificate(s) and key(s) to replace existing Machine SSL certificate
2

#Specify the name of the file below for
#Please provide valid custom certificate for Machine SSL.
/certs/$COMBINEDPEMNAME

#Specify the name of the file below for
#Please provide valid custom key for Machine SSL.
/certs/$KEYPEMNAME

#Specify the name of the file below for
#Please provide the signing certificate of the Machine SSL certificate
/certs/CA.pem

#Specify Y for the below
#You are going to replace Machine SSL cert using custom cert
#Continue operation : Option[Y/N] ? :
Y

#After clicking Y, this will take some time to complete. You MUST wait for the process to complete.
#This will take 5-10 minutes. Services will stop and start as part of this process.

#Verify all services are update
service-control --status --all

#Check your Certificate on the main VCSA page, login and check around in the VCSA as well
#You may need to close your browser and reopen it to see the updated certificate.
https://$FQDN 

#Update VMAMI Certificate
#Now we need to update VAMI to match the new Cert(VCSA 6.0 - 6.7 only. This is fixed in 7.0)
#VMware KB: https://kb.vmware.com/s/article/2136693 

#Bring back up SSH to VCSA

#Run command:
cd /certs
ls
rm /etc/applmgmt/appliance/ca.crt
cp /certs/$COMBINEDPEMNAME /etc/applmgmt/appliance/ca.crt

#Update lightttpd.conf file
#Type the below to edit the lighttpd.conf file
vi /opt/vmware/etc/lighttpd/lighttpd.conf

#Type the below to go to the ssl area:
?ssl
#Press Enter
#This will find the area of the conf like below:

#Use the arrow key to move down to the blank area
#Type the letter a (to append)
#Paste in the below information:
ssl.ca-file="/etc/applmgmt/appliance/ca.crt" #6.7 fix

#Click on the ESC button
#Type :wq (this will write and quit)
#Follow steps VAMI steps and verify the update took. If it did, type :q to exit the file

#Restart the VAMI service to complete the process. Type the below to restart the service:
/etc/init.d/vami-lighttp restart

#Check the Certicate on your VAMI site, make sure it is good. 
#You may need to close your browser and reopen it to see the updated certificate.
$VAMIURL

##After VCSA certs have been checked
#Fix Certs connecting to VCSA. This Includes:
#NSX-V
	#Login to NSX-v using local admin account
	#Refresh vCenter Server & Lookup Service URL by typing in service account password
#NSX-T
	#Login to NSX-T using local account
	#https://<NSX-T_FQDN/IP>/login.jsp?local=true
	#Depends on version
	#Click on System>Fabric>Computer Managers
	#Select VCSA and click on Edit
	#Update SHA-256 Thumbprint with updated thumbprint from new VCSA certificate (below)
	$THUMBPRINTSHA256
	#Click Save
#vROPs
	#Delete old VCSA certificate from Administration>Management>Certificates
	#Reregister VCSA via test, save
#Log Insight
	#Login with local admin account
	#Administration>Integration>vSphere, click on pencil 
	#Check Update Password, type in password for service account
	#Click Test Connection
	#Click Accept to accept new Certificate
	#Click Save after completion
#Horizon View
	#Depends upon version, find VCSA, test connection, accept new certificate
#vRA
	#Depends upon version, find VCSA, test connection, accept new certificate
"@
			Write-Host "#######################################################################################################################"
			}
			If($CertType -eq "Operations"){
				Write-Host "#######################################################################################################################" -ForegroundColor Green
				Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss") -ForegroundColor Green
				Write-Host "Use the Combined PEM File to set your cert on VCF Operations. https://operations.fqdn.here/admin" -ForegroundColor Green
				Write-Host $COMBINEDPEM -ForegroundColor Green
				Write-Host "KB - https://knowledge.broadcom.com/external/article/320343/configure-a-certificate-for-use-with-vmw.html"
				Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss") -ForegroundColor Green
				Write-Host "#######################################################################################################################" -ForegroundColor Green
			}
			
		}Else{
			Write-Error "Multiple PEM Files found with similar name. Please delete CAs from CA folder that are no longer needed and rerun this script."
		}
	}Else{
		Write-Error "CER File was not created. Please troubleshoot request process or manually place CER file in folder and rerun script"
	}
}

##Stopping Logging
#Note: Must stop transcriptting prior to sending email report with attached log file
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host "All Processes Completed"
Write-Host "Stopping Transcript"
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Stop-Transcript

##Script Completed
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host "Script Completed"
Write-Host "Press Enter to close this PowerShell Script"
Set-Location $LOCATION
PAUSE
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host "-----------------------------------------------------------------------------------------------------------------------"