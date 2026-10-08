# Entra ID Conditional Access Security Posture & Policy Analyzer

[![Test](https://github.com/habibnp01-prog/Entra-ID-Conditional-Access-Security-Posture-Policy-Analyzer/actions/workflows/test.yml/badge.svg)](https://github.com/habibnp01-prog/Entra-ID-Conditional-Access-Security-Posture-Policy-Analyzer/actions/workflows/test.yml)
![PowerShell](https://img.shields.io/badge/PowerShell-7.0%2B-blue)
![Tests](https://img.shields.io/badge/tests-54%20passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

**Analyze your tenant's Conditional Access configuration, score it 0-100, and get prioritized remediation — all from a single PowerShell command.**

## What It Does

1. **Discovers** every Conditional Access policy in your tenant
2. **Analyzes** them for 10 security findings (CA-001 through CA-010)
3. **Scores** your tenant 0-100 across five bands
4. **Reports** findings as CSV, JSON, or styled HTML
5. **Recommends** prioritized remediation with importable baseline policy templates

## Sample Output

```
=== Tenant Risk Score ===
  Score      : 25
  Band       : Critical
  Findings   : 12 total
  Critical   : 11
  High       : 1

=== Remediation Plan ===
1. [Critical] CA-003 — Privileged roles not covered by MFA
2. [Critical] CA-007 — Insufficient or absent CA enforcement
3. [High]     CA-006 — No enabled policy blocks legacy authentication
```

## Quick Start

### Prerequisites

- PowerShell 7.0 or later
- Entra ID tenant with Conditional Access (P1 license minimum)
- App registration with 4 Graph permissions

### Setup

```powershell
git clone https://github.com/habibnp01-prog/Entra-ID-Conditional-Access-Security-Posture-Policy-Analyzer.git
cd Entra-ID-Conditional-Access-Security-Posture-Policy-Analyzer
.\Start-EntraCAAnalyzer.ps1
```

### Authentication

1. Generate a certificate:
   ```powershell
   . .\Modules\Load-Modules.ps1
   New-EntraCACertificate
   ```
2. Register an app in Entra ID with these **Application permissions**:
   - `Policy.Read.All`
   - `Directory.Read.All`
   - `Application.Read.All`
   - `RoleManagement.Read.Directory`
3. Upload the `.cer` to the app's **Certificates & secrets**
4. Grant admin consent for the four permissions
5. Populate `Config/AnalyzerConfig.json` with `tenantId`, `clientId`, and `certificateThumbprint`

### Run Analysis

```powershell
. .\Modules\Load-Modules.ps1
$cfg = Get-Content '.\Config\AnalyzerConfig.json' -Raw | ConvertFrom-Json
Connect-EntraCAGraph -TenantId $cfg.tenant.tenantId -ClientId $cfg.tenant.clientId -CertificateThumbprint $cfg.tenant.certificateThumbprint
$findings = Invoke-EntraCAFullAnalysis
$summary  = Get-EntraCARiskSummary -Findings $findings
$csv  = Export-EntraCACSVReport  -Findings $findings
$json = Export-EntraCAJSONReport -Findings $findings -RiskSummary $summary
$html = New-EntraCAExecutiveDashboard -Findings $findings -RiskSummary $summary
$plan  = Get-EntraCARemediationPlan -Findings $findings
Show-EntraCARemediationPlan -Plan $plan
$planMd  = Export-EntraCARemediationPlan -Plan $plan
$bicepJs = New-EntraCARemediationBicep -RemediationPlan $plan
Disconnect-EntraCAGraph
```

## Findings Reference

| ID | Severity | What It Detects |
|----|----------|-----------------|
| CA-001 | High | Enabled policy with no assigned users or groups |
| CA-002 | Medium | Excluded groups in a policy |
| CA-003 | Critical | Privileged roles NOT covered by MFA |
| CA-004 | High | Break-glass account not excluded |
| CA-005 | Medium | Wide exclusion group (>20 members) |
| CA-006 | High | No policy blocks legacy authentication |
| CA-007 | Critical | Insufficient / absent CA enforcement |
| CA-008 | Medium | Conflicting policies |
| CA-009 | Low | Admin policy uses weak auth strength |
| CA-010 | Medium | Named location requires review |

## Running Tests

```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

54 tests, all mocked — no live tenant required.

## Documentation

- [Architecture](Documentation/Architecture.md)
- [Findings Reference](Documentation/Findings.md)
- [Remediation Guide](Documentation/Remediation.md)

## License

MIT — see [LICENSE](LICENSE)
