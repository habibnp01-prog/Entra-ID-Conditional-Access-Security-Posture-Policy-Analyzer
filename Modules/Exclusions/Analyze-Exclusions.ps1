function Invoke-EntraCAExclusionAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @(),
        [int]$WideGroupThreshold = 20,
        [switch]$ResolveGroupMembers
    )

    Write-Host "[..] Analyzing policy exclusions..." -ForegroundColor DarkCyan
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allExclusions = @(@($Policies) | Find-EntraCAPolicyExclusions)

    foreach ($ex in $allExclusions) {
        if ($ex.PolicyState -ne "enabled") { continue }
        $findings.Add([PSCustomObject]@{ FindingId = "CA-002"; Severity = "Medium"; PolicyId = $ex.PolicyId; PolicyName = $ex.PolicyName; SubjectId = $ex.ExcludeId; SubjectType = $ex.ExcludeType; Details = "Policy excludes $($ex.ExcludeType) $($ex.ExcludeId)." })
    }

    if ($ResolveGroupMembers) {
        $groupIds = @($allExclusions | Where-Object { $_.ExcludeType -eq "Group" } | Select-Object -ExpandProperty ExcludeId -Unique)
        if ($groupIds.Count -gt 0) {
            $groups = Get-EntraCAGroups -GroupIds $groupIds
            foreach ($g in @($groups)) {
                $groupMembers = Invoke-EntraCAWithRetry -ScriptBlock { Get-MgGroupMember -GroupId $g.Id -All -ErrorAction Stop }
                $memberCount = @($groupMembers).Count
                if ($memberCount -gt $WideGroupThreshold) {
                    $findings.Add([PSCustomObject]@{ FindingId = "CA-005"; Severity = "Medium"; PolicyId = $null; PolicyName = $null; SubjectId = $g.Id; SubjectType = "Group"; Details = "Excluded group ""$($g.DisplayName)"" has $memberCount members (threshold: $WideGroupThreshold)." })
                }
            }
        }
    }

    Write-Host "[OK] Exclusion analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
