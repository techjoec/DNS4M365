# Contributing to DNS4M365

Thank you for your interest in contributing to DNS4M365! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Be patient and understanding
- Respect differing viewpoints and experiences

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior**
- **Actual behavior**
- **PowerShell version** (`$PSVersionTable`)
- **Module version** (`Get-Module DNS4M365`)
- **Operating system**
- **Error messages** (full stack trace if available)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** - why this enhancement would be useful
- **Proposed solution** (if you have one)
- **Alternative solutions** you've considered
- **Examples** of how it would work

### Pull Requests

We welcome pull requests! Here's the process:

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Development Setup

### Prerequisites

1. **PowerShell 5.1 or higher**
   ```powershell
   $PSVersionTable.PSVersion
   ```

2. **Microsoft Graph PowerShell modules**
   ```powershell
   Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
   Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
   ```

3. **Git**
   ```powershell
   git --version
   ```

### Clone the Repository

```powershell
git clone https://github.com/yourusername/DNS4M365.git
cd DNS4M365
```

### Import Module for Development

```powershell
# Import from local directory
Import-Module .\DNS4M365\DNS4M365.psd1 -Force

# Verify import
Get-Module DNS4M365
Get-Command -Module DNS4M365
```

### Testing Your Changes

```powershell
# Connect to a test tenant
Connect-M365DNS -TenantId "your-test-tenant-id"

# Test your changes
Get-M365Domain
Get-M365DomainDNSRecord

# Test with verbose output
Get-M365Domain -Verbose
```

## Coding Standards

### PowerShell Best Practices

1. **Function Naming**
   - Use approved PowerShell verbs: `Get-Verb`
   - Format: `Verb-NounQualifier` (e.g., `Get-M365Domain`)
   - All exported functions should start with approved verbs

2. **Parameter Naming**
   - Use PascalCase for parameters
   - Be descriptive but concise
   - Use standard parameter names where applicable:
     - `Path` for file system paths
     - `Name` for names
     - `Id` for identifiers

3. **Comment-Based Help**
   - All public functions must have complete help
   - Include: SYNOPSIS, DESCRIPTION, PARAMETERS, EXAMPLES, OUTPUTS
   ```powershell
   <#
   .SYNOPSIS
       Brief description

   .DESCRIPTION
       Detailed description

   .PARAMETER ParameterName
       Parameter description

   .EXAMPLE
       Example usage

   .OUTPUTS
       Output type description
   #>
   ```

4. **Error Handling**
   - Use try/catch blocks for operations that might fail
   - Provide informative error messages
   - Use `Write-Error` for errors
   - Use `Write-Warning` for warnings
   - Use `Write-Verbose` for detailed logging

5. **Parameter Validation**
   ```powershell
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]$DomainName

   [Parameter(Mandatory = $false)]
   [ValidateSet('CSV', 'JSON', 'HTML')]
   [string]$Format = 'CSV'
   ```

6. **Output**
   - Return objects, not formatted text
   - Use `[PSCustomObject]` for structured output
   - Don't use `Write-Host` for output data (only for user messages)

### Code Style

1. **Indentation**: 4 spaces (no tabs)
2. **Line Length**: Keep under 120 characters when possible
3. **Braces**: Opening brace on same line
   ```powershell
   if ($condition) {
       # code
   }
   ```

4. **Spacing**:
   ```powershell
   # Good
   $variable = Get-Something -Parameter "value"

   # Bad
   $variable=Get-Something -Parameter "value"
   ```

5. **Variable Naming**:
   - Use descriptive names
   - Use PascalCase for script-level variables
   - Use camelCase for local variables

### File Organization

```
DNS4M365/
├── DNS4M365/
│   ├── Public/           # Exported functions (one function per file)
│   ├── Private/          # Internal helper functions
│   ├── Classes/          # Class definitions
│   ├── DNS4M365.psd1     # Module manifest
│   └── DNS4M365.psm1     # Main module file
├── Examples/             # Usage examples
├── docs/                 # Documentation
└── Tests/                # Pester tests (future)
```

## Submitting Changes

### Commit Messages

Follow conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(domains): add support for filtering by authentication type

Add new parameter -AuthenticationType to Get-M365Domain function
to allow filtering domains by Managed or Federated authentication.

Closes #123
```

```
fix(connection): handle expired tokens gracefully

Previously, expired tokens would throw unhandled exceptions.
Now we catch the exception and prompt for re-authentication.

Fixes #456
```

### Pull Request Process

1. **Update Documentation**
   - Update README.md if needed
   - Update CHANGELOG.md
   - Update function help

2. **Test Your Changes**
   - Test all affected functions
   - Test edge cases
   - Test error conditions

3. **Create Pull Request**
   - Use a clear, descriptive title
   - Reference related issues
   - Describe what changed and why
   - Include examples if applicable

4. **Pull Request Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   Describe how you tested your changes

   ## Related Issues
   Closes #123

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-reviewed the code
   - [ ] Commented complex code
   - [ ] Updated documentation
   - [ ] Updated CHANGELOG.md
   - [ ] No new warnings generated
   - [ ] Added tests (if applicable)
   ```

## Project Structure Details

### Public Functions

Functions in `DNS4M365/Public/` are automatically exported. Each function should:
- Be in its own .ps1 file
- Have complete comment-based help
- Include parameter validation
- Include verbose logging
- Handle errors gracefully

### Private Functions

Functions in `DNS4M365/Private/` are internal helpers. They should:
- Be used by public functions
- Still have basic help comments
- Follow the same coding standards

### Module Manifest

When adding new functions, update `DNS4M365.psd1`:
```powershell
FunctionsToExport = @(
    'Connect-M365DNS',
    'Get-M365Domain',
    'Your-NewFunction'  # Add here
)
```

## Testing Guidelines

### Manual Testing

```powershell
# Import latest version
Import-Module .\DNS4M365\DNS4M365.psd1 -Force

# Test each function
Connect-M365DNS
Get-M365Domain
Get-M365DomainDNSRecord
# ... etc
```

### Future: Pester Tests

We plan to add Pester tests. When implemented:
```powershell
# Run all tests
Invoke-Pester

# Run specific test
Invoke-Pester -Path .\Tests\Get-M365Domain.Tests.ps1
```

## Documentation

### Updating Documentation

When making changes that affect usage:

1. **README.md**: Update examples and feature lists
2. **QUICK-GUIDE.md**: Update method-specific documentation
3. **CHANGELOG.md**: Add entry under [Unreleased]
4. **Function Help**: Update comment-based help in function files

### Writing Good Documentation

- Be clear and concise
- Include practical examples
- Explain the "why" not just the "how"
- Keep it up to date with code changes

## Need Help?

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue
- **Security Issues**: See SECURITY.md (if applicable)

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- CHANGELOG.md

Thank you for contributing to DNS4M365!
