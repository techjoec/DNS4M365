# DNS4M365 v1.2.0 Implementation Plan

## Feature Requests Summary

### 1. DNS Resolver Configuration
- [ ] Support DoH (DNS-over-HTTPS) - **PARTIAL** (Google only)
- [ ] Support DoT (DNS-over-TLS) - **TODO**
- [ ] Support Standard DNS - **TODO**
- [ ] Configurable DNS server (default: Google DoH)
- [ ] Multiple DoH providers: Google, Cloudflare, Quad9
- [ ] Module-level configuration with per-call override

### 2. Authoritative Nameserver Queries
- [ ] Query authoritative NS for domain
- [ ] Compare authoritative vs public resolver results
- [ ] Automatic NS discovery via SOA/NS records

### 3. Watch Mode (DNS Propagation Monitoring)
- [ ] Monitor DNS records for changes
- [ ] Iterate every X seconds (default: 30s)
- [ ] Use case: Wait for DNS propagation after making changes
- [ ] Alert when record changes detected
- [ ] New function: `Watch-M365DomainDNS`

### 4. Diff Mode (Change Detection)
- [ ] Compare current state vs baseline/previous state
- [ ] Output only new/missing/changed records
- [ ] Use case: Weekly audits showing what changed
- [ ] Baseline storage (JSON/XML file)
- [ ] New function or parameter: `-DiffMode`, `-BaselineFile`

### 5. Record Type Filtering
- [ ] Accept array of record types to check
- [ ] Example: `-RecordTypes @('MX','TXT','CNAME')`
- [ ] Filter what gets queried/compared

### 6. Custom Record Support
- [ ] Allow admins to define required custom records
- [ ] Example: Custom SRV records for environment
- [ ] Configuration via parameters or config file
- [ ] Format: `@{Name='_custom._tcp.domain.com'; Type='SRV'; Expected='...'}`

### 7. PTR Record Support
- [ ] Add PTR record type support
- [ ] Reverse DNS lookups
- [ ] Add to all query functions

### 8. Multiple Output Formats
- [ ] **Screen**: Colorized PowerShell output (current)
- [ ] **JSON**: Structured JSON output
- [ ] **XML**: XML output
- [ ] **HTML**: Formatted HTML reports
- [ ] Parameter: `-OutputFormat` with values: Screen, JSON, XML, HTML

### 9. Standard PowerShell Patterns
- [ ] `-PassThru`: Return objects for pipeline
- [ ] `-Verbose`: Detailed logging (already supported)
- [ ] `-WhatIf`: Preview mode for changes
- [ ] `-Confirm`: Confirmation prompts
- [ ] Pipeline support (already supported)
- [ ] Standard error handling

---

## Implementation Phases

### Phase 1: DNS Infrastructure Enhancement (CURRENT)
**Priority: HIGH**
**Timeline: Immediate**

Files to create/modify:
1. `Private/Initialize-DnsConfig.ps1` - ✅ CREATED
2. `Private/Resolve-DnsQuery.ps1` - ✅ CREATED
3. `Private/Resolve-DnsOverHttps.ps1` - ENHANCE (add Server parameter, multiple providers)
4. `Private/Resolve-DnsStandard.ps1` - CREATE (wrapper for Resolve-DnsName)
5. `Private/Get-AuthoritativeNameserver.ps1` - CREATE

### Phase 2: PTR and Record Type Filtering
**Priority: HIGH**
**Timeline: Immediate**

Enhancements:
1. Add PTR to all Type ValidateSets
2. Add PTR parsing to Resolve-DnsOverHttps
3. Add `-RecordTypes` parameter to health/readiness functions
4. Filter queries based on RecordTypes array

### Phase 3: Output Formats and PassThru
**Priority: HIGH**
**Timeline: Immediate**

Enhancements:
1. Add `-OutputFormat` parameter to all public functions
2. Add `-PassThru` parameter to return objects
3. Create `Private/Format-DnsOutput.ps1` helper
4. Implement JSON/XML/HTML formatters
5. Colorized console output helper

### Phase 4: Watch Mode (DNS Propagation Monitor)
**Priority: MEDIUM**
**Timeline: Next**

New function: `Watch-M365DomainDNS`
```powershell
Watch-M365DomainDNS -DomainName "contoso.com" -RecordTypes @('MX','TXT') `
    -CompareAuthoritativeNS -Interval 30 -MaxWait 1800
```

Features:
- Query public resolver AND authoritative NS
- Compare results
- Loop every X seconds
- Display changes in real-time
- Alert when propagation complete
- Timeout after MaxWait seconds

### Phase 5: Diff Mode (Change Detection)
**Priority: MEDIUM**
**Timeline: Next**

Enhancement to `Compare-M365DomainDNS`:
```powershell
Compare-M365DomainDNS -DomainName "contoso.com" -DiffMode `
    -BaselineFile "C:\Baselines\contoso-baseline.json"
```

New function: `Export-M365DomainBaseline`
```powershell
Export-M365DomainBaseline -DomainName "contoso.com" `
    -OutputPath "C:\Baselines\contoso-baseline.json"
```

Features:
- Save current state as baseline
- Compare current vs baseline
- Output only differences
- Report: Added, Removed, Changed records

### Phase 6: Custom Record Support
**Priority: LOW**
**Timeline: Future**

New parameter for readiness/health functions:
```powershell
$customRecords = @(
    @{Name='_sip._tcp.contoso.com'; Type='SRV'; Priority=10; Port=5060; Target='sip.contoso.com'},
    @{Name='custom.contoso.com'; Type='CNAME'; Target='target.example.com'}
)

Get-M365DomainReadiness -DomainName "contoso.com" -CustomRecords $customRecords
```

Features:
- Define required custom records
- Validate presence and correctness
- Include in compliance scoring
- Support all record types

---

## Technical Debt / Cleanup
- Refactor existing functions to use Resolve-DnsQuery uniformly
- Update all functions to support new parameters
- Comprehensive error handling
- Performance optimization for bulk queries
- Unit tests (Pester)

---

## Breaking Changes Assessment

### None Expected
All new features are additive:
- New optional parameters
- New functions (don't break existing)
- Default behavior unchanged
- Existing scripts continue to work

---

## Documentation Updates Needed

1. README.md - Add new features to overview
2. CHANGELOG.md - Document v1.2.0 changes
3. Examples/ - Add examples for new features
4. Function help - Update with new parameters
5. Quick guide - Add watch mode and diff mode examples

---

## Testing Plan

1. **Unit Tests**: Test each DNS resolver independently
2. **Integration Tests**: Test end-to-end scenarios
3. **Performance Tests**: Bulk domain queries
4. **Real-World Tests**: Test against live M365 domains

Test Scenarios:
- DoH with Google, Cloudflare, Quad9
- Standard DNS with 8.8.8.8, 1.1.1.1
- Authoritative NS queries
- Watch mode during actual DNS change
- Diff mode detecting added/removed records
- Custom records validation
- All output formats
- PassThru pipeline scenarios

---

## Priority Order (Suggested)

1. **Immediate** (Phase 1-3):
   - Complete DNS resolver infrastructure
   - Add PTR support
   - Add output formats and PassThru
   - Add RecordTypes filtering

2. **Next Sprint** (Phase 4):
   - Watch mode function

3. **Following Sprint** (Phase 5):
   - Diff mode

4. **Future** (Phase 6):
   - Custom records

---

## Estimated Complexity

- **Phase 1**: 4-6 hours (infrastructure)
- **Phase 2**: 2-3 hours (PTR and filtering)
- **Phase 3**: 3-4 hours (output formats)
- **Phase 4**: 4-6 hours (watch mode)
- **Phase 5**: 3-4 hours (diff mode)
- **Phase 6**: 2-3 hours (custom records)

**Total**: ~20-25 hours of development

---

## Current Status

✅ Phase 1: 30% complete
- DNS config system created
- Unified resolver function created
- Need: Enhanced DoH, Standard DNS, Auth NS

⏳ Phase 2: Not started
⏳ Phase 3: Not started
⏳ Phase 4: Not started
⏳ Phase 5: Not started
⏳ Phase 6: Not started

---

## Next Steps

1. Complete DNS resolver infrastructure
2. Add PTR support to all functions
3. Implement output format system
4. Create watch mode function
5. Add diff mode capability
6. Implement custom records

This is a substantial v1.2.0 release with powerful new monitoring and validation capabilities.
