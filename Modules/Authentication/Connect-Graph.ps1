function Connect-EntraCAGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TenantId,
        [Parameter(Mandatory)] [string]$ClientId,
        [Parameter(Mandatory)] [string]$CertificateThumbprint,
        [switch]$SkipHealthCheck
    )

    Write-Host "`n[..] Connecting to Microsoft Graph (app-only)..." -ForegroundColor DarkCyan

    if (-not (Test-EntraCACertificateValidity -Thumbprint $CertificateThumbprint)) {
        throw "Certificate $CertificateThumbprint is missing, expired, or has no private key."
    }

    $existing = Get-MgContext -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "[..] Disconnecting existing Graph session." -ForegroundColor DarkCyan
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    Invoke-EntraCAWithRetry -ScriptBlock {
        Connect-MgGraph `
            -TenantId $TenantId `
            -ClientId $ClientId `
            -CertificateThumbprint $CertificateThumbprint `
            -NoWelcome `
            -ErrorAction Stop
    }

    $ctx = Get-MgContext
    Write-Host "[OK] Connected. Tenant: $($ctx.TenantId) | AppId: $($ctx.ClientId) | AuthType: $($ctx.AuthType)" -ForegroundColor Green

    if (-not $SkipHealthCheck) {
        $health = Test-EntraCAConnectionHealth
        if (-not $health.IsConnected -or $health.AuthType -ne "AppOnly") {
            Write-Host "[WARN] Connection health check failed: $($health.Message)" -ForegroundColor Yellow
        }
    }

    return $ctx
}

function Disconnect-EntraCAGraph {
    [CmdletBinding()]
    param()
    try {
        Disconnect-MgGraph -ErrorAction Stop | Out-Null
        Write-Host "[OK] Disconnected from Microsoft Graph." -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Disconnect reported: $_" -ForegroundColor Yellow
    }
}

function Test-EntraCAGraphConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $ctx = Get-MgContext -ErrorAction Stop
        return ($null -ne $ctx -and $null -ne $ctx.TenantId)
    } catch {
        return $false
    }
}
