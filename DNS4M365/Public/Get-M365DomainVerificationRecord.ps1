function Get-M365DomainVerificationRecord {
    <#
    .SYNOPSIS
        Retrieves domain verification DNS records for Microsoft 365 domains.

    .DESCRIPTION
        Queries Microsoft Graph API to retrieve the DNS records required to verify
        domain ownership in Microsoft 365. These are typically TXT or MX records.

    .PARAMETER DomainName
        The domain name to query. If not specified, retrieves verification records
        for all unverified domains.

    .PARAMETER UnverifiedOnly
        Only query verification records for unverified domains. Default is $true.

    .EXAMPLE
        Get-M365DomainVerificationRecord -DomainName "contoso.com"
        Retrieves verification records for contoso.com.

    .EXAMPLE
        Get-M365DomainVerificationRecord
        Retrieves verification records for all unverified domains.

    .EXAMPLE
        Get-M365DomainVerificationRecord -UnverifiedOnly $false
        Retrieves verification records for all domains, including verified ones.

    .OUTPUTS
        Custom object array containing verification record details.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Domain', 'Id')]
        [string[]]$DomainName,

        [Parameter(Mandatory = $false)]
        [bool]$UnverifiedOnly = $true
    )

    begin {
        Write-Verbose "Starting domain verification record retrieval"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-M365DNS first."
        }

        $allRecords = @()
    }

    process {
        try {
            # If no domain specified, get all domains
            if (-not $DomainName) {
                Write-Verbose "No domain specified, retrieving all domains"
                $domains = Get-MgDomain -All

                if ($UnverifiedOnly) {
                    $domains = $domains | Where-Object { $_.IsVerified -eq $false }
                    Write-Verbose "Filtering to unverified domains only: $($domains.Count) domain(s)"
                }

                $DomainName = $domains.Id
            }

            if (-not $DomainName -or $DomainName.Count -eq 0) {
                Write-Host "No domains found matching the criteria" -ForegroundColor Yellow
                return
            }

            foreach ($domain in $DomainName) {
                Write-Verbose "Querying verification records for domain: $domain"

                try {
                    # Get domain info to check verification status
                    $domainInfo = Get-MgDomain -DomainId $domain -ErrorAction Stop

                    # Get verification DNS records
                    $verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId $domain -ErrorAction Stop

                    if (-not $verificationRecords) {
                        Write-Verbose "No verification records found for $domain"
                        continue
                    }

                    foreach ($record in $verificationRecords) {
                        # Determine record type
                        $recordType = $record.AdditionalProperties['recordType']

                        # Create custom object with verification record details
                        $verificationInfo = [PSCustomObject]@{
                            Domain = $domain
                            IsVerified = $domainInfo.IsVerified
                            RecordType = $recordType
                            Label = $record.AdditionalProperties['label']
                            TTL = $record.AdditionalProperties['ttl']
                            Id = $record.Id
                        }

                        # Add type-specific properties
                        switch ($recordType) {
                            'Txt' {
                                $verificationInfo | Add-Member -MemberType NoteProperty -Name 'Text' -Value $record.AdditionalProperties['text']
                            }
                            'Mx' {
                                $verificationInfo | Add-Member -MemberType NoteProperty -Name 'MailExchange' -Value $record.AdditionalProperties['mailExchange']
                                $verificationInfo | Add-Member -MemberType NoteProperty -Name 'Preference' -Value $record.AdditionalProperties['preference']
                            }
                        }

                        $allRecords += $verificationInfo
                    }
                }
                catch {
                    Write-Warning "Failed to retrieve verification records for $domain : $_"
                    continue
                }
            }

            # Display summary
            if ($allRecords.Count -gt 0) {
                Write-Host "`nVerification Records Summary:" -ForegroundColor Cyan
                Write-Host "  Total Domains: $($DomainName.Count)" -ForegroundColor White
                Write-Host "  Total Records: $($allRecords.Count)" -ForegroundColor White

                $verifiedDomains = ($allRecords | Where-Object { $_.IsVerified }).Count
                $unverifiedDomains = ($allRecords | Where-Object { -not $_.IsVerified }).Count

                Write-Host "  Verified Domains: $verifiedDomains" -ForegroundColor Green
                Write-Host "  Unverified Domains: $unverifiedDomains" -ForegroundColor Yellow

                # Show record types
                $groupedByType = $allRecords | Group-Object -Property RecordType
                Write-Host "`n  Record Types:" -ForegroundColor Cyan
                foreach ($group in $groupedByType) {
                    Write-Host "    $($group.Name): $($group.Count)" -ForegroundColor White
                }
            }
            else {
                Write-Warning "No verification records found matching the specified criteria"
            }

            return $allRecords
        }
        catch {
            Write-Error "Failed to retrieve verification records: $_"
            throw
        }
    }
}
