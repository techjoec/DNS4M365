function Test-GraphConnection {
    <#
    .SYNOPSIS
        Internal helper function to test Microsoft Graph connection.

    .DESCRIPTION
        Verifies that a valid Microsoft Graph connection exists and that required
        scopes are available.

    .PARAMETER RequiredScopes
        Optional array of required scopes to check.

    .OUTPUTS
        Boolean - True if connected with required scopes, False otherwise.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredScopes
    )

    try {
        $context = Get-MgContext

        if (-not $context) {
            Write-Verbose "No Microsoft Graph connection found"
            return $false
        }

        Write-Verbose "Connected to tenant: $($context.TenantId)"
        Write-Verbose "Connected as: $($context.Account)"

        # Check required scopes if specified
        if ($RequiredScopes) {
            $currentScopes = $context.Scopes
            $missingScopes = @()

            foreach ($scope in $RequiredScopes) {
                if ($currentScopes -notcontains $scope) {
                    $missingScopes += $scope
                }
            }

            if ($missingScopes.Count -gt 0) {
                Write-Warning "Missing required scopes: $($missingScopes -join ', ')"
                return $false
            }
        }

        return $true
    }
    catch {
        Write-Verbose "Error checking Graph connection: $_"
        return $false
    }
}
