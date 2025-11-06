function Get-M365Domain {
    <#
    .SYNOPSIS
        Retrieves all domains from Microsoft 365 tenant.

    .DESCRIPTION
        Enumerates all domains in the Microsoft 365 tenant and optionally filters
        by verification status (Verified or Unverified).

    .PARAMETER VerificationStatus
        Filter domains by verification status. Valid values: 'All', 'Verified', 'Unverified'
        Default is 'All'.

    .PARAMETER IncludeDetails
        Include additional domain details such as authentication type, supported services,
        and capabilities.

    .EXAMPLE
        Get-M365Domain
        Retrieves all domains in the tenant.

    .EXAMPLE
        Get-M365Domain -VerificationStatus Verified
        Retrieves only verified domains.

    .EXAMPLE
        Get-M365Domain -VerificationStatus Unverified
        Retrieves only unverified domains.

    .EXAMPLE
        $domains = Get-M365Domain -IncludeDetails
        $domains | Where-Object { $_.SupportedServices -contains 'Email' }
        Retrieves all domains with detailed information and filters for email-enabled domains.

    .OUTPUTS
        Custom object array containing domain information.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('All', 'Verified', 'Unverified')]
        [string]$VerificationStatus = 'All',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    begin {
        Write-Verbose "Starting domain enumeration"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }
    }

    process {
        try {
            Write-Verbose "Retrieving domains from tenant: $($context.TenantId)"

            # Get all domains
            $domains = Get-MgDomain -All -ErrorAction Stop

            if (-not $domains) {
                Write-Warning "No domains found in tenant"
                return
            }

            Write-Verbose "Found $($domains.Count) total domain(s)"

            # Process domains
            $results = foreach ($domain in $domains) {
                # Create custom object with essential information
                $domainInfo = [PSCustomObject]@{
                    DomainName = $domain.Id
                    IsVerified = $domain.IsVerified
                    IsDefault = $domain.IsDefault
                    IsInitial = $domain.IsInitial
                    AuthenticationType = $domain.AuthenticationType
                    SupportedServices = $domain.SupportedServices
                }

                # Add additional details if requested
                if ($IncludeDetails) {
                    $domainInfo | Add-Member -MemberType NoteProperty -Name 'AvailabilityStatus' -Value $domain.AvailabilityStatus
                    $domainInfo | Add-Member -MemberType NoteProperty -Name 'IsAdminManaged' -Value $domain.IsAdminManaged
                    $domainInfo | Add-Member -MemberType NoteProperty -Name 'State' -Value $domain.State
                    $domainInfo | Add-Member -MemberType NoteProperty -Name 'PasswordValidityPeriodInDays' -Value $domain.PasswordValidityPeriodInDays
                    $domainInfo | Add-Member -MemberType NoteProperty -Name 'PasswordNotificationWindowInDays' -Value $domain.PasswordNotificationWindowInDays
                }

                # Output based on filter
                switch ($VerificationStatus) {
                    'Verified' {
                        if ($domain.IsVerified) { $domainInfo }
                    }
                    'Unverified' {
                        if (-not $domain.IsVerified) { $domainInfo }
                    }
                    'All' {
                        $domainInfo
                    }
                }
            }

            # Display summary
            $verifiedCount = ($results | Where-Object { $_.IsVerified }).Count
            $unverifiedCount = ($results | Where-Object { -not $_.IsVerified }).Count

            Write-Host "`nDomain Summary:" -ForegroundColor Cyan
            Write-Host "  Total Domains: $($results.Count)" -ForegroundColor White
            Write-Host "  Verified: $verifiedCount" -ForegroundColor Green
            Write-Host "  Unverified: $unverifiedCount" -ForegroundColor Yellow

            return $results
        }
        catch {
            Write-Error "Failed to retrieve domains: $_"
            throw
        }
    }
}
