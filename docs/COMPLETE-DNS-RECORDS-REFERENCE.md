# Complete Microsoft 365 DNS Records Reference

## Comprehensive Deep Dive - All DNS Records for Microsoft 365

This document provides an exhaustive reference of **ALL** DNS records used by Microsoft 365 services, including required, optional, service-specific, regional, and deprecated records.

---

## Table of Contents

1. [MX Records](#mx-records)
2. [CNAME Records](#cname-records)
3. [TXT Records](#txt-records)
4. [SRV Records](#srv-records)
5. [Records by Service](#records-by-service)
6. [Regional & Cloud-Specific Records](#regional--cloud-specific-records)
7. [Deprecated Records](#deprecated-records)
8. [Optional vs Required](#optional-vs-required)
9. [Advanced Configurations](#advanced-configurations)

---

## MX Records

### Primary MX Record (Exchange Online)
**Purpose**: Route inbound email to Microsoft 365

| Property | Value | Notes |
|----------|-------|-------|
| **Host/Name** | `@` (root domain) | Points to domain apex |
| **Points to** | `<domain>-<tld>.mail.protection.outlook.com` | Example: `contoso-com.mail.protection.outlook.com` |
| **Priority** | `0` or `1` | Must be lowest (highest priority) |
| **TTL** | `3600` (1 hour) | Can be 300-86400 |

**Example**:
```
contoso.com.    MX    0    contoso-com.mail.protection.outlook.com.
```

### Alternative MX Formats

#### onmicrosoft.com Format
For tenants using `.onmicrosoft.com` domains:
```
Points to: tenant-onmicrosoft-com.mail.protection.outlook.com
```

#### Multiple MX Records (Hybrid)
When running Exchange hybrid:
```
Priority 0:  mail.contoso.com (On-premises)
Priority 10: contoso-com.mail.protection.outlook.com (Exchange Online)
```

#### Third-Party Email Security Gateway
```
Priority 0:  filter.emailsecurity.com (Security gateway)
Priority 10: contoso-com.mail.protection.outlook.com (Exchange Online backend)
```

### MX Record Variations by Deployment

| Deployment Type | MX Record Target |
|----------------|------------------|
| **Cloud-Only** | `domain.mail.protection.outlook.com` |
| **Hybrid (On-Prem Primary)** | On-prem MX (Priority 0), Cloud MX (Priority 10) |
| **Hybrid (Cloud Primary)** | Cloud MX (Priority 0), On-prem MX (Priority 10) |
| **Third-Party Filter** | Filter MX (Priority 0), Cloud backend (Priority 10) |
| **GCC High** | `domain.mail.protection.office365.us` |
| **GCC DoD** | `domain.mail.protection.office365.us` |

---

## CNAME Records

### Email & Exchange Online

#### 1. Autodiscover (Required)
**Purpose**: Automatic Outlook client configuration

| Host | Points to | TTL |
|------|-----------|-----|
| `autodiscover` | `autodiscover.outlook.com` | 3600 |

**Full Record**: `autodiscover.contoso.com CNAME autodiscover.outlook.com`

**What it does**:
- Enables automatic Outlook profile configuration
- Required for Outlook desktop, mobile, and web
- Critical for Exchange ActiveSync
- Used by mobile device management

#### 2. Autodiscover for Hybrid (Alternative)
When running hybrid Exchange:
```
autodiscover.contoso.com CNAME autodiscover.contoso.mail.onmicrosoft.com
```

### Teams / Skype for Business Online

#### 3. SIP (Required for Teams Federation)
**Purpose**: SIP service discovery for Teams/SfB

| Host | Points to | TTL |
|------|-----------|-----|
| `sip` | `sipdir.online.lync.com` | 3600 |

**Full Record**: `sip.contoso.com CNAME sipdir.online.lync.com`

#### 4. lyncdiscover (Required for Teams/SfB Mobile)
**Purpose**: Lync/Skype/Teams mobile autodiscovery

| Host | Points to | TTL |
|------|-----------|-----|
| `lyncdiscover` | `webdir.online.lync.com` | 3600 |

**Full Record**: `lyncdiscover.contoso.com CNAME webdir.online.lync.com`

### Mobile Device Management (Intune)

#### 5. EnterpriseEnrollment (Required for Intune)
**Purpose**: Device enrollment for Intune/MDM

| Host | Points to | TTL |
|------|-----------|-----|
| `enterpriseenrollment` | `enterpriseenrollment.manage.microsoft.com` | 3600 |

**Full Record**: `enterpriseenrollment.contoso.com CNAME enterpriseenrollment.manage.microsoft.com`

**What it does**:
- Enables Windows, iOS, Android device enrollment
- Required for Autopilot
- Used by Company Portal app
- Critical for mobile device management

#### 6. EnterpriseRegistration (Required for Azure AD Join)
**Purpose**: Workplace join / Azure AD device registration

| Host | Points to | TTL |
|------|-----------|-----|
| `enterpriseregistration` | `enterpriseregistration.windows.net` | 3600 |

**Full Record**: `enterpriseregistration.contoso.com CNAME enterpriseregistration.windows.net`

**What it does**:
- Enables Azure AD device registration
- Required for Hybrid Azure AD Join
- Used for workplace join scenarios
- Critical for SSO on devices

### Email Security (DKIM)

#### 7. DKIM Selector 1 (Required for DKIM Signing)
**Purpose**: DKIM public key for email authentication

| Host | Points to | TTL |
|------|-----------|-----|
| `selector1._domainkey` | `selector1-<domain>-<tld>._domainkey.<tenant>.onmicrosoft.com` | 3600 |

**Example**:
```
selector1._domainkey.contoso.com CNAME selector1-contoso-com._domainkey.contoso.onmicrosoft.com
```

**What it does**:
- Publishes DKIM public key
- Enables email authentication
- Helps prevent email spoofing
- Improves email deliverability

#### 8. DKIM Selector 2 (Required for DKIM Signing)
**Purpose**: DKIM key rotation / redundancy

| Host | Points to | TTL |
|------|-----------|-----|
| `selector2._domainkey` | `selector2-<domain>-<tld>._domainkey.<tenant>.onmicrosoft.com` | 3600 |

**Example**:
```
selector2._domainkey.contoso.com CNAME selector2-contoso-com._domainkey.contoso.onmicrosoft.com
```

**Why two selectors**:
- Enables key rotation without downtime
- Both selectors active simultaneously
- Microsoft rotates between them
- Best practice for DKIM implementation

### Legacy / Authentication

#### 9. MSOID (DEPRECATED - DO NOT USE)
**Status**: ⚠️ **DEPRECATED - MUST BE REMOVED**

| Host | Points to | Status |
|------|-----------|--------|
| `msoid` | `clientconfig.microsoftonline-p.net` | **DEPRECATED** |

**IMPORTANT**:
- ❌ **No longer needed** as of 2024
- ❌ **MUST be removed** from DNS if present
- ❌ **Blocks Microsoft 365 Apps activation** if present
- ❌ Incompatible with Microsoft 365 Enterprise Apps

**If you have this record**: Remove it immediately from your DNS zone.

### SharePoint & OneDrive (Region-Specific)

#### 10. SharePoint Vanity URL (Optional)
**Purpose**: Custom SharePoint URL

| Host | Points to | Notes |
|------|-----------|-------|
| `sharepoint` | `<tenant>.sharepoint.com` | Optional branding |
| `teams` | `<tenant>.sharepoint.com` | Optional Teams branding |

**Example**:
```
sharepoint.contoso.com CNAME contoso.sharepoint.com
```

### Microsoft Teams (Advanced)

#### 11. teams-share-svc (Service-Specific)
**Purpose**: Teams sharing services

| Host | Points to | Service |
|------|-----------|---------|
| `teams-share-svc` | Microsoft Teams infrastructure | Teams file sharing |

#### 12. teams-share-data (Service-Specific)
**Purpose**: Teams data sharing endpoint

| Host | Points to | Service |
|------|-----------|---------|
| `teams-share-data` | Microsoft Teams infrastructure | Teams data services |

### Azure AD / Entra ID

#### 13. federateddir-client (Federation)
**Purpose**: Federated directory client access

| Host | Points to | Service |
|------|-----------|---------|
| `federateddir-client` | Azure AD infrastructure | Federation services |

### Additional Service-Specific CNAMEs

#### 14. msappproxy (Application Proxy)
**Purpose**: Azure AD Application Proxy

| Host | Points to | Service |
|------|-----------|---------|
| Custom app subdomain | `<tenant>.msappproxy.net` | App Proxy |

**Example**:
```
app.contoso.com CNAME contoso-app.msappproxy.net
```

#### 15. _domainconnect (Domain Connect)
**Purpose**: Automated domain configuration

| Host | Points to | Service |
|------|-----------|---------|
| `_domainconnect` | Domain provider infrastructure | Auto-config |

---

## TXT Records

### Email Authentication

#### 1. SPF (Sender Policy Framework) - REQUIRED
**Purpose**: Authorize Microsoft 365 to send email on your behalf

| Host | Value | TTL |
|------|-------|-----|
| `@` | `v=spf1 include:spf.protection.outlook.com -all` | 3600 |

**Variations**:

**Basic M365 Only**:
```
v=spf1 include:spf.protection.outlook.com -all
```

**M365 + On-Premises Exchange**:
```
v=spf1 ip4:192.168.1.1 include:spf.protection.outlook.com -all
```

**M365 + Third-Party Email Service**:
```
v=spf1 include:spf.protection.outlook.com include:_spf.google.com -all
```

**M365 + SendGrid**:
```
v=spf1 include:spf.protection.outlook.com include:sendgrid.net -all
```

**Soft Fail (Testing)**:
```
v=spf1 include:spf.protection.outlook.com ~all
```

**Important SPF Notes**:
- ⚠️ Only ONE SPF record per domain allowed
- ⚠️ Maximum 10 DNS lookups (includes nested includes)
- ⚠️ Use `-all` for hard fail (recommended)
- ⚠️ Use `~all` for soft fail (testing only)
- ⚠️ Must include `spf.protection.outlook.com`

#### 2. DMARC (Domain-based Message Authentication) - HIGHLY RECOMMENDED
**Purpose**: Email authentication policy and reporting

| Host | Value | TTL |
|------|-------|-----|
| `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@contoso.com` | 3600 |

**DMARC Policy Levels**:

**Phase 1: Monitoring (Start Here)**:
```
v=DMARC1; p=none; rua=mailto:dmarc-reports@contoso.com; ruf=mailto:dmarc-forensics@contoso.com; fo=1
```

**Phase 2: Quarantine**:
```
v=DMARC1; p=quarantine; pct=10; rua=mailto:dmarc-reports@contoso.com; adkim=r; aspf=r
```

**Phase 3: Reject (Full Protection)**:
```
v=DMARC1; p=reject; rua=mailto:dmarc-reports@contoso.com; ruf=mailto:dmarc-forensics@contoso.com; adkim=s; aspf=s
```

**Subdomain Protection**:
```
v=DMARC1; p=reject; sp=quarantine; rua=mailto:dmarc-reports@contoso.com
```

**DMARC Parameters**:
- `p=` - Policy (none, quarantine, reject)
- `sp=` - Subdomain policy
- `rua=` - Aggregate report email
- `ruf=` - Forensic report email
- `pct=` - Percentage of messages to filter (1-100)
- `adkim=` - DKIM alignment (r=relaxed, s=strict)
- `aspf=` - SPF alignment (r=relaxed, s=strict)
- `fo=` - Forensic options (0,1,d,s)

### Domain Verification

#### 3. Domain Verification TXT Record
**Purpose**: Prove domain ownership to Microsoft 365

| Host | Value | TTL |
|------|-------|-----|
| `@` or verification subdomain | `MS=msXXXXXXXX` | 3600 |

**Formats**:

**Standard Verification**:
```
@ TXT MS=ms12345678
```

**Alternative Subdomain Verification**:
```
_domainverify TXT MS=ms12345678
```

**Multiple Verification Tokens** (if verifying for multiple services):
```
@ TXT MS=ms12345678
@ TXT MS=ms87654321
```

**Notes**:
- Token is unique per domain per tenant
- Can be removed after verification (but not recommended)
- Multiple TXT records on `@` are allowed
- Obtain from Microsoft 365 Admin Center

### Email Security - Additional

#### 4. BIMI (Brand Indicators for Message Identification) - OPTIONAL
**Purpose**: Display your logo in email clients

| Host | Value | TTL |
|------|-------|-----|
| `default._bimi` | `v=BIMI1; l=https://contoso.com/logo.svg; a=https://contoso.com/cert.pem` | 3600 |

**Example**:
```
default._bimi.contoso.com TXT "v=BIMI1; l=https://contoso.com/logo.svg"
```

**Requirements for BIMI**:
- DMARC policy must be `p=quarantine` or `p=reject`
- SVG logo hosted on HTTPS
- VMC (Verified Mark Certificate) recommended

#### 5. MTA-STS (Mail Transfer Agent Strict Transport Security) - OPTIONAL
**Purpose**: Enforce TLS for email delivery

| Host | Value | TTL |
|------|-------|-----|
| `_mta-sts` | `v=STSv1; id=20250101T000000` | 3600 |

**Example**:
```
_mta-sts.contoso.com TXT "v=STSv1; id=20250106120000"
```

**Requires**: Policy file hosted at `https://mta-sts.contoso.com/.well-known/mta-sts.txt`

#### 6. TLS Reporting (TLSRPT) - OPTIONAL
**Purpose**: TLS delivery failure reporting

| Host | Value | TTL |
|------|-------|-----|
| `_smtp._tls` | `v=TLSRPTv1; rua=mailto:tlsrpt@contoso.com` | 3600 |

**Example**:
```
_smtp._tls.contoso.com TXT "v=TLSRPTv1; rua=mailto:tlsrpt@contoso.com"
```

### Additional TXT Records

#### 7. Proof of Ownership (Various Services)
Microsoft 365 services may require additional verification:

```
@ TXT "adobe-idp-site-verification=xxxxx"
@ TXT "google-site-verification=xxxxx"
@ TXT "facebook-domain-verification=xxxxx"
@ TXT "apple-domain-verification=xxxxx"
```

---

## SRV Records

### Teams / Skype for Business Federation

#### 1. SIP TLS (Required for Teams External Access)
**Purpose**: Secure SIP service discovery

| Service | Protocol | Priority | Weight | Port | Target | TTL |
|---------|----------|----------|--------|------|--------|-----|
| `_sip` | `_tls` | `100` | `1` | `443` | `sipdir.online.lync.com` | 3600 |

**Full Record**:
```
_sip._tls.contoso.com SRV 100 1 443 sipdir.online.lync.com
```

**What it does**:
- Enables Teams federation with external organizations
- Required for external Teams chat/calling
- Used for Teams-to-Teams federation
- Necessary for federation discovery

#### 2. SIP Federation TLS (Required for Teams Federation)
**Purpose**: SIP federation over TLS

| Service | Protocol | Priority | Weight | Port | Target | TTL |
|---------|----------|----------|--------|------|--------|-----|
| `_sipfederationtls` | `_tcp` | `100` | `1` | `5061` | `sipfed.online.lync.com` | 3600 |

**Full Record**:
```
_sipfederationtls._tcp.contoso.com SRV 100 1 5061 sipfed.online.lync.com
```

**What it does**:
- Required for federated SIP access
- Enables organization-to-organization federation
- Required for hybrid Skype for Business
- Used for PSTN calling scenarios

### Legacy Skype for Business (Deprecated but may still be present)

#### 3. SIP (Legacy - Non-TLS)
**Status**: Legacy - Use SIP TLS instead

| Service | Protocol | Priority | Weight | Port | Target |
|---------|----------|----------|--------|------|--------|
| `_sip` | `_tcp` | `100` | `1` | `5061` | `sipdir.online.lync.com` |

#### 4. XMPP Federation (Deprecated)
**Status**: ⚠️ **DEPRECATED** - XMPP federation retired

| Service | Protocol | Priority | Weight | Port | Target |
|---------|----------|----------|--------|------|--------|
| `_xmpp-server` | `_tcp` | `5` | `0` | `5269` | `xmpp.messenger.live.com` |

**Note**: XMPP federation was retired by Microsoft.

---

## Records by Service

### Exchange Online (Email)

| Type | Host | Value/Target | Required |
|------|------|--------------|----------|
| **MX** | `@` | `domain.mail.protection.outlook.com` | ✅ Required |
| **CNAME** | `autodiscover` | `autodiscover.outlook.com` | ✅ Required |
| **TXT** | `@` | `v=spf1 include:spf.protection.outlook.com -all` | ✅ Required |
| **TXT** | `_dmarc` | `v=DMARC1; p=quarantine; ...` | ⚠️ Highly Recommended |
| **CNAME** | `selector1._domainkey` | `selector1-domain._domainkey.tenant.onmicrosoft.com` | ⚠️ Highly Recommended |
| **CNAME** | `selector2._domainkey` | `selector2-domain._domainkey.tenant.onmicrosoft.com` | ⚠️ Highly Recommended |
| **TXT** | `default._bimi` | `v=BIMI1; l=https://...` | ⭕ Optional |
| **TXT** | `_mta-sts` | `v=STSv1; id=...` | ⭕ Optional |
| **TXT** | `_smtp._tls` | `v=TLSRPTv1; rua=...` | ⭕ Optional |

### Microsoft Teams

| Type | Host | Value/Target | Required |
|------|------|--------------|----------|
| **CNAME** | `sip` | `sipdir.online.lync.com` | ✅ Required (for federation) |
| **CNAME** | `lyncdiscover` | `webdir.online.lync.com` | ✅ Required (for mobile) |
| **SRV** | `_sip._tls` | `100 1 443 sipdir.online.lync.com` | ✅ Required (for federation) |
| **SRV** | `_sipfederationtls._tcp` | `100 1 5061 sipfed.online.lync.com` | ✅ Required (for federation) |

### Intune / MDM

| Type | Host | Value/Target | Required |
|------|------|--------------|----------|
| **CNAME** | `enterpriseenrollment` | `enterpriseenrollment.manage.microsoft.com` | ✅ Required |
| **CNAME** | `enterpriseregistration` | `enterpriseregistration.windows.net` | ✅ Required |

### SharePoint Online

| Type | Host | Value/Target | Required |
|------|------|--------------|----------|
| **CNAME** | `sharepoint` | `tenant.sharepoint.com` | ⭕ Optional (vanity URL) |
| **CNAME** | `teams` | `tenant.sharepoint.com` | ⭕ Optional (vanity URL) |

### Domain Verification

| Type | Host | Value/Target | Required |
|------|------|--------------|----------|
| **TXT** | `@` or `_domainverify` | `MS=msXXXXXXXX` | ✅ Required (initial setup) |

---

## Regional & Cloud-Specific Records

### Microsoft 365 GCC (Government Community Cloud)

Same as commercial with these exceptions:
- MX: `domain.mail.protection.office365.us`
- All other endpoints same as commercial

### Microsoft 365 GCC High

| Service | Commercial Value | GCC High Value |
|---------|-----------------|----------------|
| **MX** | `domain.mail.protection.outlook.com` | `domain.mail.protection.office365.us` |
| **Autodiscover** | `autodiscover.outlook.com` | `autodiscover.office365.us` |
| **SIP** | `sipdir.online.lync.com` | `sipdir.online.dod.skypeforbusiness.us` |
| **lyncdiscover** | `webdir.online.lync.com` | `webdir.online.dod.skypeforbusiness.us` |
| **SIP SRV** | `sipdir.online.lync.com:443` | `sipdir.online.dod.skypeforbusiness.us:443` |
| **SIP Federation SRV** | `sipfed.online.lync.com:5061` | `sipfed.online.dod.skypeforbusiness.us:5061` |

### Microsoft 365 DoD (Department of Defense)

Same as GCC High:
- MX: `domain.mail.protection.office365.us`
- Autodiscover: `autodiscover.office365.us`
- All Teams/SfB: `.dod.skypeforbusiness.us` endpoints

### Regional Variations (China, Germany - Legacy)

**Microsoft 365 operated by 21Vianet (China)**:
- MX: `domain.mail.protection.partner.outlook.cn`
- Autodiscover: `autodiscover.partner.outlook.cn`

**Microsoft Cloud Germany** (⚠️ DEPRECATED - migrating to European region):
- Legacy endpoints being retired
- Customers migrating to standard European datacenters

---

## Deprecated Records

### Records to Remove

| Record | Host | Status | Action |
|--------|------|--------|--------|
| **CNAME** | `msoid` | ⛔ DEPRECATED | **REMOVE IMMEDIATELY** |
| **SRV** | `_xmpp-server._tcp` | ⛔ DEPRECATED | Remove if present |
| **CNAME** | Legacy SfB on-prem | ⛔ DEPRECATED | Remove after migration |

### MSOID Removal (CRITICAL)

**Why it must be removed**:
- Blocks Microsoft 365 Apps for Enterprise activation
- Incompatible with modern authentication
- No longer used by any Microsoft service
- Causes SSO and authentication failures

**How to check**:
```powershell
Resolve-DnsName msoid.yourdomain.com -Type CNAME
```

**If found**: Remove immediately from your DNS zone.

---

## Optional vs Required

### Absolutely Required (Cannot function without)

✅ **MX Record** - Email delivery fails without it
✅ **Autodiscover CNAME** - Outlook cannot auto-configure
✅ **Domain Verification TXT** - Cannot add domain to tenant

### Highly Recommended (Service degradation without)

⚠️ **SPF TXT** - Email deliverability severely impacted
⚠️ **DKIM CNAMEs** - Email authentication fails
⚠️ **DMARC TXT** - No email protection/reporting
⚠️ **Teams SIP CNAMEs** - Federation fails
⚠️ **Teams SRV Records** - External federation fails
⚠️ **Intune CNAMEs** - Device enrollment fails

### Optional (Enhanced functionality)

⭕ **BIMI** - Branding in email clients
⭕ **MTA-STS** - Enhanced email security
⭕ **TLSRPT** - TLS failure reporting
⭕ **SharePoint vanity CNAMEs** - Custom branding

---

## Advanced Configurations

### Hybrid Exchange

When running hybrid:

1. **Split-brain DNS** (Internal vs External):
   - Internal: Points to on-premises Exchange
   - External: Points to Exchange Online

2. **Dual MX Records**:
   ```
   Priority 0:  mail.contoso.com (On-prem)
   Priority 10: contoso-com.mail.protection.outlook.com (EXO)
   ```

3. **Hybrid Autodiscover**:
   ```
   autodiscover.contoso.com CNAME autodiscover.contoso.mail.onmicrosoft.com
   ```

### Third-Party Email Security Gateway

**Inbound Flow**: Internet → Gateway → Exchange Online

1. **Primary MX** points to security gateway:
   ```
   Priority 0: mail-filter.emailsecurity.com
   ```

2. **Backend MX** points to Exchange Online:
   ```
   Priority 10: contoso-com.mail.protection.outlook.com
   ```

3. **Enhanced Filtering** must be configured in Exchange Online

### Subdomain Configuration

**Per-subdomain records** (e.g., mail.contoso.com):

```
MX:    mail.contoso.com → contoso-com.mail.protection.outlook.com
CNAME: autodiscover.mail.contoso.com → autodiscover.outlook.com
TXT:   mail.contoso.com → v=spf1 include:spf.protection.outlook.com -all
TXT:   _dmarc.mail.contoso.com → v=DMARC1; p=quarantine; ...
```

### Multiple Domains in One Tenant

Each domain needs:
- Separate MX record
- Separate autodiscover CNAME
- Separate SPF TXT
- Separate DMARC TXT
- Separate DKIM CNAMEs (selector1, selector2)
- Separate domain verification TXT

**Teams/SIP records**: Only needed on primary domain or domains requiring federation

---

## Summary Statistics

### Total Record Count by Type

| Record Type | Required | Recommended | Optional | Deprecated | Total |
|-------------|----------|-------------|----------|------------|-------|
| **MX** | 1 | 0 | 0-2 (hybrid) | 0 | 1-3 |
| **CNAME** | 2 | 6 | 3-10 | 1 | 8-19 |
| **TXT** | 1 | 3 | 4 | 0 | 4-8 |
| **SRV** | 0 | 2 | 0 | 2 | 2-4 |
| **TOTAL** | **4** | **11** | **7-16** | **3** | **15-34** |

### Typical Production Deployment

A typical Microsoft 365 deployment with all services enabled:
- **15-20 DNS records** total
- **4 required** for basic email
- **7 additional** for Teams federation
- **2 additional** for Intune/MDM
- **2-4 additional** for DKIM/DMARC
- **0-5 optional** for advanced features

---

## Quick Reference Checklist

### New Domain Setup Checklist

- [ ] **Domain Verification TXT** - `MS=msXXXXXXXX`
- [ ] **MX Record** - `domain.mail.protection.outlook.com`
- [ ] **Autodiscover CNAME** - `autodiscover.outlook.com`
- [ ] **SPF TXT** - `v=spf1 include:spf.protection.outlook.com -all`
- [ ] **DKIM Selector1 CNAME** - Enable in M365 admin center first
- [ ] **DKIM Selector2 CNAME** - Enable in M365 admin center first
- [ ] **DMARC TXT** - `v=DMARC1; p=none; rua=mailto:...`
- [ ] **SIP CNAME** - `sipdir.online.lync.com` (if using Teams federation)
- [ ] **lyncdiscover CNAME** - `webdir.online.lync.com` (if using Teams)
- [ ] **SIP TLS SRV** - `_sip._tls` (if using Teams federation)
- [ ] **SIP Federation TLS SRV** - `_sipfederationtls._tcp` (if using Teams federation)
- [ ] **EnterpriseEnrollment CNAME** - (if using Intune)
- [ ] **EnterpriseRegistration CNAME** - (if using Intune)
- [ ] **Remove MSOID CNAME** - ⚠️ If exists, remove it!

---

## Validation & Testing

### DNS Validation Tools

**Microsoft Tools**:
- Microsoft 365 Admin Center → Domains → Check health
- Microsoft Remote Connectivity Analyzer: https://testconnectivity.microsoft.com

**Third-Party Tools**:
- MXToolbox: https://mxtoolbox.com
- DNS Checker: https://dnschecker.org
- DMARC Analyzer: https://dmarcian.com/dmarc-inspector/
- SPF Record Checker: https://www.kitterman.com/spf/validate.html

### PowerShell Validation

```powershell
# Check MX records
Resolve-DnsName contoso.com -Type MX

# Check CNAME records
Resolve-DnsName autodiscover.contoso.com -Type CNAME
Resolve-DnsName sip.contoso.com -Type CNAME

# Check TXT records
Resolve-DnsName contoso.com -Type TXT
Resolve-DnsName _dmarc.contoso.com -Type TXT

# Check SRV records
Resolve-DnsName _sip._tls.contoso.com -Type SRV
Resolve-DnsName _sipfederationtls._tcp.contoso.com -Type SRV

# Check DKIM
Resolve-DnsName selector1._domainkey.contoso.com -Type CNAME
Resolve-DnsName selector2._domainkey.contoso.com -Type CNAME

# Check for deprecated msoid (should fail)
Resolve-DnsName msoid.contoso.com -Type CNAME
```

---

## Important Notes

1. **DNS Propagation**: Changes can take 15 minutes to 72 hours to propagate globally
2. **TTL Values**: Lower TTL (300-900) during migrations, then raise to 3600+ for stability
3. **DNSSEC**: Fully supported - ensure proper configuration if using DNSSEC
4. **CAA Records**: Not required but recommended for certificate authority authorization
5. **IPv6**: Microsoft 365 fully supports IPv6 (AAAA records not needed for DNS config)
6. **Wildcards**: Not supported for MX, not recommended for CNAMEs
7. **SPF Limit**: Maximum 10 DNS lookups - plan carefully
8. **DMARC Inheritance**: Subdomains inherit parent DMARC policy unless overridden

---

## Version History

- **v1.0** (2025-01-06): Initial comprehensive documentation
- Covers all Microsoft 365 commercial, GCC, GCC High, and DoD DNS records
- Includes deprecated records and migration guidance
- References latest Microsoft 365 DNS requirements as of January 2025

---

**Last Updated**: 2025-01-06
**Author**: DNS4M365 Project
**License**: MIT
