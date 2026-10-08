function Invoke-EntraCAAuthStrengthAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @(),
        [string[]]$PrivilegedRoleIds
    )

    if (-not $PrivilegedRoleIds) { $PrivilegedRoleIds = Get-EntraCAPrivilegedRoleIds }
    $PrivilegedRoleIds = @($PrivilegedRoleIds)

    Write-Host "[..] Analyzing authentication strength for admin policies..." -ForegroundColor DarkCyan
    $out = @()
    $enabled = @(@($Policies) | Where-Object { $_.State -eq "enabled" })

    foreach ($p in $enabled) {
        $d = Get-EntraCAPolicyDetails -Policy $p
        if (-not $d.AuthenticationStrength) { continue }
        $targetsPrivileged = @($d.IncludeRoles | Where-Object { $_ -in $PrivilegedRoleIds })
        if ($targetsPrivileged.Count -eq 0) { continue }
        $strengthName = "$($d.AuthenticationStrength.DisplayName)"
        $isPhishResistant = $strengthName -match "phishing|Resistant|FIDO|Certificate"
        if (-not $isPhishResistant) {
            $out += [PSCustomObject]@{ FindingId = "CA-009"; Severity = "Low"; PolicyId = $d.Id; PolicyName = $d.DisplayName; SubjectId = $null; SubjectType = "Policy"; Details = "Policy targets privileged roles but auth strength is ""$strengthName"". Consider phishing-resistant MFA (FIDO2 / certificate)." }
        }
    }

    Write-Host "[OK] Auth strength analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
