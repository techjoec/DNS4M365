# Research: SIP, lyncdiscover, and Teams-related DNS Records in Microsoft Graph API

## Research Question

Are SIP, lyncdiscover, and Teams-related CNAME/SRV records returned by Microsoft Graph API's `Get-MgDomainServiceConfigurationRecord` cmdlet? Are these legacy Skype for Business records or current Teams requirements?

## Executive Summary

**YES** - These records ARE returned by `Get-MgDomainServiceConfigurationRecord`, BUT they are **legacy Skype for Business records** that are **NO LONGER REQUIRED for Teams-only tenants** (as of 2024).

---

## Findings

### 1. ARE THESE RECORDS IN serviceConfigurationRecords?

✅ **YES** - All SIP/lyncdiscover records are returned by Graph API

**Evidence from Real-World Example (May 2024)**:

Source: https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/

Real output from `Get-MgDomainServiceConfigurationRecord` shows:

**CNAME Records:**
- `sip.domain.net` → `sipdir.online.lync.com`
- `lyncdiscover.domain.net` → `webdir.online.lync.com`
- `autodiscover.domain.net` → `autodiscover.outlook.com`
- `enterpriseenrollment.domain.net` → `enterpriseenrollment-s.manage.microsoft.com`
- `enterpriseregistration.domain.net` → `enterpriseregistration.windows.net`

**SRV Records:**
- `_sip._tls.domain.net` → `sipdir.online.lync.com:443` (priority 100, weight 1)
- `_sipfederationtls._tcp.domain.net` → `sipfed.online.lync.com:5061` (priority 100, weight 1)

---

## 2. WHICH SPECIFIC RECORDS?

| Record | Type | Target | Returned by Graph API? |
|--------|------|--------|------------------------|
| **sip** | CNAME | `sipdir.online.lync.com` | ✅ YES |
| **lyncdiscover** | CNAME | `webdir.online.lync.com` | ✅ YES |
| **_sip._tls** | SRV | `sipdir.online.lync.com:443` | ✅ YES |
| **_sipfederationtls._tcp** | SRV | `sipfed.online.lync.com:5061` | ✅ YES |

---

## 3. ARE THESE LEGACY SKYPE FOR BUSINESS RECORDS?

✅ **YES** - These are legacy Skype for Business Online records

**Evidence:**

### Source 1: UC Lobby (March 2024) - "Time to say goodbye to sipdir and webdir"
**URL**: https://uclobby.com/2024/03/19/time-to-say-goodbye-to-sipdir-and-webdir/

**Quote:**
> "With **Skype for Business Online** decommission the required **DNS Records** for tenants that are **Teams Only** changed, now we no longer required to have the following:
> - `sip.<SIP Domain>` (CNAME)
> - `lyncdiscover.<SIP Domain>` (CNAME)
> - `_sip._tls.<SIP Domain>` (SRV)"

### Source 2: Microsoft Community (June 2021)
**URL**: https://techcommunity.microsoft.com/t5/upgrade-skype-for-business-to/are-the-dns-records-for-skype-for-business-online-still-required/td-p/2750216

**Summary:**
- These records "apply to Teams, especially in a hybrid Teams and Skype for Business scenario"
- Many organizations operate without these records without issues
- Still needed if federated partners use Skype for Business

### Source 3: Microsoft Learn - Decommissioning Documentation
**URL**: https://learn.microsoft.com/en-us/skypeforbusiness/hybrid/decommission-manage-dns-entries

**Quote:**
> "Teams does not require these specific records. Once your organization has no on-premises users, these DNS entries must be updated to point to Microsoft 365 (or in some cases removed)."

---

## 4. ARE THEY STILL REQUIRED FOR TEAMS, OR DEPRECATED?

**Status: OPTIONAL (NOT DEPRECATED, BUT NO LONGER REQUIRED)**

### Current Status by Record (2024-2025):

| Record | Status for Teams-Only | Required? | Purpose |
|--------|----------------------|-----------|---------|
| **sip CNAME** | ❌ **NOT REQUIRED** | Optional | Legacy federation (Skype for Business era) |
| **lyncdiscover CNAME** | ❌ **NOT REQUIRED** | Optional | Legacy mobile discovery (Skype for Business era) |
| **_sip._tls SRV** | ❌ **NOT REQUIRED** | Optional | Legacy SIP service discovery |
| **_sipfederationtls._tcp SRV** | ⚠️ **CONDITIONALLY REQUIRED** | Only if federation needed | SIP federation with external orgs |

### What Changed?

**Before (Skype for Business Online era - before July 2021):**
- ✅ All four records REQUIRED
- Used for Skype for Business client sign-in
- Used for mobile discovery
- Used for federation

**After (Teams-only era - 2024+):**
- ❌ `sip` CNAME: No longer required
- ❌ `lyncdiscover` CNAME: No longer required
- ❌ `_sip._tls` SRV: No longer required
- ⚠️ `_sipfederationtls._tcp` SRV: Only required for federation

### Why Keep Them?

**Scenarios where these records are still useful:**

1. **Hybrid Deployments**: Organizations with Skype for Business on-premises + Teams
2. **Federation Partners**: Partners still using Skype for Business Online/Server
3. **Resource Account Creation**: Some tenants report issues without `_sipfederationtls._tcp`
4. **No Harm in Keeping**: Microsoft says "there's no harm in keeping them"

### Why Remove Them?

**Scenarios where they should be removed:**

1. **Pure Teams-only tenant**: No Skype for Business anywhere
2. **No federation needed**: Internal-only communication
3. **TeamsOnly mode upgrade**: Legacy records can block TeamsOnly tenant upgrade
4. **DNS cleanup**: Reduce DNS record count and complexity

---

## 5. TEAMS-ONLY TENANTS VS HYBRID

### Teams-Only Tenants (No Skype for Business)

**Required DNS:**
- ⚠️ `_sipfederationtls._tcp` SRV (only if federation needed)

**NOT Required:**
- ❌ `sip` CNAME
- ❌ `lyncdiscover` CNAME
- ❌ `_sip._tls` SRV

### Hybrid Tenants (Teams + Skype for Business On-Premises)

**Required DNS:**
- ✅ All four records still needed
- ✅ `sip` CNAME → `sipdir.online.lync.com`
- ✅ `lyncdiscover` CNAME → `webdir.online.lync.com`
- ✅ `_sip._tls` SRV → `sipdir.online.lync.com:443`
- ✅ `_sipfederationtls._tcp` SRV → `sipfed.online.lync.com:5061`

### Organizations with Federated Partners Using Skype for Business

**Required DNS:**
- ✅ `_sipfederationtls._tcp` SRV → `sipfed.online.lync.com:5061`
- ⚠️ `sip` CNAME (may be needed for discovery)

**NOT Required:**
- ❌ `lyncdiscover` CNAME
- ❌ `_sip._tls` SRV

---

## 6. MICROSOFT GRAPH API BEHAVIOR

### What Graph API Returns

`Get-MgDomainServiceConfigurationRecord` returns **ALL Microsoft-generated DNS records**, including:

✅ **Always Returned (if services enabled):**
- MX records (Exchange Online)
- Autodiscover CNAME (Exchange Online)
- SIP CNAMEs (Skype for Business / Teams)
- SRV records (Skype for Business / Teams)
- EnterpriseEnrollment/Registration CNAMEs (Intune/MDM)

❌ **NEVER Returned by Graph API:**
- DKIM selector CNAMEs (must use `Get-DkimSigningConfig` in Exchange Online PowerShell)
- Admin-created SPF TXT
- Admin-created DMARC TXT

### Why Does Graph API Still Return These Records?

Microsoft Graph API returns **all service configuration records** that were generated when services were enabled, even if:
1. The service is no longer active (e.g., Skype for Business)
2. The records are no longer strictly required (e.g., Teams-only mode)
3. The organization has migrated (e.g., from Skype to Teams)

**Reason**: Graph API provides the "expected state" based on what Microsoft 365 generated. It's up to administrators to:
- Validate which records are actually needed
- Remove legacy records if desired
- Understand the current vs legacy requirements

---

## 7. VALIDATION CMDLET

Microsoft provides a cmdlet to check DNS requirements for Teams-only:

```powershell
Test-UcTeamsOnlyDNSRequirements
```

**Purpose:**
- Identifies outdated DNS records
- Helps clean up legacy Skype for Business records
- Validates Teams-only DNS requirements

**Source**: UC Lobby article (March 2024)

---

## 8. MIGRATION CONSIDERATIONS

### When Upgrading to TeamsOnly Mode

**Problem**: Legacy DNS records can block TeamsOnly tenant upgrade

**Solution**: Use Teams admin center to identify blocking records
- Go to **Teams > Teams upgrade settings**
- Attempt to switch to TeamsOnly mode
- Any blocking DNS records will be shown in error message

**Records that may block upgrade:**
- Legacy SIP/lyncdiscover CNAMEs pointing to on-premises servers
- Misconfigured federation records

**Records that DON'T block upgrade:**
- Correctly configured CNAMEs pointing to Microsoft 365 (sipdir.online.lync.com, etc.)

---

## 9. REGIONAL VARIATIONS

### Commercial Cloud (Worldwide)

| Record | Target |
|--------|--------|
| sip | `sipdir.online.lync.com` |
| lyncdiscover | `webdir.online.lync.com` |
| _sip._tls | `sipdir.online.lync.com:443` |
| _sipfederationtls._tcp | `sipfed.online.lync.com:5061` |

### GCC High / DoD (US Government)

| Record | Target |
|--------|--------|
| sip | `sipdir.online.dod.skypeforbusiness.us` |
| lyncdiscover | `webdir.online.dod.skypeforbusiness.us` |
| _sip._tls | `sipdir.online.dod.skypeforbusiness.us:443` |
| _sipfederationtls._tcp | `sipfed.online.dod.skypeforbusiness.us:5061` |

### 21Vianet (China)

| Record | Target |
|--------|--------|
| sip | `sipdir.online.partner.lync.cn` |
| lyncdiscover | `webdir.online.partner.lync.cn` |

---

## 10. RECOMMENDATIONS

### For DNS4M365 Module

Based on this research, the module should:

✅ **DO:**
1. **Retrieve these records from Graph API** (they ARE available)
2. **Validate their presence** in DNS
3. **Identify them as "Legacy Skype for Business"** in output
4. **Provide guidance** on when they're needed vs optional
5. **Flag as "Optional for Teams-only"** in health checks

❌ **DON'T:**
1. **Mark as "Missing" with critical severity** (they're optional for Teams-only)
2. **Flag as "Deprecated"** (they're not deprecated, just optional)
3. **Recommend removal** without context (may be needed for hybrid/federation)

### Suggested Output Format

```powershell
RecordType  : CNAME
Label       : sip
Target      : sipdir.online.lync.com
Status      : Present
Service     : Skype for Business / Teams
Note        : Legacy Skype for Business record. Not required for Teams-only tenants without federation partners.
Recommendation: Optional - Keep if using hybrid or have Skype for Business federation partners. Safe to remove for pure Teams-only.
```

---

## 11. EVIDENCE URLS

### Primary Sources (Authoritative)

1. **Microsoft Learn - Decommissioning DNS**
   - https://learn.microsoft.com/en-us/skypeforbusiness/hybrid/decommission-manage-dns-entries
   - Official Microsoft documentation on managing DNS after Skype decommission

2. **Microsoft Graph API Documentation**
   - https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords
   - Official API reference (shows MX/TXT examples only, but includes all record types)

3. **Microsoft Community Hub**
   - https://techcommunity.microsoft.com/t5/upgrade-skype-for-business-to/are-the-dns-records-for-skype-for-business-online-still-required/td-p/2750216
   - Official Microsoft community response about DNS requirements

### Secondary Sources (Real-World Examples)

4. **UC Lobby (March 2024)**
   - https://uclobby.com/2024/03/19/time-to-say-goodbye-to-sipdir-and-webdir/
   - Current guidance on Teams-only DNS requirements and cleanup

5. **TimmcMic Blog (May 2024)**
   - https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/
   - Real-world example showing Graph API output with sip/lyncdiscover records

### Additional References

6. **Microsoft Q&A - DNS when decommissioning Skype**
   - https://learn.microsoft.com/en-us/answers/questions/499740/dns-records-when-we-want-to-decommission-skype-for

7. **Microsoft Q&A - DNS Records for MS Teams**
   - https://learn.microsoft.com/en-us/answers/questions/175555/dns-records-for-ms-teams

---

## 12. CONCLUSION

### Summary Table

| Question | Answer |
|----------|--------|
| **Are these records in serviceConfigurationRecords?** | ✅ **YES** |
| **Which specific records?** | sip CNAME, lyncdiscover CNAME, _sip._tls SRV, _sipfederationtls._tcp SRV |
| **Are these legacy Skype for Business records?** | ✅ **YES** (originally for Skype for Business Online) |
| **Are they still required for Teams?** | ⚠️ **OPTIONAL** (only _sipfederationtls._tcp needed for federation) |
| **Are they deprecated?** | ❌ **NO** (optional, not deprecated) |
| **Should Teams-only tenants keep them?** | ⚠️ **Optional** (safe to keep, not required) |
| **Should hybrid tenants keep them?** | ✅ **YES** (still required for hybrid scenarios) |

### Key Takeaways

1. **Graph API DOES provide these records** - Real-world evidence confirms this (May 2024)
2. **They are legacy Skype for Business records** - Documented by Microsoft
3. **Teams-only tenants don't require most of them** - Only federation SRV may be needed
4. **Hybrid scenarios still need them** - Required for Skype for Business on-premises integration
5. **Not harmful to keep** - Microsoft says "there's no harm in keeping them"
6. **Can be removed for cleanup** - Pure Teams-only organizations can safely remove them

### Impact on DNS4M365 Module

The module should:
- ✅ Expect these records from Graph API
- ✅ Validate their DNS presence
- ✅ Classify as "Legacy Skype for Business"
- ✅ Mark as "Optional for Teams-only"
- ✅ Provide context-aware recommendations

---

**Research Date**: 2025-01-06
**Researcher**: DNS4M365 Project
**Status**: Complete and Validated
