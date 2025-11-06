function Compare-M365DnsRecord {
    <#
    .SYNOPSIS
        Compares expected Microsoft 365 DNS records with actual DNS configuration.

    .DESCRIPTION
        Retrieves expected DNS records from Microsoft Graph API and compares them
        against actual DNS resolution results. Identifies missing, incorrect, or
        extra DNS records. Supports baseline/diff mode for change detection over time.

        Features:
        - Expected vs Actual comparison (Graph API vs DNS)
        - Legacy format detection (MX, DKIM)
        - Deprecated record identification
        - Optional record validation (SPF, DMARC)
        - Baseline save/load for change tracking

    .PARAMETER Name
        The domain name(s) to compare. If not specified, compares all verified domains.

    .PARAMETER CSVPath
        Path to CSV file containing expected DNS records for offline comparison.
        Use this to compare DNS without requiring live Microsoft Graph API access.
        See Templates/expected-dns-records-template.csv for format.
        Mutually exclusive with -JSONPath.

    .PARAMETER JSONPath
        Path to JSON file containing expected DNS records for offline comparison.
        Use this to compare DNS without requiring live Microsoft Graph API access.
        See Templates/expected-dns-records-template.json for format.
        Mutually exclusive with -CSVPath.

    .PARAMETER IncludeOptional
        Include optional DNS records in the comparison (DMARC, deprecated records).

    .PARAMETER ShowOnlyDifference
        Only show records that have differences (missing, incorrect, or extra).

    .PARAMETER Method
        DNS query method: Standard (Resolve-DnsName) or DoH (DNS-over-HTTPS).
        Default: Standard

    .PARAMETER Server
        DNS server to query (only with Standard method). Examples: 8.8.8.8, 1.1.1.1

    .PARAMETER SaveBaseline
        Save comparison results as baseline for future diff operations.

    .PARAMETER BaselinePath
        Path to save/load baseline file (default: current directory/baseline.json).

    .PARAMETER CompareToBaseline
        Compare current DNS state against saved baseline instead of Graph API.

    .PARAMETER ExportReport
        Export the comparison results to CSV file.

    .PARAMETER OutputPath
        Path for the exported report file (default: current directory).

    .EXAMPLE
        Compare-M365DnsRecord -Name "contoso.com"
        Compares expected vs actual DNS records for contoso.com using Graph API.

    .EXAMPLE
        Compare-M365DnsRecord -CSVPath ".\Templates\expected-dns-records-template.csv"
        Offline comparison using CSV file (no live API access required).

    .EXAMPLE
        Compare-M365DnsRecord -JSONPath ".\Templates\expected-dns-records-template.json"
        Offline comparison using JSON file (no live API access required).

    .EXAMPLE
        Compare-M365DnsRecord -Name "contoso.com" -IncludeOptional -ShowOnlyDifference
        Shows only DNS records that have differences, including optional records.

    .EXAMPLE
        Compare-M365DnsRecord -SaveBaseline -BaselinePath "C:\Baselines\pre-change.json"
        Saves current DNS state as baseline before making changes.

    .EXAMPLE
        Compare-M365DnsRecord -CompareToBaseline -BaselinePath "C:\Baselines\pre-change.json"
        Compares current DNS against saved baseline to detect changes.

    .EXAMPLE
        Compare-M365DnsRecord -Method DoH -ExportReport
        Compare all domains using DNS-over-HTTPS and export to CSV.

    .OUTPUTS
        Custom object array containing comparison results.

    .NOTES
        Requires Microsoft Graph connection with Domain.Read.All scope (unless using CSV/JSON).
        Run: Connect-MgGraph -Scopes "Domain.Read.All"

        CSV/JSON-based comparison does not require any authentication (offline mode).
    #>

    [CmdletBinding(DefaultParameterSetName = 'Compare')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('DomainName', 'Domain')]
        [string[]]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "CSV file not found: $_"
            }
            if ($_ -notlike "*.csv") {
                throw "File must be a CSV file"
            }
            $true
        })]
        [string]$CSVPath,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "JSON file not found: $_"
            }
            if ($_ -notlike "*.json") {
                throw "File must be a JSON file"
            }
            $true
        })]
        [string]$JSONPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeOptional,

        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyDifference,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Standard', 'DoH')]
        [string]$Method = 'Standard',

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            @('8.8.8.8', '8.8.4.4', '1.1.1.1', '1.0.0.1', '9.9.9.9', '149.112.112.112', '208.67.222.222', '208.67.220.220') |
                Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        })]
        [string]$Server,

        [Parameter(Mandatory = $false, ParameterSetName = 'Baseline')]
        [switch]$SaveBaseline,

        [Parameter(Mandatory = $false, ParameterSetName = 'Baseline')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Diff')]
        [string]$BaselinePath = (Join-Path -Path (Get-Location).Path -ChildPath "dns-baseline.json"),

        [Parameter(Mandatory = $false, ParameterSetName = 'Diff')]
        [switch]$CompareToBaseline,

        [Parameter(Mandatory = $false)]
        [switch]$ExportReport,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Get-Location).Path
    )

    begin {
        Write-Verbose "Starting DNS comparison"

        # Check for mutual exclusivity
        $usingCSV = $PSBoundParameters.ContainsKey('CSVPath')
        $usingJSON = $PSBoundParameters.ContainsKey('JSONPath')

        if ($usingCSV -and $usingJSON) {
            throw "Cannot specify both -CSVPath and -JSONPath. Please use only one offline comparison method."
        }

        # Determine comparison mode
        $offlineRecords = $null
        $usingOffline = $usingCSV -or $usingJSON

        if ($usingCSV) {
            Write-Verbose "Using CSV-based offline comparison mode"
            try {
                $offlineRecords = Import-Csv -Path $CSVPath
                Write-Verbose "Loaded $($offlineRecords.Count) records from CSV"
            }
            catch {
                throw "Failed to import CSV file: $_"
            }
        }
        elseif ($usingJSON) {
            Write-Verbose "Using JSON-based offline comparison mode"
            try {
                $jsonContent = Get-Content -Path $JSONPath -Raw | ConvertFrom-Json
                # Convert to array if single object
                $offlineRecords = if ($jsonContent -is [array]) { $jsonContent } else { @($jsonContent) }
                Write-Verbose "Loaded $($offlineRecords.Count) records from JSON"
            }
            catch {
                throw "Failed to import JSON file: $_"
            }
        }
        else {
            # Check Microsoft Graph connection (unless comparing to baseline only)
            if (-not $CompareToBaseline) {
                Write-Verbose "Using online comparison mode (Microsoft Graph API)"

                # Check if Microsoft.Graph.Authentication module is available
                $graphAuthModule = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication | Select-Object -First 1
                if (-not $graphAuthModule) {
                    throw @"
Microsoft Graph module not installed.

OPTION 1: Install Microsoft Graph modules (for Graph API comparison):
    Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -Scope CurrentUser
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -MinimumVersion 2.0.0 -Scope CurrentUser
    Connect-MgGraph -Scopes 'Domain.Read.All'

OPTION 2: Use CSV/JSON-based offline comparison (no dependencies required):
    Compare-M365DnsRecord -CSVPath ".\expected-dns-records.csv"
    Compare-M365DnsRecord -JSONPath ".\expected-dns-records.json"
    (See Templates/ for template files)

OPTION 3: Use baseline comparison (no dependencies required):
    Compare-M365DnsRecord -CompareToBaseline -BaselinePath ".\baseline.json"
"@
                }

                # Check Graph connection
                try {
                    $context = Get-MgContext
                    if (-not $context) {
                        throw "Not connected to Microsoft Graph. Please run: Connect-MgGraph -Scopes 'Domain.Read.All'"
                    }
                }
                catch {
                    throw "Microsoft Graph connection error: $_`n`nPlease connect: Connect-MgGraph -Scopes 'Domain.Read.All'"
                }
            }
        }

        $comparisonResults = @()
    }

    process {
        try {
            # Load baseline if doing diff
            $baseline = $null
            if ($CompareToBaseline) {
                if (-not (Test-Path $BaselinePath)) {
                    throw "Baseline file not found: $BaselinePath"
                }

                Write-Information "Loading baseline from: $BaselinePath" -InformationAction Continue
                $baseline = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
            }

            # If no domain specified, get all verified domains
            if (-not $Name) {
                if ($CompareToBaseline -and $baseline) {
                    # Get domains from baseline
                    $Name = $baseline.Domain | Select-Object -Unique
                }
                elseif ($usingOffline) {
                    # Get domains from CSV/JSON
                    $Name = $offlineRecords | Select-Object -ExpandProperty Domain -Unique
                    $sourceType = if ($usingCSV) { "CSV" } else { "JSON" }
                    Write-Verbose "Found $($Name.Count) unique domain(s) in $sourceType"
                }
                else {
                    Write-Verbose "No domain specified, retrieving all verified domains"
                    $domains = Get-MgDomain -All | Where-Object { $_.IsVerified -eq $true }
                    $Name = $domains.Id
                }
            }

            foreach ($domain in $Name) {
                Write-Information "`nComparing DNS records for: $domain" -InformationAction Continue

                # Get expected records from CSV, baseline, or Graph API
                if ($CompareToBaseline -and $baseline) {
                    Write-Verbose "Using baseline as expected state"
                    $expectedRecords = $baseline | Where-Object { $_.Domain -eq $domain }
                }
                elseif ($usingOffline) {
                    $sourceType = if ($usingCSV) { "CSV" } else { "JSON" }
                    Write-Verbose "Loading expected DNS records from $sourceType for $domain"
                    $expectedRecords = $offlineRecords | Where-Object { $_.Domain -eq $domain }

                    if (-not $expectedRecords) {
                        Write-Warning "No records found for $domain in $sourceType file"
                        continue
                    }
                }
                else {
                    Write-Verbose "Retrieving expected DNS records from Microsoft Graph"
                    $expectedRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain -ErrorAction SilentlyContinue

                    if (-not $expectedRecords) {
                        Write-Warning "No expected DNS records found for $domain"
                        continue
                    }
                }

                foreach ($record in $expectedRecords) {
                    # Extract record type and label based on source
                    if ($usingOffline) {
                        $recordType = $record.RecordType
                        $label = $record.Label
                    }
                    elseif ($CompareToBaseline) {
                        $recordType = $record.RecordType
                        $label = $record.Label
                    }
                    else {
                        $recordType = $record.AdditionalProperties['recordType']
                        $label = $record.Label
                    }

                    $fqdn = if ($label -eq '@') { $domain } else { "$label.$domain" }

                    $comparison = [PSCustomObject]@{
                        Domain          = $domain
                        RecordType      = $recordType
                        Label           = $label
                        FQDN            = $fqdn
                        ExpectedValue   = $null
                        ActualValue     = $null
                        Status          = "Unknown"
                        SupportedService = if ($usingOffline) { $record.Notes } elseif ($CompareToBaseline) { $record.SupportedService } else { $record.SupportedService }
                        IsOptional      = if ($usingOffline) { $false } elseif ($CompareToBaseline) { $record.IsOptional } else { $record.IsOptional }
                        TTL             = if ($usingOffline) { $record.TTL } elseif ($CompareToBaseline) { $record.TTL } else { $record.Ttl }
                        Details         = $null
                    }

                    # Prepare DNS query parameters
                    $dnsParams = @{
                        Method = $Method
                    }
                    if ($Server) { $dnsParams['Server'] = $Server }

                    # Get expected value based on record type
                    switch ($recordType) {
                        'MX' {
                            if ($usingOffline) {
                                $comparison.ExpectedValue = $record.ExpectedValue
                            }
                            elseif ($CompareToBaseline) {
                                $comparison.ExpectedValue = $record.ExpectedValue
                            }
                            else {
                                $comparison.ExpectedValue = "$($record.AdditionalProperties['preference']) $($record.AdditionalProperties['mailExchange'])"
                            }

                            try {
                                $actual = Invoke-DnsQuery -Name $fqdn -Type MX @dnsParams
                                if ($actual) {
                                    $primaryMX = $actual | Sort-Object Preference | Select-Object -First 1
                                    $comparison.ActualValue = "$($primaryMX.Preference) $($primaryMX.NameExchange)"

                                    if ($usingOffline -or $CompareToBaseline) {
                                        # For CSV/JSON/baseline, extract hostname from "priority hostname" format
                                        $expectedMX = if ($record.ExpectedValue -match '\d+\s+(.+)') { $Matches[1] } else { $record.ExpectedValue }
                                    }
                                    else {
                                        $expectedMX = $record.AdditionalProperties['mailExchange']
                                    }

                                    if ($primaryMX.NameExchange -eq $expectedMX) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected: $expectedMX, Got: $($primaryMX.NameExchange)"
                                    }

                                    # Check for legacy MX format
                                    if ($primaryMX.NameExchange -like "*.mail.protection.outlook.com") {
                                        $comparison.Details += " | NOTE: Legacy MX format detected"
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
                            if ($usingOffline) {
                                $comparison.ExpectedValue = $record.ExpectedValue
                                $expectedCName = $record.ExpectedValue
                            }
                            elseif ($CompareToBaseline) {
                                $comparison.ExpectedValue = $record.ExpectedValue
                                $expectedCName = $record.ExpectedValue
                            }
                            else {
                                $comparison.ExpectedValue = $record.AdditionalProperties['canonicalName']
                                $expectedCName = $record.AdditionalProperties['canonicalName']
                            }

                            try {
                                $actual = Invoke-DnsQuery -Name $fqdn -Type CNAME @dnsParams
                                if ($actual) {
                                    $comparison.ActualValue = $actual.NameHost

                                    if ($actual.NameHost -eq $expectedCName) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected: $expectedCName, Got: $($actual.NameHost)"
                                    }

                                    # Check for legacy DKIM format
                                    if ($label -like "selector*._domainkey" -and $actual.NameHost -like "*._domainkey.*.onmicrosoft.com") {
                                        $comparison.Details += " | NOTE: Legacy DKIM format"
                                    }

                                    # Check for legacy Skype for Business
                                    if ($label -eq "sip" -or $label -eq "lyncdiscover") {
                                        $comparison.Details += " | NOTE: Legacy Skype for Business (not required for Teams-only)"
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
                            if ($usingOffline) {
                                $comparison.ExpectedValue = $record.ExpectedValue
                                $expectedText = $record.ExpectedValue
                            }
                            elseif ($CompareToBaseline) {
                                $comparison.ExpectedValue = $record.ExpectedValue
                                $expectedText = $record.ExpectedValue
                            }
                            else {
                                $comparison.ExpectedValue = $record.AdditionalProperties['text']
                                $expectedText = $record.AdditionalProperties['text']
                            }

                            try {
                                $actual = Invoke-DnsQuery -Name $fqdn -Type TXT @dnsParams
                                if ($actual) {
                                    $txtValue = ($actual.Strings -join "")
                                    $comparison.ActualValue = $txtValue

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
                            if ($usingOffline -or $CompareToBaseline) {
                                $comparison.FQDN = $record.FQDN
                                $comparison.ExpectedValue = $record.ExpectedValue
                                $srvFqdn = $record.FQDN

                                # Parse expected value (format: priority weight port target)
                                $parts = $record.ExpectedValue -split ' '
                                $target = $parts[3]
                                $port = $parts[2]
                            }
                            else {
                                $service = $record.AdditionalProperties['service']
                                $protocol = $record.AdditionalProperties['protocol']
                                $srvFqdn = "$service.$protocol.$domain"
                                $comparison.FQDN = $srvFqdn

                                $priority = $record.AdditionalProperties['priority']
                                $weight = $record.AdditionalProperties['weight']
                                $port = $record.AdditionalProperties['port']
                                $target = $record.AdditionalProperties['nameTarget']

                                $comparison.ExpectedValue = "$priority $weight $port $target"
                            }

                            try {
                                $actual = Invoke-DnsQuery -Name $srvFqdn -Type SRV @dnsParams
                                if ($actual) {
                                    $comparison.ActualValue = "$($actual.Priority) $($actual.Weight) $($actual.Port) $($actual.NameTarget)"

                                    if ($actual.NameTarget -eq $target -and $actual.Port -eq $port) {
                                        $comparison.Status = "Match"
                                    }
                                    else {
                                        $comparison.Status = "Mismatch"
                                        $comparison.Details = "Expected: ${target}:${port}, Got: $($actual.NameTarget):$($actual.Port)"
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

                # Check for optional records if requested (and not in baseline mode)
                if ($IncludeOptional -and -not $CompareToBaseline) {
                    # Check DMARC
                    Write-Verbose "Checking DMARC record"
                    try {
                        $dmarc = Invoke-DnsQuery -Name "_dmarc.$domain" -Type TXT @dnsParams
                        $dmarcComparison = [PSCustomObject]@{
                            Domain           = $domain
                            RecordType       = "TXT"
                            Label            = "_dmarc"
                            FQDN             = "_dmarc.$domain"
                            ExpectedValue    = "v=DMARC1 (MANDATORY April 2025)"
                            ActualValue      = if ($dmarc) { ($dmarc.Strings -join "") } else { "(not found)" }
                            Status           = if ($dmarc) { "Present" } else { "CRITICAL - Missing" }
                            SupportedService = "Email Security"
                            IsOptional       = $false
                            TTL              = if ($dmarc) { $dmarc.TTL } else { $null }
                            Details          = if (-not $dmarc) { "CRITICAL: DMARC MANDATORY starting April 2025" } else { $null }
                        }
                        $comparisonResults += $dmarcComparison
                    }
                    catch {
                        Write-Verbose "Failed to check DMARC: $_"
                    }

                    # Check for deprecated MSOID
                    Write-Verbose "Checking for deprecated MSOID record"
                    try {
                        $msoid = Invoke-DnsQuery -Name "msoid.$domain" -Type CNAME @dnsParams
                        if ($msoid) {
                            $msoidComparison = [PSCustomObject]@{
                                Domain           = $domain
                                RecordType       = "CNAME"
                                Label            = "msoid"
                                FQDN             = "msoid.$domain"
                                ExpectedValue    = "(should not exist - DEPRECATED)"
                                ActualValue      = $msoid.NameHost
                                Status           = "DEPRECATED - REMOVE"
                                SupportedService = "Deprecated"
                                IsOptional       = $false
                                TTL              = $msoid.TTL
                                Details          = "CRITICAL: Remove this record - blocks Microsoft 365 Apps activation"
                            }
                            $comparisonResults += $msoidComparison
                        }
                    }
                    catch {
                        # Intentionally empty - msoid record should not exist for non-federated domains
                        Write-Verbose "No msoid record found (expected for non-federated domains)"
                    }
                }
            }

            # Save baseline if requested
            if ($SaveBaseline) {
                Write-Information "`nSaving baseline to: $BaselinePath" -InformationAction Continue
                $comparisonResults | ConvertTo-Json -Depth 10 | Set-Content -Path $BaselinePath
                Write-Information "Baseline saved successfully" -InformationAction Continue
            }

            # Display summary
            Write-Information "`n=== DNS Comparison Summary ===" -InformationAction Continue

            $totalRecords = $comparisonResults.Count
            $matchCount = ($comparisonResults | Where-Object { $_.Status -eq "Match" }).Count
            $mismatches = ($comparisonResults | Where-Object { $_.Status -eq "Mismatch" }).Count
            $missing = ($comparisonResults | Where-Object { $_.Status -eq "Missing" }).Count
            $deprecated = ($comparisonResults | Where-Object { $_.Status -like "*DEPRECATED*" }).Count

            Write-Information "Total Records Checked: $totalRecords" -InformationAction Continue
            Write-Information "Matches: $matchCount" -InformationAction Continue
            Write-Information "Mismatches: $mismatches" -InformationAction Continue
            Write-Information "Missing: $missing" -InformationAction Continue
            if ($deprecated -gt 0) {
                Write-Information "Deprecated (REMOVE): $deprecated" -InformationAction Continue
            }

            # Show details if requested
            if ($ShowOnlyDifference) {
                $differences = $comparisonResults | Where-Object { $_.Status -ne "Match" }
                if ($differences) {
                    Write-Information "`nDifferences Found:" -InformationAction Continue
                    $differences | Format-Table Domain, RecordType, Label, Status, ExpectedValue, ActualValue -AutoSize
                }
                else {
                    Write-Information "`nNo differences found - all DNS records match!" -InformationAction Continue
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
                Write-Information "`nReport exported to: $reportFile" -InformationAction Continue
            }

            return $comparisonResults
        }
        catch {
            Write-Error "Failed to compare DNS records: $_"
            throw
        }
    }
}
