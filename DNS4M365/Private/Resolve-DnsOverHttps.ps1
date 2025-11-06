function Resolve-DnsOverHttps {
    <#
    .SYNOPSIS
        Resolves DNS records using Google DNS-over-HTTPS API.

    .DESCRIPTION
        Performs DNS lookups using Google's public DNS-over-HTTPS service for consistent,
        reliable results regardless of local DNS configuration. Returns objects compatible
        with PowerShell's Resolve-DnsName output format.

    .PARAMETER Name
        The DNS name to query (e.g., "contoso.com", "autodiscover.contoso.com").

    .PARAMETER Type
        The DNS record type to query (MX, CNAME, TXT, SRV, A, AAAA).

    .EXAMPLE
        Resolve-DnsOverHttps -Name "contoso.com" -Type MX

    .OUTPUTS
        Custom objects matching Resolve-DnsName output format.

    .NOTES
        Uses Google Public DNS-over-HTTPS API: https://dns.google/resolve
        Provides consistent results independent of local DNS resolver configuration.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'SOA')]
        [string]$Type
    )

    try {
        # Google DNS-over-HTTPS endpoint
        $dohUrl = "https://dns.google/resolve?name=$([System.Uri]::EscapeDataString($Name))&type=$Type"

        Write-Verbose "DNS-over-HTTPS query: $Name ($Type)"

        # Query Google DNS-over-HTTPS API
        $response = Invoke-RestMethod -Uri $dohUrl -Method Get -ErrorAction Stop

        # Check if we got answers
        if (-not $response.Answer -or $response.Answer.Count -eq 0) {
            Write-Verbose "No DNS records found for $Name ($Type)"
            return $null
        }

        # Parse response based on record type
        $results = @()
        foreach ($answer in $response.Answer) {
            switch ($Type) {
                'MX' {
                    # MX format: "10 contoso-com.mail.protection.outlook.com."
                    if ($answer.data -match '^(\d+)\s+(.+)\.$') {
                        $results += [PSCustomObject]@{
                            Name = $Name
                            Type = 'MX'
                            TTL = $answer.TTL
                            Preference = [int]$Matches[1]
                            NameExchange = $Matches[2]
                        }
                    }
                }

                'CNAME' {
                    # CNAME format: "target.domain.com."
                    $results += [PSCustomObject]@{
                        Name = $Name
                        Type = 'CNAME'
                        TTL = $answer.TTL
                        NameHost = $answer.data.TrimEnd('.')
                    }
                }

                'TXT' {
                    # TXT records can have quotes that need to be cleaned
                    $txtData = $answer.data -replace '^"|"$', ''
                    $results += [PSCustomObject]@{
                        Name = $Name
                        Type = 'TXT'
                        TTL = $answer.TTL
                        Strings = $txtData
                    }
                }

                'SRV' {
                    # SRV format: "priority weight port target."
                    if ($answer.data -match '^(\d+)\s+(\d+)\s+(\d+)\s+(.+)\.$') {
                        $results += [PSCustomObject]@{
                            Name = $Name
                            Type = 'SRV'
                            TTL = $answer.TTL
                            Priority = [int]$Matches[1]
                            Weight = [int]$Matches[2]
                            Port = [int]$Matches[3]
                            NameTarget = $Matches[4]
                        }
                    }
                }

                'A' {
                    $results += [PSCustomObject]@{
                        Name = $Name
                        Type = 'A'
                        TTL = $answer.TTL
                        IPAddress = $answer.data
                    }
                }

                'AAAA' {
                    $results += [PSCustomObject]@{
                        Name = $Name
                        Type = 'AAAA'
                        TTL = $answer.TTL
                        IPAddress = $answer.data
                    }
                }

                default {
                    # Generic format for other types
                    $results += [PSCustomObject]@{
                        Name = $Name
                        Type = $Type
                        TTL = $answer.TTL
                        Data = $answer.data
                    }
                }
            }
        }

        Write-Verbose "Found $($results.Count) DNS record(s) for $Name ($Type)"
        return $results
    }
    catch {
        Write-Verbose "DNS-over-HTTPS lookup failed for $Name ($Type): $_"
        return $null
    }
}
