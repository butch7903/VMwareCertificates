<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			January 21, 2021
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for CrushFTP Server. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying certificates for CrushFTP.

	.NOTES
		
#>

##CrushFTPServer Certicate Customizable Variables
$CrushFTPServerNAME = "" #Short name for your CrushFTP Server (not FQDN)
$CrushFTPServerIP = "" #Example 10.27.1.12
$CrushFTPServerDOMAIN = "hamker.local" #Domain Name. Example hamker.local
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$CrushFTPServerNAME = $CrushFTPServerNAME.ToLower() #CrushFTPServerNAME Should be lower case
$CrushFTPServerFQDN = "$CrushFTPServerNAME.$CrushFTPServerDOMAIN"
$COUNTRY = "US" #2 Letter Country Code
$STATE = "KS" #Your State
$CITY = "Wichita" #Your City
$COMPANY = "Hamker Tech" #Your Company
$DEPARTMENT = "IT Department" #Your Department
$EMAILADDRESS = "YourEmail@here.com" #Department Email								  
$CAFILELOCATION = "C:\Certs\CAs\Combined" #Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from #Example C:\Certs\CA\Combined\CombinedCA_HAMCA01-CA-PEM.pem
$CERTIFICATESERVER = "hamca01.hamker.local" #FQDN of the Certificate server you are getting your certs from #Example HAMCA01.hamker.local

#Standard Variables
$CERTLOCATION = "C:\Certs"
$CrushFTPServerCertLocationGet = Get-Item "$CERTLOCATION\CrushFTP\$CrushFTPServerFQDN" -ErrorAction SilentlyContinue
$CrushFTPServerCertLocation = "$CERTLOCATION\CrushFTP\$CrushFTPServerFQDN"
$CrushFTPServerKEYGET = Get-Item "$CrushFTPServerCertLocation\$CrushFTPServerNAME.key" -ErrorAction SilentlyContinue
$CrushFTPServerKEY = "$CrushFTPServerCertLocation\$CrushFTPServerNAME.key" # This is in RSA format
$CrushFTPServerKEYPEMGET = Get-Item "$CrushFTPServerCertLocation\$CrushFTPServerNAME-key.pem" -ErrorAction SilentlyContinue
$CrushFTPServerKEYPEM = "$CrushFTPServerCertLocation\$CrushFTPServerNAME-key.pem" # This is in PEM format
$CrushFTPServerP12 = "$CrushFTPServerCertLocation\$CrushFTPServerNAME.pfx" # This is in P12 format
$CrushFTPServerCSRGET = Get-Item "$CrushFTPServerCertLocation\$CrushFTPServerNAME.csr" -ErrorAction SilentlyContinue
$CrushFTPServerCSR = "$CrushFTPServerCertLocation\$CrushFTPServerNAME.csr"
$CrushFTPServerCERGET = Get-Item "$CrushFTPServerCertLocation\$CrushFTPServerNAME.cer" -ErrorAction SilentlyContinue
$CrushFTPServerCER = "$CrushFTPServerCertLocation\$CrushFTPServerNAME.cer" #This is in DER format
$CrushFTPServerPEMGET = Get-Item "$CrushFTPServerCertLocation\$CrushFTPServerNAME.pem" -ErrorAction SilentlyContinue
$CrushFTPServerPEM = "$CrushFTPServerCertLocation\$CrushFTPServerNAME.pem" # This is in PEM format
$CrushFTPServerCOMBINEDPEM = "$CrushFTPServerCertLocation\$CrushFTPServerNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update CrushFTPServer with.

#Install Directions
$DIRECTIONS = "
Directions to Install Certificate:

1.Log in to CrushFTP as admin.
2.Click Admin.
3.Click Preferences.
4.Select the HTTPS interfacxe.
5.Click on the Advanced Tab
6.Click Browse for Key Store Location
7.Select the PFX File $CrushFTPServerP12 and click OK
8.Type in the Password of the PFX file in the Key Password
9.Click on Test Certificate
10.If test is successful, save your settings and then refresh the HTTPS site.
11.Repeat this for SFTP, FTPS, SCP, or any other service that can use a certificate.

References: 
https://www.crushftp.com/crush9wiki/Wiki.jsp?page=IISExport
https://www.crushftp.com/crush9wiki/Wiki.jsp?page=SSL_CLI
"

#Certificate Variables
$CACERT = "$CrushFTPServerCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $CrushFTPServerNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $CrushFTPServerCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $CrushFTPServerCertLocation+"\Log\"+$LOGFILENAME

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
	#Note: Update the below with the other IPs of the cluster with Ip.2 = $CrushFTPServerIP1, etc.
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
	DNS.1 = $CrushFTPServerFQDN
	IP.1 = $CrushFTPServerIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$CrushFTPServerFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new CrushFTP Server Cert Folder for storing all the Cert files
	IF(!$CrushFTPServerCertLocationGet)
	{
		New-Item -Path $CrushFTPServerCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "CrushFTPServer Folder already created at" $CrushFTPServerCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make CrushFTP Server Config file
	$CFGFILE = New-Item -Path $CrushFTPServerCertLocation -Name "$CrushFTPServerNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$CrushFTPServerKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $CrushFTPServerKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $CrushFTPServerKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$CrushFTPServerKEYPEMGET)
	{
		Write-Host "CrushFTPServer-key.pem file does not exist"
		Write-Host "Generating CrushFTPServer-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $CrushFTPServerKEY -outform PEM -nocrypt -out $CrushFTPServerKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $CrushFTPServerKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$CrushFTPServerCSRGET)
	{
		Write-Host "CrushFTP Server CSR File Not Found"
		Write-Host "Generating CrushFTP Server CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $CrushFTPServerKEY -out $CrushFTPServerCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $CrushFTPServerCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $CrushFTPServerCSR -ForegroundColor Blue
	.\openssl req -in $CrushFTPServerCSR -noout -text
	
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
	IF(!$CrushFTPServerCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $CrushFTPServerCSR $CrushFTPServerCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $CrushFTPServerCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$CrushFTPServerCERGETAGAIN = Get-Item "$CrushFTPServerCertLocation\$CrushFTPServerNAME.cer" -ErrorAction SilentlyContinue
	
	IF($CrushFTPServerCERGETAGAIN)			   
	{
		Write-Host "CrushFTP Server CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($CrushFTPServerCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$CrushFTPServerPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $CrushFTPServerCER -outform PEM -out $CrushFTPServerPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $CrushFTPServerPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the CrushFTPServer folder
			Write-Host "Copying CA PEM File to CrushFTP Server Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain CrushFTPServer PEM File
			Write-Host "Creating Full Chain CrushFTP Server PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			$STEP1 = Get-Content $CrushFTPServerPEM 
			$STEP2 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2
			$COMBINESTEPS | Set-Content $CrushFTPServerCOMBINEDPEM
			
						
			#Create PKCS12 file For CrushFTP Ingestion
			#Reference https://docs.vmware.com/en/VMware-NSX-Data-Center-for-vSphere/6.4/com.vmware.nsx.admin.doc/GUID-22A1D392-3A66-49E9-84B1-27F7D8091E20.html
			Write-Host "Creating PKCS12 Formatted Certificate File for Ingestion into CrushFTP Server"
			.\openssl pkcs12 -export -in $CrushFTPServerCOMBINEDPEM -inkey $CrushFTPServerKEYPEM -out $CrushFTPServerP12
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $CrushFTPServerCOMBINEDPEM -text -noout
			
			#Note P12 File Location
			Write-Host "Use this file to install the cert on your CrushFTP Server" $CrushFTPServerP12 -ForegroundColor Green
			
			#Read SHA Settings on Certificate (used for certian linux applainces)
			Write-Host "  "
			Write-Host "Getting Certificate SHA-1 Thumbprint"
			$THUMBPRINTSHA1 = ./openssl x509 -noout -fingerprint -sha1 -inform pem -in $CrushFTPServerCOMBINEDPEM
			$THUMBPRINTSHA1 = $THUMBPRINTSHA1.replace("SHA1 Fingerprint=","")
			Write-Host $THUMBPRINTSHA1
			Write-Host "  "
			Write-Host "Getting Certificate SHA-256 Thumbprint"
			$THUMBPRINTSHA256 = ./openssl x509 -noout -fingerprint -sha256 -inform pem -in $CrushFTPServerCOMBINEDPEM
			$THUMBPRINTSHA256 = $THUMBPRINTSHA256.replace("SHA256 Fingerprint=","")
			Write-Host $THUMBPRINTSHA256
			Write-Host "  "

			#Show Directions on How to install in CrushFTP
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host $DIRECTIONS -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			
			Write-Host "CrushFTPServer Certificate Generation Process Completed" $CrushFTPServerP12 -ForegroundColor Green
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