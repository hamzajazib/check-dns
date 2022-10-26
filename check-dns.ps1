Param
(
    [Parameter(Mandatory=$false)]
    [String]$option
)

$defaultGateway = $(Get-NetRoute "0.0.0.0/0").NextHop
$currentDNS = Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4

$testDomain = "www.google.com"

$dnsProviderList = ("Current P",$currentDNS.ServerAddresses[0]),
			("Current A",$currentDNS.ServerAddresses[1]),
			("Default Gateway",$defaultGateway),
			
			("AdGuard DNS P","94.140.14.14"),
			("AdGuard DNS A","94.140.15.15"),
			
			("Cloudflare P","1.1.1.1"),
			("Cloudflare A","1.0.0.1"),
			("Cloudflare B/Malware P","1.1.1.2"),
			("Cloudflare B/Malware A","1.0.0.2"),
			("Cloudflare B/Malware B/Porn P","1.1.1.3"),
			("Cloudflare B/Malware B/Porn A","1.0.0.3"),
			
			("ControlD Unfiltered P","76.76.2.0"),
			("ControlD Unfiltered A","76.76.10.0"),
			("ControlD Malware P","76.76.2.1"),
			("ControlD Malware A","76.76.10.1"),
			("ControlD Ads & Tracking P","76.76.2.2"),
			("ControlD Ads & Tracking A","76.76.10.2"),
			("ControlD Social P","76.76.2.3"),
			("ControlD Social A","76.76.10.3"),
			("ControlD Family Friendly P","76.76.2.4"),
			("ControlD Family Friendly A","76.76.10.4"),
			("ControlD Uncensored P","76.76.2.5"),
			("ControlD Uncensored A","76.76.10.5"),
			
			("Cisco Umbrella P","208.67.222.222"),
			("Cisco Umbrella A","208.67.220.220"),
			
			("Neustar P","64.6.64.6"),
			("Neustar A","64.6.65.6"),
			
			("Google P","8.8.8.8"),
			("Google A","8.8.4.4"),
			
			("Quad9 P","9.9.9.9"),
			("Quad9 A","149.112.112.112"),
			
			("CleanBrowsing Family P","185.228.168.168"),
			("CleanBrowsing Family A","185.228.169.168"),
			("CleanBrowsing Adult P","185.228.168.10"),
			("CleanBrowsing Adult A","185.228.169.11"),
			("CleanBrowsing Security P","185.228.168.9"),
			("CleanBrowsing Security A","185.228.169.9"),
			
			("NuSEC P","8.26.56.26"),
			("NuSEC A","8.20.247.20"),
			
			("DNSWatch P","84.200.69.80"),
			("DNSWatch A","84.200.70.40"),
			
			("OpenNIC P","206.125.173.29"),
			("OpenNIC A","45.32.230.225"),
			
			("UncensoredDNS P","91.239.100.100"),
			("UncensoredDNS A","89.233.43.71"),
			
			("SafeDNS P","195.46.39.39"),
			("SafeDNS A","195.46.39.40"),
			
			("Alternate DNS P","76.76.19.19"),
			("Alternate DNS A","76.223.122.150"),
			
			("Yandex P","77.88.8.8"),
			("Yandex A","77.88.8.1");

Write-Host -ForegroundColor Blue "check-dns"
Write-Host "looking up $($testDomain)`n"

$resultList = New-Object -TypeName 'System.Collections.ArrayList'
for ($i = 0; $i -lt $dnsProviderList.Length; $i += 1)
{
	if (!$dnsProviderList[$i][1]){continue}
	$timeout = $false
	Write-Host $("{0,-30}`t" -f $dnsProviderList[$i][0]) -NoNewline -ForegroundColor Blue
	Write-Host $("{0,-15}`t`t`t" -f $dnsProviderList[$i][1]) -NoNewline -ForegroundColor White
	$responseTimeList = New-Object -TypeName 'System.Collections.ArrayList'
	for ($j = 0; $j -lt 10; $j += 1)
	{
		$t = Measure-Command {$result = nslookup $testDomain $dnsProviderList[$i][1] 2>$null}
		if ($result.Contains("DNS request timed out."))
		{
			Write-Host -ForegroundColor Red "timeout"
			$timeout = $true
			break
		}
		else
		{
			Write-Host $("{0,-3} ms   " -f $t.Milliseconds) -NoNewline
			$responseTimeList.add($t.Milliseconds) >$null
		}
	}
	if (!$timeout)
	{
		$totalResponseTime = 0
		foreach ($responseTime in $responseTimeList){$totalResponseTime += $responseTime}
		$averageResponseTime = [math]::Round($totalResponseTime/10)
		Write-Host "$($averageResponseTime) ms" -ForegroundColor Blue
		$resultList.add(($dnsProviderList[$i][0],$dnsProviderList[$i][1],$averageResponseTime)) >$null
	}
}

if ($resultList)
{
	$fastestDNS = $resultList[0]
	foreach ($result in $resultList){if ($result[2] -lt $fastestDNS[2]){$fastestDNS = $result}}
	Write-Host $("{0,-30}`t" -f $fastestDNS[0]) -NoNewline -ForegroundColor Green
	Write-Host $("{0,-15}`t`t`t" -f $fastestDNS[1]) -NoNewline -ForegroundColor Green
	Write-Host $("{0,93} ms `t[FASTEST]" -f $fastestDNS[2]) -NoNewline -ForegroundColor Green	
}