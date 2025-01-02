<#
    .NOTES
	===========================================================================
	Created by:		Russell Hamker
	Date:			January 2, 2025
	Version:		4.1
	Twitter:		@butch7903
	GitHub:			https://github.com/butch7903
	===========================================================================

	.SYNOPSIS
		This script automates the generation of certificates from the Certificate Authorities Installed on your Windows PC and then combines the files for a certificate chain for later use.

	.DESCRIPTION
		Use this script to build the certificate structure. Fill in the variables and then simply run this script to
		automate the process of exporting the certificates.

		Updated script for unix format output certificates
#>

#Customizable Variables
$ROOTMATCH = "hamker" #Match the name of the CAs you wish you gather certificates from. You will want to look at this via MMC>Certificates>Computer Account>Root Certificates Authorities
$INTERMEDIATEMATCH = "hamker" #Match the name of the CAs you wish you gather certificates from. You will want to look at this via MMC>Certificates>Computer Account>Intermediate Certificates Authorities
$SSLOUTPUTDIRECTORY = "C:\Certs" #This is the directory where you want the exported certificates to placed
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

#Standard Variables
$DATE = Get-date #Todays Date. Used to verify a CA Certicate is still valid
$RootCerts = get-childitem -path Cert:\LocalMachine\Root | Sort Subject | Where {$_.Subject -match $ROOTMATCH -and $_.NotAfter -gt $DATE}
$InterCerts = get-childitem -path Cert:\LocalMachine\CA | Sort Subject | Where {$_.Subject -match $INTERMEDIATEMATCH -and $_.NotAfter -gt $DATE}

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
	#Make Folders to store Certs in
	New-item -Path $SSLOUTPUTDIRECTORY -Type Directory -ErrorAction SilentlyContinue
	New-item -Path "$SSLOUTPUTDIRECTORY\CAs" -Type Directory -ErrorAction SilentlyContinue
	New-item -Path "$SSLOUTPUTDIRECTORY\CAs\Root" -Type Directory -ErrorAction SilentlyContinue
	New-item -Path "$SSLOUTPUTDIRECTORY\CAs\Intermediate" -Type Directory -ErrorAction SilentlyContinue
	New-item -Path "$SSLOUTPUTDIRECTORY\CAs\Combined" -Type Directory -ErrorAction SilentlyContinue

	##Save Root Certs to Root Folder
	ForEach($Cert in $RootCerts) 
	{
		$CertPath = $null
		$CertPath = "cert:\LocalMachine\Root\"+$Cert.Thumbprint
		$CertDNSName = $cert.DNSNameList.unicode
		$CertFilePath = "$SSLOUTPUTDIRECTORY\CAs\Root\$CertDNSName-DER.cer"
		Export-Certificate -Cert $CertPath -FilePath $CertFilePath -Type CERT
	}
	$Cert=$null
	
	##Save Intermeidate Certs to Intermediate Folder
	ForEach($Cert in $InterCerts) 
	{
		$CertPath = $null
		$CertPath = "cert:\LocalMachine\CA\"+$Cert.Thumbprint
		$CertDNSName = $cert.DNSNameList.unicode
		$CertFilePath = "$SSLOUTPUTDIRECTORY\CAs\Intermediate\$CertDNSName-DER.cer"
		Export-Certificate -Cert $CertPath -FilePath $CertFilePath -Type CERT
	}
	$RootCertFolder = "$SSLOUTPUTDIRECTORY\CAs\Root\"
	$RootCertFolderContents = Get-ChildItem -Path $RootCertFolder
	$InterCertFolder = "$SSLOUTPUTDIRECTORY\CAs\Intermediate\"
	$InterCertFolderContents = Get-ChildItem -Path $InterCertFolder
	cd $OpenSSLLocation
	
	##Convert DER Files to PEM Format
	$RootLIST = @()
	ForEach($Cert in $RootCertFolderContents)
	{
		$Temp =""
		$DERFULLNAME = $Cert.FullName
		$PEMFULLNAME = $DERFULLNAME.Replace('DER','PEM')
		$PEMFULLNAME = $PEMFULLNAME.Replace('.cer','.pem')
		$Temp = $PEMFULLNAME
		.\openssl.exe x509 -inform DER -in $DERFULLNAME -outform PEM -out $PEMFULLNAME
		#convert pem to unix format output file
		[IO.File]::WriteAllText("$PEMFULLNAME", ([IO.File]::ReadAllText("$PEMFULLNAME") -replace "`r`n","`n"))
		$RootLIST += $TEMP
	}
	$InterLIST = @()
	ForEach($Cert in $InterCertFolderContents)
	{
		$Temp =""
		$DERFULLNAME = $Cert.FullName
		$PEMFULLNAME = $DERFULLNAME.Replace('DER','PEM')
		$PEMFULLNAME = $PEMFULLNAME.Replace('.cer','.pem')
		$Temp = $PEMFULLNAME
		.\openssl.exe x509 -inform DER -in $DERFULLNAME -outform PEM -out $PEMFULLNAME
		#convert pem to unix format output file
		[IO.File]::WriteAllText("$PEMFULLNAME", ([IO.File]::ReadAllText("$PEMFULLNAME") -replace "`r`n","`n"))
		$InterLIST += $Temp
	}
	
	##Make Combined Root/Intermediate Cert PEM File
	ForEach($InterCertFile in $InterList)
	{
		$Answer = Compare-Object -ReferenceObject $(Get-Content $RootList) -DifferenceObject $(Get-Content $InterList)
		If(!$Answer)
		{
			Write-Host 'Only 1 internal CA in the PKI environment'
			$NUM = $INTERCERTFILE.LastIndexOf('\')
			$NUM = $NUM + 1
			$INTERCERTFILENAME = $INTERCERTFILE.SubString($NUM)
			$INTERCERTFILENAME = $INTERCERTFILENAME.trim(".pem")
			IF($INTERCERTFILENAME.Contains("\"))
			{
				$SUBFILENAME = Split-Path -Path $INTERCERTFILENAME -Leaf
				Copy-item $InterList -Destination "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$SUBFILENAME.pem"
			}Else{
				Copy-item $InterList -Destination "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem"
			}
			#convert pem to unix format output file
			[IO.File]::WriteAllText("$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem", ([IO.File]::ReadAllText("$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem") -replace "`r`n","`n"))
			Write-Host 'CA File generated for VIC and VCH Usage at:'
			Write-Host "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem" -ForegroundColor Green
		}
		If($Answer)
		{
			Write-Host 'Certificate Chain has been implemented, Attempting to create Combined CA file(s)'
			$O  = .\openssl x509 -noout -subject -issuer -in $INTERCERTFILE
			$0 = $O[0]
			$0 = $0 -creplace '(?s)^.*= ', ''
			$1 = $O[1]
			$1 = $1 -creplace '(?s)^.*= ', ''
			$Compare = Compare-Object -ReferenceObject $0 -DifferenceObject $1
			IF(!$Compare)
			{
				$INTERCERTFILENAME = $INTERCERTFILE.SubString($NUM)
				$INTERCERTFILENAME = $INTERCERTFILENAME.trim(".pem")
				IF($INTERCERTFILENAME.Contains("\"))
				{
					$SUBFILENAME = Split-Path -Path $INTERCERTFILENAME -Leaf
					Copy-item $InterList -Destination "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$SUBFILENAME.pem"
				}Else{
					Copy-item $InterList -Destination "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem"
				}
				#convert pem to unix format output file
				[IO.File]::WriteAllText("$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem", ([IO.File]::ReadAllText("$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem") -replace "`r`n","`n"))
				Write-Host 'Only 1 internal CA in the PKI environment'
				Write-Host 'CA File generated for VIC and VCH Usage at:'
				Write-Host "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$INTERCERTFILENAME.pem" -ForegroundColor Green
			}
			IF($Compare)
			{
				Write-Host 'Intermediate CA has a Root CA'
				$RootCA = $1.Split('.')[0]
				$ROOTCERTFILE = (Get-ChildItem -Path "$SSLOUTPUTDIRECTORY\CAs\Root" | Where {$_.fullname -match $RootCA-and $_.Extension -eq ".pem"} ).FullName
				$STEP1 = Get-Content $INTERCERTFILE
				$STEP2 = Get-Content $ROOTCERTFILE
				Write-Host "Combining Intermediate and Root PEM Files into single joined File"
				$COMBINESTEPS = $STEP1 + $STEP2
				$COMBINEDFILEPATH = "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$0.pem"
				$COMBINESTEPS | Set-Content $COMBINEDFILEPATH
				#convert pem to unix format output file
				[IO.File]::WriteAllText("$COMBINEDFILEPATH", ([IO.File]::ReadAllText("$COMBINEDFILEPATH") -replace "`r`n","`n"))
				Write-Host 'CA File generated for VIC and VCH Usage at:'
				Write-Host "$SSLOUTPUTDIRECTORY\CAs\Combined\CombinedCA_$0.pem" -ForegroundColor Green
			}
		}
	}
}
 
