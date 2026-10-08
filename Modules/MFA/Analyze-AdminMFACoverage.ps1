function Invoke-EntraCAAdminMFAAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @(),
        [string[]]$PrivilegedRoleIds
    )

    if (-not $PrivilegedRoleIds) { $PrivilegedRoleIds = Get-EntraCAPrivilegedRoleIds }
    $PrivilegedRoleIds = @($PrivilegedRoleIds)

    Write-Host "[..] Analyzing privileged role MFA coverage..." -ForegroundColor DarkCyan

    $roleMap = Get-EntraCAPrivilegedRoleMap
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    $mfaPolicies = @(@($Policies) | Get-EntraCAMFACoverage | Where-Object { $_.RequiresMfa -and $_.State -eq "enabled" })

    foreach ($roleId in $PrivilegedRoleIds) {
        $coveringPolicy = $mfaPolicies | Where-Object {
            (@($_.IncludeRoles) -contains $roleId) -or
            ($_.CoversAllUsers -and (@($_.ExcludeRoles) -notcontains $roleId))
        } | Select-Object -First 1

        if (-not $coveringPolicy) {
            $roleName = if ($roleMap[$roleId]) { $roleMap[$roleId] } else { $roleId }
            $findings.Add([PSCustomObject]@{ FindingId = "CA-003"; Severity = "Critical"; PolicyId = $null; PolicyName = $null; SubjectId = $roleId; SubjectType = "Role"; Details = "Privileged role ""$roleName"" ($roleId) is not covered by any enabled MFA-requiring policy." })
        }
    }

    Write-Host "[OK] Admin MFA analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
