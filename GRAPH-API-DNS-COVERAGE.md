# Microsoft Graph API - DNS Record Coverage Research

**Last Updated:** 2025-01-06
**Validation Status:** ✅ Validated via 7 concurrent research agents with official Microsoft documentation

## Research Question
Can Microsoft Graph API provide ALL DNS records that M365 generates for custom domains?

## Answer: MOSTLY (With Important Exceptions)

✅ **Graph API provides MOST Microsoft-generated DNS records**
❌ **DKIM CNAMEs require Exchange Online PowerShell** (not in Graph API)
❌ **Admin-created records (DMARC) are not Microsoft-generated**

---

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

---

## What These Return (VALIDATED LIST)

### From serviceConfigurationRecords:

**Exchange Online:**
- ✅ MX record: `{tenant}-{domain}.mail.protection.outlook.com` (dynamically generated)
- ✅ CNAME: autodiscover.{domain} → autodiscover.outlook.com
- ✅ TXT (SPF): `v=spf1 include:spf.protection.outlook.com -all`

**DKIM (Exchange):**
- ❌ **NOT in serviceConfigurationRecords** - Requires Exchange Online PowerShell
- ❌ CNAME: selector1._domainkey.{domain} (not available via Graph API)
- ❌ CNAME: selector2._domainkey.{domain} (not available via Graph API)

**How to get DKIM CNAMEs:**
```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Get DKIM configuration
Get-DkimSigningConfig -Identity "contoso.com" |
    Format-List Selector1CNAME, Selector2CNAME
```

**Teams/Skype for Business:**
- ✅ CNAME: sip.{domain} → sipdir.online.lync.com (⚠️ deprecated for Teams-Only)
- ✅ CNAME: lyncdiscover.{domain} → webdir.online.lync.com (⚠️ deprecated for Teams-Only)
- ✅ SRV: _sip._tls.{domain} → sipdir.online.lync.com:443 (⚠️ deprecated for Teams-Only)
- ✅ SRV: _sipfederationtls._tcp.{domain} → sipfed.online.lync.com:5061 (still required if federation enabled)

**Intune/MDM:**
- ✅ CNAME: enterpriseenrollment.{domain} → enterpriseenrollment-s.manage.microsoft.com
- ✅ CNAME: enterpriseregistration.{domain} → enterpriseregistration.windows.net
- ✅ CNAME: msoid.{domain} → clientconfig.microsoftonline-p.net (⛔ **DEPRECATED** - remove immediately!)

### From verificationDnsRecords:

**Domain Verification:**
- ✅ TXT: MS=msXXXXXXXX (dynamically generated verification code)
- ✅ OR MX: {random-string}.pamx1.hotmail.com

---

## What Graph API DOES NOT RETURN

### ❌ DKIM Selector CNAMEs (Exchange Online PowerShell Only)
**Why NOT in Graph API:**
- DKIM is Exchange-specific workload configuration
- Graph API handles domain-level service configuration
- Architectural separation: Domain management vs. mail flow security

**Official Microsoft Documentation:**
> "Use the Defender portal or Exchange Online PowerShell to view the required CNAME values for DKIM signing"
>
> — [Microsoft Learn: DKIM Configuration](https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure)

**No mention of Microsoft Graph API as a source for DKIM records.**

### ❌ Admin-Created Records
These are policy-based, NOT Microsoft-generated:

- **DMARC (TXT)**: Admin must create `_dmarc.{domain}` with policy
  - Organizations choose their own policy (none/quarantine/reject)
  - No "Microsoft-provided" value
  - Official Microsoft documentation: "There are no admin portals or PowerShell cmdlets in Microsoft 365 for you to manage DMARC TXT records"

- **Custom DNS records**: Any additional records admin creates (BIMI, MTA-STS, etc.)

---

## CORRECTED CONCLUSION

### ✅ What Graph API DOES Provide:
- MX records (dynamically generated, tenant-specific)
- SPF TXT records (Microsoft-recommended value)
- Autodiscover CNAME
- Teams/Skype CNAMEs and SRVs (some deprecated)
- Intune/MDM CNAMEs
- Verification TXT (separate endpoint)

### ❌ What Graph API Does NOT Provide:
- DKIM selector CNAMEs (requires Exchange Online PowerShell)
- DMARC TXT (admin-created)

### 💡 Module Implication:
**We MUST keep Graph API integration** for most records, but:
- Cannot automatically validate DKIM without Exchange Online PowerShell
- Can optionally accept user-provided DKIM values for validation
- DMARC validation is out of scope (no "expected" value from Microsoft)

---

## Example: Why We Need Graph API

### MX Record (dynamically generated):
```
Expected from Graph: contoso-com.mail.protection.outlook.com
Actual from DNS:     old-server.example.com
Result:              MISMATCH - admin hasn't updated DNS
```

Without Graph API, we cannot know the exact MX hostname (tenant-specific).

### SPF TXT (Microsoft-provided):
```
Expected from Graph: v=spf1 include:spf.protection.outlook.com -all
Actual from DNS:     v=spf1 mx -all
Result:              MISMATCH - missing Microsoft 365 SPF include
```

### DKIM Selector (NOT in Graph API):
```
Expected from Exchange PS: selector1-contoso-com._domainkey.contoso.onmicrosoft.com
Actual from DNS:            (not configured)
Result:                     Cannot validate without Exchange PowerShell
```

---

## Graph API Coverage Table (VALIDATED)

| Record Type | Purpose | Graph Provides | Alternative Source | Dynamically Generated |
|-------------|---------|----------------|-------------------|----------------------|
| **MX** | Mail routing | ✅ serviceConfigurationRecords | N/A | Yes (tenant-domain) |
| **TXT (SPF)** | Email auth | ✅ serviceConfigurationRecords | N/A | No (static) |
| **CNAME autodiscover** | Outlook config | ✅ serviceConfigurationRecords | N/A | No (static) |
| **CNAME selector1** | DKIM | ❌ NOT in Graph API | Exchange Online PowerShell | Yes (tenant-domain) |
| **CNAME selector2** | DKIM | ❌ NOT in Graph API | Exchange Online PowerShell | Yes (tenant-domain) |
| **CNAME sip** | Teams | ✅ serviceConfigurationRecords (deprecated) | N/A | No (static) |
| **CNAME lyncdiscover** | Teams mobile | ✅ serviceConfigurationRecords (deprecated) | N/A | No (static) |
| **SRV _sip._tls** | Teams | ✅ serviceConfigurationRecords (deprecated) | N/A | No (static) |
| **SRV _sipfederationtls** | Teams federation | ✅ serviceConfigurationRecords | N/A | No (static) |
| **CNAME enterpriseenrollment** | Intune | ✅ serviceConfigurationRecords | N/A | No (static) |
| **CNAME enterpriseregistration** | Azure AD join | ✅ serviceConfigurationRecords | N/A | No (static) |
| **CNAME msoid** | Legacy auth | ✅ serviceConfigurationRecords (⛔ DEPRECATED) | N/A | No (static) |
| **TXT verification** | Domain ownership | ✅ verificationDnsRecords | N/A | Yes (random code) |
| **TXT DMARC** | Email auth | ❌ Admin creates | Manual DNS | N/A |

---

## PowerShell Code to Get ALL Available Records

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Domain.Read.All"

# Get domain
$domain = Get-MgDomain -DomainId "contoso.com"

# Get Microsoft-generated service records (MX, SPF TXT, CNAMEs, SRVs)
$serviceRecords = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Get verification records (if domain not verified)
if (-not $domain.IsVerified) {
    $verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId "contoso.com"
}

# For DKIM (requires separate connection to Exchange Online)
Connect-ExchangeOnline
$dkimConfig = Get-DkimSigningConfig -Identity "contoso.com"
Write-Host "DKIM Selector1: $($dkimConfig.Selector1CNAME)"
Write-Host "DKIM Selector2: $($dkimConfig.Selector2CNAME)"
```

---

## Microsoft's DNS Architecture Separation

Microsoft separates DNS record management across **THREE systems**:

### 1. Microsoft Graph API - Domain Service Configuration
**What:** Domain-level service enablement records
**Returns:**
- MX, SPF TXT
- Autodiscover, Teams/SIP, Intune CNAMEs
- Teams SRV records

### 2. Exchange Online PowerShell - Mail Security
**What:** Exchange-specific mail flow security
**Returns:**
- DKIM selector CNAMEs

### 3. Admin Manual Creation - Email Policy
**What:** Organization-defined email security policies
**Includes:**
- DMARC TXT
- BIMI, MTA-STS, TLS-RPT

---

## CONCLUSION FOR MODULE DESIGN

### We MUST keep Graph API integration because:
1. ✅ It's the primary source of truth for **MOST** expected DNS records
2. ✅ MX records are dynamically generated (cannot hardcode)
3. ✅ SPF TXT is Microsoft-provided (validates correct SPF include)
4. ✅ It tells us which services are enabled (don't validate disabled services)
5. ✅ It provides exact values for comparison

### We CANNOT automatically validate:
1. ❌ DKIM CNAMEs (requires Exchange Online PowerShell - adds complexity)
2. ❌ DMARC TXT (admin-created, no "expected" value from Microsoft)

### Recommended Approach (KISS Principle):
- **Validate** what Graph API provides (excellent coverage for most records)
- **Optionally accept** user-provided DKIM values via parameters
- **Document** DKIM limitation clearly
- **Skip** DMARC validation (out of scope - no expected value)
- **Don't add** Exchange Online PowerShell dependency (violates KISS)

### The module workflow:
```powershell
# Get expected (from Microsoft Graph API)
$expected = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Get actual (from DNS)
$actualMX = Resolve-DnsName "contoso.com" -Type MX
$actualSPF = Resolve-DnsName "contoso.com" -Type TXT

# Compare MX
if ($actualMX.NameExchange -ne $expected.mailExchange) {
    Write-Warning "MX record mismatch!"
}

# Compare SPF
$expectedSPF = ($expected | Where-Object {$_.RecordType -eq 'Txt'}).Text
if ($actualSPF.Strings -notcontains $expectedSPF) {
    Write-Warning "SPF record mismatch!"
}

# DKIM validation (optional - user provides expected values)
# OR skip DKIM validation entirely
```

---

## Evidence & Research Sources

- **Official Microsoft Graph API Documentation:**
  - https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords
  - https://learn.microsoft.com/en-us/graph/api/resources/domaindnsrecord

- **Official DKIM Documentation (confirms Graph API NOT mentioned):**
  - https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure

- **Official DMARC Documentation (confirms no cmdlets available):**
  - https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dmarc-configure

- **Real-World Validation (May 2024):**
  - https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/

- **Comprehensive Research Documents:**
  - See `COMPREHENSIVE-GRAPH-API-VALIDATION.md` for full research findings
  - See `DKIM-RECORDS-FINDING.md` for DKIM limitation evidence
  - See `TXT-RECORDS-SERVICECONFIGURATIONRECORDS-RESEARCH.md` for SPF/DMARC details

---

## Summary

**Original Question:** Can Graph API provide ALL M365-generated DNS records?

**Validated Answer:**
- ✅ YES for MX, SPF, Autodiscover, Teams/SIP, Intune CNAMEs and SRVs
- ❌ NO for DKIM CNAMEs (requires Exchange Online PowerShell)
- ❌ N/A for DMARC (admin-created, not Microsoft-generated)

**Module Strategy:**
Focus on what Graph API provides (comprehensive coverage), document DKIM limitation, optionally support user-provided DKIM values, maintain KISS principle.
