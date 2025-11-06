# DNS4M365 Mock Reports

This document contains example outputs from the DNS4M365 module to demonstrate the various report formats and data structures.

---

## Report 1: Get-M365DomainDNSRecord

### Command:
```powershell
Get-M365DomainDNSRecord -DomainName "contoso.com"
```

### Output:

```
Domain Summary:
  Total Domains: 1
  Verified: 1
  Unverified: 0

DNS Records Summary:
  Total Records: 14
  MX: 1
  CNAME: 8
  TXT: 1
  SRV: 2

  By Service:
    Email: 3
    OfficeCommunicationsOnline: 4
    Intune: 2
    SharePoint: 1


Domain          RecordType Label                    SupportedService              TTL  MailExchange/Value
------          ---------- -----                    ----------------              ---  ------------------
contoso.com     MX         @                        Email                         3600 contoso-com.mail.protection.outlook.com
contoso.com     CNAME      autodiscover             Email                         3600 autodiscover.outlook.com
contoso.com     TXT        @                        Email                         3600 v=spf1 include:spf.protection.outlook.com -all
contoso.com     CNAME      selector1._domainkey     Email                         3600 selector1-contoso-com._domainkey.contoso.onmicrosoft.com
contoso.com     CNAME      selector2._domainkey     Email                         3600 selector2-contoso-com._domainkey.contoso.onmicrosoft.com
contoso.com     CNAME      sip                      OfficeCommunicationsOnline    3600 sipdir.online.lync.com
contoso.com     CNAME      lyncdiscover             OfficeCommunicationsOnline    3600 webdir.online.lync.com
contoso.com     SRV        _sip._tls                OfficeCommunicationsOnline    3600 sipdir.online.lync.com (Port: 443)
contoso.com     SRV        _sipfederationtls._tcp   OfficeCommunicationsOnline    3600 sipfed.online.lync.com (Port: 5061)
contoso.com     CNAME      enterpriseenrollment     Intune                        3600 enterpriseenrollment.manage.microsoft.com
contoso.com     CNAME      enterpriseregistration   Intune                        3600 enterpriseregistration.windows.net
contoso.com     CNAME      msoid                    Legacy                        3600 clientconfig.microsoftonline-p.net
```

---

## Report 2: Get-M365DomainDNSHealth

### Command:
```powershell
Get-M365DomainDNSHealth -DomainName "contoso.com" -IncludeDMARC -IncludeSPF -CheckDKIMResolution -CheckSRVRecords -CheckDeprecated
```

### Output:

```
Checking DNS health for: contoso.com

  Overall Health: Issues
  Issues: 2 | Warnings: 3 | Recommendations: 2

  Critical Issues:
    - DEPRECATED: msoid CNAME found - MUST BE REMOVED (blocks M365 Apps activation)
    - No DMARC record found - strongly recommended for email security

  Warnings:
    - DKIM selectors not configured - email authentication will be limited
    - No SIP TLS SRV record found - Teams federation may not work
    - No SIP Federation SRV record found - Teams federation may not work

  Recommendations:
    - Consider using -all (hard fail) instead of ~all (soft fail) for SPF
    - DMARC policy is 'none' - consider upgrading to 'quarantine' or 'reject'

=== DNS Health Check Complete ===


Domain                  : contoso.com
OverallHealth           : Issues
MXRecord                : @{Exists=True; Target=contoso-com.mail.protection.outlook.com; Priority=0; IsMicrosoft365=True}
AutodiscoverCNAME       : @{Exists=True; Target=autodiscover.outlook.com; IsCorrect=True}
SPFRecord               : @{Exists=True; Value=v=spf1 include:spf.protection.outlook.com ~all; IncludesMicrosoft365=True;
                          HasHardFail=False; HasSoftFail=True; LookupCount=1}
DMARCRecord             : @{Exists=False}
DKIMSelector1           : @{Exists=False; Target=; PointsToMicrosoft=False}
DKIMSelector2           : @{Exists=False; Target=; PointsToMicrosoft=False}
SIPRecord               : @{Exists=True; Target=sipdir.online.lync.com; IsCorrect=True}
LyncdiscoverRecord      : @{Exists=True; Target=webdir.online.lync.com; IsCorrect=True}
SIPTLSSRVRecord         : @{Exists=False}
SIPFederationSRVRecord  : @{Exists=False}
EnterpriseEnrollment    : @{Exists=True; Target=enterpriseenrollment.manage.microsoft.com; IsCorrect=True}
EnterpriseRegistration  : @{Exists=True; Target=enterpriseregistration.windows.net; IsCorrect=True}
DeprecatedMSOID         : @{Exists=True; Target=clientconfig.microsoftonline-p.net}
Issues                  : {DEPRECATED: msoid CNAME found - MUST BE REMOVED (blocks M365 Apps activation),
                          No DMARC record found - strongly recommended for email security}
Warnings                : {DKIM selectors not configured - email authentication will be limited,
                          No SIP TLS SRV record found - Teams federation may not work,
                          No SIP Federation SRV record found - Teams federation may not work}
Recommendations         : {Consider using -all (hard fail) instead of ~all (soft fail) for SPF,
                          DMARC policy is 'none' - consider upgrading to 'quarantine' or 'reject'}
```

---

## Report 3: Get-M365DomainDNSHealth (Healthy Domain)

### Command:
```powershell
Get-M365DomainDNSHealth -DomainName "fabrikam.com" -IncludeDMARC -IncludeSPF -CheckDKIMResolution -CheckSRVRecords -CheckDeprecated
```

### Output:

```
Checking DNS health for: fabrikam.com

  Overall Health: Healthy
  Issues: 0 | Warnings: 0 | Recommendations: 0

=== DNS Health Check Complete ===


Domain                  : fabrikam.com
OverallHealth           : Healthy
MXRecord                : @{Exists=True; Target=fabrikam-com.mail.protection.outlook.com; Priority=0; IsMicrosoft365=True}
AutodiscoverCNAME       : @{Exists=True; Target=autodiscover.outlook.com; IsCorrect=True}
SPFRecord               : @{Exists=True; Value=v=spf1 include:spf.protection.outlook.com -all; IncludesMicrosoft365=True;
                          HasHardFail=True; HasSoftFail=False; LookupCount=1}
DMARCRecord             : @{Exists=True; Value=v=DMARC1; p=quarantine; rua=mailto:dmarc@fabrikam.com; adkim=r; aspf=r;
                          Policy=quarantine; HasReporting=True}
DKIMSelector1           : @{Exists=True; Target=selector1-fabrikam-com._domainkey.fabrikam.onmicrosoft.com; PointsToMicrosoft=True}
DKIMSelector2           : @{Exists=True; Target=selector2-fabrikam-com._domainkey.fabrikam.onmicrosoft.com; PointsToMicrosoft=True}
SIPRecord               : @{Exists=True; Target=sipdir.online.lync.com; IsCorrect=True}
LyncdiscoverRecord      : @{Exists=True; Target=webdir.online.lync.com; IsCorrect=True}
SIPTLSSRVRecord         : @{Exists=True; Target=sipdir.online.lync.com; Port=443; IsCorrect=True}
SIPFederationSRVRecord  : @{Exists=True; Target=sipfed.online.lync.com; Port=5061; IsCorrect=True}
EnterpriseEnrollment    : @{Exists=True; Target=enterpriseenrollment.manage.microsoft.com; IsCorrect=True}
EnterpriseRegistration  : @{Exists=True; Target=enterpriseregistration.windows.net; IsCorrect=True}
DeprecatedMSOID         : @{Exists=False}
Issues                  : {}
Warnings                : {}
Recommendations         : {}
```

---

## Report 4: Compare-M365DomainDNS

### Command:
```powershell
Compare-M365DomainDNS -DomainName "contoso.com" -IncludeOptional -ShowOnlyDifferences
```

### Output:

```
Comparing DNS records for: contoso.com

=== DNS Comparison Summary ===
Total Records Checked: 16
Matches: 10
Mismatches: 3
Missing: 2
Deprecated (REMOVE): 1

Differences Found:

Domain      RecordType Label                 Status            ExpectedValue                                            ActualValue
------      ---------- -----                 ------            -------------                                            -----------
contoso.com CNAME      selector1._domainkey  Missing           selector1-contoso-com._domainkey.contoso.onmicrosoft.com (not found)
contoso.com CNAME      selector2._domainkey  Missing           selector2-contoso-com._domainkey.contoso.onmicrosoft.com (not found)
contoso.com SRV        _sip._tls             Mismatch          100 1 443 sipdir.online.lync.com                        100 1 5061 sipdir.online.lync.com
contoso.com TXT        _dmarc                Missing           v=DMARC1; p=quarantine or p=reject (recommended)        (not found)
contoso.com TXT        @                     Mismatch          v=spf1 include:spf.protection.outlook.com -all          v=spf1 include:spf.protection.outlook.com ~all
contoso.com CNAME      msoid                 DEPRECATED - REMOVE (should not exist - DEPRECATED)                       clientconfig.microsoftonline-p.net

Report exported to: C:\Reports\DNS-Comparison-20250106-143022.csv
```

---

## Report 5: Compare-M365DomainDNS (Full Report)

### Command:
```powershell
Compare-M365DomainDNS -DomainName "fabrikam.com"
```

### Output:

```
Comparing DNS records for: fabrikam.com

=== DNS Comparison Summary ===
Total Records Checked: 14
Matches: 14
Mismatches: 0
Missing: 0
Deprecated (REMOVE): 0

No differences found - all DNS records match!


Domain       RecordType Label                    Status SupportedService
------       ---------- -----                    ------ ----------------
fabrikam.com MX         @                        Match  Email
fabrikam.com CNAME      autodiscover             Match  Email
fabrikam.com TXT        @                        Match  Email
fabrikam.com CNAME      selector1._domainkey     Match  Email
fabrikam.com CNAME      selector2._domainkey     Match  Email
fabrikam.com CNAME      sip                      Match  OfficeCommunicationsOnline
fabrikam.com CNAME      lyncdiscover             Match  OfficeCommunicationsOnline
fabrikam.com SRV        _sip._tls                Match  OfficeCommunicationsOnline
fabrikam.com SRV        _sipfederationtls._tcp   Match  OfficeCommunicationsOnline
fabrikam.com CNAME      enterpriseenrollment     Match  Intune
fabrikam.com CNAME      enterpriseregistration   Match  Intune
fabrikam.com TXT        @                        Match  Verification
fabrikam.com TXT        _dmarc                   Match  Email Security
fabrikam.com TXT        default._bimi            Match  Email Security
```

---

## Report 6: Export-M365DomainReport (CSV Format)

### Command:
```powershell
Export-M365DomainReport -Format CSV -IncludeUnverified
```

### Sample CSV Output:

```csv
DomainName,IsVerified,IsDefault,IsInitial,SupportedServices,State,TotalDNSRecords,MXRecords,CNAMERecords,TXTRecords,SRVRecords,VerificationRecords,ReportDate,TenantId
contoso.com,True,True,False,"Email; SharePoint; OfficeCommunicationsOnline",Active,14,1,8,3,2,0,2025-01-06 14:30:22,a1b2c3d4-e5f6-7890-abcd-ef1234567890
fabrikam.com,True,False,False,"Email; SharePoint; OfficeCommunicationsOnline; Intune",Active,16,1,10,4,2,0,2025-01-06 14:30:22,a1b2c3d4-e5f6-7890-abcd-ef1234567890
contoso.onmicrosoft.com,True,False,True,Email,Active,1,1,0,0,0,0,2025-01-06 14:30:22,a1b2c3d4-e5f6-7890-abcd-ef1234567890
tailspintoys.com,False,False,False,,PendingRegistration,0,0,0,0,0,1,2025-01-06 14:30:22,a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

---

## Report 7: Export-M365DomainReport (HTML Format - Preview)

### Command:
```powershell
Export-M365DomainReport -Format HTML -ReportName "M365-Domain-Audit"
```

### HTML Output Preview:

```html
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
    <p><strong>Report Date:</strong> 2025-01-06 14:30:22</p>
    <p><strong>Tenant ID:</strong> a1b2c3d4-e5f6-7890-abcd-ef1234567890</p>
    <p><strong>Total Domains:</strong> 4</p>
    <table>
        <tr>
            <th>Domain Name</th>
            <th>Verified</th>
            <th>Default</th>
            <th>Initial</th>
            <th>Supported Services</th>
            <th>DNS Records</th>
        </tr>
        <tr>
            <td>contoso.com</td>
            <td class="verified">Yes</td>
            <td>True</td>
            <td>False</td>
            <td>Email; SharePoint; OfficeCommunicationsOnline</td>
            <td>14</td>
        </tr>
        <tr>
            <td>fabrikam.com</td>
            <td class="verified">Yes</td>
            <td>False</td>
            <td>False</td>
            <td>Email; SharePoint; OfficeCommunicationsOnline; Intune</td>
            <td>16</td>
        </tr>
        <tr>
            <td>contoso.onmicrosoft.com</td>
            <td class="verified">Yes</td>
            <td>False</td>
            <td>True</td>
            <td>Email</td>
            <td>1</td>
        </tr>
        <tr>
            <td>tailspintoys.com</td>
            <td class="unverified">No</td>
            <td>False</td>
            <td>False</td>
            <td></td>
            <td>0</td>
        </tr>
    </table>
</body>
</html>
```

---

## Report 8: Multi-Domain Health Summary

### Command:
```powershell
Get-M365Domain -VerificationStatus Verified | ForEach-Object {
    Get-M365DomainDNSHealth -DomainName $_.DomainName -IncludeDMARC -IncludeSPF -CheckDeprecated
} | Select-Object Domain, OverallHealth, @{N='IssueCount';E={$_.Issues.Count}}, @{N='WarningCount';E={$_.Warnings.Count}}
```

### Output:

```
Domain                      OverallHealth IssueCount WarningCount
------                      ------------- ---------- ------------
contoso.com                 Issues        2          3
fabrikam.com                Healthy       0          0
contoso.onmicrosoft.com     Warning       0          1
adventureworks.com          Critical      5          2
northwindtraders.com        Healthy       0          0
```

---

## Report 9: Detailed DNS Record Inventory

### Command:
```powershell
Get-M365DomainDNSRecord -DomainName "contoso.com" |
    Select-Object Domain, RecordType, Label,
        @{N='Value';E={
            switch ($_.RecordType) {
                'MX' { $_.MailExchange }
                'CNAME' { $_.CanonicalName }
                'TXT' { $_.Text }
                'SRV' { "$($_.NameTarget):$($_.Port)" }
            }
        }}, SupportedService, IsOptional | Format-Table -AutoSize
```

### Output:

```
Domain      RecordType Label                    Value                                                              SupportedService              IsOptional
------      ---------- -----                    -----                                                              ----------------              ----------
contoso.com MX         @                        contoso-com.mail.protection.outlook.com                            Email                         False
contoso.com CNAME      autodiscover             autodiscover.outlook.com                                           Email                         False
contoso.com TXT        @                        v=spf1 include:spf.protection.outlook.com -all                     Email                         False
contoso.com CNAME      selector1._domainkey     selector1-contoso-com._domainkey.contoso.onmicrosoft.com           Email                         False
contoso.com CNAME      selector2._domainkey     selector2-contoso-com._domainkey.contoso.onmicrosoft.com           Email                         False
contoso.com CNAME      sip                      sipdir.online.lync.com                                             OfficeCommunicationsOnline    False
contoso.com CNAME      lyncdiscover             webdir.online.lync.com                                             OfficeCommunicationsOnline    False
contoso.com SRV        _sip._tls                sipdir.online.lync.com:443                                         OfficeCommunicationsOnline    False
contoso.com SRV        _sipfederationtls._tcp   sipfed.online.lync.com:5061                                        OfficeCommunicationsOnline    False
contoso.com CNAME      enterpriseenrollment     enterpriseenrollment.manage.microsoft.com                          Intune                        True
contoso.com CNAME      enterpriseregistration   enterpriseregistration.windows.net                                 Intune                        True
```

---

## Report 10: DNS Health Dashboard Summary

### Command:
```powershell
$domains = Get-M365Domain -VerificationStatus Verified
$healthReport = foreach ($domain in $domains) {
    $health = Get-M365DomainDNSHealth -DomainName $domain.DomainName -IncludeDMARC -IncludeSPF -CheckDeprecated
    [PSCustomObject]@{
        Domain = $domain.DomainName
        Health = $health.OverallHealth
        HasMX = $health.MXRecord.Exists
        HasAutodiscover = $health.AutodiscoverCNAME.Exists
        HasSPF = $health.SPFRecord.Exists
        SPFHardFail = $health.SPFRecord.HasHardFail
        HasDMARC = $health.DMARCRecord.Exists
        DMARCPolicy = $health.DMARCRecord.Policy
        HasDKIM = ($health.DKIMSelector1.Exists -and $health.DKIMSelector2.Exists)
        HasDeprecated = $health.DeprecatedMSOID.Exists
        IssueCount = $health.Issues.Count
        WarningCount = $health.Warnings.Count
    }
}
$healthReport | Format-Table -AutoSize
```

### Output:

```
Domain                  Health   HasMX HasAutodiscover HasSPF SPFHardFail HasDMARC DMARCPolicy HasDKIM HasDeprecated IssueCount WarningCount
------                  ------   ----- --------------- ------ ----------- -------- ----------- ------- ------------- ---------- ------------
contoso.com             Issues   True  True            True   False       False    none        False   True          2          3
fabrikam.com            Healthy  True  True            True   True        True     quarantine  True    False         0          0
contoso.onmicrosoft.com Warning  True  False           True   True        False                False   False         0          1
adventureworks.com      Critical True  True            False  False       False                False   True          5          2
northwindtraders.com    Healthy  True  True            True   True        True     reject      True    False         0          0
```

---

## Report 11: SPF Record Analysis

### Command:
```powershell
Get-M365Domain -VerificationStatus Verified | ForEach-Object {
    $health = Get-M365DomainDNSHealth -DomainName $_.DomainName -IncludeSPF
    if ($health.SPFRecord.Exists) {
        [PSCustomObject]@{
            Domain = $_.DomainName
            SPFRecord = $health.SPFRecord.Value
            IncludesMicrosoft365 = $health.SPFRecord.IncludesMicrosoft365
            HardFail = $health.SPFRecord.HasHardFail
            SoftFail = $health.SPFRecord.HasSoftFail
            LookupCount = $health.SPFRecord.LookupCount
            Status = if ($health.SPFRecord.LookupCount -gt 10) { "INVALID - Too many lookups" }
                    elseif (-not $health.SPFRecord.IncludesMicrosoft365) { "MISSING M365" }
                    elseif ($health.SPFRecord.HasHardFail) { "OPTIMAL" }
                    else { "NEEDS HARDENING" }
        }
    }
} | Format-Table -AutoSize
```

### Output:

```
Domain               SPFRecord                                                                              IncludesMicrosoft365 HardFail SoftFail LookupCount Status
------               ---------                                                                              -------------------- -------- -------- ----------- ------
contoso.com          v=spf1 include:spf.protection.outlook.com ~all                                         True                 False    True     1           NEEDS HARDENING
fabrikam.com         v=spf1 include:spf.protection.outlook.com -all                                         True                 True     False    1           OPTIMAL
adventureworks.com   v=spf1 include:_spf.google.com include:sendgrid.net include:spf.protection.outlook... True                 True     False    8           OPTIMAL
northwindtraders.com v=spf1 include:spf.protection.outlook.com include:servers.mcsv.net -all              True                 True     False    2           OPTIMAL
tailspintoys.com     v=spf1 ip4:192.168.1.1 include:amazonses.com -all                                     False                True     False    1           MISSING M365
```

---

## Report 12: DMARC Compliance Report

### Command:
```powershell
Get-M365Domain -VerificationStatus Verified | ForEach-Object {
    $health = Get-M365DomainDNSHealth -DomainName $_.DomainName -IncludeDMARC
    [PSCustomObject]@{
        Domain = $_.DomainName
        DMARCExists = $health.DMARCRecord.Exists
        Policy = if ($health.DMARCRecord.Exists) { $health.DMARCRecord.Policy } else { "None" }
        HasReporting = if ($health.DMARCRecord.Exists) { $health.DMARCRecord.HasReporting } else { $false }
        ComplianceLevel = if (-not $health.DMARCRecord.Exists) { "Non-Compliant" }
                         elseif ($health.DMARCRecord.Policy -eq "reject") { "Excellent" }
                         elseif ($health.DMARCRecord.Policy -eq "quarantine") { "Good" }
                         elseif ($health.DMARCRecord.Policy -eq "none") { "Monitoring" }
                         else { "Unknown" }
        Recommendation = if (-not $health.DMARCRecord.Exists) { "Add DMARC record immediately" }
                        elseif ($health.DMARCRecord.Policy -eq "none") { "Upgrade policy to quarantine" }
                        elseif ($health.DMARCRecord.Policy -eq "quarantine") { "Consider upgrading to reject" }
                        else { "Maintain current policy" }
    }
} | Format-Table -AutoSize
```

### Output:

```
Domain               DMARCExists Policy     HasReporting ComplianceLevel Recommendation
------               ----------- ------     ------------ --------------- --------------
contoso.com          False       None       False        Non-Compliant   Add DMARC record immediately
fabrikam.com         True        quarantine True         Good            Consider upgrading to reject
adventureworks.com   True        none       True         Monitoring      Upgrade policy to quarantine
northwindtraders.com True        reject     True         Excellent       Maintain current policy
tailspintoys.com     False       None       False        Non-Compliant   Add DMARC record immediately
```

---

## Report 13: Teams Federation Readiness

### Command:
```powershell
Get-M365Domain -VerificationStatus Verified | ForEach-Object {
    $health = Get-M365DomainDNSHealth -DomainName $_.DomainName -CheckSRVRecords
    [PSCustomObject]@{
        Domain = $_.DomainName
        SIPCNAMEExists = $health.SIPRecord.Exists
        LyncdiscoverExists = $health.LyncdiscoverRecord.Exists
        SIPTLSSRVExists = $health.SIPTLSSRVRecord.Exists
        SIPFederationSRVExists = $health.SIPFederationSRVRecord.Exists
        FederationReady = ($health.SIPRecord.Exists -and $health.SIPTLSSRVRecord.Exists -and $health.SIPFederationSRVRecord.Exists)
        Status = if ($health.SIPRecord.Exists -and $health.SIPTLSSRVRecord.Exists -and $health.SIPFederationSRVRecord.Exists) { "Ready" }
                elseif ($health.SIPRecord.Exists -or $health.SIPTLSSRVRecord.Exists) { "Partial" }
                else { "Not Configured" }
    }
} | Format-Table -AutoSize
```

### Output:

```
Domain               SIPCNAMEExists LyncdiscoverExists SIPTLSSRVExists SIPFederationSRVExists FederationReady Status
------               -------------- ------------------ --------------- ---------------------- --------------- ------
contoso.com          True           True               False           False                  False           Partial
fabrikam.com         True           True               True            True                   True            Ready
adventureworks.com   False          False              False           False                  False           Not Configured
northwindtraders.com True           True               True            True                   True            Ready
tailspintoys.com     True           True               True            False                  False           Partial
```

---

## Report 14: Deprecated Records Alert

### Command:
```powershell
Get-M365Domain -VerificationStatus Verified | ForEach-Object {
    $health = Get-M365DomainDNSHealth -DomainName $_.DomainName -CheckDeprecated
    if ($health.DeprecatedMSOID.Exists) {
        [PSCustomObject]@{
            Domain = $_.DomainName
            DeprecatedRecord = "msoid"
            CurrentTarget = $health.DeprecatedMSOID.Target
            Severity = "CRITICAL"
            Action = "REMOVE IMMEDIATELY - Blocks Microsoft 365 Apps activation"
            Impact = "Microsoft 365 Apps will fail to activate"
        }
    }
} | Format-Table -Wrap
```

### Output:

```
Domain               DeprecatedRecord CurrentTarget                        Severity Action                                                   Impact
------               ---------------- -------------                        -------- ------                                                   ------
contoso.com          msoid            clientconfig.microsoftonline-p.net   CRITICAL REMOVE IMMEDIATELY - Blocks Microsoft 365 Apps activation Microsoft 365 Apps will fail to activate
adventureworks.com   msoid            clientconfig.microsoftonline-p.net   CRITICAL REMOVE IMMEDIATELY - Blocks Microsoft 365 Apps activation Microsoft 365 Apps will fail to activate
```

---

## Report 15: Executive Summary Dashboard

### Command:
```powershell
$domains = Get-M365Domain
$verified = $domains | Where-Object { $_.IsVerified }

$summary = [PSCustomObject]@{
    ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalDomains = $domains.Count
    VerifiedDomains = $verified.Count
    UnverifiedDomains = ($domains | Where-Object { -not $_.IsVerified }).Count
    DomainsHealthy = 0
    DomainsWithIssues = 0
    DomainsWithWarnings = 0
    DomainsCritical = 0
    TotalDNSRecords = 0
    MissingDMARCCount = 0
    DeprecatedRecordsFound = 0
}

foreach ($domain in $verified) {
    $health = Get-M365DomainDNSHealth -DomainName $domain.DomainName -IncludeDMARC -IncludeSPF -CheckDeprecated
    $records = Get-M365DomainDNSRecord -DomainName $domain.DomainName

    $summary.TotalDNSRecords += $records.Count

    if ($health.OverallHealth -eq "Healthy") { $summary.DomainsHealthy++ }
    elseif ($health.OverallHealth -eq "Warning") { $summary.DomainsWithWarnings++ }
    elseif ($health.OverallHealth -eq "Issues") { $summary.DomainsWithIssues++ }
    elseif ($health.OverallHealth -eq "Critical") { $summary.DomainsCritical++ }

    if (-not $health.DMARCRecord.Exists) { $summary.MissingDMARCCount++ }
    if ($health.DeprecatedMSOID.Exists) { $summary.DeprecatedRecordsFound++ }
}

$summary | Format-List
```

### Output:

```
ReportDate            : 2025-01-06 14:30:22
TotalDomains          : 6
VerifiedDomains       : 5
UnverifiedDomains     : 1
DomainsHealthy        : 2
DomainsWithIssues     : 2
DomainsWithWarnings   : 1
DomainsCritical       : 0
TotalDNSRecords       : 73
MissingDMARCCount     : 3
DeprecatedRecordsFound: 2

=====================================================================
SUMMARY HIGHLIGHTS:
=====================================================================

✅ Healthy Domains: 2 / 5 (40%)
⚠️  Domains Needing Attention: 3 / 5 (60%)
❌ Critical Issues: 2 domains with deprecated msoid records
📧 DMARC Missing: 3 domains (60% non-compliant)
📊 Average DNS Records per Domain: 14.6

IMMEDIATE ACTIONS REQUIRED:
1. Remove deprecated 'msoid' CNAME from 2 domains (CRITICAL)
2. Configure DMARC on 3 domains for email security
3. Harden SPF records (change ~all to -all)
4. Configure DKIM selectors on domains missing email authentication

=====================================================================
```

---

## Summary

These mock reports demonstrate:

1. **Basic DNS Record Retrieval** - Listing all Microsoft-generated records
2. **Comprehensive Health Checks** - Validation with issues, warnings, and recommendations
3. **Comparison Reports** - Expected vs actual DNS configuration
4. **Export Formats** - CSV, JSON, HTML outputs
5. **Multi-Domain Analysis** - Aggregate statistics across all domains
6. **Security Compliance** - SPF, DMARC, DKIM analysis
7. **Service Readiness** - Teams federation validation
8. **Critical Alerts** - Deprecated record detection
9. **Executive Summaries** - High-level dashboard metrics

All reports are designed to provide actionable insights for Microsoft 365 DNS management.
