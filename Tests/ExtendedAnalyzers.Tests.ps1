BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-FakePolicy {
        param([string]$Id = "pol-x", [string]$State = "enabled", $SessionControls = $null, [string[]]$BuiltInControls = @("mfa"))
        [PSCustomObject]@{
            Id = $Id; DisplayName = "Test"; State = $State
            Conditions = [PSCustomObject]@{
                Users = [PSCustomObject]@{ IncludeUsers = @("All"); IncludeGroups = @(); IncludeRoles = @(); ExcludeUsers = @(); ExcludeGroups = @(); ExcludeRoles = @(); IncludeGuestsOrExternalUsers = $null }
                Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }
                ClientAppTypes = @("all")
                Platforms = [PSCustomObject]@{ IncludePlatforms = @() }
                Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() }
            }
            GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = $BuiltInControls }
            SessionControls = $SessionControls
        }
    }
}

Describe "Phase 11 - Extended Analyzers" {

    Context "Invoke-EntraCASessionAnalysis (CA-011)" {
        It "flags when no sign-in frequency set" {
            $p = New-FakePolicy -SessionControls $null
            $r = Invoke-EntraCASessionAnalysis -Policies @($p)
            ($r | Where-Object { $_.Details -match "sign-in frequency" }).Count | Should -Be 1
        }
        It "does not flag when sign-in frequency enabled" {
            $sc = [PSCustomObject]@{ SignInFrequency = [PSCustomObject]@{ IsEnabled = $true }; PersistentBrowser = [PSCustomObject]@{ IsEnabled = $true } }
            $p = New-FakePolicy -SessionControls $sc
            $r = Invoke-EntraCASessionAnalysis -Policies @($p)
            $r.Count | Should -Be 0
        }
    }

    Context "Invoke-EntraCADeviceAnalysis (CA-012)" {
        It "flags when no device compliance controls set" {
            $p = New-FakePolicy -BuiltInControls @("mfa")
            $r = Invoke-EntraCADeviceAnalysis -Policies @($p)
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-012"
        }
        It "does not flag when compliant device required" {
            $p = New-FakePolicy -BuiltInControls @("compliantDevice")
            $r = Invoke-EntraCADeviceAnalysis -Policies @($p)
            $r.Count | Should -Be 0
        }
    }

    Context "Invoke-EntraCAGuestAnalysis (CA-013)" {
        It "flags when no guest policy exists" {
            $p = New-FakePolicy
            $r = Invoke-EntraCAGuestAnalysis -Policies @($p)
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-013"
        }
        It "does not flag when guest policy exists" {
            $p = New-FakePolicy
            $p.Conditions.Users.IncludeUsers = @("GuestsOrExternalUsers")
            $r = Invoke-EntraCAGuestAnalysis -Policies @($p)
            $r.Count | Should -Be 0
        }
    }
}
