function Invoke-EntraCALocationAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @()
    )

    Write-Host "[..] Analyzing location conditions..." -ForegroundColor DarkCyan
    $out = @()

    foreach ($p in @($Policies)) {
        if ($p.State -ne "enabled") { continue }
        $d = Get-EntraCAPolicyDetails -Policy $p
        $namedLocations = @($d.Locations | Where-Object { $_ -ne "All" -and $_ -ne "AllTrusted" })
        $hasNamed = $namedLocations.Count -gt 0
        $hasExcluded = @($d.ExcludeLocations).Count -gt 0
        if ($hasNamed -or $hasExcluded) {
            $out += [PSCustomObject]@{ FindingId = "CA-010"; Severity = "Medium"; PolicyId = $d.Id; PolicyName = $d.DisplayName; SubjectId = $null; SubjectType = "Policy"; Details = "Policy uses named or excluded locations. Named locations and their memberships should be reviewed periodically." }
        }
    }

    Write-Host "[OK] Location analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
