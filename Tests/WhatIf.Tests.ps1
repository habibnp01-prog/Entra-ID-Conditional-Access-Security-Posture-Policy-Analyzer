BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "Phase 7 - What-If Simulation" {

    Context "Invoke-EntraCAWhatIf" {
        It "throws when not connected" {
            Mock Test-EntraCAGraphConnection { $false }
            { Invoke-EntraCAWhatIf -UserId "u1" -AppId "a1" } | Should -Throw "*Not connected*"
        }

        It "calls Graph and returns summary" {
            Mock Test-EntraCAGraphConnection { $true }
            Mock Invoke-EntraCAWithRetry {
                @{ value = @() }
            }
            $r = Invoke-EntraCAWhatIf -UserId "u1" -AppId "a1"
            $r.UserId      | Should -Be "u1"
            $r.AppId       | Should -Be "a1"
            $r.AppliedCount | Should -Be 0
        }
    }

    Context "Test-EntraCAProposedPolicy" {
        It "throws when policy file not found" {
            { Test-EntraCAProposedPolicy -PolicyJsonPath ".\does-not-exist.json" -UserId "u1" -AppId "a1" } | Should -Throw "*not found*"
        }
    }

    Context "Format-EntraCAWhatIfResult" {
        It "does not throw on minimal input" {
            $fake = [PSCustomObject]@{
                UserId = "u1"; AppId = "a1"; IpAddress = "1.2.3.4"
                ClientAppType = "browser"; Platform = "windows"
                AppliedCount = 0; RawResult = $null
            }
            { $fake | Format-EntraCAWhatIfResult } | Should -Not -Throw
        }
    }
}
