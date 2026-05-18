# DNS Performance Tester

A comprehensive PowerShell script for testing and benchmarking DNS server performance. This tool measures DNS lookup response times across multiple providers and generates detailed performance reports.

## Overview

The **check-dns.ps1** script performs DNS lookups against multiple DNS providers (current system DNS, gateway, and custom providers) and analyzes their performance. It provides real-time testing feedback, comprehensive statistics, and multiple export options for reporting and analysis.

### Key Capabilities
- **Real-time testing** with visual progress indicators
- **Comprehensive statistics** including min, max, median, and success rates
- **Reliability classification** (Excellent/Good/Fair/Poor) based on success rates
- **Multiple export formats** (JSON, CSV, HTML) for reporting and integration
- **Support for both IPv4 and IPv6** DNS testing
- **Custom DNS provider support** via JSON configuration
- **Automatic result ranking** by performance

## Features

✅ **Performance Metrics**
- Average response time per provider
- Minimum and maximum response times
- Median response time calculation
- Success rate tracking (percentage of successful lookups)
- Reliability tier classification

✅ **Visual Output**
- Professional formatted tables with proper alignment
- Color-coded results for quick assessment
- Real-time progress display during testing
- Ranked results with fastest provider highlighted
- Section-based organization for clarity

✅ **Data Export**
- **JSON**: Complete data structure for programmatic use
- **CSV**: Spreadsheet-ready format for analysis
- **HTML**: Styled report with professional formatting and tables
- Timestamped filenames for tracking multiple test runs

✅ **Flexibility**
- Configurable test count per provider
- Support for multiple network adapters
- IPv4 and IPv6 testing options
- Custom DNS provider definitions via JSON
- Adjustable output verbosity

## Requirements

### System Requirements
- **Windows PowerShell 5.0+** or **PowerShell Core 7.0+**
- **Administrator privileges** (required for clearing DNS cache and accessing DNS settings)
- **Network connectivity** to resolve domain names

### Network Requirements
- Active network connection to the specified adapter
- Access to at least one DNS provider
- Outbound connectivity to test domain (default: google.com)

## Installation

1. **Clone or download** the script to your local system:
   ```powershell
   # Example: Save to a scripts directory
   C:\Users\YourUsername\Documents\Scripts\check-dns.ps1
   ```

2. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **(Optional) Create DNS provider config** - See "Custom DNS Providers" section below

## Usage

### Basic Usage

```powershell
# Run with default settings (10 lookups, Wi-Fi adapter, IPv4)
.\check-dns.ps1

# Run with custom lookup count
.\check-dns.ps1 -count 20

# Run with different network adapter
.\check-dns.ps1 -adapter "Ethernet"

# Test IPv6 performance
.\check-dns.ps1 -IPv6
```

### With Export Options

```powershell
# Export results to JSON
.\check-dns.ps1 -count 10 -ExportFormat JSON

# Export results to CSV for spreadsheet analysis
.\check-dns.ps1 -count 10 -ExportFormat CSV

# Export results to HTML report
.\check-dns.ps1 -count 10 -ExportFormat HTML

# Export with custom adapter and count
.\check-dns.ps1 -adapter "Ethernet" -count 15 -ExportFormat HTML
```

### Advanced Usage

```powershell
# Test with custom DNS providers
.\check-dns.ps1 -ProvidersIPv4 ".\providers.json" -count 10 -ExportFormat JSON

# Comprehensive test: multiple lookups, custom adapter, IPv4, and export
.\check-dns.ps1 -count 20 -adapter "Ethernet" -ExportFormat HTML

# IPv6 test with export
.\check-dns.ps1 -IPv6 -count 10 -ExportFormat JSON
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-count` | Int | 10 | Number of DNS lookups to perform per provider |
| `-adapter` | String | "Wi-Fi" | Network adapter name (e.g., "Wi-Fi", "Ethernet", "Local Area Connection") |
| `-domains` | String[] | @("www.google.com") | Domain(s) to test (reserved for future multi-domain support) |
| `-IPv6` | Switch | $false | Enable IPv6 testing instead of IPv4 |
| `-ProvidersIPv4` | String | $null | Path to JSON file with custom DNS providers |
| `-ExportFormat` | String | "None" | Export results: `None`, `JSON`, `CSV`, or `HTML` |
| `-Verbosity` | String | "Detailed" | Output detail level: `Basic` or `Detailed` |

### Parameter Examples

**-count**
```powershell
# Run 5 quick tests
.\check-dns.ps1 -count 5

# Run comprehensive 50-test benchmark
.\check-dns.ps1 -count 50
```

**-adapter**
```powershell
# Use Ethernet instead of Wi-Fi
.\check-dns.ps1 -adapter "Ethernet"

# Find available adapters
Get-NetAdapter | Select-Object Name
```

**-ExportFormat**
```powershell
# Export to JSON for API integration
.\check-dns.ps1 -ExportFormat JSON

# Export to CSV for Excel analysis
.\check-dns.ps1 -ExportFormat CSV

# Export to HTML for email reports
.\check-dns.ps1 -ExportFormat HTML
```

## Custom DNS Providers

### Create a Providers JSON File

Create a JSON file (e.g., `providers.json`) with custom DNS providers:

```json
[
  {
    "Name": "Google Primary",
    "Address": "8.8.8.8"
  },
  {
    "Name": "Google Secondary",
    "Address": "8.8.4.4"
  },
  {
    "Name": "Cloudflare Primary",
    "Address": "1.1.1.1"
  },
  {
    "Name": "Cloudflare Secondary",
    "Address": "1.0.0.1"
  },
  {
    "Name": "OpenDNS Primary",
    "Address": "208.67.222.222"
  }
]
```

### Use Custom Providers

```powershell
# Run tests with custom providers
.\check-dns.ps1 -ProvidersIPv4 ".\providers.json" -count 10

# Export custom provider results
.\check-dns.ps1 -ProvidersIPv4 ".\providers.json" -ExportFormat HTML
```

## Output Interpretation

### Console Output

```
================================================================================
DNS Performance Tester
================================================================================

Adapter: Wi-Fi
Protocol: IPv4
Test Domain: google.com
Lookups per Provider: 10

✓ DNS cache cleared

─ Testing DNS Providers
───────────────────────

  Current P                      127.0.0.1       .......... 
  Default Gateway                192.168.1.102   .......... 

─ Results Summary
─────────────────

Provider                         IP Address         Avg(ms)    Min      Max      Median   Success    Tier
────────────────────────────────────────────────────────────────────────────────────────────────────────────
Current P                        127.0.0.1          92         78       115      84       100%       Excellent    ⭐ FASTEST
Default Gateway                  192.168.1.102      594        588      610      592      100%       Excellent


─ Recommendation
────────────────

  Fastest Provider: Current P (127.0.0.1)
  Average Response: 92 ms
  Reliability: Excellent

  Test Duration: 8.45 seconds
```

### Understanding the Metrics

| Metric | Description |
|--------|-------------|
| **Avg(ms)** | Average response time across all lookups |
| **Min** | Fastest individual lookup response time |
| **Max** | Slowest individual lookup response time |
| **Median** | Middle value when response times are sorted |
| **Success** | Percentage of successful lookups (100% = no timeouts) |
| **Tier** | Reliability classification based on success rate |

### Reliability Tiers

| Tier | Success Rate | Color | Interpretation |
|------|-------------|-------|-----------------|
| Excellent | 100% | 🟢 Green | All lookups successful, reliable provider |
| Good | 95-99% | 🟢 Green | One or two failures acceptable for most use |
| Fair | 80-94% | 🟡 Yellow | Multiple failures, consider alternatives |
| Poor | <80% | 🔴 Red | Frequent failures, not recommended |

### Progress Indicators

During testing:
- **`.`** = Successful lookup
- **`T`** = Timeout (failed lookup)

## Export Formats

### JSON Export
Exports complete test data for integration with other tools:

```json
{
  "Timestamp": "2026-05-18 10:30:45",
  "TestDomain": "google.com",
  "ProviderCount": 2,
  "TestCount": 10,
  "AddressFamily": "IPv4",
  "Results": [
    {
      "Name": "Current P",
      "Address": "127.0.0.1",
      "AverageMs": 92,
      "MinMs": 78,
      "MaxMs": 115,
      "MedianMs": 84,
      "SuccessRate": 1,
      "Tier": "Excellent"
    }
  ]
}
```

**Use Cases:**
- Integration with monitoring systems
- Programmatic analysis and dashboards
- Comparison across multiple test runs
- API endpoints and webhooks

### CSV Export
Exports results in spreadsheet-compatible format:

```
Provider,Address,Average_ms,Min_ms,Max_ms,Median_ms,Success_Rate,Reliability_Tier
Current P,127.0.0.1,92,78,115,84,100%,Excellent
Default Gateway,192.168.1.102,594,588,610,592,100%,Excellent
```

**Use Cases:**
- Analysis in Excel or Google Sheets
- Creating pivot tables and charts
- Comparing historical data
- Sharing with non-technical stakeholders

### HTML Export
Generates a professional styled report:

**Features:**
- Responsive design
- Color-coded reliability tiers
- Professional table formatting
- Highlight for fastest provider (green background)
- Test metadata (timestamp, domain, test count)

**Use Cases:**
- Email reports
- Documentation
- Executive dashboards
- Compliance reporting

## Real-World Examples

### Example 1: Quick Network Health Check
```powershell
# Test current DNS with 5 quick lookups
.\check-dns.ps1 -count 5
```

### Example 2: Comprehensive Benchmark with Export
```powershell
# Detailed 20-test benchmark and generate HTML report
.\check-dns.ps1 -count 20 -ExportFormat HTML
```

### Example 3: Compare Multiple Adapters
```powershell
# Test Wi-Fi
.\check-dns.ps1 -adapter "Wi-Fi" -count 10 -ExportFormat CSV

# Test Ethernet (if available)
.\check-dns.ps1 -adapter "Ethernet" -count 10 -ExportFormat CSV
```

### Example 4: Evaluate Public DNS Providers
```powershell
# Create providers.json with public DNS IPs
# Then run:
.\check-dns.ps1 -ProvidersIPv4 ".\providers.json" -count 20 -ExportFormat HTML
```

### Example 5: IPv6 Testing
```powershell
# Test IPv6 performance
.\check-dns.ps1 -IPv6 -count 10 -ExportFormat JSON
```

### Example 6: Network Troubleshooting
```powershell
# Baseline test on current setup
.\check-dns.ps1 -count 10 -ExportFormat HTML

# After configuration change
.\check-dns.ps1 -count 10 -ExportFormat HTML

# Compare both HTML reports to identify improvements/regressions
```

## Output Files

When using `-ExportFormat`, files are saved to the script directory with timestamps:

- **JSON**: `dns-results_20260518_103045.json`
- **CSV**: `dns-results_20260518_103045.csv`
- **HTML**: `dns-results_20260518_103045.html`

Access recent results:
```powershell
# View most recent HTML report
$latestReport = Get-ChildItem "dns-results_*.html" | Sort-Object -Descending | Select-Object -First 1
Invoke-Item $latestReport.FullName
```

## Troubleshooting

### Issue: "Access Denied" or "Administrator required"
**Solution:** Run PowerShell as Administrator
```powershell
# Open PowerShell as Admin and run:
.\check-dns.ps1
```

### Issue: Script doesn't execute
**Solution:** Check execution policy
```powershell
# View current policy
Get-ExecutionPolicy

# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Adapter not found
**Solution:** List available adapters
```powershell
# Find your adapter name
Get-NetAdapter | Select-Object Name, Status, MacAddress

# Use the exact name from the output
.\check-dns.ps1 -adapter "Your Adapter Name"
```

### Issue: High response times or timeouts
**Possible Causes:**
- Network connectivity issues
- DNS server overload
- Firewall or security software blocking DNS
- Network latency

**Solutions:**
```powershell
# Test with fewer lookups first
.\check-dns.ps1 -count 3

# Try different adapter
.\check-dns.ps1 -adapter "Ethernet"

# Test public DNS providers
.\check-dns.ps1 -ProvidersIPv4 ".\providers.json"

# Check network connectivity
Test-NetConnection -ComputerName 8.8.8.8 -Port 53
```

### Issue: JSON file not found for custom providers
**Solution:** Verify file path and format
```powershell
# Check file exists
Test-Path ".\providers.json"

# Validate JSON format
Get-Content ".\providers.json" | ConvertFrom-Json

# Provide full path if needed
.\check-dns.ps1 -ProvidersIPv4 "C:\path\to\providers.json"
```

### Issue: Export file not created
**Solutions:**
```powershell
# Verify write permissions to script directory
Get-Item $PSScriptRoot | Select-Object FullName

# Check disk space
Get-Volume

# Use full path for export
.\check-dns.ps1 -ExportFormat JSON
# File will be in the same directory as the script
```

## Performance Tips

### For Faster Results
- Use `count 5` for quick health checks
- Test specific adapter with `-adapter "Ethernet"`
- Consider IPv4 testing before IPv6 (more common)

### For Thorough Analysis
- Use `count 20` or higher for reliable statistics
- Test both IPv4 and IPv6
- Run during different times of day
- Export to CSV/JSON for trend analysis

### For Large-Scale Testing
```powershell
# Create a loop to test hourly
for ($i = 1; $i -le 24; $i++) {
    .\check-dns.ps1 -count 10 -ExportFormat JSON
    Start-Sleep -Seconds 3600  # Wait 1 hour
}
```

## Advanced Usage: Automation

### Scheduled Task (Windows Task Scheduler)
```powershell
# Create a PowerShell script that calls check-dns.ps1
# Schedule it to run daily/weekly for continuous monitoring
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\path\to\check-dns.ps1 -ExportFormat JSON"
$trigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "DNS-Performance-Check"
```

### Batch Testing Multiple Adapters
```powershell
$adapters = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Name
foreach ($adapter in $adapters) {
    .\check-dns.ps1 -adapter $adapter -count 10 -ExportFormat HTML
}
```

## FAQ

**Q: Can I test multiple domains?**
A: Currently the script tests a single domain (default: google.com). Multiple domain support is reserved for future versions.

**Q: Does the script modify any DNS settings?**
A: No. The script only reads DNS settings and clears the local DNS cache for accurate testing. It does not change any permanent DNS configurations.

**Q: Can I use this on non-Windows systems?**
A: This script requires Windows PowerShell. For Linux/Mac, use equivalent tools like `dig`, `nslookup`, or `dnspython`.

**Q: What's the maximum `-count` value I should use?**
A: There's no hard limit, but consider that each lookup takes time. For most use cases, 10-20 lookups provide good statistical accuracy without excessive test duration.

**Q: How often should I run DNS tests?**
A: For routine checks, daily or weekly tests are sufficient. For troubleshooting, run tests immediately when issues occur.

**Q: Can I compare results from different test runs?**
A: Yes! Use the `-ExportFormat JSON` or `CSV` options and compare the exported files using Excel or PowerShell scripting.

## Contributing & Support

For issues, feature requests, or contributions:
1. Verify your PowerShell version meets requirements
2. Test with default parameters first
3. Check that the network adapter name is correct
4. Ensure administrator privileges are enabled

## License

This script is provided as-is for diagnostic and performance testing purposes.

---

**Version:** 2.0  
**Last Updated:** May 18, 2026  
**Compatibility:** Windows PowerShell 5.0+ / PowerShell Core 7.0+
