function Invoke-EntraCAPolicyEnforcementAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [object[]]$Policies
    )

    Write-Host "[..] Analyzing policy enforcement state..." -ForegroundColor DarkCyan
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    $total       = $Policies.Count
    $enabled     = ($Policies | Where-Object { $_.State -eq "enabled" }).Count
    $reportOnly  = ($Policies | Where-Object { $_.State -eq "enabledForReportingButNotEnforced" }).Count
    $disabled    = ($Policies | Where-Object { $_.State -eq "disabled" }).Count

    if ($total -eq 0) {
        $findings.Add([PSCustomObject]@{ FindingId = "CA-007"; Severity = "Critical"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "Tenant has ZERO Conditional Access policies defined." })
    }
    elseif ($enabled -eq 0) {
        $msg = "Tenant has $total CA policies but NONE are enforced (0 enabled, $reportOnly report-only, $disabled disabled). All access is unrestricted."
        $findings.Add([PSCustomObject]@{ FindingId = "CA-007"; Severity = "Critical"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = $msg })
    }
    elseif ($enabled -lt 3) {
        $msg = "Tenant has only $enabled enforced CA policies ($reportOnly report-only, $disabled disabled). Baseline recommends 5+ for defense in depth."
        $findings.Add([PSCustomObject]@{ FindingId = "CA-007"; Severity = "High"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = $msg })
    }

    Write-Host "[OK] Enforcement analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
