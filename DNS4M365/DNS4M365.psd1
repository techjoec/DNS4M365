@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'DNS4M365.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'DNS4M365 Contributors'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for querying and managing Microsoft 365 domain DNS records. Enumerates domains, retrieves DNS records (MX, CNAME, TXT, SRV, DMARC), and provides comprehensive domain verification status.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0'},
        @{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion = '2.0.0'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'Connect-M365DNS',
        'Get-M365Domain',
        'Get-M365DomainDNSRecord',
        'Get-M365DomainVerificationRecord',
        'Export-M365DomainReport',
        'Test-M365DomainVerification',
        'Get-M365DomainDNSHealth',
        'Compare-M365DomainDNS',
        'Get-M365DomainMigrationStatus'
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
Version 1.1.0 (2025-01-06):
- Enhanced DNS health checks with 2024-2025 Microsoft 365 updates
- Added detection for new mx.microsoft MX record format (July-August 2025 migration)
- Added detection for new dkim.mail.microsoft DKIM format (May 2025+)
- Added critical warnings for mandatory email authentication (SPF/DMARC - April 2025)
- Enhanced deprecated record detection (msoid, legacy Skype for Business)
- Added Get-M365DomainMigrationStatus function for migration readiness assessment
- Updated regional endpoint detection (GCC High, DoD, 21Vianet)
- Added Teams-only vs hybrid Skype for Business detection
- Enhanced comparison function with legacy format warnings

Version 1.0.0 (2025-01-05):
- Initial release - Domain enumeration and DNS record retrieval functionality
'@
        }
    }
}
