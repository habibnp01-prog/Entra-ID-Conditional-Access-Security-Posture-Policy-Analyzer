function Get-EntraCAPolicyDetails {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] $Policy
    )

    process {
        $c = $Policy.Conditions
        $g = $Policy.GrantControls

        [PSCustomObject]@{
            Id                     = $Policy.Id
            DisplayName            = $Policy.DisplayName
            State                  = $Policy.State
            CreatedDateTime        = $Policy.CreatedDateTime
            ModifiedDateTime       = $Policy.ModifiedDateTime

            IncludeUsers           = @($c.Users.IncludeUsers)
            ExcludeUsers           = @($c.Users.ExcludeUsers)
            IncludeGroups          = @($c.Users.IncludeGroups)
            ExcludeGroups          = @($c.Users.ExcludeGroups)
            IncludeRoles           = @($c.Users.IncludeRoles)
            ExcludeRoles           = @($c.Users.ExcludeRoles)
            IncludeGuestsOrExternal = $c.Users.IncludeGuestsOrExternalUsers
            ExcludeGuestsOrExternal = $c.Users.ExcludeGuestsOrExternalUsers

            IncludeApplications    = @($c.Applications.IncludeApplications)
            ExcludeApplications    = @($c.Applications.ExcludeApplications)
            IncludeUserActions      = @($c.Applications.IncludeUserActions)

            ClientAppTypes         = @($c.ClientAppTypes)
            Platforms              = @($c.Platforms.IncludePlatforms)
            Locations              = @($c.Locations.IncludeLocations)
            ExcludeLocations       = @($c.Locations.ExcludeLocations)

            SignInRiskLevels       = @($c.SignInRiskLevels)
            UserRiskLevels         = @($c.UserRiskLevels)

            GrantOperator          = $g.Operator
            BuiltInControls        = @($g.BuiltInControls)
            CustomAuthenticationFactors = @($g.CustomAuthenticationFactors)
            AuthenticationStrength = $g.AuthenticationStrength

            SessionControls        = $Policy.SessionControls

            UserCount              = @($c.Users.IncludeUsers).Count
            GroupCount             = @($c.Users.IncludeGroups).Count
            AppCount               = @($c.Applications.IncludeApplications).Count
            ExclusionCount         = (@($c.Users.ExcludeUsers).Count + @($c.Users.ExcludeGroups).Count + @($c.Users.ExcludeRoles).Count)
        }
    }
}
