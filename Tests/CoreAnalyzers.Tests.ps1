BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "Phase 4 - Core Analyzers" {

    Context "Get-EntraCAMFACoverage" {
        It "detects a policy requiring MFA" {
            $p = [PSCustomObject]@{ Id = "pol-1"; DisplayName = "MFA Policy"; State = "enabled"; Conditions = [PSCustomObject]@{ Users = [PSCustomObject]@{ IncludeUsers = @("All"); IncludeGroups = @(); IncludeRoles = @(); ExcludeUsers = @(); ExcludeGroups = @(); ExcludeRoles = @() }; Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }; ClientAppTypes = @("all"); Platforms = [PSCustomObject]@{ IncludePlatforms = @() }; Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() } }; GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = @("mfa") }; SessionControls = $null }
            $r = Get-EntraCAMFACoverage -Policy $p
            $r.RequiresMfa | Should -BeTrue
            $r.CoversAllUsers | Should -BeTrue
        }
        It "detects a policy NOT requiring MFA" {
            $p = [PSCustomObject]@{ Id = "pol-2"; DisplayName = "Block Policy"; State = "enabled"; Conditions = [PSCustomObject]@{ Users = [PSCustomObject]@{ IncludeUsers = @("All"); IncludeGroups = @(); IncludeRoles = @(); ExcludeUsers = @(); ExcludeGroups = @(); ExcludeRoles = @() }; Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }; ClientAppTypes = @("all"); Platforms = [PSCustomObject]@{ IncludePlatforms = @() }; Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() } }; GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = @("block") }; SessionControls = $null }
            $r = Get-EntraCAMFACoverage -Policy $p
            $r.RequiresMfa | Should -BeFalse
        }
    }

    Context "Invoke-EntraCAAdminMFAAnalysis" {
        It "flags a privileged role not covered by any MFA policy" {
            $p = [PSCustomObject]@{ Id = "pol-3"; DisplayName = "Users Only"; State = "enabled"; Conditions = [PSCustomObject]@{ Users = [PSCustomObject]@{ IncludeUsers = @(); IncludeGroups = @("some-group"); IncludeRoles = @(); ExcludeUsers = @(); ExcludeGroups = @(); ExcludeRoles = @() }; Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }; ClientAppTypes = @("all"); Platforms = [PSCustomObject]@{ IncludePlatforms = @() }; Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() } }; GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = @("mfa") }; SessionControls = $null }
            $r = Invoke-EntraCAAdminMFAAnalysis -Policies @($p) -PrivilegedRoleIds @("62e90394-69f5-4237-9190-012177145e10")
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-003"
            $r[0].Severity | Should -Be "Critical"
        }
    }

    Context "Find-EntraCAPolicyExclusions" {
        It "returns all exclusion types" {
            $p = [PSCustomObject]@{ Id = "pol-4"; DisplayName = "With Exclusions"; State = "enabled"; Conditions = [PSCustomObject]@{ Users = [PSCustomObject]@{ IncludeUsers = @("All"); IncludeGroups = @(); IncludeRoles = @(); ExcludeUsers = @("u1"); ExcludeGroups = @("g1"); ExcludeRoles = @("r1") }; Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }; ClientAppTypes = @("all"); Platforms = [PSCustomObject]@{ IncludePlatforms = @() }; Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() } }; GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = @("mfa") }; SessionControls = $null }
            $r = Find-EntraCAPolicyExclusions -Policy $p
            $r.Count | Should -Be 3
        }
    }

    Context "Invoke-EntraCAExclusionAnalysis" {
        It "flags CA-002 for each exclusion on enabled policies" {
            $p = [PSCustomObject]@{ Id = "pol-5"; DisplayName = "Enforced"; State = "enabled"; Conditions = [PSCustomObject]@{ Users = [PSCustomObject]@{ IncludeUsers = @("All"); IncludeGroups = @(); IncludeRoles = @(); ExcludeUsers = @(); ExcludeGroups = @("g1"); ExcludeRoles = @() }; Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }; ClientAppTypes = @("all"); Platforms = [PSCustomObject]@{ IncludePlatforms = @() }; Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() } }; GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = @("mfa") }; SessionControls = $null }
            $r = Invoke-EntraCAExclusionAnalysis -Policies @($p)
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-002"
        }
    }

    Context "Invoke-EntraCABreakGlassAnalysis" {
        It "flags when no break-glass exclusions exist on MFA policies" {
            $p = [PSCustomObject]@{ Id = "pol-6"; DisplayName = "All Users MFA"; State = "enabled"; Conditions = [PSCustomObject]@{ Users = [PSCustomObject]@{ IncludeUsers = @("All"); IncludeGroups = @(); IncludeRoles = @(); ExcludeUsers = @(); ExcludeGroups = @(); ExcludeRoles = @() }; Applications = [PSCustomObject]@{ IncludeApplications = @("All"); ExcludeApplications = @() }; ClientAppTypes = @("all"); Platforms = [PSCustomObject]@{ IncludePlatforms = @() }; Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() } }; GrantControls = [PSCustomObject]@{ Operator = "OR"; BuiltInControls = @("mfa") }; SessionControls = $null }
            $r = Invoke-EntraCABreakGlassAnalysis -Policies @($p)
            $r.Count | Should -Be 1
            $r[0].FindingId | Should -Be "CA-004"
        }
    }
}
