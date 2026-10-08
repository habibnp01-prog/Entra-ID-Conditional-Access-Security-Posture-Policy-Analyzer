function Find-EntraCAPolicyConflicts {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [object[]]$Policies
    )

    Write-Host "[..] Analyzing policy conflicts..." -ForegroundColor DarkCyan
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    $enabled = $Policies | Where-Object { $_.State -eq "enabled" } | ForEach-Object { Get-EntraCAPolicyDetails -Policy $_ }

    for ($i = 0; $i -lt $enabled.Count; $i++) {
        for ($j = $i + 1; $j -lt $enabled.Count; $j++) {
            $a = $enabled[$i]; $b = $enabled[$j]

            $sameUsers  = ($a.IncludeUsers  -contains "All" -and $b.IncludeUsers  -contains "All") -or (($a.IncludeUsers  | Where-Object { $_ -in $b.IncludeUsers  }).Count -gt 0)
            $sameApps   = ($a.IncludeApplications -contains "All" -and $b.IncludeApplications -contains "All") -or (($a.IncludeApplications | Where-Object { $_ -in $b.IncludeApplications }).Count -gt 0)

            if (-not ($sameUsers -and $sameApps)) { continue }

            $aBlock = $a.BuiltInControls -contains "block"
            $bBlock = $b.BuiltInControls -contains "block"
            $aGrant = $a.BuiltInControls -contains "mfa"
            $bGrant = $b.BuiltInControls -contains "mfa"

            if (($aBlock -and $bGrant) -or ($bBlock -and $aGrant)) {
                $findings.Add([PSCustomObject]@{ FindingId = "CA-008"; Severity = "Medium"; PolicyId = "$($a.Id)|$($b.Id)"; PolicyName = "$($a.DisplayName) vs $($b.DisplayName)"; SubjectId = $null; SubjectType = "Policies"; Details = "Potential conflict: one policy blocks, the other requires MFA for overlapping users/apps." })
            }
        }
    }

    Write-Host "[OK] Conflict analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
