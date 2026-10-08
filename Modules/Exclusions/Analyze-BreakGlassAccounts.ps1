function Invoke-EntraCABreakGlassAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @(),
        [string[]]$KnownBreakGlassIds
    )

    Write-Host "[..] Analyzing break-glass account coverage..." -ForegroundColor DarkCyan
    $out = @()
    $mfaPolicies = @(@($Policies) | Get-EntraCAMFACoverage | Where-Object { $_.RequiresMfa -and $_.State -eq "enabled" })

    if ($mfaPolicies.Count -eq 0) {
        Write-Host "[WARN] No enabled MFA-requiring policies found." -ForegroundColor Yellow
        return ,$out
    }

    $allUserExclusions = @()
    foreach ($p in $mfaPolicies) {
        $allUserExclusions += @($p.ExcludeUsers)
        $allUserExclusions += @($p.ExcludeGroups)
    }
    $allUserExclusions = @($allUserExclusions | Where-Object { $_ } | Select-Object -Unique)

    if ($allUserExclusions.Count -eq 0) {
        $out += [PSCustomObject]@{ FindingId = "CA-004"; Severity = "High"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "No user or group exclusions detected on any enabled MFA-requiring policy." }
        Write-Host "[OK] Break-glass analysis complete: 1 finding." -ForegroundColor Green
        return ,$out
    }

    if ($KnownBreakGlassIds) {
        foreach ($bgId in @($KnownBreakGlassIds)) {
            if ($allUserExclusions -notcontains $bgId) {
                $out += [PSCustomObject]@{ FindingId = "CA-004"; Severity = "High"; PolicyId = $null; PolicyName = $null; SubjectId = $bgId; SubjectType = "User"; Details = "Break-glass account $bgId is not excluded from any MFA-requiring policy." }
            }
        }
    }

    Write-Host "[OK] Break-glass analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
