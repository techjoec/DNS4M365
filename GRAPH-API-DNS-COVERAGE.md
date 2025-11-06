# Microsoft Graph API - DNS Record Coverage Research

## Research Question
Can Microsoft Graph API provide ALL DNS records that M365 generates for custom domains?

## Graph API Endpoints

### 1. Get Domain Service Configuration Records
```
GET https://graph.microsoft.com/v1.0/domains/{domainId}/serviceConfigurationRecords
```

PowerShell:
```powershell
Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"
```

### 2. Get Domain Verification Records
```
GET https://graph.microsoft.com/v1.0/domains/{domainId}/verificationDnsRecords
```

PowerShell:
```powershell
Get-MgDomainVerificationDnsRecord -DomainId "contoso.com"
```

## What These Return (COMPLETE LIST)

### From serviceConfigurationRecords:

**Exchange Online:**
- MX record: `{tenant}-{domain}.mail.protection.outlook.com` (dynamically generated)
- CNAME: autodiscover.{domain} → autodiscover.outlook.com

**DKIM (Exchange):**
- CNAME: selector1._domainkey.{domain} → selector1-{domain-dashed}._domainkey.{tenant}.onmicrosoft.com
- CNAME: selector2._domainkey.{domain} → selector2-{domain-dashed}._domainkey.{tenant}.onmicrosoft.com
  (DYNAMICALLY GENERATED - cannot predict without querying Graph)

**Teams/Skype for Business:**
- CNAME: sip.{domain} → sipdir.online.lync.com
- CNAME: lyncdiscover.{domain} → webdir.online.lync.com
- SRV: _sip._tls.{domain} → sipdir.online.lync.com:443
- SRV: _sipfederationtls._tcp.{domain} → sipfed.online.lync.com:5061

**Intune/MDM:**
- CNAME: enterpriseenrollment.{domain} → enterpriseenrollment.manage.microsoft.com
- CNAME: enterpriseregistration.{domain} → enterpriseregistration.windows.net

### From verificationDnsRecords:

**Domain Verification:**
- TXT: MS=msXXXXXXXX (dynamically generated verification code)
- OR MX: {random-string}.pamx1.hotmail.com

## What Graph API DOES NOT RETURN

These are admin-created, NOT Microsoft-generated:

❌ SPF (TXT): Admin must create `v=spf1 include:spf.protection.outlook.com -all`
❌ DMARC (TXT): Admin must create `_dmarc.{domain}` with policy
❌ DKIM enablement: Admin must enable in Exchange admin center (Graph provides CNAMEs only)
❌ Custom DNS records: Any additional records admin creates

## CONCLUSION

✅ **YES - Graph API provides ALL Microsoft-generated DNS records**
✅ **These records are DYNAMICALLY GENERATED and cannot be predicted**
✅ **We MUST query Graph API to get expected values**

The module's core value:
1. Query Graph API for what Microsoft EXPECTS
2. Query DNS for what's ACTUALLY configured
3. Compare them
4. Alert on differences

## Example: Why We Need Graph API

### MX Record (dynamically generated):
```
Expected from Graph: contoso-com.mail.protection.outlook.com
Actual from DNS:     old-server.example.com
Result:              MISMATCH - admin hasn't updated DNS
```

### DKIM Selector (unpredictable):
```
Expected from Graph: selector1-contoso-com._domainkey.contoso.onmicrosoft.com
Actual from DNS:     (not configured)
Result:              MISSING - admin needs to add this CNAME
```

Without Graph API, we cannot know:
- The exact MX hostname (tenant-specific)
- The exact DKIM selector targets (tenant + domain specific)
- The exact verification code
- Whether records are even needed (depends on M365 services enabled)

## Graph API Coverage Table

| Record Type | Purpose | Graph Provides | Dynamically Generated |
|-------------|---------|----------------|----------------------|
| MX | Mail routing | ✅ serviceConfigurationRecords | Yes (tenant-domain) |
| CNAME autodiscover | Outlook config | ✅ serviceConfigurationRecords | No (static) |
| CNAME selector1 | DKIM | ✅ serviceConfigurationRecords | Yes (tenant-domain) |
| CNAME selector2 | DKIM | ✅ serviceConfigurationRecords | Yes (tenant-domain) |
| CNAME sip | Teams | ✅ serviceConfigurationRecords | No (static) |
| CNAME lyncdiscover | Teams mobile | ✅ serviceConfigurationRecords | No (static) |
| SRV _sip._tls | Teams | ✅ serviceConfigurationRecords | No (static) |
| SRV _sipfederationtls | Teams federation | ✅ serviceConfigurationRecords | No (static) |
| CNAME enterpriseenrollment | Intune | ✅ serviceConfigurationRecords | No (static) |
| CNAME enterpriseregistration | Azure AD join | ✅ serviceConfigurationRecords | No (static) |
| TXT verification | Domain ownership | ✅ verificationDnsRecords | Yes (random code) |
| TXT SPF | Email auth | ❌ Admin creates | N/A |
| TXT DMARC | Email auth | ❌ Admin creates | N/A |

## PowerShell Code to Get ALL Records

```powershell
# Connect
Connect-MgGraph -Scopes "Domain.Read.All"

# Get domain
$domain = Get-MgDomain -DomainId "contoso.com"

# Get Microsoft-generated service records (MX, CNAMEs, SRVs)
$serviceRecords = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Get verification records (if domain not verified)
if (-not $domain.IsVerified) {
    $verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId "contoso.com"
}

# These return objects like:
# @odata.type: #microsoft.graph.domainDnsMxRecord
# id: <guid>
# recordType: "MX"
# label: "@"
# mailExchange: "contoso-com.mail.protection.outlook.com"
# preference: 0
# ttl: 3600
```

## CONCLUSION FOR MODULE DESIGN

We MUST keep Graph API integration because:
1. ✅ It's the ONLY source of truth for expected DNS
2. ✅ Records are dynamically generated (cannot hardcode)
3. ✅ It tells us which services are enabled (don't validate disabled services)
4. ✅ It provides exact values for comparison

The module workflow:
```powershell
# Get expected (from Microsoft)
$expected = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Get actual (from DNS)
$actual = Resolve-DnsName "contoso.com" -Type MX

# Compare
if ($actual.NameExchange -ne $expected.mailExchange) {
    Write-Warning "MX record mismatch!"
}
```

NO WAY to do this without Graph API.
