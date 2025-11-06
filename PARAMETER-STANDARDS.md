# PowerShell Parameter Best Practices Research - DNS4M365

## Research Sources
1. PSScriptAnalyzer rules (https://github.com/PowerShell/PSScriptAnalyzer)
2. Microsoft.Graph.* modules (official Microsoft implementation)
3. DnsClient module (built-in Windows PowerShell)
4. ActiveDirectory module (Microsoft best practices)
5. PowerShell Best Practices and Style Guide
6. Microsoft PowerShell Documentation Standards

---

## KEY FINDINGS - Parameter Naming Conventions

### 1. SINGULAR vs PLURAL
✅ **RULE**: Parameter names are SINGULAR even when accepting arrays
```powershell
# CORRECT
[string[]]$ComputerName

# WRONG
[string[]]$ComputerNames
```

**Source**: Microsoft.Graph, ActiveDirectory, DnsClient all use singular
- `Get-ADUser -Identity` (not -Identities)
- `Resolve-DnsName -Name` (not -Names)
- `Get-MgUser -UserId` (not -UserIds)

### 2. COMMON PARAMETER NAMES (Standardized Across PowerShell)

**Identity/Name Parameters**:
- `-Identity` - Primary identifier (AD modules use this)
- `-Name` - For named objects (DNS, files, services)
- `-Id` - For GUIDs/numeric IDs
- **DO NOT MIX**: Pick one pattern and stick to it

**Path Parameters**:
- `-Path` - File system paths (NOT -OutputPath, -FilePath)
- `-LiteralPath` - For paths with wildcards

**Server/Target Parameters**:
- `-Server` - DNS server, domain controller, etc. (singular even if array)
- `-ComputerName` - Target computers

**Time Parameters**:
- `-Timeout` - Maximum wait time
- `-Interval` - Repeat interval
- `-Duration` - Time span

**Filter Parameters**:
- `-Filter` - Query filter (not -Where)
- `-RecordType` - Type of record (singular)

**Output Parameters**:
- `-Force` - Override prompts/overwrite files
- `-PassThru` - Return objects to pipeline
- `-OutVariable` - Store output in variable (common parameter)

### 3. PARAMETER SETS (Mutually Exclusive Options)

Use Parameter Sets for mutually exclusive scenarios:
```powershell
[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(ParameterSetName = 'ByName')]
    [string]$Name,

    [Parameter(ParameterSetName = 'ById')]
    [guid]$Id
)
```

**Common Sets**:
- `ByName` / `ById` / `ByObject`
- `File` / `String` / `Object`
- `Interactive` / `NonInteractive`

### 4. PIPELINE SUPPORT

**ValueFromPipeline** - Accept entire objects:
```powershell
[Parameter(ValueFromPipeline = $true)]
[Microsoft.Graph.PowerShell.Models.Domain]$Domain
```

**ValueFromPipelineByPropertyName** - Accept object properties:
```powershell
[Parameter(ValueFromPipelineByPropertyName = $true)]
[Alias('DomainName', 'Id')]
[string]$Name
```

**BOTH** - Maximum flexibility:
```powershell
[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
```

### 5. VALIDATION ATTRIBUTES (Use Built-in)

```powershell
[ValidateSet('DoH', 'DoT', 'Standard')]          # Enum values
[ValidateRange(1, 3600)]                          # Numeric range
[ValidateNotNullOrEmpty()]                        # Required value
[ValidateScript({Test-Path $_})]                  # Custom validation
[ValidatePattern('^[a-z0-9\-\.]+$')]             # Regex pattern
[ValidateLength(1, 255)]                          # String length
[ValidateCount(1, 10)]                            # Array count
```

### 6. ALIAS USAGE

Use `[Alias()]` for backward compatibility or common alternate names:
```powershell
[Parameter()]
[Alias('DomainName', 'Domain', 'DN')]
[string]$Name
```

**Common Aliases**:
- `Name` → `DomainName`, `DN`
- `ComputerName` → `CN`, `Computer`, `Server`
- `Path` → `PSPath`, `FilePath`

### 7. SWITCH PARAMETERS (Boolean Flags)

```powershell
[Parameter()]
[switch]$PassThru    # NOT [bool]$PassThru

# Usage:
Get-Something -PassThru           # True
Get-Something -PassThru:$false    # Explicit false
```

**Common Switches**:
- `-Force` - Skip confirmations
- `-PassThru` - Return objects
- `-Recurse` - Recursive operations
- `-WhatIf` - Preview mode (SupportsShouldProcess)
- `-Confirm` - Prompt for confirmation

---

## COMMENT-BASED HELP STRUCTURE

### MANDATORY SECTIONS
```powershell
<#
.SYNOPSIS
    One-line description (under 80 characters)

.DESCRIPTION
    Detailed description of what the function does. Can be multiple paragraphs.
    Explain the purpose, when to use it, and what problems it solves.

.PARAMETER ParameterName
    Description of this parameter. What it does, what values it accepts,
    and any special considerations.

.EXAMPLE
    CommandName -Parameter Value

    Description of what this example does and expected output.

.EXAMPLE
    CommandName -AnotherParam Value | CommandName2

    Another example showing pipeline usage.

.INPUTS
    What types of objects can be piped to this function.
    Example: System.String, Microsoft.Graph.PowerShell.Models.Domain

.OUTPUTS
    What types of objects this function outputs.
    Example: System.Management.Automation.PSCustomObject

.NOTES
    Additional information (author, version, requirements, etc.)
    File Name  : FunctionName.ps1
    Requires   : PowerShell 5.1+, Microsoft.Graph module

.LINK
    Related commands or documentation URLs
    https://docs.microsoft.com/powershell/module/...
#>
```

### BEST PRACTICES FOR HELP

1. **SYNOPSIS**: Must be ONE LINE, under 80 characters
2. **DESCRIPTION**: Start with verb, explain purpose clearly
3. **PARAMETER**: Document EVERY parameter, even obvious ones
4. **EXAMPLE**: Minimum 2 examples, preferably 3-5
5. **INPUTS/OUTPUTS**: Always specify object types
6. **NOTES**: Include prerequisites, version info
7. **LINK**: Add related cmdlets and documentation

---

## COMMON PARAMETER PATTERNS BY CMDLET TYPE

### Get-* Cmdlets
```powershell
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('DomainName', 'Id')]
    [string[]]$Name,

    [Parameter()]
    [ValidateSet('All', 'Verified', 'Unverified')]
    [string]$Status = 'All',

    [Parameter()]
    [switch]$IncludeDetail
)
```

### Set-* Cmdlets
```powershell
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$Name,

    [Parameter()]
    [ValidateSet('DoH', 'DoT', 'Standard')]
    [string]$ResolverType,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$PassThru
)
```

### Test-* Cmdlets
```powershell
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter()]
    [int]$Timeout = 300,

    [Parameter()]
    [switch]$Quiet  # Return $true/$false instead of object
)
```

### Watch-* Cmdlets
```powershell
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter()]
    [ValidateRange(1, 3600)]
    [int]$Interval = 30,

    [Parameter()]
    [ValidateRange(1, 86400)]
    [int]$Timeout = 1800,

    [Parameter()]
    [string[]]$Server = @('8.8.8.8', '1.1.1.1')
)
```

### Compare-* Cmdlets
```powershell
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Alias('Reference')]
    [object]$ReferenceObject,

    [Parameter(Mandatory = $true, Position = 1)]
    [Alias('Difference')]
    [object]$DifferenceObject,

    [Parameter()]
    [string[]]$Property,

    [Parameter()]
    [switch]$IncludeEqual,

    [Parameter()]
    [switch]$ExcludeDifferent
)
```

### Export-* Cmdlets
```powershell
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter()]
    [ValidateSet('Json', 'Xml', 'Html', 'Csv')]
    [string]$Format = 'Json',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$PassThru
)
```

---

## SPECIFIC PARAMETER DECISIONS FOR DNS4M365

### Domain/Name Parameter
✅ **DECISION**: Use `-Name` (not -DomainName, not -Domain)
- Follows `Resolve-DnsName -Name` pattern
- Shorter, cleaner
- Use `[Alias('DomainName', 'Domain')]` for compatibility

### Record Type Parameter
✅ **DECISION**: Use `-RecordType` (singular, array support)
```powershell
[Parameter()]
[ValidateSet('A', 'AAAA', 'MX', 'CNAME', 'TXT', 'SRV', 'NS', 'PTR', 'SOA')]
[string[]]$RecordType
```

### DNS Server Parameter
✅ **DECISION**: Use `-Server` (singular, array support)
```powershell
[Parameter()]
[string[]]$Server = @('8.8.8.8', '1.1.1.1', '9.9.9.9')
```

### Resolver Type Parameter
✅ **DECISION**: Use `-ResolverType`
```powershell
[Parameter()]
[ValidateSet('DoH', 'DoT', 'Standard')]
[string]$ResolverType = 'DoH'
```

### Output Format Parameter
✅ **DECISION**: Use `-OutputFormat` (not -Format, clearer intent)
```powershell
[Parameter()]
[ValidateSet('Screen', 'Json', 'Xml', 'Html', 'Csv')]
[string]$OutputFormat = 'Screen'
```

### Path Parameter
✅ **DECISION**: Use `-Path` (standard, not -OutputPath or -FilePath)
```powershell
[Parameter()]
[ValidateScript({Test-Path (Split-Path $_) -IsValid})]
[string]$Path
```

### Time Parameters
✅ **DECISION**:
- `-Interval` for repeat timing (seconds)
- `-Timeout` for maximum wait (seconds)
```powershell
[ValidateRange(1, 3600)]
[int]$Interval = 30

[ValidateRange(1, 86400)]
[int]$Timeout = 1800
```

---

## PARAMETER ATTRIBUTE TEMPLATE

```powershell
[CmdletBinding(
    DefaultParameterSetName = 'Default',
    SupportsShouldProcess = $true,      # For Set-/Remove-/New- cmdlets
    ConfirmImpact = 'Medium',           # Low/Medium/High
    HelpUri = 'https://...'             # Link to online help
)]
[OutputType([PSCustomObject])]          # What the function returns
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,                    # First positional parameter
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Default',
        HelpMessage = 'Enter domain name'
    )]
    [ValidateNotNullOrEmpty()]
    [Alias('DomainName', 'DN')]
    [string[]]$Name
)
```

---

## QUALITY CHECKLIST

### Every Function MUST Have:
- [ ] `[CmdletBinding()]` attribute
- [ ] Comment-based help with all sections
- [ ] Proper verb from approved list
- [ ] Singular parameter names
- [ ] Validation attributes where appropriate
- [ ] Pipeline support where relevant
- [ ] At least 2 examples in help
- [ ] `.INPUTS` and `.OUTPUTS` documentation
- [ ] Error handling with meaningful messages
- [ ] `-Verbose` output for debugging
- [ ] `-WhatIf` support for state-changing cmdlets

### Parameter Quality:
- [ ] Descriptive names (not abbreviations)
- [ ] Consistent with ecosystem (Server, not DNSServer)
- [ ] Appropriate defaults
- [ ] Validation on all inputs
- [ ] HelpMessage for mandatory parameters
- [ ] Aliases for common alternate names

### Help Quality:
- [ ] Synopsis under 80 characters
- [ ] Description explains purpose and use cases
- [ ] Every parameter documented
- [ ] Examples show common scenarios
- [ ] Examples show pipeline usage
- [ ] Examples include expected output
- [ ] Links to related commands

---

## ANTI-PATTERNS TO AVOID

❌ **DON'T**:
- Use abbreviations: `-DNS`, `-NS`, `-RR` (use full words)
- Use plural parameter names: `-Names`, `-Servers`
- Use generic names: `-Value`, `-Data`, `-Object` (be specific)
- Mix naming styles: Some `-DomainName`, some `-Name`
- Skip help documentation
- Use [bool] instead of [switch]
- Hard-code paths or servers
- Ignore pipeline support
- Return inconsistent object types

✅ **DO**:
- Use full words: `-DnsRecord`, `-Nameserver`, `-ResourceRecord`
- Use singular: `-Name`, `-Server`, `-RecordType`
- Be specific: `-DnsRecord`, `-DomainName`, `-RecordData`
- Be consistent across all functions
- Document everything
- Use [switch] for flags
- Make things configurable
- Support pipeline where appropriate
- Return consistent PSCustomObjects

---

## CONCLUSION

DNS4M365 will follow these standards:
1. All parameters use singular names
2. Common parameters use ecosystem standards (Server, Name, Path)
3. All functions have comprehensive comment-based help
4. Pipeline support on all Get-* cmdlets
5. Validation attributes on all inputs
6. Consistent parameter naming across module
7. PassThru support on state-changing cmdlets
8. SupportsShouldProcess for destructive operations

This ensures DNS4M365 feels native to PowerShell and integrates seamlessly
with existing modules and admin workflows.
