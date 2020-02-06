<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			February 5, 2020
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware NSX-T Nodes. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying vSphere Integrated Containers.

	.NOTES
		
#>

##NSXTNode Certicate Customizable Variables
$NSXTNodeNAME = "hamnsxt01" #Short name for your NSX-T Node (not FQDN)
$NSXTNodeIP = "192.168.1.61" #Example 10.27.1.12
$NSXTNodeDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$NSXTNodeNAME = $NSXTNodeNAME.ToLower() #NSXTNodeNAME Should be lower case
$NSXTNodeFQDN = "$NSXTNodeNAME.$NSXTNodeDOMAIN"
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
$NSXTNodeCertLocationGet = Get-Item "$CERTLOCATION\NSXTNode\$NSXTNodeNAME" -ErrorAction SilentlyContinue
$NSXTNodeCertLocation = "$CERTLOCATION\NSXTNode\$NSXTNodeNAME"
$NSXTNodeKEYGET = Get-Item "$NSXTNodeCertLocation\$NSXTNodeNAME.key" -ErrorAction SilentlyContinue
$NSXTNodeKEY = "$NSXTNodeCertLocation\$NSXTNodeNAME.key" # This is in RSA format
$NSXTNodeKEYPEMGET = Get-Item "$NSXTNodeCertLocation\$NSXTNodeNAME-key.pem" -ErrorAction SilentlyContinue
$NSXTNodeKEYPEM = "$NSXTNodeCertLocation\$NSXTNodeNAME-key.pem" # This is in PEM format
$NSXTNodeCSRGET = Get-Item "$NSXTNodeCertLocation\$NSXTNodeNAME.csr" -ErrorAction SilentlyContinue
$NSXTNodeCSR = "$NSXTNodeCertLocation\$NSXTNodeNAME.csr"
$NSXTNodeCERGET = Get-Item "$NSXTNodeCertLocation\$NSXTNodeNAME.cer" -ErrorAction SilentlyContinue
$NSXTNodeCER = "$NSXTNodeCertLocation\$NSXTNodeNAME.cer" #This is in DER format
$NSXTNodePEMGET = Get-Item "$NSXTNodeCertLocation\$NSXTNodeNAME.pem" -ErrorAction SilentlyContinue
$NSXTNodePEM = "$NSXTNodeCertLocation\$NSXTNodeNAME.pem" # This is in PEM format
$NSXTNodeCOMBINEDPEM = "$NSXTNodeCertLocation\$NSXTNodeNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update NSXTNode with.

#Certificate Variables
$CACERT = "$NSXTNodeCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $NSXTNodeNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $NSXTNodeCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $NSXTNodeCertLocation+"\Log\"+$LOGFILENAME

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
	#Note: Update the below with the other IPs of the cluster with Ip.2 = $NSXTNodeIP1, etc.
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
	DNS.1 = $NSXTNodeFQDN
	IP.1 = $NSXTNodeIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$NSXTNodeFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new NSXTNode Cert Folder for storing all the Cert files
	IF(!$NSXTNodeCertLocationGet)
	{
		New-Item -Path $NSXTNodeCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "NSXTNode Folder already created at" $NSXTNodeCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make NSXTNode Config file
	$CFGFILE = New-Item -Path $NSXTNodeCertLocation -Name "$NSXTNodeNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$NSXTNodeKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $NSXTNodeKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $NSXTNodeKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$NSXTNodeKEYPEMGET)
	{
		Write-Host "NSXTNode-key.pem file does not exist"
		Write-Host "Generating NSXTNode-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $NSXTNodeKEY -outform PEM -nocrypt -out $NSXTNodeKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $NSXTNodeKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$NSXTNodeCSRGET)
	{
		Write-Host "NSXTNode CSR File Not Found"
		Write-Host "Generating NSXTNode CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $NSXTNodeKEY -out $NSXTNodeCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $NSXTNodeCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $NSXTNodeCSR -ForegroundColor Blue
	.\openssl req -in $NSXTNodeCSR -noout -text
	
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
	IF(!$NSXTNodeCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $NSXTNodeCSR $NSXTNodeCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $NSXTNodeCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$NSXTNodeCERGETAGAIN = Get-Item "$NSXTNodeCertLocation\$NSXTNodeNAME.cer" -ErrorAction SilentlyContinue
	
	IF($NSXTNodeCERGETAGAIN)			   
	{
		Write-Host "NSX-T Manager CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($NSXTNodeCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$NSXTNodePEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $NSXTNodeCER -outform PEM -out $NSXTNodePEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $NSXTNodePEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the NSXTNode folder
			Write-Host "Copying CA PEM File to NSXTNode Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain NSXTNode PEM File
			Write-Host "Creating Full Chain NSXTNode PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			$STEP1 = Get-Content $NSXTNodeKEYPEM
			$STEP2 = Get-Content $NSXTNodePEM 
			$STEP3 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 + $STEP3
			$COMBINESTEPS | Set-Content $NSXTNodeCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $NSXTNodeCOMBINEDPEM -text -noout
			
			Write-Host "NSXTNode Certificate Generation Process Completed" $NSXTNodeCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
		}Else{
		Write-Error "Multiple PEM Files found with similar name. Please delete CAs from CA folder that are no longer needed and rerun this script."
		}
	}Else{
	Write-Error "CER File was not created. Please troubleshoot request process or manually place CER file in folder and rerun script"
	}
}

Write-Host "Use this file to install the cert on your NSX-T Manager Cluster for Each Node" $NSXTNodeCOMBINEDPEM -ForegroundColor Green
Write-Host "Use this file to install the RSA Key on your NSX-T Manager Cluster for Each Node" $NSXTNodeKEY -ForegroundColor Green

#Show Directions on How to install in NSX-T
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
Write-Host " "
Write-Host "After the certificate has been uploaded to NSX-T Manager, follow these instructions to install the certificate"
Write-Host "Document the Node Certificate's ID #"
Write-Host "SSH to NSX Node IP"
Write-Host "Run these commands to set the certificate as the Node Certificate"
Write-Host "export NSX_MANAGER_IP_ADDRESS=IPADDRESSHERE" 
Write-Host "Example: export NSX_MANAGER_IP_ADDRESS=192.168.1.61"
Write-Host 'export CERTIFICATE_ID="ID-Number-Here"' 
Write-Host 'Example: export CERTIFICATE_ID="f17d761a-a8e0-4251-a3f6-6c73388df820"' #Replace the ID# with the ID of your Certificate
Write-Host 'curl --insecure -u admin:''RootPASSWORDHERE'' -X POST "https://$NSX_MANAGER_IP_ADDRESS/api/v1/node/services/http?action=apply_certificate&certificate_id=$CERTIFICATE_ID"'
Write-Host "Reference: https://docs.vmware.com/en/VMware-NSX-T-Data-Center/2.5/administration/GUID-50C36862-A29D-48FA-8CE7-697E64E10E37.html"
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