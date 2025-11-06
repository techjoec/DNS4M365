function Test-M365DnsCompliance {
    <#
    .SYNOPSIS
        Validates Microsoft 365 DNS configuration compliance and health.

    .DESCRIPTION
        Comprehensive DNS validation for Microsoft 365 custom domains. Performs health checks,
        compliance assessment, format validation, and security posture analysis.

        Consolidates three validation scenarios:
        1. DNS Health: Compares expected (Graph API) vs actual (DNS) records
        2. Compliance Assessment: Modern format validation, scoring, priority assignment
        3. Verification Status: Domain verification state and readiness

        Checks performed:
        - MX, CNAME, TXT, SRV record validation
        - Email authentication (SPF, DMARC, DKIM)
        - Deprecated record detection (msoid, legacy Skype)
        - Format compliance (legacy vs modern MX/DKIM)
        - Domain verification status
        - Overall DNS health and compliance scoring

    .PARAMETER Name
        The domain name(s) to validate. If not specified, validates all verified domains.

    .PARAMETER CSVPath
        Path to CSV file containing expected DNS records for offline validation.
        Use this to validate DNS without requiring live Microsoft Graph API or Exchange Online access.
        See Templates/expected-dns-records-template.csv for format.
        Mutually exclusive with -JSONPath.

    .PARAMETER JSONPath
        Path to JSON file containing expected DNS records for offline validation.
        Use this to validate DNS without requiring live Microsoft Graph API or Exchange Online access.
        See Templates/expected-dns-records-template.json for format.
        Mutually exclusive with -CSVPath.

    .PARAMETER UseExchangeOnline
        Automatically retrieve DKIM selector CNAMEs using Exchange Online PowerShell (Get-DkimSigningConfig).
        Requires Exchange Online connection. Run: Connect-ExchangeOnline

    .PARAMETER IncludeSPF
        Validate SPF TXT records for email authentication.

    .PARAMETER IncludeDMARC
        Check for DMARC TXT records (_dmarc.domain.com).

    .PARAMETER CheckDKIM
        Verify DKIM CNAME records resolve to Microsoft infrastructure.
        When used with -UseExchangeOnline, automatically retrieves expected DKIM values.

    .PARAMETER CheckMTASTS
        Validate MTA-STS TXT record (_mta-sts.domain.com) for email encryption policy.

    .PARAMETER CheckDeprecated
        Check for deprecated records (msoid, legacy Skype for Business).

    .PARAMETER CheckSRV
        Validate SRV records for Teams/Skype for Business.

    .PARAMETER CheckVerification
        Include domain verification status in results.

    .PARAMETER Method
        DNS query method: Standard (Resolve-DnsName) or DoH (DNS-over-HTTPS).
        Default: Standard

    .PARAMETER Server
        DNS server to query (only with Standard method). Examples: 8.8.8.8, 1.1.1.1

    .PARAMETER ShowRecommendations
        Display detailed recommendations for improving DNS configuration.

    .PARAMETER DetailedOutput
        Include detailed resolution information for each record.

    .EXAMPLE
        Test-M365DnsCompliance -Name "contoso.com"
        Basic DNS compliance check for contoso.com using Graph API.

    .EXAMPLE
        Test-M365DnsCompliance -Name "contoso.com" -IncludeSPF -IncludeDMARC -CheckDKIM -UseExchangeOnline
        Comprehensive email security validation with automatic DKIM validation via Exchange Online.

    .EXAMPLE
        Test-M365DnsCompliance -CSVPath ".\Templates\expected-dns-records-template.csv"
        Offline validation using CSV file (no live API access required).

    .EXAMPLE
        Test-M365DnsCompliance -JSONPath ".\Templates\expected-dns-records-template.json"
        Offline validation using JSON file (no live API access required).

    .EXAMPLE
        Test-M365DnsCompliance -Name "contoso.com" -CheckMTASTS -IncludeDMARC
        Email security validation including MTA-STS and DMARC.

    .EXAMPLE
        Test-M365DnsCompliance -CheckDeprecated -ShowRecommendations
        Check all domains for deprecated records with recommendations.

    .EXAMPLE
        Test-M365DnsCompliance -CheckVerification
        Verify domain ownership status for all domains.

    .EXAMPLE
        Test-M365DnsCompliance -Name "contoso.com" -Method DoH
        DNS compliance check using DNS-over-HTTPS.

    .OUTPUTS
        Custom object array containing comprehensive DNS validation results.

    .NOTES
        Authentication Requirements:
        - Microsoft Graph: Connect-MgGraph -Scopes "Domain.Read.All"
        - Exchange Online (for DKIM): Connect-ExchangeOnline

        CSV/JSON-based validation does not require any authentication (offline mode).

        MTA-STS is recommended for enhanced email security but not required by Microsoft 365.
    #>

    [CmdletBinding()]
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
        [switch]$UseExchangeOnline,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSPF,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDMARC,

        [Parameter(Mandatory = $false)]
        [switch]$CheckDKIM,

        [Parameter(Mandatory = $false)]
        [switch]$CheckMTASTS,

        [Parameter(Mandatory = $false)]
        [switch]$CheckDeprecated,

        [Parameter(Mandatory = $false)]
        [switch]$CheckSRV,

        [Parameter(Mandatory = $false)]
        [switch]$CheckVerification,

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

        [Parameter(Mandatory = $false)]
        [switch]$ShowRecommendations,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )

    begin {
        Write-Verbose "Starting DNS compliance validation"

        # Check for mutual exclusivity
        $usingCSV = $PSBoundParameters.ContainsKey('CSVPath')
        $usingJSON = $PSBoundParameters.ContainsKey('JSONPath')

        if ($usingCSV -and $usingJSON) {
            throw "Cannot specify both -CSVPath and -JSONPath. Please use only one offline validation method."
        }

        # Determine validation mode
        $offlineRecords = $null
        $usingOffline = $usingCSV -or $usingJSON

        if ($usingCSV) {
            Write-Verbose "Using CSV-based offline validation mode"
            try {
                $offlineRecords = Import-Csv -Path $CSVPath
                Write-Verbose "Loaded $($offlineRecords.Count) records from CSV"
            }
            catch {
                throw "Failed to import CSV file: $_"
            }
        }
        elseif ($usingJSON) {
            Write-Verbose "Using JSON-based offline validation mode"
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
            # Check Microsoft Graph module availability (required for online validation)
            Write-Verbose "Using online validation mode (Microsoft Graph API)"

            # Check if Microsoft.Graph.Authentication module is available
            $graphAuthModule = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication | Select-Object -First 1
            if (-not $graphAuthModule) {
                throw @"
Microsoft Graph module not installed.

OPTION 1: Install Microsoft Graph modules (for Graph API validation):
    Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -Scope CurrentUser
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -MinimumVersion 2.0.0 -Scope CurrentUser
    Connect-MgGraph -Scopes 'Domain.Read.All'

OPTION 2: Use CSV/JSON-based offline validation (no dependencies required):
    Test-M365DnsCompliance -CSVPath ".\expected-dns-records.csv"
    Test-M365DnsCompliance -JSONPath ".\expected-dns-records.json"
    (See Templates/ for template files)
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

        # Check Exchange Online connection if DKIM validation with Exchange requested
        if ($UseExchangeOnline -and $CheckDKIM) {
            Write-Verbose "Checking Exchange Online connection for DKIM validation"

            # Check if ExchangeOnlineManagement module is available
            $exoModule = Get-Module -ListAvailable -Name ExchangeOnlineManagement | Select-Object -First 1
            if (-not $exoModule) {
                Write-Warning @"
ExchangeOnlineManagement module not installed. DKIM validation will use Graph API records only.

To enable automatic DKIM validation via Exchange Online PowerShell:
    Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0 -Scope CurrentUser
    Connect-ExchangeOnline
"@
                $UseExchangeOnline = $false
            }
            else {
                # Check connection
                try {
                    $exoSession = Get-PSSession | Where-Object { $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened' }
                    if (-not $exoSession) {
                        Write-Warning "Exchange Online not connected. DKIM validation will use Graph API records only. Run: Connect-ExchangeOnline"
                        $UseExchangeOnline = $false
                    }
                }
                catch {
                    Write-Warning "Could not verify Exchange Online connection: $_"
                    $UseExchangeOnline = $false
                }
            }
        }

        $complianceResults = @()
    }

    process {
        try {
            # Determine which domains to validate
            if ($usingOffline) {
                # Get unique domains from CSV/JSON
                if (-not $Name) {
                    $Name = $offlineRecords | Select-Object -ExpandProperty Domain -Unique
                    $sourceType = if ($usingCSV) { "CSV" } else { "JSON" }
                    Write-Verbose "Found $($Name.Count) unique domain(s) in $sourceType"
                }
            }
            else {
                # Get domains from Graph API
                if (-not $Name) {
                    Write-Verbose "No domain specified, retrieving all verified domains"
                    $domains = Get-MgDomain -All | Where-Object { $_.IsVerified -eq $true }
                    $Name = $domains.Id
                }
            }

            foreach ($domain in $Name) {
                Write-Information "`nValidating DNS compliance for: $domain" -InformationAction Continue

                # Get domain information
                $domainInfo = $null
                if (-not $usingOffline) {
                    try {
                        $domainInfo = Get-MgDomain -DomainId $domain -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Failed to retrieve domain $domain : $_"
                        continue
                    }
                }

                # Initialize compliance result
                $offlineMode = if ($usingOffline) {
                    if ($usingCSV) { "CSV mode" } else { "JSON mode" }
                } else {
                    $null
                }
                $compliance = [PSCustomObject]@{
                    Domain              = $domain
                    IsVerified          = if ($domainInfo) { $domainInfo.IsVerified } elseif ($offlineMode) { "Unknown ($offlineMode)" } else { "Unknown" }
                    OverallHealth       = "Unknown"
                    ComplianceScore     = 0
                    MXStatus            = "Unknown"
                    MXFormat            = "Unknown"
                    UsingLegacyMX       = $false
                    DKIMStatus          = "Unknown"
                    DKIMFormat          = "Unknown"
                    UsingLegacyDKIM     = $false
                    SPFStatus           = if ($IncludeSPF) { "Unknown" } else { "Not Checked" }
                    DMARCStatus         = if ($IncludeDMARC) { "Unknown" } else { "Not Checked" }
                    MTASTSStatus        = if ($CheckMTASTS) { "Unknown" } else { "Not Checked" }
                    DeprecatedRecords   = if ($CheckDeprecated) { @() } else { "Not Checked" }
                    SRVStatus           = if ($CheckSRV) { "Unknown" } else { "Not Checked" }
                    Issues              = @()
                    Recommendations     = @()
                }

                # Get expected DNS records (from CSV/JSON or Graph API)
                $expectedRecords = $null
                if ($usingOffline) {
                    $sourceType = if ($usingCSV) { "CSV" } else { "JSON" }
                    Write-Verbose "Loading expected DNS records from $sourceType for $domain"
                    $expectedRecords = $offlineRecords | Where-Object { $_.Domain -eq $domain }

                    if (-not $expectedRecords) {
                        $compliance.OverallHealth = "Warning"
                        $compliance.Issues += "No records found for $domain in $sourceType file"
                        $complianceResults += $compliance
                        continue
                    }
                }
                else {
                    Write-Verbose "Retrieving expected DNS configuration from Microsoft Graph"
                    $expectedRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain -ErrorAction SilentlyContinue

                    if (-not $expectedRecords) {
                        $compliance.OverallHealth = "Warning"
                        $compliance.Issues += "No service configuration records found in Microsoft Graph"
                        $complianceResults += $compliance
                        continue
                    }
                }

                # Initialize scoring
                $totalChecks = 0
                $passedChecks = 0

                # === MX RECORD VALIDATION ===
                if ($usingOffline) {
                    $mxRecords = $expectedRecords | Where-Object { $_.RecordType -eq 'MX' }
                }
                else {
                    $mxRecords = $expectedRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Mx' }
                }

                if ($mxRecords) {
                    $totalChecks++
                    if ($usingOffline) {
                        $expectedMX = $mxRecords[0].ExpectedValue
                    }
                    else {
                        $expectedMX = $mxRecords[0].AdditionalProperties['mailExchange']
                    }

                    Write-Verbose "Querying DNS for MX record: $domain"
                    $dnsParams = @{
                        Name = $domain
                        Type = 'MX'
                        Method = $Method
                    }
                    if ($Server) { $dnsParams['Server'] = $Server }

                    $actualMX = Invoke-DnsQuery @dnsParams

                    if ($actualMX) {
                        if ($actualMX.NameExchange -eq $expectedMX) {
                            $compliance.MXStatus = "Valid"
                            $passedChecks++
                        }
                        else {
                            $compliance.MXStatus = "Mismatch"
                            $compliance.Issues += "MX mismatch - Expected: $expectedMX, Actual: $($actualMX.NameExchange)"
                            $compliance.Recommendations += "Update MX record to point to: $expectedMX"
                        }

                        # Check MX format (legacy vs modern)
                        if ($expectedMX -like "*mail.protection.outlook.com") {
                            $compliance.MXFormat = "Legacy"
                            $compliance.UsingLegacyMX = $true
                            $compliance.Recommendations += "Consider migrating to modern MX format (*.mx.microsoft) when available"
                        }
                        elseif ($expectedMX -like "*.mx.microsoft") {
                            $compliance.MXFormat = "Modern"
                            $compliance.UsingLegacyMX = $false
                        }
                        else {
                            $compliance.MXFormat = "Unknown"
                        }
                    }
                    else {
                        $compliance.MXStatus = "Missing"
                        $compliance.Issues += "MX record not found in DNS"
                        $compliance.Recommendations += "Add MX record: $expectedMX"
                    }
                }

                # === DKIM VALIDATION ===
                $dkimRecords = @()

                # Get DKIM records from Exchange Online PowerShell if requested
                if ($UseExchangeOnline -and $CheckDKIM) {
                    Write-Verbose "Retrieving DKIM configuration from Exchange Online PowerShell"
                    try {
                        $dkimConfig = Get-DkimSigningConfig -Identity $domain -ErrorAction Stop

                        if ($dkimConfig) {
                            # Create pseudo-records from Exchange Online data
                            if ($dkimConfig.Selector1CNAME) {
                                $dkimRecords += [PSCustomObject]@{
                                    Label = "selector1._domainkey"
                                    ExpectedValue = $dkimConfig.Selector1CNAME
                                    Source = "ExchangeOnline"
                                }
                            }
                            if ($dkimConfig.Selector2CNAME) {
                                $dkimRecords += [PSCustomObject]@{
                                    Label = "selector2._domainkey"
                                    ExpectedValue = $dkimConfig.Selector2CNAME
                                    Source = "ExchangeOnline"
                                }
                            }
                        }
                    }
                    catch {
                        Write-Warning "Failed to get DKIM config from Exchange Online: $_"
                    }
                }
                # Otherwise get from CSV/JSON or Graph API
                elseif ($usingOffline) {
                    $dkimRecords = $expectedRecords | Where-Object { $_.RecordType -eq 'CNAME' -and $_.Label -like '*._domainkey*' }
                }
                else {
                    $dkimRecords = $expectedRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'CName' -and $_.AdditionalProperties['label'] -like '*._domainkey.*' }
                }

                if ($dkimRecords) {
                    $totalChecks++
                    $dkimValid = $true

                    foreach ($dkimRecord in $dkimRecords) {
                        # Extract label and expected CNAME based on source
                        if ($dkimRecord.Source -eq "ExchangeOnline") {
                            $dkimLabel = $dkimRecord.Label
                            $expectedCName = $dkimRecord.ExpectedValue
                        }
                        elseif ($usingOffline) {
                            $dkimLabel = $dkimRecord.Label
                            $expectedCName = $dkimRecord.ExpectedValue
                        }
                        else {
                            $dkimLabel = $dkimRecord.AdditionalProperties['label']
                            $expectedCName = $dkimRecord.AdditionalProperties['canonicalName']
                        }

                        Write-Verbose "Querying DNS for DKIM CNAME: $dkimLabel.$domain"
                        $dnsParams = @{
                            Name = "$dkimLabel.$domain"
                            Type = 'CNAME'
                            Method = $Method
                        }
                        if ($Server) { $dnsParams['Server'] = $Server }

                        $actualCName = Invoke-DnsQuery @dnsParams

                        if ($actualCName) {
                            if ($actualCName.NameHost -eq $expectedCName) {
                                # Check if DKIM resolves to Microsoft (if requested)
                                if ($CheckDKIM) {
                                    $totalChecks++
                                    $finalTarget = Invoke-DnsQuery -Name $actualCName.NameHost -Type 'CNAME' -Method $Method
                                    if ($finalTarget -and ($finalTarget.NameHost -like "*.microsoft*" -or $finalTarget.NameHost -like "*dkim.mail.microsoft*")) {
                                        $compliance.DKIMStatus = "Valid"
                                        $passedChecks++
                                    }
                                    else {
                                        $compliance.DKIMStatus = "Warning"
                                        $compliance.Issues += "DKIM record exists but resolution unclear"
                                    }
                                }
                                else {
                                    $compliance.DKIMStatus = "Valid"
                                }

                                # Check DKIM format
                                if ($expectedCName -like "*.onmicrosoft.com") {
                                    $compliance.DKIMFormat = "Legacy"
                                    $compliance.UsingLegacyDKIM = $true
                                    $compliance.Recommendations += "Consider migrating to modern DKIM format (*.dkim.mail.microsoft) for new deployments"
                                }
                                elseif ($expectedCName -like "*dkim.mail.microsoft*") {
                                    $compliance.DKIMFormat = "Modern"
                                    $compliance.UsingLegacyDKIM = $false
                                }
                            }
                            else {
                                $dkimValid = $false
                                $compliance.Issues += "DKIM CNAME mismatch - Label: $dkimLabel, Expected: $expectedCName, Actual: $($actualCName.NameHost)"
                            }
                        }
                        else {
                            $dkimValid = $false
                            $compliance.DKIMStatus = "Missing"
                            $compliance.Issues += "DKIM CNAME missing: $dkimLabel.$domain"
                            $compliance.Recommendations += "Add DKIM CNAME: $dkimLabel.$domain -> $expectedCName"
                        }
                    }

                    if ($dkimValid -and $compliance.DKIMStatus -ne "Missing") {
                        $passedChecks++
                    }
                }

                # === SPF VALIDATION ===
                if ($IncludeSPF) {
                    $totalChecks++
                    Write-Verbose "Checking SPF record for $domain"

                    $dnsParams = @{
                        Name = $domain
                        Type = 'TXT'
                        Method = $Method
                    }
                    if ($Server) { $dnsParams['Server'] = $Server }

                    $txtRecords = Invoke-DnsQuery @dnsParams

                    $spfRecord = $txtRecords | Where-Object { $_.Strings -like "v=spf1*" }
                    if ($spfRecord) {
                        if ($spfRecord.Strings -like "*include:spf.protection.outlook.com*") {
                            $compliance.SPFStatus = "Valid"
                            $passedChecks++
                        }
                        else {
                            $compliance.SPFStatus = "Warning"
                            $compliance.Issues += "SPF record exists but may not include Microsoft 365"
                            $compliance.Recommendations += "Ensure SPF includes: include:spf.protection.outlook.com"
                        }
                    }
                    else {
                        $compliance.SPFStatus = "Missing"
                        $compliance.Issues += "SPF record not found (required for email authentication)"
                        $compliance.Recommendations += "Add SPF record: v=spf1 include:spf.protection.outlook.com -all"
                    }
                }

                # === DMARC VALIDATION ===
                if ($IncludeDMARC) {
                    $totalChecks++
                    Write-Verbose "Checking DMARC record for $domain"

                    $dnsParams = @{
                        Name = "_dmarc.$domain"
                        Type = 'TXT'
                        Method = $Method
                    }
                    if ($Server) { $dnsParams['Server'] = $Server }

                    $dmarcRecord = Invoke-DnsQuery @dnsParams

                    if ($dmarcRecord -and $dmarcRecord.Strings -like "v=DMARC1*") {
                        $compliance.DMARCStatus = "Valid"
                        $passedChecks++
                    }
                    else {
                        $compliance.DMARCStatus = "Missing"
                        $compliance.Issues += "DMARC record not found (required by April 2025 mandate)"
                        $compliance.Recommendations += "Add DMARC record at _dmarc.$domain (use New-M365DmarcRecord)"
                    }
                }

                # === MTA-STS VALIDATION ===
                if ($CheckMTASTS) {
                    $totalChecks++
                    Write-Verbose "Checking MTA-STS record for $domain"

                    $dnsParams = @{
                        Name = "_mta-sts.$domain"
                        Type = 'TXT'
                        Method = $Method
                    }
                    if ($Server) { $dnsParams['Server'] = $Server }

                    $mtastsRecord = Invoke-DnsQuery @dnsParams

                    if ($mtastsRecord -and $mtastsRecord.Strings -like "v=STSv1*") {
                        $compliance.MTASTSStatus = "Valid"
                        $passedChecks++
                    }
                    else {
                        $compliance.MTASTSStatus = "Missing"
                        $compliance.Issues += "MTA-STS record not found (recommended for enhanced email security)"
                        $compliance.Recommendations += "Consider adding MTA-STS record at _mta-sts.$domain for email encryption enforcement"
                    }
                }

                # === DEPRECATED RECORDS CHECK ===
                if ($CheckDeprecated) {
                    Write-Verbose "Checking for deprecated records"

                    # Check for msoid (deprecated Azure AD join method)
                    $dnsParams = @{
                        Name = "msoid.$domain"
                        Type = 'CNAME'
                        Method = $Method
                    }
                    if ($Server) { $dnsParams['Server'] = $Server }

                    $msoid = Invoke-DnsQuery @dnsParams
                    if ($msoid) {
                        $compliance.DeprecatedRecords += "msoid CNAME (deprecated - use enterpriseregistration instead)"
                        $compliance.Recommendations += "Remove deprecated msoid CNAME record"
                    }

                    # Could add more deprecated record checks here
                    if ($compliance.DeprecatedRecords.Count -eq 0) {
                        $compliance.DeprecatedRecords = @()
                    }
                }

                # === SRV RECORDS VALIDATION ===
                if ($CheckSRV) {
                    $srvRecords = $expectedRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Srv' }
                    if ($srvRecords) {
                        $totalChecks++
                        $srvValid = $true

                        foreach ($srvRecord in $srvRecords) {
                            $srvLabel = $srvRecord.AdditionalProperties['label']
                            $expectedTarget = $srvRecord.AdditionalProperties['nameTarget']

                            Write-Verbose "Querying DNS for SRV record: $srvLabel.$domain"
                            $dnsParams = @{
                                Name = "$srvLabel.$domain"
                                Type = 'SRV'
                                Method = $Method
                            }
                            if ($Server) { $dnsParams['Server'] = $Server }

                            $actualSRV = Invoke-DnsQuery @dnsParams

                            if (-not $actualSRV -or $actualSRV.NameTarget -ne $expectedTarget) {
                                $srvValid = $false
                                $compliance.Issues += "SRV record issue: $srvLabel.$domain"
                            }
                        }

                        if ($srvValid) {
                            $compliance.SRVStatus = "Valid"
                            $passedChecks++
                        }
                        else {
                            $compliance.SRVStatus = "Issues Found"
                        }
                    }
                }

                # === CALCULATE OVERALL HEALTH AND COMPLIANCE SCORE ===
                if ($totalChecks -gt 0) {
                    $compliance.ComplianceScore = [math]::Round(($passedChecks / $totalChecks) * 100)

                    if ($compliance.ComplianceScore -ge 90) {
                        $compliance.OverallHealth = "Healthy"
                    }
                    elseif ($compliance.ComplianceScore -ge 70) {
                        $compliance.OverallHealth = "Warning"
                    }
                    else {
                        $compliance.OverallHealth = "Critical"
                    }
                }

                # Display summary
                Write-Information "  Overall Health: $($compliance.OverallHealth) ($($compliance.ComplianceScore)%)" -InformationAction Continue
                Write-Information "  MX Status: $($compliance.MXStatus) ($($compliance.MXFormat))" -InformationAction Continue

                if ($compliance.DKIMStatus -ne "Unknown") {
                    Write-Information "  DKIM Status: $($compliance.DKIMStatus) ($($compliance.DKIMFormat))" -InformationAction Continue
                }

                if ($IncludeSPF) {
                    Write-Information "  SPF Status: $($compliance.SPFStatus)" -InformationAction Continue
                }

                if ($IncludeDMARC) {
                    Write-Information "  DMARC Status: $($compliance.DMARCStatus)" -InformationAction Continue
                }

                if ($CheckMTASTS) {
                    Write-Information "  MTA-STS Status: $($compliance.MTASTSStatus)" -InformationAction Continue
                }

                # Show issues
                if ($compliance.Issues.Count -gt 0) {
                    Write-Information "`n  Issues Found:" -InformationAction Continue
                    $compliance.Issues | ForEach-Object { Write-Information "    - $_" -InformationAction Continue }
                }

                # Show recommendations if requested
                if ($ShowRecommendations -and $compliance.Recommendations.Count -gt 0) {
                    Write-Information "`n  Recommendations:" -InformationAction Continue
                    $compliance.Recommendations | ForEach-Object { Write-Information "    - $_" -InformationAction Continue }
                }

                $complianceResults += $compliance
            }

            return $complianceResults
        }
        catch {
            Write-Error "DNS compliance validation failed: $_"
            throw
        }
    }
}
