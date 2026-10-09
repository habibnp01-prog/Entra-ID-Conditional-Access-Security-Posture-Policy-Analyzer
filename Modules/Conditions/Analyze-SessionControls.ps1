function Invoke-EntraCASessionAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @()
    )

    Write-Host "[..] Analyzing session controls..." -ForegroundColor DarkCyan
    $out = @()
    $enabled = @(@($Policies) | Where-Object { $_.State -eq "enabled" })

    $hasSignInFrequency = $false
    $hasPersistentControl = $false

    foreach ($p in $enabled) {
        $sc = $p.SessionControls
        if (-not $sc) { continue }
        if ($sc.SignInFrequency -and $sc.SignInFrequency.IsEnabled -eq $true) { $hasSignInFrequency = $true }
        if ($sc.PersistentBrowser -and $sc.PersistentBrowser.IsEnabled -eq $true) { $hasPersistentControl = $true }
    }

    if (-not $hasSignInFrequency) {
        $out += [PSCustomObject]@{ FindingId = "CA-011"; Severity = "Medium"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "No enabled CA policy enforces a sign-in frequency. Long-lived sessions increase the risk of stolen token abuse." }
    }
    if (-not $hasPersistentControl) {
        $out += [PSCustomObject]@{ FindingId = "CA-011"; Severity = "Medium"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "No enabled CA policy controls persistent browser sessions. Users may remain signed in indefinitely on unmanaged devices." }
    }

    Write-Host "[OK] Session analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
