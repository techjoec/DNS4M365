# Changelog

All notable changes to the DNS4M365 project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-06

### Added

#### Core Module
- Initial release of DNS4M365 PowerShell module
- Module manifest (DNS4M365.psd1) with proper metadata and dependencies
- Main module file (DNS4M365.psm1) with automatic function loading

#### Public Functions
- `Connect-M365DNS` - Connect to Microsoft Graph with required permissions
  - Support for tenant-specific connections
  - Device code flow authentication option
  - Custom scope support
- `Get-M365Domain` - Enumerate all domains in Microsoft 365 tenant
  - Filter by verification status (All/Verified/Unverified)
  - Optional detailed domain information
  - Summary statistics display
- `Get-M365DomainDNSRecord` - Retrieve DNS service configuration records
  - Support for all record types (MX, CNAME, TXT, SRV)
  - Filter by record type
  - Filter by service type (Email, Teams, SharePoint, Intune)
  - Verified-only filtering option
  - Pipeline support
- `Get-M365DomainVerificationRecord` - Get domain verification records
  - Automatic filtering for unverified domains
  - Support for TXT and MX verification records
- `Test-M365DomainVerification` - Test domain verification status
  - Comprehensive verification status check
  - Optional unverified-only display
  - Verification record inclusion for unverified domains
- `Export-M365DomainReport` - Generate comprehensive reports
  - Multiple format support (CSV, JSON, HTML)
  - Option to include unverified domains
  - Customizable output path and report name
  - Detailed statistics and summaries

#### Private Functions
- `Test-GraphConnection` - Internal connection validation
- `Format-DNSRecordOutput` - Consistent DNS record formatting

#### Documentation
- Comprehensive README.md with:
  - Quick start guide
  - Detailed command documentation
  - Multiple usage examples
  - Architecture overview
  - Troubleshooting guide
- QUICK-GUIDE.md covering three query methods:
  - Microsoft Graph API (REST)
  - Microsoft 365 Admin Center (GUI)
  - PowerShell (native cmdlets and DNS4M365 module)
- DNS record types explained
- Permission requirements
- Best practices

#### Examples
- Basic-Usage.ps1 - Comprehensive basic examples including:
  - Connection methods
  - Domain enumeration
  - DNS record retrieval
  - Filtering and reporting
- Advanced-Usage.ps1 - Advanced scenarios including:
  - Comprehensive domain audits
  - Email security record analysis (SPF, DMARC)
  - Service-specific DNS extraction
  - DNS configuration validation
  - Multi-tenant comparison
  - Automated health checks
  - DNS zone file export
  - Scheduled report generation

#### Project Structure
- Modular directory structure:
  - `/DNS4M365` - Main module directory
  - `/DNS4M365/Public` - Exported functions
  - `/DNS4M365/Private` - Internal helper functions
  - `/DNS4M365/Classes` - Reserved for future class definitions
  - `/Examples` - Usage examples
  - `/docs` - Documentation
- .gitignore for common exclusions
- LICENSE file (MIT)
- CHANGELOG.md for version tracking

### Features

- **Full Pipeline Support**: All functions support PowerShell pipeline operations
- **Comprehensive Error Handling**: Informative error messages and graceful degradation
- **Verbose Logging**: Detailed logging via `-Verbose` parameter for troubleshooting
- **Type Safety**: Strong parameter typing and validation
- **Comment-Based Help**: Complete Get-Help support for all functions
- **Color-Coded Output**: User-friendly console output with color coding
- **Summary Statistics**: Automatic summary generation for operations
- **Export Capabilities**: Multiple export formats for reporting

### Dependencies

- Microsoft.Graph.Authentication (v2.0.0+)
- Microsoft.Graph.Identity.DirectoryManagement (v2.0.0+)
- PowerShell 5.1 or higher

### Requirements

- Microsoft Graph API permissions: `Domain.Read.All` (minimum)
- Azure AD/Entra ID role: Domain Name Administrator or Global Reader (minimum)

### Known Limitations

- Read-only operations (write operations planned for future release)
- DMARC records require separate DNS queries (not provided by Graph API)
- Custom DNS records not included (only Microsoft-generated records)

## [Unreleased]

### Planned Features

- Domain verification automation
- DNS record creation and management (write operations)
- DMARC policy retrieval and validation
- Real-time DNS record comparison against actual DNS
- Interactive dashboard/UI
- Email notification system
- Scheduled task templates
- Pester unit tests
- CI/CD pipeline integration
- PowerShell Gallery publishing
- Multi-language support

---

## Version History

- **1.0.0** (2025-11-06) - Initial release

---

## Migration Notes

### From Direct Graph API Usage

If you were previously using Microsoft Graph API directly:

```powershell
# Old method
$domains = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/domains"
$records = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/domains/contoso.com/serviceConfigurationRecords"

# New method with DNS4M365
Connect-M365DNS
$domains = Get-M365Domain
$records = Get-M365DomainDNSRecord -DomainName "contoso.com"
```

### From MSOnline Module (Deprecated)

If you were using the legacy MSOnline module:

```powershell
# Old method (MSOnline - deprecated)
Connect-MsolService
$domains = Get-MsolDomain
$verificationRecord = Get-MsolDomainVerificationDns -DomainName "contoso.com"

# New method with DNS4M365
Connect-M365DNS
$domains = Get-M365Domain
$verificationRecord = Get-M365DomainVerificationRecord -DomainName "contoso.com"
```

## Support

For questions, issues, or feature requests:
- GitHub Issues: https://github.com/yourusername/DNS4M365/issues
- Documentation: See docs/ directory
- Examples: See Examples/ directory
