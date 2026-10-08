function New-EntraCACertificate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$Subject = "CN=EntraCA-Analyzer",
        [string]$ExportPath = (Join-Path $PSScriptRoot "../../EntraCA-Analyzer.cer"),
        [int]$ValidYears = 2,
        [string]$KeyAlgorithm = "RSA",
        [int]$KeyLength = 2048,
        [string]$HashAlgorithm = "SHA256"
    )

    Write-Host "`n[..] Generating self-signed certificate..." -ForegroundColor DarkCyan
    Write-Host "     Subject  : $Subject" -ForegroundColor DarkGray
    Write-Host "     Validity : $ValidYears year(s)" -ForegroundColor DarkGray
    Write-Host "     Key      : $KeyAlgorithm $KeyLength / $HashAlgorithm" -ForegroundColor DarkGray

    # Create cert with Client Authentication EKU (required for app-only Graph auth)
    $cert = New-SelfSignedCertificate `
        -Subject $Subject `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyExportPolicy Exportable `
        -KeySpec Signature `
        -KeyLength $KeyLength `
        -KeyAlgorithm $KeyAlgorithm `
        -HashAlgorithm $HashAlgorithm `
        -NotAfter (Get-Date).AddYears($ValidYears) `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

    # Export public key (.cer) for uploading to Entra ID
    $exportDir = Split-Path $ExportPath -Parent
    if ($exportDir -and -not (Test-Path $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    }

    Export-Certificate -Cert $cert -FilePath $ExportPath -Force | Out-Null

    Write-Host "[OK] Certificate created in Cert:\CurrentUser\My" -ForegroundColor Green
    Write-Host "[OK] Public key exported to: $ExportPath" -ForegroundColor Green

    [PSCustomObject]@{
        Subject         = $cert.Subject
        Thumbprint      = $cert.Thumbprint
        NotAfter        = $cert.NotAfter
        HasPrivateKey   = $cert.HasPrivateKey
        ExportPath      = $ExportPath
        StorePath       = "Cert:\CurrentUser\My\$($cert.Thumbprint)"
    }
}
