<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			November 17, 2020
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for the VMware Skyline Collector. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process generating certificate files for the said VMware Product.

	.NOTES
		This scripts CSR Template was reverse engineered from a 6.7 VCSA created CSR. I added the email address to it
		to make it easier to see who requested the certificate.
#>

##SKYLINE Certicate Customizable Variables
$SKYLINENAME = "skyline" #Short name for your SKYLINE (not FQDN)
$SKYLINEIP = "192.168.1.66" #Example 10.27.1.12
$SKYLINEDOMAIN = "hamker.local" #Domain Example contso.com
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$SKYLINENAME = $SKYLINENAME.ToLower() #SKYLINENAME Should be lower case
$SKYLINEFQDN = "$SKYLINENAME.$SKYLINEDOMAIN"
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
$SKYLINECertLocationGet = Get-Item "$CERTLOCATION\SKYLINE\$SKYLINEFQDN" -ErrorAction SilentlyContinue
$SKYLINECertLocation = "$CERTLOCATION\SKYLINE\$SKYLINEFQDN"
$SKYLINEKEYGET = Get-Item "$SKYLINECertLocation\$SKYLINENAME.key" -ErrorAction SilentlyContinue
$SKYLINEKEY = "$SKYLINECertLocation\$SKYLINENAME.key" # This is in RSA format
$SKYLINEKEYPEMGET = Get-Item "$SKYLINECertLocation\$SKYLINENAME-key.pem" -ErrorAction SilentlyContinue
$SKYLINEKEYPEMNAME = "$SKYLINENAME-key.pem"
$SKYLINEKEYPEM = "$SKYLINECertLocation\$SKYLINEKEYPEMNAME" # This is in PEM format
$SKYLINECSRGET = Get-Item "$SKYLINECertLocation\$SKYLINENAME.csr" -ErrorAction SilentlyContinue
$SKYLINECSR = "$SKYLINECertLocation\$SKYLINENAME.csr"
$SKYLINECERGET = Get-Item "$SKYLINECertLocation\$SKYLINENAME.cer" -ErrorAction SilentlyContinue
$SKYLINECER = "$SKYLINECertLocation\$SKYLINENAME.cer" #This is in DER format
$SKYLINEPEMGET = Get-Item "$SKYLINECertLocation\$SKYLINENAME.pem" -ErrorAction SilentlyContinue
$SKYLINEPEM = "$SKYLINECertLocation\$SKYLINENAME.pem" # This is in PEM format
$SKYLINECOMBINEDPEMNAME = "$SKYLINENAME-sslCertificateChain.pem"
$SKYLINECOMBINEDPEM = "$SKYLINECertLocation\$SKYLINECOMBINEDPEMNAME" # This is in PEM format. This is the file you use to update SKYLINE with.

#Certificate Variables
$CACERT = "$SKYLINECertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $SKYLINENAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $SKYLINECertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $SKYLINECertLocation+"\Log\"+$LOGFILENAME

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
	#Note: This CNF File is reverse engineered from created a CSR on a 6.7u3 SKYLINE
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
	IP.1 = $SKYLINEIP
	DNS.1 = $SKYLINEFQDN

	[ req_distinguished_name ]
	CN = $SKYLINEFQDN 					#NAME (eg, example.com)
	C = $COUNTRY					#Country
	ST = $STATE					#State
	L = $CITY					#Locality
	O = $COMPANY					#Organization
	OU = $DEPARTMENT				#OrgUnit
	emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs SKYLINE CSR), as required for certain business requirements.
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new SKYLINE Cert Folder for storing all the Cert files
	IF(!$SKYLINECertLocationGet)
	{
		New-Item -Path $SKYLINECertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "SKYLINE Folder already created at" $SKYLINECertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make SKYLINE Config file
	$CFGFILE = New-Item -Path $SKYLINECertLocation -Name "$SKYLINENAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$SKYLINEKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $SKYLINEKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $SKYLINEKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$SKYLINEKEYPEMGET)
	{
		Write-Host "SKYLINE-key.pem file does not exist"
		Write-Host "Generating SKYLINE-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $SKYLINEKEY -outform PEM -nocrypt -out $SKYLINEKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $SKYLINEKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$SKYLINECSRGET)
	{
		Write-Host "SKYLINE CSR File Not Found"
		Write-Host "Generating SKYLINE CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $SKYLINEKEY -out $SKYLINECSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $SKYLINECSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $SKYLINECSR -ForegroundColor Blue
	.\openssl req -in $SKYLINECSR -noout -text
	
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
	IF(!$SKYLINECERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $SKYLINECSR $SKYLINECER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $SKYLINECER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$SKYLINECERGETAGAIN = Get-Item "$SKYLINECertLocation\$SKYLINENAME.cer" -ErrorAction SilentlyContinue
	
	IF($SKYLINECERGETAGAIN)			   
	{
		Write-Host "SKYLINE CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($SKYLINECERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$SKYLINEPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $SKYLINECER -outform PEM -out $SKYLINEPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $SKYLINEPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the SKYLINE folder
			Write-Host "Copying CA PEM File to SKYLINE Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain SKYLINE PEM File
			Write-Host "Creating Full Chain SKYLINE PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			#$STEP1 = Get-Content $SKYLINEKEYPEM
			$STEP1 = Get-Content $SKYLINEPEM 
			$STEP2 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 #+ $STEP3
			$COMBINESTEPS | Set-Content $SKYLINECOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $SKYLINECOMBINEDPEM -text -noout
			
			#Verify Certificate Files
			Write-Host "Displaying Certificate Issuer Chain"
			./openssl crl2pkcs7 -nocrl -certfile $SKYLINEPEM | ./openssl pkcs7 -print_certs -noout
			Write-Host "Displaying MD5 of the $SKYLINEPEM"
			$SKYLINEPEMMD5 = ./openssl x509 -modulus -noout -in $SKYLINEPEM | ./openssl md5
			$SKYLINEPEMMD5 = $SKYLINEPEMMD5.replace("(stdin)= ","")
			Write-Host $SKYLINEPEMMD5
			Write-Host "Displaying MD5 of the $SKYLINEKEYPEM"
			$SKYLINEKEYPEMMD5 = ./openssl rsa -modulus -noout -in $SKYLINEKEYPEM | ./openssl md5
			$SKYLINEKEYPEMMD5 = $SKYLINEKEYPEMMD5.replace("(stdin)= ","")
			Write-Host $SKYLINEKEYPEMMD5
			If($SKYLINEPEMMD5 -eq $SKYLINEKEYPEMMD5)
			{
				Write-Host "MD5s Match for SKYLINEPEM and SKYLINEKEYPEM" -foreground green
			}Else{
				Write-Error "MD5 DO NOT MATCH FOR SKYLINEPEM and SKYLINEKEYPEM"
			}
			Write-Host "  "
			Write-Host "Getting Certificate SHA-1 Thumbprint"
			$THUMBPRINTSHA1 = ./openssl x509 -noout -fingerprint -sha1 -inform pem -in $SKYLINEPEM
			$THUMBPRINTSHA1 = $THUMBPRINTSHA1.replace("SHA1 Fingerprint=","")
			Write-Host $THUMBPRINTSHA1
			Write-Host "  "
			Write-Host "Getting Certificate SHA-256 Thumbprint (Needed for NSX-T)"
			$THUMBPRINTSHA256 = ./openssl x509 -noout -fingerprint -sha256 -inform pem -in $SKYLINEPEM
			$THUMBPRINTSHA256 = $THUMBPRINTSHA256.replace("SHA256 Fingerprint=","")
			Write-Host $THUMBPRINTSHA256
			Write-Host "  "
			Write-Host "SKYLINE Certificate Generation Process Completed" $SKYLINECOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host "Use this file to install the Cert on your SKYLINE" $SKYLINECOMBINEDPEM -ForegroundColor Green
			Write-Host "Use this file to install the Key on your SKYLINE" $SKYLINEKEYPEM -ForegroundColor Green
			Write-Host "Use this file to install the CA cert on your SKYLINE" $CACERT -ForegroundColor Green
			Write-Host "#######################################################################################################################"
			Write-Host "Directions:"
			$VAMIURL = "https://$SKYLINEFQDN/configuration/web-server-certificate"
			Write-Host @"
Steps to Replace Skyline Certificate
Please take a snapshot on the Skyline Collector Appliance prior to beginning this process
1. Open a web browser to $VAMIURL
2. Login with the admin account
3. Click on Choose File next to Certificate (.cert/.cer/.crt/.pem
4. Select the PEM file previously Generated $SKYLINECOMBINEDPEM
5. Click on Choose File next to Certificate key (.key/.pem)
6. Select the KEY PEM file previously Generated $SKYLINEKEYPEM
7. Click on SET CERTIFICATE
8. Open an Incognito browser to the Skyline Appliance and verify that the certificate has been replaced.
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