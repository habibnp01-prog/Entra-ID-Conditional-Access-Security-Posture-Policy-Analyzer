#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "Config/AnalyzerConfig.json"),
    [switch]$SkipReports,
    [switch]$SkipRemediation,
    [switch]$OpenReport,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "Reports"),
    [switch]$PassThru,
    [string]$TenantId,
    [string]$ClientId,
    [string]$CertificateThumbprint,
    [int]$WideGroupThreshold = 20,
    [switch]$AutoInstallDependencies = $true,
    [string[]]$ExcludedFindingIds,
    [string]$ExceptionsPath = (Join-Path $PSScriptRoot "Config/Exceptions.json"),
    [switch]$KeepConnection,
    [switch]$Quiet
)

# Set-StrictMode disabled for compatibility
$ErrorActionPreference = "Stop"

function Write-Banner {
    if ($Quiet) { return }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Entra ID Conditional Access Security Posture & Policy Analyzer" -ForegroundColor Cyan
    Write-Host "  v1.0.0" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Initialize-Analyzer {
    Write-Banner
    Write-Host "[1/8] Loading modules..." -ForegroundColor Cyan
    . (Join-Path $PSScriptRoot "Modules/Load-Modules.ps1")
    Write-Host "[2/8] Loading configuration..." -ForegroundColor Cyan
    if (-not (Test-Path $ConfigPath)) {
        throw "Config not found: $ConfigPath"
    }
    return (Get-Content $ConfigPath -Raw | ConvertFrom-Json)
}

function Assert-Dependencies {
    param($Config)
    if (-not $AutoInstallDependencies) { return }
    Write-Host "[3/8] Checking dependencies..." -ForegroundColor Cyan
    $required = @()
    foreach ($m in $Config.requiredModules) {
        $required += @{ Name = $m.name; MinimumVersion = $m.minimumVersion }
    }
    . (Join-Path $PSScriptRoot "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $PSScriptRoot "Modules/Bootstrap/Install-RequiredModules.ps1")
    Install-EntraCARequiredModules -RequiredModules $required -Force -Quiet | Out-Null
}

function Resolve-Authentication {
    param($Config)
    Write-Host "[4/8] Authenticating to Microsoft Graph..." -ForegroundColor Cyan
    $tenant = if ($TenantId) { $TenantId } else { $Config.tenant.tenantId }
    $client = if ($ClientId) { $ClientId } else { $Config.tenant.clientId }
    $thumb  = if ($CertificateThumbprint) { $CertificateThumbprint } else { $Config.tenant.certificateThumbprint }
    if (-not $tenant -or -not $client -or -not $thumb) {
        throw "TenantId, ClientId, and CertificateThumbprint are required."
    }
    Connect-EntraCAGraph -TenantId $tenant -ClientId $client -CertificateThumbprint $thumb | Out-Null
}

function Invoke-Analysis {
    Write-Host "[5/8] Running Conditional Access analysis..." -ForegroundColor Cyan
    $findings = Invoke-EntraCAFullAnalysis -WideGroupThreshold $WideGroupThreshold
    if ($ExcludedFindingIds -and $ExcludedFindingIds.Count -gt 0) {
        $findings = @($findings | Where-Object { $_.FindingId -notin $ExcludedFindingIds })
    }
    return $findings
}

function Invoke-Reporting {
    param($Findings, $Summary)
    if ($SkipReports) { return $null }
    Write-Host "[6/8] Generating reports..." -ForegroundColor Cyan
    [PSCustomObject]@{
        CSV  = Export-EntraCACSVReport  -Findings $Findings -OutputPath (Join-Path $OutputDirectory "CSV")
        JSON = Export-EntraCAJSONReport -Findings $Findings -RiskSummary $Summary -OutputPath (Join-Path $OutputDirectory "JSON")
        HTML = Export-EntraCAHTMLReport -Findings $Findings -RiskSummary $Summary -OutputPath (Join-Path $OutputDirectory "HTML")
    }
}

function Invoke-Remediation {
    param($Findings)
    if ($SkipRemediation) { return $null }
    Write-Host "[7/8] Building remediation plan..." -ForegroundColor Cyan
    $plan = Get-EntraCARemediationPlan -Findings $Findings
    $plan = @($plan); if (-not $Quiet) { Show-EntraCARemediationPlan -Plan $plan }
    $dir = Join-Path $OutputDirectory "Remediation"
    [PSCustomObject]@{
        Plan      = $plan
        PlanFile  = Export-EntraCARemediationPlan -Plan $plan -OutputPath $dir
        BicepFile = New-EntraCARemediationBicep -RemediationPlan $plan -OutputPath $dir
    }
}

function Show-FinalSummary {
    param($Summary, $Artifacts, $Remediation, $StartTime)
    if ($Quiet) { return }
    $elapsed = [Math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ANALYSIS COMPLETE" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Tenant Score : $($Summary.Score) / 100  [$($Summary.Band)]"
    Write-Host "  Findings     : $($Summary.Findings) total ($($Summary.Critical) Critical, $($Summary.High) High, $($Summary.Medium) Medium, $($Summary.Low) Low)"
    Write-Host "  Duration     : $elapsed seconds"
    Write-Host ""
    if ($Artifacts) {
        Write-Host "  Reports:" -ForegroundColor Cyan
        Write-Host "    CSV  : $($Artifacts.CSV)"
        Write-Host "    JSON : $($Artifacts.JSON)"
        Write-Host "    HTML : $($Artifacts.HTML)"
    }
    if ($Remediation) {
        Write-Host "  Remediation:" -ForegroundColor Cyan
        Write-Host "    Plan  : $($Remediation.PlanFile)"
        if ($Remediation.BicepFile) { Write-Host "    Bicep : $($Remediation.BicepFile)" }
    }
}

$startTime = Get-Date
try {
    $config      = Initialize-Analyzer
    Assert-Dependencies -Config $config
    Resolve-Authentication -Config $config
    $findings    = Invoke-Analysis
    Write-Host "[6b/8] Calculating risk score..." -ForegroundColor Cyan
    $findings    = Apply-EntraCAExceptions -Findings $findings
    $findings    = Apply-EntraCAExceptions -Findings $findings
    $summary     = Calculate-EntraCATenantScore -Findings $findings
    $artifacts   = Invoke-Reporting -Findings $findings -Summary $summary
    $remediation = Invoke-Remediation -Findings $findings
    Show-FinalSummary -Summary $summary -Artifacts $artifacts -Remediation $remediation -StartTime $startTime
    if ($OpenReport -and $artifacts -and $artifacts.HTML) { Start-Process $artifacts.HTML }
    $session = [PSCustomObject]@{
        Findings    = $findings
        Summary     = $summary
        Artifacts   = $artifacts
        Remediation = $remediation
    }
    if ($PassThru) { $session }
}
finally {
    if (-not $KeepConnection) { try { Disconnect-EntraCAGraph | Out-Null } catch { } }
}
