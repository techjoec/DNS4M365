function Compare-M365DomainDNS {
    <#
    .SYNOPSIS
        Compares expected Microsoft 365 DNS records with actual DNS configuration.

    .DESCRIPTION
        Retrieves expected DNS records from Microsoft Graph API and compares them
        against actual DNS resolution results. Identifies missing, incorrect, or
        extra DNS records.

    .PARAMETER DomainName
        The domain name to compare. If not specified, compares all verified domains.

    .PARAMETER IncludeOptional
        Include optional DNS records in the comparison (DMARC, BIMI, etc.).

    .PARAMETER ShowOnlyDifferences
        Only show records that have differences (missing, incorrect, or extra).

    .PARAMETER ExportReport
        Export the comparison results to a file.

    .PARAMETER OutputPath
        Path for the exported report file.

    .EXAMPLE
        Compare-M365DomainDNS -DomainName "contoso.com"
        Compares expected vs actual DNS records for contoso.com.

    .EXAMPLE
        Compare-M365DomainDNS -DomainName "contoso.com" -IncludeOptional -ShowOnlyDifferences
        Shows only DNS records that have differences, including optional records.

    .EXAMPLE
        Compare-M365DomainDNS -ExportReport -OutputPath "C:\Reports"
        Compares all domains and exports results to a report.

    .OUTPUTS
        Custom object array containing comparison results.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$DomainName,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeOptional,

        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyDifferences,

        [Parameter(Mandatory = $false)]
        [switch]$ExportReport,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Get-Location).Path
    )

    begin {
        Write-Verbose "Starting DNS comparison"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }

        $comparisonResults = @()
    }

    process {
        try {
            # If no domain specified, get all verified domains
            if (-not $DomainName) {
                Write-Verbose "No domain specified, retrieving all verified domains"
                $domains = Get-MgDomain -All | Where-Object { $_.IsVerified -eq $true }
                $DomainName = $domains.Id
            }

            foreach ($domain in $DomainName) {
                Write-Host "`nComparing DNS records for: $domain" -ForegroundColor Cyan

                # Get expected records from Graph API
                Write-Verbose "Retrieving expected DNS records from Graph API"
                $expectedRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain -ErrorAction SilentlyContinue

                if (-not $expectedRecords) {
                    Write-Warning "No expected DNS records found for $domain"
                    continue
                }

                foreach ($record in $expectedRecords) {
                    $recordType = $record.AdditionalProperties['recordType']
                    $label = $record.Label
                    $fqdn = if ($label -eq '@') { $domain } else { "$label.$domain" }

                    $comparison = [PSCustomObject]@{
                        Domain = $domain
                        RecordType = $recordType
                        Label = $label
                        FQDN = $fqdn
                        ExpectedValue = $null
                        ActualValue = $null
                        Status = "Unknown"
                        SupportedService = $record.SupportedService
                        IsOptional = $record.IsOptional
                        TTL = $record.Ttl
                        Details = $null
                    }

                    # Get expected value based on record type
                    switch ($recordType) {
                        'MX' {
                            $comparison.ExpectedValue = "$($record.AdditionalProperties['preference']) $($record.AdditionalProperties['mailExchange'])"

                            try {
                                $actual = Resolve-DnsName -Name $fqdn -Type MX -ErrorAction SilentlyContinue
                                if ($actual) {
                                    $primaryMX = $actual | Sort-Object Preference | Select-Object -First 1
                                    $comparison.ActualValue = "$($primaryMX.Preference) $($primaryMX.NameExchange)"

                                    if ($primaryMX.NameExchange -eq $record.AdditionalProperties['mailExchange']) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected: $($record.AdditionalProperties['mailExchange']), Got: $($primaryMX.NameExchange)"
                                    }

                                    # Check for legacy MX format (July-August 2025 migration)
                                    if ($primaryMX.NameExchange -like "*.mail.protection.outlook.com") {
                                        $comparison.Details += " | NOTE: Legacy MX format detected (consider migrating to mx.microsoft)"
                                    }
                                }
                                else {
                                    $comparison.Status = "Missing"
                                    $comparison.ActualValue = "(not found)"
                                }
                            }
                            catch {
                                $comparison.Status = "Error"
                                $comparison.Details = $_.Exception.Message
                            }
                        }

                        'CName' {
                            $comparison.ExpectedValue = $record.AdditionalProperties['canonicalName']

                            try {
                                $actual = Resolve-DnsName -Name $fqdn -Type CNAME -ErrorAction SilentlyContinue
                                if ($actual) {
                                    $comparison.ActualValue = $actual.NameHost

                                    if ($actual.NameHost -eq $record.AdditionalProperties['canonicalName']) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected: $($record.AdditionalProperties['canonicalName']), Got: $($actual.NameHost)"
                                    }

                                    # Check for legacy DKIM format (May 2025 new format)
                                    if ($label -like "selector*._domainkey" -and $actual.NameHost -like "*._domainkey.*.onmicrosoft.com") {
                                        $comparison.Details += " | NOTE: Legacy DKIM format (new deployments use dkim.mail.microsoft)"
                                    }

                                    # Check for legacy Skype for Business records
                                    if ($label -eq "sip" -or $label -eq "lyncdiscover") {
                                        $comparison.Details += " | NOTE: Legacy Skype for Business record (not required for Teams-only tenants)"
                                    }
                                }
                                else {
                                    $comparison.Status = "Missing"
                                    $comparison.ActualValue = "(not found)"
                                }
                            }
                            catch {
                                $comparison.Status = "Error"
                                $comparison.Details = $_.Exception.Message
                            }
                        }

                        'Txt' {
                            $comparison.ExpectedValue = $record.AdditionalProperties['text']

                            try {
                                $actual = Resolve-DnsName -Name $fqdn -Type TXT -ErrorAction SilentlyContinue
                                if ($actual) {
                                    $txtValue = ($actual.Strings -join "")
                                    $comparison.ActualValue = $txtValue

                                    # For TXT records, we need to check if the expected value exists among all TXT records
                                    $expectedText = $record.AdditionalProperties['text']
                                    if ($actual | Where-Object { ($_.Strings -join "") -eq $expectedText }) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected text not found in TXT records"
                                    }
                                }
                                else {
                                    $comparison.Status = "Missing"
                                    $comparison.ActualValue = "(not found)"
                                }
                            }
                            catch {
                                $comparison.Status = "Error"
                                $comparison.Details = $_.Exception.Message
                            }
                        }

                        'Srv' {
                            $service = $record.AdditionalProperties['service']
                            $protocol = $record.AdditionalProperties['protocol']
                            $srvFqdn = "$service.$protocol.$domain"
                            $comparison.FQDN = $srvFqdn

                            $priority = $record.AdditionalProperties['priority']
                            $weight = $record.AdditionalProperties['weight']
                            $port = $record.AdditionalProperties['port']
                            $target = $record.AdditionalProperties['nameTarget']

                            $comparison.ExpectedValue = "$priority $weight $port $target"

                            try {
                                $actual = Resolve-DnsName -Name $srvFqdn -Type SRV -ErrorAction SilentlyContinue
                                if ($actual) {
                                    $comparison.ActualValue = "$($actual.Priority) $($actual.Weight) $($actual.Port) $($actual.NameTarget)"

                                    if ($actual.NameTarget -eq $target -and $actual.Port -eq $port) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected: $target:$port, Got: $($actual.NameTarget):$($actual.Port)"
                                    }
                                }
                                else {
                                    $comparison.Status = "Missing"
                                    $comparison.ActualValue = "(not found)"
                                }
                            }
                            catch {
                                $comparison.Status = "Error"
                                $comparison.Details = $_.Exception.Message
                            }
                        }
                    }

                    $comparisonResults += $comparison
                }

                # Check for optional records if requested
                if ($IncludeOptional) {
                    # Check DMARC
                    Write-Verbose "Checking DMARC record (MANDATORY starting April 2025)"
                    try {
                        $dmarc = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction SilentlyContinue
                        $dmarcComparison = [PSCustomObject]@{
                            Domain = $domain
                            RecordType = "TXT"
                            Label = "_dmarc"
                            FQDN = "_dmarc.$domain"
                            ExpectedValue = "v=DMARC1; p=quarantine or p=reject (MANDATORY April 2025)"
                            ActualValue = if ($dmarc) { ($dmarc.Strings -join "") } else { "(not found)" }
                            Status = if ($dmarc) { "Present" } else { "CRITICAL - Missing" }
                            SupportedService = "Email Security"
                            IsOptional = $false  # Changed: MANDATORY as of April 2025
                            TTL = if ($dmarc) { $dmarc.TTL } else { $null }
                            Details = if (-not $dmarc) { "CRITICAL: Email authentication MANDATORY starting April 2025 - DMARC record MUST exist with policy p=quarantine or p=reject" } else { $null }
                        }
                        $comparisonResults += $dmarcComparison
                    }
                    catch {
                        Write-Verbose "Failed to check DMARC: $_"
                    }

                    # Check for deprecated MSOID
                    Write-Verbose "Checking for deprecated MSOID record"
                    try {
                        $msoid = Resolve-DnsName -Name "msoid.$domain" -Type CNAME -ErrorAction SilentlyContinue
                        if ($msoid) {
                            $msoidComparison = [PSCustomObject]@{
                                Domain = $domain
                                RecordType = "CNAME"
                                Label = "msoid"
                                FQDN = "msoid.$domain"
                                ExpectedValue = "(should not exist - DEPRECATED)"
                                ActualValue = $msoid.NameHost
                                Status = "DEPRECATED - REMOVE"
                                SupportedService = "Deprecated"
                                IsOptional = $false
                                TTL = $msoid.TTL
                                Details = "CRITICAL: This record MUST be removed - it blocks Microsoft 365 Apps activation"
                            }
                            $comparisonResults += $msoidComparison
                        }
                    }
                    catch {
                        # Good - record doesn't exist
                    }
                }
            }

            # Display summary
            Write-Host "`n=== DNS Comparison Summary ===" -ForegroundColor Cyan

            $totalRecords = $comparisonResults.Count
            $matches = ($comparisonResults | Where-Object { $_.Status -eq "Match" }).Count
            $mismatches = ($comparisonResults | Where-Object { $_.Status -eq "Mismatch" }).Count
            $missing = ($comparisonResults | Where-Object { $_.Status -eq "Missing" }).Count
            $deprecated = ($comparisonResults | Where-Object { $_.Status -like "*DEPRECATED*" }).Count

            Write-Host "Total Records Checked: $totalRecords" -ForegroundColor White
            Write-Host "Matches: $matches" -ForegroundColor Green
            Write-Host "Mismatches: $mismatches" -ForegroundColor Yellow
            Write-Host "Missing: $missing" -ForegroundColor Red
            if ($deprecated -gt 0) {
                Write-Host "Deprecated (REMOVE): $deprecated" -ForegroundColor Magenta
            }

            # Show details if requested
            if ($ShowOnlyDifferences) {
                $differences = $comparisonResults | Where-Object { $_.Status -ne "Match" }
                if ($differences) {
                    Write-Host "`nDifferences Found:" -ForegroundColor Yellow
                    $differences | Format-Table Domain, RecordType, Label, Status, ExpectedValue, ActualValue -AutoSize
                }
                else {
                    Write-Host "`nNo differences found - all DNS records match!" -ForegroundColor Green
                }
            }
            else {
                $comparisonResults | Format-Table Domain, RecordType, Label, Status, SupportedService -AutoSize
            }

            # Export report if requested
            if ($ExportReport) {
                $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $reportFile = Join-Path -Path $OutputPath -ChildPath "DNS-Comparison-$timestamp.csv"
                $comparisonResults | Export-Csv -Path $reportFile -NoTypeInformation
                Write-Host "`nReport exported to: $reportFile" -ForegroundColor Green
            }

            return $comparisonResults
        }
        catch {
            Write-Error "Failed to compare DNS records: $_"
            throw
        }
    }
}
