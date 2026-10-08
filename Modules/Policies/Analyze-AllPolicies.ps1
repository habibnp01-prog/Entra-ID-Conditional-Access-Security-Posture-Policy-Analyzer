function Invoke-EntraCAFullAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [object[]]$Policies,
        [int]$WideGroupThreshold = 20
    )

    if (-not $Policies) {
        if (-not (Test-EntraCAGraphConnection)) { throw "Not connected. Call Connect-EntraCAGraph first." }
        $Policies = Get-EntraCAPolicies -State all
    }

    Write-Host "`n=== Running Full Entra CA Analysis ===" -ForegroundColor Cyan

    $all = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Phase 4 analyzers
    (Invoke-EntraCAAdminMFAAnalysis -Policies $Policies)                  | ForEach-Object { $all.Add($_) }
    (Invoke-EntraCAExclusionAnalysis -Policies $Policies -WideGroupThreshold $WideGroupThreshold) | ForEach-Object { $all.Add($_) }
    (Invoke-EntraCABreakGlassAnalysis -Policies $Policies)                | ForEach-Object { $all.Add($_) }

    # Phase 5 analyzers
    (Invoke-EntraCAPolicyEnforcementAnalysis -Policies $Policies)         | ForEach-Object { $all.Add($_) }
    (Invoke-EntraCALegacyAuthAnalysis -Policies $Policies)                | ForEach-Object { $all.Add($_) }
    (Find-EntraCAPolicyConflicts -Policies $Policies)                     | ForEach-Object { $all.Add($_) }
    (Invoke-EntraCAAuthStrengthAnalysis -Policies $Policies)              | ForEach-Object { $all.Add($_) }
    (Invoke-EntraCALocationAnalysis -Policies $Policies)                  | ForEach-Object { $all.Add($_) }

    Write-Host "`n[OK] Full analysis complete: $($all.Count) total finding(s)." -ForegroundColor Green
    return $all
}
