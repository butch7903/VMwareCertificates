<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			March 20, 2020
	Version:		2.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for VMware vROPs. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of deploying vSphere Integrated Containers.

	.NOTES
		
#>

##VROPS Certicate Customizable Variables
$VROPSNAME = "vrops" #Short name for your vROPs node (not FQDN)
$VROPSIP = "192.168.1.55" #Example 10.27.1.12
$VROPSDOMAIN = "hamker.local"
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Vmware6.0WebServer
$VROPSNAME = $VROPSNAME.ToLower() #VROPSNAME Should be lower case
$VROPSFQDN = "$VROPSNAME.$VROPSDOMAIN"
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
$VROPSCertLocationGet = Get-Item "$CERTLOCATION\VROPS\$VROPSFQDN" -ErrorAction SilentlyContinue
$VROPSCertLocation = "$CERTLOCATION\VROPS\$VROPSFQDN"
$VROPSKEYGET = Get-Item "$VROPSCertLocation\$VROPSNAME.key" -ErrorAction SilentlyContinue
$VROPSKEY = "$VROPSCertLocation\$VROPSNAME.key" # This is in RSA format
$VROPSKEYPEMGET = Get-Item "$VROPSCertLocation\$VROPSNAME-key.pem" -ErrorAction SilentlyContinue
$VROPSKEYPEM = "$VROPSCertLocation\$VROPSNAME-key.pem" # This is in PEM format
$VROPSCSRGET = Get-Item "$VROPSCertLocation\$VROPSNAME.csr" -ErrorAction SilentlyContinue
$VROPSCSR = "$VROPSCertLocation\$VROPSNAME.csr"
$VROPSCERGET = Get-Item "$VROPSCertLocation\$VROPSNAME.cer" -ErrorAction SilentlyContinue
$VROPSCER = "$VROPSCertLocation\$VROPSNAME.cer" #This is in DER format
$VROPSPEMGET = Get-Item "$VROPSCertLocation\$VROPSNAME.pem" -ErrorAction SilentlyContinue
$VROPSPEM = "$VROPSCertLocation\$VROPSNAME.pem" # This is in PEM format
$VROPSCOMBINEDPEM = "$VROPSCertLocation\$VROPSNAME-sslCertificateChain.pem" # This is in PEM format. This is the file you use to update VROPS with.

#Certificate Variables
$CACERT = "$VROPSCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $VROPSNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $VROPSCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $VROPSCertLocation+"\Log\"+$LOGFILENAME

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
	#Note: Update the below with the other IPs of the cluster with Ip.2 = $VROPSIP1, etc.
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
	keyUsage = keyEncipherment, digitalSignature, keyAgreement
	extendedKeyUsage = serverAuth, clientAuth
	subjectAltName = @alt_names

	[ alt_names ]
	DNS.1 = $VROPSFQDN
	IP.1 = $VROPSIP

	[ req_distinguished_name ]
	C=$COUNTRY
	ST=$STATE
	L=$CITY
	O=$COMPANY
	OU=$DEPARTMENT
	CN=$VROPSFQDN
	emailAddress=$EMAILADDRESS
	"

	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation
	
	#Make new VROPS Cert Folder for storing all the Cert files
	IF(!$VROPSCertLocationGet)
	{
		New-Item -Path $VROPSCertLocation -ItemType "directory" -ErrorAction SilentlyContinue
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "VROPS Folder already created at" $VROPSCertLocation -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Make VROPS Config file
	$CFGFILE = New-Item -Path $VROPSCertLocation -Name "$VROPSNAME.cfg" -ItemType "file" -Force
	#$CNF | Out-File -FilePath $CFGFILE
	
	#Write contents to Config file from $CNF Variable
	Set-Content -Path $CFGFILE -Value $CNF
	$CFGFILEFULLNAME = $cfgfile.fullname
	
	IF(!$VROPSKEYGET)
	{
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl genrsa -out $VROPSKEY 2048
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.key already generated at" $VROPSKEY -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	IF(!$VROPSKEYPEMGET)
	{
		Write-Host "VROPS-key.pem file does not exist"
		Write-Host "Generating VROPS-key.pem file"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl pkcs8 -topk8 -in $VROPSKEY -outform PEM -nocrypt -out $VROPSKEYPEM
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Key.pem already generated at" $VROPSKEYPEM -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}

	IF(!$VROPSCSRGET)
	{
		Write-Host "VROPS CSR File Not Found"
		Write-Host "Generating VROPS CSR"
		#Open OpenSSL EXE Location
		CD $OpenSSLLocation
		.\openssl req -config $CFGFILEFULLNAME -new -key $VROPSKEY -out $VROPSCSR
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.csr already generated at" $VROPSCSR -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Read CSR
	Write-Host "CSR Info is:" $VROPSCSR -ForegroundColor Blue
	.\openssl req -in $VROPSCSR -noout -text
	
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
	IF(!$VROPSCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $VROPSCSR $VROPSCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $VROPSCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$VROPSCERGETAGAIN = Get-Item "$VROPSCertLocation\$VROPSNAME.cer" -ErrorAction SilentlyContinue
	
	IF($VROPSCERGETAGAIN)			   
	{
		Write-Host "vROPs Manager CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($VROPSCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$VROPSPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $VROPSCER -outform PEM -out $VROPSPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $VROPSPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the VROPS folder
			Write-Host "Copying CA PEM File to VROPS Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain vROPS PEM File
			Write-Host "Create Full Chain vROPS PEM File"
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			#Reference https://kb.vmware.com/s/article/2046591
			#Reference 2 https://docs.vmware.com/en/vRealize-Operations-Manager/8.0/com.vmware.vcom.core.doc/GUID-D476DD8F-0CCA-460D-BE94-9AC3F677B1EA.html
			$STEP1 = Get-Content $VROPSPEM
			$STEP2 = Get-Content $VROPSKEY
			$STEP3 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 + $STEP3
			$COMBINESTEPS | Set-Content $VROPSCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $VROPSCOMBINEDPEM -text -noout
			
			Write-Host "VROPS Certificate Generation Process Completed" $VROPSCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			
			Write-Host "#######################################################################################################################" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss") -ForegroundColor Green
			Write-Host "Use the vROPs Combined PEM File to set your cert on vROPs. https://vrops.fqdn.here/admin" -ForegroundColor Green
			Write-Host $VROPSCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss") -ForegroundColor Green
			Write-Host "#######################################################################################################################" -ForegroundColor Green
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