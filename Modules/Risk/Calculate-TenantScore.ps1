function Get-EntraCARiskModel {
    [CmdletBinding()]
    param()
    $cfg = Get-Content (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Config/RiskThresholds.json") -Raw | ConvertFrom-Json
    return $cfg
}

function Calculate-EntraCATenantScore {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [object[]]$Findings,
        [string]$RiskModelPath
    )

    if (-not $RiskModelPath) {
        $RiskModelPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Config/RiskThresholds.json"
    }
    $model = Get-Content $RiskModelPath -Raw | ConvertFrom-Json

    $maxPerFinding = 3
    $weights = $model.severityLevels

    $groups = $Findings | Group-Object FindingId

    $penalty = 0
    $breakdown = foreach ($g in $groups) {
        $sev = ($g.Group | Select-Object -First 1).Severity
        $weight = if ($weights.$sev) { $weights.$sev.weight } else { 4 }
        $capped = [Math]::Min($g.Count, $maxPerFinding)
        $contribution = $weight * $capped
        $penalty += $contribution

        [PSCustomObject]@{
            FindingId    = $g.Name
            Severity     = $sev
            RawCount     = $g.Count
            CappedCount  = $capped
            Weight       = $weight
            Contribution = $contribution
        }
    }

    $maxPenalty = 10 * 10 * $maxPerFinding
    $score = [Math]::Round([Math]::Max(0, 100 - ($penalty / $maxPenalty) * 100), 1)

    $band = "Critical"
    foreach ($b in $model.tenantScoreBands.PSObject.Properties) {
        if ($score -ge $b.Value.min) { $band = $b.Value.label; break }
    }

    [PSCustomObject]@{
        Score      = $score
        Band       = $band
        Penalty    = $penalty
        MaxPenalty = $maxPenalty
        Findings   = $Findings.Count
        Critical   = ($Findings | Where-Object { $_.Severity -eq "Critical" }).Count
        High       = ($Findings | Where-Object { $_.Severity -eq "High" }).Count
        Medium     = ($Findings | Where-Object { $_.Severity -eq "Medium" }).Count
        Low        = ($Findings | Where-Object { $_.Severity -eq "Low" }).Count
        Breakdown  = @($breakdown)
    }
}
