<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			Janunary 2, 2025
	Version:		1.2.2
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware VCSA (VMware vCenter Server Applaince) to become a Subordinate CA.
		This includes generating all certificates using a Windows CA and CA Template. You must open this script and change the variables 
		to match your environment and then execute the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate for the VCSA to become a subordindate CA. Fill in the variables and then simply run this
		script to automate the process of generating the certificate.

		This scripts CSR Template was reverse engineered from a 8.0 VCSA created CSR.
#>

##VCSA Certicate Customizable Variables
$VCSANAME = "hamvc01" #Short name for your VCSA (not FQDN)
$VCSAIP = "192.168.1.65" #Example 10.27.1.12
$VCSADOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:SubCA" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:SubCA
$VCSANAME = $VCSANAME.ToLower() #VCSANAME Should be lower case
$VCSAFQDN = "$VCSANAME.$VCSADOMAIN"
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
$VCSACertLocationGet = Get-Item "$CERTLOCATION\SubordinateCA\$VCSAFQDN" -ErrorAction SilentlyContinue
$VCSACertLocation = "$CERTLOCATION\SubordinateCA\$VCSAFQDN"
$VCSAKEYGET = Get-Item "$VCSACertLocation\$VCSANAME-ca.key" -ErrorAction SilentlyContinue
$VCSAKEY = "$VCSACertLocation\$VCSANAME-ca.key" # This is in RSA format
$VCSAKEYPEMGET = Get-Item "$VCSACertLocation\$VCSANAME-ca-key.pem" -ErrorAction SilentlyContinue
$VCSAKEYPEMNAME = "$VCSANAME-ca-key.pem"
$VCSAKEYPEM = "$VCSACertLocation\$VCSAKEYPEMNAME" # This is in PEM format
$VCSACSRGET = Get-Item "$VCSACertLocation\$VCSANAME-ca.csr" -ErrorAction SilentlyContinue
$VCSACSR = "$VCSACertLocation\$VCSANAME-ca.csr"
$VCSACERGET = Get-Item "$VCSACertLocation\$VCSANAME-ca.cer" -ErrorAction SilentlyContinue
$VCSACER = "$VCSACertLocation\$VCSANAME-ca.cer" #This is in DER format
$VCSAPEMGET = Get-Item "$VCSACertLocation\$VCSANAME-ca.pem" -ErrorAction SilentlyContinue
$VCSAPEM = "$VCSACertLocation\$VCSANAME-ca.pem" # This is in PEM format
$VCSACOMBINEDPEMNAME = "$VCSANAME-ca-sslCertificateChain.pem"
$VCSACOMBINEDPEM = "$VCSACertLocation\$VCSACOMBINEDPEMNAME" # This is in PEM format. This is the file you use to update VCSA with.

#Certificate Variables
$CACERT = "$VCSACertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $VCSANAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $VCSACertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $VCSACertLocation+"\Log\"+$LOGFILENAME

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
	#Note: This CNF File is reverse engineered from created a CSR on a 6.7u3 VCSA
	$CNF = "[ req ]
	default_md = sha256
	default_bits = 4096
	default_keyfile = key.key
	distinguished_name = req_distinguished_name
	encrypt_key = no
	prompt = no
	string_mask = nombstr
	req_extensions = v3_ca

	[ v3_ca ]
	basicConstraints = critical, CA:TRUE, pathlen:0
	keyUsage = critical, keyCertSign, cRLSign
	extendedKeyUsage = critical, serverAuth, clientAuth
	subjectAltName = @alt_names
	subjectKeyIdentifier = hash

	[ alt_names ]
	email = $EMAILADDRESS
	IP.1 = $VCSAIP
	DNS.1 = $VCSAFQDN

	[ req_distinguished_name ]
	CN = $VCSAFQDN 					#NAME (eg, example.com)
	C = $COUNTRY					#Country
	ST = $STATE					#State
	L = $CITY					#Locality
	O = $COMPANY					#Organization
	OU = $DEPARTMENT				#OrgUnit
	emailAddress = $EMAILADDRESS	#emailAddress #Note: Added this field (not std version vs VCSA CSR), as required for certain business requirements.
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new VCSA Cert Folder for storing all the Cert files
	IF(!$VCSACertLocationGet)
	{
		New-Item -Path $VCSACertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "VCSA Folder already created at" $VCSACertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make VCSA Config file
	$CFGFILE = New-Item -Path $VCSACertLocation -Name "$VCSANAME-ca.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$VCSAKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $VCSAKEY 4096

		#Update output for Unix format
		[IO.File]::WriteAllText("$VCSAKEY", ([IO.File]::ReadAllText("$VCSAKEY") -replace "`r`n","`n"))

		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $VCSAKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$VCSAKEYPEMGET)
	{
		Write-Host "VCSA-key.pem file does not exist"
		Write-Host "Generating VCSA-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $VCSAKEY -outform PEM -nocrypt -out $VCSAKEYPEM
		#Update output for Unix format
		[IO.File]::WriteAllText("$VCSAKEYPEM", ([IO.File]::ReadAllText("$VCSAKEYPEM") -replace "`r`n","`n"))
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $VCSAKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$VCSACSRGET)
	{
		Write-Host "VCSA CSR File Not Found"
		Write-Host "Generating VCSA CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $VCSAKEY -out $VCSACSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $VCSACSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $VCSACSR -ForegroundColor Blue
	.\openssl req -in $VCSACSR -noout -text
	
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
	IF(!$VCSACERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $VCSACSR $VCSACER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $VCSACER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$VCSACERGETAGAIN = Get-Item "$VCSACertLocation\$VCSANAME-ca.cer" -ErrorAction SilentlyContinue
	
	IF($VCSACERGETAGAIN)			   
	{
		Write-Host "VCSA CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($VCSACERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$VCSAPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $VCSACER -outform PEM -out $VCSAPEM

			#Update output for Unix format
			[IO.File]::WriteAllText("$VCSAPEM", ([IO.File]::ReadAllText("$VCSAPEM") -replace "`r`n","`n"))

			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $VCSAPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the VCSA folder
			Write-Host "Copying CA PEM File to VCSA Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain VCSA PEM File
			Write-Host "Creating Full Chain VCSA PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			#$STEP1 = Get-Content $VCSAKEYPEM
			$STEP1 = Get-Content $VCSAPEM 
			$STEP2 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 #+ $STEP3
			$COMBINESTEPS | Set-Content $VCSACOMBINEDPEM

			#Update output for Unix format
			[IO.File]::WriteAllText("$VCSACOMBINEDPEM", ([IO.File]::ReadAllText("$VCSACOMBINEDPEM") -replace "`r`n","`n"))
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $VCSACOMBINEDPEM -text -noout
			
			#Verify Certificate Files
			Write-Host "Displaying Certificate Issuer Chain"
			./openssl crl2pkcs7 -nocrl -certfile $VCSAPEM | ./openssl pkcs7 -print_certs -noout
			Write-Host "Displaying MD5 of the $VCSAPEM"
			$VCSAPEMMD5 = ./openssl x509 -modulus -noout -in $VCSAPEM | ./openssl md5
			$VCSAPEMMD5 = $VCSAPEMMD5.replace("(stdin)= ","")
			Write-Host $VCSAPEMMD5
			Write-Host "Displaying MD5 of the $VCSAKEYPEM"
			$VCSAKEYPEMMD5 = ./openssl rsa -modulus -noout -in $VCSAKEYPEM | ./openssl md5
			$VCSAKEYPEMMD5 = $VCSAKEYPEMMD5.replace("(stdin)= ","")
			Write-Host $VCSAKEYPEMMD5
			If($VCSAPEMMD5 -eq $VCSAKEYPEMMD5)
			{
				Write-Host "MD5s Match for VCSAPEM and VCSAKEYPEM" -foreground green
			}Else{
				Write-Error "MD5 DO NOT MATCH FOR VCSAPEM and VCSAKEYPEM"
			}
			Write-Host "  "
			Write-Host "Getting Certificate SHA-1 Thumbprint"
			$THUMBPRINTSHA1 = ./openssl x509 -noout -fingerprint -sha1 -inform pem -in $VCSAPEM
			$THUMBPRINTSHA1 = $THUMBPRINTSHA1.replace("SHA1 Fingerprint=","")
			Write-Host $THUMBPRINTSHA1
			Write-Host "  "
			Write-Host "Getting Certificate SHA-256 Thumbprint (Needed for NSX-T)"
			$THUMBPRINTSHA256 = ./openssl x509 -noout -fingerprint -sha256 -inform pem -in $VCSAPEM
			$THUMBPRINTSHA256 = $THUMBPRINTSHA256.replace("SHA256 Fingerprint=","")
			Write-Host $THUMBPRINTSHA256
			Write-Host "  "
			Write-Host "VCSA Certificate Generation Process Completed" $VCSACOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host "Use this file to install the Cert on your VCSA" $VCSACOMBINEDPEM -ForegroundColor Green
			Write-Host "Use this file to install the Key on your VCSA" $VCSAKEYPEM -ForegroundColor Green
			Write-Host "Use this file to install the CA cert on your VCSA" $CACERT -ForegroundColor Green
			Write-Host "#######################################################################################################################"
			Write-Host "Directions:"
			$VAMIURL = "https://$VCSAFQDN"+":5480/login"
			Write-Host @"
SSH to your VCSA using the root login

#Create a \certs folder
mkdir \certs

#Copy Certificates listed below to \certs. Use WinSCP or some other means to copy files over.
$VCSACOMBINEDPEM
$VCSAKEYPEM
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
/certs/$VCSACOMBINEDPEMNAME

#Specify the name of the file below for
#Please provide valid custom key for Root.
/certs/$VCSAKEYPEMNAME

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