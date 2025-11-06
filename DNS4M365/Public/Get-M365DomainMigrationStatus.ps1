function Get-M365DomainMigrationStatus {
    <#
    .SYNOPSIS
        Assesses domain readiness for 2024-2025 Microsoft 365 DNS migrations.

    .DESCRIPTION
        Evaluates custom domain DNS configuration against latest Microsoft 365 requirements
        and identifies necessary migrations:
        - MX record migration to mx.microsoft format (July-August 2025)
        - DKIM migration to new dkim.mail.microsoft format (May 2025+)
        - Email authentication mandates (SPF/DMARC mandatory April 2025)
        - Deprecated record removal (msoid, legacy Skype for Business)
        - cloud.microsoft domain consolidation (April 2025)

    .PARAMETER DomainName
        The domain name(s) to assess. If not specified, assesses all verified domains.

    .PARAMETER ShowRecommendations
        Display detailed migration recommendations for each domain.

    .PARAMETER ExportReport
        Export migration status report to CSV file.

    .PARAMETER OutputPath
        Path for exported report file (default: current directory).

    .EXAMPLE
        Get-M365DomainMigrationStatus -DomainName "contoso.com"
        Assesses migration status for contoso.com.

    .EXAMPLE
        Get-M365DomainMigrationStatus -ShowRecommendations
        Assesses all domains with detailed migration recommendations.

    .EXAMPLE
        Get-M365DomainMigrationStatus -ExportReport -OutputPath "C:\Reports"
        Assesses all domains and exports migration report.

    .OUTPUTS
        Custom object array containing migration status and recommendations.
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
        Write-Verbose "Starting migration status assessment"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }

        $migrationResults = @()
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
                Write-Host "`nAssessing migration status for: $domain" -ForegroundColor Cyan

                $migrationStatus = [PSCustomObject]@{
                    Domain = $domain
                    OverallReadiness = 0
                    MXStatus = "Unknown"
                    MXFormat = "Unknown"
                    MXNeedsMigration = $false
                    DKIMStatus = "Unknown"
                    DKIMFormat = "Unknown"
                    DKIMNeedsMigration = $false
                    EmailAuthStatus = "Unknown"
                    SPFConfigured = $false
                    DMARCConfigured = $false
                    EmailAuthReady = $false
                    DeprecatedRecords = @()
                    LegacyTeamsRecords = @()
                    CriticalActions = @()
                    Recommendations = @()
                    MigrationPriority = "Unknown"
                }

                # 1. Check MX Record Format
                Write-Verbose "Checking MX record format for $domain"
                try {
                    $mxRecords = Resolve-DnsName -Name $domain -Type MX -ErrorAction SilentlyContinue
                    if ($mxRecords) {
                        $primaryMX = $mxRecords | Sort-Object Preference | Select-Object -First 1

                        if ($primaryMX.NameExchange -like "*.mx.microsoft") {
                            $migrationStatus.MXStatus = "Modern"
                            $migrationStatus.MXFormat = "mx.microsoft (current)"
                            $migrationStatus.MXNeedsMigration = $false
                        }
                        elseif ($primaryMX.NameExchange -like "*.mail.protection.outlook.com") {
                            $migrationStatus.MXStatus = "Legacy"
                            $migrationStatus.MXFormat = "mail.protection.outlook.com (legacy)"
                            $migrationStatus.MXNeedsMigration = $true
                            $migrationStatus.CriticalActions += "Migrate MX record to mx.microsoft format (Message Center MC1048624, July-August 2025)"
                        }
                        elseif ($primaryMX.NameExchange -like "*.mail.protection.office365.us" -or
                                $primaryMX.NameExchange -like "*.protection.office365.us") {
                            $migrationStatus.MXStatus = "Government Cloud"
                            $migrationStatus.MXFormat = "office365.us (GCC/DoD)"
                            $migrationStatus.MXNeedsMigration = $false
                        }
                        elseif ($primaryMX.NameExchange -like "*.mail.protection.partner.outlook.cn") {
                            $migrationStatus.MXStatus = "21Vianet China"
                            $migrationStatus.MXFormat = "partner.outlook.cn (21Vianet)"
                            $migrationStatus.MXNeedsMigration = $false
                        }
                        else {
                            $migrationStatus.MXStatus = "Non-Microsoft"
                            $migrationStatus.MXFormat = "Third-party or hybrid"
                            $migrationStatus.MXNeedsMigration = $false
                        }
                    }
                    else {
                        $migrationStatus.MXStatus = "Missing"
                        $migrationStatus.CriticalActions += "Configure MX record for Microsoft 365"
                    }
                }
                catch {
                    Write-Verbose "Failed to check MX: $_"
                }

                # 2. Check DKIM Format
                Write-Verbose "Checking DKIM configuration for $domain"
                try {
                    $selector1 = Resolve-DnsName -Name "selector1._domainkey.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    $selector2 = Resolve-DnsName -Name "selector2._domainkey.$domain" -Type CNAME -ErrorAction SilentlyContinue

                    $hasSelector1 = $null -ne $selector1
                    $hasSelector2 = $null -ne $selector2

                    if ($hasSelector1 -or $hasSelector2) {
                        $isNewFormat = ($selector1 -and $selector1.NameHost -like "*._domainkey.*.dkim.mail.microsoft") -or
                                      ($selector2 -and $selector2.NameHost -like "*._domainkey.*.dkim.mail.microsoft")
                        $isLegacyFormat = ($selector1 -and $selector1.NameHost -like "*._domainkey.*.onmicrosoft.com") -or
                                         ($selector2 -and $selector2.NameHost -like "*._domainkey.*.onmicrosoft.com")

                        if ($isNewFormat) {
                            $migrationStatus.DKIMStatus = "Modern"
                            $migrationStatus.DKIMFormat = "dkim.mail.microsoft (current)"
                            $migrationStatus.DKIMNeedsMigration = $false
                        }
                        elseif ($isLegacyFormat) {
                            $migrationStatus.DKIMStatus = "Legacy"
                            $migrationStatus.DKIMFormat = "onmicrosoft.com (legacy)"
                            $migrationStatus.DKIMNeedsMigration = $true
                            $migrationStatus.Recommendations += "DKIM using legacy format - new deployments use dkim.mail.microsoft (May 2025+)"
                        }
                    }
                    else {
                        $migrationStatus.DKIMStatus = "Not Configured"
                        $migrationStatus.Recommendations += "Configure DKIM signing for improved email authentication"
                    }
                }
                catch {
                    Write-Verbose "Failed to check DKIM: $_"
                }

                # 3. Check Email Authentication (SPF/DMARC) - MANDATORY April 2025
                Write-Verbose "Checking email authentication status for $domain"
                try {
                    # Check SPF
                    $txtRecords = Resolve-DnsName -Name $domain -Type TXT -ErrorAction SilentlyContinue
                    $spfRecord = $txtRecords | Where-Object { $_.Strings -like "v=spf1*" } | Select-Object -First 1

                    if ($spfRecord) {
                        $spfText = $spfRecord.Strings -join ""
                        $migrationStatus.SPFConfigured = $true

                        if ($spfText -notlike "*spf.protection.outlook.com*" -and $spfText -notlike "*spf.protection.office365.us*") {
                            $migrationStatus.CriticalActions += "SPF record does not include Microsoft 365 - MANDATORY for April 2025"
                        }
                    }
                    else {
                        $migrationStatus.SPFConfigured = $false
                        $migrationStatus.CriticalActions += "CRITICAL: No SPF record found - MANDATORY for email authentication (April 2025)"
                    }

                    # Check DMARC
                    $dmarcRecord = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction SilentlyContinue
                    if ($dmarcRecord) {
                        $migrationStatus.DMARCConfigured = $true
                        $dmarcText = $dmarcRecord.Strings -join ""

                        if ($dmarcText -like "*p=none*") {
                            $migrationStatus.Recommendations += "DMARC policy is 'none' - upgrade to 'quarantine' or 'reject' for April 2025 compliance"
                        }
                    }
                    else {
                        $migrationStatus.DMARCConfigured = $false
                        $migrationStatus.CriticalActions += "CRITICAL: No DMARC record found - MANDATORY with policy p=quarantine or p=reject (April 2025)"
                    }

                    $migrationStatus.EmailAuthReady = $migrationStatus.SPFConfigured -and $migrationStatus.DMARCConfigured
                    $migrationStatus.EmailAuthStatus = if ($migrationStatus.EmailAuthReady) { "Ready" }
                                                       elseif ($migrationStatus.SPFConfigured -or $migrationStatus.DMARCConfigured) { "Partial" }
                                                       else { "Not Ready" }
                }
                catch {
                    Write-Verbose "Failed to check email authentication: $_"
                }

                # 4. Check for Deprecated Records
                Write-Verbose "Checking for deprecated records"
                try {
                    # Check msoid (CRITICAL - blocks M365 Apps)
                    $msoid = Resolve-DnsName -Name "msoid.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($msoid) {
                        $migrationStatus.DeprecatedRecords += "msoid.$domain"
                        $migrationStatus.CriticalActions += "CRITICAL: Remove msoid.$domain CNAME - BLOCKS Microsoft 365 Apps activation"
                    }
                }
                catch {
                    # Good - record doesn't exist
                }

                # 5. Check for Legacy Teams/Skype Records
                Write-Verbose "Checking for legacy Teams/Skype for Business records"
                try {
                    $sip = Resolve-DnsName -Name "sip.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($sip) {
                        $migrationStatus.LegacyTeamsRecords += "sip.$domain CNAME"
                        $migrationStatus.Recommendations += "sip.$domain CNAME is legacy (Skype for Business) - not required for Teams-only tenants"
                    }

                    $lyncdiscover = Resolve-DnsName -Name "lyncdiscover.$domain" -Type CNAME -ErrorAction SilentlyContinue
                    if ($lyncdiscover) {
                        $migrationStatus.LegacyTeamsRecords += "lyncdiscover.$domain CNAME"
                        $migrationStatus.Recommendations += "lyncdiscover.$domain CNAME is legacy (Skype for Business) - not required for Teams-only tenants"
                    }

                    $sipTLS = Resolve-DnsName -Name "_sip._tls.$domain" -Type SRV -ErrorAction SilentlyContinue
                    if ($sipTLS) {
                        $migrationStatus.LegacyTeamsRecords += "_sip._tls.$domain SRV"
                        $migrationStatus.Recommendations += "_sip._tls.$domain SRV is legacy - Teams-only needs _sipfederationtls._tcp only"
                    }
                }
                catch {
                    Write-Verbose "No legacy Teams/Skype records found"
                }

                # Calculate Overall Readiness Percentage
                $readinessPoints = 0
                $totalPoints = 5

                # MX modern format (1 point)
                if ($migrationStatus.MXStatus -eq "Modern" -or $migrationStatus.MXStatus -eq "Government Cloud" -or $migrationStatus.MXStatus -eq "21Vianet China") {
                    $readinessPoints++
                }

                # DKIM configured (1 point)
                if ($migrationStatus.DKIMStatus -ne "Not Configured") {
                    $readinessPoints++
                }

                # Email authentication ready (2 points - critical for April 2025)
                if ($migrationStatus.SPFConfigured) { $readinessPoints++ }
                if ($migrationStatus.DMARCConfigured) { $readinessPoints++ }

                # No deprecated records (1 point)
                if ($migrationStatus.DeprecatedRecords.Count -eq 0) {
                    $readinessPoints++
                }

                $migrationStatus.OverallReadiness = [math]::Round(($readinessPoints / $totalPoints) * 100, 0)

                # Determine Migration Priority
                if ($migrationStatus.DeprecatedRecords.Count -gt 0 -or -not $migrationStatus.EmailAuthReady) {
                    $migrationStatus.MigrationPriority = "CRITICAL"
                }
                elseif ($migrationStatus.MXNeedsMigration -or $migrationStatus.DKIMNeedsMigration) {
                    $migrationStatus.MigrationPriority = "High"
                }
                elseif ($migrationStatus.LegacyTeamsRecords.Count -gt 0) {
                    $migrationStatus.MigrationPriority = "Medium"
                }
                else {
                    $migrationStatus.MigrationPriority = "Low"
                }

                # Display summary
                $readinessColor = switch ($migrationStatus.OverallReadiness) {
                    { $_ -ge 80 } { "Green" }
                    { $_ -ge 60 } { "Yellow" }
                    { $_ -ge 40 } { "Magenta" }
                    default { "Red" }
                }

                Write-Host "  Overall Readiness: $($migrationStatus.OverallReadiness)%" -ForegroundColor $readinessColor
                Write-Host "  Migration Priority: $($migrationStatus.MigrationPriority)" -ForegroundColor $(
                    switch ($migrationStatus.MigrationPriority) {
                        "CRITICAL" { "Red" }
                        "High" { "Magenta" }
                        "Medium" { "Yellow" }
                        default { "Green" }
                    }
                )
                Write-Host "  MX Format: $($migrationStatus.MXFormat)" -ForegroundColor White
                Write-Host "  DKIM Format: $($migrationStatus.DKIMFormat)" -ForegroundColor White
                Write-Host "  Email Auth Status: $($migrationStatus.EmailAuthStatus)" -ForegroundColor White

                if ($migrationStatus.CriticalActions.Count -gt 0) {
                    Write-Host "`n  Critical Actions Required:" -ForegroundColor Red
                    $migrationStatus.CriticalActions | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
                }

                if ($ShowRecommendations -and $migrationStatus.Recommendations.Count -gt 0) {
                    Write-Host "`n  Recommendations:" -ForegroundColor Cyan
                    $migrationStatus.Recommendations | ForEach-Object { Write-Host "    - $_" -ForegroundColor Cyan }
                }

                if ($migrationStatus.DeprecatedRecords.Count -gt 0) {
                    Write-Host "`n  Deprecated Records (REMOVE):" -ForegroundColor Magenta
                    $migrationStatus.DeprecatedRecords | ForEach-Object { Write-Host "    - $_" -ForegroundColor Magenta }
                }

                if ($migrationStatus.LegacyTeamsRecords.Count -gt 0) {
                    Write-Host "`n  Legacy Teams/Skype Records:" -ForegroundColor Yellow
                    $migrationStatus.LegacyTeamsRecords | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
                }

                $migrationResults += $migrationStatus
            }

            # Export report if requested
            if ($ExportReport) {
                $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $reportFile = Join-Path -Path $OutputPath -ChildPath "M365-Migration-Status-$timestamp.csv"

                $exportData = $migrationResults | Select-Object Domain, OverallReadiness, MigrationPriority,
                    MXStatus, MXFormat, DKIMStatus, DKIMFormat, EmailAuthStatus, SPFConfigured, DMARCConfigured,
                    @{N='CriticalActionsCount';E={$_.CriticalActions.Count}},
                    @{N='DeprecatedRecordsCount';E={$_.DeprecatedRecords.Count}},
                    @{N='LegacyRecordsCount';E={$_.LegacyTeamsRecords.Count}}

                $exportData | Export-Csv -Path $reportFile -NoTypeInformation
                Write-Host "`nMigration report exported to: $reportFile" -ForegroundColor Green
            }

            # Display summary statistics
            Write-Host "`n=== Migration Status Summary ===" -ForegroundColor Cyan
            $totalDomains = $migrationResults.Count
            $criticalPriority = ($migrationResults | Where-Object { $_.MigrationPriority -eq "CRITICAL" }).Count
            $highPriority = ($migrationResults | Where-Object { $_.MigrationPriority -eq "High" }).Count
            $avgReadiness = [math]::Round(($migrationResults | Measure-Object -Property OverallReadiness -Average).Average, 0)

            Write-Host "Total Domains Assessed: $totalDomains" -ForegroundColor White
            Write-Host "Average Readiness: $avgReadiness%" -ForegroundColor White
            Write-Host "CRITICAL Priority: $criticalPriority" -ForegroundColor Red
            Write-Host "High Priority: $highPriority" -ForegroundColor Magenta

            return $migrationResults
        }
        catch {
            Write-Error "Failed to assess migration status: $_"
            throw
        }
    }
}
