# DNS4M365 Examples

This directory contains comprehensive examples and usage scenarios for the DNS4M365 PowerShell module.

## Example Files

### Code Examples

#### [Basic-Usage.ps1](Basic-Usage.ps1)
Fundamental examples covering:
- Connecting to Microsoft Graph
- Enumerating domains
- Retrieving DNS records
- Filtering by record type and service
- Testing domain verification
- Generating basic reports

**Recommended for:** New users, getting started

#### [Advanced-Usage.ps1](Advanced-Usage.ps1)
Advanced scenarios including:
- Comprehensive domain audits
- Email security record analysis (SPF, DMARC, DKIM)
- Service-specific DNS extraction
- DNS configuration validation
- Multi-tenant comparison
- Automated health checks
- DNS zone file export
- Scheduled report generation

**Recommended for:** Experienced administrators, automation workflows

### Mock Output Examples

#### [Mock-Reports.md](Mock-Reports.md)
15 realistic report scenarios showing:
- DNS record retrieval outputs
- Health check reports (healthy and issues)
- Comparison reports
- Export formats (CSV, JSON, HTML)
- Multi-domain analysis
- Security compliance reports
- Teams federation readiness
- Deprecated record detection
- Executive summaries

**Recommended for:** Understanding report formats, planning implementations

#### [v1.1.0-Readiness-Examples.md](v1.1.0-Readiness-Examples.md) ⭐ NEW
11 comprehensive DNS compliance assessment examples featuring v1.1.0 enhancements:
- DNS compliance assessment with `Get-M365DomainReadiness`
- Enhanced health checks with 2024-2025 DNS format detection
- Legacy vs modern MX format comparison (mail.protection.outlook.com vs mx.microsoft)
- Legacy vs modern DKIM format comparison (onmicrosoft.com vs dkim.mail.microsoft)
- April 2025 email authentication mandate warnings (SPF/DMARC)
- Deprecated record detection (msoid, legacy Skype for Business)
- Government Cloud configurations (GCC High, DoD)
- Migration priority dashboards
- Filtering and reporting for compliance tracking

**Recommended for:** 2024-2025 compliance tracking, understanding latest features

## Quick Start

### 1. Basic Connection and Retrieval
```powershell
# Connect
Connect-M365DNS

# Get all domains
Get-M365Domain

# Get DNS records for a domain
Get-M365DomainDNSRecord -DomainName "contoso.com"
```

### 2. Health Check (v1.1.0)
```powershell
# Comprehensive health check with 2024-2025 validations
Get-M365DomainDNSHealth -DomainName "contoso.com" `
    -IncludeSPF `
    -IncludeDMARC `
    -CheckDKIMResolution `
    -CheckDeprecated `
    -CheckSRVRecords
```

### 3. Migration Assessment (v1.1.0) ⭐ NEW
```powershell
# Assess migration readiness for 2024-2025 DNS changes
Get-M365DomainReadiness -ShowRecommendations -ExportReport

# Filter critical domains
$status = Get-M365DomainReadiness
$status | Where-Object { $_.MigrationPriority -eq "CRITICAL" }
```

## What's New in v1.1.0

### New Function: Get-M365DomainReadiness
Comprehensive migration readiness assessment for 2024-2025 Microsoft 365 DNS updates:
- MX format detection (legacy vs modern mx.microsoft)
- DKIM format detection (legacy vs modern dkim.mail.microsoft)
- Email authentication readiness (SPF/DMARC mandatory April 2025)
- Deprecated record detection
- Migration priority assignment (CRITICAL/High/Medium/Low)
- Overall readiness percentage

### Enhanced Functions
- **Get-M365DomainDNSHealth**: Added 2024-2025 format detection, April 2025 mandate warnings
- **Compare-M365DomainDNS**: Added legacy format warnings, migration context

See [v1.1.0-Readiness-Examples.md](v1.1.0-Readiness-Examples.md) for detailed examples.

## Migration Timelines (2024-2025)

| Change | Timeline | Priority |
|--------|----------|----------|
| **Email Authentication Mandate** | April 2025 | 🚨 CRITICAL |
| **DKIM New Format** | May 2025+ | New deployments |
| **MX Migration to mx.microsoft** | July-August 2025 | Microsoft Message Center MC1048624 |
| **Teams DNS Simplification** | 2024 (complete) | Teams-only environments |

## Example Scenarios by Use Case

### Security & Compliance
- Email authentication validation (SPF, DMARC, DKIM) - [Advanced-Usage.ps1](Advanced-Usage.ps1)
- Deprecated record detection - [v1.1.0-Readiness-Examples.md](v1.1.0-Readiness-Examples.md)
- Security compliance reports - [Mock-Reports.md](Mock-Reports.md)

### Migration Planning
- DNS compliance assessment - [v1.1.0-Readiness-Examples.md](v1.1.0-Readiness-Examples.md)
- Legacy vs modern format comparison - [v1.1.0-Readiness-Examples.md](v1.1.0-Readiness-Examples.md)
- Priority domain filtering - [v1.1.0-Readiness-Examples.md](v1.1.0-Readiness-Examples.md)

### Auditing & Reporting
- Comprehensive domain audits - [Advanced-Usage.ps1](Advanced-Usage.ps1)
- Multi-format exports (CSV, JSON, HTML) - [Basic-Usage.ps1](Basic-Usage.ps1)
- Executive dashboards - [Mock-Reports.md](Mock-Reports.md)

### Troubleshooting
- DNS health checks - [Advanced-Usage.ps1](Advanced-Usage.ps1)
- Expected vs actual comparison - [Advanced-Usage.ps1](Advanced-Usage.ps1)
- Service-specific validation - [Advanced-Usage.ps1](Advanced-Usage.ps1)

## Related Documentation

- [Main README](../README.md) - Module overview and installation
- [QUICK-GUIDE](../docs/QUICK-GUIDE.md) - Three methods for querying M365 DNS
- [COMPLETE-DNS-RECORDS-REFERENCE](../docs/COMPLETE-DNS-RECORDS-REFERENCE.md) - Exhaustive DNS record reference
- [CHANGELOG](../CHANGELOG.md) - Version history and release notes

## Support

For questions or issues:
- **GitHub Issues**: https://github.com/yourusername/DNS4M365/issues
- **Documentation**: See `/docs` directory
- **Examples**: This directory

## License

MIT License - See [LICENSE](../LICENSE) file
