function Invoke-EntraCAFullAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @(),
        [int]$WideGroupThreshold = 20
    )

    $Policies = @($Policies)

    if ($Policies.Count -eq 0) {
        if (-not (Test-EntraCAGraphConnection)) { throw "Not connected. Call Connect-EntraCAGraph first." }
        $Policies = @(Get-EntraCAPolicies -State all)
    }

    Write-Host "`n=== Running Full Entra CA Analysis ===" -ForegroundColor Cyan
    $all = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($f in @(Invoke-EntraCAAdminMFAAnalysis -Policies $Policies)) { $all.Add($f) }
    foreach ($f in @(Invoke-EntraCAExclusionAnalysis -Policies $Policies -WideGroupThreshold $WideGroupThreshold)) { $all.Add($f) }
    foreach ($f in @(Invoke-EntraCABreakGlassAnalysis -Policies $Policies)) { $all.Add($f) }
    foreach ($f in @(Invoke-EntraCAPolicyEnforcementAnalysis -Policies $Policies)) { $all.Add($f) }
    foreach ($f in @(Invoke-EntraCALegacyAuthAnalysis -Policies $Policies)) { $all.Add($f) }
    foreach ($f in @(Find-EntraCAPolicyConflicts -Policies $Policies)) { $all.Add($f) }
    foreach ($f in @(Invoke-EntraCAAuthStrengthAnalysis -Policies $Policies)) { $all.Add($f) }
    foreach ($f in @(Invoke-EntraCALocationAnalysis -Policies $Policies)) { $all.Add($f) }

    Write-Host "`n[OK] Full analysis complete: $($all.Count) total finding(s)." -ForegroundColor Green
    return $all
}
