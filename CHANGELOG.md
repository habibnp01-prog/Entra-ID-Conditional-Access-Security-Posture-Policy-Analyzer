# Changelog

All notable changes to this project are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - Initial Release
### Added
- Complete 10-phase build: Foundation, Authentication, Discovery, Core Analyzers, Advanced Analyzers, Risk Scoring, What-If, Reporting, Remediation, CI/CD
- 10 findings (CA-001 through CA-010)
- Risk scoring engine (0-100 with bands)
- HTML executive dashboard with embedded CSS
- Baseline policy templates in report-only mode
- Full Pester test suite (54 tests)
- GitHub Actions CI
- Complete documentation

## [0.9.0] - Phase 9: Remediation Engine
### Added
- `Get-EntraCARemediationPlan`
- `New-EntraCARemediationBicep`
- `Export-EntraCARemediationPlan`
- `Show-EntraCARemediationPlan`

## [0.8.0] - Phase 8: Reporting Layer
### Added
- `Export-EntraCACSVReport`
- `Export-EntraCAJSONReport`
- `Export-EntraCAHTMLReport`
- `New-EntraCAExecutiveDashboard`

## [0.7.0] - Phase 7: What-If Simulation
### Added
- `Invoke-EntraCAWhatIf`
- `Test-EntraCAUserScenario`
- `Test-EntraCAProposedPolicy`
- `Format-EntraCAWhatIfResult`

## [0.6.0] - Phase 6: Risk Scoring
### Added
- `Calculate-EntraCATenantScore`
- `Get-EntraCARiskSummary`
- `Export-EntraCARiskSummary`

## [0.5.0] - Phase 5: Advanced Analyzers
### Added
- `Invoke-EntraCAPolicyEnforcementAnalysis` (CA-007)
- `Invoke-EntraCALegacyAuthAnalysis` (CA-006)
- `Find-EntraCAPolicyConflicts` (CA-008)
- `Invoke-EntraCAAuthStrengthAnalysis` (CA-009)
- `Invoke-EntraCALocationAnalysis` (CA-010)
- `Invoke-EntraCAFullAnalysis` orchestrator

## [0.4.0] - Phase 4: Core Analyzers
### Added
- `Get-EntraCAMFACoverage`
- `Invoke-EntraCAAdminMFAAnalysis` (CA-003)
- `Find-EntraCAPolicyExclusions` (CA-002)
- `Invoke-EntraCAExclusionAnalysis` (CA-005)
- `Invoke-EntraCABreakGlassAnalysis` (CA-004)
- `Findings/FindingDefinitions.json`

## [0.3.0] - Phase 3: Policy Discovery
### Added
- `Get-EntraCAPolicies`
- `Get-EntraCAPolicyDetails`
- `Get-EntraCAPolicyTemplates`
- `Export-EntraCASnapshot`
- `Get-EntraCAUsers`, `Get-EntraCAGroups`, `Get-EntraCAPrivilegedRoles`

## [0.2.0] - Phase 2: Authentication
### Added
- `New-EntraCACertificate`
- `Get-EntraCACertificate`
- `Connect-EntraCAGraph` / `Disconnect-EntraCAGraph`
- `Test-EntraCAConnectionHealth`
- `Assert-EntraCAPermissions`
- `Invoke-EntraCAWithRetry`

## [0.1.0] - Phase 1: Foundation
### Added
- Bootstrap module
- Config files
- Logging module
- Module loader
- Entry point
