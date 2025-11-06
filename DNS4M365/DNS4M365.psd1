@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'DNS4M365.psm1'

    # Version number of this module.
    ModuleVersion = '1.2.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'DNS4M365 Contributors'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Simplified PowerShell module for Microsoft 365 DNS validation and monitoring. Validates DNS compliance against Microsoft Graph API, monitors DNS propagation in real-time, and provides comprehensive health checks for M365 custom domains. Supports DNS-over-HTTPS, baseline/diff mode, and multiple output formats.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0'},
        @{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion = '2.0.0'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'Test-M365DnsCompliance',
        'Compare-M365DnsRecord',
        'Watch-M365DnsPropagation',
        'Export-M365DomainReport'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('Microsoft365', 'M365', 'DNS', 'Domains', 'Graph', 'Azure', 'EntraID')
            LicenseUri = 'https://github.com/yourusername/DNS4M365/blob/main/LICENSE'
            ProjectUri = 'https://github.com/yourusername/DNS4M365'
            ReleaseNotes = @'
Version 1.2.0 (2025-01-06) - KISS Architecture Simplification:
BREAKING CHANGES:
- Removed wrapper functions: Use Microsoft.Graph cmdlets directly (Connect-MgGraph, Get-MgDomain, etc.)
- Consolidated 3 validation functions into Test-M365DnsCompliance (Health/Readiness/Verification)
- Renamed Compare-M365DomainDNS → Compare-M365DnsRecord (singular parameter names)
- Simplified DNS queries: Native Resolve-DnsName for standard, Invoke-WebRequest for DoH only

NEW FEATURES:
- Watch-M365DnsPropagation: Real-time DNS propagation monitoring across multiple resolvers
- Baseline/Diff mode: Save DNS snapshots and compare changes over time
- Configurable DNS query methods: Standard DNS or DNS-over-HTTPS per-call
- Enhanced comparison with legacy format detection (MX, DKIM)
- Comprehensive compliance scoring and recommendations

SIMPLIFIED ARCHITECTURE:
- Reduced from 9+ functions to 4 core functions (KISS principle)
- Direct Microsoft.Graph dependency - no unnecessary wrappers
- Use native PowerShell cmdlets where possible (Export-Csv, ConvertTo-Json)
- Parameter-based configuration (no state management)

Version 1.1.0 (2025-01-06):
- DNS-over-HTTPS support using Google Public DNS
- Enhanced health checks and compliance assessment
- MX/DKIM format detection (modern vs legacy)

Version 1.0.0 (2025-01-05):
- Initial release - Domain enumeration and DNS record retrieval
'@
        }
    }
}
