Param
(
	[Parameter(Mandatory=$false)]
    [int]$count = 10,										#default 10 counts
	
	[Parameter(Mandatory=$false)]
    [String]$adapter = "Wi-Fi",								#default "Wi-Fi", for Ethernet, pass "Ethernet"
	
	[Parameter(Mandatory=$false)]
    [String[]]$domains = @("www.google.com"),  				# default single domain
	
	[Parameter(Mandatory=$false)]
    [Switch]$IPv6,   										# optional switch to enable IPv6 testing
	
	[Parameter(Mandatory=$false)]
    [String]$ProvidersIPv4,    								# Additional IPv4 providers, JSON
	
	[Parameter(Mandatory=$false)]
	[ValidateSet("None", "JSON", "CSV", "HTML")]
	[String]$ExportFormat = "None",							# Export results to file (JSON, CSV, HTML, or None)
	
	[Parameter(Mandatory=$false)]
	[ValidateSet("Basic", "Detailed")]
	[String]$Verbosity = "Detailed"							# Output verbosity level
)


function Get-DnsProvidersFromJSON
{
    param
	(
        [Parameter(Mandatory=$true)]
        [string]$JSON
    )

    if (-Not (Test-Path $JSON))
	{
        Write-Host "JSON file not found: $JSON" -ForegroundColor Red
        return @()
    }

    try
	{
        $jsonProviders = Get-Content $JSON | ConvertFrom-Json
        $providerList = @()
        foreach ($provider in $jsonProviders)
		{
            if ($provider.Address)
			{
                $providerList += [PSCustomObject]@{
                    Name = $provider.Name
                    Address = $provider.Address
                }
            }
        }
        return $providerList
    }
	catch
	{
        Write-Host "Failed to parse JSON file: $JSON" -ForegroundColor Red
        return @()
    }
}

function Write-Header
{
	param([string]$Text, [int]$Width = 80)
	$separator = "=" * $Width
	Write-Host $separator -ForegroundColor Cyan
	Write-Host $Text -ForegroundColor Cyan
	Write-Host $separator -ForegroundColor Cyan
}

function Write-Section
{
	param([string]$Text)
	Write-Host "`n─ $Text" -ForegroundColor Yellow
	Write-Host ("─" * ($Text.Length + 2)) -ForegroundColor Yellow
}

function Write-ProgressSpinner
{
	param([int]$Current, [int]$Total)
	$percent = [math]::Round(($Current / $Total) * 100)
	$filled = [math]::Round($Current / $Total * 20)
	$bar = "█" * $filled + "░" * (20 - $filled)
	Write-Host "`r  [$bar] $percent% " -NoNewline
}

function Get-ReliabilityTier
{
	param([double]$SuccessRate)
	if ($SuccessRate -ge 1.0) { return @{Tier = "Excellent"; Color = "Green"} }
	elseif ($SuccessRate -ge 0.95) { return @{Tier = "Good"; Color = "Green"} }
	elseif ($SuccessRate -ge 0.80) { return @{Tier = "Fair"; Color = "Yellow"} }
	else { return @{Tier = "Poor"; Color = "Red"} }
}

function Export-DnsResultsToJSON
{
	param([array]$Results, [string]$FilePath)
	$jsonData = @{
		Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		TestDomain = $testDomain
		ProviderCount = $Results.Count
		TestCount = $count
		AddressFamily = $addressFamily
		Results = @()
	}
	
	foreach ($result in $Results) {
		$jsonData.Results += @{
			Name = $result.Name
			Address = $result.Address
			AverageMs = $result.Average
			MinMs = $result.Min
			MaxMs = $result.Max
			MedianMs = $result.Median
			SuccessRate = $result.SuccessRate
			Tier = $result.Tier
		}
	}
	
	$jsonData | ConvertTo-Json | Out-File -FilePath $FilePath -Encoding UTF8
	Write-Host "`n✓ Results exported to: $FilePath" -ForegroundColor Green
}

function Export-DnsResultsToCSV
{
	param([array]$Results, [string]$FilePath)
	$csvData = @()
	foreach ($result in $Results) {
		$csvData += [PSCustomObject]@{
			Provider = $result.Name
			Address = $result.Address
			Average_ms = $result.Average
			Min_ms = $result.Min
			Max_ms = $result.Max
			Median_ms = $result.Median
			Success_Rate = "{0:P0}" -f $result.SuccessRate
			Reliability_Tier = $result.Tier
		}
	}
	$csvData | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
	Write-Host "`n✓ Results exported to: $FilePath" -ForegroundColor Green
}

function Export-DnsResultsToHTML
{
	param([array]$Results, [string]$FilePath)
	$html = @"
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>DNS Test Results</title>
	<style>
		body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
		.container { max-width: 1000px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
		h1 { color: #333; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
		.info { background-color: #f0f0f0; padding: 10px; border-radius: 4px; margin: 10px 0; font-size: 14px; }
		table { width: 100%; border-collapse: collapse; margin: 20px 0; }
		th { background-color: #0078d4; color: white; padding: 12px; text-align: left; }
		td { padding: 10px; border-bottom: 1px solid #ddd; }
		tr:hover { background-color: #f9f9f9; }
		.excellent { color: #107c10; font-weight: bold; }
		.good { color: #107c10; font-weight: bold; }
		.fair { color: #ffb900; font-weight: bold; }
		.poor { color: #da3b01; font-weight: bold; }
		.fastest { background-color: #d4edda; }
		.timestamp { color: #666; font-size: 12px; }
	</style>
</head>
<body>
	<div class="container">
		<h1>DNS Performance Test Results</h1>
		<div class="info">
			<strong>Test Time:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")<br>
			<strong>Domain Tested:</strong> $testDomain<br>
			<strong>Lookups Per Provider:</strong> $count<br>
			<strong>Protocol:</strong> $addressFamily
		</div>
		<table>
			<thead>
				<tr>
					<th>Provider</th>
					<th>IP Address</th>
					<th>Average (ms)</th>
					<th>Min (ms)</th>
					<th>Max (ms)</th>
					<th>Median (ms)</th>
					<th>Success Rate</th>
					<th>Reliability</th>
				</tr>
			</thead>
			<tbody>
"@
	
	foreach ($result in $Results) {
		$tierClass = $result.Tier.ToLower()
		$successPercent = "{0:P0}" -f $result.SuccessRate
		$isFastest = if ($result.IsFastest) { 'class="fastest"' } else { '' }
		$html += @"
				<tr $isFastest>
					<td><strong>$($result.Name)</strong></td>
					<td>$($result.Address)</td>
					<td>$($result.Average)</td>
					<td>$($result.Min)</td>
					<td>$($result.Max)</td>
					<td>$($result.Median)</td>
					<td>$successPercent</td>
					<td><span class="$tierClass">$($result.Tier)</span></td>
				</tr>
"@
	}
	
	$html += @"
			</tbody>
		</table>
	</div>
</body>
</html>
"@
	$html | Out-File -FilePath $FilePath -Encoding UTF8
	Write-Host "`n✓ Results exported to: $FilePath" -ForegroundColor Green
}



$testDomain = "google.com"
$addressFamily = if ($IPv6) { "IPv6" } else { "IPv4" }
$scriptStartTime = Get-Date

$dnsProviderList = @()

$currentDNS = Get-DnsClientServerAddress -InterfaceAlias $adapter -AddressFamily $addressFamily
if ($currentDNS.ServerAddresses.Count -ge 1) { $dnsProviderList += [PSCustomObject]@{ Name = "Current P"; Address = $currentDNS.ServerAddresses[0] } }
if ($currentDNS.ServerAddresses.Count -ge 2) { $dnsProviderList += [PSCustomObject]@{ Name = "Current A"; Address = $currentDNS.ServerAddresses[1] } }

$defaultGateway = $(Get-NetRoute "0.0.0.0/0" -AddressFamily $addressFamily).NextHop
if ($defaultGateway) { $dnsProviderList += [PSCustomObject]@{ Name = "Default Gateway"; Address = $defaultGateway } }

if ($ProvidersIPv4)
{
    $dnsProviderList += Get-DnsProvidersFromJSON -JSON $ProvidersIPv4
}

# Display header
Write-Host ""
Write-Header "DNS Performance Tester" 80
Write-Host ""
Write-Host "Adapter: " -NoNewline -ForegroundColor Gray
Write-Host $adapter -ForegroundColor White
Write-Host "Protocol: " -NoNewline -ForegroundColor Gray
Write-Host $addressFamily -ForegroundColor White
Write-Host "Test Domain: " -NoNewline -ForegroundColor Gray
Write-Host $testDomain -ForegroundColor White
Write-Host "Lookups per Provider: " -NoNewline -ForegroundColor Gray
Write-Host $count -ForegroundColor White
Write-Host ""

Clear-DnsClientCache
Write-Host "✓ DNS cache cleared" -ForegroundColor Green

Write-Section "Testing DNS Providers"
Write-Host ""

$resultList = [System.Collections.ArrayList]::new()

for ($i = 0; $i -lt $dnsProviderList.Length; $i++)
{
	if (!$dnsProviderList[$i].Address){continue}
	
	$timeout = $false
	Write-Host "  $("{0,-30}" -f $dnsProviderList[$i].Name) " -NoNewline -ForegroundColor Blue
	Write-Host "$("{0,-15}" -f $dnsProviderList[$i].Address) " -NoNewline -ForegroundColor White
	
	$responseTimeList = [System.Collections.ArrayList]::new()
	$testIndex = 0
	
	for ($j = 0; $j -lt $count; $j++)
	{
		$t = Measure-Command { $result = nslookup $testDomain $dnsProviderList[$i].Address 2>$null }
		$testIndex++
		
		if ( (!$result) -OR ($result.Contains("DNS request timed out.")) )
		{
			Write-Host "T" -NoNewline -ForegroundColor Red
			$timeout = $true
			# Continue testing even after timeout to get accurate success rate
		}
		else
		{
			Write-Host "." -NoNewline -ForegroundColor Green
			$responseTimeList.add($t.Milliseconds) >$null
		}
		
		# Show progress
		if (($j + 1) % 5 -eq 0) {
			Write-Host " " -NoNewline
		}
	}
	
	Write-Host ""
	
	if ($responseTimeList.Count -gt 0)
	{
		$avgTime = [math]::Round(($responseTimeList | Measure-Object -Average).Average)
		$minTime = ($responseTimeList | Measure-Object -Minimum).Minimum
		$maxTime = ($responseTimeList | Measure-Object -Maximum).Maximum
		$median = @($responseTimeList | Sort-Object)[($responseTimeList.Count - 1) / 2]
		$successRate = $responseTimeList.Count / $count
		$reliabilityInfo = Get-ReliabilityTier -SuccessRate $successRate
		
		$resultList.add([PSCustomObject]@{
			Name = $dnsProviderList[$i].Name
			Address = $dnsProviderList[$i].Address
			Average = $avgTime
			Min = $minTime
			Max = $maxTime
			Median = $median
			SuccessRate = $successRate
			Tier = $reliabilityInfo.Tier
			TierColor = $reliabilityInfo.Color
			ResponseTimes = $responseTimeList
		}) >$null
	}
	else
	{
		Write-Host "  ✗ All requests timed out" -ForegroundColor Red
	}
}

if ($resultList.Count -gt 0)
{
	# Sort by average response time
	$resultList = $resultList | Sort-Object -Property Average
	
	# Mark the fastest
	$resultList[0] | Add-Member -NotePropertyName IsFastest -NotePropertyValue $true
	
	# Display results table
	Write-Section "Results Summary"
	Write-Host ""
	$header = "{0,-32} {1,-18} {2,-10} {3,-8} {4,-8} {5,-8} {6,-10} {7,-12}" -f "Provider", "IP Address", "Avg(ms)", "Min", "Max", "Median", "Success", "Tier"
	Write-Host $header -ForegroundColor White
	Write-Host ("-" * 120) -ForegroundColor Gray
	
	foreach ($result in $resultList)
	{
		$successPercent = "{0:P0}" -f $result.SuccessRate
		$isFastest = if ($result.IsFastest) { " ⭐ FASTEST" } else { "" }
		$tierColor = $result.TierColor
		
		$row = "{0,-32} {1,-18} {2,-10} {3,-8} {4,-8} {5,-8} {6,-10} {7,-12}" -f $result.Name, $result.Address, $result.Average, $result.Min, $result.Max, $result.Median, $successPercent, $result.Tier
		Write-Host $row -NoNewline
		Write-Host $isFastest -ForegroundColor Green
	}
	
	Write-Host ""
	Write-Section "Recommendation"
	$fastest = $resultList[0]
	Write-Host ""
	Write-Host "  Fastest Provider: " -NoNewline -ForegroundColor Gray
	Write-Host "$($fastest.Name)" -ForegroundColor Green -NoNewline
	Write-Host " ($($fastest.Address))" -ForegroundColor White
	Write-Host "  Average Response: " -NoNewline -ForegroundColor Gray
	Write-Host "$($fastest.Average) ms" -ForegroundColor Green
	Write-Host "  Reliability: " -NoNewline -ForegroundColor Gray
	Write-Host "$($fastest.Tier)" -ForegroundColor $fastest.TierColor
	
	$scriptEndTime = Get-Date
	$testDuration = $scriptEndTime - $scriptStartTime
	Write-Host ""
	Write-Host "  Test Duration: $([math]::Round($testDuration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
	Write-Host ""
	
	# Export results if requested
	if ($ExportFormat -ne "None")
	{
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
		
		switch ($ExportFormat)
		{
			"JSON" {
				$filePath = Join-Path $scriptDir "dns-results_$timestamp.json"
				Export-DnsResultsToJSON -Results $resultList -FilePath $filePath
			}
			"CSV" {
				$filePath = Join-Path $scriptDir "dns-results_$timestamp.csv"
				Export-DnsResultsToCSV -Results $resultList -FilePath $filePath
			}
			"HTML" {
				$filePath = Join-Path $scriptDir "dns-results_$timestamp.html"
				Export-DnsResultsToHTML -Results $resultList -FilePath $filePath
			}
		}
	}
}
else
{
	Write-Host "`n✗ No valid DNS providers tested successfully" -ForegroundColor Red
}

Write-Host ""
