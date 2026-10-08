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

    $all = @()
    $all += Invoke-EntraCAAdminMFAAnalysis           -Policies $Policies
    $all += Invoke-EntraCAExclusionAnalysis          -Policies $Policies -WideGroupThreshold $WideGroupThreshold
    $all += Invoke-EntraCABreakGlassAnalysis         -Policies $Policies
    $all += Invoke-EntraCAPolicyEnforcementAnalysis  -Policies $Policies
    $all += Invoke-EntraCALegacyAuthAnalysis         -Policies $Policies
    $all += Find-EntraCAPolicyConflicts              -Policies $Policies
    $all += Invoke-EntraCAAuthStrengthAnalysis       -Policies $Policies
    $all += Invoke-EntraCALocationAnalysis           -Policies $Policies

    $all = @($all)
    Write-Host "`n[OK] Full analysis complete: $($all.Count) total finding(s)." -ForegroundColor Green
    return ,$all
}
