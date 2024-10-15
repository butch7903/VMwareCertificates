<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			October 15, 2024
	Version:		1.2.1
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for a Gitlab Server. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying vSphere Integrated Containers.
		
	.EXAMPLE
	#Example 1
	./'Generate Gitlab Certificate Files.ps1'
#>

##System Certicate Customizable Variables
$SHORTNAME = "ham-gitlab-001" #Short name for your System (not FQDN)
$SYSIP = "192.168.1.165" #Example 10.27.1.12
$SYSDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$SHORTNAME = $SHORTNAME.ToLower() #SHORTNAME Should be lower case
$SYSFQDN = "$SHORTNAME.$SYSDOMAIN"
$SYSFQDN = $SYSFQDN.ToLower() #FQDN Should be lower case
$COUNTRY = "US" #2 Letter Country Code
$STATE = "KS" #Your State
$CITY = "Wichita" #Your City
$COMPANY = "Hamker Tech" #Your Company
$DEPARTMENT = "IT VMware Team" #Your Department
$EMAILADDRESS = "YourGroupEmailAddressHere@me.com" #Department Email								  
$CAFILELOCATION = "C:\certs\CAs\Combined" #Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from #Example C:\Certs\CA\Combined\CombinedCA_HAMCA01-CA-PEM.pem
$CERTIFICATESERVER = "hamca01.hamker.local" #FQDN of the Certificate server you are getting your certs from #Example HAMCA01.hamker.local

#Standard Variables
$CERTLOCATION = "C:\Certs"
$SYSCERTLOCATIONGET = Get-Item "$CERTLOCATION\Gitlab\$SYSFQDN" -ErrorAction SilentlyContinue
$SYSCERTLOCATION = "$CERTLOCATION\Gitlab\$SYSFQDN"
$SYSKEYGET = Get-Item "$SYSCERTLOCATION\$SHORTNAME.key" -ErrorAction SilentlyContinue
$KEYFILE = "$SHORTNAME.key"
$SYSKEY = "$SYSCERTLOCATION\$KEYFILE" # This is in RSA format
$SYSKEYPEMGET = Get-Item "$SYSCERTLOCATION\$SHORTNAME-key.pem" -ErrorAction SilentlyContinue
$SYSKEYPEMNAME = "$SHORTNAME-key.pem"
$SYSKEYPEM = "$SYSCERTLOCATION\$SYSKEYPEMNAME" # This is in PEM format
$SYSCSRGET = Get-Item "$SYSCERTLOCATION\$SHORTNAME.csr" -ErrorAction SilentlyContinue
$SYSCSR = "$SYSCERTLOCATION\$SHORTNAME.csr"
$SYSCERGET = Get-Item "$SYSCERTLOCATION\$SHORTNAME.cer" -ErrorAction SilentlyContinue
$SYSCER = "$SYSCERTLOCATION\$SHORTNAME.cer" #This is in DER format
$SYSPEMGET = Get-Item "$SYSCERTLOCATION\$SHORTNAME.pem" -ErrorAction SilentlyContinue
$SYSPEM = "$SYSCERTLOCATION\$SHORTNAME.pem" # This is in PEM format
$SYSCOMBINEDPEMNAME = "$SHORTNAME-sslcertificatechain.pem"
$SYSCOMBINEDPEM = "$SYSCERTLOCATION\$SYSCOMBINEDPEMNAME" # This is in PEM format. This is the file you use to update the System with.

#Certificate Variables
$CACERT = "$SYSCERTLOCATION\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $SHORTNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $SYSCERTLOCATION+"\log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $SYSCERTLOCATION+"\log\"+$LOGFILENAME

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
	subjectKeyIdentifier = hash

	[ alt_names ]
	email = $EMAILADDRESS
	IP.1 = $SYSIP
	DNS.1 = $SYSFQDN

	[ req_distinguished_name ]
	CN = $SYSFQDN 					#NAME (eg, example.com)
	C = $COUNTRY					#Country
	ST = $STATE					#State
	L = $CITY					#Locality
	O = $COMPANY					#Organization
	OU = $DEPARTMENT				#OrgUnit
	emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs System CSR), as required for certain business requirements.
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new System Cert Folder for storing all the Cert files
	IF(!$SYSCERTLOCATIONGET)
	{
		New-Item -Path $SYSCERTLOCATION -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "System Folder already created at" $SYSCERTLOCATION -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make System Config file
	$CFGFILE = New-Item -Path $SYSCERTLOCATION -Name "$SHORTNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$SYSKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $SYSKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $SYSKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$SYSKEYPEMGET)
	{
		Write-Host "$SHORTNAME-key.pem file does not exist"
		Write-Host "Generating $SHORTNAME-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $SYSKEY -outform PEM -nocrypt -out $SYSKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $SYSKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$SYSCSRGET)
	{
		Write-Host "$SHORTNAME CSR File Not Found"
		Write-Host "Generating $SHORTNAME CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $SYSKEY -out $SYSCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $SYSCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $SYSCSR -ForegroundColor Blue
	.\openssl req -in $SYSCSR -noout -text
	
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
	IF(!$SYSCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $SYSCSR $SYSCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $SYSCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$SYSCERGETAGAIN = Get-Item "$SYSCERTLOCATION\$SHORTNAME.cer" -ErrorAction SilentlyContinue
	
	IF($SYSCERGETAGAIN)			   
	{
		Write-Host "$SHORTNAME CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($SYSCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$SYSPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $SYSCER -outform PEM -out $SYSPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $SYSPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the System folder
			Write-Host "Copying CA PEM File to System Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain System PEM File
			Write-Host "Creating Full Chain System PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			#$STEP1 = Get-Content $SYSKEYPEM
			$STEP1 = Get-Content $SYSPEM 
			$STEP2 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 #+ $STEP3
			$COMBINESTEPS | Set-Content $SYSCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $SYSCOMBINEDPEM -text -noout
			
			#Verify Certificate Files
			Write-Host "Displaying Certificate Issuer Chain"
			./openssl crl2pkcs7 -nocrl -certfile $SYSPEM | ./openssl pkcs7 -print_certs -noout
			Write-Host "Displaying MD5 of the $SYSPEM"
			$SYSPEMMD5 = ./openssl x509 -modulus -noout -in $SYSPEM | ./openssl md5
			$SYSPEMMD5 = $SYSPEMMD5.replace("(stdin)= ","")
			Write-Host $SYSPEMMD5
			Write-Host "Displaying MD5 of the $SYSKEYPEM"
			$SYSKEYPEMMD5 = ./openssl rsa -modulus -noout -in $SYSKEYPEM | ./openssl md5
			$SYSKEYPEMMD5 = $SYSKEYPEMMD5.replace("(stdin)= ","")
			Write-Host $SYSKEYPEMMD5
			If($SYSPEMMD5 -eq $SYSKEYPEMMD5)
			{
				Write-Host "MD5s Match for SYSPEM and SYSKEYPEM" -foreground green
			}Else{
				Write-Error "MD5 DO NOT MATCH FOR SYSPEM and SYSKEYPEM"
			}
			Write-Host "  "
			Write-Host "Getting Certificate SHA-1 Thumbprint"
			$THUMBPRINTSHA1 = ./openssl x509 -noout -fingerprint -sha1 -inform pem -in $SYSPEM
			$THUMBPRINTSHA1 = $THUMBPRINTSHA1.replace("SHA1 Fingerprint=","")
			Write-Host $THUMBPRINTSHA1
			Write-Host "  "
			Write-Host "Getting Certificate SHA-256 Thumbprint (Needed for NSX-T)"
			$THUMBPRINTSHA256 = ./openssl x509 -noout -fingerprint -sha256 -inform pem -in $SYSPEM
			$THUMBPRINTSHA256 = $THUMBPRINTSHA256.replace("SHA256 Fingerprint=","")
			Write-Host $THUMBPRINTSHA256
			Write-Host "  "
			Write-Host "System Certificate Generation Process Completed" $SYSCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host "Use this file to install the Cert on your System" $SYSCOMBINEDPEM -ForegroundColor Green
			Write-Host "Use this file to install the Key on your System" $SYSKEY -ForegroundColor Green
			Write-Host "Use this file to install the CA cert on your System" $CACERT -ForegroundColor Green
			Write-Host "#######################################################################################################################"
			Write-Host "Directions:"
			$VAMIURL = "https://$SYSFQDN"+":5480/login"
			Write-Host @"
SSH to your system using the root login

#Create a \certs folder
mkdir \certs

#Copy Certificates listed below to \certs. Use WinSCP or some other means to copy files over.
$SYSCOMBINEDPEM
$SYSKEY
$CACERT

#Install CA certificate on Server
cp CA.pem ca.crt
cp ca.crt /usr/local/share/ca-certificates
sudo update-ca-certificates

#create gitlab ssl folder and install cert
mkdir /etc/gitlab/ssl/
cp $SYSCOMBINEDPEMNAME $KEYFILE /etc/gitlab/ssl/

#follow gitlab documention to install ssl cert on Gitlab
https://docs.gitlab.com/omnibus/settings/ssl/

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