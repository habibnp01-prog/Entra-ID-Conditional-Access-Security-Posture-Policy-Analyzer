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
        [AllowEmptyCollection()] [object[]]$Findings = @(),
        [string]$RiskModelPath
    )

    if (-not $RiskModelPath) {
        $RiskModelPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Config/RiskThresholds.json"
    }
    $model = Get-Content $RiskModelPath -Raw | ConvertFrom-Json

    # Per-severity penalty (points deducted from 100 per unique finding ID)
    # These are NOT capped by count — repeated findings of the same ID only count once.
    $severityPenalty = @{
        Critical = 30
        High     = 15
        Medium   = 7
        Low      = 2
        Info     = 0
    }

    $groups = @($Findings | Group-Object FindingId)

    $penalty = 0
    $breakdown = foreach ($g in $groups) {
        $sev = ($g.Group | Select-Object -First 1).Severity
        $points = if ($severityPenalty.ContainsKey($sev)) { $severityPenalty[$sev] } else { 5 }
        # Cap 30 max per finding ID (i.e. Critical max)
        $capped = [Math]::Min($points, 30)
        $penalty += $capped

        [PSCustomObject]@{
            FindingId    = $g.Name
            Severity     = $sev
            RawCount     = $g.Count
            Penalty      = $capped
        }
    }

    $score = [Math]::Round([Math]::Max(0, 100 - $penalty), 1)

    $band = "Critical"
    foreach ($b in $model.tenantScoreBands.PSObject.Properties) {
        if ($score -ge $b.Value.min) { $band = $b.Value.label; break }
    }

    [PSCustomObject]@{
        Score      = $score
        Band       = $band
        Penalty    = $penalty
        Findings   = $Findings.Count
        Critical   = @($Findings | Where-Object { $_.Severity -eq "Critical" }).Count
        High       = @($Findings | Where-Object { $_.Severity -eq "High" }).Count
        Medium     = @($Findings | Where-Object { $_.Severity -eq "Medium" }).Count
        Low        = @($Findings | Where-Object { $_.Severity -eq "Low" }).Count
        Breakdown  = @($breakdown)
    }
}
