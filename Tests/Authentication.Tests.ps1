BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "Phase 2 - Authentication" {

    Context "Certificate generation" {
        It "New-EntraCACertificate creates a cert with private key" {
            $result = New-EntraCACertificate -Subject "CN=EntraCA-Test-$(Get-Random)" -ExportPath "$env:TEMP\EntraCA-Test.cer"
            $result.HasPrivateKey | Should -BeTrue
            $result.Thumbprint.Length | Should -BeGreaterThan 10
            Remove-Item "Cert:\CurrentUser\My\$($result.Thumbprint)" -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Certificate discovery" {
        It "Test-EntraCACertificateValidity returns false for unknown thumbprint" {
            Test-EntraCACertificateValidity -Thumbprint "0000000000000000000000000000000000000000" | Should -BeFalse
        }
    }

    Context "Connection health" {
        It "Test-EntraCAConnectionHealth reports disconnected when no session" {
            Mock Get-MgContext { $null }
            $h = Test-EntraCAConnectionHealth
            $h.IsConnected | Should -BeFalse
        }

        It "Test-EntraCAConnectionHealth reports AppOnly when context is valid" {
            Mock Get-MgContext {
                [PSCustomObject]@{
                    AuthType = "AppOnly"
                    TenantId = "tenant-abc"
                    ClientId = "client-xyz"
                    Scopes   = @("Policy.Read.All")
                }
            }
            $h = Test-EntraCAConnectionHealth
            $h.IsConnected | Should -BeTrue
            $h.AuthType | Should -Be "AppOnly"
            $h.Message | Should -Be "OK"
        }
    }

    Context "Retry logic" {
        It "Invoke-EntraCAWithRetry returns immediately on success" {
            $script:attempts = 0
            $result = Invoke-EntraCAWithRetry -ScriptBlock { $script:attempts++; "ok" } -MaxAttempts 3
            $result | Should -Be "ok"
            $script:attempts | Should -Be 1
        }

        It "Invoke-EntraCAWithRetry retries on transient failure then succeeds" {
            $script:attempts2 = 0
            $result = Invoke-EntraCAWithRetry -InitialDelaySeconds 0 -MaxAttempts 4 -ScriptBlock {
                $script:attempts2++
                if ($script:attempts2 -lt 2) {
                    $ex = New-Object System.Exception "429 throttled"
                    throw $ex
                }
                "recovered"
            }
            $result | Should -Be "recovered"
            $script:attempts2 | Should -Be 2
        }

        It "Invoke-EntraCAWithRetry gives up after max attempts" {
            { Invoke-EntraCAWithRetry -InitialDelaySeconds 0 -MaxAttempts 2 -ScriptBlock {
                $ex = New-Object System.Exception "timeout"
                throw $ex
            } } | Should -Throw
        }
    }

    Context "Permission assertion" {
        It "Assert-EntraCAPermissions throws when app not found" {
            Mock Get-MgContext {
                [PSCustomObject]@{ ClientId = "fake-app-id" }
            }
            Mock Get-MgApplication { throw "Not found" }
            { Assert-EntraCAPermissions -ClientId "fake-app-id" } | Should -Throw
        }
    }
}
