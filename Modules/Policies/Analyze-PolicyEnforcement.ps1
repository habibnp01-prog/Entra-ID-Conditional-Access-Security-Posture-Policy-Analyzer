function Invoke-EntraCAPolicyEnforcementAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @()
    )

    Write-Host "[..] Analyzing policy enforcement state..." -ForegroundColor DarkCyan
    $out = @()

    $policies = @($Policies)
    $total      = $policies.Count
    $enabled    = @($policies | Where-Object { $_.State -eq "enabled" }).Count
    $reportOnly = @($policies | Where-Object { $_.State -eq "enabledForReportingButNotEnforced" }).Count
    $disabled   = @($policies | Where-Object { $_.State -eq "disabled" }).Count

    if ($total -eq 0) {
        $out += [PSCustomObject]@{ FindingId = "CA-007"; Severity = "Critical"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "Tenant has ZERO Conditional Access policies defined." }
    }
    elseif ($enabled -eq 0) {
        $msg = "Tenant has $total CA policies but NONE are enforced (0 enabled, $reportOnly report-only, $disabled disabled). All access is unrestricted."
        $out += [PSCustomObject]@{ FindingId = "CA-007"; Severity = "Critical"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = $msg }
    }
    elseif ($enabled -lt 3) {
        $msg = "Tenant has only $enabled enforced CA policies ($reportOnly report-only, $disabled disabled). Baseline recommends 5+ for defense in depth."
        $out += [PSCustomObject]@{ FindingId = "CA-007"; Severity = "High"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = $msg }
    }

    Write-Host "[OK] Enforcement analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
