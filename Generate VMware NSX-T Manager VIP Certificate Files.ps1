<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			March 17, 2020
	Version:		1.1
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware NSX-T VIP Manager. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate. Fill in the variables and then simply run this script to
		automate the process of generating the certificate.

	.NOTES
		
#>

##NSXTManager Certicate Customizable Variables
$NSXTVIPManagerNAME = "hamnsxt" #Short name for your NSX-T VIP Manager (not FQDN)
$NSXTVIPManagerIP = "192.168.1.59" #Example 10.27.1.12
$NSXTManagerDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$NSXTManagerNAME = $NSXTVIPManagerNAME.ToLower() #NSXTManagerNAME Should be lower case
$NSXTManagerFQDN = "$NSXTVIPManagerNAME.$NSXTManagerDOMAIN"
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
$NSXTManagerCertLocationGet = Get-Item "$CERTLOCATION\NSXT\$NSXTManagerNAME" -ErrorAction SilentlyContinue
$NSXTManagerCertLocation = "$CERTLOCATION\NSXT\$NSXTManagerNAME"
$NSXTManagerKEYGET = Get-Item "$NSXTManagerCertLocation\$NSXTManagerNAME.key" -ErrorAction SilentlyContinue
$NSXTManagerKEY = "$NSXTManagerCertLocation\$NSXTManagerNAME.key" # This is in RSA format
$NSXTManagerKEYPEMGET = Get-Item "$NSXTManagerCertLocation\$NSXTManagerNAME-key.pem" -ErrorAction SilentlyContinue
$NSXTManagerKEYPEM = "$NSXTManagerCertLocation\$NSXTManagerNAME-key.pem" # This is in PEM format
$NSXTManagerCSRGET = Get-Item "$NSXTManagerCertLocation\$NSXTManagerNAME.csr" -ErrorAction SilentlyContinue
$NSXTManagerCSR = "$NSXTManagerCertLocation\$NSXTManagerNAME.csr"
$NSXTManagerCERGET = Get-Item "$NSXTManagerCertLocation\$NSXTManagerNAME.cer" -ErrorAction SilentlyContinue
$NSXTManagerCER = "$NSXTManagerCertLocation\$NSXTManagerNAME.cer" #This is in DER format
$NSXTManagerPEMGET = Get-Item "$NSXTManagerCertLocation\$NSXTManagerNAME.pem" -ErrorAction SilentlyContinue
$NSXTManagerPEM = "$NSXTManagerCertLocation\$NSXTManagerNAME.pem" # This is in PEM format
$NSXTManagerCOMBINEDPEM = "$NSXTManagerCertLocation\$NSXTManagerNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update NSXTManager with.

#Certificate Variables
$CACERT = "$NSXTManagerCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $NSXTManagerNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $NSXTManagerCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $NSXTManagerCertLocation+"\Log\"+$LOGFILENAME

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
	#Note: Update the below with the other IPs of the cluster with Ip.2 = $NSXTManagerIP1, etc.
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
	DNS.1 = $NSXTManagerFQDN
	IP.1 = $NSXTVIPManagerIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$NSXTManagerFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new NSXTManager Cert Folder for storing all the Cert files
	IF(!$NSXTManagerCertLocationGet)
	{
		New-Item -Path $NSXTManagerCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "NSXTManager Folder already created at" $NSXTManagerCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make NSXTManager Config file
	$CFGFILE = New-Item -Path $NSXTManagerCertLocation -Name "$NSXTManagerNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$NSXTManagerKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $NSXTManagerKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $NSXTManagerKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$NSXTManagerKEYPEMGET)
	{
		Write-Host "NSXTManager-key.pem file does not exist"
		Write-Host "Generating NSXTManager-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $NSXTManagerKEY -outform PEM -nocrypt -out $NSXTManagerKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $NSXTManagerKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$NSXTManagerCSRGET)
	{
		Write-Host "NSXTManager CSR File Not Found"
		Write-Host "Generating NSXTManager CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $NSXTManagerKEY -out $NSXTManagerCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $NSXTManagerCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $NSXTManagerCSR -ForegroundColor Blue
	.\openssl req -in $NSXTManagerCSR -noout -text
	
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
	IF(!$NSXTManagerCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $NSXTManagerCSR $NSXTManagerCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $NSXTManagerCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$NSXTManagerCERGETAGAIN = Get-Item "$NSXTManagerCertLocation\$NSXTManagerNAME.cer" -ErrorAction SilentlyContinue
	
	IF($NSXTManagerCERGETAGAIN)			   
	{
		Write-Host "NSX-T Manager CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($NSXTManagerCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$NSXTManagerPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $NSXTManagerCER -outform PEM -out $NSXTManagerPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $NSXTManagerPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the NSXTManager folder
			Write-Host "Copying CA PEM File to NSXTManager Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain NSXTManager PEM File
			Write-Host "Creating Full Chain NSXTManager PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			$STEP1 = Get-Content $NSXTManagerKEYPEM
			$STEP2 = Get-Content $NSXTManagerPEM 
			$STEP3 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 + $STEP3
			$COMBINESTEPS | Set-Content $NSXTManagerCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $NSXTManagerCOMBINEDPEM -text -noout
			
			Write-Host "NSXTManager Certificate Generation Process Completed" $NSXTManagerCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
		}Else{
		Write-Error "Multiple PEM Files found with similar name. Please delete CAs from CA folder that are no longer needed and rerun this script."
		}
	}Else{
	Write-Error "CER File was not created. Please troubleshoot request process or manually place CER file in folder and rerun script"
	}
}

Write-Host "Use this file to install the cert on your NSX-T Manager Cluster" $NSXTManagerCOMBINEDPEM -ForegroundColor Green
Write-Host "Use this file to install the RSA Key on your NSX-T Manager Cluster" $NSXTManagerKEY -ForegroundColor Green

#Show Directions on How to install in NSX-T
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host " "
Write-Host "After the certificate has been uploaded to NSX-T Manager, follow these instructions to install the certificate"
Write-Host "Document the VIP Certificate's ID #"
Write-Host "SSH to NSX VIP IP"
Write-Host "Run these commands to set the certificate as the VIP Certificate"
Write-Host "export NSX_MANAGER_IP_ADDRESS=IPADDRESSHERE" 
Write-Host "Example: export NSX_MANAGER_IP_ADDRESS=192.168.1.59"
Write-Host 'export CERTIFICATE_ID="ID-Number-Here"' 
Write-Host 'Example: export CERTIFICATE_ID="eac3cddd-adba-4865-b748-616a364c9847"' #Replace the ID# with the ID of your Certificate
Write-Host 'curl --insecure -u admin:''RootPASSWORDHERE'' -X POST "https://$NSX_MANAGER_IP_ADDRESS/api/v1/cluster/api-certificate?action=set_cluster_certificate&certificate_id=$CERTIFICATE_ID"'
Write-Host "Reference: https://docs.pivotal.io/pks/1-6/nsxt-generate-ca-cert.html"
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host "-----------------------------------------------------------------------------------------------------------------------"

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