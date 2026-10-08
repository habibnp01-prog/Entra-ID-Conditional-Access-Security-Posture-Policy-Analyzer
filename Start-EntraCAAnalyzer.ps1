#Requires -Version 7.0
[CmdletBinding()]
param()

# Legacy alias — delegates to the standard entry point.
# Prefer .\Invoke-EntraCAAnalysis.ps1 directly.
& (Join-Path $PSScriptRoot 'Invoke-EntraCAAnalysis.ps1') @PSBoundParameters
