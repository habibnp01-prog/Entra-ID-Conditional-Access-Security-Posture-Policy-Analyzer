function Test-EntraCAUserScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$UserPrincipalName,
        [Parameter(Mandatory)] [string]$ApplicationId,
        [string]$IpAddress = "203.0.113.1",
        [ValidateSet("browser","mobileAppsAndDesktopClients","exchangeActiveSync","other")]
        [string]$ClientAppType = "browser",
        [ValidateSet("windows","macOS","iOS","android","linux","unknown")]
        [string]$Platform = "windows"
    )

    $user = Invoke-EntraCAWithRetry -ScriptBlock {
        Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ErrorAction Stop
    }

    if (-not $user) { throw "User not found: $UserPrincipalName" }

    Write-Host "[..] Resolved $UserPrincipalName to $($user.Id)" -ForegroundColor DarkCyan

    Invoke-EntraCAWhatIf -UserId $user.Id -AppId $ApplicationId -IpAddress $IpAddress -ClientAppType $ClientAppType -Platform $Platform
}
