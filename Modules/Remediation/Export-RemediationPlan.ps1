function Export-EntraCARemediationPlan {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyCollection()] [object[]]$Plan = @(),
        [string]$OutputPath
    )

    $Plan = @($Plan)
    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Reports/Remediation"
    }
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $file = Join-Path $OutputPath "remediation-plan-$timestamp.md"

    $md = "# Remediation Plan`n`n"
    $md += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    $md += "Total unique findings: $($Plan.Count)`n`n"
    $md += "---`n`n"

    $i = 1
    foreach ($item in $Plan) {
        $md += "## $i. [$($item.Severity)] $($item.FindingId) - $($item.Name)`n`n"
        $md += "**Occurrences:** $($item.Occurrences)`n`n"
        $md += "**Description:** $($item.Description)`n`n"
        $md += "**Remediation:** $($item.Remediation)`n`n"
        if ($item.References -and $item.References.Count -gt 0) {
            $md += "**References:**`n"
            foreach ($r in $item.References) { $md += "- $r`n" }
            $md += "`n"
        }
        $md += "---`n`n"
        $i++
    }

    $md | Set-Content -Path $file -Encoding UTF8
    Write-Host "[OK] Remediation plan written: $file" -ForegroundColor Green
    return $file
}
