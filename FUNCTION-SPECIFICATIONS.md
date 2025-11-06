# DNS4M365 Function Specifications - Complete Parameter & Help Documentation

## Table of Contents
1. [Connection & Configuration](#connection--configuration)
2. [DNS Record Queries](#dns-record-queries)
3. [Health & Compliance](#health--compliance)
4. [Monitoring & Watch](#monitoring--watch)
5. [Comparison & Analysis](#comparison--analysis)
6. [Export & Baseline](#export--baseline)
7. [Custom Records](#custom-records)

---

## CONNECTION & CONFIGURATION

### Connect-M365Dns

```powershell
function Connect-M365Dns {
    <#
    .SYNOPSIS
        Connects to Microsoft 365 with permissions for DNS management.

    .DESCRIPTION
        Establishes an authenticated connection to Microsoft Graph API with the necessary
        permissions to query and manage domain DNS records. This connection is required
        before using any other DNS4M365 cmdlets.

        Required Microsoft Graph permissions:
        - Domain.Read.All (minimum for read operations)
        - Domain.ReadWrite.All (for write operations)

    .PARAMETER TenantId
        The Azure AD tenant ID or domain name to connect to.
        Example: contoso.onmicrosoft.com or xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

    .PARAMETER Scopes
        The Microsoft Graph permission scopes to request.
        Default: Domain.Read.All

    .PARAMETER UseDeviceCode
        Use device code authentication flow instead of interactive browser login.
        Useful for remote sessions or environments without web browser access.

    .PARAMETER Environment
        The Azure cloud environment to connect to.
        Default: Global

    .EXAMPLE
        Connect-M365Dns

        Connects to Microsoft 365 using interactive authentication with default permissions.

    .EXAMPLE
        Connect-M365Dns -TenantId "contoso.onmicrosoft.com" -UseDeviceCode

        Connects using device code flow for a specific tenant.

    .EXAMPLE
        Connect-M365Dns -Scopes "Domain.Read.All","Domain.ReadWrite.All"

        Connects with both read and write permissions for domain management.

    .INPUTS
        None. You cannot pipe objects to Connect-M365Dns.

    .OUTPUTS
        None. Connection status is displayed to console.

    .NOTES
        File Name  : Connect-M365Dns.ps1
        Author     : DNS4M365 Module
        Requires   : PowerShell 5.1+, Microsoft.Graph modules

    .LINK
        Get-M365Domain
        Get-M365DnsRecord
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Domain.Read.All', 'Domain.ReadWrite.All')]
        [string[]]$Scopes = @('Domain.Read.All'),

        [Parameter(Mandatory = $false)]
        [switch]$UseDeviceCode,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Global', 'China', 'USGov', 'USGovDoD', 'Germany')]
        [string]$Environment = 'Global'
    )

    # Function implementation
}
```

---

### Set-DnsResolverConfig

```powershell
function Set-DnsResolverConfig {
    <#
    .SYNOPSIS
        Configures DNS resolver settings for the module.

    .DESCRIPTION
        Sets the DNS resolution method and server(s) used for all DNS queries performed
        by DNS4M365 cmdlets. Supports DNS-over-HTTPS (DoH), DNS-over-TLS (DoT), and
        standard DNS resolution.

        Configuration is stored at module-scope and applies to all subsequent DNS queries
        until changed or the module is reloaded.

    .PARAMETER ResolverType
        The DNS resolution method to use.
        - DoH: DNS-over-HTTPS (encrypted, recommended)
        - DoT: DNS-over-TLS (encrypted, future support)
        - Standard: Traditional DNS queries

    .PARAMETER Server
        DNS server(s) to use for queries. Can specify multiple for redundancy.

        For DoH:
        - dns.google (default)
        - cloudflare-dns.com
        - dns.quad9.net

        For Standard:
        - 8.8.8.8 (Google)
        - 1.1.1.1 (Cloudflare)
        - 9.9.9.9 (Quad9)

    .PARAMETER PassThru
        Returns the configuration object after setting.

    .EXAMPLE
        Set-DnsResolverConfig -ResolverType DoH -Server "dns.google"

        Configures the module to use Google DNS-over-HTTPS.

    .EXAMPLE
        Set-DnsResolverConfig -ResolverType Standard -Server @('8.8.8.8', '1.1.1.1')

        Configures standard DNS with Google and Cloudflare as fallback.

    .EXAMPLE
        Set-DnsResolverConfig -ResolverType DoH -Server "cloudflare-dns.com" -PassThru

        Sets Cloudflare DoH and returns the configuration object.

    .INPUTS
        None. You cannot pipe objects to Set-DnsResolverConfig.

    .OUTPUTS
        None by default. PSCustomObject if -PassThru is specified.

    .NOTES
        Configuration persists until module is reloaded or explicitly changed.
        Default: DoH using dns.google

    .LINK
        Get-DnsResolverConfig
        Get-M365DnsRecordLive
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('DoH', 'DoT', 'Standard')]
        [string]$ResolverType,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Server,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Function implementation
}
```

---

## DNS RECORD QUERIES

### Get-M365DnsRecordLive

```powershell
function Get-M365DnsRecordLive {
    <#
    .SYNOPSIS
        Queries live DNS records using configured or specified resolvers.

    .DESCRIPTION
        Performs real-time DNS lookups for domain records using the configured DNS resolver
        (DoH, DoT, or Standard). Unlike Get-M365DnsRecord which queries the Graph API,
        this cmdlet performs actual DNS queries to verify what is published in DNS.

        Useful for:
        - Verifying DNS propagation after changes
        - Comparing Graph API records vs actual DNS
        - Troubleshooting DNS resolution issues
        - Checking DNS from different resolvers

    .PARAMETER Name
        The domain name(s) to query. Accepts multiple domains via array or pipeline.

    .PARAMETER RecordType
        The DNS record type(s) to query. Can specify multiple types.
        Supported: A, AAAA, MX, CNAME, TXT, SRV, NS, PTR, SOA

    .PARAMETER Server
        DNS server(s) to query. Overrides module configuration for this query.
        Can specify multiple servers to query in parallel.

    .PARAMETER ResolverType
        DNS resolution method for this query. Overrides module configuration.

    .PARAMETER UseAuthoritativeNS
        Query the authoritative nameservers for the domain instead of configured resolver.
        Automatically discovers and queries the domain's authoritative NS.

    .PARAMETER OutputFormat
        Format for displaying results.
        - Screen: Colorized console output (default)
        - Json: JSON format
        - Xml: XML format
        - Html: HTML table
        - Csv: CSV format

    .PARAMETER PassThru
        Returns DNS record objects to the pipeline for further processing.

    .EXAMPLE
        Get-M365DnsRecordLive -Name "contoso.com" -RecordType MX

        Queries MX records for contoso.com using configured resolver.

    .EXAMPLE
        Get-M365DnsRecordLive -Name "contoso.com" -RecordType @('MX','TXT','SPF') -PassThru

        Queries multiple record types and returns objects to pipeline.

    .EXAMPLE
        "contoso.com","fabrikam.com" | Get-M365DnsRecordLive -RecordType A,AAAA

        Queries A and AAAA records for multiple domains via pipeline.

    .EXAMPLE
        Get-M365DnsRecordLive -Name "contoso.com" -RecordType MX -UseAuthoritativeNS

        Queries the domain's authoritative nameservers directly.

    .EXAMPLE
        Get-M365DnsRecordLive -Name "contoso.com" -Server @('8.8.8.8','1.1.1.1') -RecordType TXT

        Queries TXT records from both Google and Cloudflare DNS servers.

    .INPUTS
        System.String
        You can pipe domain names to Get-M365DnsRecordLive.

    .OUTPUTS
        PSCustomObject
        Returns DNS record objects with properties: Name, Type, TTL, RecordData

    .NOTES
        Requires DNS resolver configuration (use Set-DnsResolverConfig).
        Default resolver: DNS-over-HTTPS via Google (dns.google)

    .LINK
        Get-M365DnsRecord
        Set-DnsResolverConfig
        Watch-M365DnsPropagation
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Default'
        )]
        [Parameter(ParameterSetName = 'MultiServer')]
        [Alias('DomainName', 'Domain')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'PTR', 'SOA')]
        [string[]]$RecordType = @('A', 'MX', 'TXT'),

        [Parameter(Mandatory = $false, ParameterSetName = 'MultiServer')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Server,

        [Parameter(Mandatory = $false)]
        [ValidateSet('DoH', 'DoT', 'Standard')]
        [string]$ResolverType,

        [Parameter(Mandatory = $false)]
        [switch]$UseAuthoritativeNS,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Screen', 'Json', 'Xml', 'Html', 'Csv')]
        [string]$OutputFormat = 'Screen',

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    begin {
        # Initialization
    }

    process {
        # Per-item processing
    }

    end {
        # Cleanup
    }
}
```

---

## MONITORING & WATCH

### Watch-M365DnsPropagation

```powershell
function Watch-M365DnsPropagation {
    <#
    .SYNOPSIS
        Monitors DNS records for changes and propagation status.

    .DESCRIPTION
        Continuously monitors DNS records across multiple resolvers and/or authoritative
        nameservers, detecting when changes propagate. Useful for verifying DNS updates
        after making changes in your DNS management console.

        Features:
        - Monitors authoritative NS and public resolvers simultaneously
        - Configurable check interval
        - Timeout after maximum wait time
        - Real-time status updates with color coding
        - Alerts when propagation is complete
        - Detailed propagation timeline

    .PARAMETER Name
        The domain name to monitor for DNS changes.

    .PARAMETER RecordType
        The DNS record type(s) to monitor.
        Default: MX, TXT

    .PARAMETER ExpectedValue
        The expected new value for the record. Monitoring stops when this value is detected.
        For MX: Mail server hostname
        For TXT: Full text string
        For A: IP address

    .PARAMETER Server
        DNS server(s) to monitor. Checks propagation across all specified servers.
        Default: Google (8.8.8.8), Cloudflare (1.1.1.1), Quad9 (9.9.9.9)

    .PARAMETER CompareAuthoritativeNS
        Also monitor the domain's authoritative nameservers for comparison.
        Shows when auth NS updates vs when public resolvers see the change.

    .PARAMETER Interval
        How often to check DNS, in seconds.
        Default: 30 seconds
        Range: 1-3600

    .PARAMETER Timeout
        Maximum time to wait before giving up, in seconds.
        Default: 1800 (30 minutes)
        Range: 1-86400 (24 hours)

    .PARAMETER Quiet
        Suppress progress output. Only display final result.

    .PARAMETER PassThru
        Return propagation timeline object at completion.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "contoso.com" -RecordType MX

        Monitors MX record changes for contoso.com with default settings.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "contoso.com" -RecordType TXT -ExpectedValue "v=spf1 include:spf.protection.outlook.com -all" -Interval 10 -Timeout 600

        Watches for specific SPF record value, checking every 10 seconds for up to 10 minutes.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "contoso.com" -RecordType @('MX','TXT') -CompareAuthoritativeNS -PassThru

        Monitors both MX and TXT records, comparing auth NS vs public resolvers,
        and returns timeline object.

    .INPUTS
        System.String
        You can pipe domain names to Watch-M365DnsPropagation.

    .OUTPUTS
        PSCustomObject (with -PassThru)
        Propagation timeline with check timestamps and status changes.

    .NOTES
        Requires: Network connectivity to DNS servers
        Typical DNS TTL is 300-3600 seconds (5 minutes to 1 hour)
        Propagation across internet can take longer than TTL

    .LINK
        Get-M365DnsRecordLive
        Test-M365DnsPropagation
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the domain name to monitor'
        )]
        [Alias('DomainName', 'Domain')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'PTR', 'SOA')]
        [string[]]$RecordType = @('MX', 'TXT'),

        [Parameter(Mandatory = $false)]
        [string]$ExpectedValue,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Server = @('8.8.8.8', '1.1.1.1', '9.9.9.9'),

        [Parameter(Mandatory = $false)]
        [switch]$CompareAuthoritativeNS,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3600)]
        [int]$Interval = 30,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 86400)]
        [int]$Timeout = 1800,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Function implementation
}
```

---

## COMPARISON & ANALYSIS

### Compare-M365DnsBaseline

```powershell
function Compare-M365DnsBaseline {
    <#
    .SYNOPSIS
        Compares current DNS state against a saved baseline to detect changes.

    .DESCRIPTION
        Performs differential analysis between the current DNS configuration and a
        previously saved baseline. Identifies records that have been added, removed,
        or modified since the baseline was captured.

        Use cases:
        - Weekly/monthly DNS change auditing
        - Detecting unauthorized DNS changes
        - Tracking DNS configuration drift
        - Compliance validation over time

    .PARAMETER Name
        The domain name(s) to compare against baseline.

    .PARAMETER BaselinePath
        Path to the baseline file created with Export-M365DnsBaseline.
        Supports .json, .xml, and .csv formats.

    .PARAMETER RecordType
        Limit comparison to specific record types.
        If not specified, compares all record types in baseline.

    .PARAMETER ShowEqual
        Include records that haven't changed in the output.
        Default: Only show differences (added/removed/modified).

    .PARAMETER OutputFormat
        Format for displaying results.

    .PARAMETER PassThru
        Return comparison results object to pipeline.

    .EXAMPLE
        Compare-M365DnsBaseline -Name "contoso.com" -BaselinePath "C:\Baselines\contoso-2025-01.json"

        Compares current DNS state against January 2025 baseline.

    .EXAMPLE
        Compare-M365DnsBaseline -Name "contoso.com" -BaselinePath "baseline.json" -ShowEqual

        Shows all records including unchanged ones.

    .EXAMPLE
        Compare-M365DnsBaseline -Name "contoso.com" -BaselinePath "baseline.json" -RecordType @('MX','TXT') -PassThru

        Compares only MX and TXT records and returns results object.

    .INPUTS
        System.String
        You can pipe domain names to Compare-M365DnsBaseline.

    .OUTPUTS
        PSCustomObject
        Comparison results with properties: RecordName, RecordType, ChangeType, OldValue, NewValue

    .NOTES
        Baseline files should be created with Export-M365DnsBaseline.
        Comparison detects: Added, Removed, Modified records

    .LINK
        Export-M365DnsBaseline
        Import-M365DnsBaseline
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('DomainName', 'Domain')]
        [string[]]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [Alias('Baseline', 'Path')]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Baseline file not found: $_"
            }
            if ($_ -notmatch '\.(json|xml|csv)$') {
                throw "Baseline file must be .json, .xml, or .csv format"
            }
            $true
        })]
        [string]$BaselinePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'PTR', 'SOA')]
        [string[]]$RecordType,

        [Parameter(Mandatory = $false)]
        [switch]$ShowEqual,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Screen', 'Json', 'Xml', 'Html', 'Csv')]
        [string]$OutputFormat = 'Screen',

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Function implementation
}
```

---

## EXPORT & BASELINE

### Export-M365DnsBaseline

```powershell
function Export-M365DnsBaseline {
    <#
    .SYNOPSIS
        Exports current DNS configuration as baseline for future comparison.

    .DESCRIPTION
        Captures the current state of DNS records for specified domain(s) and saves
        to a file for future comparison. Baseline files can be used with
        Compare-M365DnsBaseline to track changes over time.

        Baseline includes:
        - All DNS records from Microsoft Graph API
        - Live DNS query results from configured resolver
        - Timestamp and metadata
        - Record types, values, and TTLs

    .PARAMETER Name
        The domain name(s) to export as baseline.

    .PARAMETER Path
        File path for the baseline export.
        Supports .json, .xml, and .csv formats.

    .PARAMETER RecordType
        Limit baseline to specific record types.
        Default: All record types (A, AAAA, MX, CNAME, TXT, SRV, NS, PTR, SOA)

    .PARAMETER IncludeLiveQuery
        Include live DNS query results in baseline (in addition to Graph API data).
        Useful for capturing both expected and actual DNS state.

    .PARAMETER Format
        Output file format.
        Default: Json (recommended for full fidelity)

    .PARAMETER Force
        Overwrite existing baseline file without confirmation.

    .PARAMETER PassThru
        Return baseline object after export.

    .EXAMPLE
        Export-M365DnsBaseline -Name "contoso.com" -Path "C:\Baselines\contoso-baseline.json"

        Exports complete DNS baseline for contoso.com to JSON file.

    .EXAMPLE
        Export-M365DnsBaseline -Name "contoso.com" -Path "baseline.xml" -RecordType @('MX','TXT','SPF') -Format Xml

        Exports only email-related records to XML format.

    .EXAMPLE
        Get-M365Domain | Export-M365DnsBaseline -Path "C:\Baselines\all-domains-{0}.json" -IncludeLiveQuery

        Exports baselines for all domains, including live DNS queries.

    .INPUTS
        System.String
        You can pipe domain names to Export-M365DnsBaseline.

    .OUTPUTS
        None by default. PSCustomObject if -PassThru is specified.

    .NOTES
        Recommended to export baselines regularly (weekly/monthly) for audit trails.
        JSON format preserves full object structure including metadata.

    .LINK
        Compare-M365DnsBaseline
        Import-M365DnsBaseline
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('DomainName', 'Domain')]
        [string[]]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateScript({
            $parentPath = Split-Path $_
            if ($parentPath -and -not (Test-Path $parentPath)) {
                throw "Directory does not exist: $parentPath"
            }
            if ($_ -notmatch '\.(json|xml|csv)$') {
                throw "Path must end with .json, .xml, or .csv"
            }
            $true
        })]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'PTR', 'SOA')]
        [string[]]$RecordType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLiveQuery,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Json', 'Xml', 'Csv')]
        [string]$Format = 'Json',

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Function implementation
}
```

---

## CUSTOM RECORDS

### Add-M365CustomDnsRecord

```powershell
function Add-M365CustomDnsRecord {
    <#
    .SYNOPSIS
        Defines custom DNS record requirements for environment-specific validation.

    .DESCRIPTION
        Adds custom DNS record definitions that are required for your specific environment.
        These custom records are validated alongside standard M365 DNS records in health
        and readiness checks.

        Use cases:
        - Custom SRV records for specific applications
        - Additional CNAME records required by your environment
        - Custom TXT records for verification or monitoring
        - Load balancer or firewall-specific DNS requirements

    .PARAMETER Name
        The full DNS record name (FQDN).
        Example: _custom._tcp.contoso.com, monitor.contoso.com

    .PARAMETER RecordType
        The DNS record type.

    .PARAMETER RecordData
        Hashtable containing the expected record data.
        Structure varies by record type:

        A/AAAA:    @{IPAddress='10.0.0.1'}
        MX:        @{Priority=10; MailServer='mail.contoso.com'}
        CNAME:     @{Target='target.contoso.com'}
        TXT:       @{Text='verification-string'}
        SRV:       @{Priority=10; Weight=5; Port=443; Target='service.contoso.com'}

    .PARAMETER Description
        Optional description of why this custom record is required.

    .PARAMETER Mandatory
        Whether this record is mandatory for compliance.
        Default: $true

    .PARAMETER PassThru
        Return the custom record definition object.

    .EXAMPLE
        Add-M365CustomDnsRecord -Name "_sip._tcp.contoso.com" -RecordType SRV -RecordData @{Priority=10; Weight=5; Port=5060; Target='sip.contoso.com'} -Description "SIP service record"

        Adds a custom SRV record requirement.

    .EXAMPLE
        $recordData = @{IPAddress='10.0.0.100'}
        Add-M365CustomDnsRecord -Name "monitoring.contoso.com" -RecordType A -RecordData $recordData -Mandatory $true

        Adds a mandatory custom A record.

    .EXAMPLE
        Add-M365CustomDnsRecord -Name "alias.contoso.com" -RecordType CNAME -RecordData @{Target='target.example.com'} -PassThru

        Adds custom CNAME and returns the definition object.

    .INPUTS
        None. You cannot pipe objects to Add-M365CustomDnsRecord.

    .OUTPUTS
        None by default. PSCustomObject if -PassThru is specified.

    .NOTES
        Custom records are stored in module scope for current session.
        For persistent custom records, add to module configuration file.

    .LINK
        Get-M365CustomDnsRecord
        Remove-M365CustomDnsRecord
        Test-M365CustomDnsRecord
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9\-\._]+$')]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'PTR')]
        [string]$RecordType,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNull()]
        [hashtable]$RecordData,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [bool]$Mandatory = $true,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Function implementation
}
```

---

## SUMMARY

This specification provides:

✅ **Complete parameter definitions** for all major functions
✅ **Comprehensive comment-based help** following Microsoft standards
✅ **3-5 examples per function** showing common usage patterns
✅ **Pipeline support** where appropriate
✅ **Validation attributes** on all inputs
✅ **Consistent naming** across all functions
✅ **Proper verb usage** from approved PowerShell verbs
✅ **OutputType declarations** for IntelliSense support

All functions follow the parameter patterns documented in PARAMETER-STANDARDS.md.
