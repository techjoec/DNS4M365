# Research Finding: MX Records ARE Available via Microsoft Graph API

## Summary

**YES** - MX records are fully supported and returned by `Get-MgDomainServiceConfigurationRecord` (Microsoft Graph API endpoint `/domains/{id}/serviceConfigurationRecords`).

After thorough research of official Microsoft documentation, real-world examples, and community sources, I confirmed that MX records are **reliably available** through the Microsoft Graph API with complete property information.

## Answer to Research Questions

### 1. Are MX records in serviceConfigurationRecords?
**YES** - Confirmed across all sources

### 2. Record Type Name
**"Mx"** (capital M, lowercase x)

### 3. OData Type
**"microsoft.graph.domainDnsMxRecord"**

### 4. MX Record Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (GUID). Not nullable, Read-only. |
| `isOptional` | Boolean | Indicates if required. When `false`, customer must configure the MX record. |
| `label` | String | Value for the alias/host/name of the MX record at DNS host. |
| `mailExchange` | String | The mail server hostname (e.g., "contoso-com.mail.protection.outlook.com"). |
| `preference` | Int32 | MX priority value (lower = higher priority, typically 0 for M365). |
| `recordType` | String | Always "Mx" for MX records. |
| `supportedService` | String | Microsoft service that requires this record (typically "Email"). |
| `ttl` | Int32 | Time-to-live in seconds (typically 3600). |

## Official Microsoft Documentation

### Primary Source: List serviceConfigurationRecords
**URL:** https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords?view=graph-rest-1.0

**API Endpoint:**
```
GET https://graph.microsoft.com/v1.0/domains/{domain-name}/serviceConfigurationRecords
```

**PowerShell Cmdlet:**
```powershell
Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"
```

**Permissions Required:**
- Domain Name Administrator role OR Global Reader role
- Scopes: `Domain.Read.All` or `Domain.ReadWrite.All`

### Example JSON Response

Official Microsoft documentation provides this example:

```json
{
  "@odata.type": "microsoft.graph.domainDnsMxRecord",
  "isOptional": false,
  "label": "contoso.com",
  "recordType": "Mx",
  "supportedService": "Email",
  "ttl": 3600,
  "mailExchange": "contoso-com.mail.protection.outlook.com",
  "preference": 0
}
```

### Resource Type Documentation
**URL:** https://learn.microsoft.com/en-us/graph/api/resources/domaindnsmxrecord?view=graph-rest-1.0

Complete property definitions with data types and descriptions.

## Real-World Examples

### Example 1: TIMMCMIC Blog (May 2024)
**URL:** https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/

**PowerShell Command:**
```powershell
$records = Get-MgDomainServiceConfigurationRecord -DomainId domain.net
```

**MX Record Output:**
```powershell
domain.net

Key          Value
---          -----
@odata.type  #microsoft.graph.domainDnsMxRecord
mailExchange domain-net0c.mail.protection.outlook.com
preference   0
```

**Note:** Properties are in `AdditionalProperties` when using PowerShell cmdlet.

### Example 2: Icewolf Blog (May 2024)
**URL:** https://blog.icewolf.ch/archive/2024/05/06/manage-m365-dns-records-with-powershell/

**Filtering for MX Records:**
```powershell
$M365DNSRecords = Get-MgDomainServiceConfigurationRecord -DomainId icewolf.ch
$M365DNSRecords | where {$_.RecordType -eq "MX"}
$M365DNSRecords | where {$_.RecordType -eq "MX"} | fl
```

Shows MX records can be filtered by `RecordType` property.

### Example 3: PowerShell is Fun (June 2022)
**URL:** https://powershellisfun.com/2022/06/19/retrieve-email-dns-records-using-powershell/

Demonstrates retrieving email DNS records including MX via Graph API.

### Example 4: GitHub - Microsoft Graph Docs
**URL:** https://github.com/microsoftgraph/microsoft-graph-docs/blob/main/api-reference/v1.0/api/domain-list-serviceconfigurationrecords.md

Official source code for the Microsoft Learn documentation showing MX record examples.

## Community Validation

Multiple community sources from 2020-2024 confirm MX records are available:
- Blog posts showing actual output
- GitHub repositories with implementation examples
- Microsoft Q&A forums referencing the endpoint
- PowerShell Gallery modules using this API

## Important Upcoming Change (2025)

**Source:** https://mc.merill.net/message/MC1048624 (Microsoft 365 Message Center)

**Effective Date:** February 1, 2025 (previously October 1, 2024)

**Change:**
- **OLD:** MX records provisioned as `{domain}.mail.protection.outlook.com`
- **NEW:** MX records provisioned as `{domain}.mx.microsoft`

**Impact:**
> "After February 1st, 2025, List serviceConfigurationRecords Graph API will be the **only source of truth** for your Accepted Domains' MX record value."

**Reason:** Support DNSSEC adoption with new infrastructure.

**Action Required:**
Auto-provisioning of MX records must use the List serviceConfigurationRecords Graph API to retrieve the `mailExchange` field as the authoritative source.

## PowerShell Usage Examples

### Basic Retrieval
```powershell
# Connect with required scope
Connect-MgGraph -Scopes "Domain.Read.All"

# Get all service configuration records
$records = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Display all records
$records | Format-Table RecordType, Label

# Filter for MX records only
$mxRecords = $records | Where-Object {$_.RecordType -eq "Mx"}

# Display MX record details
$mxRecords | ForEach-Object {
    [PSCustomObject]@{
        Domain       = $_.Label
        MailExchange = $_.AdditionalProperties.mailExchange
        Preference   = $_.AdditionalProperties.preference
        TTL          = $_.Ttl
        Service      = $_.SupportedService
        Required     = -not $_.IsOptional
    }
}
```

### Access MX Properties
```powershell
# Properties are in AdditionalProperties
foreach ($record in $records) {
    if ($record.RecordType -eq "Mx") {
        $record.Label  # Domain name
        $record.AdditionalProperties  # Contains mailExchange, preference
    }
}
```

### REST API Call
```powershell
# Using Invoke-MgGraphRequest
$response = Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/domains/contoso.com/serviceConfigurationRecords"

# Filter for MX records
$mxRecords = $response.value | Where-Object { $_.'@odata.type' -eq 'microsoft.graph.domainDnsMxRecord' }

# Access properties
$mxRecords | ForEach-Object {
    Write-Host "Mail Exchange: $($_.mailExchange)"
    Write-Host "Preference: $($_.preference)"
}
```

## Record Type Values

The `recordType` property can have these values:
- **"Mx"** - Mail Exchange records
- **"CName"** - Canonical Name records
- **"Srv"** - Service records
- **"Txt"** - Text records

**Note:** Case-sensitive - "Mx" not "MX" or "mx"

## Conditions and Caveats

### When MX Records Are Returned
1. Domain must be added to Microsoft 365 tenant
2. Exchange Online service must be enabled for the domain
3. No special verification required - available for all domains

### When MX Records Are NOT Returned
1. Domain not added to tenant
2. Exchange Online not assigned/enabled
3. API permissions insufficient

### MX Record Characteristics
- **Always required** (`isOptional: false`)
- **supportedService** is always "Email"
- **preference** typically 0 for Microsoft 365
- **mailExchange** is dynamically generated (tenant + domain specific)
- **Cannot be predicted** - must query API for actual value

## Comparison with DKIM Records

**Key Difference:**

| Record Type | Available in Graph API? | Source |
|-------------|------------------------|--------|
| **MX** | YES | serviceConfigurationRecords |
| **DKIM CNAME** | NO | Exchange Online PowerShell only |

MX records are considered core domain service configuration, while DKIM is Exchange-specific configuration requiring `Get-DkimSigningConfig`.

## Impact on DNS4M365 Module

### Positive Findings
- MX records are **fully supported** via Graph API
- Complete property access (mailExchange, preference, ttl)
- Reliable and consistent across all sources
- Official Microsoft recommendation to use Graph API as source of truth

### Validation Capabilities
```powershell
# Example: Validate MX record
function Test-M365MxRecord {
    param([string]$Domain)

    # Get expected MX from Graph API
    $expected = Get-MgDomainServiceConfigurationRecord -DomainId $Domain |
        Where-Object {$_.RecordType -eq "Mx"}

    # Get actual MX from DNS
    $actual = Resolve-DnsName -Name $Domain -Type MX

    # Compare
    if ($actual.NameExchange -eq $expected.AdditionalProperties.mailExchange) {
        Write-Host "MX record correctly configured" -ForegroundColor Green
    } else {
        Write-Warning "MX record mismatch!"
        Write-Host "Expected: $($expected.AdditionalProperties.mailExchange)"
        Write-Host "Actual:   $($actual.NameExchange)"
    }
}
```

### Module Functions Supported
- `Get-M365ExpectedDnsRecord` - CAN retrieve MX records from Graph API
- `Test-M365DnsCompliance` - CAN validate MX records
- `Compare-M365DnsRecord` - CAN compare expected vs actual MX records
- `Export-M365DnsRecordToZoneFile` - CAN include accurate MX records

## Conclusion

**CONFIRMED:** MX records are comprehensively supported in Microsoft Graph API's `serviceConfigurationRecords` endpoint.

**Evidence Quality:**
- Official Microsoft Learn documentation
- Multiple real-world implementations (2022-2024)
- GitHub repository examples
- Community validation
- Microsoft Message Center announcement emphasizing Graph API as source of truth

**Reliability:** HIGH - This is a stable, documented, officially-supported API feature.

**Recommendation:** The DNS4M365 module should use Microsoft Graph API as the authoritative source for expected MX record values, as this is Microsoft's stated direction (especially post-February 2025).

## Additional Resources

- Microsoft Graph SDK: https://learn.microsoft.com/en-us/powershell/microsoftgraph/
- Domain management: https://learn.microsoft.com/en-us/graph/api/resources/domain
- DNS record types: https://learn.microsoft.com/en-us/graph/api/resources/domaindnsrecord

---

**Research Date:** 2025-11-06
**Graph API Version:** v1.0 (stable)
**PowerShell Module:** Microsoft.Graph.Identity.DirectoryManagement 2.0+
