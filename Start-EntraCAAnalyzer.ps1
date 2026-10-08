#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "Config/AnalyzerConfig.json"),
    [switch]$SkipPhase1SelfTest,
    [switch]$SkipDependencyCheck,
    [switch]$AutoInstallDependencies
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "`n=== Entra ID Conditional Access Analyzer ===" -ForegroundColor Cyan
Write-Host "Root: $root`n" -ForegroundColor DarkGray

if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
Write-Host "[OK] Config loaded (v$($config.version))." -ForegroundColor Green

if (-not $SkipDependencyCheck) {
    Write-Host "`n--- Dependency Check ---" -ForegroundColor Cyan
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    $required = @()
    foreach ($m in $config.requiredModules) { $required += @{ Name = $m.name; MinimumVersion = $m.minimumVersion } }
    Install-EntraCARequiredModules -RequiredModules $required -Force:$AutoInstallDependencies | Out-Null
}

Write-Host "`n--- Loading Modules ---" -ForegroundColor Cyan
. (Join-Path $root "Modules/Load-Modules.ps1")

if (-not $SkipPhase1SelfTest) {
    Write-Host "`n--- Phase 1 Self-Test ---" -ForegroundColor Cyan
    Write-EntraCAAssessmentLog -Message "Analyzer bootstrap started." -Level Info
    Write-EntraCAAuditLog -Message "Bootstrap started." -Component "Startup"
    $perms = Get-EntraCARequiredPermissions
    Write-Host "[OK] Required permissions loaded: $($perms.Count) entries." -ForegroundColor Green
    $risk = Get-Content (Join-Path $root "Config/RiskThresholds.json") -Raw | ConvertFrom-Json
    Write-Host "[OK] Risk thresholds loaded: $(@($risk.severityLevels.PSObject.Properties.Name).Count) levels." -ForegroundColor Green
    Write-EntraCAAssessmentLog -Message "Phase 1 self-test passed." -Level Success
    Write-Host "`n[DONE] Phase 1 foundation verified." -ForegroundColor Cyan
    Write-Host "Next: implement Phase 2 (Authentication)." -ForegroundColor DarkGray
}