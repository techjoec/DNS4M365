# DNS4M365

A comprehensive PowerShell module for querying and managing Microsoft 365 domain DNS records using Microsoft Graph API.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

DNS4M365 simplifies the process of retrieving, validating, and managing DNS records for Microsoft 365 domains. It provides an easy-to-use PowerShell interface for:

- 🔍 Validating DNS compliance against Microsoft Graph API and Exchange Online
- ✅ Monitoring DNS propagation in real-time across multiple resolvers
- 📋 Retrieving Microsoft-generated DNS records (MX, CNAME, TXT, SRV)
- 🔐 Automatic DKIM validation via Exchange Online PowerShell
- 📊 CSV/JSON-based offline validation (no live API access required)
- 🛡️ DMARC policy generation (New-M365DmarcRecord cmdlet)
- 🔒 MTA-STS validation for email encryption
- 📈 Baseline/diff mode for change detection over time
- 🏥 Comprehensive health checks and compliance scoring

## Features

### Core Capabilities (v1.3.0)

- **DNS Compliance Validation**: Test-M365DnsCompliance validates actual DNS against expected values
- **Automatic DKIM Validation**: Retrieves DKIM selectors from Exchange Online PowerShell
- **CSV/JSON-Based Offline Validation**: Validate DNS without live API access (ideal for testing)
- **DMARC Policy Generation**: New-M365DmarcRecord cmdlet creates compliant DMARC records
- **MTA-STS Support**: Validates MTA-STS TXT records for email encryption enforcement
- **Real-Time DNS Monitoring**: Watch-M365DnsPropagation tracks propagation across resolvers
- **Baseline/Diff Mode**: Save DNS snapshots and detect changes over time
- **DNS-over-HTTPS**: Optional encrypted DNS queries via Google Public DNS
- **Report Generation**: Export data to CSV, JSON, or HTML formats
- **Pipeline Support**: Full PowerShell pipeline compatibility

### Record Types Supported

- **MX Records**: Mail routing for Exchange Online
- **CNAME Records**: Service aliases (Autodiscover, Teams, MDM, etc.)
- **TXT Records**: SPF, DMARC, domain verification
- **SRV Records**: SIP, Federation, and other service records

### Service Types Supported

- Email (Exchange Online)
- Teams (Skype for Business Online)
- SharePoint
- Intune (Mobile Device Management)

## Quick Start

### Installation

**Step 1: Clone or Download**
```powershell
git clone https://github.com/yourusername/DNS4M365.git
cd DNS4M365
```

**Step 2: Install Dependencies (Optional)**

Choose based on your use case:

- **For CSV/JSON offline validation**: No dependencies needed! Skip to Step 3.
- **For Graph API features**: Install Microsoft Graph modules
  ```powershell
  Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
  Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser -Force
  ```
- **For automatic DKIM validation**: Also install Exchange Online module
  ```powershell
  Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
  ```

**Step 3: Import Module**
```powershell
Import-Module .\DNS4M365\DNS4M365.psd1
```

**Step 4: Start Using**
```powershell
# Option A: CSV/JSON offline validation (no authentication)
Test-M365DnsCompliance -CSVPath ".\Templates\expected-dns-records-template.csv"

# Option B: Interactive with Graph API (authentication required)
Connect-MgGraph -Scopes "Domain.Read.All"
Test-M365DnsCompliance -Name "contoso.com"
```

### Prerequisites

#### Required
- **PowerShell 5.1 or higher** (REQUIRED for all features)

#### Optional Dependencies
The following modules are **ONLY** required if you use Graph API or Exchange Online features.
**CSV/JSON-based validation requires NO external dependencies!**

- **OPTIONAL** - For Graph API features:
  - `Microsoft.Graph.Authentication` (v2.0.0+)
  - `Microsoft.Graph.Identity.DirectoryManagement` (v2.0.0+)
- **OPTIONAL** - For automatic DKIM validation:
  - `ExchangeOnlineManagement` (v3.0.0+)

### Installation

#### Option 1: CSV/JSON-Based Offline Validation (No Dependencies Required)

```powershell
# 1. Clone or download this repository
git clone https://github.com/yourusername/DNS4M365.git
cd DNS4M365

# 2. Import the module (no dependencies required!)
Import-Module .\DNS4M365\DNS4M365.psd1

# 3. Use CSV or JSON-based validation immediately
Test-M365DnsCompliance -CSVPath ".\Templates\expected-dns-records-template.csv"
Test-M365DnsCompliance -JSONPath ".\Templates\expected-dns-records-template.json"
```

#### Option 2: Full Installation (Graph API + Exchange Online)

```powershell
# Install Microsoft Graph PowerShell modules
Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Identity.DirectoryManagement -MinimumVersion 2.0.0 -Scope CurrentUser -Force

# Install Exchange Online Management module (optional - for automatic DKIM validation)
Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0 -Scope CurrentUser -Force
```

#### Install DNS4M365 Module

1. **Clone or download this repository**:
   ```powershell
   git clone https://github.com/yourusername/DNS4M365.git
   cd DNS4M365
   ```

2. **Import the module**:
   ```powershell
   Import-Module .\DNS4M365\DNS4M365.psd1
   ```

3. **Or install to your PowerShell modules directory**:
   ```powershell
   # Copy to user modules directory
   $modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\DNS4M365"
   Copy-Item -Path .\DNS4M365 -Destination $modulePath -Recurse -Force

   # Import the module
   Import-Module DNS4M365
   ```

### Permissions and Authentication

#### Required Permissions

DNS4M365 requires different permissions depending on the features you use:

##### Microsoft Graph API Permissions

| Permission | Scope | Required For | Type |
|------------|-------|--------------|------|
| Domain.Read.All | Delegated or Application | Reading domain and DNS configuration | Read-only |
| Domain.ReadWrite.All | Delegated or Application | Writing domain configuration (future) | Read/Write |

##### Azure AD Roles (for Delegated Auth)

Minimum role required: **Global Reader** or **Domain Name Administrator**

- **Global Reader**: Read-only access to all Azure AD and Microsoft 365 settings
- **Domain Name Administrator**: Can manage domain names and DNS configuration
- **Global Administrator**: Full access (not recommended for read-only operations)

##### Exchange Online Permissions (for DKIM Validation)

For automatic DKIM validation via `Test-M365DnsCompliance -UseExchangeOnline`:

| Permission | Role | Required For |
|------------|------|--------------|
| View-Only Configuration | Organization Management (View-Only) | Reading DKIM configuration |
| Get-DkimSigningConfig | Exchange Administrator | Reading DKIM signing configuration |
| Mail Flow Administrator | Mail Flow Administrator | Managing DKIM settings |

#### Authentication Methods

##### Method 1: Interactive Authentication (Recommended for User Accounts)

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Domain.Read.All"

# Connect to Exchange Online (optional - for DKIM validation)
Connect-ExchangeOnline

# Verify connections
Get-MgContext
Get-ConnectionInformation

# Use the module
Test-M365DnsCompliance -Name "contoso.com" -IncludeSPF -IncludeDMARC -CheckDKIM -UseExchangeOnline
```

##### Method 2: CSV/JSON-Based Offline Validation (No Authentication Required)

For scenarios where you don't have or don't want to use live API access:

```powershell
# 1. Create CSV or JSON file with expected DNS records
#    (see Templates/expected-dns-records-template.csv or .json)

# 2. Run validation offline
Test-M365DnsCompliance -CSVPath ".\expected-dns-records.csv"
Test-M365DnsCompliance -JSONPath ".\expected-dns-records.json"

# 3. Compare against CSV/JSON
Compare-M365DnsRecord -CSVPath ".\expected-dns-records.csv"
Compare-M365DnsRecord -JSONPath ".\expected-dns-records.json"
```

**Benefits of Offline Mode:**
- No authentication required
- Supports both CSV and JSON formats
- Ideal for testing and validation scripts
- Works in restricted environments
- Reproducible validation (version-controlled expected values)

### Basic Usage

```powershell
# 1. Connect to Microsoft Graph
Connect-MgGraph -Scopes "Domain.Read.All"

# 2. Validate DNS compliance
Test-M365DnsCompliance -Name "contoso.com" -IncludeSPF -IncludeDMARC -CheckMTASTS

# 3. Generate DMARC record
New-M365DmarcRecord -Domain "contoso.com" -Policy quarantine -AggregateReportEmail "dmarc@contoso.com"

# 4. Watch DNS propagation
Watch-M365DnsPropagation -Name "contoso.com" -RecordType MX -ExpectedValue "contoso-com.mail.protection.outlook.com"
```

## Documentation

### Quick Guide

For detailed information on the three methods of querying Microsoft 365 DNS records (Graph API, GUI, PowerShell), see:

📖 **[Quick Guide - Three Methods](docs/QUICK-GUIDE.md)**

This guide covers:
- Using Microsoft Graph API directly
- Using the Microsoft 365 Admin Center (GUI)
- Using PowerShell (both native cmdlets and this module)

### What's New in v1.3.0 (2025-01-06)

**Exchange Online Integration & Enhanced Features:**

- **NEW:** `New-M365DmarcRecord` - Generate compliant DMARC policies (mandatory April 2025)
- **Exchange Online Integration:** Automatic DKIM validation via Get-DkimSigningConfig
- **CSV-Based Offline Validation:** Validate DNS without live API access (ideal for testing/restricted environments)
- **MTA-STS Support:** Validate MTA-STS TXT records for email encryption enforcement
- **Enhanced Test-M365DnsCompliance:** Added `-UseExchangeOnline`, `-CSVPath`, `-CheckMTASTS` parameters
- **Enhanced Compare-M365DnsRecord:** Added `-CSVPath` parameter for offline comparison
- **CSV Template:** Pre-built template (Templates/expected-dns-records-template.csv) for offline validation
- **Comprehensive Permissions Documentation:** Detailed guide for Graph API and Exchange Online

**Dependencies:**
- Added ExchangeOnlineManagement module (v3.0.0+) for DKIM validation
- Requires Exchange Online admin permissions for automatic DKIM retrieval

**CSV Workflow:**
```powershell
# 1. Get template
Get-Content Templates/expected-dns-records-template.csv

# 2. Fill in your tenant-specific values

# 3. Validate offline (no authentication required)
Test-M365DnsCompliance -CSVPath ".\my-expected-dns.csv"
```

### What's New in v1.2.0 (2025-01-06)

**KISS Architecture Simplification:**
- Consolidated 3 validation functions into `Test-M365DnsCompliance`
- Removed wrapper functions (use native Microsoft.Graph cmdlets directly)
- Added `Watch-M365DnsPropagation` for real-time DNS monitoring
- Baseline/diff mode for change detection
- Enhanced legacy format detection (MX, DKIM)

### Available Commands

#### Connection Management

##### `Connect-M365DNS`
Connects to Microsoft Graph with required permissions.

```powershell
# Basic connection
Connect-M365DNS

# Connect to specific tenant
Connect-M365DNS -TenantId "00000000-0000-0000-0000-000000000000"

# Use device code flow (headless)
Connect-M365DNS -UseDeviceCode

# Request write permissions
Connect-M365DNS -Scopes "Domain.ReadWrite.All"
```

#### Domain Operations

##### `Get-M365Domain`
Retrieves domains from the Microsoft 365 tenant.

```powershell
# Get all domains
Get-M365Domain

# Get only verified domains
Get-M365Domain -VerificationStatus Verified

# Get only unverified domains
Get-M365Domain -VerificationStatus Unverified

# Include detailed properties
Get-M365Domain -IncludeDetails
```

##### `Test-M365DomainVerification`
Tests domain verification status.

```powershell
# Test all domains
Test-M365DomainVerification

# Test specific domain
Test-M365DomainVerification -DomainName "contoso.com"

# Show only unverified domains
Test-M365DomainVerification -ShowOnlyUnverified
```

#### DNS Record Operations

##### `Get-M365DomainDNSRecord`
Retrieves DNS service configuration records.

```powershell
# Get all DNS records for all verified domains
Get-M365DomainDNSRecord

# Get records for specific domain
Get-M365DomainDNSRecord -DomainName "contoso.com"

# Filter by record type
Get-M365DomainDNSRecord -RecordType MX
Get-M365DomainDNSRecord -RecordType CNAME
Get-M365DomainDNSRecord -RecordType TXT
Get-M365DomainDNSRecord -RecordType SRV

# Filter by service type
Get-M365DomainDNSRecord -ServiceType Email
Get-M365DomainDNSRecord -ServiceType OfficeCommunicationsOnline

# Multiple filters
Get-M365DomainDNSRecord -DomainName "contoso.com" -RecordType MX -ServiceType Email

# Include unverified domains
Get-M365DomainDNSRecord -VerifiedOnly $false
```

##### `Get-M365DomainVerificationRecord`
Retrieves domain verification records.

```powershell
# Get verification records for all unverified domains
Get-M365DomainVerificationRecord

# Get verification records for specific domain
Get-M365DomainVerificationRecord -DomainName "contoso.com"

# Include verified domains
Get-M365DomainVerificationRecord -UnverifiedOnly $false
```

#### Reporting Operations

##### `Export-M365DomainReport`
Exports comprehensive domain and DNS record reports.

```powershell
# Export CSV report (default)
Export-M365DomainReport

# Export JSON report
Export-M365DomainReport -Format JSON

# Export HTML report
Export-M365DomainReport -Format HTML

# Export all formats
Export-M365DomainReport -Format All

# Include unverified domains
Export-M365DomainReport -IncludeUnverified

# Custom output path and name
Export-M365DomainReport -OutputPath "C:\Reports" -ReportName "M365-Domains-Monthly" -Format All
```

#### DNS Compliance Assessment (NEW in v1.1.0)

##### `Get-M365DomainReadiness`
Assesses domain readiness for 2024-2025 Microsoft 365 DNS migrations.

```powershell
# Assess all domains
Get-M365DomainReadiness

# Assess specific domain with recommendations
Get-M365DomainReadiness -DomainName "contoso.com" -ShowRecommendations

# Assess all domains and export report
Get-M365DomainReadiness -ExportReport -OutputPath "C:\Reports"

# Get detailed migration recommendations
Get-M365DomainReadiness -ShowRecommendations
```

**What it checks:**
- MX record format (legacy mail.protection.outlook.com vs new mx.microsoft)
- DKIM format (legacy onmicrosoft.com vs new dkim.mail.microsoft)
- Email authentication readiness (SPF/DMARC mandatory April 2025)
- Deprecated records (msoid CNAME - blocks M365 Apps)
- Legacy Teams/Skype for Business records
- Overall DNS compliance percentage
- Migration priority (CRITICAL/High/Medium/Low)

## Examples

### Example 1: Basic Domain Audit

```powershell
# Connect and get all verified domains with their DNS records
Connect-M365DNS
$domains = Get-M365Domain -VerificationStatus Verified
$dnsRecords = Get-M365DomainDNSRecord

# Display summary
Write-Host "Total Domains: $($domains.Count)"
Write-Host "Total DNS Records: $($dnsRecords.Count)"

# Group records by type
$dnsRecords | Group-Object RecordType | Select-Object Name, Count
```

### Example 2: Email DNS Configuration Check

```powershell
# Get all email-related DNS records
$emailRecords = Get-M365DomainDNSRecord -ServiceType Email

# Show MX records
$emailRecords | Where-Object { $_.RecordType -eq 'MX' } |
    Select-Object Domain, MailExchange, Preference |
    Format-Table

# Show SPF records (TXT records with SPF)
$emailRecords | Where-Object { $_.RecordType -eq 'TXT' -and $_.Text -like 'v=spf1*' } |
    Select-Object Domain, Text |
    Format-Table
```

### Example 3: Unverified Domain Report

```powershell
# Get all unverified domains and their verification records
$unverified = Get-M365Domain -VerificationStatus Unverified
$verificationRecords = Get-M365DomainVerificationRecord

# Display verification instructions
foreach ($domain in $unverified) {
    $record = $verificationRecords | Where-Object { $_.Domain -eq $domain.DomainName }

    Write-Host "`nDomain: $($domain.DomainName)" -ForegroundColor Yellow
    Write-Host "Verification Record:" -ForegroundColor Cyan
    Write-Host "  Type: $($record.RecordType)"
    Write-Host "  Host: $($record.Label)"
    Write-Host "  Value: $($record.Text)"
}
```

### Example 4: Export for DNS Provider

```powershell
# Get all DNS records for a specific domain
$domainName = "contoso.com"
$records = Get-M365DomainDNSRecord -DomainName $domainName

# Export to CSV for easy import to DNS provider
$records | Select-Object RecordType, Label,
    @{N='Value'; E={
        switch ($_.RecordType) {
            'MX' { $_.MailExchange }
            'CNAME' { $_.CanonicalName }
            'TXT' { $_.Text }
            'SRV' { $_.NameTarget }
        }
    }},
    @{N='Priority'; E={
        switch ($_.RecordType) {
            'MX' { $_.Preference }
            'SRV' { $_.Priority }
            default { '' }
        }
    }},
    TTL | Export-Csv -Path "$domainName-dns-records.csv" -NoTypeInformation
```

### Example 5: Migration Readiness Assessment (NEW in v1.1.0)

```powershell
# Assess all domains for 2025 DNS migrations
$migrationStatus = Get-M365DomainReadiness -ShowRecommendations

# Filter domains that need critical attention
$criticalDomains = $migrationStatus | Where-Object { $_.MigrationPriority -eq "CRITICAL" }

# Display domains with legacy MX format
$legacyMX = $migrationStatus | Where-Object { $_.MXNeedsMigration -eq $true }
$legacyMX | Select-Object Domain, MXFormat, OverallReadiness | Format-Table

# Display domains missing mandatory email authentication
$noEmailAuth = $migrationStatus | Where-Object { $_.EmailAuthReady -eq $false }
$noEmailAuth | Select-Object Domain, SPFConfigured, DMARCConfigured, EmailAuthStatus | Format-Table

# Export comprehensive migration report
Get-M365DomainReadiness -ExportReport -OutputPath "C:\Reports"
```

### More Examples

See the [Examples](Examples/) folder for:
- `Basic-Usage.ps1`: Comprehensive examples of all basic operations
- `Advanced-Usage.ps1`: Advanced scenarios including auditing, health checks, and automation

## Architecture

### Module Structure

```
DNS4M365/
├── DNS4M365/
│   ├── DNS4M365.psd1           # Module manifest
│   ├── DNS4M365.psm1           # Main module file
│   ├── Public/                 # Exported functions
│   │   ├── Connect-M365DNS.ps1
│   │   ├── Get-M365Domain.ps1
│   │   ├── Get-M365DomainDNSRecord.ps1
│   │   ├── Get-M365DomainVerificationRecord.ps1
│   │   ├── Test-M365DomainVerification.ps1
│   │   └── Export-M365DomainReport.ps1
│   ├── Private/                # Internal functions
│   │   ├── Test-GraphConnection.ps1
│   │   └── Format-DNSRecordOutput.ps1
│   └── Classes/                # Class definitions (reserved)
├── Examples/                   # Usage examples
│   ├── Basic-Usage.ps1
│   └── Advanced-Usage.ps1
├── docs/                       # Documentation
│   └── QUICK-GUIDE.md
├── LICENSE
└── README.md
```

### Design Principles

1. **Modular**: Separate public and private functions for maintainability
2. **Pipeline-Friendly**: Full support for PowerShell pipeline operations
3. **Error Handling**: Comprehensive error handling with informative messages
4. **Verbose Logging**: Detailed logging available via `-Verbose` parameter
5. **Type Safety**: Strong typing and parameter validation
6. **Documentation**: Complete comment-based help for all functions

## Requirements

### Minimum Requirements

- **PowerShell**: Version 5.1 or higher
- **Operating System**: Windows, macOS, or Linux
- **Modules**:
  - Microsoft.Graph.Authentication (v2.0.0+)
  - Microsoft.Graph.Identity.DirectoryManagement (v2.0.0+)

### Permissions

The following Microsoft Graph API permissions are required:

- **Read-Only Operations**: `Domain.Read.All`
- **Read/Write Operations**: `Domain.ReadWrite.All`

### Azure AD Roles

One of the following roles is required:

- Global Administrator
- Global Reader
- Domain Name Administrator

## Troubleshooting

### Common Issues

#### Issue: "Not connected to Microsoft Graph"

**Solution**: Run `Connect-M365DNS` before using other commands.

```powershell
Connect-M365DNS
```

#### Issue: "Insufficient privileges to complete the operation"

**Solution**: Ensure you have the required permissions and roles. Try connecting with explicit scopes:

```powershell
Connect-M365DNS -Scopes "Domain.Read.All"
```

#### Issue: Module not found after installation

**Solution**: Verify the module path and reload:

```powershell
# Check if module is in path
Get-Module -ListAvailable DNS4M365

# If not found, import explicitly
Import-Module "C:\Path\To\DNS4M365\DNS4M365.psd1"
```

#### Issue: No DNS records returned for verified domain

**Solution**: Verify the domain is truly verified and supports services:

```powershell
$domain = Get-MgDomain -DomainId "yourdomain.com"
$domain | Select-Object IsVerified, SupportedServices
```

### Debug Mode

Enable verbose output for detailed troubleshooting:

```powershell
$VerbosePreference = 'Continue'
Get-M365DomainDNSRecord -DomainName "contoso.com" -Verbose
```

## Roadmap

### Completed in v1.1.0 (2025-01-06)

- [x] Add DNS record comparison against actual DNS (`Compare-M365DomainDNS`)
- [x] Add support for DMARC policy retrieval and validation
- [x] Enhanced health checks with 2024-2025 Microsoft 365 updates
- [x] DNS compliance assessment function (`Get-M365DomainReadiness`)
- [x] Detection for new mx.microsoft and dkim.mail.microsoft formats
- [x] Mandatory email authentication warnings (April 2025)
- [x] Deprecated record detection (msoid, legacy Skype for Business)

### Future Enhancements

- [ ] Add DNSSEC/DANE availability checking
- [ ] Add support for custom domain DNS record creation
- [ ] Implement domain verification automation
- [ ] Create interactive dashboard/UI
- [ ] Implement email notification capabilities
- [ ] Add scheduled task templates
- [x] Create Pester tests
- [x] Add CI/CD pipeline

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Microsoft Graph API team for excellent API documentation
- PowerShell community for best practices and patterns
- All contributors and users of this module

## Support

For issues, questions, or suggestions:

- **Issues**: [GitHub Issues](https://github.com/yourusername/DNS4M365/issues)
- **Documentation**: [Quick Guide](docs/QUICK-GUIDE.md)
- **Examples**: [Examples Directory](Examples/)

## Resources

### Official Documentation

- [Microsoft Graph API - Domains](https://learn.microsoft.com/en-us/graph/api/resources/domain)
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Microsoft 365 DNS Records](https://learn.microsoft.com/en-us/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider)

### Related Projects

- [Microsoft Graph PowerShell SDK](https://github.com/microsoftgraph/msgraph-sdk-powershell)
- [Microsoft 365 CLI](https://pnp.github.io/cli-microsoft365/)

---

**Made with ❤️ for Microsoft 365 administrators**
