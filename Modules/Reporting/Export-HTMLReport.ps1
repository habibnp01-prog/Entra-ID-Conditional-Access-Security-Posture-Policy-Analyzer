function Export-EntraCAHTMLReport {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings,
        [Parameter(Mandatory)] $RiskSummary,
        [string]$OutputPath
    )

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Reports/HTML"
    }
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $file = Join-Path $OutputPath "report-$timestamp.html"

    $tenantId = (Get-MgContext -ErrorAction SilentlyContinue).TenantId
    $generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")

    $bandColor = switch ($RiskSummary.Band) {
        "Excellent" { "#16A34A" }
        "Good"      { "#22C55E" }
        "Fair"      { "#CA8A04" }
        "Poor"      { "#EA580C" }
        "Critical"  { "#DC2626" }
        default     { "#64748B" }
    }

    $severityColor = @{
        Critical = "#DC2626"
        High     = "#EA580C"
        Medium   = "#CA8A04"
        Low      = "#16A34A"
        Info     = "#2563EB"
    }

    # Build findings rows
    $findingRows = foreach ($f in ($Findings | Sort-Object Severity, FindingId)) {
        $c = if ($severityColor[$f.Severity]) { $severityColor[$f.Severity] } else { "#64748B" }
        $pn = if ($f.PolicyName) { $f.PolicyName } else { "—" }
        $det = ($f.Details -replace "<", "&lt;" -replace ">", "&gt;")
        "<tr><td><code>$($f.FindingId)</code></td><td><span class=""sev"" style=""background:$c"">$($f.Severity)</span></td><td>$pn</td><td>$det</td></tr>"
    }
    $findingRows = $findingRows -join "`n"

    # Build breakdown rows
    $breakdownRows = foreach ($b in $RiskSummary.Breakdown) {
        "<tr><td><code>$($b.FindingId)</code></td><td>$($b.Severity)</td><td>$($b.RawCount)</td><td>$($b.Penalty)</td></tr>"
    }
    $breakdownRows = $breakdownRows -join "`n"

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Entra ID Conditional Access Security Report</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: -apple-system, Segoe UI, Roboto, sans-serif; margin: 0; padding: 0; background: #F1F5F9; color: #0F172A; }
  .container { max-width: 1200px; margin: 0 auto; padding: 32px; }
  h1 { font-size: 28px; margin: 0 0 8px 0; }
  h2 { font-size: 20px; margin: 32px 0 12px 0; border-bottom: 2px solid #E2E8F0; padding-bottom: 6px; }
  .meta { color: #64748B; font-size: 14px; margin-bottom: 24px; }
  .scorecard { display: flex; gap: 24px; background: white; border-radius: 12px; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); align-items: center; }
  .score-big { font-size: 72px; font-weight: 700; line-height: 1; }
  .band { display: inline-block; padding: 6px 14px; border-radius: 999px; color: white; font-weight: 600; font-size: 14px; }
  .metrics { display: flex; gap: 32px; margin-left: auto; }
  .metric { text-align: center; }
  .metric .val { font-size: 28px; font-weight: 700; }
  .metric .lbl { font-size: 12px; color: #64748B; text-transform: uppercase; letter-spacing: 0.05em; }
  table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
  th { text-align: left; padding: 12px 16px; background: #F8FAFC; font-size: 12px; text-transform: uppercase; color: #64748B; border-bottom: 1px solid #E2E8F0; }
  td { padding: 12px 16px; border-bottom: 1px solid #F1F5F9; font-size: 14px; vertical-align: top; }
  td code { background: #F1F5F9; padding: 2px 6px; border-radius: 4px; font-size: 12px; }
  .sev { display: inline-block; padding: 2px 10px; border-radius: 999px; color: white; font-weight: 600; font-size: 11px; text-transform: uppercase; letter-spacing: 0.03em; }
  footer { text-align: center; color: #94A3B8; font-size: 12px; margin-top: 48px; }
</style>
</head>
<body>
<div class="container">
  <h1>Entra ID Conditional Access Security Report</h1>
  <div class="meta">Tenant: <code>$tenantId</code> &middot; Generated: $generatedAt</div>

  <div class="scorecard">
    <div>
      <div class="score-big" style="color: $bandColor">$($RiskSummary.Score)</div>
      <div style="color:#64748B; font-size:12px; text-transform:uppercase; letter-spacing:0.05em;">Tenant Score</div>
    </div>
    <div><span class="band" style="background: $bandColor">$($RiskSummary.Band)</span></div>
    <div class="metrics">
      <div class="metric"><div class="val" style="color:#DC2626">$($RiskSummary.Critical)</div><div class="lbl">Critical</div></div>
      <div class="metric"><div class="val" style="color:#EA580C">$($RiskSummary.High)</div><div class="lbl">High</div></div>
      <div class="metric"><div class="val" style="color:#CA8A04">$($RiskSummary.Medium)</div><div class="lbl">Medium</div></div>
      <div class="metric"><div class="val" style="color:#16A34A">$($RiskSummary.Low)</div><div class="lbl">Low</div></div>
    </div>
  </div>

  <h2>Per-Finding Breakdown</h2>
  <table>
    <thead><tr><th>Finding</th><th>Severity</th><th>Occurrences</th><th>Penalty</th></tr></thead>
    <tbody>
$breakdownRows
    </tbody>
  </table>

  <h2>All Findings ($($Findings.Count))</h2>
  <table>
    <thead><tr><th>ID</th><th>Severity</th><th>Policy</th><th>Details</th></tr></thead>
    <tbody>
$findingRows
    </tbody>
  </table>

  <footer>Generated by Entra ID Conditional Access Security Analyzer</footer>
</div>
</body>
</html>
"@

    $html | Set-Content -Path $file -Encoding UTF8
    Write-Host "[OK] HTML report written: $file" -ForegroundColor Green
    return $file
}
