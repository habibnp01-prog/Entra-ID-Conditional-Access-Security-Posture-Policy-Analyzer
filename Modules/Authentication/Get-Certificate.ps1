function Get-EntraCACertificate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$Subject,
        [string]$Thumbprint,
        [switch]$RequirePrivateKey = $true
    )

    if (-not $Subject -and -not $Thumbprint) {
        throw "Specify either -Subject or -Thumbprint."
    }

    $path = "Cert:\CurrentUser\My"
    $certs = if ($Thumbprint) {
        Get-ChildItem -Path $path | Where-Object { $_.Thumbprint -eq $Thumbprint }
    } else {
        Get-ChildItem -Path $path | Where-Object { $_.Subject -like "*$Subject*" }
    }

    if (-not $certs) {
        $criteria = if ($Thumbprint) { "Thumbprint $Thumbprint" } else { "Subject matching *$Subject*" }
        throw "No certificate found in $path matching $criteria."
    }

    $result = foreach ($c in $certs) {
        $hasKey = $c.HasPrivateKey
        if ($RequirePrivateKey -and -not $hasKey) {
            Write-Host "[WARN] Cert $($c.Thumbprint) has no private key. Skipping." -ForegroundColor Yellow
            continue
        }
        [PSCustomObject]@{
            Subject         = $c.Subject
            Thumbprint      = $c.Thumbprint
            NotAfter        = $c.NotAfter
            NotBefore       = $c.NotBefore
            HasPrivateKey   = $hasKey
            IsExpired       = ($c.NotAfter -lt (Get-Date))
            StorePath       = $c.PSPath
        }
    }

    if (-not $result) {
        throw "No usable certificate found (private key required)."
    }

    return $result
}

function Test-EntraCACertificateValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Thumbprint
    )

    $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$Thumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) { return $false }
    if ($cert.NotAfter -lt (Get-Date)) { return $false }
    if (-not $cert.HasPrivateKey) { return $false }
    return $true
}
