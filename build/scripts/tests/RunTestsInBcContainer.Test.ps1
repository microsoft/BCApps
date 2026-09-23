Describe "Test-AllSelectedTestsExecuted" {
    BeforeAll {
        # RunTestsInBcContainer.ps1 runs a full pipeline on load, so extract just the function under
        # test (and its Get-BaseFolder dependency) from the AST into global scope; removed in AfterAll.
        $scriptPath = Join-Path $PSScriptRoot '..\RunTestsInBcContainer.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$null)
        $fn = $ast.FindAll({ param($n)
            $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Test-AllSelectedTestsExecuted' }, $true) | Select-Object -First 1
        if (-not $fn) { throw "Could not find Test-AllSelectedTestsExecuted in $scriptPath" }
        Invoke-Expression ($fn.Extent.Text -replace '^function\s+Test-AllSelectedTestsExecuted', 'function global:Test-AllSelectedTestsExecuted')

        # A fixture 'test' folder with three tiny test codeunits: the reconciliation scans AL source
        # under folders named 'test', so the layout mirrors a real test app.
        $script:fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("rticbc_" + [System.Guid]::NewGuid().ToString('N'))
        $testFolder = Join-Path $script:fixtureRoot 'test'
        New-Item -ItemType Directory -Path $testFolder -Force | Out-Null

        Set-Content -Encoding utf8 -Path (Join-Path $testFolder 'Alpha.Codeunit.al') -Value @'
codeunit 90001 "Alpha"
{
    Subtype = Test;

    [Test]
    procedure A1()
    begin
    end;

    [Test]
    procedure A2()
    begin
    end;

    [Test]
    procedure A3()
    begin
    end;
}
'@

        # Beta declares one live test plus block- and line-commented [Test] methods that must not count.
        Set-Content -Encoding utf8 -Path (Join-Path $testFolder 'Beta.Codeunit.al') -Value @'
codeunit 90002 "Beta"
{
    Subtype = Test;

    [Test]
    procedure B1()
    begin
    end;

    /*  Bug 123456: parked because it hangs
    [Test]
    procedure BBlockCommented()
    begin
    end;
    */

    // [Test]
    // procedure BLineCommented()
    // begin
    // end;
}
'@

        Set-Content -Encoding utf8 -Path (Join-Path $testFolder 'Gamma.Codeunit.al') -Value @'
codeunit 90003 "Gamma"
{
    Subtype = Test;

    [Test]
    procedure G1()
    begin
    end;

    [Test]
    procedure G2()
    begin
    end;
}
'@

        # Get-BaseFolder is what the function calls to locate the source tree.
        $global:RticbcFixtureRoot = $script:fixtureRoot
        function global:Get-BaseFolder { $global:RticbcFixtureRoot }

        # Writes a JUnit result file. $Suites is an ordered map of "<id> <name>" -> @(testcase names).
        function script:New-ResultsFile {
            param([hashtable]$Suites)
            $doc = New-Object System.Xml.XmlDocument
            $root = $doc.CreateElement('testsuites'); [void]$doc.AppendChild($root)
            foreach ($suiteName in $Suites.Keys) {
                $s = $doc.CreateElement('testsuite'); $s.SetAttribute('name', $suiteName)
                foreach ($tc in $Suites[$suiteName]) {
                    $c = $doc.CreateElement('testcase'); $c.SetAttribute('name', $tc); [void]$s.AppendChild($c)
                }
                [void]$root.AppendChild($s)
            }
            $path = Join-Path $script:fixtureRoot ("results_" + [System.Guid]::NewGuid().ToString('N') + '.xml')
            $doc.Save($path)
            return $path
        }

        function script:Disabled { param([int]$Id, [string]$Method) [pscustomobject]@{ codeunitId = $Id; method = $Method } }
    }

    AfterAll {
        if (Test-Path 'function:global:Test-AllSelectedTestsExecuted') { Remove-Item 'function:global:Test-AllSelectedTestsExecuted' -Force }
        if (Test-Path 'function:global:Get-BaseFolder') { Remove-Item 'function:global:Get-BaseFolder' -Force }
        Remove-Item 'variable:global:RticbcFixtureRoot' -Force -ErrorAction SilentlyContinue
        if ($script:fixtureRoot -and (Test-Path $script:fixtureRoot)) { Remove-Item $script:fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It "passes when every declared, non-disabled test in an executed codeunit ran" {
        $results = script:New-ResultsFile @{ '90001 Alpha' = @('A1', 'A2', 'A3') }
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = $results } | Should -BeTrue
    }

    It "fails when a declared test was silently dropped from an executed codeunit" {
        $results = script:New-ResultsFile @{ '90001 Alpha' = @('A1', 'A2') } # A3 never ran
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = $results } | Should -BeFalse
    }

    It "passes when the only missing test is on the disabled list" {
        $results = script:New-ResultsFile @{ '90001 Alpha' = @('A1', 'A2') }
        $p = @{ JUnitResultFileName = $results; disabledTests = @(script:Disabled -Id 90001 -Method 'A3') }
        Test-AllSelectedTestsExecuted -parameters $p | Should -BeTrue
    }

    It "counts a tolerated result as executed" {
        # The tolerance mechanism re-labels a result "<method> (tolerated)".
        $results = script:New-ResultsFile @{ '90003 Gamma' = @('G1', 'G2 (tolerated)') }
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = $results } | Should -BeTrue
    }

    It "ignores [Test] methods that are commented out in source" {
        # Beta's only live test is B1; the block- and line-commented [Test] methods must not count.
        $results = script:New-ResultsFile @{ '90002 Beta' = @('B1') }
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = $results } | Should -BeTrue
    }

    It "ignores codeunits that produced no results (legitimately filtered out by selection)" {
        # Only Alpha ran; Gamma was not selected, so its declared tests are not expected.
        $results = script:New-ResultsFile @{ '90001 Alpha' = @('A1', 'A2', 'A3') }
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = $results } | Should -BeTrue
    }

    It "reports every silently dropped codeunit, not just the first" {
        $results = script:New-ResultsFile @{
            '90001 Alpha' = @('A1')        # A2, A3 dropped
            '90003 Gamma' = @('G1')        # G2 dropped
        }
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = $results } | Should -BeFalse
    }

    It "skips reconciliation when no result file is available" {
        Test-AllSelectedTestsExecuted -parameters @{ JUnitResultFileName = 'C:\does\not\exist.xml' } | Should -BeTrue
    }
}
