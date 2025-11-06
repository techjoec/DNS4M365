function New-M365DmarcRecord {
    <#
    .SYNOPSIS
        Generates a DMARC TXT record for Microsoft 365 email authentication.

    .DESCRIPTION
        Creates a properly formatted DMARC (Domain-based Message Authentication, Reporting, and Conformance)
        TXT record for DNS configuration. DMARC policies are MANDATORY starting April 2025 for email deliverability.

        DMARC works with SPF and DKIM to protect against email spoofing and phishing.

    .PARAMETER Domain
        The domain name for which to generate the DMARC record.

    .PARAMETER Policy
        DMARC policy to apply to emails that fail authentication.
        - none: Monitor only (no action taken)
        - quarantine: Move suspicious emails to spam/junk
        - reject: Reject emails that fail authentication

        Recommended progression: Start with 'none' for monitoring, then 'quarantine', finally 'reject'.

    .PARAMETER SubdomainPolicy
        Policy to apply to subdomains. If not specified, inherits the main policy.

    .PARAMETER Percentage
        Percentage of emails to which the policy applies (1-100).
        Default: 100

        Use lower percentages during initial rollout to minimize impact.

    .PARAMETER AggregateReportEmail
        Email address(es) to receive aggregate DMARC reports.
        Can specify multiple addresses separated by commas.

        Format: mailto:dmarc@example.com

    .PARAMETER ForensicReportEmail
        Email address(es) to receive forensic (failure) DMARC reports.
        Can specify multiple addresses separated by commas.

        Format: mailto:dmarc-forensics@example.com

    .PARAMETER ReportFormat
        Format for forensic reports. Default: afrf (Authentication Failure Reporting Format)

    .PARAMETER ReportInterval
        Interval for aggregate reports in seconds. Default: 86400 (24 hours)

    .PARAMETER Alignment
        Alignment mode for SPF and DKIM.
        - relaxed: Allow partial domain matches (default, recommended)
        - strict: Require exact domain matches

    .PARAMETER FailureReportOption
        When to generate forensic reports.
        - 0: Generate reports if all mechanisms fail (default)
        - 1: Generate reports if any mechanism fails
        - d: Generate reports if DKIM fails
        - s: Generate reports if SPF fails

    .PARAMETER OutputFormat
        Output format for the generated record.
        - DNS: Formatted for direct DNS entry (default)
        - PowerShell: PowerShell object
        - JSON: JSON format

    .EXAMPLE
        New-M365DmarcRecord -Domain "contoso.com" -Policy none -AggregateReportEmail "dmarc@contoso.com"

        Generates monitoring-only DMARC record:
        _dmarc.contoso.com TXT "v=DMARC1; p=none; rua=mailto:dmarc@contoso.com"

    .EXAMPLE
        New-M365DmarcRecord -Domain "contoso.com" -Policy quarantine -AggregateReportEmail "dmarc@contoso.com" -Percentage 25

        Generates quarantine policy affecting 25% of email (gradual rollout):
        _dmarc.contoso.com TXT "v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc@contoso.com"

    .EXAMPLE
        New-M365DmarcRecord -Domain "contoso.com" -Policy reject -SubdomainPolicy quarantine -AggregateReportEmail "dmarc@contoso.com" -ForensicReportEmail "dmarc-forensics@contoso.com"

        Generates strict policy with forensic reporting:
        _dmarc.contoso.com TXT "v=DMARC1; p=reject; sp=quarantine; rua=mailto:dmarc@contoso.com; ruf=mailto:dmarc-forensics@contoso.com"

    .EXAMPLE
        New-M365DmarcRecord -Domain "contoso.com" -Policy reject -Alignment strict

        Generates strict alignment policy (exact domain match required):
        _dmarc.contoso.com TXT "v=DMARC1; p=reject; adkim=s; aspf=s"

    .OUTPUTS
        String or PSCustomObject depending on OutputFormat

    .NOTES
        DMARC Deployment Best Practices:
        1. Start with p=none for monitoring (collect reports for 2-4 weeks)
        2. Review aggregate reports to understand email flow
        3. Move to p=quarantine with pct=25, gradually increase
        4. Finally move to p=reject for maximum protection

        Microsoft 365 DMARC Requirements (April 2025):
        - DMARC record is MANDATORY for email deliverability
        - Minimum policy: p=none (monitoring)
        - Recommended: p=quarantine or p=reject

        External Resources:
        - https://dmarc.org/
        - https://mxtoolbox.com/dmarc.aspx (validator)
        - https://dmarcian.com/ (report analysis)

    .LINK
        https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dmarc-configure
    #>

    [CmdletBinding()]
    [OutputType([String], [PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('DomainName', 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,

        [Parameter(Mandatory = $true)]
        [ValidateSet('none', 'quarantine', 'reject')]
        [string]$Policy,

        [Parameter(Mandatory = $false)]
        [ValidateSet('none', 'quarantine', 'reject')]
        [string]$SubdomainPolicy,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$Percentage = 100,

        [Parameter(Mandatory = $false)]
        [Alias('rua')]
        [string[]]$AggregateReportEmail,

        [Parameter(Mandatory = $false)]
        [Alias('ruf')]
        [string[]]$ForensicReportEmail,

        [Parameter(Mandatory = $false)]
        [ValidateSet('afrf')]
        [string]$ReportFormat = 'afrf',

        [Parameter(Mandatory = $false)]
        [ValidateRange(3600, 604800)]
        [int]$ReportInterval = 86400,

        [Parameter(Mandatory = $false)]
        [ValidateSet('relaxed', 'strict')]
        [string]$Alignment = 'relaxed',

        [Parameter(Mandatory = $false)]
        [ValidateSet('0', '1', 'd', 's')]
        [string]$FailureReportOption = '0',

        [Parameter(Mandatory = $false)]
        [ValidateSet('DNS', 'PowerShell', 'JSON')]
        [string]$OutputFormat = 'DNS'
    )

    begin {
        Write-Verbose "Generating DMARC record for $Domain"
    }

    process {
        # Build DMARC record
        $dmarcParts = @("v=DMARC1")

        # Policy (required)
        $dmarcParts += "p=$Policy"

        # Subdomain policy (optional)
        if ($SubdomainPolicy) {
            $dmarcParts += "sp=$SubdomainPolicy"
        }

        # Percentage (optional, omit if 100%)
        if ($Percentage -ne 100) {
            $dmarcParts += "pct=$Percentage"
        }

        # Aggregate report email (optional but highly recommended)
        if ($AggregateReportEmail) {
            $ruaAddresses = $AggregateReportEmail | ForEach-Object {
                if ($_ -notmatch '^mailto:') {
                    "mailto:$_"
                } else {
                    $_
                }
            }
            $dmarcParts += "rua=$($ruaAddresses -join ',')"
        }

        # Forensic report email (optional)
        if ($ForensicReportEmail) {
            $rufAddresses = $ForensicReportEmail | ForEach-Object {
                if ($_ -notmatch '^mailto:') {
                    "mailto:$_"
                } else {
                    $_
                }
            }
            $dmarcParts += "ruf=$($rufAddresses -join ',')"
        }

        # Report format (optional, omit if default afrf)
        if ($ReportFormat -ne 'afrf') {
            $dmarcParts += "rf=$ReportFormat"
        }

        # Report interval (optional, omit if default 86400)
        if ($ReportInterval -ne 86400) {
            $dmarcParts += "ri=$ReportInterval"
        }

        # Alignment mode (optional, omit if relaxed)
        if ($Alignment -eq 'strict') {
            $dmarcParts += "adkim=s"  # DKIM alignment strict
            $dmarcParts += "aspf=s"   # SPF alignment strict
        }

        # Failure reporting options (optional, omit if default 0)
        if ($FailureReportOption -ne '0') {
            $dmarcParts += "fo=$FailureReportOption"
        }

        # Combine into final record
        $dmarcRecord = $dmarcParts -join "; "

        # Create result object
        $result = [PSCustomObject]@{
            Domain          = $Domain
            RecordName      = "_dmarc.$Domain"
            RecordType      = "TXT"
            Value           = $dmarcRecord
            Policy          = $Policy
            SubdomainPolicy = if ($SubdomainPolicy) { $SubdomainPolicy } else { "(inherits main policy)" }
            Percentage      = $Percentage
            ReportEmails    = if ($AggregateReportEmail) { $AggregateReportEmail -join ", " } else { "(none)" }
            Alignment       = $Alignment
            TTL             = 3600
        }

        # Output based on format
        switch ($OutputFormat) {
            'DNS' {
                Write-Information "`nGenerated DMARC Record:" -InformationAction Continue
                Write-Information "======================" -InformationAction Continue
                Write-Information "`nDNS Record Name:" -InformationAction Continue
                Write-Information "  _dmarc.$Domain" -InformationAction Continue
                Write-Information "`nRecord Type:" -InformationAction Continue
                Write-Information "  TXT" -InformationAction Continue
                Write-Information "`nRecord Value:" -InformationAction Continue
                Write-Information "  $dmarcRecord" -InformationAction Continue
                Write-Information "`nTTL:" -InformationAction Continue
                Write-Information "  3600 (1 hour)" -InformationAction Continue
                Write-Information "`nConfiguration Summary:" -InformationAction Continue
                Write-Information "  Policy: $Policy" -InformationAction Continue
                if ($SubdomainPolicy) {
                    Write-Information "  Subdomain Policy: $SubdomainPolicy" -InformationAction Continue
                }
                Write-Information "  Percentage: $Percentage%" -InformationAction Continue
                Write-Information "  Alignment: $Alignment" -InformationAction Continue
                if ($AggregateReportEmail) {
                    Write-Information "  Aggregate Reports: $($AggregateReportEmail -join ', ')" -InformationAction Continue
                }
                if ($ForensicReportEmail) {
                    Write-Information "  Forensic Reports: $($ForensicReportEmail -join ', ')" -InformationAction Continue
                }

                Write-Information "`nNext Steps:" -InformationAction Continue
                Write-Information "  1. Add the TXT record to your DNS zone at your domain registrar" -InformationAction Continue
                Write-Information "  2. Wait for DNS propagation (up to 48 hours, typically 15-60 minutes)" -InformationAction Continue
                Write-Information "  3. Verify with: Resolve-DnsName _dmarc.$Domain -Type TXT" -InformationAction Continue
                Write-Information "  4. Monitor aggregate reports for 2-4 weeks" -InformationAction Continue

                if ($Policy -eq 'none') {
                    Write-Information "`n  ⚠️  Monitoring Mode: After reviewing reports, consider p=quarantine" -InformationAction Continue
                }

                Write-Information "`nValidation Tools:" -InformationAction Continue
                Write-Information "  - https://mxtoolbox.com/SuperTool.aspx?action=dmarc%3a$Domain" -InformationAction Continue
                Write-Information "  - https://dmarcian.com/dmarc-inspector/" -InformationAction Continue

                Write-Information "" -InformationAction Continue

                return $dmarcRecord
            }
            'PowerShell' {
                return $result
            }
            'JSON' {
                return $result | ConvertTo-Json -Depth 10
            }
        }
    }
}
