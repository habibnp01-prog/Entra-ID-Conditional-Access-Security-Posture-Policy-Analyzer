function Test-EntraCAConnectionHealth {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $result = [PSCustomObject]@{
        IsConnected  = $false
        AuthType     = $null
        TenantId     = $null
        ClientId     = $null
        Scopes       = @()
        Message      = $null
    }

    try {
        $ctx = Get-MgContext -ErrorAction Stop
    } catch {
        $result.Message = "No active Microsoft Graph session."
        return $result
    }

    if (-not $ctx) {
        $result.Message = "Get-MgContext returned null."
        return $result
    }

    $result.IsConnected = $true
    $result.AuthType    = $ctx.AuthType
    $result.TenantId    = $ctx.TenantId
    $result.ClientId    = $ctx.ClientId
    $result.Scopes      = $ctx.Scopes

    if ($ctx.AuthType -ne "AppOnly") {
        $result.Message = "Connection is not AppOnly. Actual: $($ctx.AuthType)"
    } else {
        $result.Message = "OK"
    }

    return $result
}
