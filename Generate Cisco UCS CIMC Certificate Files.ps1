<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			May 13, 2020
	Version:		1.0
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates for the Cisco UCS CIMC Web Interface. This includes generating all certificates
		using a Windows CA and CA Template. You must open this script and change the variables to match your environment and then execute
		the PS1 file.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of generating certificates.

	.NOTES
		I added the email address to it to make it easier to see who requested the certificate.
#>

##CIMC Certicate Customizable Variables
$CERTLOCATION = "C:\Certs"		#Location where you want to create your certificates		  
$CAFILELOCATION = "C:\certs\CAs\Combined" #Folder location of combined CA Files. Make sure you put your Combined CA PEM file somewhere it can be copied over easily from #Example C:\Certs\CA\Combined\CombinedCA_HAMCA01-CA-PEM.pem
$CERTIFICATESERVER = "hamca01.hamker.local" #FQDN of the Certificate server you are getting your certs from #Example HAMCA01.hamker.local
$CERTTEMPLATE = "CertificateTemplate:VMwareWebServer" #To List the Certiicate Templates to get the right 1 #certutil -template | Select-String -Pattern TemplatePropCommonName #Example CertificateTemplate:Cisco6.0WebServer

#Standard Variables
$CIMCFQDN = Read-Host "Provide the FQDN for your Cisco UCS CIMC"
$CIMCFQDN = $CIMCFQDN.ToLower() #CIMCNAME Should be lower case	
$CIMCCertLocationGet = Get-Item "$CERTLOCATION\CIMC\$CIMCFQDN" -ErrorAction SilentlyContinue
$CIMCCertLocation = "$CERTLOCATION\CIMC\$CIMCFQDN"
$CIMCCSRGET = Get-Item "$CIMCCertLocation\$CIMCFQDN.csr" -ErrorAction SilentlyContinue
$CIMCCSR = "$CIMCCertLocation\$CIMCFQDN.csr"
$CIMCCERGET = Get-Item "$CIMCCertLocation\$CIMCFQDN.cer" -ErrorAction SilentlyContinue
$CIMCCER = "$CIMCCertLocation\$CIMCFQDN.cer" #This is in DER format
$CIMCPEMGET = Get-Item "$CIMCCertLocation\$CIMCFQDN.pem" -ErrorAction SilentlyContinue
$CIMCCRT = "$CIMCCertLocation\$CIMCFQDN.crt" #This is in DER format
$CIMCPFX = "$CIMCCertLocation\$CIMCFQDN.pfx" #This is in pks12 format
$CIMCPEM = "$CIMCCertLocation\$CIMCFQDN.pem" # This is in PEM format
$CIMCCOMBINEDPEMNAME = "$CIMCFQDN-sslCertificateChain.pem"
$CIMCCOMBINEDPEM = "$CIMCCertLocation\$CIMCCOMBINEDPEMNAME" # This is in PEM format. This is the file you use to update CIMC with.

#Certificate Variables
$CACERT = "$CIMCCertLocation\CA.pem" #This must be in PEM format, note this is copied from a network location typically #Example CombinedCA_HAMCA01-CA-PEM.pem
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

##Logging Info
#Get Date Info for naming of snapshot variable
$LOGDATE = Get-Date -format "MMM-dd-yyyy_HH-mm"
#Specify Log File Info
$LOGFILENAME = "Log_" + $CIMCNAME + "_" + $LOGDATE + ".txt"
#Create Log Folder
$LogFolder = $CIMCCertLocation+"\Log"
If (Test-Path $LogFolder){
	Write-Host "Log Directory Created. Continuing..."
}Else{
	New-Item $LogFolder -type directory
}
#Specify Log File
$LOGFILE = $CIMCCertLocation+"\Log\"+$LOGFILENAME

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
	#Open OpenSSL EXE Location
	Write-Host "-----------------------------------------------------------------------------------------------------------------------"
	Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	Write-Host "Starting Certifacte Creation Process"
	CD $OpenSSLLocation

	#Copy CSR to Folder
	$CSRLOCATION = Read-Host "Please Provide full file path to CSR Generated by UCS CIMC"
	Copy-Item -Path $CSRLOCATION -Destination $CIMCCSR
	
	#Read CSR
	Write-Host "CSR Info is:" $CIMCCSR -ForegroundColor Blue
	.\openssl req -in $CIMCCSR -noout -text
	
	$CA = certutil -config $CERTIFICATESERVER -ping
	$CA = $CA[1]
	$CA = $CA.Replace("Server "," ")
	$CA = $CA.SubString(0, $CA.IndexOf('ICertRequest2'))
	$CA = $CA.Replace('"','')
	$CA = $CA.Replace(' ','')

	#To List the Certificate Templates to get the right 1
	#certutil -template | Select-String -Pattern TemplatePropCommonName
	#Detailed Example certutil -template | Select-String -Pattern Cisco6.0WebServer
	
	#Generate CER
	IF(!$CIMCCERGET)
	{
		certreq -submit -attrib $CERTTEMPLATE -Kerberos -config $CERTIFICATESERVER\$CA $CIMCCSR $CIMCCER
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}else {
		Write-Host "Server.Cer already generated at" $CIMCCER -ForegroundColor Green
		Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
	}
	
	#Checking if CER was Generated
	$CIMCCERGETAGAIN = Get-Item "$CIMCCertLocation\$CIMCFQDN.cer" -ErrorAction SilentlyContinue
	
	IF($CIMCCERGETAGAIN)			   
	{
		Write-Host "CIMC CER Found, proceeding with copying cert and combining certificate"
		
		#Read CER File Info
		$CERTPRINT = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$CERTPRINT.Import($CIMCCERGETAGAIN.FullName)
		$ISSUINGCA = $certPrint.IssuerName.Name
		$ISSUINGCATEMP1 = $ISSUINGCA.Split(",")
		$ISSUINGCATEMP2 = $ISSUINGCATEMP1.Split("=")
		$ISSUINGCASEL = $ISSUINGCATEMP2[1]
		Write-Host "Issuing CA for CER is:"$ISSUINGCASEL
		
		#Convert CER to PEM
		IF(!$CIMCPEMGET)
		{
			#Open OpenSSL EXE Location
			CD $OpenSSLLocation
			.\openssl x509 -in $CIMCCER -outform PEM -out $CIMCPEM
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}else {
			Write-Host "Server.pem already generated at" $CIMCPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
		}
		
		
		#Finding Combined CA PEM File that matches issuing CA for CER
		Write-Host "Finding CA PEM File CA:"$ISSUINGCASEL
		$CAFILELIST = Get-ChildItem $CAFILELOCATION | where {$_.extension -eq ".pem" -and $_.name -match $ISSUINGCASEL}
		
		IF($CAFILELIST.count -eq 1)
		{
			#Place your CA Cert to the CIMC folder
			Write-Host "Copying CA PEM File to CIMC Cert folder" -ForegroundColor Green
			Write-Host "Copying $CAFILELIST.FullName to $CACERT"
			Copy-Item $CAFILELIST.FullName $CACERT -ErrorAction SilentlyContinue
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			
			#Create Full Chain CIMC PEM File
			Write-Host "Creating Full Chain CIMC PEM File" -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			#$STEP1 = Get-Content $CIMCKEYPEM
			$STEP1 = Get-Content $CIMCPEM 
			$STEP2 = Get-Content $CACERT 
			$COMBINESTEPS = $STEP1 + $STEP2 #+ $STEP3
			$COMBINESTEPS | Set-Content $CIMCCOMBINEDPEM
			
			#Output name of pem full chain
			CD $OpenSSLLocation
			#openssl x509 -in certificate.crt -text -noout
			Write-Host "Reading Combined PEM file to verify configuration of file:" -ForegroundColor Green
			.\openssl x509 -in $CIMCCOMBINEDPEM -text -noout
			Write-Host "  "
			Write-Host "CIMC Certificate Generation Process Completed" $CIMCCOMBINEDPEM -ForegroundColor Green
			Write-Host (Get-Date -format "MMM-dd-yyyy_HH-mm-ss")
			Write-Host "-----------------------------------------------------------------------------------------------------------------------"
			Write-Host "#######################################################################################################################"
			Write-Host "Directions:"
			Write-Host "
Open CIMC web interface
Login with admin
Browse to the Certificate Upload Area
Upload the CRT File list below
$CIMCCOMBINEDPEM
"
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