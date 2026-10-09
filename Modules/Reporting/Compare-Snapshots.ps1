function Compare-EntraCASnapshots {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$BeforePath,
        [Parameter(Mandatory)] [string]$AfterPath
    )

    if (-not (Test-Path $BeforePath)) { throw "Before snapshot not found: $BeforePath" }
    if (-not (Test-Path $AfterPath))  { throw "After snapshot not found: $AfterPath" }

    $before = Get-Content $BeforePath -Raw | ConvertFrom-Json
    $after  = Get-Content $AfterPath  -Raw | ConvertFrom-Json

    $beforeIds = @($before.Policies    | Select-Object -ExpandProperty Id)
    $afterIds  = @($after.Policies     | Select-Object -ExpandProperty Id)
    $beforeFindings = if ($before.Findings) { @($before.Findings) } else { @() }
    $afterFindings  = if ($after.Findings)  { @($after.Findings) }  else { @() }

    $added   = @($afterIds  | Where-Object { $_ -notin $beforeIds })
    $removed = @($beforeIds | Where-Object { $_ -notin $afterIds })

    $beforeScore = if ($before.Summary) { $before.Summary.Score } else { $null }
    $afterScore  = if ($after.Summary)  { $after.Summary.Score }  else { $null }

    [PSCustomObject]@{
        BeforeDate      = $before.GeneratedAt
        AfterDate       = $after.GeneratedAt
        PoliciesBefore  = $beforeIds.Count
        PoliciesAfter   = $afterIds.Count
        PoliciesAdded   = $added
        PoliciesRemoved = $removed
        FindingsBefore  = $beforeFindings.Count
        FindingsAfter   = $afterFindings.Count
        ScoreBefore     = $beforeScore
        ScoreAfter      = $afterScore
        ScoreDelta      = if ($beforeScore -ne $null -and $afterScore -ne $null) { [Math]::Round($afterScore - $beforeScore, 1) } else { $null }
    }
}
