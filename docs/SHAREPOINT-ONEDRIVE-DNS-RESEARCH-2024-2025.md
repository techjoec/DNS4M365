# SharePoint Online and OneDrive DNS Requirements Research (2024-2025)

**Research Date**: November 6, 2025
**Sources**: Official Microsoft Learn Documentation, Microsoft Community Hub, Microsoft 365 Admin Center

---

## Executive Summary

This comprehensive research document covers the latest SharePoint Online and OneDrive DNS requirements, network endpoints, and related service configurations for 2024-2025. Based on official Microsoft documentation, this report addresses vanity URLs, custom domains, hybrid configurations, external sharing, Viva services, and deprecated records.

### Key Findings

1. **SharePoint Vanity URLs**: Not natively supported; workarounds required
2. **OneDrive Custom Domains**: Limited support; primarily for domain renaming
3. **No New CNAME Records**: No new SharePoint-specific CNAME records announced for 2024-2025
4. **Viva Services**: Leverage existing Microsoft 365 infrastructure
5. **Loop Integration**: Requires WebSocket support for real-time collaboration
6. **Deprecated Records**: msoid CNAME deprecated for most environments (except 21Vianet)

---

## Table of Contents

1. [SharePoint Vanity URL DNS Requirements](#1-sharepoint-vanity-url-dns-requirements)
2. [OneDrive Custom Domain DNS Requirements](#2-onedrive-custom-domain-dns-requirements)
3. [SharePoint Hybrid DNS Requirements](#3-sharepoint-hybrid-dns-requirements)
4. [SharePoint External Sharing DNS Requirements](#4-sharepoint-external-sharing-dns-requirements)
5. [Viva Engage (Yammer) DNS Requirements](#5-viva-engage-yammer-dns-requirements)
6. [Viva Connections DNS Requirements](#6-viva-connections-dns-requirements)
7. [Microsoft Loop DNS Requirements](#7-microsoft-loop-dns-requirements)
8. [SharePoint Online Core DNS Endpoints](#8-sharepoint-online-core-dns-endpoints)
9. [OneDrive Core DNS Endpoints](#9-onedrive-core-dns-endpoints)
10. [SharePoint CDN Endpoints](#10-sharepoint-cdn-endpoints)
11. [SharePoint Advanced Management](#11-sharepoint-advanced-management)
12. [SharePoint Embedded](#12-sharepoint-embedded)
13. [Deprecated SharePoint DNS Records](#13-deprecated-sharepoint-dns-records)
14. [Microsoft 365 Endpoint Web Service](#14-microsoft-365-endpoint-web-service)
15. [Best Practices and Recommendations](#15-best-practices-and-recommendations)

---

## 1. SharePoint Vanity URL DNS Requirements

### Current Status (2024-2025)

**SharePoint Online does NOT natively support vanity URLs or custom CNAME records for site collections.**

### Technical Limitations

- **Architectural Constraint**: All SharePoint Online sites must operate under a single hostname (`https://tenant.sharepoint.com`)
- **No CNAME Support**: Cannot add CNAME records to point custom domains to internal SharePoint Online sites
- **OneDrive Exception**: OneDrive for Business has limited custom domain support through domain renaming

### Workarounds

Organizations requiring vanity URLs typically use:

1. **Azure Front Door**: DNS entry points to Azure Front Door, which proxies requests to SharePoint
   - **Limitation**: SharePoint URL typically appears in the address bar rather than preserving the custom domain

2. **Reverse Proxy Solutions**: Third-party reverse proxy services
   - **Limitation**: Complex configuration, may break certain SharePoint functionality

3. **Public Sites (Deprecated)**: Historical support for custom domains on public-facing SharePoint sites
   - **Status**: This feature has been deprecated and is no longer available for new sites

### Official Microsoft Guidance

- Vanity URLs are not recommended or officially supported for SharePoint Online internal sites
- Domain renaming is available for the base SharePoint domain (limited to tenants with <10,000 sites)

---

## 2. OneDrive Custom Domain DNS Requirements

### SharePoint Domain Rename Feature

**Available for**: Organizations with fewer than 10,000 total sites (SharePoint sites + OneDrive accounts + SharePoint Embedded containers)

**Advanced Tenant Rename**: Available with SharePoint Advanced Management for any number of sites

### Requirements

1. **Domain Verification**: Target domain must be verified in Microsoft 365 using TXT records
   - **TXT Record**: `@` host with Microsoft-provided verification string
   - **Verification Time**: Up to 48 hours (typically 10 minutes)

2. **Domain Addition**: Domain must be in the verified domains list before initiating rename

3. **What Changes**:
   - SharePoint and OneDrive URLs
   - **Does NOT change**: Email addresses

### DNS Configuration Notes

- No custom CNAME records required for OneDrive custom domains
- Standard Microsoft 365 domain verification process applies
- Domain must not be configured for "full redelegation" to function properly

### Limitations

- Cannot use custom domains for individual OneDrive users or specific sites
- Domain rename affects the entire tenant's SharePoint and OneDrive infrastructure

---

## 3. SharePoint Hybrid DNS Requirements

### Overview

SharePoint Hybrid allows integration between SharePoint Server (on-premises) and SharePoint Online.

### DNS Requirements

#### 1. Split DNS Configuration

**Requirement**: On-premises DNS server must be configured with split DNS

**Configuration**:
- Create a forward lookup zone for the public Internet domain used for your public URL
- Create an A record in the forward lookup zone with:
  - **Host**: External URL hostname
  - **IP Address**: SharePoint Server external endpoint

#### 2. Public DNS Records

**Requirements**:
- **Public Domain**: Registered with a domain registrar (e.g., GoDaddy)
- **A Record**: In public DNS zone
  - **Host**: External URL hostname
  - **IP Address**: External endpoint of reverse proxy device
  - **Purpose**: Associates published SharePoint in Microsoft 365 site

#### 3. On-Premises DNS Records

**Configuration**:
- **A Record**: Maps external URL hostname to on-premises SharePoint farm
  - **Host**: External URL hostname
  - **IP Address**: Internal SharePoint farm IP address

#### 4. Reverse Proxy Requirements

**Network Configuration**:
- **Internet Domain**: Required (e.g., `https://adventureworks.com`)
- **Permissions**: Ability to create or edit DNS records for the domain
- **Ports**: Only TCP 443 required on external reverse proxy endpoint
- **Purpose**: Supports hybrid connectivity between on-premises and cloud

### Example Configuration

```
Public DNS (at domain registrar):
  Type: A
  Host: sharepoint
  Value: 203.0.113.10 (reverse proxy external IP)

Internal DNS (on-premises):
  Type: A
  Host: sharepoint
  Value: 10.0.1.50 (SharePoint Server internal IP)

Forward Lookup Zone:
  Zone: adventureworks.com
  Record: sharepoint.adventureworks.com → 10.0.1.50
```

---

## 4. SharePoint External Sharing DNS Requirements

### Overview

SharePoint external sharing and B2B collaboration do not require specific DNS records beyond standard Microsoft 365 configuration.

### Configuration Requirements

External sharing is managed through **Azure AD (Entra ID) External Identities**, not DNS:

1. **Azure AD B2B Integration**: Enabled at the tenant level
2. **Domain Restrictions**: Configured in Microsoft 365 admin center
   - Allow only specific domains
   - Block specific domains

### Important Changes (2024-2025)

**July 1, 2025 Breaking Change**:
- Users must reshare files, folders, and sites with external collaborators
- Old invitations sent via legacy SharePoint Invitation Manager will no longer grant access to guests
- **Action Required**: Re-invite external users using the new Azure AD B2B integration

**June 2024 Change**:
- Legacy SharePoint Invitation Manager invitations stopped working
- All external sharing now goes through Azure AD B2B

### DNS Impact

**No specific DNS records required** for SharePoint external sharing. However, external users must have access to:
- Standard Microsoft 365 authentication endpoints
- Azure AD login endpoints (`login.microsoftonline.com`, `login.windows.net`)
- SharePoint Online endpoints

---

## 5. Viva Engage (Yammer) DNS Requirements

### DNS and CNAME Requirements

**Viva Engage does NOT require any special CNAME DNS records.**

### Configuration

1. **Domain Verification**: Standard Microsoft 365 TXT record verification
   - **TXT Record**: Required for domain ownership proof
   - **CNAME Record**: Only required for Microsoft 365 operated by 21Vianet customers

2. **Automatic Setup**: When you add a domain to Microsoft 365, it automatically becomes available in Viva Engage
   - Primary domain is based on the first custom domain added to Microsoft 365

### Network Requirements (2024 Update)

**Access Requirements (as of January 2024)**:
- Users must be able to access `engage.cloud.microsoft`
- **Important**: Microsoft recommends against using IP address allowlists
  - IP ranges can change
  - May create access problems for users

### Email Domain Changes (2025-2026)

**Rollout Timeline**: Starting September 2025

**Changes**:
- Email sender domain changing from `yammer.com` to `engage.mail.microsoft`
- Industry-standard email authentication (SPF) continues to prevent tenant spoofing
- Phased rollout over several months

### Required Endpoints

Viva Engage users need access to:
- `engage.cloud.microsoft`
- Standard Microsoft 365 endpoints (Exchange, SharePoint, Teams)
- Azure AD authentication endpoints

---

## 6. Viva Connections DNS Requirements

### Overview

**Viva Connections does NOT have separate DNS requirements beyond standard Microsoft 365 services.**

### Network Dependencies

Viva Connections is built on:
- **Microsoft Teams** infrastructure
- **SharePoint Online** infrastructure
- **Exchange Online** (for some features)
- **Microsoft 365 Common services**
- **Office Online**

### Required Endpoint Categories

Since Viva Connections runs within Teams and uses SharePoint infrastructure:

1. **Microsoft Teams endpoints** (required)
2. **SharePoint Online endpoints** (required)
3. **Exchange Online endpoints** (for some features)
4. **Microsoft 365 Common services** (required)

### Network Configuration

**Requirements**:
- Whitelist Microsoft 365 URLs and IP addresses per official documentation
- Same network requirements as Microsoft Teams client
- Categories listed as "required" for Teams must be open on firewall

### Official Documentation

For complete endpoint list:
- **Reference**: Microsoft 365 URLs and IP address ranges (learn.microsoft.com)
- **Update Schedule**: Monthly with 30-day advance notice
- **Service Areas**: Common, Exchange, SharePoint, Teams

---

## 7. Microsoft Loop DNS Requirements

### Overview

Microsoft Loop requires specific network endpoints for real-time collaboration features.

### Critical WebSocket Requirements

**WebSocket Endpoints** (Required for real-time collaboration):
- `*.svc.ms` (wildcard domain)
- `*.office.com` (wildcard domain)

**Purpose**: Enable real-time features:
- Live editing
- Presence indicators
- Shared cursors

### Core DNS Endpoints

1. **Loop Application Access**:
   - `loop.cloud.microsoft`

2. **Microsoft 365 Copilot Integration**:
   - `*.cloud.microsoft`

3. **Infrastructure Dependencies**:
   - `*.svc.ms`
   - `*.office.com`

### Network Configuration Requirements

**Firewall Configuration**:
- Allow WebSocket traffic to `*.svc.ms` and `*.office.com`
- Ensure connections to Loop services are available and enabled
- Follow Office 365 URLs and IP address ranges documentation

### Infrastructure Dependencies

Loop leverages:
- **SharePoint Online** infrastructure
- **OneDrive** infrastructure
- **Fluid Framework** (Microsoft's collaborative platform)

### Access Requirements

**Supported Plans**:
- Office 365 commercial plans
- Government Community Cloud (GCC)

**Note**: Endpoints are updated monthly at the beginning of each month, with new IP addresses and URLs published 30 days in advance.

---

## 8. SharePoint Online Core DNS Endpoints

Based on official Microsoft 365 URLs and IP address ranges documentation (ID references from Microsoft endpoint service).

### Primary Endpoints (ID 31 - Optimize Required)

**Wildcard Domain**: `*.sharepoint.com`

**Category**: Optimize (highest priority)
- **Azure ExpressRoute**: Supported
- **Ports**: TCP 443, TCP 80, UDP 443
- **IPv4 Ranges**:
  - 13.107.136.0/22
  - 40.108.128.0/17
  - 52.104.0.0/14
  - 104.146.128.0/17
  - 150.171.40.0/22
- **IPv6 Ranges**: Multiple ranges (see Microsoft documentation for current list)

### Supporting Service Endpoints

#### ID 32 - OneDrive Functionality (Default Optional)

**Domain**: `storage.live.com`

**Purpose**: OneDrive supportability, telemetry, APIs, embedded email links
- **Port**: TCP 443
- **ExpressRoute**: Not supported

#### ID 35 - Windows Push Notifications (Default Required)

**Domains**:
- `*.wns.windows.com`
- `admin.onedrive.com`
- `officeclient.microsoft.com`

**Ports**: TCP 443, TCP 80

#### ID 36 - OneDrive Components (Default Required)

**Domains**:
- `g.live.com`
- `oneclient.sfx.ms`

**Ports**: TCP 443, TCP 80

#### ID 37 - SharePoint Infrastructure (Default Required)

**Domains**:
- `*.sharepointonline.com`
- `spoprod-a.akamaihd.net`

**Ports**: TCP 443, TCP 80

#### ID 39 - Service Endpoints (Default Required)

**Domain**: `*.svc.ms`

**Ports**: TCP 443, TCP 80
- **Note**: Used for SharePoint services including Loop real-time collaboration

### Unified Microsoft 365 Domains (ID 184)

**New Consolidated Domains** for Microsoft 365 services:
- `*.cloud.microsoft`
- `*.static.microsoft`
- `*.usercontent.microsoft`

**Ports**: TCP 443, UDP 443

---

## 9. OneDrive Core DNS Endpoints

### OneDrive for Business Endpoints

OneDrive for Business uses the **SharePoint Online endpoints** (see Section 8).

**Key Domains**:
- `*.sharepoint.com`
- `*.sharepointonline.com`
- `*.svc.ms`
- `*.office.com`

### OneDrive Consumer Endpoints

For OneDrive personal/consumer version (not Microsoft 365):

#### Group 1: Authentication and Core Services

**Ports**: TCP 80, TCP 443

**Specific Domains**:
- `onedrive.com`
- `onedrive.live.com`
- `login.live.com`
- `g.live.com`
- `spoprod-a.akamaihd.net`
- `p.sfx.ms`
- `oneclient.sfx.ms`
- `fabric.io`
- `vortex.data.microsoft.com`
- `posarprodcssservice.accesscontrol.windows.net`
- `redemptionservices.accesscontrol.windows.net`
- `token.cp.microsoft.com`
- `tokensit.cp.microsoft-tst.com`
- `odc.officeapps.live.com`
- `login.windows.net`
- `login.microsoftonline.com`

**Wildcard Domains**:
- `*.onedrive.com`
- `*.mesh.com`
- `*.microsoft.com`
- `*.crashlytics.com`
- `*.office.com`
- `*.officeapps.live.com`
- `*.aria.microsoft.com`
- `*.mobileengagement.windows.net`
- `*.branch.io`
- `*.adjust.com`
- `*.servicebus.windows.net`

#### Group 2: File Storage and Data Services

**Ports**: TCP 80, TCP 443

**Specific Domains**:
- `storage.live.com`
- `favorites.live.com`
- `oauth.live.com`
- `photos.live.com`
- `skydrive.live.com`
- `api.live.net`
- `apis.live.net`
- `docs.live.net`
- `policies.live.net`
- `settings.live.net`
- `skyapi.live.net`
- `snapi.live.net`
- `storage.msn.com`
- `vas.samsungapps.com`

**Wildcard Domains**:
- `*.files.1drv.com`
- `*.onedrive.live.com`
- `*.*.onedrive.live.com` (multi-level wildcard)
- `*.storage.live.com`
- `*.*.storage.live.com` (multi-level wildcard)
- `*.groups.office.live.com`
- `*.groups.photos.live.com`
- `*.groups.skydrive.live.com`
- `*.docs.live.net`
- `*.policies.live.net`
- `*.settings.live.net`
- `*.livefilestore.com`
- `*.*.livefilestore.com` (multi-level wildcard)
- `*.storage.msn.com`
- `*.*.storage.msn.com` (multi-level wildcard)

---

## 10. SharePoint CDN Endpoints

### Overview

SharePoint Online Content Delivery Network (CDN) provides improved performance by caching static assets closer to browsers.

### Public CDN Endpoints

**URL Format**: `https://publiccdn.sharepointonline.com/<tenant host name>/sites/site/library`

**Supported Content**:
- JavaScript (JS)
- CSS (Style Sheets)
- Web Font Files (WOFF, WOFF2)
- Non-proprietary images (company logos, etc.)

### Private CDN Endpoints

**URL Format**: `https://privatecdn.sharepointonline.com/tenant/sites/site/library/item`

**Use Case**: Internal organizational content requiring authentication

### Important Guidance

**Do NOT hardcode CDN URLs** - they are subject to change!

**Recommended Approach**:
- **Classic SharePoint**: Use `window._spPageContextInfo.publicCdnBaseUrl`
- **SPFx Web Parts**: Use `this.context.pageContext.legacyPageContext.publicCdnBaseUrl`

### Features

- **HTTP/2 Protocol**: Improved compression and HTTP pipelining
- **Geographic Distribution**: Assets cached closer to users
- **Reduced Latency**: Faster downloads for static content
- **General Availability**: Fully supported (GA) as of 2017

### DNS Impact

**No special DNS configuration required**. CDN endpoints use SharePoint Online infrastructure:
- `*.sharepointonline.com`

---

## 11. SharePoint Advanced Management

### Overview

**SharePoint Advanced Management** (now part of SharePoint Premium) is a governance tool for managing SharePoint and OneDrive content.

### DNS Requirements

**No specific DNS requirements or dedicated endpoints** for SharePoint Advanced Management.

### Network Requirements

SharePoint Advanced Management uses the **standard SharePoint Online infrastructure**:
- Standard SharePoint Online endpoints (see Section 8)
- Standard Microsoft 365 endpoints

### Features (No Additional DNS Required)

- Lifecycle policies
- Access controls
- Advanced tenant rename (for tenants with >10,000 sites)
- Content governance

### Configuration

All configuration is done through:
- SharePoint admin center
- Microsoft 365 admin center
- Microsoft Purview compliance portal

---

## 12. SharePoint Embedded

### Overview

SharePoint Embedded is an API-only solution for developers to build applications that leverage SharePoint's file and document storage capabilities.

### DNS Requirements

**No specific DNS requirements** for SharePoint Embedded.

### Network Requirements

SharePoint Embedded relies on:

1. **Microsoft Graph API**:
   - `graph.microsoft.com`
   - All operations exposed via Microsoft Graph

2. **Standard SharePoint Online Endpoints**:
   - `*.sharepoint.com`
   - `*.sharepointonline.com`

3. **Microsoft 365 Infrastructure**:
   - Standard Microsoft 365 endpoints
   - Azure AD authentication endpoints

### Architecture

- **API-Only**: No UI provided by Microsoft
- **Microsoft Graph Integration**: All operations via Graph API
- **Tenant Integration**: Documents stored in customer's Microsoft 365 tenant
- **Compliance**: Subject to Microsoft Purview compliance, risk, and security settings
- **Office Integration**: Documents can be opened from Office clients

### Endpoint Reference

For SharePoint Embedded applications, ensure access to:
- Microsoft Graph endpoints
- SharePoint Online endpoints (Section 8)
- Microsoft 365 common endpoints

---

## 13. Deprecated SharePoint DNS Records

### msoid CNAME Record

**Status**: Deprecated for most Microsoft 365 environments (2024)

#### Previously Used For

- Directed users to optimal authentication server
- Improved authentication response times
- Required for Office 365 GCC High and DoD

#### Current Status (2024-2025)

**Removed**: msoid CNAME record must be removed from DNS for:
- Office 365 Government Community Cloud (GCC) High
- Office 365 Department of Defense (DoD)

**Still Required For**:
- Microsoft 365 operated by 21Vianet (China)

#### Record Details (21Vianet Only)

```
Type: CNAME
Alias: msoid
Target: clientconfig.partner.microsoftonline-p.net.cn
```

#### Migration Guidance

**For GCC High/DoD customers**:
1. Verify existing msoid CNAME in DNS zone
2. Remove the record from DNS
3. No replacement record required

**For 21Vianet customers**:
- Keep msoid CNAME record
- Continue to maintain record for authentication

### Legacy SharePoint Public Sites

**Status**: Deprecated and discontinued

**Historical Feature**:
- Custom domain support for public-facing SharePoint sites
- Required A records and CNAME records
- Allowed vanity URLs for public websites

**Current Status**:
- Feature removed from SharePoint Online
- No longer available for new sites
- Existing public sites migrated or deprecated

---

## 14. Microsoft 365 Endpoint Web Service

### Overview

Microsoft provides a REST-based web service for programmatic access to Microsoft 365 network endpoints.

### Primary Endpoints

#### Version Endpoint

```
https://endpoints.office.com/version
```

**Purpose**: Check current version of endpoint data

#### Endpoints Endpoint

```
https://endpoints.office.com/endpoints/worldwide
```

**Purpose**: Retrieve current endpoint list

#### Changes Endpoint

```
https://endpoints.office.com/changes/worldwide/0000000000
```

**Purpose**: Track changes since specific version

### Service Area Filtering

**SharePoint-Specific Endpoints**:

```
https://endpoints.office.com/endpoints/worldwide?ServiceAreas=SharePoint
```

**Available Service Areas**:
- Common (prerequisite for all other services)
- Exchange
- SharePoint
- Skype

### Configuration Parameters

**Format Options**:
- JSON (default)
- CSV
- RSS

**Instance Options**:
- Worldwide (default)
- China (21Vianet)
- USGovDoD
- USGovGCCHigh

**Additional Parameters**:
- `NoIPv6`: Exclude IPv6 addresses
- `ClientRequestId`: Required unique GUID for tracking

### Version Format

**Pattern**: `YYYYMMDDNN`
- YYYY: Year
- MM: Month
- DD: Day
- NN: Sequential update number for that day

### Example Usage

```powershell
# Get SharePoint endpoints as JSON
$uri = "https://endpoints.office.com/endpoints/worldwide?ServiceAreas=SharePoint&ClientRequestId=$([guid]::NewGuid())"
$endpoints = Invoke-RestMethod -Uri $uri

# Get version
$version = Invoke-RestMethod -Uri "https://endpoints.office.com/version?ClientRequestId=$([guid]::NewGuid())"

# Get changes since specific version
$changes = Invoke-RestMethod -Uri "https://endpoints.office.com/changes/worldwide/2024110100?ClientRequestId=$([guid]::NewGuid())"
```

### Update Schedule

- **Frequency**: Monthly (beginning of each month)
- **Advance Notice**: 30 days before new endpoints become active
- **Ad-hoc Updates**: May occur for security incidents or operational requirements

---

## 15. Best Practices and Recommendations

### DNS Management

#### 1. Use Dynamic Endpoint Lists

**Recommendation**: Use the Microsoft 365 IP Address and URL Web Service for automated updates

**Reasons**:
- Monthly endpoint updates
- 30-day advance notice for changes
- Programmatic access
- Version tracking

**Implementation**:
```powershell
# Check version hourly
$version = Invoke-RestMethod -Uri "https://endpoints.office.com/version?ClientRequestId=$([guid]::NewGuid())"

# If version changed, update firewall rules
if ($version.latest -ne $lastKnownVersion) {
    # Retrieve updated endpoints
    $endpoints = Invoke-RestMethod -Uri "https://endpoints.office.com/endpoints/worldwide?ServiceAreas=SharePoint&ClientRequestId=$([guid]::NewGuid())"
    # Update firewall/proxy configuration
}
```

#### 2. Prioritize Optimize Category Endpoints

**Optimize Endpoints** (highest priority):
- `*.sharepoint.com`
- Low latency requirement
- High bandwidth requirement
- Azure ExpressRoute supported

**Configuration**:
- Bypass proxy for Optimize endpoints
- Direct internet egress
- Minimal inspection (SSL break-and-inspect not recommended)

#### 3. Implement Wildcard Domain Support

**Required Wildcards**:
- `*.sharepoint.com`
- `*.sharepointonline.com`
- `*.office.com`
- `*.svc.ms`
- `*.cloud.microsoft`

**Firewall Configuration**:
- Support wildcard FQDN rules
- Avoid hardcoding specific subdomains
- Microsoft may add new subdomains without notice

#### 4. Enable WebSocket Support

**Required For**:
- Microsoft Loop real-time collaboration
- SharePoint real-time features
- Presence indicators

**Domains**:
- `*.svc.ms`
- `*.office.com`

**Ports**: TCP 443, UDP 443

### SharePoint Hybrid Deployments

#### 1. Implement Split DNS

**Best Practice**: Configure split DNS for hybrid scenarios

**Benefits**:
- Seamless user experience
- Reduced latency for internal users
- Proper routing for external users

#### 2. Use Reverse Proxy

**Requirements**:
- Public certificate (not self-signed)
- TCP 443 only required
- URL rewriting capability

**Recommended Solutions**:
- Azure Application Proxy
- Web Application Proxy (WAP)
- Third-party solutions (F5, Citrix ADC)

### Security Considerations

#### 1. Avoid IP Address Allowlisting

**Microsoft Recommendation**: Do not use IP address ranges alone

**Reasons**:
- IP ranges change frequently
- May cause unexpected access issues
- 30-day notice doesn't guarantee exact change date

**Alternative**: Use FQDN-based firewall rules

#### 2. SSL Inspection

**Optimize Endpoints**: Do NOT perform SSL break-and-inspect
- Performance degradation
- May break functionality
- Trust issues

**Allow/Default Endpoints**: Selective SSL inspection acceptable

#### 3. Authentication Endpoints

**Critical Dependencies**:
- `login.microsoftonline.com`
- `login.windows.net`
- `*.windows.net`

**Ensure Access To**:
- Azure AD authentication
- Multi-factor authentication (MFA)
- Conditional Access policies

### Migration and Deprecation Planning

#### 1. Monitor Message Center

**Action**: Regularly check Microsoft 365 Message Center
- Upcoming changes
- Deprecation notices
- New features requiring network changes

**Location**: admin.microsoft.com > Health > Message center

#### 2. Plan for Viva Engage Email Domain Change

**Timeline**: September 2025 - Early 2026

**Action Items**:
1. Update email filters and rules
2. Communicate change to users
3. Update SPF records if customized
4. Test email deliverability

**Old Domain**: `yammer.com`
**New Domain**: `engage.mail.microsoft`

#### 3. External Sharing Migration (July 1, 2025)

**Action Required**:
- Re-invite all external collaborators
- Test B2B sharing functionality
- Update documentation
- Train users on new sharing process

### Monitoring and Troubleshooting

#### 1. Endpoint Health Monitoring

**Tools**:
- Microsoft 365 network connectivity test: `https://connectivity.office.com`
- Network trace tools
- Fiddler for traffic analysis

**Key Metrics**:
- Latency to Optimize endpoints (<50ms recommended)
- Packet loss
- DNS resolution times

#### 2. DNS Health Checks

**Regular Testing**:
```powershell
# Test SharePoint endpoint resolution
Resolve-DnsName "tenant.sharepoint.com"

# Test CDN endpoints
Resolve-DnsName "publiccdn.sharepointonline.com"

# Test authentication
Resolve-DnsName "login.microsoftonline.com"
```

#### 3. WebSocket Testing

**Verify WebSocket Support**:
- Browser developer tools (Network tab)
- Look for WS/WSS connections to `*.svc.ms`
- Ensure no proxy/firewall blocking

### Documentation and Change Management

#### 1. Maintain Endpoint Inventory

**Document**:
- Current endpoint version
- Custom firewall rules
- Proxy bypass list
- ExpressRoute peering configuration

#### 2. Change Control Process

**For Endpoint Updates**:
1. Review monthly endpoint changes
2. Test in non-production environment
3. Schedule maintenance window
4. Update firewall/proxy rules
5. Validate functionality
6. Document changes

#### 3. Disaster Recovery

**Prepare For**:
- Endpoint connectivity failures
- DNS resolution issues
- Service degradation

**Recovery Steps**:
1. Verify DNS resolution
2. Check firewall rules
3. Bypass proxy temporarily for testing
4. Contact Microsoft support
5. Review Message Center for incidents

---

## Conclusion

SharePoint Online and OneDrive for Business in 2024-2025 continue to evolve with tighter integration into the broader Microsoft 365 ecosystem. Key takeaways:

### No New SharePoint-Specific DNS Records

- No new CNAME records announced for 2024-2025
- SharePoint continues to use wildcard domains (`*.sharepoint.com`, `*.sharepointonline.com`)
- Focus on endpoint management rather than custom DNS configuration

### Viva Services Leverage Existing Infrastructure

- Viva Engage: No special DNS requirements
- Viva Connections: Uses Teams/SharePoint endpoints
- Microsoft Loop: Requires WebSocket support (`*.svc.ms`)

### Key DNS Requirements Summary

| Service | Primary DNS Requirement | Notes |
|---------|------------------------|-------|
| SharePoint Online | `*.sharepoint.com` | Optimize endpoint, bypass proxy |
| OneDrive for Business | `*.sharepoint.com` | Same as SharePoint Online |
| SharePoint Hybrid | Split DNS, A records | Reverse proxy required |
| Viva Engage | Standard M365 endpoints | No special DNS |
| Viva Connections | Teams + SharePoint endpoints | No special DNS |
| Microsoft Loop | `*.svc.ms`, `loop.cloud.microsoft` | WebSocket support required |
| SharePoint CDN | `*.sharepointonline.com` | No special config |
| SharePoint Embedded | Microsoft Graph endpoints | No special DNS |

### Deprecated Items

- **msoid CNAME**: Removed for most environments (except 21Vianet)
- **Public Sites**: No longer available
- **Legacy Invitation Manager**: Replaced by Azure AD B2B

### Action Items for Administrators

1. **Implement Dynamic Endpoint Management**: Use the Microsoft 365 endpoint web service
2. **Enable WebSocket Support**: Required for Loop and real-time features
3. **Plan for July 2025**: Re-invite external collaborators (Azure AD B2B migration)
4. **Monitor Viva Engage Email Change**: September 2025 - Early 2026
5. **Optimize Network Configuration**: Bypass proxy for Optimize endpoints
6. **Regular Health Checks**: Test endpoint connectivity and DNS resolution

---

## References

### Official Microsoft Documentation

1. **Microsoft 365 URLs and IP Address Ranges**
   https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges

2. **Microsoft 365 IP Address and URL Web Service**
   https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service

3. **External Domain Name System Records for Microsoft 365**
   https://learn.microsoft.com/en-us/microsoft-365/enterprise/external-domain-name-system-records

4. **SharePoint Hybrid Configuration**
   https://learn.microsoft.com/en-us/sharepoint/hybrid/configure-inbound-connectivity

5. **Required URLs and Ports for OneDrive**
   https://learn.microsoft.com/en-us/sharepoint/required-urls-and-ports

6. **Manage Loop Components in Your Organization**
   https://learn.microsoft.com/en-us/microsoft-365/loop/loop-components-configuration

7. **SharePoint Domain Rename**
   https://learn.microsoft.com/en-us/sharepoint/change-your-sharepoint-domain-name

8. **Viva Engage Domains Management**
   https://learn.microsoft.com/en-us/viva/engage/configure-your-viva-engage-network/manage-viva-engage-domains

9. **SharePoint CDN Usage**
   https://learn.microsoft.com/en-us/microsoft-365/enterprise/use-microsoft-365-cdn-with-spo

10. **SharePoint External Sharing (Azure AD B2B)**
    https://learn.microsoft.com/en-us/sharepoint/sharepoint-azureb2b-integration

### Update Schedule

- **Endpoint Updates**: Monthly (first of each month)
- **Advance Notice**: 30 days for new endpoints
- **Web Service**: Check hourly for version changes
- **Documentation**: Regularly updated by Microsoft

---

**Document Version**: 1.0
**Last Updated**: November 6, 2025
**Next Review**: December 1, 2025
**Maintained By**: DNS4M365 Project Team
