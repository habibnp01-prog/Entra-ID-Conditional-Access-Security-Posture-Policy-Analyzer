function Show-EntraCARemediationPlan {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Plan)

    Write-Host "`n=== Remediation Plan ===" -ForegroundColor Cyan
    Write-Host "  Total unique findings: $($Plan.Count)`n"

    $i = 1
    foreach ($item in $Plan) {
        $color = switch ($item.Severity) {
            "Critical" { "Red" }
            "High"     { "DarkYellow" }
            "Medium"   { "Yellow" }
            "Low"      { "Green" }
            default    { "White" }
        }
        Write-Host "$i. [$($item.Severity)] $($item.FindingId) — $($item.Name)" -ForegroundColor $color
        Write-Host "   Occurrences: $($item.Occurrences)" -ForegroundColor DarkGray
        Write-Host "   Action: $($item.Remediation)" -ForegroundColor Gray
        Write-Host ""
        $i++
    }
}
