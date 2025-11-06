# DNS4M365 Module - Basic Usage Examples
# This script demonstrates basic usage of the DNS4M365 PowerShell module

# ============================================================================
# Example 1: Connect to Microsoft 365
# ============================================================================

Write-Host "`n=== Example 1: Connecting to Microsoft 365 ===" -ForegroundColor Cyan

# Basic connection (will prompt for credentials)
Connect-M365DNS

# Or connect to a specific tenant
# Connect-M365DNS -TenantId "00000000-0000-0000-0000-000000000000"

# Or use device code flow (for headless environments)
# Connect-M365DNS -UseDeviceCode

# ============================================================================
# Example 2: List All Domains
# ============================================================================

Write-Host "`n=== Example 2: Listing All Domains ===" -ForegroundColor Cyan

# Get all domains
$allDomains = Get-M365Domain
$allDomains | Format-Table DomainName, IsVerified, IsDefault, IsInitial

# Get only verified domains
$verifiedDomains = Get-M365Domain -VerificationStatus Verified
Write-Host "`nVerified Domains:" -ForegroundColor Green
$verifiedDomains | Format-Table DomainName, SupportedServices

# Get only unverified domains
$unverifiedDomains = Get-M365Domain -VerificationStatus Unverified
Write-Host "`nUnverified Domains:" -ForegroundColor Yellow
$unverifiedDomains | Format-Table DomainName, IsVerified

# ============================================================================
# Example 3: Get DNS Records for All Verified Domains
# ============================================================================

Write-Host "`n=== Example 3: Getting DNS Records ===" -ForegroundColor Cyan

# Get all DNS records for all verified domains
$allRecords = Get-M365DomainDNSRecord
$allRecords | Format-Table Domain, RecordType, Label, SupportedService

# Group by record type
Write-Host "`nRecords by Type:" -ForegroundColor Green
$allRecords | Group-Object RecordType | Select-Object Name, Count | Format-Table

# ============================================================================
# Example 4: Get DNS Records for a Specific Domain
# ============================================================================

Write-Host "`n=== Example 4: Domain-Specific DNS Records ===" -ForegroundColor Cyan

# Replace 'contoso.com' with your actual domain
$domainName = "contoso.com"

if ($verifiedDomains.DomainName -contains $domainName) {
    $domainRecords = Get-M365DomainDNSRecord -DomainName $domainName
    $domainRecords | Format-Table RecordType, Label, SupportedService
}
else {
    Write-Host "Domain $domainName not found in verified domains" -ForegroundColor Yellow
}

# ============================================================================
# Example 5: Filter by Record Type
# ============================================================================

Write-Host "`n=== Example 5: Filtering by Record Type ===" -ForegroundColor Cyan

# Get only MX records
Write-Host "`nMX Records:" -ForegroundColor Green
$mxRecords = Get-M365DomainDNSRecord -RecordType MX
$mxRecords | Format-Table Domain, Label, MailExchange, Preference

# Get only CNAME records
Write-Host "`nCNAME Records:" -ForegroundColor Green
$cnameRecords = Get-M365DomainDNSRecord -RecordType CNAME
$cnameRecords | Format-Table Domain, Label, CanonicalName

# Get only TXT records (SPF, DMARC, etc.)
Write-Host "`nTXT Records:" -ForegroundColor Green
$txtRecords = Get-M365DomainDNSRecord -RecordType TXT
$txtRecords | Format-Table Domain, Label, Text

# ============================================================================
# Example 6: Filter by Service Type
# ============================================================================

Write-Host "`n=== Example 6: Filtering by Service Type ===" -ForegroundColor Cyan

# Get only email-related DNS records
$emailRecords = Get-M365DomainDNSRecord -ServiceType Email
Write-Host "`nEmail Service Records:" -ForegroundColor Green
$emailRecords | Format-Table Domain, RecordType, Label

# ============================================================================
# Example 7: Get Verification Records
# ============================================================================

Write-Host "`n=== Example 7: Getting Verification Records ===" -ForegroundColor Cyan

# Get verification records for unverified domains
$verificationRecords = Get-M365DomainVerificationRecord
if ($verificationRecords) {
    $verificationRecords | Format-Table Domain, IsVerified, RecordType, Text
}
else {
    Write-Host "No unverified domains found" -ForegroundColor Green
}

# ============================================================================
# Example 8: Test Domain Verification Status
# ============================================================================

Write-Host "`n=== Example 8: Testing Domain Verification ===" -ForegroundColor Cyan

# Test all domains
$verificationStatus = Test-M365DomainVerification
$verificationStatus | Format-Table DomainName, Status, SupportedServices

# Test specific domain
if ($domainName) {
    $specificTest = Test-M365DomainVerification -DomainName $domainName
    $specificTest | Format-List
}

# Show only unverified domains
Write-Host "`nUnverified Domains Only:" -ForegroundColor Yellow
$unverifiedStatus = Test-M365DomainVerification -ShowOnlyUnverified
$unverifiedStatus | Format-Table DomainName, Status, VerificationTXT

# ============================================================================
# Example 9: Export Reports
# ============================================================================

Write-Host "`n=== Example 9: Exporting Reports ===" -ForegroundColor Cyan

# Export to CSV (default)
$csvReport = Export-M365DomainReport
Write-Host "CSV Report saved to: $csvReport" -ForegroundColor Green

# Export to JSON
$jsonReport = Export-M365DomainReport -Format JSON -ReportName "M365-Domains-$(Get-Date -Format 'yyyyMMdd')"
Write-Host "JSON Report saved to: $jsonReport" -ForegroundColor Green

# Export to HTML
$htmlReport = Export-M365DomainReport -Format HTML -ReportName "M365-Domain-Report"
Write-Host "HTML Report saved to: $htmlReport" -ForegroundColor Green

# Export all formats including unverified domains
$allReports = Export-M365DomainReport -Format All -IncludeUnverified
Write-Host "All reports saved:" -ForegroundColor Green
$allReports | ForEach-Object { Write-Host "  $_" }

# ============================================================================
# Cleanup
# ============================================================================

Write-Host "`n=== Script Completed ===" -ForegroundColor Cyan
Write-Host "For more information, see the documentation in the docs folder" -ForegroundColor White
