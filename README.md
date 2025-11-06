# DNS4M365

A comprehensive PowerShell module for querying and managing Microsoft 365 domain DNS records using Microsoft Graph API.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

DNS4M365 simplifies the process of retrieving and managing DNS records for Microsoft 365 domains. It provides an easy-to-use PowerShell interface for:

- 🔍 Enumerating all domains in a Microsoft 365 tenant
- ✅ Splitting domains by verification status (Verified/Unverified)
- 📋 Retrieving Microsoft-generated DNS records (MX, CNAME, TXT, SRV)
- 🔐 Getting domain verification records
- 📊 Exporting comprehensive reports (CSV, JSON, HTML)
- 🏥 Testing domain health and configuration

## Features

### Core Capabilities

- **Domain Enumeration**: List all domains with verification status, supported services, and authentication type
- **DNS Record Retrieval**: Get all Microsoft-generated DNS records for verified domains
- **Verification Management**: Retrieve verification records for unverified domains
- **Flexible Filtering**: Filter by domain, record type (MX, CNAME, TXT, SRV), or service type (Email, Teams, SharePoint)
- **Health Checks**: Test domain verification status and configuration
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

### Prerequisites

- PowerShell 5.1 or higher
- Microsoft Graph PowerShell SDK modules:
  - `Microsoft.Graph.Authentication`
  - `Microsoft.Graph.Identity.DirectoryManagement`

### Installation

#### Install Prerequisites

```powershell
# Install Microsoft Graph PowerShell modules
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser -Force
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

### Basic Usage

```powershell
# 1. Connect to Microsoft 365
Connect-M365DNS

# 2. List all domains
Get-M365Domain

# 3. Get DNS records for all verified domains
Get-M365DomainDNSRecord

# 4. Export a comprehensive report
Export-M365DomainReport -Format HTML
```

## Documentation

### Quick Guide

For detailed information on the three methods of querying Microsoft 365 DNS records (Graph API, GUI, PowerShell), see:

📖 **[Quick Guide - Three Methods](docs/QUICK-GUIDE.md)**

This guide covers:
- Using Microsoft Graph API directly
- Using the Microsoft 365 Admin Center (GUI)
- Using PowerShell (both native cmdlets and this module)

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

### Future Enhancements

- [ ] Add support for custom domain DNS record creation
- [ ] Implement domain verification automation
- [ ] Add DNS record comparison against actual DNS
- [ ] Create interactive dashboard/UI
- [ ] Add support for DMARC policy retrieval
- [ ] Implement email notification capabilities
- [ ] Add scheduled task templates
- [ ] Create Pester tests
- [ ] Add CI/CD pipeline

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
