# Architecture

## Overview

The analyzer is organized into domain-specific modules under `Modules/`. Each module exposes one or more PowerShell functions that follow a consistent naming convention (`Verb-EntraCANoun`).

## Module Loading

`Modules/Load-Modules.ps1` is dot-sourced by the entry point. It walks `Modules/` recursively and dot-sources every `.ps1` file except itself and anything under `Modules/Bootstrap/`.

## Authentication

All Graph calls use certificate-based **app-only** authentication. Required Application permissions:

- `Policy.Read.All`
- `Directory.Read.All`
- `Application.Read.All`
- `RoleManagement.Read.Directory`

## Data Flow

```
Config/AnalyzerConfig.json
        down
Connect-EntraCAGraph  ->  Microsoft Graph
        down
Get-EntraCAPolicies
        down
Invoke-EntraCAFullAnalysis
   (CA-002) Invoke-EntraCAExclusionAnalysis
   (CA-003) Invoke-EntraCAAdminMFAAnalysis
   (CA-004) Invoke-EntraCABreakGlassAnalysis
   (CA-006) Invoke-EntraCALegacyAuthAnalysis
   (CA-007) Invoke-EntraCAPolicyEnforcementAnalysis
   (CA-008) Find-EntraCAPolicyConflicts
   (CA-009) Invoke-EntraCAAuthStrengthAnalysis
   (CA-010) Invoke-EntraCALocationAnalysis
        down
Calculate-EntraCATenantScore  (0-100 + band)
        down
Export-EntraCACSVReport / JSONReport / HTMLReport
        down
Get-EntraCARemediationPlan
        down
New-EntraCARemediationBicep  (report-only policies)
```

## Testing

Pester 5+ tests live in `Tests/`. All Graph calls are mocked — no live tenant is required for unit tests.

## Extension Points

To add a new finding:

1. Add an entry to `Findings/FindingDefinitions.json` with a unique `CA-0XX` ID
2. Create an analyzer function in the appropriate `Modules/` subfolder
3. Wire it into `Invoke-EntraCAFullAnalysis`
4. Add Pester tests in `Tests/`
5. Update `Documentation/Findings.md`
