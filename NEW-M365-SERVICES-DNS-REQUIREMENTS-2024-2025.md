# DNS Requirements for NEW Microsoft 365 Services and Features (2024-2025)

**Research Date**: 2025-01-06
**Scope**: DNS requirements for Microsoft 365 services and features launched or updated in 2024-2025

---

## Executive Summary

Microsoft is undergoing a **major DNS domain consolidation** in 2024-2025, transitioning most Microsoft 365 services to the unified **`cloud.microsoft`** domain. This represents the most significant DNS infrastructure change in Microsoft 365 history and affects virtually all new and existing services.

### Critical Actions Required

1. **Add `*.cloud.microsoft` to firewall/proxy allowlists** - Mandatory for all Microsoft 365 services
2. **Ensure WebSocket Secure (WSS) protocol support** - Required for Copilot and modern Microsoft 365 apps
3. **Update to wildcard domain patterns** - Microsoft no longer provides granular FQDN lists due to hyperscale infrastructure
4. **Review IPv6 readiness** - Power Platform and other services now support IPv6 (starting April 2024)

---

## 1. MAJOR CHANGE: cloud.microsoft Domain Consolidation

### Overview

Microsoft announced in 2024 the rollout of `cloud.microsoft` as the **unified DNS domain** for all Microsoft 365 apps and services, consolidating what was previously "hundreds of domains" into a single namespace.

### Timeline

- **Early 2023**: Domain provisioned
- **April 2023**: Added to standard Microsoft network guidance
- **2024**: Active migration began
- **January 2025**: Microsoft 365 app renamed to Microsoft 365 Copilot, moved to m365.cloud.microsoft
- **April 2025**: Migration target completion date
- **September 2025**: Copilot Chat consolidation to m365.cloud.microsoft/chat

### Services Already Migrated to cloud.microsoft

| Service | New URL | Notes |
|---------|---------|-------|
| **Microsoft 365 Copilot** | `m365.cloud.microsoft` | Formerly office.com/microsoft365.com |
| **Microsoft 365 Copilot Chat** | `m365.cloud.microsoft/chat` | Consolidating from copilot.cloud.microsoft |
| **Word** | `*.cloud.microsoft` | Office app migration |
| **Excel** | `*.cloud.microsoft` | Office app migration |
| **PowerPoint** | `*.cloud.microsoft` | Office app migration |
| **Outlook** | `*.cloud.microsoft` | Office app migration |
| **OneNote** | `*.cloud.microsoft` | Office app migration |
| **Microsoft Planner** | `*.cloud.microsoft` | Productivity app migration |
| **Microsoft Loop** | `*.cloud.microsoft` | Collaboration app migration |
| **Microsoft Mesh** | `*.cloud.microsoft` | VR/immersive experiences |
| **Microsoft Clipchamp** | `m365.cloud.microsoft/launch/clipchamp` | Video editor |
| **Viva Engage** | `*.cloud.microsoft` | Employee experience |
| **Viva Insights** | `insights.cloud.microsoft` | Changed from insights.viva.office.com (Feb 2024) |
| **Viva Learning** | `*.cloud.microsoft` | Learning platform |
| **Viva Pulse** | `*.cloud.microsoft` | Employee feedback |

### DNS Records Required

**Primary Wildcard Domain**:
```
Allow: *.cloud.microsoft
Protocol: HTTPS (443)
Note: All HTTP requests automatically upgrade to HTTPS via HSTS preload
```

**Key Characteristics**:
- Uses exclusive `.microsoft` TLD (not .com or .net)
- All subdomains guaranteed to be legitimate Microsoft content only
- No third-party content, IaaS/PaaS, or hosted code allowed under this domain
- Security-enhanced with automatic HTTPS enforcement

### Administrator Actions Required

1. **Update Firewall/Proxy Allowlists**:
   - Add `*.cloud.microsoft` to allow lists
   - Add `*.cloud.microsoft.com` (also used for some services)

2. **Configuration Methods**:
   - **Automatic**: Use Microsoft 365 web service API (recommended)
   - **Manual**: Update endpoint lists per organizational procedures

3. **Backward Compatibility**:
   - Old URLs (office.com, microsoft365.com) redirect automatically
   - No immediate user action required
   - Links to previous domains remain supported

---

## 2. Microsoft Copilot for Microsoft 365

### Overview

Microsoft 365 Copilot is Microsoft's AI assistant integrated across all Microsoft 365 applications, requiring specific network and DNS configurations for proper operation.

### DNS/Domain Requirements

**Required Domains**:
```
*.cloud.microsoft          - Primary Copilot domain
*.office.com              - Core Microsoft 365 functionality
*.office.net              - Microsoft 365 CDN
*.officeapps.live.com     - Office application services
*.online.office.com       - Online Office services
office.live.com           - Office Live services
```

**Copilot-Specific URLs**:
```
m365.cloud.microsoft           - Microsoft 365 Copilot app
m365.cloud.microsoft/chat      - Copilot Chat interface
copilot.cloud.microsoft        - Legacy Copilot (retiring Sep 2025)
```

### Network Protocol Requirements

**WebSocket Secure (WSS) - CRITICAL**:
- Full WSS connectivity is **mandatory** for Copilot functionality
- Common failure mode: Networks blocking WebSocket connections
- Must support WSS to `*.cloud.microsoft` and `*.office.com`

### DNS Records

**Type**: No custom DNS records required
**Action**: Allow domains in firewall/proxy configuration

### Firewall Issues to Avoid

1. **WSS protocol blocking** - Blocks Copilot entirely
2. **TLS inspection interference** - Can break Copilot connections
3. **Aggressive proxy timeouts** - Interrupts Copilot sessions
4. **Selective domain/URL blocking** - Microsoft does NOT support this approach

### Important Notes

- Microsoft cannot provide granular FQDN lists due to hyperscale infrastructure
- Must use wildcard domain patterns (*.cloud.microsoft)
- Network-level restrictions on Copilot are NOT supported by Microsoft
- Refer to "Microsoft 365 URLs and IP address ranges" for complete endpoint list

### Configuration Method

**NOT RECOMMENDED**:
```
❌ Selective domain blocking (unsupported by Microsoft)
❌ Network-protocol filtering for Copilot
❌ Granular IP/URL whitelisting (too dynamic)
```

**RECOMMENDED**:
```
✅ Allow *.cloud.microsoft at firewall level
✅ Ensure WSS protocol support
✅ Use Microsoft 365 web service API for automated updates
✅ Follow Microsoft's standard network guidance
```

---

## 3. Microsoft Viva (All Modules)

### Viva Insights

**Service URL Changes (February 2024)**:
- Old: `https://insights.viva.office.com`
- New: `https://insights.cloud.microsoft`
- Old (Analyst): `https://analysis.insights.viva.office.com`
- New (Analyst): `https://analysis.insights.cloud.microsoft`

**Required URLs (Must Allow)**:
```
login.microsoftonline.com              - Authentication and authorization
api.orginsights.viva.office.com        - Viva Insights API services
*.cloud.microsoft                      - Analytical processing for Viva Insights
substrate.office.com                   - Data processing and integration
graph.microsoft.com                    - Microsoft Graph API for organizational data
```

**Recommended URLs (Optional but Improves Performance)**:
```
webshell.suite.office.com              - Microsoft Office 365 Web Shell
clients.config.office.net              - Office client configuration
res-1.cdn.office.net                   - Content delivery network
ecs.office.com                         - Office 365 cloud services
r4.res.office365.com                   - Resource services
amcdn.msftauth.net                     - Authentication services
config.fp.measure.office.com           - Telemetry and performance
js.monitor.azure.com                   - Azure monitoring
browser.events.data.microsoft.com      - Event data collection
```

### Viva Engage, Viva Learning, Viva Pulse

**Domain Requirements**:
- All migrated to `*.cloud.microsoft` domain
- Use standard Microsoft 365 endpoints
- No separate DNS records required beyond standard M365 configuration

### Viva Connections

**Domain Requirements**:
- Operates on SharePoint Online infrastructure
- Uses standard SharePoint endpoints
- No unique DNS requirements

### Key Notes

- Blocking any Viva Insights endpoint may cause: inability to access service, missing data, degraded performance, or limited features
- Viva services were noted as not fully documented in Microsoft's endpoint web service (acknowledged by Microsoft)
- Organizations should check Microsoft Learn documentation for current endpoint lists

---

## 4. Microsoft Mesh

### Overview

Microsoft Mesh provides immersive 3D experiences and virtual meetings, requiring specific network configurations for VR/AR functionality.

### DNS/Domain Requirements

**Required Domains**:
```
*.cloud.microsoft.com                  - Primary Mesh domain
*.office.com                          - Core Microsoft 365 functionality
*.graph.microsoft.com                 - Microsoft Graph API
*.substrate.office.com                - Data processing and integration
*.microsoft.com                       - General Microsoft services
```

### Firewall Ports

```
TCP 443 (HTTPS)                       - Primary protocol
TCP 80 (HTTP)                         - HTTP connections
```

### Network Endpoint Configuration

**Primary Requirements**:
1. **Microsoft 365 requirements** - Configure firewall for Microsoft Teams and Microsoft 365 Common endpoints
2. **Azure Communication Services** - Additional requirements for media capabilities (audio, video, screenshare)

**Reference Documentation**:
- Microsoft 365 URLs and IP address ranges
- Firewall configuration for Azure Communication Services

### Content Access Requirements

**For Embedded Content (Videos, Images, WebSlates)**:
- SharePoint-hosted content follows M365 access permissions
- External URLs require firewall allowlisting on TCP 443
- Content blocked in browsers will also be blocked in Mesh

### 2024 Infrastructure Simplification

**July 2024 Update**:
- Multi-room events transitioned to same backend as Teams for spatial audio
- Resulted in improved audio quality
- Simplified URL/port requirements
- Reduced number of endpoints needed

### Critical Note

"Without access to these [endpoints], Mesh won't work properly for users in your organization."

---

## 5. Microsoft Purview

### Overview

Microsoft Purview provides data governance, compliance, and protection capabilities with complex network and DNS requirements, especially for private endpoint scenarios.

### DNS Requirements for Private Endpoints

**Private DNS Zones Required**:

**Classic Microsoft Purview Governance Portal**:
```
privatelink.purview.azure.com          - Account endpoints
privatelink.purviewstudio.azure.com    - Portal endpoints
```

**New Microsoft Purview Portal**:
```
privatelink.purview-service.microsoft.com   - Service endpoints
```

**Ingestion Endpoints**:
```
privatelink.blob.core.windows.net      - Blob storage
privatelink.queue.core.windows.net     - Queue storage
privatelink.servicebus.windows.net     - Event Hubs (if configured)
```

### DNS Name Resolution Requirements

**Critical Requirement**: Accurate name resolution is mandatory when using private endpoints.

**FQDN Resolution**: Clients must resolve Purview FQDNs to private endpoint IP addresses.

**DNS Configuration**:
- Custom DNS servers must be able to resolve `privatelink.*` domains
- Private DNS zones created automatically with private endpoint provisioning
- DNS zones can be centralized in hub/data management subscription (recommended)

### Network Requirements for Self-Hosted Integration Runtime (SHIR)

**Required Domains and Ports**:
```
*.servicebus.windows.net               - Azure Relay communication (CRITICAL)
download.microsoft.com                 - Auto-update (if enabled)
wu2.frontend.clouddatahub.net          - Integration runtime communication
```

**Port Requirements**:
```
Port 443                               - All Microsoft Purview communication
```

### Key Recommendations

1. **Do NOT use static IP addresses** - Azure resource IPs are dynamic
2. **Centralize DNS zones** - Hub subscription for all private endpoint DNS
3. **View Service URLs** - Available in Purview portal → Data Map → Integration runtimes → edit SHIR → Nodes → "View Service URLs"

### Important Notes

- Endpoint lists vary based on Purview account creation date (before/after Dec 15, 2023)
- Managed Event Hubs vs Kafka notifications affect required endpoints
- Microsoft Purview is primarily an Azure service but integrates with Microsoft 365 compliance

---

## 6. Microsoft Priva

### Overview

Microsoft Priva provides privacy management within Microsoft 365, helping organizations manage personal data and meet privacy regulations.

### DNS Requirements

**Key Finding**: No separate DNS requirements found for Microsoft Priva.

**Reason**: Microsoft Priva:
- Built on Microsoft 365 infrastructure
- Works with Microsoft 365 data (Exchange Online, SharePoint, OneDrive, Teams)
- Integrated into Microsoft Purview compliance portal
- Enabled at tenant level without separate network configuration

### Network Configuration

**Uses Standard Microsoft 365 Endpoints**:
- Same endpoints as Microsoft 365 core services
- Same endpoints as Microsoft Purview compliance features
- No dedicated Priva-specific domains or DNS records

### Recommendation

Organizations should ensure:
1. Standard Microsoft 365 URLs and IP ranges are allowed
2. Microsoft Purview endpoint requirements are met
3. Compliance portal access is configured

**Reference Documentation**: Microsoft 365 URLs and IP address ranges

---

## 7. Microsoft Syntex

### Overview

Microsoft Syntex is an AI-powered content intelligence service that automates content processing, classification, and management within Microsoft 365.

### DNS Requirements

**Key Finding**: No separate DNS requirements for Microsoft Syntex.

**Reason**: Microsoft Syntex:
- Operates as add-on service to SharePoint Online
- Leverages Azure AI services
- Integrated with Power Platform (AI Builder)
- Uses Purview for compliance and security
- Built on existing Microsoft 365 infrastructure

### Network Configuration

**Underlying Service Dependencies**:
Since Syntex uses multiple Microsoft 365 services, organizations should ensure access to:

1. **SharePoint Online endpoints** - Content storage and management
2. **Azure service endpoints** - AI Builder and cognitive services
3. **Power Platform endpoints** - Form processing models
4. **Microsoft 365 CDN** - Content delivery

### Recommendation

Allow standard endpoint categories:
- Microsoft 365 URLs and IP address ranges (SharePoint section)
- Power Platform URLs and IP address ranges
- Azure service endpoints (if applicable)

**No custom DNS records required** - All functionality provided through existing infrastructure

---

## 8. Microsoft Bookings

### Overview

Microsoft Bookings provides appointment scheduling functionality within Microsoft 365, now with enhanced custom domain support.

### Custom Domain Support

**Feature Introduced**: Custom domain support announced in 2023-2024 for Bookings

**Default Domain Format**:
```
@<tenant>.onmicrosoft.com             - Default Bookings domain
```

**Custom Domain Configuration**:
- Bookings can now use organization's verified custom domain
- Configured via OWA (Outlook Web Access) mailbox policy
- Highly recommended to avoid emails landing in spam/junk folders

### DNS Requirements

**Standard Email DNS Records**:
Since Bookings sends emails and creates mailboxes, standard Exchange Online DNS records are required:

```
MX Record:      <domain>.mail.protection.outlook.com
CNAME:          autodiscover → autodiscover.outlook.com
TXT (SPF):      v=spf1 include:spf.protection.outlook.com -all
CNAME (DKIM):   selector1._domainkey → selector1-<domain>._domainkey.<tenant>.onmicrosoft.com
CNAME (DKIM):   selector2._domainkey → selector2-<domain>._domainkey.<tenant>.onmicrosoft.com
TXT (DMARC):    _dmarc → v=DMARC1; p=quarantine; ...
```

### Network Endpoints

**Uses Standard Microsoft 365 Endpoints**:
- No Bookings-specific DNS records
- No unique network endpoints
- Operates on Exchange Online and Microsoft 365 infrastructure

### Best Practices

1. **Configure custom domain** - Prevents emails going to spam
2. **Enable DKIM signing** - Improves email deliverability
3. **Configure DMARC** - Required for email security
4. **Update OWA mailbox policy** - To specify which domain to use

### Important Note

Microsoft is limiting `*.onmicrosoft.com` domain usage for sending emails, making custom domain configuration increasingly important for Bookings.

---

## 9. Microsoft Lists

### Overview

Microsoft Lists is a collaboration app for tracking information and organizing work within Microsoft 365.

### DNS Requirements

**Key Finding**: No separate custom domain DNS requirements for Microsoft Lists.

**Reason**: Microsoft Lists:
- Built on SharePoint Online infrastructure
- Uses SharePoint URLs and endpoints
- No custom domain feature for Lists URLs
- Lists accessed via SharePoint sites or Teams

### Network Configuration

**Uses SharePoint Online Endpoints**:
```
*.sharepoint.com                      - SharePoint Online domains
<tenant>.sharepoint.com               - Tenant-specific SharePoint
```

### Custom Domain for Microsoft 365

If using custom domain for Microsoft 365 tenant:

**Standard DNS Records Required**:
```
TXT:     @ → MS=msXXXXXXXX           - Domain verification
MX:      @ → <domain>.mail.protection.outlook.com
CNAME:   autodiscover → autodiscover.outlook.com
TXT:     @ → v=spf1 include:spf.protection.outlook.com -all
SRV:     _sip._tls → sipdir.online.lync.com
```

### SharePoint Vanity URL (Optional)

**Custom SharePoint CNAME**:
```
CNAME:   sharepoint → <tenant>.sharepoint.com
```

**Note**: Microsoft Lists URLs follow SharePoint URL structure and cannot be independently customized with DNS records.

---

## 10. Microsoft Forms

### Overview

Microsoft Forms provides survey and form creation capabilities within Microsoft 365.

### Custom Domain Support

**Key Finding**: Microsoft Forms does **NOT** support custom domains natively.

**Current Behavior**:
- Forms always use `forms.office.com` or `forms.microsoft.com` domain
- No DNS configuration available to change Forms URLs
- Built-in feature only shortens URLs (does not customize domain)

### Alternatives and Workarounds

**1. URL Redirection Method**:
```
Setup: Configure web server or URL shortener
Example: forms.contoso.com → https://forms.office.com/r/xyz123
Method: HTTP 301/302 redirect
DNS Record: CNAME: forms → web-server-hosting-redirect
```

**2. Dynamics 365 Customer Voice**:
- Previously "Forms Pro"
- Enterprise forms solution
- **Does support** customized links
- Requires Dynamics 365 license
- Separate product from Microsoft Forms

### DNS Requirements

**For Microsoft Forms itself**: No custom DNS records possible

**For Microsoft 365 Custom Domain** (general):
```
TXT:     @ → MS=msXXXXXXXX           - Tenant domain verification
MX:      @ → <domain>.mail.protection.outlook.com (for notifications)
TXT:     @ → v=spf1 include:spf.protection.outlook.com -all
```

### Network Endpoints

**Forms URLs**:
```
forms.office.com                      - Primary Forms domain
forms.microsoft.com                   - Alternative Forms domain
*.office.com                         - Microsoft 365 services
```

**Protocol**: HTTPS (443)

### Important Note

Custom domains for Forms is a frequently requested feature but not available as of 2024-2025. Organizations needing custom domains must use URL redirection workarounds or consider Dynamics 365 Customer Voice.

---

## 11. Power Platform (Power Apps, Power Automate)

### Overview

Power Platform services have undergone significant endpoint updates in 2024, including new domains and IPv6 support.

### Major Changes in 2024

**New Endpoint (February 2024)**:
```
*.content.powerplatform.com           - New Power Platform API endpoint
```

**IPv6 Support (April 2024)**:
- Selective Power Platform endpoints now resolve to IPv4 and IPv6
- Goal: Enable IPv6 on all Power Platform and Dynamics 365 endpoints
- Organizations must ensure network infrastructure supports IPv6

### Essential Consolidated Domains (2024-2025)

**Primary Three Domains - REQUIRED**:

| Domain | Purpose | Ports |
|--------|---------|-------|
| `*.cloud.microsoft.com` | Authenticated Microsoft SaaS product experiences | TCP/UDP 443 |
| `*.static.microsoft.com` | Static content on CDN | TCP/UDP 443 |
| `*.usercontent.microsoft.com` | User-generated content requiring isolation | TCP/UDP 443 |

### Service-Specific Endpoints

**Authentication Endpoints**:
```
login.microsoftonline-p.com           - B2C and guest scenarios
login.live.com                        - Consumer authentication
auth.gfx.ms                          - Authentication services
*.windows.net                        - Azure services
*.passport.net                       - Microsoft account services
```

**Power Platform API Endpoints**:
```
*.crm#.dynamics.com                  - Regional Dynamics (# = region number)
*.api.powerplatform.com              - Power Platform API
*.powerplatform.com                  - Power Platform services
*.api.powerplatformusercontent.com   - API user content
*.powerplatformusercontent.com       - User content
```

**Power Apps & Power Automate**:
```
*.content.powerplatform.com          - New 2024 endpoint
*.powerapps.com                      - Power Apps services
*.flow.microsoft.com                 - Power Automate services
*.powerbi.com                        - Power BI integration
```

### Support and Infrastructure Endpoints

```
go.microsoft.com                     - Documentation
urs.microsoft.com                    - Defender SmartScreen
crl.microsoft.com                    - Certificate revocation
download.microsoft.com               - Software downloads
```

### IP Address Service Tags

**Required Azure Service Tags**:
```
AzureCloud                           - All Power Platform and Dynamics 365 services
AzureSignalR                         - Real-time communication
MicrosoftAzureFluidRelay             - Real-time collaboration features
OneDsCollector                       - Telemetry gathering
PowerPlatformPlex                    - Power Platform infrastructure
AzureConnectors                      - Logic Apps connectors (Power Automate)
```

**Download Location**: Azure service tag JSON files updated monthly

### Port Requirements

**Standard Ports**:
```
TCP/UDP 443                          - HTTPS (primary)
TCP 1433                             - Dataverse Tabular Data Stream
TCP 5558                             - Dataverse Tabular Data Stream
```

### DNS Records

**Type**: No custom DNS records required
**Action**: Allow domains in firewall/proxy configuration

### Critical 2024 Update

Organizations must allowlist `*.powerplatform.com` to prevent service interruptions. Failure to allowlist this domain may cause connectivity issues depending on firewall configuration.

### Documentation References

**Official Endpoints**: https://learn.microsoft.com/en-us/power-platform/admin/online-requirements

**Service-Specific**:
- Power Apps: Public and Government cloud URLs
- Power Automate: `/power-automate/ip-address-configuration`
- Power BI: Public and Government cloud URLs
- Power Pages: Public and Government cloud URLs
- Microsoft Copilot Studio: Public and Government cloud URLs

---

## 12. Microsoft Clipchamp

### Overview

Microsoft Clipchamp is the video editing tool integrated into Microsoft 365, transitioning to the unified cloud.microsoft domain in 2024.

### Domain Migration (2024)

**New URL (2024)**:
```
m365.cloud.microsoft/launch/clipchamp - Work/school accounts
```

**Previous URLs** (redirecting):
```
https://m365.cloud.microsoft/launch/Clipchamp/   - Old path
https://m365.cloud.microsoft/launch/stream        - Old unified page
```

**Personal Account URL** (unchanged):
```
https://app.clipchamp.com                        - Personal Clipchamp
```

### DNS/Domain Requirements

**Required Domains**:
```
*.cloud.microsoft                    - Primary Clipchamp domain for M365
m365.cloud.microsoft                 - Microsoft 365 app launcher
app.clipchamp.com                    - Personal accounts (if used)
api.clipchamp.com                    - API services (in some firewall configs)
```

### Network Endpoints

**Protocol**: HTTPS (443)

**Browser Requirements**:
- Microsoft Edge (recommended)
- Google Chrome

### Microsoft Stream and Clipchamp Unification (2024)

**Brand Unification Update**:
- Stream and Clipchamp consolidating into unified video hub
- Both redirect to same experience at `m365.cloud.microsoft`
- Simplified video management across Microsoft 365

### Firewall Configuration

**Required Actions**:
1. Ensure `*.cloud.microsoft` is not blocked
2. Allow connections from client networks and enterprise networks
3. No special DNS records needed - operates on standard M365 infrastructure

### Administrator Guidance

**Automatic Configuration**:
- Customers using Microsoft 365 web service API have had cloud.microsoft in configuration since 2023
- Manual endpoint management requires adding `*.cloud.microsoft`

**Control Options**:
- Administrators can enable/disable Clipchamp for users via admin center
- Administrative controls available for Microsoft 365 commercial accounts

### Key Notes

- Clipchamp requires internet connection to function
- Browser-based application, no local installation DNS needs
- Part of Microsoft 365 domain consolidation initiative
- No separate DNS records required

---

## 13. Microsoft Designer

### Overview

Microsoft Designer is an AI-powered graphic design tool integrated into Microsoft 365 ecosystem.

### DNS Requirements

**Key Finding**: No dedicated DNS endpoint documentation found for Microsoft Designer.

**Reason**:
- Microsoft Designer is web-based service
- Deeply integrated with Microsoft 365 ecosystem
- Uses standard Microsoft 365 and AI service infrastructure
- Likely part of `*.cloud.microsoft` domain migration

### Expected Network Requirements

Based on Microsoft 365 and Copilot infrastructure:

**Likely Required Domains**:
```
*.cloud.microsoft                    - Microsoft 365 unified domain
*.office.com                        - Office services
*.microsoft.com                     - General Microsoft services
designer.microsoft.com              - Possible Designer-specific URL
```

### Network Endpoints

**Protocol**: HTTPS (443)

**Integration Points**:
- Microsoft 365 authentication endpoints
- AI/Copilot service endpoints
- Image generation and processing services

### DNS Records

**Type**: No custom DNS records required
**Action**: Ensure standard Microsoft 365 endpoints are allowed

### Recommendation

Since Microsoft Designer is part of Microsoft 365's Copilot and AI initiatives:

1. **Allow standard M365 endpoints** - Designer operates on M365 infrastructure
2. **Include Copilot endpoints** - Designer uses AI capabilities
3. **Refer to official documentation** - Check Microsoft 365 URLs and IP address ranges

**Official Documentation**: https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges

### Important Note

No separate DNS configuration appears necessary as Designer is integrated into the broader Microsoft 365 platform. Organizations with standard M365 connectivity should have Designer access automatically.

---

## 14. Microsoft 365 Backup

### Overview

Microsoft 365 Backup is Microsoft's native backup service for OneDrive, SharePoint, and Exchange Online, announced in 2024.

### Network Architecture

**Data Boundary**:
- Backup data remains within Microsoft 365 data trust boundary
- Honors geographic data residency of current data
- Limited metadata (tenantID, siteIDs) sent to Azure for billing only

**Infrastructure**:
- Built on standard OneDrive, SharePoint, and Exchange Online infrastructure
- Creates backups within protected services' data boundaries
- Ultra-fast backup and restore capabilities

### DNS Requirements

**Key Finding**: No separate DNS requirements found for Microsoft 365 Backup.

**Reason**:
- Operates within Microsoft 365 data boundary
- Uses standard Microsoft 365 network endpoints
- No additional DNS configuration needed beyond standard M365 setup

### Network Endpoints

**Expected Endpoints**:
Since Microsoft 365 Backup operates on M365 infrastructure:

```
*.cloud.microsoft                    - Microsoft 365 unified domain
*.sharepoint.com                    - SharePoint Online
*.outlook.com                       - Exchange Online
*.onedrive.com                      - OneDrive for Business
```

**Azure Billing Endpoints** (minimal metadata only):
```
*.azure.com                         - Billing information
```

### DNS Records

**Type**: No custom DNS records required
**Action**: Standard Microsoft 365 DNS configuration sufficient

### Firewall Configuration

Organizations should ensure:

1. **Standard M365 endpoints allowed** - Backup uses existing infrastructure
2. **Microsoft 365 web service API** - For automated endpoint management
3. **Microsoft 365 IP Address and URL Web service** - Third-party products integrate with this

### Documentation References

**Microsoft 365 Backup Overview**: https://learn.microsoft.com/en-us/microsoft-365/backup/

**Endpoint Management**: https://learn.microsoft.com/en-us/microsoft-365/enterprise/managing-office-365-endpoints

### Important Notes

- Service is relatively new (2024 launch)
- DNS/endpoint documentation integrated with general M365 requirements
- No additional network configuration beyond standard M365 setup
- Third-party network perimeter products can integrate with M365 IP/URL web service

---

## Summary of DNS Requirements by Service

| Service | Custom DNS Records | Required Domains | Notes |
|---------|-------------------|------------------|-------|
| **Microsoft 365 Copilot** | None | `*.cloud.microsoft`, `*.office.com` | Requires WSS protocol support |
| **Viva Insights** | None | `*.cloud.microsoft`, `api.orginsights.viva.office.com` | URL changed Feb 2024 |
| **Viva Engage/Learning/Pulse** | None | `*.cloud.microsoft` | Standard M365 endpoints |
| **Microsoft Mesh** | None | `*.cloud.microsoft.com`, `*.office.com`, `*.graph.microsoft.com` | Requires Azure Communication Services |
| **Microsoft Purview** | Private DNS zones | `privatelink.purview.azure.com`, `privatelink.purview-service.microsoft.com` | Complex private endpoint setup |
| **Microsoft Priva** | None | Standard M365 endpoints | No separate requirements |
| **Microsoft Syntex** | None | Standard M365 + SharePoint endpoints | Built on existing infrastructure |
| **Microsoft Bookings** | Standard M365 email | MX, CNAME (autodiscover), TXT (SPF, DKIM, DMARC) | Custom domain support added |
| **Microsoft Lists** | None | SharePoint endpoints | No custom domain feature |
| **Microsoft Forms** | None (no custom domain support) | `forms.office.com`, `forms.microsoft.com` | Custom domains not available |
| **Power Platform** | None | `*.cloud.microsoft.com`, `*.powerplatform.com`, `*.content.powerplatform.com` | Major 2024 updates, IPv6 support |
| **Microsoft Clipchamp** | None | `m365.cloud.microsoft`, `app.clipchamp.com` | Migrated to cloud.microsoft |
| **Microsoft Designer** | None | `*.cloud.microsoft`, `*.office.com` | Part of M365 infrastructure |
| **Microsoft 365 Backup** | None | Standard M365 endpoints | No separate requirements |

---

## Critical DNS Changes for 2024-2025

### 1. Universal *.cloud.microsoft Requirement

**Action Required**: Add to all firewall/proxy allowlists

```
Domain: *.cloud.microsoft
Port: 443 (HTTPS)
Protocol: HTTPS only (automatic HSTS upgrade)
```

**Affects**: All Microsoft 365 services, including traditional and new services

### 2. WebSocket Secure (WSS) Protocol

**Action Required**: Ensure WSS protocol is not blocked

```
Protocol: wss://
Ports: 443
Critical for: Microsoft 365 Copilot, modern M365 apps
```

### 3. IPv6 Support

**Action Required**: Verify network IPv6 readiness (starting April 2024)

```
Affects: Power Platform, Dynamics 365, eventually all M365 services
Testing: Ensure dual-stack (IPv4 + IPv6) configuration works
```

### 4. Power Platform New Endpoint

**Action Required**: Add new endpoint to allowlists (February 2024)

```
Domain: *.content.powerplatform.com
Port: 443
Purpose: Power Platform API service dependency
```

### 5. Viva Insights URL Change

**Action Required**: Update bookmarks and allowlists

```
Old: insights.viva.office.com
New: insights.cloud.microsoft
Changed: February 2024
```

### 6. Wildcard Pattern Migration

**Action Required**: Replace granular FQDNs with wildcard patterns

```
Old approach: Specific FQDN lists (unsupported)
New approach: *.cloud.microsoft, *.office.com (required)
Reason: Microsoft hyperscale infrastructure too dynamic for static lists
```

---

## Configuration Methods

### Automatic Configuration (Recommended)

**Microsoft 365 Web Service API**:
```
Endpoint: https://endpoints.office.com/
Methods: /version, /endpoints/worldwide
Format: JSON
Update: Monthly (30 days advance notice)
```

**Benefits**:
- Automatic updates to endpoint changes
- Includes cloud.microsoft domains since 2023
- Third-party firewall/proxy products integrate automatically
- No manual tracking required

### Manual Configuration

**Required Actions**:
1. Subscribe to Microsoft 365 Message Center updates
2. Monitor monthly endpoint changes
3. Update firewall/proxy rules manually
4. Test connectivity after changes

**Key Domains to Add Manually**:
```
*.cloud.microsoft
*.cloud.microsoft.com
*.static.microsoft.com
*.usercontent.microsoft.com
*.office.com
*.office.net
*.powerplatform.com
*.content.powerplatform.com
```

---

## Testing and Validation

### Connectivity Testing

**PowerShell Test**:
```powershell
# Test cloud.microsoft connectivity
Test-NetConnection -ComputerName m365.cloud.microsoft -Port 443

# Test WSS support (requires custom script)
# WebSocket testing tools needed for WSS verification
```

**Browser Testing**:
```
1. Navigate to https://m365.cloud.microsoft
2. Verify successful connection
3. Test Microsoft 365 Copilot access
4. Verify no TLS/certificate errors
```

### Firewall Log Analysis

**What to Check**:
- No blocks on `*.cloud.microsoft` domains
- WSS protocol connections succeeding
- No TLS inspection breaking connections
- No aggressive timeout disconnections

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| **WSS blocking** | Copilot fails to load | Enable WSS protocol |
| **Domain blocking** | M365 apps fail | Allow `*.cloud.microsoft` |
| **TLS inspection** | Certificate errors | Exclude M365 domains from inspection |
| **IPv6 issues** | Power Platform failures | Enable IPv6 support |
| **Timeout issues** | Copilot disconnects | Increase proxy timeouts |

---

## Migration Timeline

### 2023
- **Early 2023**: cloud.microsoft domain provisioned
- **April 2023**: cloud.microsoft added to Microsoft network guidance

### 2024
- **February 2024**: Viva Insights URL migration, Power Platform new endpoint
- **April 2024**: IPv6 support begins for Power Platform
- **June 2024**: Active migration of products to cloud.microsoft
- **July 2024**: Mesh audio infrastructure simplified

### 2025
- **January 2025**: Microsoft 365 app renamed to Microsoft 365 Copilot
- **April 2025**: Target completion for cloud.microsoft migration
- **July 2025**: DNS provisioning changes for new domains (mx.microsoft subdomain)
- **September 2025**: Copilot Chat consolidation to m365.cloud.microsoft/chat

---

## Recommendations for Administrators

### Immediate Actions (High Priority)

1. ✅ **Add `*.cloud.microsoft` to firewall allowlists**
   - Critical for all Microsoft 365 services
   - Required for Copilot, Viva, Mesh, Clipchamp, and more

2. ✅ **Verify WSS protocol support**
   - Test WebSocket connections
   - Critical for Copilot functionality

3. ✅ **Review TLS inspection policies**
   - Exclude Microsoft 365 domains from deep inspection
   - Prevents certificate and connection issues

4. ✅ **Update to wildcard domain patterns**
   - Replace specific FQDN lists with `*.cloud.microsoft`
   - Microsoft no longer supports granular endpoint lists

### Medium Priority

5. ⚠️ **Implement Microsoft 365 Web Service API**
   - Automate endpoint updates
   - Reduce manual maintenance

6. ⚠️ **Test IPv6 connectivity**
   - Prepare for full IPv6 rollout
   - Test Power Platform access with IPv6

7. ⚠️ **Update Viva Insights bookmarks**
   - Change from viva.office.com to cloud.microsoft
   - Communicate to users

8. ⚠️ **Configure custom domain for Bookings**
   - Improve email deliverability
   - Avoid spam folder issues

### Long-Term Planning

9. 📋 **Monitor Microsoft 365 Message Center**
   - Subscribe to endpoint change notifications
   - Plan for future migrations

10. 📋 **Document network requirements**
    - Maintain list of required domains
    - Share with network/security teams

11. 📋 **Plan for DNSSEC adoption**
    - Microsoft moving to mx.microsoft subdomain for DNSSEC readiness (July 2025)
    - Long-term DNS infrastructure improvement

---

## Additional Resources

### Official Microsoft Documentation

**Primary Endpoint Reference**:
- Microsoft 365 URLs and IP address ranges: https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges

**cloud.microsoft Domain**:
- Unified cloud.microsoft domain: https://learn.microsoft.com/en-us/microsoft-365/enterprise/cloud-microsoft-domain

**Service-Specific**:
- Microsoft 365 Copilot requirements: https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-requirements
- Power Platform endpoints: https://learn.microsoft.com/en-us/power-platform/admin/online-requirements
- Viva Insights allowlist: https://learn.microsoft.com/en-us/viva/insights/advanced/reference/allowlist-urls
- Microsoft Mesh preparation: https://learn.microsoft.com/en-us/mesh/setup/content/preparing-your-organization

**Web Service API**:
- Microsoft 365 IP Address and URL web service: https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service

### Endpoint Web Service

**Version Check**:
```
https://endpoints.office.com/version
```

**Worldwide Endpoints**:
```
https://endpoints.office.com/endpoints/worldwide
```

**GCC Endpoints**:
```
https://endpoints.office.com/endpoints/USGOVGCCHigh
```

---

## Conclusion

The 2024-2025 period represents the most significant DNS infrastructure change in Microsoft 365 history with the consolidation to the `cloud.microsoft` domain. Organizations must:

1. **Immediately add `*.cloud.microsoft`** to firewall allowlists
2. **Ensure WebSocket Secure (WSS) protocol support** for Copilot and modern apps
3. **Migrate from granular FQDN lists to wildcard patterns** for dynamic infrastructure
4. **Prepare for IPv6** as Microsoft enables dual-stack across services
5. **Implement automated endpoint management** using Microsoft's web service API

Most new Microsoft 365 services (Copilot, Viva, Mesh, Clipchamp, Designer, etc.) **do not require custom DNS records** but instead rely on proper network connectivity to Microsoft's consolidated domains.

The emphasis has shifted from DNS record management to **network allowlist management** with wildcard domain patterns being the only supported approach for Microsoft's hyperscale infrastructure.

---

**Last Updated**: 2025-01-06
**Research Version**: 1.0
**Coverage**: All major Microsoft 365 services launched or updated 2024-2025
