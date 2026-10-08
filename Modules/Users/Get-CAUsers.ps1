function Get-EntraCAUsers {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string[]]$UserIds,
        [int]$BatchSize = 50
    )

    if (-not $UserIds -or $UserIds.Count -eq 0) { return @() }

    $results = @()
    $total = $UserIds.Count
    Write-Host "[..] Resolving $total user(s)..." -ForegroundColor DarkCyan

    for ($i = 0; $i -lt $total; $i += $BatchSize) {
        $batch = $UserIds[$i..([Math]::Min($i + $BatchSize - 1, $total - 1))]
        $filter = ($batch | ForEach-Object { "id eq '$_'" }) -join " or "

        $users = Invoke-EntraCAWithRetry -ScriptBlock {
            Get-MgUser -Filter $filter -All -Property "Id,DisplayName,UserPrincipalName,AccountEnabled" -ErrorAction Stop
        }

        foreach ($u in $users) {
            $results += [PSCustomObject]@{
                Id                = $u.Id
                DisplayName       = $u.DisplayName
                UserPrincipalName = $u.UserPrincipalName
                AccountEnabled    = $u.AccountEnabled
            }
        }
    }

    Write-Host "[OK] Resolved $($results.Count) / $total user(s)." -ForegroundColor Green
    return $results
}
