<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			March 5, 2021
	Version:		1.1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware vRNI (VMware vRealize Network Insight). This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate. Fill in the variables and then simply run this script to
		automate the process of generating the certificate.

	.NOTES
		
#>

##vRNI Certicate Customizable Variables
$vRNINAME = "hamvrni01" #Short name for your vRNI (not FQDN)
$vRNIIP = "192.168.1.68" #Example 10.27.1.12
$vRNIDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$vRNINAME = $vRNINAME.ToLower() #vRNINAME Should be lower case
$vRNIFQDN = "$vRNINAME.$vRNIDOMAIN"
$COUNTRY = "US" #2 Letter Country Code
$STATE = "KS" #Your State
$CITY = "Wichita" #Your City
$COMPANY = "Hamker Tech" #Your Company
$DEPARTMENT = "IT" #Your Department
$EMAILADDRESS = "YourEmailHere@something.com" #Department Email								  
$CAFILELOCATION = "C:\certs\CAs\Combined" #Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from #Example C:\Certs\CA\Combined\CombinedCA_HAMCA01-CA-PEM.pem
$CERTIFICATESERVER = "hamca01.hamker.local" #FQDN of the Certificate server you are getting your certs from #Example HAMCA01.hamker.local
##If you have a VRNI multiple platform nodes, uncomment the quantity of nodes below and fill in the FQDNs/IPs
#$VRNINodeNAME2 = "VRNI02.adu.dcn" #FQDN of Node #2
#$VRNINodeIP2 = "192.168.1.42" #IP of Node #2
#$VRNINodeNAME3 = "VRNI03.adu.dcn" #FQDN of Node #3
#$VRNINodeIP3 = "192.168.1.43" #IP of Node #3
#$VRNINodeNAME4 = "VRNI04.adu.dcn" #FQDN of Node #4
#$VRNINodeIP4 = "192.168.1.44" #IP of Node #4
#$VRNINodeNAME5 = "VRNI05.adu.dcn" #FQDN of Node #5
#$VRNINodeIP5 = "192.168.1.45" #IP of Node #5
#$VRNINodeNAME6 = "VRNI06.adu.dcn" #FQDN of Node #6
#$VRNINodeIP6 = "192.168.1.46" #IP of Node #6
#$VRNINodeNAME7 = "VRNI07.adu.dcn" #FQDN of Node #7
#$VRNINodeIP7 = "192.168.1.47" #IP of Node #7
#$VRNINodeNAME8 = "VRNI08.adu.dcn" #FQDN of Node #8
#$VRNINodeIP8 = "192.168.1.48" #IP of Node #8
#$VRNINodeNAME9 = "VRNI09.adu.dcn" #FQDN of Node #9
#$VRNINodeIP9 = "192.168.1.49" #IP of Node #9
#$VRNINodeNAME10 = "VRNI10.adu.dcn" #FQDN of Node #10
#$VRNINodeIP10 = "192.168.1.50" #IP of Node #10

#Standard Variables
$CERTLOCATION = "C:\Certs"
$vRNICertLocationGet = Get-Item "$CERTLOCATION\vRNI\$vRNIFQDN" -ErrorAction SilentlyContinue
$vRNICertLocation = "$CERTLOCATION\vRNI\$vRNIFQDN"
$vRNIKEYGET = Get-Item "$vRNICertLocation\$vRNINAME.key" -ErrorAction SilentlyContinue
$vRNIKEYNAME = "$vRNINAME.key"
$vRNIKEY = "$vRNICertLocation\$vRNIKEYNAME" # This is in RSA format
$vRNIKEYPEMGET = Get-Item "$vRNICertLocation\$vRNINAME-key.pem" -ErrorAction SilentlyContinue
$vRNIKEYPEMNAME = "$vRNINAME-key.pem"
$vRNIKEYPEM = "$vRNICertLocation\$vRNIKEYPEMNAME" # This is in PEM format
$vRNICSRGET = Get-Item "$vRNICertLocation\$vRNINAME.csr" -ErrorAction SilentlyContinue
$vRNICSR = "$vRNICertLocation\$vRNINAME.csr"
$vRNICERGET = Get-Item "$vRNICertLocation\$vRNINAME.cer" -ErrorAction SilentlyContinue
$vRNICER = "$vRNICertLocation\$vRNINAME.cer" #This is in DER format
$vRNIPEMGET = Get-Item "$vRNICertLocation\$vRNINAME.pem" -ErrorAction SilentlyContinue
$vRNIPEM = "$vRNICertLocation\$vRNINAME.pem" # This is in PEM format
$vRNICOMBINEDPEMNAME = "$vRNINAME.crt"
$vRNICOMBINEDPEM = "$vRNICertLocation\$vRNICOMBINEDPEMNAME" # This is in PEM format. This is the file you use to update vRNI with.

#Certificate Variables
$CACERT = "$vRNICertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $vRNINAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $vRNICertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $vRNICertLocation+"\Log\"+$LOGFILENAME

##Starting Logging
Start-Transcript -path $LOGFILE -Append


###Test if OpenSSL is Installed
##Specify OpenSSL version. If you have a 64-bit OS, use the x64 version. If you have a 32-bit OS, use the x86 version
#$OPENSSL = get-item "C:\Program Files (x86)\OpenSSL-Win32\bin\OpenSSL.exe" -ErrorAction SilentlyContinue ##x86 version
$OPENSSL = get-item "C:\Program Files\OpenSSL-Win64\bin\OpenSSL.exe" -ErrorAction SilentlyContinue ##x64 version 
IF(!$OPENSSL)
{
	Write-Warning "OpenSSL is not installed"
	Write-Warning "Please download and install OpenSSL"
	Write-Warning "Download similar to version Win64 OpenSSL v1.1.1b Light"
	Write-Warning "https://slproweb.com/products/Win32OpenSSL.html"
	Write-Warning "Example downlod would be https://slproweb.com/download/Win64OpenSSL_Light-1_1_1b.msi"
	write-host "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
	#Start-Sleep
	#EXIT
}else{
	Write-Host "Verified: OpenSSL has been properly installed" -ForegroundColor Green
}

###Verify that OpenSSL is installed
IF($OPENSSL)
{
	#CNF Config
	#Note: This CNF File is reverse engineered from created a CSR on a 6.7u3 vRNI
	$CNF = "[ req ]
	default_md = sha256
	default_bits = 2048
	default_keyfile = key.key
	distinguished_name = req_distinguished_name
	encrypt_key = no
	prompt = no
	string_mask = nombstr
	req_extensions = v3_req

	[ v3_req ]
	basicConstraints = CA:false
	keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
	extendedKeyUsage = serverAuth, clientAuth
	subjectAltName = @alt_names
	subjectKeyIdentifier = hash

	[ alt_names ]
	email = $EMAILADDRESS
	IP.1 = $vRNIIP
	DNS.1 = $vRNIFQDN

	[ req_distinguished_name ]
	CN = $vRNIFQDN 					#NAME (eg, example.com)
	C = $COUNTRY					#Country
	ST = $STATE					#State
	L = $CITY					#Locality
	O = $COMPANY					#Organization
	OU = $DEPARTMENT				#OrgUnit
	emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
	"
	If($VRNINodeNAME2)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME3)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME4)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME5)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		DNS.5 = $VRNINodeNAME5
		IP.5 = $VRNINodeIP5
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME6)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		DNS.5 = $VRNINodeNAME5
		IP.5 = $VRNINodeIP5
		DNS.6 = $VRNINodeNAME6
		IP.6 = $VRNINodeIP6
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME7)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		DNS.5 = $VRNINodeNAME5
		IP.5 = $VRNINodeIP5
		DNS.6 = $VRNINodeNAME6
		IP.6 = $VRNINodeIP6
		DNS.7 = $VRNINodeNAME7
		IP.7 = $VRNINodeIP7

		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME8)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		DNS.5 = $VRNINodeNAME5
		IP.5 = $VRNINodeIP5
		DNS.6 = $VRNINodeNAME6
		IP.6 = $VRNINodeIP6
		DNS.7 = $VRNINodeNAME7
		IP.7 = $VRNINodeIP7
		DNS.8 = $VRNINodeNAME8
		IP.8 = $VRNINodeIP8
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME9)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		DNS.5 = $VRNINodeNAME5
		IP.5 = $VRNINodeIP5
		DNS.6 = $VRNINodeNAME6
		IP.6 = $VRNINodeIP6
		DNS.7 = $VRNINodeNAME7
		IP.7 = $VRNINodeIP7
		DNS.8 = $VRNINodeNAME8
		IP.8 = $VRNINodeIP8
		DNS.9 = $VRNINodeNAME9
		IP.9 = $VRNINodeIP9
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	If($VRNINodeNAME10)
	{
		$CNF = "[ req ]
		default_md = sha256
		default_bits = 2048
		default_keyfile = key.key
		distinguished_name = req_distinguished_name
		encrypt_key = no
		prompt = no
		string_mask = nombstr
		req_extensions = v3_req

		[ v3_req ]
		basicConstraints = CA:false
		keyUsage = keyEncipherment, digitalSignature, keyAgreement, nonRepudiation
		extendedKeyUsage = serverAuth, clientAuth
		subjectAltName = @alt_names
		subjectKeyIdentifier = hash

		[ alt_names ]
		email = $EMAILADDRESS
		DNS.1 = $vRNIFQDN
		IP.1 = $vRNIIP
		DNS.2 = $VRNINodeNAME2
		IP.2 = $VRNINodeIP2
		DNS.3 = $VRNINodeNAME3
		IP.3 = $VRNINodeIP3
		DNS.4 = $VRNINodeNAME4
		IP.4 = $VRNINodeIP4
		DNS.5 = $VRNINodeNAME5
		IP.5 = $VRNINodeIP5
		DNS.6 = $VRNINodeNAME6
		IP.6 = $VRNINodeIP6
		DNS.7 = $VRNINodeNAME7
		IP.7 = $VRNINodeIP7
		DNS.8 = $VRNINodeNAME8
		IP.8 = $VRNINodeIP8
		DNS.9 = $VRNINodeNAME9
		IP.9 = $VRNINodeIP9
		DNS.10 = $VRNINodeNAME10
		IP.10 = $VRNINodeIP10
		
		[ req_distinguished_name ]
		CN = $vRNIFQDN 					#NAME (eg, example.com)
		C = $COUNTRY					#Country
		ST = $STATE					#State
		L = $CITY					#Locality
		O = $COMPANY					#Organization
		OU = $DEPARTMENT				#OrgUnit
		emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs vRNI CSR), as required for certain business requirements.
		"
	}
	
	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new vRNI Cert Folder for storing all the Cert files
	IF(!$vRNICertLocationGet)
	{
		New-Item -Path $vRNICertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "vRNI Folder already created at" $vRNICertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make vRNI Config file
	$CFGFILE = New-Item -Path $vRNICertLocation -Name "$vRNINAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$vRNIKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $vRNIKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $vRNIKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$vRNIKEYPEMGET)
	{
		Write-Host "vRNI-key.pem file does not exist"
		Write-Host "Generating vRNI-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $vRNIKEY -outform PEM -nocrypt -out $vRNIKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $vRNIKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$vRNICSRGET)
	{
		Write-Host "vRNI CSR File Not Found"
		Write-Host "Generating vRNI CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $vRNIKEY -out $vRNICSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $vRNICSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $vRNICSR -ForegroundColor Blue
	.\openssl req -in $vRNICSR -noout -text
	
	$CA = certutil -config $CERTIFICATESERVER -ping
	$CA = $CA[1]
	$CA = $CA.Replace("Server "," ")
	$CA = $CA.SubString(0, $CA.IndexOf('ICertRequest2'))
	$CA = $CA.Replace('"','')
	$CA = $CA.Replace(' ','')

	#To List the Certificate Templates to get the right 1
	#certutil -template | Select-String -Pattern TemplatePropCommonName
	#Detailed Example certutil -template | Select-String -Pattern Vmware6.0WebServer
	
	#Generate CER
	IF(!$vRNICERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $vRNICSR $vRNICER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $vRNICER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$vRNICERGETAGAIN = Get-Item "$vRNICertLocation\$vRNINAME.cer" -ErrorAction SilentlyContinue
	
	IF($vRNICERGETAGAIN)			   
	{
		Write-Host "vRNI CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($vRNICERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$vRNIPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $vRNICER -outform PEM -out $vRNIPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $vRNIPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the vRNI folder
			Write-Host "Copying CA PEM File to vRNI Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain vRNI PEM File
			Write-Host "Creating Full Chain vRNI PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			#$STEP1 = Get-Content $vRNIKEYPEM
			#$STEP1 = Get-Content $vRNIKEY
			$STEP1 = Get-Content $vRNIPEM
			$STEP2 = Get-Content $CACERT
			$COMBINESTEPS = $STEP1 + $STEP2 #+ $STEP3
			$COMBINESTEPS | Set-Content $vRNICOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $vRNICOMBINEDPEM -text -noout
			
			#Verify Certificate Files
			Write-Host "Displaying Certificate Issuer Chain"
			./openssl crl2pkcs7 -nocrl -certfile $vRNIPEM | ./openssl pkcs7 -print_certs -noout
			Write-Host "Displaying MD5 of the $vRNIPEM"
			$vRNIPEMMD5 = ./openssl x509 -modulus -noout -in $vRNIPEM | ./openssl md5
			$vRNIPEMMD5 = $vRNIPEMMD5.replace("(stdin)= ","")
			Write-Host $vRNIPEMMD5
			Write-Host "Displaying MD5 of the $vRNIKEYPEM"
			$vRNIKEYPEMMD5 = ./openssl rsa -modulus -noout -in $vRNIKEYPEM | ./openssl md5
			$vRNIKEYPEMMD5 = $vRNIKEYPEMMD5.replace("(stdin)= ","")
			Write-Host $vRNIKEYPEMMD5
			If($vRNIPEMMD5 -eq $vRNIKEYPEMMD5)
			{
				Write-Host "MD5s Match for vRNIPEM and vRNIKEYPEM" -foreground green
			}Else{
				Write-Error "MD5 DO NOT MATCH FOR vRNIPEM and vRNIKEYPEM"
			}
			Write-Host "  "
			Write-Host "Getting Certificate SHA-1 Thumbprint"
			$THUMBPRINTSHA1 = ./openssl x509 -noout -fingerprint -sha1 -inform pem -in $vRNIPEM
			$THUMBPRINTSHA1 = $THUMBPRINTSHA1.replace("SHA1 Fingerprint=","")
			Write-Host $THUMBPRINTSHA1
			Write-Host "  "
			Write-Host "Getting Certificate SHA-256 Thumbprint (Needed for NSX-T)"
			$THUMBPRINTSHA256 = ./openssl x509 -noout -fingerprint -sha256 -inform pem -in $vRNIPEM
			$THUMBPRINTSHA256 = $THUMBPRINTSHA256.replace("SHA256 Fingerprint=","")
			Write-Host $THUMBPRINTSHA256
			Write-Host "  "
			Write-Host "vRNI Certificate Generation Process Completed" $vRNICOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host "Use this file to install the Cert on your vRNI" $vRNICOMBINEDPEM -ForegroundColor Green
			Write-Host "Use this file to install the Key on your vRNI" $vRNIKEYPEM -ForegroundColor Green
			#Write-Host "Use this file to install the CA cert on your vRNI" $CACERT -ForegroundColor Green
			Write-Host "#######################################################################################################################"
			Write-Host "Directions:"
			Write-Host @"
Follow these Steps to properly install your new certificate

OPTION A
########
Based on KB https://kb.vmware.com/s/article/2148128

1. Log in to vRealize Network Insight command line interface (CLI) via SSH as the user consoleuser.
2. Remove the existing certificate using custom-cert remove command:

custom-cert remove

You see this message:

Removed all custom certificates
 
3. Copy the new certificate from the host where it is located using custom-cert copy command:
custom-cert copy --host <IP_of_SFTP_host> --user <user_of_SFTP_host> --port 22 --path </path/to/file>.crt
custom-cert copy --host <IP_of_SFTP_host> --user <user_of_SFTP_host> --port 22 --path </path/to/file>.key
Note: replace <IP_of_SFTP_host>, <user_of_SFTP_host>, and </path/to/file> with the real values. An example this command would be as below:
custom-cert copy --host 10.1.1.1 --user adminxyz --port 22 --path /root/$vRNICOMBINEDPEMNAME
custom-cert copy --host 10.1.1.1 --user adminxyz --port 22 --path /root/$vRNIKEYNAME
 
When you are prompted to enter the password, enter <user_of_SFTP_host> password.

When copying is successful, you see this message:

copying...
successfully copied

4. List the available certificates using custom-cert list command:

custom-cert list
file.crt
file.key
 
5. Apply the new certificate using custom-cert apply command:

custom-cert apply

After the certificate is applied, you see this message:

Successfully applied new certificate. All active UI sessions have to be restarted.
Note: Passphrase protected keypair is not supported.

OPTION B
########
This is not documented, but fully supported (based on vRNI using ubuntu OS)

1. Use WinSCP with the support user account to copy files below to each platform.
/home/support/$vRNICOMBINEDPEMNAME
/home/support/$vRNIKEYNAME

2. SSH to a platform via support

3. Run these commands 
sudo mkdir -u ubuntu -p /home/ubuntu/custom_certs
sudo cp /home/support/$vRNICOMBINEDPEMNAME /home/ubuntu/custom_certs
sudo cp /home/support/$vRNIKEYNAME /home/ubuntu/custom_certs

4. Change users to consoleuser 
sudo su consoleuser

5. List the Files
custom-cert list
#verify files are there

6. Apply Cert
custom-cert apply

"@
			Write-Host "#######################################################################################################################"
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
PAUSE
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host "-----------------------------------------------------------------------------------------------------------------------"