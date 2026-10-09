function Invoke-EntraCAGuestAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Policies = @()
    )

    Write-Host "[..] Analyzing guest/external user restrictions..." -ForegroundColor DarkCyan
    $out = @()
    $enabled = @(@($Policies) | Where-Object { $_.State -eq "enabled" })

    $hasGuestPolicy = $false
    foreach ($p in $enabled) {
        $d = Get-EntraCAPolicyDetails -Policy $p
        $guests = $d.IncludeGuestsOrExternal
        $users  = @($d.IncludeUsers)
        if ($guests -or ($users -contains "GuestsOrExternalUsers")) {
            $hasGuestPolicy = $true
            break
        }
    }

    if (-not $hasGuestPolicy) {
        $out += [PSCustomObject]@{ FindingId = "CA-013"; Severity = "Medium"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "No enabled CA policy explicitly targets guest or external users. Guests may have broader access than intended." }
    }

    Write-Host "[OK] Guest analysis complete: $($out.Count) finding(s)." -ForegroundColor Green
    return ,$out
}
