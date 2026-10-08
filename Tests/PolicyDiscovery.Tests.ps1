BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "Phase 3 - Policy Discovery" {

    Context "Get-EntraCAPolicies" {
        It "throws when not connected to Graph" {
            Mock Test-EntraCAGraphConnection { $false }
            { Get-EntraCAPolicies } | Should -Throw "*Not connected*"
        }

        It "returns all policies when connected" {
            Mock Test-EntraCAGraphConnection { $true }
            Mock Invoke-EntraCAWithRetry {
                @(
                    [PSCustomObject]@{ Id = "p1"; DisplayName = "Policy 1"; State = "enabled" }
                    [PSCustomObject]@{ Id = "p2"; DisplayName = "Policy 2"; State = "disabled" }
                )
            }
            $result = Get-EntraCAPolicies
            $result.Count | Should -Be 2
        }

        It "filters to enabled only when requested" {
            Mock Test-EntraCAGraphConnection { $true }
            Mock Invoke-EntraCAWithRetry {
                @(
                    [PSCustomObject]@{ Id = "p1"; DisplayName = "Policy 1"; State = "enabled" }
                    [PSCustomObject]@{ Id = "p2"; DisplayName = "Policy 2"; State = "disabled" }
                )
            }
            $result = Get-EntraCAPolicies -State "enabled"
            $result.Count | Should -Be 1
            $result[0].State | Should -Be "enabled"
        }
    }

    Context "Get-EntraCAPolicyDetails" {
        It "normalizes a policy into a flat structure" {
            $fakePolicy = [PSCustomObject]@{
                Id = "pol-1"
                DisplayName = "Test Policy"
                State = "enabled"
                CreatedDateTime = (Get-Date).AddDays(-30)
                ModifiedDateTime = (Get-Date).AddDays(-1)
                Conditions = [PSCustomObject]@{
                    Users = [PSCustomObject]@{
                        IncludeUsers  = @("user-1","user-2")
                        ExcludeUsers  = @("user-3")
                        IncludeGroups = @("group-1")
                        ExcludeGroups = @()
                        IncludeRoles  = @()
                        ExcludeRoles  = @()
                    }
                    Applications = [PSCustomObject]@{
                        IncludeApplications = @("app-1")
                        ExcludeApplications = @()
                    }
                    ClientAppTypes = @("browser","mobileAppsAndDesktopClients")
                    Platforms = [PSCustomObject]@{ IncludePlatforms = @("windows") }
                    Locations = [PSCustomObject]@{ IncludeLocations = @("All"); ExcludeLocations = @() }
                }
                GrantControls = [PSCustomObject]@{
                    Operator = "OR"
                    BuiltInControls = @("mfa")
                }
                SessionControls = $null
            }

            $d = Get-EntraCAPolicyDetails -Policy $fakePolicy
            $d.Id | Should -Be "pol-1"
            $d.DisplayName | Should -Be "Test Policy"
            $d.IncludeUsers.Count | Should -Be 2
            $d.ExcludeUsers.Count | Should -Be 1
            $d.IncludeGroups.Count | Should -Be 1
            $d.ClientAppTypes.Count | Should -Be 2
            $d.BuiltInControls | Should -Contain "mfa"
            $d.ExclusionCount | Should -Be 1
        }
    }

    Context "Policy templates" {
        It "Get-EntraCAPolicyTemplates returns predefined templates" {
            $templates = Get-EntraCAPolicyTemplates
            $templates.Count | Should -BeGreaterThan 5
        }
    }

    Context "Privileged roles" {
        It "Get-EntraCAPrivilegedRoleIds returns well-known role IDs" {
            $ids = Get-EntraCAPrivilegedRoleIds
            $ids.Count | Should -BeGreaterThan 5
            $ids | Should -Contain "62e90394-69f5-4237-9190-012177145e10"
        }

        It "includes Global Administrator template ID" {
            $ids = Get-EntraCAPrivilegedRoleIds
            $ids -contains "62e90394-69f5-4237-9190-012177145e10" | Should -BeTrue
        }
    }
}
