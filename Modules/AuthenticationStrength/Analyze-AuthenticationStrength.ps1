function Invoke-EntraCAAuthStrengthAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [object[]]$Policies,
        [string[]]$PrivilegedRoleIds
    )

    if (-not $PrivilegedRoleIds) { $PrivilegedRoleIds = Get-EntraCAPrivilegedRoleIds }

    Write-Host "[..] Analyzing authentication strength for admin policies..." -ForegroundColor DarkCyan
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    $enabled = $Policies | Where-Object { $_.State -eq "enabled" }

    foreach ($p in $enabled) {
        $d = Get-EntraCAPolicyDetails -Policy $p
        if (-not $d.AuthenticationStrength) { continue }

        # If policy targets privileged roles but strength is not phishing-resistant
        $targetsPrivileged = $d.IncludeRoles | Where-Object { $_ -in $PrivilegedRoleIds }
        if (-not $targetsPrivileged) { continue }

        $strengthName = "$($d.AuthenticationStrength.DisplayName)"
        $isPhishResistant = $strengthName -match "phishing|Resistant|FIDO|Certificate"

        if (-not $isPhishResistant) {
            $findings.Add([PSCustomObject]@{ FindingId = "CA-009"; Severity = "Low"; PolicyId = $d.Id; PolicyName = $d.DisplayName; SubjectId = $null; SubjectType = "Policy"; Details = "Policy targets privileged roles but auth strength is ""$strengthName"". Consider phishing-resistant MFA (FIDO2 / certificate)." })
        }
    }

    Write-Host "[OK] Auth strength analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
