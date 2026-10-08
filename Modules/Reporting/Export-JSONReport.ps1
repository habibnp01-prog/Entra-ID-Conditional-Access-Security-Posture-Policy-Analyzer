function Export-EntraCAJSONReport {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings,
        $RiskSummary,
        [string]$OutputPath
    )

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Reports/JSON"
    }
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $file = Join-Path $OutputPath "report-$timestamp.json"

    $payload = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        TenantId    = (Get-MgContext -ErrorAction SilentlyContinue).TenantId
        RiskSummary = $RiskSummary
        Findings    = $Findings
    }
    $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8
    Write-Host "[OK] JSON report written: $file" -ForegroundColor Green
    return $file
}
