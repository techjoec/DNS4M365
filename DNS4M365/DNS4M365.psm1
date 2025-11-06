#Requires -Version 5.1

<#
.SYNOPSIS
    DNS4M365 - Microsoft 365 Domain DNS Records Management Module

.DESCRIPTION
    This module provides comprehensive functionality for querying and managing
    Microsoft 365 domain DNS records using Microsoft Graph API.

.NOTES
    Author: DNS4M365 Contributors
    Version: 1.0.0
    Requires: Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement
#>

# Get public and private function definition files
$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Classes = @(Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Classes + $Private + $Public)) {
    try {
        . $import.FullName
        Write-Verbose "Imported: $($import.FullName)"
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName

# Module variables
$script:ModuleVersion = '1.0.0'
$script:GraphScopes = @('Domain.Read.All')
$script:IsConnected = $false

Write-Verbose "DNS4M365 module loaded successfully (v$script:ModuleVersion)"
