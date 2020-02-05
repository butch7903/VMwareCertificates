<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			February 4, 2020
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware Identity manager. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying vSphere Integrated Containers.

	.NOTES
		
#>

##IdentityManager Certicate Customizable Variables
$IdentityManagerNAME = "vidm01" #Short name for your IdentityManagerA (not FQDN)
$IdentityManagerIP = "192.168.1.28" #Example 10.27.1.12 #Note you may want to specify all IPs for your Identity Manager cluster other than your VIP IP here.
$IdentityManagerDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$IdentityManagerNAME = $IdentityManagerNAME.ToLower() #IdentityManagerNAME Should be lower case
$IdentityManagerFQDN = "$IdentityManagerNAME.$IdentityManagerDOMAIN"
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
$IdentityManagerCertLocationGet = Get-Item "$CERTLOCATION\IdentityManager" -ErrorAction SilentlyContinue
$IdentityManagerCertLocation = "$CERTLOCATION\IdentityManager"
$IdentityManagerKEYGET = Get-Item "$IdentityManagerCertLocation\$IdentityManagerNAME.key" -ErrorAction SilentlyContinue
$IdentityManagerKEY = "$IdentityManagerCertLocation\$IdentityManagerNAME.key" # This is in RSA format
$IdentityManagerKEYPEMGET = Get-Item "$IdentityManagerCertLocation\$IdentityManagerNAME-key.pem" -ErrorAction SilentlyContinue
$IdentityManagerKEYPEM = "$IdentityManagerCertLocation\$IdentityManagerNAME-key.pem" # This is in PEM format
$IdentityManagerCSRGET = Get-Item "$IdentityManagerCertLocation\$IdentityManagerNAME.csr" -ErrorAction SilentlyContinue
$IdentityManagerCSR = "$IdentityManagerCertLocation\$IdentityManagerNAME.csr"
$IdentityManagerCERGET = Get-Item "$IdentityManagerCertLocation\$IdentityManagerNAME.cer" -ErrorAction SilentlyContinue
$IdentityManagerCER = "$IdentityManagerCertLocation\$IdentityManagerNAME.cer" #This is in DER format
$IdentityManagerPEMGET = Get-Item "$IdentityManagerCertLocation\$IdentityManagerNAME.pem" -ErrorAction SilentlyContinue
$IdentityManagerPEM = "$IdentityManagerCertLocation\$IdentityManagerNAME.pem" # This is in PEM format
$IdentityManagerCOMBINEDPEM = "$IdentityManagerCertLocation\$IdentityManagerNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update IdentityManager with.

#Certificate Variables
$CACERT = "$IdentityManagerCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $IdentityManagerNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $IdentityManagerCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $IdentityManagerCertLocation+"\Log\"+$LOGFILENAME

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
	#Note: Update the below with the other IPs of the cluster with Ip.2 = $IdentityManagerIP1, etc.
	$CNF = "[ req ]
	default_md = sha512
	default_bits = 2048
	default_keyfile = key.key
	distinguished_name = req_distinguished_name
	encrypt_key = no
	prompt = no
	string_mask = nombstr
	req_extensions = v3_req

	[ v3_req ]
	basicConstraints = CA:false
	keyUsage = keyEncipherment, digitalSignature, keyAgreement
	extendedKeyUsage = serverAuth, clientAuth
	subjectAltName = @alt_names

	[ alt_names ]
	DNS.1 = $IdentityManagerFQDN
	IP.1 = $IdentityManagerIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$IdentityManagerFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new IdentityManager Cert Folder for storing all the Cert files
	IF(!$IdentityManagerCertLocationGet)
	{
		New-Item -Path $IdentityManagerCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "IdentityManager Folder already created at" $IdentityManagerCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make IdentityManager Config file
	$CFGFILE = New-Item -Path $IdentityManagerCertLocation -Name "$IdentityManagerNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$IdentityManagerKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $IdentityManagerKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $IdentityManagerKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$IdentityManagerKEYPEMGET)
	{
		Write-Host "IdentityManagerA-key.pem file does not exist"
		Write-Host "Generating IdentityManagerA-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $IdentityManagerKEY -outform PEM -nocrypt -out $IdentityManagerKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $IdentityManagerKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$IdentityManagerCSRGET)
	{
		Write-Host "IdentityManagerA CSR File Not Found"
		Write-Host "Generating IdentityManagerA CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $IdentityManagerKEY -out $IdentityManagerCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $IdentityManagerCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $IdentityManagerCSR -ForegroundColor Blue
	.\openssl req -in $IdentityManagerCSR -noout -text
	
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
	IF(!$IdentityManagerCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $IdentityManagerCSR $IdentityManagerCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $IdentityManagerCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$IdentityManagerCERGETAGAIN = Get-Item "$IdentityManagerCertLocation\$IdentityManagerNAME.cer" -ErrorAction SilentlyContinue
	
	IF($IdentityManagerCERGETAGAIN)			   
	{
		Write-Host "Identity Manager CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($IdentityManagerCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$IdentityManagerPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $IdentityManagerCER -outform PEM -out $IdentityManagerPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $IdentityManagerPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the IdentityManager folder
			Write-Host "Copying CA PEM File to IdentityManager Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain IdentityManager PEM File
			Write-Host "Creating Full Chain IdentityManager PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			$STEP1 = Get-Content $IdentityManagerKEYPEM
			$STEP2 = Get-Content $IdentityManagerPEM 
			$STEP3 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 + $STEP3
			$COMBINESTEPS | Set-Content $IdentityManagerCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $IdentityManagerCOMBINEDPEM -text -noout
			
			Write-Host "IdentityManager Certificate Generation Process Completed" $IdentityManagerCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
		}Else{
		Write-Error "Multiple PEM Files found with similar name. Please delete CAs from CA folder that are no longer needed and rerun this script."
		}
	}Else{
	Write-Error "CER File was not created. Please troubleshoot request process or manually place CER file in folder and rerun script"
	}
}

Write-Host "Use this file to install the cert on your Identity Manager Cluster" $IdentityManagerCOMBINEDPEM -ForegroundColor Green
Write-Host "Use this file to install the RSA Key on your Identity Manager Cluster" $IdentityManagerKEY -ForegroundColor Green
Write-Host "Note: Only install Certificate on Identity Manager Directly if you are not using a load balancer"

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