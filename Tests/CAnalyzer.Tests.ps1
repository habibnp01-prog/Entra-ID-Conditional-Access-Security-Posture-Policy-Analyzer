BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "Phase 1 - Foundation" {
    It "AnalyzerConfig.json is valid JSON" {
        $p = Join-Path $root "Config/AnalyzerConfig.json"
        { Get-Content $p -Raw | ConvertFrom-Json } | Should -Not -Throw
    }
    It "RiskThresholds.json defines severity levels" {
        $r = Get-Content (Join-Path $root "Config/RiskThresholds.json") -Raw | ConvertFrom-Json
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "Critical"
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "High"
    }
    It "Get-EntraCARequiredPermissions returns 4 permissions" {
        (Get-EntraCARequiredPermissions).Count | Should -Be 4
    }
    It "Write-EntraCAAssessmentLog writes without error" {
        { Write-EntraCAAssessmentLog -Message "test" -Level Info } | Should -Not -Throw
    }
    It "Connect-EntraCAGraph throws NotImplemented" {
        { Connect-EntraCAGraph -TenantId "x" -ClientId "y" -CertificateThumbprint "z" } | Should -Throw "*NotImplemented*"
    }
    It "Test-EntraCARequiredModules reports Missing for fake module" {
        $r = Test-EntraCARequiredModules -RequiredModules @(@{ Name="NoSuchModule999"; MinimumVersion="1.0.0" })
        $r[0].Status | Should -Be "Missing"
    }
    It "Test-EntraCARequiredModules reports OK for Pester" {
        $r = Test-EntraCARequiredModules -RequiredModules @(@{ Name="Pester"; MinimumVersion="5.0.0" })
        $r[0].Status | Should -BeIn @("OK","Outdated")
    }
}