# TXT Records in Microsoft Graph API serviceConfigurationRecords - Complete Research

## Research Date
2025-11-06

## Research Question
What TXT records are returned by Microsoft Graph API's `Get-MgDomainServiceConfigurationRecord` cmdlet, and which TXT records are NOT included?

---

## Executive Summary

Microsoft Graph API's `serviceConfigurationRecords` endpoint returns **ONLY SPF TXT records** for email authentication. All other TXT records (DMARC, domain verification, BIMI, MTA-STS, etc.) are either:
1. In a different endpoint (verificationDnsRecords)
2. Admin-created and not provided by Microsoft APIs
3. Not applicable to Microsoft 365 services

---

## FINDINGS: TXT Record Types

### ✅ SPF TXT Records: **YES - IN serviceConfigurationRecords**

**Evidence:**
1. **Official Microsoft Graph API Documentation** ([source](https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords))
   ```json
   {
     "@odata.type":"microsoft.graph.domainDnsTxtRecord",
     "isOptional": false,
     "label": "contoso.com",
     "recordType": "Txt",
     "supportedService": "Email",
     "ttl": 3600,
     "text": "v=spf1 include: spf.protection.outlook.com ~all"
   }
   ```

2. **Real-World Example** (May 2024 - timmcmic.wordpress.com)
   - Blog post demonstrates `Get-MgDomainServiceConfigurationRecord` returning SPF TXT record
   - Text value: `"v=spf1 include:spf.protection.outlook.com -all"`
   - Listed alongside MX, CNAME, and SRV records

3. **Microsoft Graph API Resource Documentation**
   - `domainDnsTxtRecord` resource type supported in serviceConfigurationRecords
   - `supportedService` property can be "Email" for SPF records
   - Part of official v1.0 API (not beta)

**Format:**
- **Host/Label:** `@` (domain apex) or domain name
- **Type:** TXT
- **Value:** `v=spf1 include:spf.protection.outlook.com -all` (or with ~all for soft fail)
- **supportedService:** "Email"
- **isOptional:** false

**Why it's included:**
- Microsoft GENERATES this record recommendation based on tenant configuration
- Required for Exchange Online email delivery
- Dynamically configured based on enabled services

---

### ❌ DMARC TXT Records: **NO - NOT in serviceConfigurationRecords**

**Evidence:**
1. **Official Microsoft Documentation** ([source](https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dmarc-configure))
   > "There are no admin portals or PowerShell cmdlets in Microsoft 365 for you to manage DMARC TXT records in your custom domains. Instead, you create the DMARC TXT record at your domain registrar or DNS hosting service."

2. **Real-World Example** (May 2024 - timmcmic.wordpress.com)
   - Example output from `Get-MgDomainServiceConfigurationRecord` shows:
     - ✅ MX records
     - ✅ SPF TXT record
     - ✅ CNAME records (autodiscover, sip, etc.)
     - ✅ SRV records
     - ❌ **NO DMARC _dmarc TXT record**

3. **Multiple Microsoft 365 Setup Guides Confirm**
   - All guides state DMARC must be manually created by admin
   - No Microsoft API provides DMARC record values
   - Microsoft recommends starting with `p=none` and gradually increasing to `p=reject`

**Format (if admin creates it):**
- **Host/Label:** `_dmarc`
- **Type:** TXT
- **Value:** `v=DMARC1; p=none; rua=mailto:dmarc@example.com`

**Why it's NOT included:**
- DMARC policy is **ADMIN-DEFINED**, not Microsoft-generated
- Organizations choose their own policy (none/quarantine/reject)
- Organizations specify their own reporting email addresses
- No "default" DMARC configuration exists

---

### ❌ Domain Verification TXT Records: **NO - In verificationDnsRecords Instead**

**Evidence:**
1. **Microsoft Graph API Separation**
   - **verificationDnsRecords endpoint:** `GET /domains/{id}/verificationDnsRecords`
   - **serviceConfigurationRecords endpoint:** `GET /domains/{id}/serviceConfigurationRecords`
   - These are TWO SEPARATE endpoints with different purposes

2. **Official Documentation Distinction**
   - verificationDnsRecords: "DNS records the customer adds to verify domain ownership"
   - serviceConfigurationRecords: "DNS records to enable services for the domain"

3. **PowerShell Cmdlet Separation**
   ```powershell
   # For domain verification
   Get-MgDomainVerificationDnsRecord -DomainId "contoso.com"

   # For service configuration (MX, SPF, CNAMEs, SRVs)
   Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"
   ```

4. **Real-World Usage**
   - Blog posts and tutorials consistently show verification TXT in separate queries
   - Example: `(Get-MgDomainVerificationDnsRecord -DomainId "domain.com" | Where-Object {$_.RecordType -eq "Txt"}).AdditionalProperties.text`

**Format:**
- **Host/Label:** `@` or custom subdomain (e.g., `_domainverify`)
- **Type:** TXT
- **Value:** `MS=msXXXXXXXX` (unique verification code)
- **Endpoint:** verificationDnsRecords (**NOT** serviceConfigurationRecords)

**Why it's separate:**
- Different lifecycle: Verification is one-time, service records are permanent
- Different purpose: Ownership proof vs. service enablement
- Can be removed after verification (though not recommended)

---

### ❌ DKIM TXT Records: **N/A - DKIM Uses CNAME Records**

**Important Clarification:**
DKIM does NOT use TXT records in Microsoft 365. DKIM uses **CNAME records** that point to Microsoft-hosted TXT records.

**Evidence:**
1. **Official Microsoft DKIM Documentation** ([source](https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure))
   > "Use the Defender portal or Exchange Online PowerShell to view the required CNAME values for DKIM signing"
   - No mention of Microsoft Graph API

2. **DKIM Record Format:**
   ```
   selector1._domainkey.contoso.com CNAME selector1-contoso-com._domainkey.contoso.onmicrosoft.com
   selector2._domainkey.contoso.com CNAME selector2-contoso-com._domainkey.contoso.onmicrosoft.com
   ```

3. **How to Get DKIM Records:**
   - ✅ Exchange Online PowerShell: `Get-DkimSigningConfig -Identity "contoso.com"`
   - ✅ Microsoft Defender Portal: Enable DKIM, dialog shows CNAME values
   - ❌ Microsoft Graph API: **NOT AVAILABLE**

**Real-World Example (May 2024):**
- `Get-MgDomainServiceConfigurationRecord` output shows:
  - ✅ autodiscover CNAME
  - ✅ sip CNAME
  - ✅ lyncdiscover CNAME
  - ✅ enterpriseenrollment CNAME
  - ❌ **NO selector1._domainkey CNAME**
  - ❌ **NO selector2._domainkey CNAME**

**Why DKIM CNAMEs are NOT in serviceConfigurationRecords:**
- DKIM configuration is managed through Exchange Online, not Azure AD/Entra ID
- Microsoft separates domain management (Graph API) from mail flow configuration (Exchange Online)
- DKIM must be explicitly enabled in Exchange admin center before selectors are generated

---

### ❌ Other TXT Records: **NOT in serviceConfigurationRecords**

**BIMI (Brand Indicators for Message Identification):**
- Host: `default._bimi`
- Status: **Admin-created, not in API**
- Microsoft does not auto-generate BIMI records

**MTA-STS (Mail Transfer Agent Strict Transport Security):**
- Host: `_mta-sts`
- Status: **Admin-created, not in API**
- Microsoft 365 supports MTA-STS but doesn't auto-configure it

**TLS-RPT (TLS Reporting):**
- Host: `_smtp._tls`
- Status: **Admin-created, not in API**
- Optional reporting configuration

**Third-Party Verification TXT Records:**
- Google, Adobe, Facebook, Apple domain verification
- Status: **Admin-created for third-party services**

---

## Complete Summary Table

| TXT Record Type | In serviceConfigurationRecords? | Evidence | Where to Find It |
|----------------|--------------------------------|----------|------------------|
| **SPF** | ✅ **YES** | Official MS docs, real-world examples | `Get-MgDomainServiceConfigurationRecord` |
| **DMARC** | ❌ **NO** | Admin must create manually | Domain registrar/DNS provider |
| **Verification (MS=)** | ❌ **NO** | Separate endpoint | `Get-MgDomainVerificationDnsRecord` |
| **DKIM** | ❌ **N/A** | Uses CNAMEs, not TXT (CNAMEs also NOT in serviceConfigurationRecords) | `Get-DkimSigningConfig` (Exchange Online PowerShell) |
| **BIMI** | ❌ **NO** | Admin must create manually | Domain registrar/DNS provider |
| **MTA-STS** | ❌ **NO** | Admin must create manually | Domain registrar/DNS provider |
| **TLS-RPT** | ❌ **NO** | Admin must create manually | Domain registrar/DNS provider |

---

## What IS in serviceConfigurationRecords?

### Complete List of Record Types Returned:

1. **MX Record** (1 record)
   - `domain-tld.mail.protection.outlook.com`
   - For Exchange Online mail routing

2. **SPF TXT Record** (1 record)
   - `v=spf1 include:spf.protection.outlook.com -all`
   - For email authentication

3. **CNAME Records** (6-8 records depending on services enabled)
   - `autodiscover` → `autodiscover.outlook.com` (Exchange)
   - `sip` → `sipdir.online.lync.com` (Teams)
   - `lyncdiscover` → `webdir.online.lync.com` (Teams mobile)
   - `enterpriseenrollment` → `enterpriseenrollment.manage.microsoft.com` (Intune)
   - `enterpriseregistration` → `enterpriseregistration.windows.net` (Azure AD Join)
   - `msoid` → `clientconfig.microsoftonline-p.net` ⚠️ **DEPRECATED - REMOVE IF PRESENT**

4. **SRV Records** (2 records for Teams)
   - `_sip._tls` → `sipdir.online.lync.com:443`
   - `_sipfederationtls._tcp` → `sipfed.online.lync.com:5061`

**Total Records:** Typically 10-12 records depending on enabled services

---

## What is NOT in serviceConfigurationRecords?

### Records in Different Endpoints:

1. **Domain Verification TXT** → Use `Get-MgDomainVerificationDnsRecord`

### Records in Different PowerShell Modules:

1. **DKIM Selector CNAMEs** → Use `Get-DkimSigningConfig` (Exchange Online PowerShell)

### Records Admin Must Create:

1. **DMARC TXT** → Admin creates at DNS provider
2. **BIMI TXT** → Admin creates at DNS provider
3. **MTA-STS TXT** → Admin creates at DNS provider
4. **TLS-RPT TXT** → Admin creates at DNS provider
5. **Third-party verification TXT** → Admin creates at DNS provider

---

## Key Architectural Finding

Microsoft separates DNS record management across THREE systems:

### 1. Microsoft Graph API - Domain Management
**Endpoint:** `GET /domains/{id}/serviceConfigurationRecords`
**Purpose:** Microsoft-GENERATED service records
**Returns:**
- MX (mail routing)
- SPF TXT (email authentication framework)
- CNAMEs (autodiscover, Teams, Intune)
- SRVs (Teams federation)

### 2. Microsoft Graph API - Domain Verification
**Endpoint:** `GET /domains/{id}/verificationDnsRecords`
**Purpose:** Domain ownership proof
**Returns:**
- Verification TXT (MS=msXXXXXXXX)
- Alternative verification MX

### 3. Exchange Online PowerShell - Mail Flow Configuration
**Cmdlet:** `Get-DkimSigningConfig`
**Purpose:** Email security configuration
**Returns:**
- DKIM selector1 CNAME target
- DKIM selector2 CNAME target
- DKIM enablement status

### 4. Admin Manual Configuration
**Purpose:** Policy-based and third-party records
**Admin Creates:**
- DMARC policy TXT
- BIMI branding TXT
- MTA-STS security TXT
- TLS-RPT reporting TXT

---

## Impact on DNS4M365 Module

### Current Documentation Status:

**GRAPH-API-DNS-COVERAGE.md:**
- ❌ **INCORRECT:** Claims SPF/DMARC are NOT in Graph API
- ✅ **CORRECT:** SPF IS in serviceConfigurationRecords
- ❌ **INCORRECT:** DMARC is NOT admin-created in the sense it's not in any Microsoft API

**DKIM-RECORDS-FINDING.md:**
- ✅ **CORRECT:** DKIM records NOT in serviceConfigurationRecords
- ✅ **CORRECT:** SPF TXT records ARE in serviceConfigurationRecords
- ✅ **CORRECT:** Only Exchange Online PowerShell provides DKIM values

### Recommendations:

1. **Update GRAPH-API-DNS-COVERAGE.md** to reflect that SPF TXT IS returned
2. **Document the three-system architecture** clearly
3. **For module functionality:**
   - ✅ Can validate SPF from Graph API
   - ❌ Cannot validate DMARC (no source of expected value)
   - ❌ Cannot validate DKIM without Exchange Online PowerShell integration
   - ✅ Can validate verification TXT from verificationDnsRecords endpoint

---

## Sources

### Official Microsoft Documentation:
1. [List serviceConfigurationRecords - Microsoft Graph v1.0](https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords)
2. [List verificationDnsRecords - Microsoft Graph v1.0](https://learn.microsoft.com/en-us/graph/api/domain-list-verificationdnsrecords)
3. [DMARC Configuration - Microsoft Defender](https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dmarc-configure)
4. [DKIM Configuration - Microsoft Defender](https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure)
5. [Get-DkimSigningConfig - Exchange PowerShell](https://learn.microsoft.com/en-us/powershell/module/exchange/get-dkimsigningconfig)
6. [domainDnsTxtRecord Resource Type](https://learn.microsoft.com/en-us/graph/api/resources/domaindnstxtrecord)

### Real-World Examples:
1. [Using Graph PowerShell to list domain DNS records (May 2024)](https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/)
   - Shows actual output from Get-MgDomainServiceConfigurationRecord
   - Confirms SPF TXT is included
   - Confirms DKIM CNAMEs are NOT included
   - Confirms DMARC is NOT included

### Community Documentation:
1. Multiple DMARC setup guides confirm manual creation required
2. Multiple DKIM setup guides reference Exchange Online PowerShell
3. Stack Overflow and Microsoft Q&A discussions confirm findings

---

## Testing Recommendations

To validate these findings in your own tenant:

```powershell
# 1. Connect to Microsoft Graph
Connect-MgGraph -Scopes "Domain.Read.All"

# 2. Get service configuration records (includes SPF TXT)
$serviceRecords = Get-MgDomainServiceConfigurationRecord -DomainId "yourdomain.com"
$serviceRecords | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.domainDnsTxtRecord' }

# 3. Get verification records (includes MS= TXT)
$verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId "yourdomain.com"
$verificationRecords | Where-Object { $_.RecordType -eq 'Txt' }

# 4. For DKIM - requires Exchange Online PowerShell
Connect-ExchangeOnline
Get-DkimSigningConfig -Identity "yourdomain.com" | Format-List Selector1CNAME, Selector2CNAME
```

---

## Conclusion

**Answer to Research Question:**

Microsoft Graph API's `Get-MgDomainServiceConfigurationRecord` returns **ONLY ONE TYPE of TXT record**:
- ✅ **SPF TXT record** for email authentication

**All other TXT records are NOT included:**
- ❌ DMARC TXT (admin must create manually)
- ❌ Verification TXT (in separate verificationDnsRecords endpoint)
- ❌ DKIM TXT (DKIM uses CNAMEs, which are also NOT in serviceConfigurationRecords)
- ❌ BIMI, MTA-STS, TLS-RPT (admin must create manually)

This architectural separation reflects Microsoft's division between:
1. **Auto-generated service records** (serviceConfigurationRecords)
2. **Domain ownership proof** (verificationDnsRecords)
3. **Mail flow configuration** (Exchange Online PowerShell)
4. **Policy-based configuration** (Admin manual creation)

---

**Research Completed:** 2025-11-06
**Confidence Level:** ✅ High (Multiple official sources + real-world validation)
**Last Updated:** 2025-11-06
