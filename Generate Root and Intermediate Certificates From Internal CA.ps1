#Customizable Variables
$Domain = "hamker" #Note: Example Domain hamker.local is represented as hamker. DO NOT Use the FQDN of your domain. If you wish to target only a subdomain, use the subdomain in this variable
$OpenSSLLocation = "C:\Program Files\OpenSSL-Win64\bin" #x64 Version

#Standard Variables
$DATE = Get-date #Todays Date. Used to verify a CA Certicate is still valid
$RootCerts = get-childitem -path Cert:\LocalMachine\Root | Sort Subject | Where {$_.Subject -match $Domain -and $_.NotAfter -gt $DATE}
$InterCerts = get-childitem -path Cert:\LocalMachine\CA | Sort Subject | Where {$_.Subject -match $Domain -and $_.NotAfter -gt $DATE}

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
	New-item -Path C:\certs -Type Directory -ErrorAction SilentlyContinue
	New-item -Path C:\certs\CAs -Type Directory -ErrorAction SilentlyContinue
	New-item -Path C:\certs\CAs\Root -Type Directory -ErrorAction SilentlyContinue
	New-item -Path C:\certs\CAs\Intermediate -Type Directory -ErrorAction SilentlyContinue
	New-item -Path C:\certs\CAs\Combined -Type Directory -ErrorAction SilentlyContinue

	##Save Root Certs to Root Folder
	ForEach($Cert in $RootCerts) 
	{
		$CertPath = “cert:\LocalMachine\Root\”+$Cert.Thumbprint
		$CertDNSName = $cert.DNSNameList.unicode
		$CertFilePath = “c:\certs\CAs\Root\$CertDNSName-DER.cer”
		Export-Certificate -Cert $CertPath -FilePath $CertFilePath -Type CERT
	}
	$Cert=$null
	
	##Save Intermeidate Certs to Intermediate Folder
	ForEach($Cert in $InterCerts) 
	{
		$CertPath = “cert:\LocalMachine\CA\”+$Cert.Thumbprint
		$CertDNSName = $cert.DNSNameList.unicode
		$CertFilePath = “c:\certs\CAs\Intermediate\$CertDNSName-DER.cer”
		Export-Certificate -Cert $CertPath -FilePath $CertFilePath -Type CERT
	}
	$RootCertFolder = “c:\certs\CAs\Root\”
	$RootCertFolderContents = Get-ChildItem -Path $RootCertFolder
	$InterCertFolder = “c:\certs\CAs\Intermediate\”
	$InterCertFolderContents = Get-ChildItem -Path $InterCertFolder
	cd $OpenSSLLocation
	
	##Convert DER Files to PEM Format
	$RootLIST = @()
	ForEach($Cert in $RootCertFolderContents)
	{
		$Temp =""
		$DERFULLNAME = $Cert.FullName
		$PEMFULLNAME = $DERFULLNAME.Replace(“DER”,”PEM”)
		$PEMFULLNAME = $PEMFULLNAME.Replace(“.cer”,”.pem”)
		$Temp = $PEMFULLNAME
		.\openssl.exe x509 -inform DER -in $DERFULLNAME -outform PEM -out $PEMFULLNAME
		$RootLIST += $TEMP
	}
	$InterLIST = @()
	ForEach($Cert in $InterCertFolderContents)
	{
		$Temp =""
		$DERFULLNAME = $Cert.FullName
		$PEMFULLNAME = $DERFULLNAME.Replace(“DER”,”PEM”)
		$PEMFULLNAME = $PEMFULLNAME.Replace(“.cer”,”.pem”)
		$Temp = $PEMFULLNAME
		.\openssl.exe x509 -inform DER -in $DERFULLNAME -outform PEM -out $PEMFULLNAME
		$InterLIST += $Temp
	}
	
	##Make Combined Root/Intermediate Cert PEM File
	ForEach($FILE in $InterList)
	{
		$Answer = Compare-Object -ReferenceObject $(Get-Content $RootList) -DifferenceObject $(Get-Content $InterList)
		If(!$Answer)
		{
			Write-Host 'Only 1 internal CA in the PKI environment'
			$NUM = $File.LastIndexOf('\')
			$NUM = $NUM + 1
			$FILENAME = $FILE.SubString($NUM)
			$FILENAME = $FILENAME.trim(".pem")
			IF($FILENAME.Contains("\"))
			{
				$SUBFILENAME = Split-Path -Path $FILENAME -Leaf
				Copy-item $InterList –Destination “c:\certs\CAs\Combined\CombinedCA_$SUBFILENAME.pem”
			}Else{
				Copy-item $InterList –Destination “c:\certs\CAs\Combined\CombinedCA_$FILENAME.pem”
			}
			Write-Host 'CA File generated for VIC and VCH Usage at:'
			Write-Host "c:\certs\CAs\Combined\CombinedCA_$FILENAME.pem" -ForegroundColor Green
		}
		If($Answer)
		{
			Write-Host 'Certificate Chain has been implemented, Attempting to create Combined CA file(s)'
			$O  = .\openssl x509 -noout -subject -issuer -in $FILE
			$0 = $O[0]
			$0 = $0 -creplace '(?s)^.*= ', ''
			$1 = $O[1]
			$1 = $1 -creplace '(?s)^.*= ', ''
			$Compare = Compare-Object -ReferenceObject $0 -DifferenceObject $1
			IF(!$Compare)
			{
				$FILENAME = $FILE.SubString($NUM)
				$FILENAME = $FILENAME.trim(".pem")
				IF($FILENAME.Contains("\"))
				{
					$SUBFILENAME = Split-Path -Path $FILENAME -Leaf
					Copy-item $InterList –Destination “c:\certs\CAs\Combined\CombinedCA_$SUBFILENAME.pem”
				}Else{
					Copy-item $InterList –Destination “c:\certs\CAs\Combined\CombinedCA_$FILENAME.pem”
				}
				Write-Host 'Only 1 internal CA in the PKI environment'
				Write-Host 'CA File generated for VIC and VCH Usage at:'
				Write-Host "c:\certs\CAs\Combined\CombinedCA_$FILENAME.pem" -ForegroundColor Green
			}
			IF($Compare)
			{
				Write-Host 'Intermediate CA has a Root CA'
				$RootCA = $1.Split(‘.’)[0]
				$RootCertFile = (Get-ChildItem -Path “c:\certs\CAs\Root” | Where {$_.fullname -match $RootCA-and $_.Extension -eq ".pem"} ).FullName
				$RootCertFileContent = Get-Content $RootCertFile
				$InterCertFileContent = Get-Content $File
				Write-Host “Combining Intermediate and Root PEM Files into single joined File”
				$InterCertFileContent  | Out-File -FilePath “c:\certs\CAs\Combined\CombinedCA_$0.pem” -Append
				$RootCertFileContent | Out-File -FilePath “c:\certs\CAs\Combined\CombinedCA_$0.pem” -Append
				Write-Host 'CA File generated for VIC and VCH Usage at:'
				Write-Host "c:\certs\CAs\Combined\CombinedCA_$0.pem" -ForegroundColor Green

			}
			#Copy-item $InterList –Destination “c:\certs\CAs\Combined\CombinedCA.pem”
		}
	}
}
 
