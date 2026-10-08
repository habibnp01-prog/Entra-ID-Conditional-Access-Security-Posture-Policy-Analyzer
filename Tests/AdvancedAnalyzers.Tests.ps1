BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-FakePolicy {
        param([string]$Id = "pol-x", [string]$Name = "Test", [string]$State = "enabled", [string[]]$BuiltInControls = @("mfa"), [string[]]$ClientAppTypes = @("all"), [string[]]$IncludeRoles = @(), [string[]]$IncludeUsers = @("All"))
        [PSCustomObject]@{
            Id = $Id; DisplayName = $Name; State = $State
            Conditions = [PSCustomObject]@{
                Users = [PSCustomObject]@{ IncludeUsers = $IncludeUsers; IncludeGroups = @(); IncludeRoles = $IncludeRoles; ExcludeUsers = @(); ExcludeGroups = @(); ExcludeRoles = @() }
                Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }
                ClientAppTypes = $ClientAppTypes
                Platforms = [PSCustomObject]@{ IncludePlatforms = @() }
                Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() }
            }
            GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = $BuiltInControls }
            SessionControls = $null
        }
    }
}

Describe "Phase 5 - Advanced Analyzers" {

    Context "Invoke-EntraCAPolicyEnforcementAnalysis" {
        It "flags CA-007 when no enabled policies exist" {
            $r = Invoke-EntraCAPolicyEnforcementAnalysis -Policies @((New-FakePolicy -State "disabled"))
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-007"
            $r[0].Severity | Should -Be "Critical"
        }
        It "does not flag when 3+ enabled policies exist" {
            $r = Invoke-EntraCAPolicyEnforcementAnalysis -Policies @((New-FakePolicy -Id "1"),(New-FakePolicy -Id "2"),(New-FakePolicy -Id "3"))
            $r.Count | Should -Be 0
        }
    }

    Context "Invoke-EntraCALegacyAuthAnalysis" {
        It "flags CA-006 when no policy blocks legacy auth" {
            $r = Invoke-EntraCALegacyAuthAnalysis -Policies @((New-FakePolicy -BuiltInControls @("mfa") -ClientAppTypes @("browser")))
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-006"
        }
        It "does not flag when a blocking policy covers legacy clients" {
            $r = Invoke-EntraCALegacyAuthAnalysis -Policies @((New-FakePolicy -BuiltInControls @("block") -ClientAppTypes @("exchangeActiveSync","other")))
            $r.Count | Should -Be 0
        }
    }

    Context "Find-EntraCAPolicyConflicts" {
        It "returns empty for non-overlapping policies" {
            $r = Find-EntraCAPolicyConflicts -Policies @((New-FakePolicy -Id "1" -BuiltInControls @("mfa")))
            $r.Count | Should -Be 0
        }
    }

    Context "Invoke-EntraCAAuthStrengthAnalysis" {
        It "returns empty when no auth strength set" {
            $r = Invoke-EntraCAAuthStrengthAnalysis -Policies @((New-FakePolicy -IncludeRoles @("62e90394-69f5-4237-9190-012177145e10")))
            $r.Count | Should -Be 0
        }
    }

    Context "Invoke-EntraCALocationAnalysis" {
        It "returns empty when locations are default" {
            $r = Invoke-EntraCALocationAnalysis -Policies @((New-FakePolicy))
            $r.Count | Should -Be 0
        }
    }

    Context "Invoke-EntraCAFullAnalysis" {
        It "runs all analyzers and aggregates findings" {
            $r = Invoke-EntraCAFullAnalysis -Policies @((New-FakePolicy -State "disabled"))
            $r.Count | Should -BeGreaterThan 0
            ($r | Select-Object -ExpandProperty FindingId -Unique) | Should -Contain "CA-007"
        }
    }
}
