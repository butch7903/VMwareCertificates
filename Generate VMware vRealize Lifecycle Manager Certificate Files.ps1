<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			May 4, 2020
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware vRealize Lifecycle Manager. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying vSphere Integrated Containers.

	.NOTES
		
#>

##vRLCM Certicate Customizable Variables
$vRLCMNAME = "vrlcm01" #Short name for your vRLCMA (not FQDN)
$vRLCMIP = "192.168.1.28" #Example 10.27.1.12 #Note you may want to specify all IPs for your VMware vRealize Lifecycle Manager cluster other than your VIP IP here.
$vRLCMDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$vRLCMNAME = $vRLCMNAME.ToLower() #vRLCMNAME Should be lower case
$vRLCMFQDN = "$vRLCMNAME.$vRLCMDOMAIN"
$COUNTRY = "US" #2 Letter Country Code
$STATE = "KS" #Your State
$CITY = "Wichita" #Your City
$COMPANY = "Hamker Tech" #Your Company
$DEPARTMENT = "IT" #Your Department
$EMAILADDRESS = "YourDepartmentEmail@here.com" #Department Email								  
$CAFILELOCATION = "C:\certs\CAs\Combined" #Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from #Example C:\Certs\CA\Combined\CombinedCA_HAMCA01-CA-PEM.pem
$CERTIFICATESERVER = "hamca01.hamker.local" #FQDN of the Certificate server you are getting your certs from #Example HAMCA01.hamker.local

#Standard Variables
$CERTLOCATION = "C:\Certs"
$vRLCMCertLocationGet = Get-Item "$CERTLOCATION\vRLCM\$vRLCMFQDN" -ErrorAction SilentlyContinue
$vRLCMCertLocation = "$CERTLOCATION\vRLCM\$vRLCMFQDN"
$vRLCMKEYGET = Get-Item "$vRLCMCertLocation\$vRLCMNAME.key" -ErrorAction SilentlyContinue
$vRLCMKEY = "$vRLCMCertLocation\$vRLCMNAME.key" # This is in RSA format
$vRLCMKEYPEMGET = Get-Item "$vRLCMCertLocation\$vRLCMNAME-key.pem" -ErrorAction SilentlyContinue
$vRLCMKEYPEM = "$vRLCMCertLocation\$vRLCMNAME-key.pem" # This is in PEM format
$vRLCMCSRGET = Get-Item "$vRLCMCertLocation\$vRLCMNAME.csr" -ErrorAction SilentlyContinue
$vRLCMCSR = "$vRLCMCertLocation\$vRLCMNAME.csr"
$vRLCMCERGET = Get-Item "$vRLCMCertLocation\$vRLCMNAME.cer" -ErrorAction SilentlyContinue
$vRLCMCER = "$vRLCMCertLocation\$vRLCMNAME.cer" #This is in DER format
$vRLCMPEMGET = Get-Item "$vRLCMCertLocation\$vRLCMNAME.pem" -ErrorAction SilentlyContinue
$vRLCMPEM = "$vRLCMCertLocation\$vRLCMNAME.pem" # This is in PEM format
$vRLCMCOMBINEDPEM = "$vRLCMCertLocation\$vRLCMNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update vRLCM with.

#Certificate Variables
$CACERT = "$vRLCMCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $vRLCMNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $vRLCMCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $vRLCMCertLocation+"\Log\"+$LOGFILENAME

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
	#Note: Update the below with the other IPs of the cluster with Ip.2 = $vRLCMIP1, etc.
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
	DNS.1 = $vRLCMFQDN
	IP.1 = $vRLCMIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$vRLCMFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new vRLCM Cert Folder for storing all the Cert files
	IF(!$vRLCMCertLocationGet)
	{
		New-Item -Path $vRLCMCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "vRLCM Folder already created at" $vRLCMCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make vRLCM Config file
	$CFGFILE = New-Item -Path $vRLCMCertLocation -Name "$vRLCMNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$vRLCMKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $vRLCMKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $vRLCMKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$vRLCMKEYPEMGET)
	{
		Write-Host "vRLCMA-key.pem file does not exist"
		Write-Host "Generating vRLCMA-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $vRLCMKEY -outform PEM -nocrypt -out $vRLCMKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $vRLCMKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$vRLCMCSRGET)
	{
		Write-Host "vRLCMA CSR File Not Found"
		Write-Host "Generating vRLCMA CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $vRLCMKEY -out $vRLCMCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $vRLCMCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $vRLCMCSR -ForegroundColor Blue
	.\openssl req -in $vRLCMCSR -noout -text
	
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
	IF(!$vRLCMCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $vRLCMCSR $vRLCMCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $vRLCMCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$vRLCMCERGETAGAIN = Get-Item "$vRLCMCertLocation\$vRLCMNAME.cer" -ErrorAction SilentlyContinue
	
	IF($vRLCMCERGETAGAIN)			   
	{
		Write-Host "VMware vRealize Lifecycle Manager CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($vRLCMCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$vRLCMPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $vRLCMCER -outform PEM -out $vRLCMPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $vRLCMPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the vRLCM folder
			Write-Host "Copying CA PEM File to vRLCM Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain vRLCM PEM File
			Write-Host "Creating Full Chain vRLCM PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			$STEP1 = Get-Content $vRLCMKEYPEM
			$STEP2 = Get-Content $vRLCMPEM 
			$STEP3 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 + $STEP3
			$COMBINESTEPS | Set-Content $vRLCMCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $vRLCMCOMBINEDPEM -text -noout
			
			Write-Host "vRLCM Certificate Generation Process Completed" $vRLCMCOMBINEDPEM -ForegroundColor Green
			Write-Host " "
			Write-Host "Follow Steps to Import vRLCM Certificate"
			Write-Host "Login to https://$vRLCMFQDN using admin@local"
			Write-Host "Click on Locker>Import"
			Write-Host "Type in a Valid unique Name"
			Write-Host "Copy the text contents of the below file to the Private Key area: "
			Write-Host "$vRLCMKEYPEM"
			Write-Host (Get-Content $vRLCMKEYPEM)
			Write-Host "Copy the text contents of the below file to the Certificate Chain area:"
			Write-Host "$vRLCMCOMBINEDPEM"
			Write-Host (Get-Content $vRLCMCOMBINEDPEM)
			Write-Host " "
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
		}Else{
		Write-Error "Multiple PEM Files found with similar name. Please delete CAs from CA folder that are no longer needed and rerun this script."
		}
	}Else{
	Write-Error "`
CER File was not created. Please troubleshoot request process or manually place CER file in folder and rerun script.`
File name must be:`
$vRLCMCertLocation\$vRLCMNAME.cer"
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