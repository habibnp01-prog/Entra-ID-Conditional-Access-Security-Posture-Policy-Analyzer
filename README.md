# Entra ID Conditional Access Security Posture & Policy Analyzer

![PowerShell](https://img.shields.io/badge/PowerShell-7.0%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-15%20passing-brightgreen)

Analyzes an organization's Conditional Access configuration and identifies security gaps, policy conflicts, exclusions, coverage gaps, and risky configurations — with actionable remediation and safe policy simulation.

## Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Foundation (config, logging, bootstrap, tests) | ✅ Complete |
| 2 | Authentication (cert-based app-only Graph) | ✅ Complete |
| 3 | Policy Discovery | 🚧 Planned |
| 4 | Core Analyzers (MFA, exclusions) | 🚧 Planned |
| 5 | Advanced Analyzers (conflicts, legacy auth) | 🚧 Planned |
| 6 | Risk Scoring Engine | 🚧 Planned |
| 7 | What-If Simulation | 🚧 Planned |
| 8 | Reporting (CSV, JSON, HTML) | 🚧 Planned |
| 9 | Remediation Engine | 🚧 Planned |
| 10 | CI/CD and Release | 🚧 Planned |

## Requirements

- PowerShell 7.0 or later
- Microsoft.Graph PowerShell SDK (auto-installed on first run)
- Entra ID tenant with P1/P2 licenses for full analysis

## Quick Start

```powershell
git clone https://github.com/habibnp01-prog/Entra-ID-Conditional-Access-Security-Posture-Policy-Analyzer.git
cd Entra-ID-Conditional-Access-Security-Posture-Policy-Analyzer
.\Start-EntraCAAnalyzer.ps1
```

## Run Tests

```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

## Required Graph Permissions

| Permission | Type | Purpose |
|------------|------|---------|
| Policy.Read.All | Application | Read Conditional Access policies |
| Directory.Read.All | Application | Resolve users and groups in exclusions |
| Application.Read.All | Application | Read app registrations |
| RoleManagement.Read.Directory | Application | Identify privileged roles |

## License

MIT — see [LICENSE](LICENSE)
