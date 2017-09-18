<#

Windows Server 2003 Resource Kit Tools - https://www.microsoft.com/en-us/download/details.aspx?id=17657
tsctst.exe - Terminal Server Client License Dump

ID                       : 1
TS Certificate Version   : 0x00050001
HWID                     : 0x00000002, 0x7d4eb2c0, 0x37ffa910, 0x75eb542b, 0x87707af6
Client Platform ID       : 0x000000ff
Company Name             : Microsoft Corporation
Issuer                   : SBTR
Scope                    : CON
Issued to machine        : CL-01
Issued to user           : SYSTEM
TS Locale ID             : 0x00000419
License ID               : A02-5.02-S
License Type             : Windows server 2003 TS temporary or permanent CAL.
Licensed Product Version : 0005.0002, Flag 0x80d48000
Valid from               : 8/7/2017 1:18:50 PM
Expires on               : 11/5/2017 1:18:50 PM

#>

Function Get-TSCtst {
	Param(
		$Path = "HKLM:\SOFTWARE\Microsoft\MSLicensing\Store"
	)
	
	$Certs = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$License = Get-ChildItem $Path | Get-ItemProperty -Name ClientLicense 
	
	$LicenseType = @{
		"A02-5.00-EX" = 'Windows 2000 TS CAL from the "Built-in" pool.' 
		"A02-5.00-S"  = "Windows 2000 TS temporary or permanent CAL." 
		"A02-5.02-S"  = "Windows server 2003 TS temporary or permanent CAL." 
		"A02-6.00-S"  = "Windows server 2008 TS/2008 R2 RDS temporary or permanent CAL." 
	}
	
	if(-not $License) 
	{
		"Can't decode license"
		break
	}
	
	foreach($l in $License) 
	{
		$Certs.Import($l.ClientLicense)
	}
	


	$Certs = $Certs.Where{$_.Subject -match "SERIALNUMBER"}
	$Number = 1
	
	foreach($Cert in $Certs)
	{
		#Info
		[byte[]]$info = $Cert.Extensions | Where {$_.Oid.Value -eq '1.3.6.1.4.1.311.18.5'} | Foreach {$_.RawData}	
		
		#TSVer
		[byte[]]$btsver = $Cert.Extensions | Where {$_.Oid.Value -eq '1.3.6.1.4.1.311.18.4'} | Foreach {$_.RawData}
		[Array]::Reverse($btsver)
		$TSVer = "0x$([BitConverter]::ToString($btsver).replace('-',''))"
		
		#Compnay
		$bcompany = $Cert.Extensions | Where {$_.Oid.Value -eq '1.3.6.1.4.1.311.18.2'} | Foreach {$_.RawData}
		$Company = [Text.Encoding]::Unicode.GetString($bcompany)
		
		#Product
		$CId = "0x$([BitConverter]::ToString($info[5..8]).Replace('-','').ToLower())"
		
		#Issuer,Scope
		$Scope,$Issuer = $Cert.Issuer -split "\s\+\s" | Foreach {$_.split("=")[1]}
		
		#User,Machine Issuer
		$UIssuer,$MIssuer = $Cert.Subject -split "\s\+\s" -match "^(L|CN)" | Foreach {$_.split("=")[1]}
		
		#Locale
		$bid = $info[12..13]
		[Array]::Reverse($bid)
		$TSId = "0x$([BitConverter]::ToString($bid).Replace('-','').PadLeft(8,'0'))"
		
		#License
		[string]$LicStr = [Text.Encoding]::Unicode.GetString($info) -split "\0" -match "A02-"
		
		#License Type
		$LicType = $LicenseType[$LicStr]
		
		#Licensed Product Version
		$LPV = "{0}.{1}, Flag 0x{2}" -f [BitConverter]::ToString($info,58,1).PadLeft(4,'0'),
			[BitConverter]::ToString($info,60,1).PadLeft(4,'0').ToLower(),
			[BitConverter]::ToString($info,63,4).Replace('-','').ToLower()
		
		#HWID
		$RegHWID    = "HKLM:\SOFTWARE\Microsoft\MSLicensing\HardwareID"
		$ClientHWID = (Get-ItemProperty $RegHWID).ClientHWID
		$HexClientHWID = for($i=0;$i -le $ClientHWID.Count -1 ; $i+=4) {
			$temp = $ClientHWID[$i..($i+3)]
			[Array]::Reverse($temp)
			"0x$([BitConverter]::ToString($temp).Replace('-','').ToLower())"
		}
		$HexClientHWID = $HexClientHWID -join ', '
		
		# Display
		[PSCustomObject]@{
			"ID"					   = $Number
			"TS Certificate Version"   = $TSVer
			"HWID" 					   = $HexClientHWID
			"Client Platform ID"       = $CId
			"Company Name"             = $Company
			"Issuer" 				   = $Issuer
			"Scope"  				   = $Scope
			"Issued to machine" 	   = $MIssuer
			"Issued to user" 		   = $UIssuer
			"TS Locale ID" 			   = $TSId
			"License ID" 			   = $LicStr
			"License Type"			   = $LicType
			"Licensed Product Version" = $LPV
			"Valid from" 			   = $Cert.NotBefore
			"Expires on" 			   = $Cert.NotAfter
		}
		
		$Number++
	}
}

