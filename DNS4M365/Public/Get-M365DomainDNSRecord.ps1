function Get-M365DomainDNSRecord {
    <#
    .SYNOPSIS
        Retrieves DNS service configuration records for Microsoft 365 domains.

    .DESCRIPTION
        Queries Microsoft Graph API to retrieve all DNS records required for Microsoft 365
        services including MX, CNAME, TXT, SRV records for email, SharePoint, Teams, etc.

    .PARAMETER DomainName
        The domain name to query. If not specified, retrieves records for all verified domains.

    .PARAMETER RecordType
        Filter by specific DNS record type(s). Valid values: 'MX', 'CNAME', 'TXT', 'SRV', 'All'
        Default is 'All'.

    .PARAMETER ServiceType
        Filter by Microsoft 365 service type. Valid values: 'Email', 'SharePoint', 'Teams',
        'Intune', 'OfficeCommunicationsOnline', 'All'

    .PARAMETER VerifiedOnly
        Only query DNS records for verified domains. Default is $true.

    .EXAMPLE
        Get-M365DomainDNSRecord -DomainName "contoso.com"
        Retrieves all DNS records for contoso.com.

    .EXAMPLE
        Get-M365DomainDNSRecord -RecordType MX
        Retrieves all MX records for all verified domains.

    .EXAMPLE
        Get-M365DomainDNSRecord -DomainName "contoso.com" -RecordType CNAME
        Retrieves only CNAME records for contoso.com.

    .EXAMPLE
        Get-M365DomainDNSRecord -ServiceType Email
        Retrieves DNS records for email services across all domains.

    .OUTPUTS
        Custom object array containing DNS record details.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Domain', 'Id')]
        [string[]]$DomainName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('MX', 'CNAME', 'TXT', 'SRV', 'All')]
        [string[]]$RecordType = @('All'),

        [Parameter(Mandatory = $false)]
        [ValidateSet('Email', 'SharePoint', 'Teams', 'Intune', 'OfficeCommunicationsOnline', 'All')]
        [string]$ServiceType = 'All',

        [Parameter(Mandatory = $false)]
        [bool]$VerifiedOnly = $true
    )

    begin {
        Write-Verbose "Starting DNS record retrieval"

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

                if ($VerifiedOnly) {
                    $domains = $domains | Where-Object { $_.IsVerified -eq $true }
                    Write-Verbose "Filtering to verified domains only: $($domains.Count) domain(s)"
                }

                $DomainName = $domains.Id
            }

            foreach ($domain in $DomainName) {
                Write-Verbose "Querying DNS records for domain: $domain"

                try {
                    # Get service configuration records
                    $dnsRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain -ErrorAction Stop

                    if (-not $dnsRecords) {
                        Write-Verbose "No DNS records found for $domain"
                        continue
                    }

                    foreach ($record in $dnsRecords) {
                        # Determine record type from AdditionalProperties
                        $recordTypeValue = $record.AdditionalProperties['recordType']

                        # Filter by record type if specified
                        if ($RecordType -notcontains 'All' -and $recordTypeValue -notin $RecordType) {
                            continue
                        }

                        # Create custom object with DNS record details
                        $dnsInfo = [PSCustomObject]@{
                            Domain = $domain
                            RecordType = $recordTypeValue
                            Label = $record.Label
                            SupportedService = $record.SupportedService
                            TTL = $record.Ttl
                            IsOptional = $record.IsOptional
                            Id = $record.Id
                        }

                        # Add type-specific properties
                        switch ($recordTypeValue) {
                            'MX' {
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'MailExchange' -Value $record.AdditionalProperties['mailExchange']
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Preference' -Value $record.AdditionalProperties['preference']
                            }
                            'CNAME' {
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'CanonicalName' -Value $record.AdditionalProperties['canonicalName']
                            }
                            'TXT' {
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Text' -Value $record.AdditionalProperties['text']
                            }
                            'SRV' {
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'NameTarget' -Value $record.AdditionalProperties['nameTarget']
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Port' -Value $record.AdditionalProperties['port']
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Priority' -Value $record.AdditionalProperties['priority']
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $record.AdditionalProperties['protocol']
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Service' -Value $record.AdditionalProperties['service']
                                $dnsInfo | Add-Member -MemberType NoteProperty -Name 'Weight' -Value $record.AdditionalProperties['weight']
                            }
                        }

                        # Filter by service type if specified
                        if ($ServiceType -eq 'All' -or $record.SupportedService -eq $ServiceType) {
                            $allRecords += $dnsInfo
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to retrieve DNS records for $domain : $_"
                    continue
                }
            }

            # Display summary
            if ($allRecords.Count -gt 0) {
                Write-Host "`nDNS Records Summary:" -ForegroundColor Cyan
                Write-Host "  Total Records: $($allRecords.Count)" -ForegroundColor White

                $groupedByType = $allRecords | Group-Object -Property RecordType
                foreach ($group in $groupedByType) {
                    Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor Yellow
                }

                $groupedByService = $allRecords | Group-Object -Property SupportedService
                Write-Host "`n  By Service:" -ForegroundColor Cyan
                foreach ($group in $groupedByService) {
                    Write-Host "    $($group.Name): $($group.Count)" -ForegroundColor White
                }
            }
            else {
                Write-Warning "No DNS records found matching the specified criteria"
            }

            return $allRecords
        }
        catch {
            Write-Error "Failed to retrieve DNS records: $_"
            throw
        }
    }
}
