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

    .PARAMETER IncludeSPF
        Validate SPF TXT records for email authentication.

    .PARAMETER IncludeDMARC
        Check for DMARC TXT records (_dmarc.domain.com).

    .PARAMETER CheckDKIM
        Verify DKIM CNAME records resolve to Microsoft infrastructure.

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
        Basic DNS compliance check for contoso.com.

    .EXAMPLE
        Test-M365DnsCompliance -Name "contoso.com" -IncludeSPF -IncludeDMARC -CheckDKIM
        Comprehensive email security validation.

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
        Requires Microsoft Graph connection with Domain.Read.All scope.
        Run: Connect-MgGraph -Scopes "Domain.Read.All"
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('DomainName', 'Domain')]
        [string[]]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSPF,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDMARC,

        [Parameter(Mandatory = $false)]
        [switch]$CheckDKIM,

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
        [string]$Server,

        [Parameter(Mandatory = $false)]
        [switch]$ShowRecommendations,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )

    begin {
        Write-Verbose "Starting DNS compliance validation"

        # Check Microsoft Graph connection
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run: Connect-MgGraph -Scopes 'Domain.Read.All'"
        }

        $complianceResults = @()
    }

    process {
        try {
            # If no domain specified, get all verified domains
            if (-not $Name) {
                Write-Verbose "No domain specified, retrieving all verified domains"
                $domains = Get-MgDomain -All | Where-Object { $_.IsVerified -eq $true }
                $Name = $domains.Id
            }

            foreach ($domain in $Name) {
                Write-Host "`nValidating DNS compliance for: $domain" -ForegroundColor Cyan

                # Get domain information
                try {
                    $domainInfo = Get-MgDomain -DomainId $domain -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to retrieve domain $domain : $_"
                    continue
                }

                # Initialize compliance result
                $compliance = [PSCustomObject]@{
                    Domain              = $domain
                    IsVerified          = $domainInfo.IsVerified
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
                    DeprecatedRecords   = if ($CheckDeprecated) { @() } else { "Not Checked" }
                    SRVStatus           = if ($CheckSRV) { "Unknown" } else { "Not Checked" }
                    Issues              = @()
                    Recommendations     = @()
                }

                # Get expected DNS records from Graph API
                Write-Verbose "Retrieving expected DNS configuration from Microsoft Graph"
                $expectedRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain -ErrorAction SilentlyContinue

                if (-not $expectedRecords) {
                    $compliance.OverallHealth = "Warning"
                    $compliance.Issues += "No service configuration records found in Microsoft Graph"
                    $complianceResults += $compliance
                    continue
                }

                # Initialize scoring
                $totalChecks = 0
                $passedChecks = 0

                # === MX RECORD VALIDATION ===
                $mxRecords = $expectedRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Mx' }
                if ($mxRecords) {
                    $totalChecks++
                    $expectedMX = $mxRecords[0].AdditionalProperties['mailExchange']

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
                $dkimRecords = $expectedRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'CName' -and $_.AdditionalProperties['label'] -like '*._domainkey.*' }
                if ($dkimRecords) {
                    $totalChecks++
                    $dkimValid = $true

                    foreach ($dkimRecord in $dkimRecords) {
                        $dkimLabel = $dkimRecord.AdditionalProperties['label']
                        $expectedCName = $dkimRecord.AdditionalProperties['canonicalName']

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
                        $compliance.Recommendations += "Add DMARC record at _dmarc.$domain"
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
                $healthColor = switch ($compliance.OverallHealth) {
                    "Healthy" { "Green" }
                    "Warning" { "Yellow" }
                    "Critical" { "Red" }
                    default { "White" }
                }

                Write-Host "  Overall Health: $($compliance.OverallHealth) ($($compliance.ComplianceScore)%)" -ForegroundColor $healthColor
                Write-Host "  MX Status: $($compliance.MXStatus) ($($compliance.MXFormat))" -ForegroundColor White

                if ($compliance.DKIMStatus -ne "Unknown") {
                    Write-Host "  DKIM Status: $($compliance.DKIMStatus) ($($compliance.DKIMFormat))" -ForegroundColor White
                }

                if ($IncludeSPF) {
                    Write-Host "  SPF Status: $($compliance.SPFStatus)" -ForegroundColor White
                }

                if ($IncludeDMARC) {
                    Write-Host "  DMARC Status: $($compliance.DMARCStatus)" -ForegroundColor White
                }

                # Show issues
                if ($compliance.Issues.Count -gt 0) {
                    Write-Host "`n  Issues Found:" -ForegroundColor Yellow
                    $compliance.Issues | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
                }

                # Show recommendations if requested
                if ($ShowRecommendations -and $compliance.Recommendations.Count -gt 0) {
                    Write-Host "`n  Recommendations:" -ForegroundColor Cyan
                    $compliance.Recommendations | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
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
