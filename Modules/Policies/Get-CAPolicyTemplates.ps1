function Get-EntraCAPolicyTemplates {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    return @(
        [PSCustomObject]@{ Id = "c1"; Name = "Require MFA for admins";                Category = "Baseline" }
        [PSCustomObject]@{ Id = "c2"; Name = "Secure security info registration";    Category = "Baseline" }
        [PSCustomObject]@{ Id = "c3"; Name = "Block legacy authentication";          Category = "Baseline" }
        [PSCustomObject]@{ Id = "c4"; Name = "Require MFA for all users";            Category = "Baseline" }
        [PSCustomObject]@{ Id = "c5"; Name = "Require compliant device";             Category = "Baseline" }
        [PSCustomObject]@{ Id = "c6"; Name = "Require hybrid Azure AD joined";       Category = "Baseline" }
        [PSCustomObject]@{ Id = "c7"; Name = "Block unknown platforms";              Category = "Baseline" }
        [PSCustomObject]@{ Id = "c8"; Name = "Require approved client apps";         Category = "Baseline" }
        [PSCustomObject]@{ Id = "c9"; Name = "Block high sign-in risk";              Category = "Risk" }
        [PSCustomObject]@{ Id = "c10"; Name = "Require password change for high user risk"; Category = "Risk" }
        [PSCustomObject]@{ Id = "c11"; Name = "Block access for guest users";        Category = "Guests" }
        [PSCustomObject]@{ Id = "c12"; Name = "Require MFA for guest access";        Category = "Guests" }
    )
}

function Find-EntraCAMatchingTemplates {
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)] $Policy)

    process {
        $details = Get-EntraCAPolicyDetails -Policy $Policy
        $matches = @()
        if ($details.BuiltInControls -contains "mfa") { $matches += "c1" }
        if ($details.ClientAppTypes -contains "exchangeActiveSync" -or $details.ClientAppTypes -contains "other") { $matches += "c3" }
        if ($details.IncludeUsers -contains "All") { $matches += "c4" }

        [PSCustomObject]@{
            PolicyId       = $Policy.Id
            PolicyName     = $Policy.DisplayName
            TemplateIds    = $matches
        }
    }
}
