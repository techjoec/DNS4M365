# SharePoint Online and OneDrive DNS Quick Reference (2024-2025)

**Last Updated**: November 6, 2025

---

## Critical DNS Endpoints

### SharePoint Online Wildcard Domains (Required)

| Domain Pattern | Category | Ports | Purpose |
|---------------|----------|-------|---------|
| `*.sharepoint.com` | Optimize | TCP 443, 80; UDP 443 | Primary SharePoint Online access |
| `*.sharepointonline.com` | Default | TCP 443, 80 | SharePoint infrastructure |
| `*.svc.ms` | Default | TCP 443, 80 | Service endpoints, WebSockets |
| `*.office.com` | Default | TCP 443, 80 | Office integration, WebSockets |
| `*.cloud.microsoft` | Default | TCP 443; UDP 443 | Unified Microsoft 365 services |

### OneDrive for Business Endpoints

| Domain Pattern | Category | Ports | Purpose |
|---------------|----------|-------|---------|
| `*.sharepoint.com` | Optimize | TCP 443, 80; UDP 443 | Primary OneDrive access |
| `storage.live.com` | Default | TCP 443 | OneDrive APIs and telemetry |
| `oneclient.sfx.ms` | Default | TCP 443, 80 | OneDrive sync client |
| `admin.onedrive.com` | Default | TCP 443, 80 | OneDrive admin portal |
| `g.live.com` | Default | TCP 443, 80 | OneDrive services |

### Microsoft Loop Endpoints (New 2024-2025)

| Domain Pattern | Category | Ports | Purpose |
|---------------|----------|-------|---------|
| `loop.cloud.microsoft` | Default | TCP 443 | Loop app access |
| `*.svc.ms` | Default | TCP 443, 80 | Real-time collaboration (WebSocket) |
| `*.office.com` | Default | TCP 443, 80 | Real-time collaboration (WebSocket) |

### Viva Engage (Yammer) Endpoints

| Domain Pattern | Category | Ports | Purpose |
|---------------|----------|-------|---------|
| `engage.cloud.microsoft` | Default | TCP 443 | Viva Engage access (as of Jan 2024) |
| Standard M365 endpoints | - | - | No special DNS required |

**Note**: Viva Engage uses standard Microsoft 365 endpoints. Email domain changing from `yammer.com` to `engage.mail.microsoft` (September 2025).

### SharePoint CDN Endpoints

| Domain Pattern | Category | Ports | Purpose |
|---------------|----------|-------|---------|
| `publiccdn.sharepointonline.com` | Default | TCP 443, 80 | Public CDN for static assets |
| `privatecdn.sharepointonline.com` | Default | TCP 443, 80 | Private CDN for org assets |
| `spoprod-a.akamaihd.net` | Default | TCP 443, 80 | CDN infrastructure |

---

## DNS Records Required for Custom Configurations

### Domain Verification (All Custom Domains)

| Record Type | Host | Value | Purpose |
|-------------|------|-------|---------|
| TXT | `@` | `MS=msXXXXXXXX` (Microsoft-provided) | Domain ownership verification |

**Note**: CNAME verification record (`msoid`) only required for Microsoft 365 operated by 21Vianet customers.

### SharePoint Hybrid (On-Premises Integration)

#### Public DNS (at Domain Registrar)

| Record Type | Host | Value | Purpose |
|-------------|------|-------|---------|
| A | `sharepoint` (or custom) | Public IP of reverse proxy | External access to hybrid endpoint |

#### Internal DNS (On-Premises)

| Record Type | Host | Value | Purpose |
|-------------|------|-------|---------|
| A | `sharepoint` (or custom) | Internal IP of SharePoint farm | Internal access to on-premises SharePoint |

**Configuration**: Requires split DNS with forward lookup zone.

---

## IP Address Ranges (SharePoint Online - ID 31)

**IPv4 Ranges**:
- 13.107.136.0/22
- 40.108.128.0/17
- 52.104.0.0/14
- 104.146.128.0/17
- 150.171.40.0/22

**IPv6 Ranges**: See official Microsoft documentation for current list

**Note**: IP ranges change frequently. Use FQDN-based rules where possible.

---

## Service-Specific Endpoints

### Authentication and Identity

| Domain | Category | Purpose |
|--------|----------|---------|
| `login.microsoftonline.com` | Required | Azure AD authentication |
| `login.windows.net` | Required | Legacy authentication |
| `*.windows.net` | Required | Azure services |

### Supporting Services

| Domain | Category | Purpose |
|--------|----------|---------|
| `*.wns.windows.com` | Required | Windows Push Notifications |
| `officeclient.microsoft.com` | Required | Office client configuration |
| `*.static.microsoft` | Default | Static content delivery |
| `*.usercontent.microsoft` | Default | User-generated content |

---

## Deprecated DNS Records (2024-2025)

### msoid CNAME (Deprecated)

| Record Type | Host | Value | Status |
|-------------|------|-------|--------|
| CNAME | `msoid` | `clientconfig.partner.microsoftonline-p.net.cn` | Required for 21Vianet ONLY |

**Action Required**:
- **GCC High/DoD customers**: Remove this record from DNS
- **21Vianet customers**: Keep this record

---

## Network Configuration Priorities

### Optimize Category (Highest Priority)

**Domain**: `*.sharepoint.com`

**Requirements**:
- Bypass proxy
- Direct internet egress
- No SSL break-and-inspect
- Low latency (<50ms recommended)
- Azure ExpressRoute supported

### Allow Category (Medium Priority)

**Domains**: Most other SharePoint/OneDrive endpoints

**Requirements**:
- Proxy allowed
- Selective SSL inspection acceptable
- Standard routing

### Default Category (Standard Priority)

**Domains**: Supporting services

**Requirements**:
- Standard network policies
- Proxy allowed

---

## Port Requirements Summary

| Service | TCP Ports | UDP Ports |
|---------|-----------|-----------|
| SharePoint Online | 443, 80 | 443 |
| OneDrive for Business | 443, 80 | 443 |
| Microsoft Loop (WebSocket) | 443, 80 | 443 |
| SharePoint Hybrid (Reverse Proxy) | 443 only | - |
| CDN | 443, 80 | - |

---

## WebSocket Requirements (New for 2024-2025)

**Required For**:
- Microsoft Loop real-time collaboration
- Live editing features
- Presence indicators
- Shared cursors

**Domains Requiring WebSocket Support**:
- `*.svc.ms`
- `*.office.com`

**Ports**: TCP 443, UDP 443

**Firewall Configuration**:
- Enable WebSocket protocol
- Do not block WS/WSS connections
- Allow HTTP Upgrade to WebSocket

---

## Custom Domain Limitations

### SharePoint Vanity URLs

**Status**: NOT SUPPORTED natively

**Workarounds**:
- Azure Front Door (URL rewrites to SharePoint)
- Reverse proxy solutions
- **Limitation**: SharePoint URL may appear in address bar

### OneDrive Custom Domains

**Status**: LIMITED SUPPORT via domain rename

**Requirements**:
- Tenant must have <10,000 sites (or use SharePoint Advanced Management)
- Domain must be verified in Microsoft 365
- Affects entire tenant (all SharePoint and OneDrive URLs)
- Does NOT affect email addresses

**DNS Required**:
- Standard TXT record for domain verification
- No custom CNAME records

---

## Firewall Configuration Checklist

### Required Wildcard Domains

```
✓ *.sharepoint.com
✓ *.sharepointonline.com
✓ *.office.com
✓ *.svc.ms
✓ *.cloud.microsoft
✓ *.microsoft.com (for OneDrive consumer/auth)
✓ login.microsoftonline.com
✓ login.windows.net
```

### Optional but Recommended

```
✓ *.static.microsoft
✓ *.usercontent.microsoft
✓ *.wns.windows.com
✓ officeclient.microsoft.com
```

### Protocol Support

```
✓ HTTPS (TCP 443)
✓ HTTP (TCP 80) - for redirects
✓ WebSocket (WS/WSS)
✓ UDP 443 (for modern protocols)
```

---

## Microsoft 365 Endpoint Web Service

### Query SharePoint Endpoints Programmatically

```powershell
# Get SharePoint-specific endpoints
$clientId = [guid]::NewGuid()
$uri = "https://endpoints.office.com/endpoints/worldwide?ServiceAreas=SharePoint&ClientRequestId=$clientId"
$endpoints = Invoke-RestMethod -Uri $uri

# Filter by category
$optimizeEndpoints = $endpoints | Where-Object { $_.category -eq 'Optimize' }

# Get just URLs
$urls = $endpoints.urls | Select-Object -Unique
```

### Check for Updates

```powershell
# Check version (recommended: hourly)
$version = Invoke-RestMethod -Uri "https://endpoints.office.com/version?ClientRequestId=$([guid]::NewGuid())"

# Get changes since specific version
$changes = Invoke-RestMethod -Uri "https://endpoints.office.com/changes/worldwide/2024110100?ClientRequestId=$([guid]::NewGuid())"
```

---

## Troubleshooting Quick Checks

### DNS Resolution Test

```powershell
# Test primary SharePoint domain
Resolve-DnsName "tenant.sharepoint.com"

# Test authentication
Resolve-DnsName "login.microsoftonline.com"

# Test Loop endpoint
Resolve-DnsName "loop.cloud.microsoft"

# Test CDN
Resolve-DnsName "publiccdn.sharepointonline.com"
```

### Connectivity Test

```powershell
# Test SharePoint connectivity
Test-NetConnection -ComputerName "tenant.sharepoint.com" -Port 443

# Test OneDrive admin portal
Test-NetConnection -ComputerName "admin.onedrive.com" -Port 443

# Test authentication endpoint
Test-NetConnection -ComputerName "login.microsoftonline.com" -Port 443
```

### Network Connectivity Tool

Microsoft provides an online tool:
- **URL**: https://connectivity.office.com
- **Purpose**: Test network connectivity to Microsoft 365 services
- **Features**: Latency testing, endpoint reachability, recommendations

---

## Important Dates and Milestones (2024-2025)

| Date | Change | Impact |
|------|--------|--------|
| June 2024 | Legacy SharePoint Invitation Manager deprecated | External guests must be re-invited |
| July 1, 2025 | Azure AD B2B integration mandatory | All external sharing via Azure AD B2B |
| September 2025 | Viva Engage email domain change begins | Email domain changes from yammer.com to engage.mail.microsoft |
| Monthly | Endpoint updates | New IP addresses/URLs (30-day notice) |

---

## No Special DNS Requirements

The following services do NOT require special DNS records beyond standard Microsoft 365 endpoints:

- **Viva Connections**: Uses Teams + SharePoint endpoints
- **Viva Engage (Yammer)**: Uses standard M365 endpoints
- **SharePoint External Sharing**: Managed via Azure AD B2B
- **SharePoint Advanced Management**: Uses SharePoint Online infrastructure
- **SharePoint Embedded**: Uses Microsoft Graph endpoints
- **SharePoint Forms**: Uses SharePoint Online endpoints
- **Microsoft Lists**: Uses SharePoint Online endpoints

---

## Quick Reference: DNS Records by Scenario

### Scenario 1: New Microsoft 365 Tenant with SharePoint

**Required DNS Records**:
1. TXT record for domain verification
2. Allow wildcard domain: `*.sharepoint.com`
3. Allow wildcard domain: `*.office.com`
4. Allow authentication: `login.microsoftonline.com`

### Scenario 2: SharePoint Hybrid Deployment

**Required DNS Records**:
1. TXT record for domain verification
2. Public A record → reverse proxy IP
3. Internal A record → SharePoint farm IP
4. Split DNS configuration
5. All wildcard domains from Scenario 1

### Scenario 3: Microsoft Loop Deployment

**Required DNS Records**:
1. All from Scenario 1
2. Allow WebSocket to: `*.svc.ms`
3. Allow: `loop.cloud.microsoft`
4. Allow: `*.cloud.microsoft`

### Scenario 4: OneDrive Deployment

**Required DNS Records**:
1. All from Scenario 1
2. Allow: `storage.live.com`
3. Allow: `oneclient.sfx.ms`
4. Allow: `admin.onedrive.com`

---

## References

- **Microsoft 365 URLs and IP Addresses**: https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges
- **Endpoint Web Service**: https://endpoints.office.com
- **Network Connectivity Test**: https://connectivity.office.com
- **SharePoint Hybrid Docs**: https://learn.microsoft.com/en-us/sharepoint/hybrid/configure-inbound-connectivity

---

**Document Version**: 1.0
**For Detailed Information**: See SHAREPOINT-ONEDRIVE-DNS-RESEARCH-2024-2025.md
