function Connect-M365DNS {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph with required permissions for DNS record management.

    .DESCRIPTION
        Establishes a connection to Microsoft Graph API with the necessary scopes
        to query domain DNS records in Microsoft 365.

    .PARAMETER TenantId
        The Tenant ID (GUID) of the Microsoft 365 organization.
        If not specified, you'll be prompted to select a tenant during authentication.

    .PARAMETER Scopes
        Custom scopes to request. Default is 'Domain.Read.All'.
        For write operations, use 'Domain.ReadWrite.All'.

    .PARAMETER UseDeviceCode
        Use device code flow for authentication (useful for headless scenarios).

    .EXAMPLE
        Connect-M365DNS
        Connects to Microsoft Graph with default scopes using interactive authentication.

    .EXAMPLE
        Connect-M365DNS -TenantId "00000000-0000-0000-0000-000000000000"
        Connects to a specific tenant by GUID.

    .EXAMPLE
        Connect-M365DNS -Scopes "Domain.ReadWrite.All" -UseDeviceCode
        Connects with write permissions using device code flow.

    .OUTPUTS
        System.Boolean - Returns $true if connection successful, $false otherwise.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [string[]]$Scopes = @('Domain.Read.All'),

        [Parameter(Mandatory = $false)]
        [switch]$UseDeviceCode
    )

    begin {
        Write-Verbose "Initiating connection to Microsoft Graph"
    }

    process {
        try {
            $connectParams = @{
                Scopes = $Scopes
                NoWelcome = $true
            }

            if ($TenantId) {
                $connectParams['TenantId'] = $TenantId
                Write-Verbose "Connecting to tenant: $TenantId"
            }

            if ($UseDeviceCode) {
                $connectParams['UseDeviceCode'] = $true
                Write-Verbose "Using device code authentication flow"
            }

            # Connect to Microsoft Graph
            Connect-MgGraph @connectParams -ErrorAction Stop

            # Verify connection
            $context = Get-MgContext

            if ($context) {
                Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
                Write-Host "Tenant ID: $($context.TenantId)" -ForegroundColor Cyan
                Write-Host "Account: $($context.Account)" -ForegroundColor Cyan
                Write-Host "Scopes: $($context.Scopes -join ', ')" -ForegroundColor Cyan

                $script:IsConnected = $true
                return $true
            }
            else {
                Write-Warning "Connection established but unable to retrieve context"
                return $false
            }
        }
        catch {
            Write-Error "Failed to connect to Microsoft Graph: $_"
            $script:IsConnected = $false
            return $false
        }
    }
}
