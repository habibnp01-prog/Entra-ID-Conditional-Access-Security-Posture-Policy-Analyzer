function Invoke-EntraCAWhatIf {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$UserId,
        [Parameter(Mandatory)] [string]$AppId,
        [string]$IpAddress = "203.0.113.1",
        [string]$ClientAppType = "browser",
        [string]$Platform = "windows",
        [string]$SignInRisk = "none",
        [string]$UserRisk = "none"
    )

    if (-not (Test-EntraCAGraphConnection)) { throw "Not connected. Call Connect-EntraCAGraph first." }

    Write-Host "[..] Running What-If simulation for user $UserId..." -ForegroundColor DarkCyan

    $body = @{
        signInIdentity   = @{
            "@odata.type" = "#microsoft.graph.userSignIn"
            userId        = $UserId
        }
        signInContext    = @{
            "@odata.type"       = "#microsoft.graph.applicationContext"
            includeApplications = @($AppId)
            clientAppType       = $ClientAppType
            signInRiskLevel     = $SignInRisk
            userRiskLevel       = $UserRisk
            ipAddress           = $IpAddress
            devicePlatform      = $Platform
        }
        appliedPoliciesOnly = $false
    }

    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/evaluate"

    Write-Host "     POST $uri" -ForegroundColor DarkGray
    Write-Host "     Body: $($body | ConvertTo-Json -Compress -Depth 10)" -ForegroundColor DarkGray

    $result = Invoke-EntraCAWithRetry -ScriptBlock {
        Invoke-MgGraphRequest -Method POST -Uri $uri -Body ($body | ConvertTo-Json -Depth 10) -ErrorAction Stop
    }

    $appliedCount = if ($result.value) { @($result.value).Count } else { 0 }
    Write-Host "[OK] What-If complete. Policies that would apply: $appliedCount" -ForegroundColor Green

    [PSCustomObject]@{
        UserId         = $UserId
        AppId          = $AppId
        IpAddress      = $IpAddress
        ClientAppType  = $ClientAppType
        Platform       = $Platform
        AppliedCount   = $appliedCount
        RawResult      = $result
    }
}
