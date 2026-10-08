function Export-EntraCASnapshot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$OutputPath,
        [switch]$IncludeDisabled
    )

    if (-not $OutputPath) {
        $OutputPath = Join-Path $PSScriptRoot "../../Reports/JSON"
    }

    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    Write-Host "[..] Building Conditional Access snapshot..." -ForegroundColor DarkCyan

    $stateFilter = if ($IncludeDisabled) { "all" } else { "all" }
    $raw = Get-EntraCAPolicies -State $stateFilter

    $details = $raw | ForEach-Object { Get-EntraCAPolicyDetails -Policy $_ }

    $snapshot = [PSCustomObject]@{
        GeneratedAt    = (Get-Date).ToString("o")
        GeneratedBy    = "$env:USERNAME@$env:COMPUTERNAME"
        TenantId       = (Get-MgContext).TenantId
        PolicyCount    = $raw.Count
        EnabledCount   = ($raw | Where-Object State -eq "enabled").Count
        DisabledCount  = ($raw | Where-Object State -eq "disabled").Count
        ReportOnly     = ($raw | Where-Object State -eq "enabledForReportingButNotEnforced").Count
        Policies       = $details
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $file = Join-Path $OutputPath "snapshot-$timestamp.json"

    $snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8

    Write-Host "[OK] Snapshot written: $file" -ForegroundColor Green
    Write-Host "     Policies: $($snapshot.PolicyCount) (enabled: $($snapshot.EnabledCount), disabled: $($snapshot.DisabledCount), report-only: $($snapshot.ReportOnly))" -ForegroundColor DarkGray

    return $file
}
