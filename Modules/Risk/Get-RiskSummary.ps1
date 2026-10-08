function Get-EntraCARiskSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [object[]]$Findings)
    $score = Calculate-EntraCATenantScore -Findings $Findings

    Write-Host "`n=== Tenant Risk Score ===" -ForegroundColor Cyan
    Write-Host "  Score      : $($score.Score)" -ForegroundColor $(if ($score.Score -lt 40) { "Red" } elseif ($score.Score -lt 75) { "Yellow" } else { "Green" })
    Write-Host "  Band       : $($score.Band)" -ForegroundColor $(if ($score.Band -eq "Critical" -or $score.Band -eq "Poor") { "Red" } elseif ($score.Band -eq "Fair") { "Yellow" } else { "Green" })
    Write-Host "  Findings   : $($score.Findings) total"
    Write-Host "  Critical   : $($score.Critical)" -ForegroundColor Red
    Write-Host "  High       : $($score.High)" -ForegroundColor DarkYellow
    Write-Host "  Medium     : $($score.Medium)" -ForegroundColor Yellow
    Write-Host "  Low        : $($score.Low)" -ForegroundColor Green

    Write-Host "`n--- Per-Finding Breakdown ---" -ForegroundColor Cyan
    $score.Breakdown | Format-Table -AutoSize

    return $score
}
