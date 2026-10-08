function Get-EntraCAMFACoverage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] $Policy
    )

    process {
        $d = Get-EntraCAPolicyDetails -Policy $Policy
        $requiresMfa = $d.BuiltInControls -contains "mfa"

        [PSCustomObject]@{
            PolicyId       = $d.Id
            PolicyName     = $d.DisplayName
            State          = $d.State
            RequiresMfa    = $requiresMfa
            CoversAllUsers = $d.IncludeUsers -contains "All"
            IncludeUsers   = $d.IncludeUsers
            IncludeGroups  = $d.IncludeGroups
            IncludeRoles   = $d.IncludeRoles
            ExcludeUsers   = $d.ExcludeUsers
            ExcludeGroups  = $d.ExcludeGroups
            ExcludeRoles   = $d.ExcludeRoles
        }
    }
}
