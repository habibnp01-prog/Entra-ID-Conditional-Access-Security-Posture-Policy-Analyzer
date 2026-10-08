function Invoke-EntraCAWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock,
        [int]$MaxAttempts = 5,
        [int]$InitialDelaySeconds = 2,
        [int]$MaxDelaySeconds = 60,
        [int[]]$RetryOnStatusCodes = @(429, 500, 502, 503, 504)
    )

    $attempt = 0
    $delay = $InitialDelaySeconds

    while ($true) {
        $attempt++
        try {
            return & $ScriptBlock
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            $isTransient = $statusCode -and ($RetryOnStatusCodes -contains $statusCode)
            $isTransient = $isTransient -or ($_.Exception.Message -match "429|503|504|timeout|throttl")

            if (-not $isTransient -or $attempt -ge $MaxAttempts) {
                Write-Host "[ERR ] Attempt $attempt failed: $($_.Exception.Message)" -ForegroundColor Red
                throw
            }

            Write-Host "[WARN] Transient error (attempt $attempt / $MaxAttempts). Retrying in $delay s..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delay
            $delay = [Math]::Min($delay * 2, $MaxDelaySeconds)
        }
    }
}
