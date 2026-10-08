function Invoke-EntraCALocationAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [object[]]$Policies
    )

    Write-Host "[..] Analyzing location conditions..." -ForegroundColor DarkCyan
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($p in $Policies) {
        if ($p.State -ne "enabled") { continue }
        $d = Get-EntraCAPolicyDetails -Policy $p

        # If policy has named locations in include but uses "All" for locations, flag for review
        $hasNamedLocations = ($d.Locations | Where-Object { $_ -ne "All" -and $_ -ne "AllTrusted" }).Count -gt 0
        $hasExcluded       = ($d.ExcludeLocations).Count -gt 0

        if ($hasNamedLocations -or $hasExcluded) {
            $findings.Add([PSCustomObject]@{ FindingId = "CA-010"; Severity = "Medium"; PolicyId = $d.Id; PolicyName = $d.DisplayName; SubjectId = $null; SubjectType = "Policy"; Details = "Policy uses named or excluded locations. Named locations and their memberships should be reviewed periodically." })
        }
    }

    Write-Host "[OK] Location analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
