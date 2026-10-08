function Export-EntraCACSVReport {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings,
        [string]$OutputPath
    )

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Reports/CSV"
    }
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $file = Join-Path $OutputPath "findings-$timestamp.csv"

    $Findings | Select-Object FindingId, Severity, PolicyId, PolicyName, SubjectId, SubjectType, Details |
        Export-Csv -Path $file -NoTypeInformation -Encoding UTF8

    Write-Host "[OK] CSV report written: $file" -ForegroundColor Green
    return $file
}
