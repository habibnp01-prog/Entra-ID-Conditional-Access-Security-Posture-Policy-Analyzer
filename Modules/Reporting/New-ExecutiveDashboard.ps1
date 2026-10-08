function New-EntraCAExecutiveDashboard {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings,
        [Parameter(Mandatory)] $RiskSummary,
        [string]$OutputPath
    )

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Reports/HTML"
    }

    Write-Host "`n=== Executive Summary ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Tenant Score : $($RiskSummary.Score) / 100  [$($RiskSummary.Band)]"
    Write-Host "  Total        : $($Findings.Count) findings"
    Write-Host "  Critical     : $($RiskSummary.Critical)"
    Write-Host "  High         : $($RiskSummary.High)"
    Write-Host "  Medium       : $($RiskSummary.Medium)"
    Write-Host "  Low          : $($RiskSummary.Low)"
    Write-Host ""
    Write-Host "  Top Findings by Impact:" -ForegroundColor Yellow

    $top = $RiskSummary.Breakdown | Sort-Object Penalty -Descending | Select-Object -First 5
    foreach ($b in $top) {
        Write-Host "    [$($b.Severity)] $($b.FindingId) — $($b.RawCount) occurrence(s), penalty $($b.Penalty)"
    }

    Write-Host "`n  Recommended Next Steps:" -ForegroundColor Yellow
    if ($RiskSummary.Critical -gt 0) {
        Write-Host "    1. Address CRITICAL findings immediately — they represent the largest gaps."
    }
    if ($Findings | Where-Object { $_.FindingId -eq "CA-007" }) {
        Write-Host "    2. Enable at least one baseline Conditional Access policy."
    }
    if ($Findings | Where-Object { $_.FindingId -eq "CA-003" }) {
        Write-Host "    3. Require MFA for all privileged directory roles."
    }
    if ($Findings | Where-Object { $_.FindingId -eq "CA-006" }) {
        Write-Host "    4. Block legacy authentication protocols."
    }
    Write-Host ""

    return (Export-EntraCAHTMLReport -Findings $Findings -RiskSummary $RiskSummary -OutputPath $OutputPath)
}
