function Invoke-DnsQuery {
    <#
    .SYNOPSIS
        Performs DNS lookups using standard DNS or DNS-over-HTTPS.

    .DESCRIPTION
        Simple DNS query wrapper that uses native Resolve-DnsName for standard queries
        or Google DNS-over-HTTPS for encrypted queries. Returns consistent output format.

    .PARAMETER Name
        The DNS name to query (e.g., "contoso.com", "autodiscover.contoso.com").

    .PARAMETER Type
        The DNS record type to query (MX, CNAME, TXT, SRV, A, AAAA, NS, SOA, PTR).

    .PARAMETER Method
        Query method: Standard (native Resolve-DnsName) or DoH (DNS-over-HTTPS).
        Default: Standard

    .PARAMETER Server
        DNS server to query (only used with Standard method).
        Examples: 8.8.8.8, 1.1.1.1

    .EXAMPLE
        Invoke-DnsQuery -Name "contoso.com" -Type MX
        Standard DNS query using system resolver.

    .EXAMPLE
        Invoke-DnsQuery -Name "contoso.com" -Type MX -Method DoH
        Encrypted DNS query using Google Public DNS.

    .EXAMPLE
        Invoke-DnsQuery -Name "contoso.com" -Type MX -Method Standard -Server "8.8.8.8"
        Query specific DNS server.

    .OUTPUTS
        Custom objects matching Resolve-DnsName output format.

    .NOTES
        KISS Design: Uses native Resolve-DnsName for standard queries.
        Only DoH requires special handling via Invoke-WebRequest.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('DomainName', 'Domain')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'SOA', 'PTR')]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Standard', 'DoH')]
        [string]$Method = 'Standard',

        [Parameter(Mandatory = $false)]
        [string]$Server
    )

    process {
        try {
            if ($Method -eq 'DoH') {
                # DNS-over-HTTPS: Use Google Public DNS API
                Write-Verbose "DNS-over-HTTPS query: $Name ($Type)"

                $dohUrl = "https://dns.google/resolve?name=$([System.Uri]::EscapeDataString($Name))&type=$Type"
                $response = Invoke-RestMethod -Uri $dohUrl -Method Get -ErrorAction Stop

                if (-not $response.Answer -or $response.Answer.Count -eq 0) {
                    Write-Verbose "No DNS records found for $Name ($Type)"
                    return $null
                }

                # Parse DoH response to match Resolve-DnsName format
                return $response.Answer | ForEach-Object {
                    switch ($Type) {
                        'MX' {
                            if ($_.data -match '^(\d+)\s+(.+)\.$') {
                                [PSCustomObject]@{
                                    Name         = $Name
                                    Type         = 'MX'
                                    TTL          = $_.TTL
                                    Preference   = [int]$Matches[1]
                                    NameExchange = $Matches[2]
                                }
                            }
                        }
                        'CNAME' {
                            [PSCustomObject]@{
                                Name     = $Name
                                Type     = 'CNAME'
                                TTL      = $_.TTL
                                NameHost = $_.data.TrimEnd('.')
                            }
                        }
                        'TXT' {
                            [PSCustomObject]@{
                                Name    = $Name
                                Type    = 'TXT'
                                TTL     = $_.TTL
                                Strings = $_.data -replace '^\"|\"$', ''
                            }
                        }
                        'SRV' {
                            if ($_.data -match '^(\d+)\s+(\d+)\s+(\d+)\s+(.+)\.$') {
                                [PSCustomObject]@{
                                    Name       = $Name
                                    Type       = 'SRV'
                                    TTL        = $_.TTL
                                    Priority   = [int]$Matches[1]
                                    Weight     = [int]$Matches[2]
                                    Port       = [int]$Matches[3]
                                    NameTarget = $Matches[4]
                                }
                            }
                        }
                        'A' {
                            [PSCustomObject]@{
                                Name      = $Name
                                Type      = 'A'
                                TTL       = $_.TTL
                                IPAddress = $_.data
                            }
                        }
                        'AAAA' {
                            [PSCustomObject]@{
                                Name      = $Name
                                Type      = 'AAAA'
                                TTL       = $_.TTL
                                IPAddress = $_.data
                            }
                        }
                        default {
                            [PSCustomObject]@{
                                Name = $Name
                                Type = $Type
                                TTL  = $_.TTL
                                Data = $_.data
                            }
                        }
                    }
                }
            }
            else {
                # Standard DNS: Use native Resolve-DnsName (FAST!)
                Write-Verbose "Standard DNS query: $Name ($Type)"

                $params = @{
                    Name        = $Name
                    Type        = $Type
                    ErrorAction = 'Stop'
                }

                if ($Server) {
                    $params['Server'] = $Server
                }

                $result = Resolve-DnsName @params

                # Return only the answer section (filter out authority/additional)
                return $result | Where-Object { $_.Type -eq $Type }
            }
        }
        catch {
            Write-Verbose "DNS query failed for $Name ($Type): $_"
            return $null
        }
    }
}
