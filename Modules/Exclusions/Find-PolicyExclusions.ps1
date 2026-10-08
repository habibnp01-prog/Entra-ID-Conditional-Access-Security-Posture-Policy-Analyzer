function Find-EntraCAPolicyExclusions {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] $Policy
    )

    process {
        $d = Get-EntraCAPolicyDetails -Policy $Policy
        foreach ($id in $d.ExcludeUsers) { [PSCustomObject]@{ PolicyId = $d.Id; PolicyName = $d.DisplayName; PolicyState = $d.State; ExcludeType = "User";  ExcludeId = $id; ExcludeName = $null } }
        foreach ($id in $d.ExcludeGroups) { [PSCustomObject]@{ PolicyId = $d.Id; PolicyName = $d.DisplayName; PolicyState = $d.State; ExcludeType = "Group"; ExcludeId = $id; ExcludeName = $null } }
        foreach ($id in $d.ExcludeRoles)  { [PSCustomObject]@{ PolicyId = $d.Id; PolicyName = $d.DisplayName; PolicyState = $d.State; ExcludeType = "Role";  ExcludeId = $id; ExcludeName = $null } }
    }
}
