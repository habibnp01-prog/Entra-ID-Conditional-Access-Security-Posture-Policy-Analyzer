# Remediation Guide

The remediation engine produces two artifacts:

1. **Remediation plan (Markdown)** — prioritized action items, one per unique finding ID
2. **Baseline policy templates (JSON)** — importable Conditional Access policies in **report-only** mode

## Safety Model

Generated policy templates are set to `enabledForReportingButNotEnforced` (report-only). This means:

- They will **not** block or require anything during sign-in
- They **will** be visible in the What-If tool and sign-in logs
- You decide when to flip them to `enabled`

## Workflow

1. Run `Invoke-EntraCAFullAnalysis` to produce findings
2. Run `Get-EntraCARemediationPlan` to produce the prioritized plan
3. Run `New-EntraCARemediationBicep` to produce the baseline templates
4. Review and adjust the templates
5. Import via the Entra admin center, Microsoft Graph, or Bicep
6. Monitor sign-in logs and What-If for 1-2 weeks
7. Flip `state` to `enabled` once confident

## Not Implemented

This tool does **not** create or modify Conditional Access policies in your tenant. All policy changes are the responsibility of the operator.
