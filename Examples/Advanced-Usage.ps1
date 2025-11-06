# DNS4M365 Module - Advanced Usage Examples
# This script demonstrates advanced scenarios and best practices

# ============================================================================
# Example 1: Comprehensive Domain Audit
# ============================================================================

Write-Host "`n=== Example 1: Comprehensive Domain Audit ===" -ForegroundColor Cyan

# Connect to Microsoft 365
Connect-M365DNS

# Get all domains with detailed information
$domains = Get-M365Domain -IncludeDetails

# Create audit report
$auditReport = foreach ($domain in $domains) {
    Write-Host "Auditing: $($domain.DomainName)" -ForegroundColor Yellow

    # Get DNS records if verified
    $dnsRecords = @()
    if ($domain.IsVerified) {
        $dnsRecords = Get-M365DomainDNSRecord -DomainName $domain.DomainName
    }

    # Create detailed audit entry
    [PSCustomObject]@{
        DomainName = $domain.DomainName
        IsVerified = $domain.IsVerified
        IsDefault = $domain.IsDefault
        IsInitial = $domain.IsInitial
        SupportedServices = ($domain.SupportedServices -join ', ')
        TotalDNSRecords = $dnsRecords.Count
        MXRecords = ($dnsRecords | Where-Object { $_.RecordType -eq 'MX' }).Count
        CNAMERecords = ($dnsRecords | Where-Object { $_.RecordType -eq 'CNAME' }).Count
        TXTRecords = ($dnsRecords | Where-Object { $_.RecordType -eq 'TXT' }).Count
        SRVRecords = ($dnsRecords | Where-Object { $_.RecordType -eq 'SRV' }).Count
        EmailEnabled = $domain.SupportedServices -contains 'Email'
        TeamsEnabled = $domain.SupportedServices -contains 'OfficeCommunicationsOnline'
        SharePointEnabled = $domain.SupportedServices -contains 'SharePoint'
        AuditDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

# Display and export
$auditReport | Format-Table -AutoSize
$auditReport | Export-Csv -Path "Domain-Audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation

# ============================================================================
# Example 2: DMARC and SPF Record Analysis
# ============================================================================

Write-Host "`n=== Example 2: Email Security Record Analysis ===" -ForegroundColor Cyan

# Get all TXT records for email service
$txtRecords = Get-M365DomainDNSRecord -RecordType TXT -ServiceType Email

# Analyze SPF records
Write-Host "`nSPF Records:" -ForegroundColor Green
$spfRecords = $txtRecords | Where-Object { $_.Text -like "v=spf1*" }
foreach ($record in $spfRecords) {
    [PSCustomObject]@{
        Domain = $record.Domain
        Label = $record.Label
        SPFRecord = $record.Text
        IncludesOutlook = $record.Text -like "*outlook.com*"
        HardFail = $record.Text -like "*-all"
        SoftFail = $record.Text -like "*~all"
    }
} | Format-Table -AutoSize

# Check for DMARC records (requires custom domain DNS query)
Write-Host "`nNote: DMARC records (_dmarc subdomain) must be queried from actual DNS" -ForegroundColor Yellow
Write-Host "Use 'Resolve-DnsName _dmarc.yourdomain.com -Type TXT' to check DMARC" -ForegroundColor Yellow

# ============================================================================
# Example 3: Service-Specific DNS Record Extraction
# ============================================================================

Write-Host "`n=== Example 3: Service-Specific DNS Records ===" -ForegroundColor Cyan

# Get all verified domains
$verifiedDomains = Get-M365Domain -VerificationStatus Verified

foreach ($domain in $verifiedDomains) {
    Write-Host "`nDomain: $($domain.DomainName)" -ForegroundColor Cyan

    # Get all DNS records for this domain
    $records = Get-M365DomainDNSRecord -DomainName $domain.DomainName

    # Email (Exchange) records
    $emailRecords = $records | Where-Object { $_.SupportedService -eq 'Email' }
    if ($emailRecords) {
        Write-Host "  Email Records: $($emailRecords.Count)" -ForegroundColor Green
        $emailRecords | Select-Object RecordType, Label | Format-Table
    }

    # Teams (Skype for Business Online) records
    $teamsRecords = $records | Where-Object { $_.SupportedService -eq 'OfficeCommunicationsOnline' }
    if ($teamsRecords) {
        Write-Host "  Teams Records: $($teamsRecords.Count)" -ForegroundColor Green
        $teamsRecords | Select-Object RecordType, Label | Format-Table
    }

    # Intune (MDM) records
    $intuneRecords = $records | Where-Object { $_.SupportedService -eq 'Intune' }
    if ($intuneRecords) {
        Write-Host "  Intune Records: $($intuneRecords.Count)" -ForegroundColor Green
        $intuneRecords | Select-Object RecordType, Label | Format-Table
    }
}

# ============================================================================
# Example 4: Compare Expected vs Actual DNS Records
# ============================================================================

Write-Host "`n=== Example 4: DNS Configuration Validation ===" -ForegroundColor Cyan

function Test-DnsRecordExists {
    param(
        [string]$DomainName,
        [string]$RecordName,
        [string]$RecordType
    )

    try {
        $fqdn = if ($RecordName -eq '@') { $DomainName } else { "$RecordName.$DomainName" }
        $result = Resolve-DnsName -Name $fqdn -Type $RecordType -ErrorAction SilentlyContinue
        return $null -ne $result
    }
    catch {
        return $false
    }
}

# Get expected records from Microsoft 365
$expectedRecords = Get-M365DomainDNSRecord

# Sample validation (you can expand this)
Write-Host "`nValidating DNS records against actual DNS..." -ForegroundColor Yellow
Write-Host "Note: This requires DNS resolution and may take time" -ForegroundColor Yellow

$validationResults = foreach ($record in $expectedRecords | Select-Object -First 5) {
    $exists = Test-DnsRecordExists -DomainName $record.Domain -RecordName $record.Label -RecordType $record.RecordType

    [PSCustomObject]@{
        Domain = $record.Domain
        RecordType = $record.RecordType
        Label = $record.Label
        ExpectedInM365 = $true
        ExistsInDNS = $exists
        Status = if ($exists) { "✓ Configured" } else { "✗ Missing" }
    }
}

$validationResults | Format-Table -AutoSize

# ============================================================================
# Example 5: Multi-Tenant Domain Comparison
# ============================================================================

Write-Host "`n=== Example 5: Multi-Tenant Comparison ===" -ForegroundColor Cyan
Write-Host "This example shows how to compare domains across tenants" -ForegroundColor Yellow

function Get-TenantDomainInfo {
    param([string]$TenantId, [string]$TenantName)

    Write-Host "`nConnecting to tenant: $TenantName" -ForegroundColor Cyan
    Connect-M365DNS -TenantId $TenantId

    $domains = Get-M365Domain
    $records = Get-M365DomainDNSRecord

    return [PSCustomObject]@{
        TenantName = $TenantName
        TenantId = $TenantId
        TotalDomains = $domains.Count
        VerifiedDomains = ($domains | Where-Object { $_.IsVerified }).Count
        TotalDNSRecords = $records.Count
        CollectionDate = Get-Date
    }
}

# Uncomment and modify with your tenant IDs
# $tenant1 = Get-TenantDomainInfo -TenantId "tenant1-guid" -TenantName "Production"
# $tenant2 = Get-TenantDomainInfo -TenantId "tenant2-guid" -TenantName "Development"
# @($tenant1, $tenant2) | Format-Table -AutoSize

# ============================================================================
# Example 6: Automated Health Check and Alerting
# ============================================================================

Write-Host "`n=== Example 6: Automated Health Check ===" -ForegroundColor Cyan

function Test-M365DomainHealth {
    $healthReport = @{
        Timestamp = Get-Date
        TotalDomains = 0
        VerifiedDomains = 0
        UnverifiedDomains = 0
        DomainsWithIssues = @()
        OverallStatus = "Unknown"
    }

    try {
        # Get all domains
        $domains = Get-M365Domain

        $healthReport.TotalDomains = $domains.Count
        $healthReport.VerifiedDomains = ($domains | Where-Object { $_.IsVerified }).Count
        $healthReport.UnverifiedDomains = ($domains | Where-Object { -not $_.IsVerified }).Count

        # Check for potential issues
        foreach ($domain in $domains) {
            $issues = @()

            # Check if domain is unverified
            if (-not $domain.IsVerified) {
                $issues += "Domain not verified"
            }

            # Check if domain supports email but has no DNS records
            if ($domain.IsVerified -and $domain.SupportedServices -contains 'Email') {
                $dnsRecords = Get-M365DomainDNSRecord -DomainName $domain.DomainName
                if ($dnsRecords.Count -eq 0) {
                    $issues += "No DNS records found for email-enabled domain"
                }
            }

            if ($issues.Count -gt 0) {
                $healthReport.DomainsWithIssues += [PSCustomObject]@{
                    Domain = $domain.DomainName
                    Issues = $issues -join '; '
                }
            }
        }

        # Determine overall status
        if ($healthReport.UnverifiedDomains -eq 0 -and $healthReport.DomainsWithIssues.Count -eq 0) {
            $healthReport.OverallStatus = "Healthy"
        }
        elseif ($healthReport.UnverifiedDomains -gt 0 -or $healthReport.DomainsWithIssues.Count -le 2) {
            $healthReport.OverallStatus = "Warning"
        }
        else {
            $healthReport.OverallStatus = "Critical"
        }

        return $healthReport
    }
    catch {
        Write-Error "Health check failed: $_"
        return $healthReport
    }
}

# Run health check
$health = Test-M365DomainHealth

Write-Host "`nHealth Check Results:" -ForegroundColor Cyan
Write-Host "  Status: $($health.OverallStatus)" -ForegroundColor $(
    switch ($health.OverallStatus) {
        "Healthy" { "Green" }
        "Warning" { "Yellow" }
        "Critical" { "Red" }
        default { "White" }
    }
)
Write-Host "  Total Domains: $($health.TotalDomains)" -ForegroundColor White
Write-Host "  Verified: $($health.VerifiedDomains)" -ForegroundColor Green
Write-Host "  Unverified: $($health.UnverifiedDomains)" -ForegroundColor Yellow
Write-Host "  Issues Found: $($health.DomainsWithIssues.Count)" -ForegroundColor $(if ($health.DomainsWithIssues.Count -eq 0) { "Green" } else { "Red" })

if ($health.DomainsWithIssues.Count -gt 0) {
    Write-Host "`n  Domains with Issues:" -ForegroundColor Red
    $health.DomainsWithIssues | Format-Table -AutoSize
}

# ============================================================================
# Example 7: Export for External DNS Provider
# ============================================================================

Write-Host "`n=== Example 7: Generate DNS Zone File Format ===" -ForegroundColor Cyan

function Export-M365DnsToZoneFile {
    param(
        [string]$DomainName,
        [string]$OutputPath = ".\$DomainName-zone.txt"
    )

    $records = Get-M365DomainDNSRecord -DomainName $DomainName

    $zoneContent = @"
; DNS Zone file for $DomainName
; Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
; Source: Microsoft 365 DNS4M365 Module
;
; IMPORTANT: Review and adjust TTL values as needed
;
"@

    foreach ($record in $records) {
        $label = if ($record.Label -eq '@') { '@' } else { $record.Label }

        switch ($record.RecordType) {
            'MX' {
                $zoneContent += "`n$label`tIN`tMX`t$($record.Preference)`t$($record.MailExchange)"
            }
            'CNAME' {
                $zoneContent += "`n$label`tIN`tCNAME`t$($record.CanonicalName)"
            }
            'TXT' {
                $zoneContent += "`n$label`tIN`tTXT`t`"$($record.Text)`""
            }
            'SRV' {
                $service = $record.Service
                $protocol = $record.Protocol
                $zoneContent += "`n$service.$protocol.$DomainName`tIN`tSRV`t$($record.Priority)`t$($record.Weight)`t$($record.Port)`t$($record.NameTarget)"
            }
        }
    }

    $zoneContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Zone file exported to: $OutputPath" -ForegroundColor Green
    return $OutputPath
}

# Example: Export first verified domain
$firstDomain = (Get-M365Domain -VerificationStatus Verified | Select-Object -First 1).DomainName
if ($firstDomain) {
    # Export-M365DnsToZoneFile -DomainName $firstDomain
    Write-Host "To export zone file, uncomment the line above and specify your domain" -ForegroundColor Yellow
}

# ============================================================================
# Example 8: Scheduled Report Generation
# ============================================================================

Write-Host "`n=== Example 8: Scheduled Report Generation ===" -ForegroundColor Cyan
Write-Host "Use this function in a scheduled task for automated reporting" -ForegroundColor Yellow

function Invoke-M365DailyDomainReport {
    param(
        [string]$OutputDirectory = "C:\Reports\M365Domains",
        [string]$EmailTo,
        [string]$SmtpServer
    )

    try {
        # Ensure output directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }

        # Connect
        Connect-M365DNS

        # Generate comprehensive report
        $reportDate = Get-Date -Format 'yyyyMMdd'
        $reportPath = Export-M365DomainReport -OutputPath $OutputDirectory `
                                               -Format All `
                                               -ReportName "Daily-Domain-Report-$reportDate" `
                                               -IncludeUnverified

        # Optional: Send email notification
        if ($EmailTo -and $SmtpServer) {
            $emailParams = @{
                To = $EmailTo
                From = "m365reports@yourdomain.com"
                Subject = "Microsoft 365 Domain DNS Report - $(Get-Date -Format 'yyyy-MM-dd')"
                Body = "Daily domain DNS report has been generated. See attached files."
                Attachments = $reportPath
                SmtpServer = $SmtpServer
            }
            # Send-MailMessage @emailParams
        }

        Write-Host "Daily report generated successfully" -ForegroundColor Green
        return $reportPath
    }
    catch {
        Write-Error "Failed to generate daily report: $_"
    }
}

# ============================================================================
# Cleanup
# ============================================================================

Write-Host "`n=== Advanced Examples Completed ===" -ForegroundColor Cyan
Write-Host "These examples can be adapted for your specific requirements" -ForegroundColor White
Write-Host "See the documentation for more information" -ForegroundColor White
