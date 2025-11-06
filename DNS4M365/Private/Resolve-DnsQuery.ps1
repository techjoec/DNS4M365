function Resolve-DnsQuery {
    <#
    .SYNOPSIS
        Unified DNS resolver supporting DoH, DoT, Standard DNS, and Authoritative NS queries.

    .DESCRIPTION
        Performs DNS lookups using configured resolver type (DoH, DoT, or Standard DNS).
        Can also query authoritative nameservers directly for a domain.

    .PARAMETER Name
        The DNS name to query.

    .PARAMETER Type
        The DNS record type to query (MX, CNAME, TXT, SRV, A, AAAA, PTR, NS, SOA).

    .PARAMETER UseAuthoritativeNS
        Query the authoritative nameservers for the domain instead of configured resolver.

    .PARAMETER Server
        Override the configured DNS server for this query.

    .PARAMETER ResolverType
        Override the configured resolver type for this query.

    .EXAMPLE
        Resolve-DnsQuery -Name "contoso.com" -Type MX

    .EXAMPLE
        Resolve-DnsQuery -Name "contoso.com" -Type TXT -UseAuthoritativeNS

    .OUTPUTS
        Custom objects matching Resolve-DnsName output format.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'SOA', 'PTR')]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$UseAuthoritativeNS,

        [Parameter(Mandatory = $false)]
        [string]$Server,

        [Parameter(Mandatory = $false)]
        [ValidateSet('DoH', 'DoT', 'Standard')]
        [string]$ResolverType
    )

    # Use module configuration if not overridden
    if (-not $ResolverType) {
        $ResolverType = $script:DnsResolverType
    }
    if (-not $Server) {
        $Server = $script:DnsServer
    }

    # If querying authoritative NS, find them first
    if ($UseAuthoritativeNS) {
        $authNS = Get-AuthoritativeNameserver -DomainName $Name
        if ($authNS -and $authNS.Count -gt 0) {
            $Server = $authNS[0]
            $ResolverType = 'Standard'  # Always use standard DNS for auth NS queries
            Write-Verbose "Querying authoritative NS: $Server"
        }
        else {
            Write-Warning "Could not determine authoritative nameservers for $Name, using configured resolver"
        }
    }

    # Route to appropriate resolver
    switch ($ResolverType) {
        'DoH' {
            return Resolve-DnsOverHttps -Name $Name -Type $Type -Server $Server
        }
        'DoT' {
            # DoT not yet implemented, fall back to DoH
            Write-Verbose "DoT not yet implemented, falling back to DoH"
            return Resolve-DnsOverHttps -Name $Name -Type $Type -Server $Server
        }
        'Standard' {
            return Resolve-DnsStandard -Name $Name -Type $Type -Server $Server
        }
    }
}
