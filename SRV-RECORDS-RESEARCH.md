# Microsoft Graph API - SRV Records Research

## Research Question
Are SRV records returned by Microsoft Graph API's `Get-MgDomainServiceConfigurationRecord` cmdlet?

**ANSWER: YES ✅**

---

## Executive Summary

**SRV records ARE included in `serviceConfigurationRecords`** returned by Microsoft Graph API. Two SRV records are provided for Teams/Skype for Business federation:

1. **_sip._tls** → sipdir.online.lync.com:443 (⚠️ DEPRECATED for Teams-only tenants as of March 2024)
2. **_sipfederationtls._tcp** → sipfed.online.lync.com:5061 (✅ STILL REQUIRED for federation)

---

## Evidence

### 1. Official Microsoft Graph API Schema

**Source:** https://learn.microsoft.com/en-us/graph/api/resources/domaindnssrvrecord

**Resource Type:** `microsoft.graph.domainDnsSrvRecord`

**Complete Property List:**

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (Read-only) |
| `isOptional` | Boolean | Whether record is required at DNS host |
| `label` | String | Value for configuring the _name_ of SRV record |
| `nameTarget` | String | Value for configuring the _Target_ of SRV record |
| `port` | Int32 | Value for configuring the _port_ of SRV record |
| `priority` | Int32 | Value for configuring the _priority_ of SRV record |
| `protocol` | String | Value for configuring the _protocol_ of SRV record |
| `recordType` | String | Type of DNS record (always "Srv") |
| `service` | String | Value for configuring the _service_ of SRV record |
| `supportedService` | String | Microsoft service dependency (e.g., "OfficeCommunicationsOnline") |
| `ttl` | Int32 | Time-to-live value (not nullable) |
| `weight` | Int32 | Value for configuring the _weight_ of SRV record |

**JSON Schema Example:**
```json
{
  "@odata.type": "microsoft.graph.domainDnsSrvRecord",
  "id": "String (identifier)",
  "isOptional": true,
  "label": "String",
  "nameTarget": "String",
  "port": 1024,
  "priority": 1024,
  "protocol": "String",
  "recordType": "Srv",
  "service": "String",
  "supportedService": "String",
  "ttl": 3600,
  "weight": 1024
}
```

### 2. Real-World PowerShell Output

**Source:** https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/

**Blog Post Date:** May 13, 2024

**Command:**
```powershell
Get-MgDomainServiceConfigurationRecord -DomainId "domain.net"
```

**Output for _sip._tls SRV Record:**
```
_sip._tls.domain.net

Key         Value
---         -----
@odata.type #microsoft.graph.domainDnsSrvRecord
nameTarget  sipdir.online.lync.com
port        443
priority    100
protocol    _tls
service     _sip
weight      1
```

**Output for _sipfederationtls._tcp SRV Record:**
```
_sipfederationtls._tcp.domain.net

Key         Value
---         -----
@odata.type #microsoft.graph.domainDnsSrvRecord
nameTarget  sipfed.online.lync.com
port        5061
priority    100
protocol    _tcp
service     _sipfederationtls
weight      1
```

### 3. Microsoft Community Thread Confirmation

**Source:** https://learn.microsoft.com/en-us/answers/questions/1418720/srv-record-for-sip-federation-record

**Confirmed SRV Record Format:**
```
_sipfederationtls._tcp.domain.com. IN SRV 100 1 5061 sipfed.online.lync.com.
```

**Components:**
- **Priority:** 100
- **Weight:** 1
- **Port:** 5061
- **Target:** sipfed.online.lync.com

---

## SRV Records Breakdown

### Record 1: _sip._tls (DEPRECATED for Teams-only)

**Full DNS Record:**
```
_sip._tls.contoso.com SRV 100 1 443 sipdir.online.lync.com
```

**Properties:**
- **Service:** `_sip`
- **Protocol:** `_tls`
- **Priority:** `100`
- **Weight:** `1`
- **Port:** `443`
- **Target:** `sipdir.online.lync.com`
- **TTL:** `3600` (1 hour)

**Purpose:**
- Secure SIP service discovery
- Enables Teams federation with external organizations
- Required for external Teams chat/calling
- Used for Teams-to-Teams federation

**STATUS as of 2024:**
⚠️ **DEPRECATED for Teams-Only Tenants** (March 2024)

**Source:** https://uclobby.com/2024/03/19/time-to-say-goodbye-to-sipdir-and-webdir/

Quote:
> "With Skype for Business Online decommission the required DNS Records for tenants that are Teams Only changed. Three DNS records are now obsolete:
> - _sip._tls.<SIP Domain> (SRV record)
> - sip.<SIP Domain> (CNAME)
> - lyncdiscover.<SIP Domain> (CNAME)"

### Record 2: _sipfederationtls._tcp (STILL REQUIRED)

**Full DNS Record:**
```
_sipfederationtls._tcp.contoso.com SRV 100 1 5061 sipfed.online.lync.com
```

**Properties:**
- **Service:** `_sipfederationtls`
- **Protocol:** `_tcp`
- **Priority:** `100`
- **Weight:** `1`
- **Port:** `5061`
- **Target:** `sipfed.online.lync.com`
- **TTL:** `3600` (1 hour)

**Purpose:**
- SIP federation over TLS
- Required for federated SIP access
- Enables organization-to-organization federation
- Required for hybrid Skype for Business scenarios
- Used for PSTN calling scenarios

**STATUS as of 2025:**
✅ **STILL REQUIRED** (if federation is enabled)

**When Required:**
- Only if SIP federation is needed
- Must be configured if you need external access
- Enables Teams users to communicate with external organizations

**Validation:**
- Destination MUST match `sipfed.online.lync.com`
- Port MUST be `5061`
- This is a requirement for TeamsOnly tenants configured for federation

---

## Teams-Only Tenant Requirements (2024-2025)

### DNS Records NO LONGER REQUIRED:

After Skype for Business Online retirement (July 2021) and Teams-Only transition (2024):

❌ **CNAME:** `lyncdiscover.<domain>` → webdir.online.lync.com (mobile client login)
❌ **CNAME:** `sip.<domain>` → sipdir.online.lync.com (federation)
❌ **SRV:** `_sip._tls.<domain>` → sipdir.online.lync.com:443 (SIP discovery)

### DNS Records STILL REQUIRED:

✅ **SRV:** `_sipfederationtls._tcp.<domain>` → sipfed.online.lync.com:5061
   - **Required ONLY if federation is enabled**
   - **Can be removed if no external federation needed**

**Critical Note:** While Microsoft Graph API still returns the `_sip._tls` SRV record, it is NO LONGER needed for Teams-Only tenants. This represents a discrepancy between what Graph API provides and what is actually required.

---

## Graph API Behavior

### What Get-MgDomainServiceConfigurationRecord Returns:

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Domain.Read.All"

# Get all service configuration records
$records = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Filter SRV records
$srvRecords = $records | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Srv' }
```

**Expected Output:**
- Returns 2 SRV records (as of 2024)
- Both records are in `microsoft.graph.domainDnsSrvRecord` format
- Properties accessible via `AdditionalProperties` hashtable

**Access Properties:**
```powershell
foreach ($srv in $srvRecords) {
    $service = $srv.AdditionalProperties['service']           # e.g., "_sip"
    $protocol = $srv.AdditionalProperties['protocol']         # e.g., "_tls"
    $priority = $srv.AdditionalProperties['priority']         # e.g., 100
    $weight = $srv.AdditionalProperties['weight']             # e.g., 1
    $port = $srv.AdditionalProperties['port']                 # e.g., 443 or 5061
    $nameTarget = $srv.AdditionalProperties['nameTarget']     # e.g., "sipdir.online.lync.com"
    $ttl = $srv.AdditionalProperties['ttl']                   # e.g., 3600
    $isOptional = $srv.AdditionalProperties['isOptional']     # true/false

    # Construct full FQDN
    $fqdn = "$service.$protocol.contoso.com"

    # Construct SRV record value
    $srvValue = "$priority $weight $port $nameTarget"
}
```

---

## Integration with DNS4M365 Module

### Current Implementation Status:

✅ **Test-M365DnsCompliance** - Validates SRV records (lines 390-425)
✅ **Compare-M365DnsRecord** - Compares expected vs actual SRV records (lines 318-365)
✅ **Export-M365DomainReport** - Counts SRV records (line 150)

**Example from Test-M365DnsCompliance.ps1:**
```powershell
# === SRV RECORDS VALIDATION ===
if ($CheckSRV) {
    $srvRecords = $expectedRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Srv' }
    if ($srvRecords) {
        foreach ($srvRecord in $srvRecords) {
            $srvLabel = $srvRecord.AdditionalProperties['label']
            $expectedTarget = $srvRecord.AdditionalProperties['nameTarget']

            $actualSRV = Invoke-DnsQuery -Name "$srvLabel.$domain" -Type 'SRV'

            if (-not $actualSRV -or $actualSRV.NameTarget -ne $expectedTarget) {
                $srvValid = $false
                $compliance.Issues += "SRV record issue: $srvLabel.$domain"
            }
        }
    }
}
```

**Example from Compare-M365DnsRecord.ps1:**
```powershell
'Srv' {
    $service = $record.AdditionalProperties['service']
    $protocol = $record.AdditionalProperties['protocol']
    $srvFqdn = "$service.$protocol.$domain"

    $priority = $record.AdditionalProperties['priority']
    $weight = $record.AdditionalProperties['weight']
    $port = $record.AdditionalProperties['port']
    $target = $record.AdditionalProperties['nameTarget']

    $comparison.ExpectedValue = "$priority $weight $port $target"

    $actual = Invoke-DnsQuery -Name $srvFqdn -Type SRV
    if ($actual) {
        $comparison.ActualValue = "$($actual.Priority) $($actual.Weight) $($actual.Port) $($actual.NameTarget)"

        if ($actual.NameTarget -eq $target -and $actual.Port -eq $port) {
            $comparison.Status = "Match"
        }
    }
}
```

---

## Recommended Actions for DNS4M365 Module

### 1. Update Documentation

Update `/home/user/DNS4M365/docs/COMPLETE-DNS-RECORDS-REFERENCE.md` to reflect:

- ⚠️ Mark `_sip._tls` SRV record as **DEPRECATED for Teams-Only** (as of March 2024)
- ✅ Confirm `_sipfederationtls._tcp` is **STILL REQUIRED** (if federation enabled)
- Add note: "Graph API still returns _sip._tls but it's not needed for Teams-Only"

### 2. Add Warning in Compare-M365DnsRecord

Consider adding logic to detect Teams-Only tenants and warn about deprecated `_sip._tls`:

```powershell
# If _sip._tls is returned by Graph API but tenant is Teams-Only
if ($srvRecord.AdditionalProperties['service'] -eq '_sip' -and $srvRecord.AdditionalProperties['protocol'] -eq '_tls') {
    Write-Warning "SRV record _sip._tls is deprecated for Teams-Only tenants (March 2024). Consider removing if not using Skype for Business."
}
```

### 3. Update GRAPH-API-DNS-COVERAGE.md

Update the table to clarify SRV record status:

| Record Type | Purpose | Graph Provides | Status for Teams-Only |
|-------------|---------|----------------|----------------------|
| SRV _sip._tls | Teams | ✅ serviceConfigurationRecords | ⚠️ DEPRECATED (March 2024) |
| SRV _sipfederationtls | Teams federation | ✅ serviceConfigurationRecords | ✅ REQUIRED (if federation enabled) |

---

## Validation Examples

### PowerShell DNS Validation:

```powershell
# Check _sip._tls SRV record (deprecated)
Resolve-DnsName _sip._tls.contoso.com -Type SRV

# Expected output (if still present):
# Name                   Type Priority Weight Port NameTarget
# ----                   ---- -------- ------ ---- ----------
# _sip._tls.contoso.com  SRV  100      1      443  sipdir.online.lync.com

# Check _sipfederationtls._tcp SRV record (required)
Resolve-DnsName _sipfederationtls._tcp.contoso.com -Type SRV

# Expected output:
# Name                                  Type Priority Weight Port NameTarget
# ----                                  ---- -------- ------ ---- ----------
# _sipfederationtls._tcp.contoso.com   SRV  100      1      5061 sipfed.online.lync.com
```

### Graph API Query:

```powershell
# Connect to Graph API
Connect-MgGraph -Scopes "Domain.Read.All"

# Get all service configuration records
$allRecords = Get-MgDomainServiceConfigurationRecord -DomainId "contoso.com"

# Filter only SRV records
$srvRecords = $allRecords | Where-Object { $_.AdditionalProperties['recordType'] -eq 'Srv' }

# Display SRV records
$srvRecords | ForEach-Object {
    $props = $_.AdditionalProperties
    [PSCustomObject]@{
        Service    = $props['service']
        Protocol   = $props['protocol']
        Priority   = $props['priority']
        Weight     = $props['weight']
        Port       = $props['port']
        NameTarget = $props['nameTarget']
        TTL        = $props['ttl']
        IsOptional = $props['isOptional']
        FQDN       = "$($props['service']).$($props['protocol']).contoso.com"
        FullRecord = "$($props['priority']) $($props['weight']) $($props['port']) $($props['nameTarget'])"
    }
}
```

**Expected Output:**
```
Service             : _sip
Protocol            : _tls
Priority            : 100
Weight              : 1
Port                : 443
NameTarget          : sipdir.online.lync.com
TTL                 : 3600
IsOptional          : False
FQDN                : _sip._tls.contoso.com
FullRecord          : 100 1 443 sipdir.online.lync.com

Service             : _sipfederationtls
Protocol            : _tcp
Priority            : 100
Weight              : 1
Port                : 5061
NameTarget          : sipfed.online.lync.com
TTL                 : 3600
IsOptional          : False
FQDN                : _sipfederationtls._tcp.contoso.com
FullRecord          : 100 1 5061 sipfed.online.lync.com
```

---

## Summary Table

| Question | Answer |
|----------|--------|
| **Are SRV records in serviceConfigurationRecords?** | ✅ YES |
| **Which specific SRV records?** | `_sip._tls` and `_sipfederationtls._tcp` |
| **Example structure** | `priority weight port nameTarget` (e.g., "100 1 5061 sipfed.online.lync.com") |
| **Required for Teams-only?** | ⚠️ Only `_sipfederationtls._tcp` (and only if federation enabled) |
| **Is _sip._tls still needed?** | ❌ NO - Deprecated March 2024 for Teams-Only tenants |

---

## Evidence URLs

1. **Microsoft Graph API - domainDnsSrvRecord Schema:**
   https://learn.microsoft.com/en-us/graph/api/resources/domaindnssrvrecord

2. **Microsoft Graph API - List serviceConfigurationRecords:**
   https://learn.microsoft.com/en-us/graph/api/domain-list-serviceconfigurationrecords

3. **Real-World PowerShell Example (May 2024):**
   https://timmcmic.wordpress.com/2024/05/13/entraid-office-365-using-graph-powershell-to-list-domain-dns-records/

4. **Teams-Only DNS Changes (March 2024):**
   https://uclobby.com/2024/03/19/time-to-say-goodbye-to-sipdir-and-webdir/

5. **SRV Record Validation (Microsoft Q&A):**
   https://learn.microsoft.com/en-us/answers/questions/1418720/srv-record-for-sip-federation-record

6. **Get-MgDomainServiceConfigurationRecord Cmdlet:**
   https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.directorymanagement/get-mgdomainserviceconfigurationrecord

---

## Conclusion

**SRV records ARE returned by Microsoft Graph API's `Get-MgDomainServiceConfigurationRecord` cmdlet.**

- ✅ Two SRV records are provided: `_sip._tls` and `_sipfederationtls._tcp`
- ✅ Properties include: `priority`, `weight`, `port`, `nameTarget`, `service`, `protocol`
- ⚠️ `_sip._tls` is DEPRECATED for Teams-Only tenants (March 2024)
- ✅ `_sipfederationtls._tcp` is STILL REQUIRED (if federation is enabled)
- ✅ DNS4M365 module correctly implements SRV record validation

**Recommendation:** Update documentation to reflect the March 2024 deprecation of `_sip._tls` for Teams-Only tenants while maintaining backward compatibility for hybrid scenarios.

---

**Research Date:** 2025-01-06
**Last Updated:** 2025-01-06
**Author:** DNS4M365 Research
**Status:** ✅ VALIDATED
