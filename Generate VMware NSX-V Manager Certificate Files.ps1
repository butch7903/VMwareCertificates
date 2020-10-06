<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			October 6, 2020
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware NSX-V Manager. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying vSphere Integrated Containers.

	.NOTES
		
#>

##NSXVManager Certicate Customizable Variables
$NSXVManagerNAME = "nsxmanager" #Short name for your NSX-V Manager (not FQDN)
$NSXVManagerIP = "192.168.1.66" #Example 10.27.1.12
$NSXVManagerDOMAIN = "hamker.local" #Domain Name. Example hamker.local
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$NSXVManagerNAME = $NSXVManagerNAME.ToLower() #NSXVManagerNAME Should be lower case
$NSXVManagerFQDN = "$NSXVManagerNAME.$NSXVManagerDOMAIN"
$COUNTRY = "US" #2 Letter Country Code
$STATE = "KS" #Your State
$CITY = "Wichita" #Your City
$COMPANY = "Hamker Tech" #Your Company
$DEPARTMENT = "IT #Your Department"
$EMAILADDRESS = "YourEmailHere@something.com" #Department Email								  
$CAFILELOCATION = "C:\certs\CAs\Combined" #Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from #Example C:\Certs\CA\Combined\CombinedCA_HAMCA01-CA-PEM.pem
$CERTIFICATESERVER = "hamca01.hamker.local" #FQDN of the Certificate server you are getting your certs from #Example HAMCA01.hamker.local

#Standard Variables
$CERTLOCATION = "C:\Certs"
$NSXVManagerCertLocationGet = Get-Item "$CERTLOCATION\NSXV\$NSXVManagerFQDN" -ErrorAction SilentlyContinue
$NSXVManagerCertLocation = "$CERTLOCATION\NSXV\$NSXVManagerFQDN"
$NSXVManagerKEYGET = Get-Item "$NSXVManagerCertLocation\$NSXVManagerNAME.key" -ErrorAction SilentlyContinue
$NSXVManagerKEY = "$NSXVManagerCertLocation\$NSXVManagerNAME.key" # This is in RSA format
$NSXVManagerKEYPEMGET = Get-Item "$NSXVManagerCertLocation\$NSXVManagerNAME-key.pem" -ErrorAction SilentlyContinue
$NSXVManagerKEYPEM = "$NSXVManagerCertLocation\$NSXVManagerNAME-key.pem" # This is in PEM format
$NSXVManagerP12 = "$NSXVManagerCertLocation\$NSXVManagerNAME.p12" # This is in P12 format
$NSXVManagerCSRGET = Get-Item "$NSXVManagerCertLocation\$NSXVManagerNAME.csr" -ErrorAction SilentlyContinue
$NSXVManagerCSR = "$NSXVManagerCertLocation\$NSXVManagerNAME.csr"
$NSXVManagerCERGET = Get-Item "$NSXVManagerCertLocation\$NSXVManagerNAME.cer" -ErrorAction SilentlyContinue
$NSXVManagerCER = "$NSXVManagerCertLocation\$NSXVManagerNAME.cer" #This is in DER format
$NSXVManagerPEMGET = Get-Item "$NSXVManagerCertLocation\$NSXVManagerNAME.pem" -ErrorAction SilentlyContinue
$NSXVManagerPEM = "$NSXVManagerCertLocation\$NSXVManagerNAME.pem" # This is in PEM format
$NSXVManagerCOMBINEDPEM = "$NSXVManagerCertLocation\$NSXVManagerNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update NSXVManager with.

#Install Directions
$DIRECTIONS = "
Directions to Install Certificate:

1.Log in to the NSX Manager virtual appliance.
2.Click Manage Appliance Settings.
3.From the Settings panel, click SSL Certificates.
4.Click Upload PKCS#12 Keystore.
5.Select the PKCS#12 File from here $NSXVManagerP12
6.Click Choose File to locate the file.
7.Click Import.
8.To apply the certificate, reboot the NSX Manager appliance.

Reference: 
https://docs.vmware.com/en/VMware-NSX-Data-Center-for-vSphere/6.4/com.vmware.nsx.admin.doc/GUID-0467DB43-C95F-45EB-98C4-D9B132488A9B.html
"

#Certificate Variables
$CACERT = "$NSXVManagerCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $NSXVManagerNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $NSXVManagerCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $NSXVManagerCertLocation+"\Log\"+$LOGFILENAME

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

	[ alt_names ]
	DNS.1 = $NSXVManagerFQDN
	IP.1 = $NSXVManagerIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$NSXVManagerFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new NSX-V Manager Cert Folder for storing all the Cert files
	IF(!$NSXVManagerCertLocationGet)
	{
		New-Item -Path $NSXVManagerCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "NSXVManager Folder already created at" $NSXVManagerCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make NSX-V Manager Config file
	$CFGFILE = New-Item -Path $NSXVManagerCertLocation -Name "$NSXVManagerNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$NSXVManagerKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $NSXVManagerKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $NSXVManagerKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$NSXVManagerKEYPEMGET)
	{
		Write-Host "NSXVManager-key.pem file does not exist"
		Write-Host "Generating NSXVManager-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $NSXVManagerKEY -outform PEM -nocrypt -out $NSXVManagerKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $NSXVManagerKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$NSXVManagerCSRGET)
	{
		Write-Host "NSX-V Manager CSR File Not Found"
		Write-Host "Generating NSX-V Manager CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $NSXVManagerKEY -out $NSXVManagerCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $NSXVManagerCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $NSXVManagerCSR -ForegroundColor Blue
	.\openssl req -in $NSXVManagerCSR -noout -text
	
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
	IF(!$NSXVManagerCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $NSXVManagerCSR $NSXVManagerCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $NSXVManagerCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$NSXVManagerCERGETAGAIN = Get-Item "$NSXVManagerCertLocation\$NSXVManagerNAME.cer" -ErrorAction SilentlyContinue
	
	IF($NSXVManagerCERGETAGAIN)			   
	{
		Write-Host "NSX-V Manager CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($NSXVManagerCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$NSXVManagerPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $NSXVManagerCER -outform PEM -out $NSXVManagerPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $NSXVManagerPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the NSXVManager folder
			Write-Host "Copying CA PEM File to NSX-V Manager Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain NSXVManager PEM File
			Write-Host "Creating Full Chain NSX-V Manager PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			$STEP1 = Get-Content $NSXVManagerPEM 
			$STEP2 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2
			$COMBINESTEPS | Set-Content $NSXVManagerCOMBINEDPEM
			
						
			#Create PKCS12 file For NSX-V Manager Ingestion
			#Reference https://docs.vmware.com/en/VMware-NSX-Data-Center-for-vSphere/6.4/com.vmware.nsx.admin.doc/GUID-22A1D392-3A66-49E9-84B1-27F7D8091E20.html
			Write-Host "Creating PKCS12 Formatted Certificate File for Ingestion into NSX-V Manager"
			.\openssl pkcs12 -export -in $NSXVManagerCOMBINEDPEM -inkey $NSXVManagerKEYPEM -out $NSXVManagerP12
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $NSXVManagerCOMBINEDPEM -text -noout
			
			#Note P12 File Location
			Write-Host "Use this file to install the cert on your NSX-V Manager" $NSXVManagerP12 -ForegroundColor Green

			#Show Directions on How to install in NSX-V
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host $DIRECTIONS -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			
			Write-Host "NSXVManager Certificate Generation Process Completed" $NSXVManagerP12 -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
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