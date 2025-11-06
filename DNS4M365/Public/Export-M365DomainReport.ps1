function Export-M365DomainReport {
    <#
    .SYNOPSIS
        Exports a comprehensive report of Microsoft 365 domain DNS records.

    .DESCRIPTION
        Generates a detailed report of all domains and their DNS records, including
        verification status, service configuration records, and exports to various formats.

    .PARAMETER OutputPath
        The path where the report file(s) will be saved. Default is current directory.

    .PARAMETER Format
        The output format for the report. Valid values: 'CSV', 'JSON', 'HTML', 'All'
        Default is 'CSV'.

    .PARAMETER IncludeUnverified
        Include unverified domains in the report. Default is $false.

    .PARAMETER IncludeVerificationRecords
        Include verification records for unverified domains. Default is $true when
        IncludeUnverified is $true.

    .PARAMETER ReportName
        Custom name for the report file(s). Default is 'M365-Domain-Report-[timestamp]'.

    .EXAMPLE
        Export-M365DomainReport
        Exports a CSV report of all verified domains and their DNS records.

    .EXAMPLE
        Export-M365DomainReport -Format All -IncludeUnverified
        Exports reports in all formats including unverified domains.

    .EXAMPLE
        Export-M365DomainReport -OutputPath "C:\Reports" -Format JSON
        Exports a JSON report to the specified directory.

    .EXAMPLE
        Export-M365DomainReport -ReportName "Contoso-Domains" -Format HTML
        Exports an HTML report with a custom name.

    .OUTPUTS
        String - Path(s) to the generated report file(s).
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CSV', 'JSON', 'HTML', 'All')]
        [string]$Format = 'CSV',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeUnverified,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVerificationRecords,

        [Parameter(Mandatory = $false)]
        [string]$ReportName
    )

    begin {
        Write-Verbose "Starting domain report generation"

        # Check if connected to Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run: Connect-MgGraph -Scopes 'Domain.Read.All'"
        }

        # Verify output path exists
        if (-not (Test-Path -Path $OutputPath)) {
            try {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Created output directory: $OutputPath"
            }
            catch {
                throw "Failed to create output directory: $_"
            }
        }

        # Generate timestamp and report name
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        if (-not $ReportName) {
            $ReportName = "M365-Domain-Report-$timestamp"
        }

        $outputFiles = @()
    }

    process {
        try {
            Write-Host "Generating Microsoft 365 Domain DNS Report..." -ForegroundColor Cyan

            # Collect domain data
            Write-Verbose "Retrieving domains..."
            $domains = Get-MgDomain -All

            if (-not $IncludeUnverified) {
                $domains = $domains | Where-Object { $_.IsVerified -eq $true }
            }

            Write-Host "  Processing $($domains.Count) domain(s)..." -ForegroundColor White

            # Build comprehensive report data
            $reportData = @()

            foreach ($domain in $domains) {
                Write-Verbose "Processing domain: $($domain.Id)"

                # Get DNS records for verified domains
                $dnsRecords = @()
                if ($domain.IsVerified) {
                    try {
                        $dnsRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain.Id -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Warning "Failed to retrieve DNS records for $($domain.Id)"
                    }
                }

                # Get verification records for unverified domains
                $verificationRecords = @()
                if (-not $domain.IsVerified -and $IncludeVerificationRecords) {
                    try {
                        $verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId $domain.Id -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Warning "Failed to retrieve verification records for $($domain.Id)"
                    }
                }

                # Create domain entry
                $domainEntry = [PSCustomObject]@{
                    DomainName = $domain.Id
                    IsVerified = $domain.IsVerified
                    IsDefault = $domain.IsDefault
                    IsInitial = $domain.IsInitial
                    AuthenticationType = $domain.AuthenticationType
                    SupportedServices = ($domain.SupportedServices -join '; ')
                    State = if ($domain.State) { $domain.State.Status } else { 'N/A' }
                    TotalDNSRecords = $dnsRecords.Count
                    MXRecords = ($dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'MX' }).Count
                    CNAMERecords = ($dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'CName' }).Count
                    TXTRecords = ($dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Txt' }).Count
                    SRVRecords = ($dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Srv' }).Count
                    VerificationRecords = $verificationRecords.Count
                    ReportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    TenantId = $context.TenantId
                }

                $reportData += $domainEntry

                # Add detailed DNS records
                foreach ($record in $dnsRecords) {
                    $recordDetail = [PSCustomObject]@{
                        DomainName = $domain.Id
                        RecordType = $record.AdditionalProperties['recordType']
                        Label = $record.Label
                        SupportedService = $record.SupportedService
                        TTL = $record.Ttl
                        IsOptional = $record.IsOptional
                    }

                    # Add type-specific details
                    switch ($record.AdditionalProperties['recordType']) {
                        'MX' {
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'Value' -Value $record.AdditionalProperties['mailExchange']
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'Preference' -Value $record.AdditionalProperties['preference']
                        }
                        'CName' {
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'Value' -Value $record.AdditionalProperties['canonicalName']
                        }
                        'Txt' {
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'Value' -Value $record.AdditionalProperties['text']
                        }
                        'Srv' {
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'NameTarget' -Value $record.AdditionalProperties['nameTarget']
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'Port' -Value $record.AdditionalProperties['port']
                            $recordDetail | Add-Member -MemberType NoteProperty -Name 'Priority' -Value $record.AdditionalProperties['priority']
                        }
                    }

                    $reportData += $recordDetail
                }
            }

            # Export to requested format(s)
            $formats = if ($Format -eq 'All') { @('CSV', 'JSON', 'HTML') } else { @($Format) }

            foreach ($fmt in $formats) {
                $fileName = "$ReportName.$($fmt.ToLower())"
                $fullPath = Join-Path -Path $OutputPath -ChildPath $fileName

                Write-Verbose "Exporting to $fmt format: $fullPath"

                switch ($fmt) {
                    'CSV' {
                        $reportData | Export-Csv -Path $fullPath -NoTypeInformation -Encoding UTF8
                        Write-Host "  CSV report saved: $fullPath" -ForegroundColor Green
                    }
                    'JSON' {
                        $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $fullPath -Encoding UTF8
                        Write-Host "  JSON report saved: $fullPath" -ForegroundColor Green
                    }
                    'HTML' {
                        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Microsoft 365 Domain DNS Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078d4; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078d4; color: white; padding: 10px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .verified { color: green; font-weight: bold; }
        .unverified { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Microsoft 365 Domain DNS Report</h1>
    <p><strong>Report Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <p><strong>Tenant ID:</strong> $($context.TenantId)</p>
    <p><strong>Total Domains:</strong> $($domains.Count)</p>
    <table>
        <tr>
            <th>Domain Name</th>
            <th>Verified</th>
            <th>Default</th>
            <th>Initial</th>
            <th>Supported Services</th>
            <th>DNS Records</th>
        </tr>
"@
                        foreach ($item in $reportData | Where-Object { $_.DomainName }) {
                            $verifiedClass = if ($item.IsVerified) { 'verified' } else { 'unverified' }
                            $verifiedText = if ($item.IsVerified) { 'Yes' } else { 'No' }
                            $htmlContent += @"
        <tr>
            <td>$($item.DomainName)</td>
            <td class="$verifiedClass">$verifiedText</td>
            <td>$($item.IsDefault)</td>
            <td>$($item.IsInitial)</td>
            <td>$($item.SupportedServices)</td>
            <td>$($item.TotalDNSRecords)</td>
        </tr>
"@
                        }
                        $htmlContent += @"
    </table>
</body>
</html>
"@
                        $htmlContent | Out-File -FilePath $fullPath -Encoding UTF8
                        Write-Host "  HTML report saved: $fullPath" -ForegroundColor Green
                    }
                }

                $outputFiles += $fullPath
            }

            Write-Host "`nReport generation completed successfully!" -ForegroundColor Green
            return $outputFiles
        }
        catch {
            Write-Error "Failed to generate report: $_"
            throw
        }
    }
}
