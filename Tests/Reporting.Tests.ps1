BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root "Modules/Bootstrap/Test-RequiredModules.ps1")
    . (Join-Path $root "Modules/Bootstrap/Install-RequiredModules.ps1")
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-Finding {
        param([string]$Id = "CA-003", [string]$Severity = "Critical", [string]$Details = "test details")
        [PSCustomObject]@{ FindingId = $Id; Severity = $Severity; PolicyId = $null; PolicyName = $null; SubjectId = $null; SubjectType = "Test"; Details = $Details }
    }
}

Describe "Phase 8 - Reporting" {

    Context "Export-EntraCACSVReport" {
        It "writes a CSV file" {
            $tmp = Join-Path $env:TEMP "csvtest-$(Get-Random)"
            $f = @(New-Finding)
            $file = Export-EntraCACSVReport -Findings $f -OutputPath $tmp
            Test-Path $file | Should -BeTrue
            (Get-Content $file | Measure-Object -Line).Lines | Should -BeGreaterThan 1
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Export-EntraCAJSONReport" {
        It "writes a JSON file" {
            $tmp = Join-Path $env:TEMP "jsontest-$(Get-Random)"
            $f = @(New-Finding)
            $file = Export-EntraCAJSONReport -Findings $f -RiskSummary ([PSCustomObject]@{ Score=25; Band="Critical" }) -OutputPath $tmp
            Test-Path $file | Should -BeTrue
            $obj = Get-Content $file -Raw | ConvertFrom-Json
            $obj.Findings.Count | Should -Be 1
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Export-EntraCAHTMLReport" {
        It "writes an HTML file with score" {
            $tmp = Join-Path $env:TEMP "htmltest-$(Get-Random)"
            $f = @(New-Finding)
            $rs = [PSCustomObject]@{
                Score=25; Band="Critical"; Critical=1; High=0; Medium=0; Low=0; Findings=1
                Breakdown=@([PSCustomObject]@{ FindingId="CA-003"; Severity="Critical"; RawCount=1; Penalty=30 })
            }
            $file = Export-EntraCAHTMLReport -Findings $f -RiskSummary $rs -OutputPath $tmp
            Test-Path $file | Should -BeTrue
            $html = Get-Content $file -Raw
            $html | Should -Match "<html"
            $html | Should -Match "Tenant Score"
            $html | Should -Match "25"
            $html | Should -Match "CA-003"
            Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
