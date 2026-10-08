function Assert-EntraCAPermissions {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ClientId,
        [switch]$ThrowOnMissing
    )

    if (-not $ClientId) {
        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $ctx) { throw "No active Graph connection and no -ClientId supplied." }
        $ClientId = $ctx.ClientId
    }

    $required = Get-EntraCARequiredPermissions | Select-Object -ExpandProperty Permission

    Write-Host "[..] Querying app registration for granted permissions..." -ForegroundColor DarkCyan

    try {
        $app = Get-MgApplication -Filter "appId eq '$ClientId'" -ErrorAction Stop
    } catch {
        throw "Failed to query app registration for ClientId $ClientId : $_"
    }

    if (-not $app) { throw "App registration not found for ClientId $ClientId" }

    $requiredResourceAccess = $app.RequiredResourceAccess |
        Where-Object { $_.ResourceAppId -eq "00000003-0000-0000-c000-000000000000" }

    $granted = @()
    foreach ($rra in $requiredResourceAccess) {
        foreach ($scope in $rra.ResourceAccess) {
            if ($scope.Type -eq "Role") {
                $granted += $scope.Id
            }
        }
    }

    # Map scope IDs to names via Microsoft Graph service principal
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
    $idToName = @{}
    if ($graphSp) {
        foreach ($perm in $graphSp.AppRoles) {
            $idToName[$perm.Id] = $perm.Value
        }
    }

    $grantedNames = $granted | ForEach-Object { if ($idToName[$_]) { $idToName[$_] } else { $_ } }

    $missing = $required | Where-Object { $_ -notin $grantedNames }
    $extra   = $grantedNames | Where-Object { $_ -notin $required }

    $status = if ($missing.Count -eq 0) { "OK" } else { "Missing" }

    if ($missing.Count -gt 0) {
        Write-Host "[WARN] Missing permissions:" -ForegroundColor Yellow
        $missing | ForEach-Object { Write-Host "       - $_" -ForegroundColor Yellow }
        if ($ThrowOnMissing) {
            throw "App registration is missing $($missing.Count) required permission(s): $($missing -join ', ')"
        }
    } else {
        Write-Host "[OK] All required permissions granted." -ForegroundColor Green
    }

    [PSCustomObject]@{
        ClientId  = $ClientId
        AppName   = $app.DisplayName
        Required  = $required
        Granted   = $grantedNames
        Missing   = $missing
        Extra     = $extra
        Status    = $status
    }
}
