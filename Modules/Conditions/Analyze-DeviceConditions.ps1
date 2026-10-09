function Invoke-EntraCADeviceAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @()
    )

    Write-Host "[..] Analyzing device compliance requirements..." -ForegroundColor DarkCyan
    $out = @()
    $enabled = @(@($Policies) | Where-Object { $_.State -eq "enabled" })

    $hasCompliance = $false
    $hasHybridJoin = $false

    foreach ($p in $enabled) {
        $d = Get-EntraCAPolicyDetails -Policy $p
        $controls = @($d.BuiltInControls)
        if ($controls -contains "compliantDevice")   { $hasCompliance = $true }
        if ($controls -contains "domainJoinedDevice") { $hasHybridJoin = $true }
    }

    if (-not $hasCompliance -and -not $hasHybridJoin) {
        $out += [PSCustomObject]@{ FindingId = "CA-012"; Severity = "High"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "No enabled CA policy requires a compliant or hybrid Azure AD joined device. Unmanaged devices can access corporate resources." }
    }

    Write-Host "[OK] Device analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
