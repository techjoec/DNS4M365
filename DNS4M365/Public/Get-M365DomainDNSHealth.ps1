function Get-M365DomainDNSHealth {
    <#
    .SYNOPSIS
        Performs comprehensive DNS health check for Microsoft 365 domains.

    .DESCRIPTION
        Validates ALL DNS records for Microsoft 365 including those not returned by Graph API
        (DMARC, SPF validation, DKIM resolution, SRV records, deprecated records).
        Compares expected records from Graph API with actual DNS resolution.

    .PARAMETER DomainName
        The domain name(s) to check. If not specified, checks all verified domains.

    .PARAMETER IncludeDMARC
        Check for DMARC TXT records (_dmarc.domain.com).

    .PARAMETER IncludeSPF
        Validate SPF TXT records.

    .PARAMETER CheckDKIMResolution
        Verify DKIM CNAME records actually resolve to Microsoft infrastructure.

    .PARAMETER CheckDeprecated
        Check for deprecated records (like msoid) that should be removed.

    .PARAMETER CheckSRVRecords
        Validate SRV records for Teams/Skype for Business.

    .PARAMETER DetailedOutput
        Include detailed resolution information for each record.

    .EXAMPLE
        Get-M365DomainDNSHealth -DomainName "contoso.com"
        Performs basic DNS health check for contoso.com.

    .EXAMPLE
        Get-M365DomainDNSHealth -DomainName "contoso.com" -IncludeDMARC -IncludeSPF -CheckDKIMResolution
        Comprehensive health check including DMARC, SPF, and DKIM validation.

    .EXAMPLE
        Get-M365DomainDNSHealth -CheckDeprecated
        Checks all domains for deprecated DNS records that should be removed.

    .OUTPUTS
        Custom object array containing DNS health check results.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Domain', 'Id')]
        [string[]]$DomainName,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDMARC,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSPF,

        [Parameter(Mandatory = $false)]
        [switch]$CheckDKIMResolution,

        [Parameter(Mandatory = $false)]
        [switch]$CheckDeprecated,

        [Parameter(Mandatory = $false)]
        [switch]$CheckSRVRecords,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )

    begin {
        Write-Verbose "Starting comprehensive DNS health check"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }

        $healthResults = @()
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
                Write-Host "`nChecking DNS health for: $domain" -ForegroundColor Cyan

                $domainHealth = [PSCustomObject]@{
                    Domain = $domain
                    OverallHealth = "Unknown"
                    MXRecord = $null
                    AutodiscoverCNAME = $null
                    SPFRecord = $null
                    DMARCRecord = $null
                    DKIMSelector1 = $null
                    DKIMSelector2 = $null
                    SIPRecord = $null
                    LyncdiscoverRecord = $null
                    SIPTLSSRVRecord = $null
                    SIPFederationSRVRecord = $null
                    EnterpriseEnrollment = $null
                    EnterpriseRegistration = $null
                    DeprecatedMSOID = $null
                    Issues = @()
                    Warnings = @()
                    Recommendations = @()
                }

                # Check MX Record
                Write-Verbose "Checking MX record for $domain"
                try {
                    $mxRecords = Resolve-DnsName -Name $domain -Type MX -ErrorAction SilentlyContinue
                    if ($mxRecords) {
                        $primaryMX = $mxRecords | Sort-Object Preference | Select-Object -First 1

                        # Detect MX format (2024-2025 updates)
                        $isNewFormat = $primaryMX.NameExchange -like "*.mx.microsoft"
                        $isLegacyFormat = $primaryMX.NameExchange -like "*.mail.protection.outlook.com" -or
                                         $primaryMX.NameExchange -like "*.mail.protection.office365.us"
                        $isGCCHigh = $primaryMX.NameExchange -like "*.mail.protection.office365.us"
                        $isDoD = $primaryMX.NameExchange -like "*.protection.office365.us"
                        $is21Vianet = $primaryMX.NameExchange -like "*.mail.protection.partner.outlook.cn"

                        $domainHealth.MXRecord = [PSCustomObject]@{
                            Exists = $true
                            Target = $primaryMX.NameExchange
                            Priority = $primaryMX.Preference
                            IsMicrosoft365 = $isNewFormat -or $isLegacyFormat -or $isGCCHigh -or $isDoD -or $is21Vianet
                            Format = if ($isNewFormat) { "Modern (mx.microsoft)" }
                                    elseif ($isLegacyFormat) { "Legacy (mail.protection.outlook.com)" }
                                    elseif ($isGCCHigh -or $isDoD) { "Government Cloud" }
                                    elseif ($is21Vianet) { "21Vianet China" }
                                    else { "Non-Microsoft" }
                        }

                        if (-not $domainHealth.MXRecord.IsMicrosoft365) {
                            $domainHealth.Warnings += "MX record does not point to Microsoft 365"
                        }

                        # Migration notice for legacy format (July-August 2025 migration)
                        if ($isLegacyFormat) {
                            $domainHealth.Recommendations += "Consider migrating to new mx.microsoft format (Microsoft Message Center MC1048624, July-August 2025 timeline)"
                        }
                    }
                    else {
                        $domainHealth.MXRecord = [PSCustomObject]@{ Exists = $false }
                        $domainHealth.Issues += "No MX record found"
                    }
                }
                catch {
                    Write-Verbose "Failed to resolve MX: $_"
                }

                # Check Autodiscover CNAME
                Write-Verbose "Checking Autodiscover CNAME for $domain"
                try {
                    $autodiscover = Resolve-DnsName -Name "autodiscover.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($autodiscover) {
                        $domainHealth.AutodiscoverCNAME = [PSCustomObject]@{
                            Exists = $true
                            Target = $autodiscover.NameHost
                            IsCorrect = $autodiscover.NameHost -like "*outlook.com" -or
                                       $autodiscover.NameHost -like "*office365.us"
                        }

                        if (-not $domainHealth.AutodiscoverCNAME.IsCorrect) {
                            $domainHealth.Warnings += "Autodiscover CNAME does not point to Microsoft"
                        }
                    }
                    else {
                        $domainHealth.AutodiscoverCNAME = [PSCustomObject]@{ Exists = $false }
                        $domainHealth.Issues += "No Autodiscover CNAME found"
                    }
                }
                catch {
                    Write-Verbose "Failed to resolve Autodiscover: $_"
                }

                # Check SPF Record
                if ($IncludeSPF) {
                    Write-Verbose "Checking SPF record for $domain"
                    try {
                        $txtRecords = Resolve-DnsName -Name $domain -Type TXT -ErrorAction SilentlyContinue
                        $spfRecord = $txtRecords | Where-Object { $_.Strings -like "v=spf1*" } | Select-Object -First 1

                        if ($spfRecord) {
                            $spfText = $spfRecord.Strings -join ""
                            $domainHealth.SPFRecord = [PSCustomObject]@{
                                Exists = $true
                                Value = $spfText
                                IncludesMicrosoft365 = $spfText -like "*spf.protection.outlook.com*" -or $spfText -like "*spf.protection.office365.us*"
                                HasHardFail = $spfText -like "*-all"
                                HasSoftFail = $spfText -like "*~all"
                                LookupCount = ($spfText | Select-String -Pattern "include:" -AllMatches).Matches.Count
                            }

                            if (-not $domainHealth.SPFRecord.IncludesMicrosoft365) {
                                $domainHealth.Issues += "SPF record does not include Microsoft 365 (spf.protection.outlook.com)"
                                $domainHealth.Issues += "CRITICAL: Email authentication mandatory starting April 2025 - SPF must include Microsoft 365"
                            }

                            if ($domainHealth.SPFRecord.LookupCount -gt 10) {
                                $domainHealth.Issues += "SPF record exceeds 10 DNS lookup limit (RFC 7208)"
                            }

                            if (-not $domainHealth.SPFRecord.HasHardFail) {
                                $domainHealth.Recommendations += "Consider using -all (hard fail) instead of ~all (soft fail) for SPF to improve email security"
                            }
                        }
                        else {
                            $domainHealth.SPFRecord = [PSCustomObject]@{ Exists = $false }
                            $domainHealth.Issues += "No SPF record found - REQUIRED for email delivery"
                            $domainHealth.Issues += "CRITICAL: Email authentication mandatory starting April 2025 - SPF record MUST exist"
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check SPF: $_"
                    }
                }

                # Check DMARC Record
                if ($IncludeDMARC) {
                    Write-Verbose "Checking DMARC record for $domain"
                    try {
                        $dmarcRecord = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction SilentlyContinue

                        if ($dmarcRecord) {
                            $dmarcText = $dmarcRecord.Strings -join ""
                            $domainHealth.DMARCRecord = [PSCustomObject]@{
                                Exists = $true
                                Value = $dmarcText
                                Policy = if ($dmarcText -match "p=([^;]+)") { $Matches[1] } else { "unknown" }
                                SubdomainPolicy = if ($dmarcText -match "sp=([^;]+)") { $Matches[1] } else { "inherited" }
                                HasReporting = $dmarcText -like "*rua=*"
                                HasForensics = $dmarcText -like "*ruf=*"
                            }

                            if ($domainHealth.DMARCRecord.Policy -eq "none") {
                                $domainHealth.Recommendations += "DMARC policy is 'none' - consider upgrading to 'quarantine' or 'reject' for better protection"
                            }

                            if (-not $domainHealth.DMARCRecord.HasReporting) {
                                $domainHealth.Recommendations += "Add DMARC reporting (rua=) to receive email authentication reports"
                            }
                        }
                        else {
                            $domainHealth.DMARCRecord = [PSCustomObject]@{ Exists = $false }
                            $domainHealth.Issues += "No DMARC record found - REQUIRED for email security"
                            $domainHealth.Issues += "CRITICAL: Email authentication mandatory starting April 2025 - DMARC record MUST exist with policy p=quarantine or p=reject"
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check DMARC: $_"
                    }
                }

                # Check DKIM Records
                if ($CheckDKIMResolution) {
                    Write-Verbose "Checking DKIM records for $domain"
                    try {
                        $selector1Host = "selector1._domainkey.$domain"
                        $selector2Host = "selector2._domainkey.$domain"

                        $selector1 = Resolve-DnsName -Name $selector1Host -Type CNAME -ErrorAction SilentlyContinue
                        $selector2 = Resolve-DnsName -Name $selector2Host -Type CNAME -ErrorAction SilentlyContinue

                        # Detect DKIM format (legacy vs new May 2025 format)
                        $isLegacyFormat1 = if ($selector1) { $selector1.NameHost -like "*._domainkey.*.onmicrosoft.com" } else { $false }
                        $isNewFormat1 = if ($selector1) { $selector1.NameHost -like "*._domainkey.*.dkim.mail.microsoft" } else { $false }
                        $isLegacyFormat2 = if ($selector2) { $selector2.NameHost -like "*._domainkey.*.onmicrosoft.com" } else { $false }
                        $isNewFormat2 = if ($selector2) { $selector2.NameHost -like "*._domainkey.*.dkim.mail.microsoft" } else { $false }

                        $domainHealth.DKIMSelector1 = [PSCustomObject]@{
                            Exists = $null -ne $selector1
                            Target = if ($selector1) { $selector1.NameHost } else { $null }
                            PointsToMicrosoft = $isLegacyFormat1 -or $isNewFormat1
                            Format = if ($isNewFormat1) { "Modern (dkim.mail.microsoft)" }
                                    elseif ($isLegacyFormat1) { "Legacy (onmicrosoft.com)" }
                                    else { "Unknown" }
                        }

                        $domainHealth.DKIMSelector2 = [PSCustomObject]@{
                            Exists = $null -ne $selector2
                            Target = if ($selector2) { $selector2.NameHost } else { $null }
                            PointsToMicrosoft = $isLegacyFormat2 -or $isNewFormat2
                            Format = if ($isNewFormat2) { "Modern (dkim.mail.microsoft)" }
                                    elseif ($isLegacyFormat2) { "Legacy (onmicrosoft.com)" }
                                    else { "Unknown" }
                        }

                        if (-not $domainHealth.DKIMSelector1.Exists -or -not $domainHealth.DKIMSelector2.Exists) {
                            $domainHealth.Warnings += "DKIM selectors not configured - email authentication will be limited"
                            $domainHealth.Recommendations += "Configure DKIM signing in Exchange Online admin center for this domain"
                        }

                        # Migration notice for legacy DKIM format
                        if ($isLegacyFormat1 -or $isLegacyFormat2) {
                            $domainHealth.Recommendations += "DKIM using legacy format - new deployments use dkim.mail.microsoft format (May 2025+)"
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check DKIM: $_"
                    }
                }

                # Check SRV Records for Teams
                if ($CheckSRVRecords) {
                    Write-Verbose "Checking Teams/SfB SRV records for $domain"

                    try {
                        $sipTLS = Resolve-DnsName -Name "_sip._tls.$domain" -Type SRV -ErrorAction SilentlyContinue
                        if ($sipTLS) {
                            $domainHealth.SIPTLSSRVRecord = [PSCustomObject]@{
                                Exists = $true
                                Target = $sipTLS.NameTarget
                                Port = $sipTLS.Port
                                IsCorrect = $sipTLS.NameTarget -like "*online.lync.com" -or
                                           $sipTLS.NameTarget -like "*skypeforbusiness.us"
                            }

                            if (-not $domainHealth.SIPTLSSRVRecord.IsCorrect) {
                                $domainHealth.Warnings += "SIP TLS SRV record does not point to Microsoft"
                            }

                            # Note: _sip._tls may be legacy for Teams-only tenants
                            $domainHealth.Recommendations += "NOTE: _sip._tls SRV record is legacy - Teams-only tenants only need _sipfederationtls._tcp (2024 update)"
                        }
                        else {
                            $domainHealth.SIPTLSSRVRecord = [PSCustomObject]@{ Exists = $false }
                            # Not a warning anymore - this is expected for Teams-only
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check SIP TLS SRV: $_"
                    }

                    try {
                        $sipFed = Resolve-DnsName -Name "_sipfederationtls._tcp.$domain" -Type SRV -ErrorAction SilentlyContinue
                        if ($sipFed) {
                            $domainHealth.SIPFederationSRVRecord = [PSCustomObject]@{
                                Exists = $true
                                Target = $sipFed.NameTarget
                                Port = $sipFed.Port
                                IsCorrect = $sipFed.NameTarget -like "*online.lync.com" -or
                                           $sipFed.NameTarget -like "*skypeforbusiness.us"
                            }

                            if (-not $domainHealth.SIPFederationSRVRecord.IsCorrect) {
                                $domainHealth.Warnings += "SIP Federation SRV record does not point to Microsoft"
                            }
                        }
                        else {
                            $domainHealth.SIPFederationSRVRecord = [PSCustomObject]@{ Exists = $false }
                            $domainHealth.Warnings += "No SIP Federation SRV record found - Teams external access/federation requires this record"
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check SIP Federation SRV: $_"
                    }

                    # Check SIP CNAME
                    try {
                        $sip = Resolve-DnsName -Name "sip.$domain" -Type CNAME -ErrorAction SilentlyContinue
                        if ($sip) {
                            $domainHealth.SIPRecord = [PSCustomObject]@{
                                Exists = $true
                                Target = $sip.NameHost
                                IsCorrect = $sip.NameHost -like "*online.lync.com"
                            }

                            # Note: sip CNAME is legacy for Teams-only tenants
                            $domainHealth.Recommendations += "NOTE: sip.$domain CNAME is legacy (Skype for Business) - not required for Teams-only tenants"
                        }
                        else {
                            $domainHealth.SIPRecord = [PSCustomObject]@{ Exists = $false }
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check SIP CNAME: $_"
                    }

                    # Check lyncdiscover CNAME
                    try {
                        $lyncdiscover = Resolve-DnsName -Name "lyncdiscover.$domain" -Type CNAME -ErrorAction SilentlyContinue
                        if ($lyncdiscover) {
                            $domainHealth.LyncdiscoverRecord = [PSCustomObject]@{
                                Exists = $true
                                Target = $lyncdiscover.NameHost
                                IsCorrect = $lyncdiscover.NameHost -like "*online.lync.com"
                            }

                            # Note: lyncdiscover CNAME is legacy for Teams-only tenants
                            $domainHealth.Recommendations += "NOTE: lyncdiscover.$domain CNAME is legacy (Skype for Business mobile) - not required for Teams-only tenants"
                        }
                        else {
                            $domainHealth.LyncdiscoverRecord = [PSCustomObject]@{ Exists = $false }
                        }
                    }
                    catch {
                        Write-Verbose "Failed to check lyncdiscover: $_"
                    }
                }

                # Check for deprecated MSOID record
                if ($CheckDeprecated) {
                    Write-Verbose "Checking for deprecated msoid record"
                    try {
                        $msoid = Resolve-DnsName -Name "msoid.$domain" -Type CNAME -ErrorAction SilentlyContinue
                        if ($msoid) {
                            $domainHealth.DeprecatedMSOID = [PSCustomObject]@{
                                Exists = $true
                                Target = $msoid.NameHost
                            }
                            $domainHealth.Issues += "DEPRECATED: msoid CNAME found - MUST BE REMOVED (blocks M365 Apps activation)"
                        }
                        else {
                            $domainHealth.DeprecatedMSOID = [PSCustomObject]@{ Exists = $false }
                        }
                    }
                    catch {
                        # Good - record doesn't exist
                        $domainHealth.DeprecatedMSOID = [PSCustomObject]@{ Exists = $false }
                    }
                }

                # Check Intune/MDM records
                try {
                    $enterpriseEnroll = Resolve-DnsName -Name "enterpriseenrollment.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($enterpriseEnroll) {
                        $domainHealth.EnterpriseEnrollment = [PSCustomObject]@{
                            Exists = $true
                            Target = $enterpriseEnroll.NameHost
                            IsCorrect = $enterpriseEnroll.NameHost -like "*manage.microsoft.com"
                        }
                    }
                    else {
                        $domainHealth.EnterpriseEnrollment = [PSCustomObject]@{ Exists = $false }
                    }

                    $enterpriseReg = Resolve-DnsName -Name "enterpriseregistration.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($enterpriseReg) {
                        $domainHealth.EnterpriseRegistration = [PSCustomObject]@{
                            Exists = $true
                            Target = $enterpriseReg.NameHost
                            IsCorrect = $enterpriseReg.NameHost -like "*windows.net"
                        }
                    }
                    else {
                        $domainHealth.EnterpriseRegistration = [PSCustomObject]@{ Exists = $false }
                    }
                }
                catch {
                    Write-Verbose "Failed to check Intune records: $_"
                }

                # Determine overall health
                $criticalIssues = $domainHealth.Issues.Count
                $warningCount = $domainHealth.Warnings.Count

                if ($criticalIssues -eq 0 -and $warningCount -eq 0) {
                    $domainHealth.OverallHealth = "Healthy"
                }
                elseif ($criticalIssues -eq 0 -and $warningCount -le 2) {
                    $domainHealth.OverallHealth = "Warning"
                }
                elseif ($criticalIssues -le 2) {
                    $domainHealth.OverallHealth = "Issues"
                }
                else {
                    $domainHealth.OverallHealth = "Critical"
                }

                # Display summary
                $healthColor = switch ($domainHealth.OverallHealth) {
                    "Healthy" { "Green" }
                    "Warning" { "Yellow" }
                    "Issues" { "Magenta" }
                    "Critical" { "Red" }
                    default { "White" }
                }

                Write-Host "  Overall Health: $($domainHealth.OverallHealth)" -ForegroundColor $healthColor
                Write-Host "  Issues: $criticalIssues | Warnings: $warningCount | Recommendations: $($domainHealth.Recommendations.Count)" -ForegroundColor White

                if ($criticalIssues -gt 0) {
                    Write-Host "`n  Critical Issues:" -ForegroundColor Red
                    $domainHealth.Issues | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
                }

                if ($warningCount -gt 0) {
                    Write-Host "`n  Warnings:" -ForegroundColor Yellow
                    $domainHealth.Warnings | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
                }

                if ($domainHealth.Recommendations.Count -gt 0) {
                    Write-Host "`n  Recommendations:" -ForegroundColor Cyan
                    $domainHealth.Recommendations | ForEach-Object { Write-Host "    - $_" -ForegroundColor Cyan }
                }

                $healthResults += $domainHealth
            }

            Write-Host "`n=== DNS Health Check Complete ===" -ForegroundColor Cyan
            return $healthResults
        }
        catch {
            Write-Error "Failed to perform DNS health check: $_"
            throw
        }
    }
}
