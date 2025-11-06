# Critical Finding: DKIM Records NOT in Microsoft Graph API

## Summary

After thorough research of official Microsoft documentation and real-world examples, I found that **DKIM CNAME records are NOT returned by `Get-MgDomainServiceConfigurationRecord`**. They can only be obtained through **Exchange Online PowerShell**.

## Evidence

### 1. Official Microsoft Graph Documentation

**Source:** https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords

The example response shows ONLY:
- MX records (`domainDnsMxRecord`)
- TXT records (`domainDnsTxtRecord`)

**CNAME records are NOT shown in any official example.**

### 2. Real-World Example (2024)

**Source:** https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/

Blog post using `Get-MgDomainServiceConfigurationRecord` in May 2024 shows:
- ✅ MX records
- ✅ SPF TXT records
- ✅ CNAME records (autodiscover, sip, lyncdiscover, msoid, enterpriseregistration, enterpriseenrollment)
- ✅ SRV records (_sip._tls, _sipfederationtls._tcp)
- ❌ **NO DKIM selector1._domainkey or selector2._domainkey CNAME records**

### 3. Official Microsoft Documentation on DKIM

**Source:** https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure

Quote:
> "Use the Defender portal or Exchange Online PowerShell to view the required CNAME values for DKIM signing of outbound messages using a custom domain."

**Does NOT mention Microsoft Graph API as a source for DKIM records.**

### 4. Get-DkimSigningConfig (Exchange Online PowerShell)

**Source:** https://learn.microsoft.com/en-us/powershell/module/exchange/get-dkimsigningconfig

Official cmdlet for retrieving DKIM configuration:
```powershell
Get-DkimSigningConfig -Identity "contoso.com" | Format-List Selector1CNAME, Selector2CNAME
```

**This is the ONLY documented way to get DKIM CNAME values.**

### 5. Multiple Community Sources Confirm

**Sources:**
- https://danielchronlund.com/2020/04/29/quickly-check-and-manage-your-exchange-online-dns-records-for-spf-dkim-and-dmarc-with-powershell/
- https://o365info.com/get-the-value-of-the-dkim-record-for-a-domain-using-powershell-office-365-part-7-10/
- https://www.alitajran.com/configure-dkim-record-for-office-365/

All sources use **Exchange Online PowerShell (`Get-DkimSigningConfig`)**, not Microsoft Graph API.

## What Microsoft Graph API DOES Return

From serviceConfigurationRecords:
- ✅ MX records (Exchange Online mail routing)
- ✅ CNAME records for:
  - autodiscover (Exchange Autodiscover)
  - sip / lyncdiscover (Skype for Business / Teams)
  - enterpriseregistration / enterpriseenrollment (Intune/MDM)
- ✅ SRV records (Skype for Business / Teams)
- ✅ TXT records (verification codes)

## What Microsoft Graph API Does NOT Return

From any endpoint:
- ❌ DKIM selector CNAME records (selector1._domainkey, selector2._domainkey)
- ❌ Admin-created SPF TXT records
- ❌ Admin-created DMARC TXT records

## Why This Matters

### Impact on DNS4M365 Module

1. **GRAPH-API-DNS-COVERAGE.md is INCORRECT** - Claims Graph API provides DKIM records
2. **Test-M365DnsCompliance** - Cannot validate expected DKIM values without Graph API data
3. **Compare-M365DnsRecord** - Cannot compare expected vs actual DKIM records

### The Architecture Gap

**Current assumption:** Microsoft Graph API provides all Microsoft-generated DNS records

**Reality:**
- Microsoft Graph API: Provides MOST service configuration records
- Exchange Online PowerShell: Required for DKIM CNAME values
- Admin configuration: SPF and DMARC are manually configured, not in Graph API

## Recommended Fix

### Option 1: Add Exchange Online PowerShell Dependency (Complex)

```powershell
RequiredModules = @(
    @{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion = '2.0.0'},
    @{ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.0.0'}
)
```

Then use:
```powershell
# Get most records from Graph API
$serviceRecords = Get-MgDomainServiceConfigurationRecord -DomainId $domain

# Get DKIM records from Exchange Online PowerShell
Connect-ExchangeOnline
$dkimConfig = Get-DkimSigningConfig -Identity $domain
# Use $dkimConfig.Selector1CNAME and $dkimConfig.Selector2CNAME
```

**Pros:** Complete coverage
**Cons:** Two authentication contexts, more complex, requires Exchange Online license/permissions

### Option 2: Document the Limitation (Simple - KISS)

Update documentation to clarify:
- Graph API provides MX, Autodiscover, SIP/Skype CNAMEs, SRVs
- DKIM CNAME records must be obtained separately via Exchange Online PowerShell or Defender portal
- Module validates DNS records that ARE in Graph API
- For DKIM validation, users should:
  1. Get expected values: `Get-DkimSigningConfig`
  2. Pass as parameter: `Test-M365DnsCompliance -DKIMSelector1 "selector1-contoso-com._domainkey.contoso.onmicrosoft.com"`

**Pros:** Simpler, maintains KISS principle, no additional auth complexity
**Cons:** Doesn't automatically validate DKIM records

### Option 3: Skip DKIM Validation Entirely (Simplest)

Focus on what Graph API DOES provide:
- MX record validation ✅
- Autodiscover CNAME validation ✅
- SIP/Teams CNAME validation ✅
- SRV record validation ✅
- Verification TXT validation ✅

Document that DKIM validation is out of scope for this module.

**Pros:** Honest about capabilities, simplest implementation
**Cons:** Less comprehensive DNS validation

## Conclusion

The original claim that "ALL in scope DNS records can be gotten from [Graph API]" is **FALSE** for DKIM records.

Microsoft intentionally separates:
- **Domain management** (Graph API) - Domain verification, basic service records
- **Exchange Online mail configuration** (Exchange Online PowerShell) - DKIM, mail flow rules, etc.

The module should either:
1. Add Exchange Online PowerShell support (complex, breaks KISS)
2. Accept the limitation and document it clearly (KISS-compliant)
3. Remove DKIM validation claims (most honest)

**Recommendation:** Option 2 - Document the limitation, allow optional DKIM parameters if users want to manually provide expected values.
