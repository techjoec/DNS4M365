# Quick Guide: Querying Microsoft 365 Domain DNS Records

This guide covers three methods for querying Microsoft 365 custom domain DNS records: Graph API, GUI (Microsoft 365 Admin Center), and PowerShell.

---

## Table of Contents

1. [Method 1: Microsoft Graph API](#method-1-microsoft-graph-api)
2. [Method 2: Microsoft 365 Admin Center (GUI)](#method-2-microsoft-365-admin-center-gui)
3. [Method 3: PowerShell](#method-3-powershell)
4. [Comparison Table](#comparison-table)

---

## Method 1: Microsoft Graph API

### Overview

Microsoft Graph API provides programmatic access to Microsoft 365 domain DNS records through RESTful endpoints.

### Prerequisites

- Application registration in Azure AD/Entra ID
- API permissions: `Domain.Read.All` (or `Domain.ReadWrite.All` for write operations)
- Access token for authentication

### Key Endpoints

#### List All Domains
```http
GET https://graph.microsoft.com/v1.0/domains
```

#### Get Specific Domain
```http
GET https://graph.microsoft.com/v1.0/domains/{domain-id}
```

#### Get Service Configuration Records (DNS Records)
```http
GET https://graph.microsoft.com/v1.0/domains/{domain-id}/serviceConfigurationRecords
```

#### Get Verification Records
```http
GET https://graph.microsoft.com/v1.0/domains/{domain-id}/verificationDnsRecords
```

### Example: Using cURL

```bash
# Get all domains
curl -X GET "https://graph.microsoft.com/v1.0/domains" \
  -H "Authorization: Bearer {access-token}" \
  -H "Content-Type: application/json"

# Get DNS records for a specific domain
curl -X GET "https://graph.microsoft.com/v1.0/domains/contoso.com/serviceConfigurationRecords" \
  -H "Authorization: Bearer {access-token}" \
  -H "Content-Type: application/json"
```

### Response Example

```json
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#domains('contoso.com')/serviceConfigurationRecords",
  "value": [
    {
      "@odata.type": "#microsoft.graph.domainDnsMxRecord",
      "id": "...",
      "isOptional": false,
      "label": "@",
      "recordType": "MX",
      "supportedService": "Email",
      "ttl": 3600,
      "mailExchange": "contoso-com.mail.protection.outlook.com",
      "preference": 0
    },
    {
      "@odata.type": "#microsoft.graph.domainDnsTxtRecord",
      "id": "...",
      "isOptional": false,
      "label": "@",
      "recordType": "Txt",
      "supportedService": "Email",
      "ttl": 3600,
      "text": "v=spf1 include:spf.protection.outlook.com -all"
    }
  ]
}
```

### Advantages

- ✅ Fully automated and scriptable
- ✅ Can be integrated into CI/CD pipelines
- ✅ Language-agnostic (works with any HTTP client)
- ✅ Structured JSON responses
- ✅ Rate limiting and retry logic possible

### Limitations

- ❌ Requires application registration and permissions
- ❌ Token management required
- ❌ More complex initial setup

---

## Method 2: Microsoft 365 Admin Center (GUI)

### Overview

The Microsoft 365 Admin Center provides a web-based interface for viewing and managing domain DNS records.

### Step-by-Step Instructions

#### 1. Access the Admin Center

1. Navigate to [https://admin.microsoft.com](https://admin.microsoft.com)
2. Sign in with Global Administrator or Domain Administrator credentials

#### 2. Navigate to Domains

1. In the left navigation pane, expand **Settings**
2. Click on **Domains**
3. You'll see a list of all domains in your tenant

#### 3. View Domain Details

1. Click on the domain you want to inspect
2. The domain details page shows:
   - Verification status (Verified/Unverified)
   - DNS records required for Microsoft 365 services
   - Domain health status

#### 4. View DNS Records

1. Click on **DNS records** tab
2. You'll see all required DNS records categorized by service:
   - **Exchange and Email**: MX, TXT (SPF), CNAME (Autodiscover)
   - **Teams**: SRV and CNAME records
   - **Intune**: CNAME records
   - **SharePoint**: CNAME records

#### 5. Check Domain Status

1. Click **Check health** to verify DNS configuration
2. The system will validate each DNS record
3. Issues will be highlighted with recommended fixes

### DNS Record Information Displayed

For each record, the GUI shows:
- **Type**: MX, CNAME, TXT, SRV
- **Name/Host**: The record label
- **Value/Points to**: The target value
- **Priority**: (For MX and SRV records)
- **TTL**: Time to Live
- **Status**: Whether the record is correctly configured

### Advantages

- ✅ User-friendly visual interface
- ✅ No coding required
- ✅ Built-in validation and health checks
- ✅ Contextual help and tooltips
- ✅ Copy-paste ready values for DNS provider

### Limitations

- ❌ Manual process (not automated)
- ❌ Not suitable for bulk operations
- ❌ Cannot export data easily
- ❌ Requires browser and manual navigation

---

## Method 3: PowerShell

### Overview

PowerShell provides the most flexible and powerful way to query Microsoft 365 domain DNS records using the Microsoft Graph PowerShell SDK.

### Prerequisites

```powershell
# Install Microsoft Graph PowerShell modules
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
```

### 3A: Using Microsoft Graph PowerShell SDK

#### Connect to Microsoft Graph

```powershell
# Connect with required scopes
Connect-MgGraph -Scopes "Domain.Read.All"

# Connect to specific tenant
Connect-MgGraph -Scopes "Domain.Read.All" -TenantId "00000000-0000-0000-0000-000000000000"
```

#### Get All Domains

```powershell
# Get all domains
$domains = Get-MgDomain

# Display domains
$domains | Select-Object Id, IsVerified, IsDefault, AuthenticationType, SupportedServices

# Get only verified domains
$verifiedDomains = Get-MgDomain | Where-Object { $_.IsVerified -eq $true }

# Get only unverified domains
$unverifiedDomains = Get-MgDomain | Where-Object { $_.IsVerified -eq $false }
```

#### Get DNS Service Configuration Records

```powershell
# Get DNS records for a specific domain
$dnsRecords = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Display all records
$dnsRecords | Select-Object Label, RecordType, SupportedService, Ttl

# Filter by record type
$mxRecords = $dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'MX' }
$cnameRecords = $dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'CName' }
$txtRecords = $dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Txt' }
$srvRecords = $dnsRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Srv' }

# Get MX record details
foreach ($record in $mxRecords) {
    [PSCustomObject]@{
        Label = $record.Label
        MailExchange = $record.AdditionalProperties['mailExchange']
        Preference = $record.AdditionalProperties['preference']
        TTL = $record.Ttl
    }
}

# Get TXT record details (SPF, DMARC, etc.)
foreach ($record in $txtRecords) {
    [PSCustomObject]@{
        Label = $record.Label
        Text = $record.AdditionalProperties['text']
        Service = $record.SupportedService
    }
}
```

#### Get Domain Verification Records

```powershell
# Get verification records for a domain
$verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId "contoso.com"

# Extract TXT verification code
$txtVerification = $verificationRecords |
    Where-Object { $_.AdditionalProperties['recordType'] -eq 'Txt' } |
    Select-Object -First 1

$verificationCode = $txtVerification.AdditionalProperties['text']
Write-Host "Verification TXT Record: $verificationCode"
```

#### Enumerate All Domains and Their DNS Records

```powershell
# Get all verified domains
$verifiedDomains = Get-MgDomain | Where-Object { $_.IsVerified -eq $true }

# Loop through each domain and get DNS records
$allDnsRecords = foreach ($domain in $verifiedDomains) {
    Write-Host "Processing: $($domain.Id)" -ForegroundColor Cyan

    $records = Get-MgDomainServiceConfigurationRecord -DomainId $domain.Id

    foreach ($record in $records) {
        [PSCustomObject]@{
            Domain = $domain.Id
            RecordType = $record.AdditionalProperties['recordType']
            Label = $record.Label
            Service = $record.SupportedService
            TTL = $record.Ttl
            IsOptional = $record.IsOptional
        }
    }
}

# Display summary
$allDnsRecords | Group-Object RecordType |
    Select-Object Name, Count |
    Format-Table -AutoSize

# Export to CSV
$allDnsRecords | Export-Csv -Path "M365-DNS-Records.csv" -NoTypeInformation
```

### 3B: Using the DNS4M365 Module

This repository includes a custom PowerShell module that simplifies the process:

```powershell
# Import the module
Import-Module .\DNS4M365\DNS4M365.psd1

# Connect to Microsoft 365
Connect-M365DNS

# Or connect to specific tenant
Connect-M365DNS -TenantId "00000000-0000-0000-0000-000000000000"

# Get all domains
Get-M365Domain

# Get only verified domains
Get-M365Domain -VerificationStatus Verified

# Get only unverified domains
Get-M365Domain -VerificationStatus Unverified

# Get DNS records for all verified domains
Get-M365DomainDNSRecord

# Get DNS records for a specific domain
Get-M365DomainDNSRecord -DomainName "contoso.com"

# Get only MX records
Get-M365DomainDNSRecord -RecordType MX

# Get only email-related DNS records
Get-M365DomainDNSRecord -ServiceType Email

# Get verification records for unverified domains
Get-M365DomainVerificationRecord

# Test domain verification status
Test-M365DomainVerification

# Export comprehensive report
Export-M365DomainReport -Format All -IncludeUnverified
```

### Advantages

- ✅ Fully automated and scriptable
- ✅ Supports bulk operations
- ✅ Rich filtering and sorting capabilities
- ✅ Easy to export data (CSV, JSON, etc.)
- ✅ Can be scheduled and integrated into workflows
- ✅ No additional API registration needed (uses delegated permissions)

### Limitations

- ❌ Requires PowerShell knowledge
- ❌ Module installation required
- ❌ May require script execution policy changes

---

## Comparison Table

| Feature | Graph API | Admin Center (GUI) | PowerShell |
|---------|-----------|-------------------|------------|
| **Automation** | ✅ Excellent | ❌ Manual only | ✅ Excellent |
| **Ease of Use** | ⚠️ Moderate | ✅ Very Easy | ⚠️ Moderate |
| **Bulk Operations** | ✅ Yes | ❌ No | ✅ Yes |
| **Setup Complexity** | ⚠️ High | ✅ Low | ⚠️ Moderate |
| **Scheduling** | ✅ Yes | ❌ No | ✅ Yes |
| **Export Capability** | ✅ Yes | ⚠️ Limited | ✅ Excellent |
| **Integration** | ✅ Excellent | ❌ None | ✅ Good |
| **Learning Curve** | ⚠️ Steep | ✅ Easy | ⚠️ Moderate |
| **Authentication** | App Registration | User Login | User Login |
| **Use Case** | Automation, CI/CD | Quick checks, Manual tasks | Scripts, Reports |

---

## DNS Record Types Explained

### MX (Mail Exchange)
- **Purpose**: Routes email to Microsoft 365 mail servers
- **Example**: `contoso-com.mail.protection.outlook.com`
- **Priority**: Usually 0 for Microsoft 365

### CNAME (Canonical Name)
- **Purpose**: Aliases for various services (Autodiscover, MDM, Teams, etc.)
- **Examples**:
  - `autodiscover.contoso.com` → `autodiscover.outlook.com`
  - `sip.contoso.com` → `sipdir.online.lync.com`
  - `enterpriseregistration.contoso.com` → `enterpriseregistration.windows.net`

### TXT (Text)
- **Purpose**: Domain verification, SPF, DMARC, DKIM
- **Examples**:
  - SPF: `v=spf1 include:spf.protection.outlook.com -all`
  - DMARC: `v=DMARC1; p=reject; rua=mailto:dmarc@contoso.com`
  - Verification: `MS=ms12345678`

### SRV (Service)
- **Purpose**: Locate services like SIP, Federation
- **Examples**:
  - `_sip._tls.contoso.com` → `sipdir.online.lync.com`
  - `_sipfederationtls._tcp.contoso.com` → `sipfed.online.lync.com`

---

## Important Notes

### API Deprecation Notice

**IMPORTANT**: After February 1st, 2025, the `List serviceConfigurationRecords` Graph API will be the **only source of truth** for Accepted Domains' MX record values. Update any automation to use this API by this date to avoid mail flow issues.

### Required Permissions

- **Read-Only**: `Domain.Read.All`
- **Read/Write**: `Domain.ReadWrite.All`
- **Required Roles**: Domain Name Administrator or Global Reader (minimum)

### Best Practices

1. **Always verify domains** before adding DNS records to production DNS servers
2. **Check DNS propagation** after making changes (can take up to 72 hours)
3. **Document custom records** separately (these APIs only show Microsoft-generated records)
4. **Test in development** environment before production changes
5. **Monitor domain health** regularly using the Admin Center or PowerShell

---

## Additional Resources

- [Microsoft Graph API - Domain Resource Type](https://learn.microsoft.com/en-us/graph/api/resources/domain)
- [Add DNS records at any DNS hosting provider](https://learn.microsoft.com/en-us/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider)
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [DNS4M365 Module Documentation](../README.md)

---

## Support

For issues with:
- **Graph API**: Check Microsoft Graph documentation
- **Admin Center**: Contact Microsoft Support
- **DNS4M365 Module**: See repository issues or documentation
