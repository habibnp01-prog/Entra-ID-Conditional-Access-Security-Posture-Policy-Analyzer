function Get-EntraCAPolicies {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [ValidateSet("all","enabled","disabled","enabledForReportingButNotEnforced")]
        [string]$State = "all",
        [switch]$RefreshCache
    )

    if (-not (Test-EntraCAGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-EntraCAGraph first."
    }

    Write-Host "[..] Fetching Conditional Access policies..." -ForegroundColor DarkCyan

    $policies = Invoke-EntraCAWithRetry -ScriptBlock {
        Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
    }

    if ($State -ne "all") {
        $policies = $policies | Where-Object { $_.State -eq $State }
    }

    Write-Host "[OK] Retrieved $($policies.Count) policies (filter: $State)." -ForegroundColor Green
    return $policies
}
