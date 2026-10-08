function Invoke-EntraCALegacyAuthAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [object[]]$Policies
    )

    Write-Host "[..] Analyzing legacy authentication blocking..." -ForegroundColor DarkCyan
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()

    $enabled = $Policies | Where-Object { $_.State -eq "enabled" }

    $blockingPolicies = foreach ($p in $enabled) {
        $d = Get-EntraCAPolicyDetails -Policy $p
        $clientApps = $d.ClientAppTypes
        $isBlock  = $d.BuiltInControls -contains "block"
        $noAppsInclude = ($d.IncludeApplications -contains "All") -or ($d.IncludeApplications -contains "None")
        $coversLegacy = ($clientApps -contains "exchangeActiveSync") -or ($clientApps -contains "other")
        if ($isBlock -and $noAppsInclude -and $coversLegacy) { $p }
    }

    if (-not $blockingPolicies) {
        $findings.Add([PSCustomObject]@{ FindingId = "CA-006"; Severity = "High"; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Tenant"; Details = "No enabled CA policy blocks legacy authentication protocols (Exchange ActiveSync, other). Legacy auth bypasses MFA entirely and is a top attack vector." })
    }

    Write-Host "[OK] Legacy auth analysis complete: $($findings.Count) finding(s)." -ForegroundColor Green
    return $findings
}
