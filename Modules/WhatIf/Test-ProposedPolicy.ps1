function Test-EntraCAProposedPolicy {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$PolicyJsonPath,
        [Parameter(Mandatory)] [string]$UserId,
        [Parameter(Mandatory)] [string]$AppId,
        [string]$IpAddress = "203.0.113.1"
    )

    if (-not (Test-Path $PolicyJsonPath)) { throw "Policy file not found: $PolicyJsonPath" }

    Write-Host "[..] Simulating proposed policy from $PolicyJsonPath" -ForegroundColor DarkCyan

    $policy = Get-Content $PolicyJsonPath -Raw | ConvertFrom-Json

    $body = @{
        signInIdentity = @{ "@odata.type" = "#microsoft.graph.signInIdentity"; userId = $UserId }
        signInContext  = @{
            "@odata.type"  = "#microsoft.graph.conditionalAccessWhatIfContext"
            applicationId  = $AppId
            ipAddress      = $IpAddress
            clientAppType  = "browser"
            devicePlatform = "windows"
        }
        policiesToEvaluate = @($policy)
    }

    $uri = "https://graph.microsoft.com/beta/identity/conditionalAccess/evaluate"
    $result = Invoke-EntraCAWithRetry -ScriptBlock {
        Invoke-MgGraphRequest -Method POST -Uri $uri -Body ($body | ConvertTo-Json -Depth 15) -ErrorAction Stop
    }

    Write-Host "[OK] Simulation complete." -ForegroundColor Green
    return $result
}
