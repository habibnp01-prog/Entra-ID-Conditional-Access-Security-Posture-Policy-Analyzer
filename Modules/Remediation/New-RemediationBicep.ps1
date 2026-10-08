function New-EntraCARemediationBicep {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyCollection()] [object[]]$RemediationPlan = @(),
        [string]$OutputPath
    )

    $RemediationPlan = @($RemediationPlan)
    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Reports/Remediation"
    }
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $file = Join-Path $OutputPath "baseline-policies-$timestamp.json"

    Write-Host "[..] Generating baseline policy templates..." -ForegroundColor DarkCyan
    $templates = @()

    $hasIds = @($RemediationPlan | Select-Object -ExpandProperty FindingId)

    if ($hasIds -contains "CA-003") {
        $templates += [PSCustomObject]@{
            displayName = "[EntraCA] Require MFA for privileged roles"
            state       = "enabledForReportingButNotEnforced"
            conditions  = [PSCustomObject]@{
                users = [PSCustomObject]@{
                    includeRoles = @(
                        "62e90394-69f5-4237-9190-012177145e10"
                        "194ae4cb-b126-40b2-bd5b-6091b380977d"
                        "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
                        "29232cdf-9323-42fd-ade2-1d097af3e4de"
                        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
                        "729827e3-9c14-49f7-bb1b-9608f156bbb8"
                        "966707d0-3269-4727-9be2-8c3a10f19b9d"
                        "fe930be7-5e62-47db-91af-98c3a49a38b1"
                        "e8611ab8-c189-46e8-94e1-60213ab1f814"
                        "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
                    )
                }
                applications = [PSCustomObject]@{ includeApplications = @("All") }
                clientAppTypes = @("all")
            }
            grantControls = [PSCustomObject]@{
                operator = "OR"
                builtInControls = @("mfa")
            }
        }
    }

    if ($hasIds -contains "CA-006") {
        $templates += [PSCustomObject]@{
            displayName = "[EntraCA] Block legacy authentication"
            state       = "enabledForReportingButNotEnforced"
            conditions  = [PSCustomObject]@{
                users = [PSCustomObject]@{ includeUsers = @("All") }
                applications = [PSCustomObject]@{ includeApplications = @("All") }
                clientAppTypes = @("exchangeActiveSync","other")
            }
            grantControls = [PSCustomObject]@{
                operator = "OR"
                builtInControls = @("block")
            }
        }
    }

    if ($templates.Count -eq 0) {
        Write-Host "[!!] No remediation templates to generate (no CA-003/CA-006 findings)." -ForegroundColor Yellow
        return $null
    }

    $templates | ConvertTo-Json -Depth 15 | Set-Content -Path $file -Encoding UTF8
    Write-Host "[OK] Generated $($templates.Count) baseline policy template(s): $file" -ForegroundColor Green
    Write-Host "     Policies are in REPORT-ONLY mode - safe to import." -ForegroundColor Yellow
    return $file
}
