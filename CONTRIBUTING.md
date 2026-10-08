# Contributing

Thanks for your interest. Here is how to add value to the project.

## Development Setup

1. Install **PowerShell 7.0+**
2. Clone the repository
3. Run `.\Start-EntraCAAnalyzer.ps1` once — it auto-installs Microsoft.Graph and Pester

## Running Tests

```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

All tests use mocks — no live tenant required.

## Adding a New Finding

1. Add an entry to `Findings/FindingDefinitions.json` with a unique `CA-0XX` ID
2. Create an analyzer function under the appropriate `Modules/` subfolder
3. Wire it into `Invoke-EntraCAFullAnalysis` in `Modules/Policies/Analyze-AllPolicies.ps1`
4. Add Pester tests in `Tests/`
5. Update `Documentation/Findings.md`
6. Commit with a `feat:` prefix

## Code Style

- PowerShell 7+ syntax
- `[CmdletBinding()]` on every function
- Explicit `[OutputType()]` on functions that return objects
- Parameters use `[Parameter(Mandatory)]` where required
- No hardcoded secrets

## Pull Requests

- One feature or fix per PR
- All tests must pass
- Update CHANGELOG.md
- Reference issue numbers if applicable
