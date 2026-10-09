function Apply-EntraCAExceptions {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowEmptyCollection()] [object[]]$Findings = @(),
        [string]$ExceptionsPath
    )

    $Findings = @($Findings)
    if (-not $ExceptionsPath) {
        $ExceptionsPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Config/Exceptions.json"
    }

    if (-not (Test-Path $ExceptionsPath)) {
        Write-Host "[..] No exceptions file found; skipping." -ForegroundColor DarkCyan
        return ,$Findings
    }

    $exceptions = @((Get-Content $ExceptionsPath -Raw | ConvertFrom-Json).exceptions)
    if ($exceptions.Count -eq 0) {
        return ,$Findings
    }

    $today = (Get-Date).ToString("yyyy-MM-dd")
    $applied = @()
    $kept = @()

    foreach ($f in $Findings) {
        $matched = $null
        foreach ($ex in $exceptions) {
            if ($ex.findingId -and $ex.findingId -eq $f.FindingId) {
                if ($ex.policyName -and $ex.policyName -ne $f.PolicyName) { continue }
                if ($ex.subjectId  -and $ex.subjectId  -ne $f.SubjectId)  { continue }
                $matched = $ex
                break
            }
        }

        if ($matched) {
            if ($matched.expiresOn -and $matched.expiresOn -lt $today) {
                Write-Host "[WARN] Exception for $($f.FindingId) expired on $($matched.expiresOn)." -ForegroundColor Yellow
                $kept += $f
            } else {
                $applied += [PSCustomObject]@{
                    FindingId = $f.FindingId
                    Reason    = $matched.reason
                    ApprovedBy = $matched.approvedBy
                    ExpiresOn = $matched.expiresOn
                }
            }
        } else {
            $kept += $f
        }
    }

    if ($applied.Count -gt 0) {
        Write-Host "[OK] Applied $($applied.Count) tenant exception(s):" -ForegroundColor Green
        $applied | Format-Table -AutoSize | Out-String | Write-Host
    }

    return ,$kept
}
