function Test-M365DomainVerification {
    <#
    .SYNOPSIS
        Tests the verification status of Microsoft 365 domains.

    .DESCRIPTION
        Checks the verification status of specified domains or all domains in the tenant.
        Provides detailed information about verification state and any issues.

    .PARAMETER DomainName
        The domain name(s) to test. If not specified, tests all domains.

    .PARAMETER ShowOnlyUnverified
        Only show unverified domains in the results.

    .EXAMPLE
        Test-M365DomainVerification
        Tests all domains in the tenant.

    .EXAMPLE
        Test-M365DomainVerification -DomainName "contoso.com"
        Tests verification status for contoso.com.

    .EXAMPLE
        Test-M365DomainVerification -ShowOnlyUnverified
        Shows only unverified domains.

    .OUTPUTS
        Custom object array containing domain verification status.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$DomainName,

        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyUnverified
    )

    begin {
        Write-Verbose "Starting domain verification test"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }

        $results = @()
    }

    process {
        try {
            # If no domain specified, get all domains
            if (-not $DomainName) {
                Write-Verbose "No domain specified, testing all domains"
                $domains = Get-MgDomain -All
            }
            else {
                $domains = @()
                foreach ($domain in $DomainName) {
                    try {
                        $domains += Get-MgDomain -DomainId $domain -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Failed to retrieve domain $domain : $_"
                    }
                }
            }

            if (-not $domains) {
                Write-Warning "No domains found"
                return
            }

            Write-Verbose "Testing $($domains.Count) domain(s)"

            foreach ($domain in $domains) {
                # Skip verified domains if ShowOnlyUnverified is specified
                if ($ShowOnlyUnverified -and $domain.IsVerified) {
                    continue
                }

                # Create result object
                $result = [PSCustomObject]@{
                    DomainName = $domain.Id
                    IsVerified = $domain.IsVerified
                    IsDefault = $domain.IsDefault
                    IsInitial = $domain.IsInitial
                    AuthenticationType = $domain.AuthenticationType
                    AvailabilityStatus = $domain.AvailabilityStatus
                    State = if ($domain.State) { $domain.State.Status } else { 'N/A' }
                    SupportedServices = $domain.SupportedServices -join ', '
                    Status = if ($domain.IsVerified) { 'Verified' } else { 'Unverified' }
                }

                # Add verification records for unverified domains
                if (-not $domain.IsVerified) {
                    try {
                        $verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId $domain.Id -ErrorAction SilentlyContinue
                        if ($verificationRecords) {
                            $txtRecord = $verificationRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Txt' } | Select-Object -First 1
                            if ($txtRecord) {
                                $result | Add-Member -MemberType NoteProperty -Name 'VerificationTXT' -Value $txtRecord.AdditionalProperties['text']
                            }
                        }
                    }
                    catch {
                        Write-Verbose "Could not retrieve verification records for $($domain.Id)"
                    }
                }

                $results += $result
            }

            # Display summary
            Write-Host "`nDomain Verification Summary:" -ForegroundColor Cyan
            Write-Host "  Total Domains Tested: $($results.Count)" -ForegroundColor White

            $verifiedCount = ($results | Where-Object { $_.IsVerified }).Count
            $unverifiedCount = ($results | Where-Object { -not $_.IsVerified }).Count

            Write-Host "  Verified: $verifiedCount" -ForegroundColor Green
            Write-Host "  Unverified: $unverifiedCount" -ForegroundColor Yellow

            # Show unverified domains
            if ($unverifiedCount -gt 0) {
                Write-Host "`n  Unverified Domains:" -ForegroundColor Yellow
                $results | Where-Object { -not $_.IsVerified } | ForEach-Object {
                    Write-Host "    - $($_.DomainName)" -ForegroundColor White
                }
            }

            return $results
        }
        catch {
            Write-Error "Failed to test domain verification: $_"
            throw
        }
    }
}
