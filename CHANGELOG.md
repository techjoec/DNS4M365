# Changelog

All notable changes to the DNS4M365 project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive Pester test suite with 15 tests covering module structure, imports, and code quality
- Tab completion support for DNS server parameters (ArgumentCompleter)
  - `Compare-M365DnsRecord -Server <tab>`
  - `Test-M365DnsCompliance -Server <tab>`
  - `Watch-M365DnsPropagation -Resolver <tab>`
  - Suggests common public DNS servers (Google, Cloudflare, Quad9, OpenDNS)

### Fixed
- Syntax error in `Compare-M365DnsRecord` function (variable interpolation with colons)
- Empty catch block in `Compare-M365DnsRecord` now includes explanation
- Automatic variable conflict: renamed `$matches` to `$matchCount`
- Removed unused variables (`$healthColor`, `$valuesMatch`)

### Changed
- Replaced all `Write-Host` calls with `Write-Information` (94 occurrences) for better PowerShell practices
- Replaced Unicode emoji with ASCII equivalents for cross-platform compatibility
  - ⚠️ → [WARNING]
  - ✓ → [OK] or [SUCCESS]
  - ✗ → [FAILED]
  - 🎉 → [SUCCESS]

### Code Quality
- All PSScriptAnalyzer critical warnings resolved
- 0 errors, 0 critical warnings
- All cmdlet verbs comply with PowerShell standards

## [1.1.0] - 2025-01-06

### Added

#### DNS-over-HTTPS Support
- All DNS lookups now use Google Public DNS-over-HTTPS API
- Consistent DNS resolution results independent of local resolver configuration
- More reliable lookups compared to local DNS resolvers
- Private helper function: `Resolve-DnsOverHttps` for internal use
- Supports all record types: MX, CNAME, TXT, SRV, A, AAAA

#### New Function: Get-M365DomainReadiness
- Comprehensive DNS compliance assessment for 2024-2025 Microsoft 365 DNS updates
- Evaluates MX record format (legacy `mail.protection.outlook.com` vs modern `mx.microsoft`)
- Evaluates DKIM format (legacy `onmicrosoft.com` vs new `dkim.mail.microsoft`)
- Assesses email authentication readiness (SPF/DMARC mandatory April 2025)
- Detects deprecated records (msoid, legacy Skype for Business)
- Calculates overall DNS compliance percentage
- Assigns migration priority (CRITICAL/High/Medium/Low)
- Exports comprehensive migration reports to CSV
- Provides actionable recommendations per domain

### Enhanced

#### Get-M365DomainDNSHealth
- **MX Record Detection (2024-2025 Updates)**
  - Detection for new `mx.microsoft` format (July-August 2025 migration, Message Center MC1048624)
  - Identifies legacy `mail.protection.outlook.com` format with migration recommendations
  - Enhanced regional cloud support (GCC High, DoD, 21Vianet China)
  - Format classification in health output (Modern/Legacy/Government Cloud/21Vianet)
- **DKIM Detection (May 2025 New Format)**
  - Detection for new `dkim.mail.microsoft` format
  - Identifies legacy `onmicrosoft.com` format with migration notes
  - Format status for both selector1 and selector2
  - Migration recommendations for legacy configurations
- **Email Authentication Validation (April 2025 Mandates)**
  - **SPF**: Added CRITICAL warnings for missing SPF records
  - **SPF**: Added CRITICAL warnings if SPF doesn't include Microsoft 365
  - **SPF**: Enhanced lookup count validation (RFC 7208 10-lookup limit)
  - **DMARC**: Added CRITICAL warnings for missing DMARC records (mandatory April 2025)
  - **DMARC**: Added subdomain policy detection (sp=)
  - **DMARC**: Added forensic reporting detection (ruf=)
  - **DMARC**: Policy recommendations for upgrading from p=none to p=quarantine/reject
- **Teams/Skype for Business Record Checking**
  - Added note that `_sip._tls` SRV is legacy (Teams-only needs `_sipfederationtls._tcp` only)
  - Added note that `sip` CNAME is legacy (not required for Teams-only tenants)
  - Added note that `lyncdiscover` CNAME is legacy (not required for Teams-only)
  - Updated validation logic to not warn on missing `_sip._tls` for Teams-only

#### Compare-M365DomainDNS
- **MX Comparison**: Added legacy format detection with migration notes
- **CNAME Comparison**:
  - Added legacy DKIM format detection with migration notes
  - Added legacy Skype for Business record warnings (sip, lyncdiscover)
- **DMARC Checking**:
  - Changed IsOptional to false (MANDATORY as of April 2025)
  - Updated status to "CRITICAL - Missing" when DMARC not found
  - Enhanced warning messages for April 2025 mandate
  - Updated expected value to include "MANDATORY April 2025" notice

### Changed
- Module version bumped from 1.0.0 to 1.1.0
- Module manifest (DNS4M365.psd1) updated with:
  - Version 1.1.0
  - Added `Get-M365DomainReadiness` to FunctionsToExport
  - Comprehensive release notes for v1.1.0
- README.md updated with:
  - "What's New in v1.1.0" section highlighting 2024-2025 enhancements
  - Documentation for `Get-M365DomainReadiness` function
  - Example 5: Migration Readiness Assessment
  - Updated roadmap showing completed features
- Function descriptions enhanced with 2024-2025 context

### Technical Implementation Details
- **Scope**: All enhancements focused on custom domain DNS records (e.g., contoso.com)
  - No Microsoft infrastructure hostnames or firewall ports
  - Only records that administrators configure in their own DNS zones
- **2024-2025 Timeline**:
  - MX migration to mx.microsoft: July-August 2025 (Message Center MC1048624)
  - DKIM new format: May 2025+ for new deployments
  - Email authentication mandate: April 2025 (SPF + DMARC with p=quarantine or p=reject)
  - cloud.microsoft domain consolidation: April 2025
  - Teams DNS simplification: 2024 update (only `_sipfederationtls._tcp` needed for Teams-only)
- **Pattern Detection**:
  - MX: `*.mx.microsoft` (modern) vs `*.mail.protection.outlook.com` (legacy)
  - DKIM: `*._domainkey.*.dkim.mail.microsoft` (modern) vs `*._domainkey.*.onmicrosoft.com` (legacy)
  - Regional patterns: `*.office365.us` (GCC/DoD), `*.partner.outlook.cn` (21Vianet)

### Backward Compatibility
- All existing v1.0.0 functionality preserved
- No breaking changes to existing functions
- Enhanced output objects include additional fields (backward compatible)
- All existing scripts continue to work without modification

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
