function Watch-M365DnsPropagation {
    <#
    .SYNOPSIS
        Monitors DNS records for changes and propagation status in real-time.

    .DESCRIPTION
        Continuously monitors DNS records across multiple resolvers to track propagation
        of DNS changes. Useful for validating that DNS updates have propagated globally
        before proceeding with service cutover or configuration changes.

        Features:
        - Real-time DNS monitoring with configurable intervals
        - Multiple DNS resolver support (Google, Cloudflare, Quad9, custom)
        - Change detection and notification
        - TTL countdown tracking
        - Propagation percentage calculation

    .PARAMETER Name
        The domain name to monitor for DNS changes.

    .PARAMETER RecordType
        The DNS record type to monitor (MX, CNAME, TXT, SRV, A, AAAA).

    .PARAMETER ExpectedValue
        The expected DNS value to watch for. When specified, monitoring continues
        until this value is seen across all resolvers.

    .PARAMETER Interval
        Check interval in seconds (default: 30 seconds).

    .PARAMETER Duration
        Maximum monitoring duration in minutes (default: continuous until Ctrl+C).

    .PARAMETER Resolver
        DNS resolvers to query. Default: Google (8.8.8.8), Cloudflare (1.1.1.1), Quad9 (9.9.9.9).
        Specify custom resolvers as array: @('8.8.8.8', '1.1.1.1', '208.67.222.222')

    .PARAMETER UseDoH
        Use DNS-over-HTTPS instead of standard DNS queries.

    .PARAMETER Quiet
        Suppress per-check output, only show changes and summary.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "contoso.com" -RecordType MX
        Monitor MX record changes across default public DNS resolvers.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "contoso.com" -RecordType MX -ExpectedValue "contoso-com.mail.protection.outlook.com" -Interval 60
        Monitor until MX record propagates to expected value, checking every 60 seconds.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "autodiscover.contoso.com" -RecordType CNAME -UseDoH
        Monitor CNAME using DNS-over-HTTPS for encrypted queries.

    .EXAMPLE
        Watch-M365DnsPropagation -Name "contoso.com" -RecordType MX -Resolver @('8.8.8.8', '1.1.1.1') -Duration 30
        Monitor MX for 30 minutes across Google and Cloudflare DNS.

    .OUTPUTS
        Real-time console output with DNS propagation status. Press Ctrl+C to stop monitoring.

    .NOTES
        This function runs continuously until stopped with Ctrl+C or duration expires.
        Use -Quiet for less verbose output when monitoring long-running changes.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias('DomainName', 'Domain')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV')]
        [string]$RecordType,

        [Parameter(Mandatory = $false)]
        [string]$ExpectedValue,

        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 3600)]
        [int]$Interval = 30,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1440)]
        [int]$Duration,

        [Parameter(Mandatory = $false)]
        [string[]]$Resolver = @('8.8.8.8', '1.1.1.1', '9.9.9.9'),

        [Parameter(Mandatory = $false)]
        [switch]$UseDoH,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )

    begin {
        Write-Information "`n=== DNS Propagation Monitor ===" -InformationAction Continue
        Write-Information "Domain: $Name" -InformationAction Continue
        Write-Information "Record Type: $RecordType" -InformationAction Continue
        Write-Information "Resolvers: $($Resolver -join ', ')" -InformationAction Continue
        Write-Information "Check Interval: $Interval seconds" -InformationAction Continue

        if ($ExpectedValue) {
            Write-Information "Expected Value: $ExpectedValue" -InformationAction Continue
            Write-Information "Monitoring until value propagates..." -InformationAction Continue
        }

        if ($Duration) {
            Write-Information "Duration: $Duration minutes" -InformationAction Continue
        }
        else {
            Write-Information "Duration: Continuous (press Ctrl+C to stop)" -InformationAction Continue
        }

        Write-Information "`nStarting monitoring at $(Get-Date -Format 'HH:mm:ss')..." -InformationAction Continue
        Write-Information ("=" * 80) -InformationAction Continue

        # Initialize tracking
        $startTime = Get-Date
        $previousValues = @{}
        $checkCount = 0
        $changeCount = 0
        $allMatch = $false

        # Initialize previous values for each resolver
        foreach ($server in $Resolver) {
            $previousValues[$server] = $null
        }
    }

    process {
        try {
            while (-not $allMatch) {
                # Check if duration exceeded
                if ($Duration) {
                    $elapsed = ((Get-Date) - $startTime).TotalMinutes
                    if ($elapsed -ge $Duration) {
                        Write-Information "`nMonitoring duration ($Duration minutes) reached." -InformationAction Continue
                        break
                    }
                }

                $checkCount++
                $timestamp = Get-Date -Format 'HH:mm:ss'

                if (-not $Quiet) {
                    Write-Information "`n[$timestamp] Check #$checkCount" -InformationAction Continue
                }

                $currentResults = @{}
                $matchExpected = 0

                # Query each resolver
                foreach ($server in $Resolver) {
                    try {
                        if ($UseDoH) {
                            $result = Invoke-DnsQuery -Name $Name -Type $RecordType -Method DoH
                        }
                        else {
                            $result = Invoke-DnsQuery -Name $Name -Type $RecordType -Method Standard -Server $server
                        }

                        # Extract value based on record type
                        $value = switch ($RecordType) {
                            'MX' { $result.NameExchange }
                            'CNAME' { $result.NameHost }
                            'TXT' { $result.Strings }
                            'SRV' { $result.NameTarget }
                            'A' { $result.IPAddress }
                            'AAAA' { $result.IPAddress }
                            default { $result.Data }
                        }

                        $currentResults[$server] = $value

                        # Check for changes
                        if ($previousValues[$server] -and $previousValues[$server] -ne $value) {
                            $changeCount++
                            Write-Information "  ⚠️  CHANGE DETECTED on $server" -InformationAction Continue
                            Write-Information "      Old: $($previousValues[$server])" -InformationAction Continue
                            Write-Information "      New: $value" -InformationAction Continue
                        }
                        elseif (-not $Quiet) {
                            $status = if ($value) { "✓" } else { "✗" }
                            Write-Information "  $status $server : $value" -InformationAction Continue
                        }

                        # Check against expected value
                        if ($ExpectedValue) {
                            if ($value -eq $ExpectedValue) {
                                $matchExpected++
                            }
                        }

                        $previousValues[$server] = $value
                    }
                    catch {
                        Write-Verbose "Failed to query $server : $_"
                        if (-not $Quiet) {
                            Write-Information "  ✗ $server : Query failed" -InformationAction Continue
                        }
                    }
                }

                # Calculate propagation percentage
                if ($ExpectedValue -and $Resolver.Count -gt 0) {
                    $propagationPct = [math]::Round(($matchExpected / $Resolver.Count) * 100)

                    if ($propagationPct -lt 100) {
                        Write-Information "`n  Propagation: $propagationPct% ($matchExpected/$($Resolver.Count) resolvers)" -InformationAction Continue
                    }
                    else {
                        Write-Information "`n  ✓ Propagation: 100% (All resolvers match expected value!)" -InformationAction Continue
                        $allMatch = $true
                    }
                }

                # Exit if all match expected (and expected was provided)
                if ($ExpectedValue -and $allMatch) {
                    Write-Information "`n🎉 DNS propagation complete! All resolvers now return the expected value." -InformationAction Continue
                    break
                }

                # Wait for next check
                if (-not $allMatch) {
                    if (-not $Quiet) {
                        Write-Information "`n  Next check in $Interval seconds..." -InformationAction Continue
                    }
                    Start-Sleep -Seconds $Interval
                }
            }

            # Display summary
            $endTime = Get-Date
            $totalDuration = $endTime - $startTime

            Write-Information "" -InformationAction Continue
            Write-Information ("=" * 80) -InformationAction Continue
            Write-Information "`n=== Monitoring Summary ===" -InformationAction Continue
            Write-Information "Total Checks: $checkCount" -InformationAction Continue
            Write-Information "Changes Detected: $changeCount" -InformationAction Continue
            Write-Information "Duration: $($totalDuration.ToString('hh\:mm\:ss'))" -InformationAction Continue

            if ($ExpectedValue -and $allMatch) {
                Write-Information "Status: ✓ Propagation Complete" -InformationAction Continue
            }
            elseif ($ExpectedValue) {
                Write-Information "Status: ⚠️  Still Propagating" -InformationAction Continue
            }
            else {
                Write-Information "Status: Monitoring Stopped" -InformationAction Continue
            }

            Write-Information "`nFinal Values:" -InformationAction Continue
            foreach ($server in $Resolver) {
                if ($currentResults.ContainsKey($server)) {
                    Write-Information "  $server : $($currentResults[$server])" -InformationAction Continue
                }
            }

            Write-Information "" -InformationAction Continue
        }
        catch {
            Write-Error "DNS monitoring failed: $_"
            throw
        }
    }
}
