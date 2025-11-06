function Get-M365DomainReadiness {
    <#
    .SYNOPSIS
        Assesses Microsoft 365 domain DNS configuration compliance and readiness.

    .DESCRIPTION
        Evaluates custom domain DNS configuration against current Microsoft 365 best practices
        and requirements. Identifies configuration issues, format compliance, and provides
        recommendations for optimal DNS setup.

        Checks performed:
        - MX record format validation (detects legacy vs modern formats)
        - DKIM configuration and format validation
        - Email authentication compliance (SPF/DMARC requirements)
        - Deprecated record detection (msoid, legacy Skype for Business)
        - Overall DNS health and compliance scoring

        Use cases:
        - Regular DNS compliance auditing
        - Configuration validation
        - Security posture assessment
        - Change planning and impact analysis

    .PARAMETER DomainName
        The domain name(s) to assess. If not specified, assesses all verified domains.

    .PARAMETER ShowRecommendations
        Display detailed recommendations for improving DNS configuration.

    .PARAMETER ExportReport
        Export assessment report to CSV file.

    .PARAMETER OutputPath
        Path for exported report file (default: current directory).

    .EXAMPLE
        Get-M365DomainReadiness -DomainName "contoso.com"
        Assesses DNS configuration for contoso.com.

    .EXAMPLE
        Get-M365DomainReadiness -ShowRecommendations
        Assesses all domains with detailed recommendations.

    .EXAMPLE
        Get-M365DomainReadiness -ExportReport -OutputPath "C:\Reports"
        Assesses all domains and exports compliance report.

    .OUTPUTS
        Custom object array containing DNS configuration assessment and recommendations.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$DomainName,

        [Parameter(Mandatory = $false)]
        [switch]$ShowRecommendations,

        [Parameter(Mandatory = $false)]
        [switch]$ExportReport,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Get-Location).Path
    )

    begin {
        Write-Verbose "Starting DNS readiness assessment"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }

        $assessmentResults = @()
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
                Write-Host "`nAssessing DNS readiness for: $domain" -ForegroundColor Cyan

                $domainStatus = [PSCustomObject]@{
                    Domain = $domain
                    OverallReadiness = 0
                    MXStatus = "Unknown"
                    MXFormat = "Unknown"
                    UsingLegacyMX = $false
                    DKIMStatus = "Unknown"
                    DKIMFormat = "Unknown"
                    UsingLegacyDKIM = $false
                    EmailAuthStatus = "Unknown"
                    SPFConfigured = $false
                    DMARCConfigured = $false
                    EmailAuthReady = $false
                    DeprecatedRecords = @()
                    LegacyTeamsRecords = @()
                    CriticalActions = @()
                    Recommendations = @()
                    ActionPriority = "Unknown"
                }

                # 1. Check MX Record Format
                Write-Verbose "Checking MX record format for $domain"
                try {
                    $mxRecords = Resolve-DnsOverHttps -Name $domain -Type MX -ErrorAction SilentlyContinue
                    if ($mxRecords) {
                        $primaryMX = $mxRecords | Sort-Object Preference | Select-Object -First 1

                        if ($primaryMX.NameExchange -like "*.mx.microsoft") {
                            $domainStatus.MXStatus = "Modern"
                            $domainStatus.MXFormat = "mx.microsoft (current)"
                            $domainStatus.UsingLegacyMX = $false
                        }
                        elseif ($primaryMX.NameExchange -like "*.mail.protection.outlook.com") {
                            $domainStatus.MXStatus = "Legacy"
                            $domainStatus.MXFormat = "mail.protection.outlook.com (legacy)"
                            $domainStatus.UsingLegacyMX = $true
                            $domainStatus.CriticalActions += "Migrate MX record to mx.microsoft format (Message Center MC1048624, July-August 2025)"
                        }
                        elseif ($primaryMX.NameExchange -like "*.mail.protection.office365.us" -or
                                $primaryMX.NameExchange -like "*.protection.office365.us") {
                            $domainStatus.MXStatus = "Government Cloud"
                            $domainStatus.MXFormat = "office365.us (GCC/DoD)"
                            $domainStatus.UsingLegacyMX = $false
                        }
                        elseif ($primaryMX.NameExchange -like "*.mail.protection.partner.outlook.cn") {
                            $domainStatus.MXStatus = "21Vianet China"
                            $domainStatus.MXFormat = "partner.outlook.cn (21Vianet)"
                            $domainStatus.UsingLegacyMX = $false
                        }
                        else {
                            $domainStatus.MXStatus = "Non-Microsoft"
                            $domainStatus.MXFormat = "Third-party or hybrid"
                            $domainStatus.UsingLegacyMX = $false
                        }
                    }
                    else {
                        $domainStatus.MXStatus = "Missing"
                        $domainStatus.CriticalActions += "Configure MX record for Microsoft 365"
                    }
                }
                catch {
                    Write-Verbose "Failed to check MX: $_"
                }

                # 2. Check DKIM Format
                Write-Verbose "Checking DKIM configuration for $domain"
                try {
                    $selector1 = Resolve-DnsOverHttps -Name "selector1._domainkey.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    $selector2 = Resolve-DnsOverHttps -Name "selector2._domainkey.$domain" -Type CNAME -ErrorAction SilentlyContinue

                    $hasSelector1 = $null -ne $selector1
                    $hasSelector2 = $null -ne $selector2

                    if ($hasSelector1 -or $hasSelector2) {
                        $isNewFormat = ($selector1 -and $selector1.NameHost -like "*._domainkey.*.dkim.mail.microsoft") -or
                                      ($selector2 -and $selector2.NameHost -like "*._domainkey.*.dkim.mail.microsoft")
                        $isLegacyFormat = ($selector1 -and $selector1.NameHost -like "*._domainkey.*.onmicrosoft.com") -or
                                         ($selector2 -and $selector2.NameHost -like "*._domainkey.*.onmicrosoft.com")

                        if ($isNewFormat) {
                            $domainStatus.DKIMStatus = "Modern"
                            $domainStatus.DKIMFormat = "dkim.mail.microsoft (current)"
                            $domainStatus.UsingLegacyDKIM = $false
                        }
                        elseif ($isLegacyFormat) {
                            $domainStatus.DKIMStatus = "Legacy"
                            $domainStatus.DKIMFormat = "onmicrosoft.com (legacy)"
                            $domainStatus.UsingLegacyDKIM = $true
                            $domainStatus.Recommendations += "DKIM using legacy format - new deployments use dkim.mail.microsoft (May 2025+)"
                        }
                    }
                    else {
                        $domainStatus.DKIMStatus = "Not Configured"
                        $domainStatus.Recommendations += "Configure DKIM signing for improved email authentication"
                    }
                }
                catch {
                    Write-Verbose "Failed to check DKIM: $_"
                }

                # 3. Check Email Authentication (SPF/DMARC) - MANDATORY April 2025
                Write-Verbose "Checking email authentication status for $domain"
                try {
                    # Check SPF
                    $txtRecords = Resolve-DnsOverHttps -Name $domain -Type TXT -ErrorAction SilentlyContinue
                    $spfRecord = $txtRecords | Where-Object { $_.Strings -like "v=spf1*" } | Select-Object -First 1

                    if ($spfRecord) {
                        $spfText = $spfRecord.Strings -join ""
                        $domainStatus.SPFConfigured = $true

                        if ($spfText -notlike "*spf.protection.outlook.com*" -and $spfText -notlike "*spf.protection.office365.us*") {
                            $domainStatus.CriticalActions += "SPF record does not include Microsoft 365 - MANDATORY for April 2025"
                        }
                    }
                    else {
                        $domainStatus.SPFConfigured = $false
                        $domainStatus.CriticalActions += "CRITICAL: No SPF record found - MANDATORY for email authentication (April 2025)"
                    }

                    # Check DMARC
                    $dmarcRecord = Resolve-DnsOverHttps -Name "_dmarc.$domain" -Type TXT -ErrorAction SilentlyContinue
                    if ($dmarcRecord) {
                        $domainStatus.DMARCConfigured = $true
                        $dmarcText = $dmarcRecord.Strings -join ""

                        if ($dmarcText -like "*p=none*") {
                            $domainStatus.Recommendations += "DMARC policy is 'none' - upgrade to 'quarantine' or 'reject' for April 2025 compliance"
                        }
                    }
                    else {
                        $domainStatus.DMARCConfigured = $false
                        $domainStatus.CriticalActions += "CRITICAL: No DMARC record found - MANDATORY with policy p=quarantine or p=reject (April 2025)"
                    }

                    $domainStatus.EmailAuthReady = $domainStatus.SPFConfigured -and $domainStatus.DMARCConfigured
                    $domainStatus.EmailAuthStatus = if ($domainStatus.EmailAuthReady) { "Ready" }
                                                       elseif ($domainStatus.SPFConfigured -or $domainStatus.DMARCConfigured) { "Partial" }
                                                       else { "Not Ready" }
                }
                catch {
                    Write-Verbose "Failed to check email authentication: $_"
                }

                # 4. Check for Deprecated Records
                Write-Verbose "Checking for deprecated records"
                try {
                    # Check msoid (CRITICAL - blocks M365 Apps)
                    $msoid = Resolve-DnsOverHttps -Name "msoid.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($msoid) {
                        $domainStatus.DeprecatedRecords += "msoid.$domain"
                        $domainStatus.CriticalActions += "CRITICAL: Remove msoid.$domain CNAME - BLOCKS Microsoft 365 Apps activation"
                    }
                }
                catch {
                    # Good - record doesn't exist
                }

                # 5. Check for Legacy Teams/Skype Records
                Write-Verbose "Checking for legacy Teams/Skype for Business records"
                try {
                    $sip = Resolve-DnsOverHttps -Name "sip.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($sip) {
                        $domainStatus.LegacyTeamsRecords += "sip.$domain CNAME"
                        $domainStatus.Recommendations += "sip.$domain CNAME is legacy (Skype for Business) - not required for Teams-only tenants"
                    }

                    $lyncdiscover = Resolve-DnsOverHttps -Name "lyncdiscover.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($lyncdiscover) {
                        $domainStatus.LegacyTeamsRecords += "lyncdiscover.$domain CNAME"
                        $domainStatus.Recommendations += "lyncdiscover.$domain CNAME is legacy (Skype for Business) - not required for Teams-only tenants"
                    }

                    $sipTLS = Resolve-DnsOverHttps -Name "_sip._tls.$domain" -Type SRV -ErrorAction SilentlyContinue
                    if ($sipTLS) {
                        $domainStatus.LegacyTeamsRecords += "_sip._tls.$domain SRV"
                        $domainStatus.Recommendations += "_sip._tls.$domain SRV is legacy - Teams-only needs _sipfederationtls._tcp only"
                    }
                }
                catch {
                    Write-Verbose "No legacy Teams/Skype records found"
                }

                # Calculate Overall Readiness Percentage
                $readinessPoints = 0
                $totalPoints = 5

                # MX modern format (1 point)
                if ($domainStatus.MXStatus -eq "Modern" -or $domainStatus.MXStatus -eq "Government Cloud" -or $domainStatus.MXStatus -eq "21Vianet China") {
                    $readinessPoints++
                }

                # DKIM configured (1 point)
                if ($domainStatus.DKIMStatus -ne "Not Configured") {
                    $readinessPoints++
                }

                # Email authentication ready (2 points - critical for April 2025)
                if ($domainStatus.SPFConfigured) { $readinessPoints++ }
                if ($domainStatus.DMARCConfigured) { $readinessPoints++ }

                # No deprecated records (1 point)
                if ($domainStatus.DeprecatedRecords.Count -eq 0) {
                    $readinessPoints++
                }

                $domainStatus.OverallReadiness = [math]::Round(($readinessPoints / $totalPoints) * 100, 0)

                # Determine Action Priority
                if ($domainStatus.DeprecatedRecords.Count -gt 0 -or -not $domainStatus.EmailAuthReady) {
                    $domainStatus.ActionPriority = "CRITICAL"
                }
                elseif ($domainStatus.UsingLegacyMX -or $domainStatus.UsingLegacyDKIM) {
                    $domainStatus.ActionPriority = "High"
                }
                elseif ($domainStatus.LegacyTeamsRecords.Count -gt 0) {
                    $domainStatus.ActionPriority = "Medium"
                }
                else {
                    $domainStatus.ActionPriority = "Low"
                }

                # Display summary
                $readinessColor = switch ($domainStatus.OverallReadiness) {
                    { $_ -ge 80 } { "Green" }
                    { $_ -ge 60 } { "Yellow" }
                    { $_ -ge 40 } { "Magenta" }
                    default { "Red" }
                }

                Write-Host "  Overall Readiness: $($domainStatus.OverallReadiness)%" -ForegroundColor $readinessColor
                Write-Host "  Action Priority: $($domainStatus.ActionPriority)" -ForegroundColor $(
                    switch ($domainStatus.ActionPriority) {
                        "CRITICAL" { "Red" }
                        "High" { "Magenta" }
                        "Medium" { "Yellow" }
                        default { "Green" }
                    }
                )
                Write-Host "  MX Format: $($domainStatus.MXFormat)" -ForegroundColor White
                Write-Host "  DKIM Format: $($domainStatus.DKIMFormat)" -ForegroundColor White
                Write-Host "  Email Auth Status: $($domainStatus.EmailAuthStatus)" -ForegroundColor White

                if ($domainStatus.CriticalActions.Count -gt 0) {
                    Write-Host "`n  Critical Actions Required:" -ForegroundColor Red
                    $domainStatus.CriticalActions | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
                }

                if ($ShowRecommendations -and $domainStatus.Recommendations.Count -gt 0) {
                    Write-Host "`n  Recommendations:" -ForegroundColor Cyan
                    $domainStatus.Recommendations | ForEach-Object { Write-Host "    - $_" -ForegroundColor Cyan }
                }

                if ($domainStatus.DeprecatedRecords.Count -gt 0) {
                    Write-Host "`n  Deprecated Records (REMOVE):" -ForegroundColor Magenta
                    $domainStatus.DeprecatedRecords | ForEach-Object { Write-Host "    - $_" -ForegroundColor Magenta }
                }

                if ($domainStatus.LegacyTeamsRecords.Count -gt 0) {
                    Write-Host "`n  Legacy Teams/Skype Records:" -ForegroundColor Yellow
                    $domainStatus.LegacyTeamsRecords | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
                }

                $assessmentResults += $domainStatus
            }

            # Export report if requested
            if ($ExportReport) {
                $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $reportFile = Join-Path -Path $OutputPath -ChildPath "M365-DNS-Readiness-$timestamp.csv"

                $exportData = $assessmentResults | Select-Object Domain, OverallReadiness, ActionPriority,
                    MXStatus, MXFormat, DKIMStatus, DKIMFormat, EmailAuthStatus, SPFConfigured, DMARCConfigured,
                    @{N='CriticalActionsCount';E={$_.CriticalActions.Count}},
                    @{N='DeprecatedRecordsCount';E={$_.DeprecatedRecords.Count}},
                    @{N='LegacyRecordsCount';E={$_.LegacyTeamsRecords.Count}}

                $exportData | Export-Csv -Path $reportFile -NoTypeInformation
                Write-Host "`nDNS readiness report exported to: $reportFile" -ForegroundColor Green
            }

            # Display summary statistics
            Write-Host "`n=== DNS Readiness Summary ===" -ForegroundColor Cyan
            $totalDomains = $assessmentResults.Count
            $criticalPriority = ($assessmentResults | Where-Object { $_.ActionPriority -eq "CRITICAL" }).Count
            $highPriority = ($assessmentResults | Where-Object { $_.ActionPriority -eq "High" }).Count
            $avgReadiness = [math]::Round(($assessmentResults | Measure-Object -Property OverallReadiness -Average).Average, 0)

            Write-Host "Total Domains Assessed: $totalDomains" -ForegroundColor White
            Write-Host "Average Readiness: $avgReadiness%" -ForegroundColor White
            Write-Host "CRITICAL Priority: $criticalPriority" -ForegroundColor Red
            Write-Host "High Priority: $highPriority" -ForegroundColor Magenta

            return $assessmentResults
        }
        catch {
            Write-Error "Failed to assess readiness: $_"
            throw
        }
    }
}
