function Initialize-DnsConfig {
    <#
    .SYNOPSIS
        Initializes module-level DNS resolver configuration.

    .DESCRIPTION
        Sets up DNS resolver configuration for the module including resolver type
        (DoH, DoT, or Standard) and DNS server to use.

    .PARAMETER ResolverType
        Type of DNS resolver to use: DoH (DNS-over-HTTPS), DoT (DNS-over-TLS), or Standard.

    .PARAMETER DnsServer
        DNS server to use. Can be IP address or hostname.
        DoH defaults: Google (dns.google), Cloudflare (cloudflare-dns.com), Quad9 (dns.quad9.net)
        Standard defaults: 8.8.8.8 (Google), 1.1.1.1 (Cloudflare), 9.9.9.9 (Quad9)

    .EXAMPLE
        Initialize-DnsConfig -ResolverType DoH -DnsServer "dns.google"

    .EXAMPLE
        Initialize-DnsConfig -ResolverType Standard -DnsServer "8.8.8.8"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('DoH', 'DoT', 'Standard')]
        [string]$ResolverType = 'DoH',

        [Parameter(Mandatory = $false)]
        [string]$DnsServer = $null
    )

    # Set default DNS server based on resolver type if not specified
    if (-not $DnsServer) {
        $DnsServer = switch ($ResolverType) {
            'DoH' { 'dns.google' }
            'DoT' { 'dns.google' }
            'Standard' { '8.8.8.8' }
        }
    }

    # Store in script-scope variables
    $script:DnsResolverType = $ResolverType
    $script:DnsServer = $DnsServer

    Write-Verbose "DNS Resolver initialized: Type=$ResolverType, Server=$DnsServer"
}

# Initialize with defaults when module loads
if (-not $script:DnsResolverType) {
    Initialize-DnsConfig -ResolverType DoH -DnsServer 'dns.google'
}
