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

Describe "Phase 6 - Risk Scoring" {

    Context "Calculate-EntraCATenantScore" {
        It "returns 100 when no findings" {
            $r = Calculate-EntraCATenantScore -Findings @()
            $r.Score | Should -Be 100
            $r.Band  | Should -Be "Excellent"
        }

        It "one Critical finding drops to Fair" {
            $r = Calculate-EntraCATenantScore -Findings @(New-Finding -Id "CA-003" -Severity "Critical")
            $r.Score | Should -Be 70
            $r.Band  | Should -Be "Fair"
        }

        It "two Critical findings drop to Poor" {
            $r = Calculate-EntraCATenantScore -Findings @(New-Finding -Id "CA-003" -Severity "Critical"; New-Finding -Id "CA-007" -Severity "Critical")
            $r.Score | Should -Be 40
            $r.Band  | Should -Be "Poor"
        }

        It "three Critical findings drop to Critical band" {
            $r = Calculate-EntraCATenantScore -Findings @(New-Finding -Id "CA-003" -Severity "Critical"; New-Finding -Id "CA-007" -Severity "Critical"; New-Finding -Id "CA-008" -Severity "Critical")
            $r.Score | Should -Be 10
            $r.Band  | Should -Be "Critical"
        }

        It "repeated findings of the same ID count only once" {
            $f = 1..10 | ForEach-Object { New-Finding -Id "CA-003" -Severity "Critical" }
            $r = Calculate-EntraCATenantScore -Findings $f
            $r.Score | Should -Be 70
            $r.Breakdown.Count | Should -Be 1
        }

        It "counts severities correctly" {
            $f = @()
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $f += New-Finding -Id "CA-006" -Severity "High"
            $f += New-Finding -Id "CA-009" -Severity "Low"
            $r = Calculate-EntraCATenantScore -Findings $f
            $r.Critical | Should -Be 2
            $r.High     | Should -Be 1
            $r.Low      | Should -Be 1
        }

        It "produces a breakdown with one entry per unique FindingId" {
            $f = @()
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $f += New-Finding -Id "CA-003" -Severity "Critical"
            $f += New-Finding -Id "CA-006" -Severity "High"
            $r = Calculate-EntraCATenantScore -Findings $f
            $r.Breakdown.Count | Should -Be 2
        }
    }
}
