BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-Finding {
        param([string]$Id = "CA-003", [string]$Severity = "Critical")
        [PSCustomObject]@{ FindingId = $Id; Severity = $Severity; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Test"; Details = "test" }
    }
}

Describe "Phase 9 - Remediation" {

    Context "Get-EntraCARemediationPlan" {
        It "returns one entry per unique finding ID" {
            $f = @()
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $f += New-Finding -Id "CA-006" -Severity "High"
            $plan = Get-EntraCARemediationPlan -Findings $f
            $plan.Count | Should -Be 2
        }

        It "orders plan Critical first" {
            $f = @()
            $f += New-Finding -Id "CA-006" -Severity "High"
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $plan = Get-EntraCARemediationPlan -Findings $f
            $plan[0].Severity | Should -Be "Critical"
        }
    }

    Context "New-EntraCARemediationBicep" {
        It "generates baseline policies for CA-003 and CA-006" {
            $tmp = Join-Path $env:TEMP "remtest-$(Get-Random)"
            $plan = @([PSCustomObject]@{ FindingId="CA-003"; Severity="Critical"; Occurrences=1; Name="x"; Description=""; Remediation=""; References=@() })
            $file = New-EntraCARemediationBicep -RemediationPlan $plan -OutputPath $tmp
            Test-Path $file | Should -BeTrue
            $obj = Get-Content $file -Raw | ConvertFrom-Json
            @($obj).Count | Should -BeGreaterThan 0
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Export-EntraCARemediationPlan" {
        It "writes a markdown file" {
            $tmp = Join-Path $env:TEMP "remmd-$(Get-Random)"
            $plan = @([PSCustomObject]@{ FindingId="CA-003"; Severity="Critical"; Occurrences=1; Name="Test"; Description="d"; Remediation="r"; References=@() })
            $file = Export-EntraCARemediationPlan -Plan $plan -OutputPath $tmp
            Test-Path $file | Should -BeTrue
            (Get-Content $file -Raw) | Should -Match "CA-003"
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
