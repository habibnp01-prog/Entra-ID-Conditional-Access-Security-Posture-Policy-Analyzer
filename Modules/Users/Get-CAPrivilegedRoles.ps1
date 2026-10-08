function Get-EntraCAPrivilegedRoles {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    Write-Host "[..] Fetching directory roles..." -ForegroundColor DarkCyan
    $roles = Invoke-EntraCAWithRetry -ScriptBlock { Get-MgDirectoryRole -ErrorAction Stop }
    $results = foreach ($role in $roles) { [PSCustomObject]@{ Id = $role.Id; RoleTemplateId = $role.RoleTemplateId; DisplayName = $role.DisplayName; Description = $role.Description } }
    Write-Host "[OK] Retrieved $($results.Count) directory role(s)." -ForegroundColor Green
    return $results
}

function Get-EntraCAPrivilegedRoleIds {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    return @(
        "62e90394-69f5-4237-9190-012177145e10"
        "194ae4cb-b126-40b2-bd5b-6091b380977d"
        "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
        "29232cdf-9323-42fd-ade2-1d097af3e4de"
        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
        "729827e3-9c14-49f7-bb1b-9608f156bbb8"
        "966707d0-3269-4727-9be2-8c3a10f19b9d"
        "fe930be7-5e62-47db-91af-98c3a49a38b1"
        "e8611ab8-c189-46e8-94e1-60213ab1f814"
        "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
    )
}

function Get-EntraCAPrivilegedRoleMap {
    [CmdletBinding()]
    param()
    return @{
        "62e90394-69f5-4237-9190-012177145e10" = "Global Administrator"
        "194ae4cb-b126-40b2-bd5b-6091b380977d" = "Security Administrator"
        "f28a1f50-f6e7-4571-818b-6a12f2af6b6c" = "SharePoint Administrator"
        "29232cdf-9323-42fd-ade2-1d097af3e4de" = "Exchange Administrator"
        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9" = "Conditional Access Administrator"
        "729827e3-9c14-49f7-bb1b-9608f156bbb8" = "Helpdesk Administrator"
        "966707d0-3269-4727-9be2-8c3a10f19b9d" = "Password Administrator"
        "fe930be7-5e62-47db-91af-98c3a49a38b1" = "User Administrator"
        "e8611ab8-c189-46e8-94e1-60213ab1f814" = "Privileged Role Administrator"
        "7be44c8a-adaf-4e2a-84d6-ab2649e08a13" = "Privileged Authentication Administrator"
    }
}
