function Get-EntraCARemediationPlan {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings,
        [string]$FindingDefinitionsPath
    )

    if (-not $FindingDefinitionsPath) {
        $FindingDefinitionsPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Findings/FindingDefinitions.json"
    }

    $defs = (Get-Content $FindingDefinitionsPath -Raw | ConvertFrom-Json).findings
    $byId = @{}
    foreach ($d in $defs) { $byId[$d.id] = $d }

    Write-Host "[..] Building remediation plan..." -ForegroundColor DarkCyan

    $unique = $Findings | Group-Object FindingId | Sort-Object {
        switch ($_.Group[0].Severity) {
            "Critical" { 1 }
            "High"     { 2 }
            "Medium"   { 3 }
            "Low"      { 4 }
            default    { 5 }
        }
    }

    $plan = foreach ($g in $unique) {
        $id = $g.Name
        $sev = $g.Group[0].Severity
        $def = $byId[$id]

        [PSCustomObject]@{
            FindingId    = $id
            Severity     = $sev
            Occurrences  = $g.Count
            Name         = if ($def) { $def.name } else { $id }
            Description  = if ($def) { $def.description } else { "" }
            Remediation  = if ($def) { $def.remediation } else { "Review and address this finding." }
            References   = if ($def) { $def.references } else { @() }
        }
    }

    $plan = @($plan)
    Write-Host "[OK] Remediation plan built: $($plan.Count) unique finding(s)." -ForegroundColor Green
    return $plan
}
