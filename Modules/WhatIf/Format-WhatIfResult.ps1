function Format-EntraCAWhatIfResult {
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)] $WhatIfResult)

    process {
        Write-Host "`n=== What-If Result ===" -ForegroundColor Cyan
        Write-Host "  User        : $($WhatIfResult.UserId)"
        Write-Host "  Application : $($WhatIfResult.AppId)"
        Write-Host "  IP          : $($WhatIfResult.IpAddress)"
        Write-Host "  Client App  : $($WhatIfResult.ClientAppType)"
        Write-Host "  Platform    : $($WhatIfResult.Platform)"
        Write-Host "  Policies    : $($WhatIfResult.AppliedCount) would apply" -ForegroundColor Yellow

        if ($WhatIfResult.RawResult -and $WhatIfResult.RawResult.value) {
            $applied = @($WhatIfResult.RawResult.value | Where-Object { $_.policyApplies -eq $true })
            $notApplied = @($WhatIfResult.RawResult.value | Where-Object { $_.policyApplies -ne $true })

            if ($applied.Count -gt 0) {
                Write-Host "`n--- Policies That WOULD Apply ---" -ForegroundColor Green
                $applied | ForEach-Object {
                    Write-Host "  $($_.policyDisplayName)" -ForegroundColor White
                    if ($_.grantControls -and $_.grantControls.builtInControls) {
                        Write-Host "    Grant: $($_.grantControls.builtInControls -join ', ')" -ForegroundColor DarkGray
                    }
                }
            }

            if ($notApplied.Count -gt 0) {
                Write-Host "`n--- Policies That Would NOT Apply ---" -ForegroundColor DarkGray
                $notApplied | Select-Object -First 10 | ForEach-Object {
                    Write-Host "  $($_.policyDisplayName)" -ForegroundColor DarkGray
                    if ($_.analysisReasons) {
                        Write-Host "    Reason: $($_.analysisReasons -join ', ')" -ForegroundColor DarkGray
                    }
                }
            }
        } else {
            Write-Host "  (no policy evaluation results returned)" -ForegroundColor DarkGray
        }
    }
}
