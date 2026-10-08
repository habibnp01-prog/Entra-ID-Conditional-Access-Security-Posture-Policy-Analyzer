function Get-EntraCAGroups {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string[]]$GroupIds,
        [int]$BatchSize = 50
    )

    if (-not $GroupIds -or $GroupIds.Count -eq 0) { return @() }

    $results = @()
    $total = $GroupIds.Count
    Write-Host "[..] Resolving $total group(s)..." -ForegroundColor DarkCyan

    for ($i = 0; $i -lt $total; $i += $BatchSize) {
        $batch = $GroupIds[$i..([Math]::Min($i + $BatchSize - 1, $total - 1))]
        $filter = ($batch | ForEach-Object { "id eq '$_'" }) -join " or "

        $groups = Invoke-EntraCAWithRetry -ScriptBlock {
            Get-MgGroup -Filter $filter -All -Property "Id,DisplayName,Description,SecurityEnabled" -ErrorAction Stop
        }

        foreach ($g in $groups) {
            $results += [PSCustomObject]@{
                Id              = $g.Id
                DisplayName     = $g.DisplayName
                Description     = $g.Description
                SecurityEnabled = $g.SecurityEnabled
            }
        }
    }

    Write-Host "[OK] Resolved $($results.Count) / $total group(s)." -ForegroundColor Green
    return $results
}
