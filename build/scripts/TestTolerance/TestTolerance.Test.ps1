Describe "TestTolerance" {
    BeforeAll {
        Import-Module "$PSScriptRoot\TestTolerance.psm1" -Force

        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("TestTolerance-Tests-" + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        function New-TempFile {
            param([string] $Name, [string] $Content)
            $path = Join-Path $script:tempRoot $Name
            Set-Content -Path $path -Value $Content -Encoding UTF8
            return $path
        }
    }

    AfterAll {
        if (Test-Path $script:tempRoot) {
            Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Test-IsToleranceSupportedBranch" {
        It "supports main" {
            Test-IsToleranceSupportedBranch -Branch 'main' | Should -BeTrue
        }

        It "supports releases/* branches" {
            Test-IsToleranceSupportedBranch -Branch 'releases/26.0' | Should -BeTrue
            Test-IsToleranceSupportedBranch -Branch 'releases/27.1' | Should -BeTrue
        }

        It "rejects feature branches" {
            Test-IsToleranceSupportedBranch -Branch 'feature/foo' | Should -BeFalse
            Test-IsToleranceSupportedBranch -Branch 'mazhelez/test' | Should -BeFalse
        }

        It "rejects empty input" {
            Test-IsToleranceSupportedBranch -Branch '' | Should -BeFalse
        }
    }

    Context "Get-UnstableTestsArtifactName" {
        It "produces a stable name for main" {
            Get-UnstableTestsArtifactName -Branch 'main' | Should -Be 'unstable-tests-main'
        }

        It "normalizes slashes for releases branches" {
            Get-UnstableTestsArtifactName -Branch 'releases/26.0' | Should -Be 'unstable-tests-releases-26.0'
        }

        It "throws on unsupported branches" {
            { Get-UnstableTestsArtifactName -Branch 'feature/foo' } | Should -Throw
        }
    }

    Context "Read-UnstableTestsList" {
        It "returns empty hashtable when file does not exist" {
            $result = Read-UnstableTestsList -Path (Join-Path $script:tempRoot 'does-not-exist.json')
            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
        }

        It "parses a valid unstable tests file" {
            $json = @'
{
  "branch": "main",
  "updatedAt": "2026-04-24T00:00:00Z",
  "tests": [
    { "extensionId": "ext-1", "codeunitId": 100, "codeunitName": "My Codeunit", "testMethod": "TestA", "reason": "timing", "linkedIssue": "https://example/issues/1" },
    { "codeunitId": 200, "codeunitName": "Other Codeunit", "testMethod": "TestB" }
  ]
}
'@
            $path = New-TempFile -Name 'unstable.json' -Content $json
            $result = Read-UnstableTestsList -Path $path
            $result.Count | Should -Be 2
            $result['ext-1::100::testa'].Reason | Should -Be 'timing'
            $result['ext-1::100::testa'].ExtensionId | Should -Be 'ext-1'
            $result['::200::testb'].LinkedIssue | Should -Be ''
        }

        It "returns empty hashtable when file has no tests array" {
            $path = New-TempFile -Name 'empty.json' -Content '{ "branch": "main" }'
            (Read-UnstableTestsList -Path $path).Count | Should -Be 0
        }
    }

    Context "Get-FailedTestsFromResults" {
        It "extracts failed tests from JUnit-style XML" {
            $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="100 My Codeunit" tests="3" failures="1" errors="1">
    <properties>
      <property name="extensionid" value="abc-123" />
    </properties>
    <testcase classname="100 My Codeunit" name="TestPasses" time="0.1" />
    <testcase classname="100 My Codeunit" name="TestFails" time="0.1">
      <failure message="boom">stack</failure>
    </testcase>
    <testcase classname="100 My Codeunit" name="TestErrors" time="0.1">
      <error message="oops">stack</error>
    </testcase>
  </testsuite>
</testsuites>
'@
            $path = New-TempFile -Name 'results.xml' -Content $xml
            $failed = Get-FailedTestsFromResults -Path $path
            $failed.Count | Should -Be 2
            $failed[0].TestMethod | Should -Be 'TestFails'
            $failed[0].FailureMessage | Should -Be 'boom'
            $failed[0].FailureDetail | Should -Be 'stack'
            $failed[0].ExtensionId | Should -Be 'abc-123'
            $failed[0].CodeunitId | Should -Be 100
            $failed[0].CodeunitName | Should -Be 'My Codeunit'
            $failed[0].Key | Should -Be 'abc-123::100::testfails'
            $failed[1].TestMethod | Should -Be 'TestErrors'
            $failed[1].FailureDetail | Should -Be 'stack'
        }

        It "extracts failed tests with empty extensionId when property is missing" {
            $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<testsuite name="Fallback Suite" tests="1" failures="1">
  <testcase name="OnlyTest">
    <failure message="x">y</failure>
  </testcase>
</testsuite>
'@
            $path = New-TempFile -Name 'fallback.xml' -Content $xml
            $failed = Get-FailedTestsFromResults -Path $path
            $failed.Count | Should -Be 1
            $failed[0].CodeunitId | Should -Be 0
            $failed[0].CodeunitName | Should -Be 'Fallback Suite'
            $failed[0].ExtensionId | Should -Be ''
            $failed[0].Key | Should -Be '::0::onlytest'
        }

        It "returns empty list when no failures" {
            $xml = @'
<?xml version="1.0"?>
<testsuites>
  <testsuite name="A" tests="1" failures="0">
    <testcase classname="A" name="OK" />
  </testsuite>
</testsuites>
'@
            $path = New-TempFile -Name 'pass.xml' -Content $xml
            @(Get-FailedTestsFromResults -Path $path).Count | Should -Be 0
        }
    }

    Context "Resolve-TestTolerance" {
        It "splits failures into tolerated and unresolved" {
            $failed = @(
                [pscustomobject]@{ CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1'; Key = (Get-UnstableTestKey -CodeunitId 300 -TestMethod 'T1' -ExtensionId 'ext1') },
                [pscustomobject]@{ CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T2'; FailureMessage = 'm2'; Key = (Get-UnstableTestKey -CodeunitId 300 -TestMethod 'T2' -ExtensionId 'ext1') }
            )
            $unstable = @{
                'ext1::300::t1' = [pscustomobject]@{ CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; Reason = 'unstable'; LinkedIssue = '' }
            }
            $resolution = Resolve-TestTolerance -FailedTests $failed -UnstableTests $unstable
            $resolution.Tolerated.Count | Should -Be 1
            $resolution.Unresolved.Count | Should -Be 1
            $resolution.Tolerated[0].TestMethod | Should -Be 'T1'
            $resolution.Unresolved[0].TestMethod | Should -Be 'T2'
        }

        It "uses extensionId to distinguish tests with the same codeunit and method" {
            $failed = @(
                [pscustomobject]@{ ExtensionId = 'ext-a'; CodeunitId = 600; CodeunitName = 'Suite'; TestMethod = 'Test'; FailureMessage = 'x'; Key = (Get-UnstableTestKey -CodeunitId 600 -TestMethod 'Test' -ExtensionId 'ext-a') },
                [pscustomobject]@{ ExtensionId = 'ext-b'; CodeunitId = 600; CodeunitName = 'Suite'; TestMethod = 'Test'; FailureMessage = 'y'; Key = (Get-UnstableTestKey -CodeunitId 600 -TestMethod 'Test' -ExtensionId 'ext-b') }
            )
            $unstable = @{
                'ext-a::600::test' = [pscustomobject]@{ ExtensionId = 'ext-a'; CodeunitId = 600; CodeunitName = 'Suite'; TestMethod = 'Test'; Reason = 'unstable'; LinkedIssue = '' }
            }
            $resolution = Resolve-TestTolerance -FailedTests $failed -UnstableTests $unstable
            $resolution.Tolerated.Count | Should -Be 1
            $resolution.Unresolved.Count | Should -Be 1
            $resolution.Tolerated[0].ExtensionId | Should -Be 'ext-a'
            $resolution.Unresolved[0].ExtensionId | Should -Be 'ext-b'
        }
    }

    Context "Update-TestResultsForTolerance" {
        It "uses extensionId from properties block to match tolerated tests" {
            $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="600 Suite" tests="2" failures="2" errors="0">
    <properties><property name="extensionid" value="ext-x" /></properties>
    <testcase classname="600 Suite" name="T1"><failure message="m1">s1</failure></testcase>
    <testcase classname="600 Suite" name="T2"><failure message="m2">s2</failure></testcase>
  </testsuite>
</testsuites>
'@
            $path = New-TempFile -Name 'props-update.xml' -Content $xml
            $tolerated = @(
                [pscustomobject]@{ ExtensionId = 'ext-x'; CodeunitId = 600; CodeunitName = 'Suite'; TestMethod = 'T1'; FailureMessage = 'm1'; Reason = 'unstable'; LinkedIssue = '' }
            )
            Update-TestResultsForTolerance -Path $path -ToleratedTests $tolerated

            [xml]$result = Get-Content -Raw -Path $path
            $suite = $result.DocumentElement.testsuite
            $suite.GetAttribute('failures') | Should -Be '1'
            $suite.SelectSingleNode("testcase[@name='T1']").SelectSingleNode('failure') | Should -BeNullOrEmpty
            $suite.SelectSingleNode("testcase[@name='T2']").SelectSingleNode('failure') | Should -Not -BeNullOrEmpty
        }

        It "removes failure nodes for tolerated tests and decrements failure count" {
            $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="300 A" tests="2" failures="2" errors="0">
    <testcase classname="300 A" name="T1"><failure message="m1">s1</failure></testcase>
    <testcase classname="300 A" name="T2"><failure message="m2">s2</failure></testcase>
  </testsuite>
</testsuites>
'@
            $path = New-TempFile -Name 'update.xml' -Content $xml
            $tolerated = @(
                [pscustomobject]@{ CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1'; Reason = 'unstable'; LinkedIssue = '' }
            )
            Update-TestResultsForTolerance -Path $path -ToleratedTests $tolerated

            [xml]$result = Get-Content -Raw -Path $path
            $suite = $result.DocumentElement.testsuite
            $suite.GetAttribute('failures') | Should -Be '1'

            $t1 = $suite.SelectSingleNode("testcase[@name='T1']")
            $t1.SelectSingleNode('failure') | Should -BeNullOrEmpty
            $t1.SelectSingleNode('system-out').InnerText | Should -Match 'TOLERATED'

            $t2 = $suite.SelectSingleNode("testcase[@name='T2']")
            $t2.SelectSingleNode('failure') | Should -Not -BeNullOrEmpty
        }

        It "is a no-op when nothing is tolerated" {
            $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="300 A" tests="1" failures="1">
    <testcase classname="300 A" name="T1"><failure message="m1">s1</failure></testcase>
  </testsuite>
</testsuites>
'@
            $path = New-TempFile -Name 'noop.xml' -Content $xml
            $original = Get-Content -Raw -Path $path
            Update-TestResultsForTolerance -Path $path -ToleratedTests (New-Object System.Collections.Generic.List[object])
            (Get-Content -Raw -Path $path) | Should -Be $original
        }
    }

    Context "Test-ShouldTolerateFailures" {

        It "returns false when unstable tests path is empty" {
            Test-ShouldTolerateFailures -TestResultsPath 'any' -UnstableTestsPath '' | Should -BeFalse
        }

        It "returns false when unstable tests file does not exist" {
            Test-ShouldTolerateFailures -TestResultsPath 'any' -UnstableTestsPath (Join-Path $script:tempRoot 'no-file.json') | Should -BeFalse
        }

        It "returns false when test results file does not exist" {
            $unstablePath = New-TempFile -Name 'unstable-for-tolerate.json' -Content '{"tests":[{"extensionId":"ext1","codeunitId":300,"codeunitName":"A","testMethod":"T1"}]}'
            Test-ShouldTolerateFailures -TestResultsPath (Join-Path $script:tempRoot 'no-results.xml') -UnstableTestsPath $unstablePath | Should -BeFalse
        }

        It "returns false when unstable list is empty" {
            $unstablePath = New-TempFile -Name 'empty-unstable.json' -Content '{"tests":[]}'
            $xmlPath = New-TempFile -Name 'results-for-empty.xml' -Content @'
<?xml version="1.0"?>
<testsuites><testsuite name="300 A" tests="1" failures="1"><testcase classname="300 A" name="T1"><failure message="x">y</failure></testcase></testsuite></testsuites>
'@
            Test-ShouldTolerateFailures -TestResultsPath $xmlPath -UnstableTestsPath $unstablePath | Should -BeFalse
        }

        It "returns true and rewrites XML when all failures are tolerated" {
            $unstablePath = New-TempFile -Name 'unstable-all.json' -Content '{"tests":[{"extensionId":"ext1","codeunitId":300,"codeunitName":"A","testMethod":"T1","reason":"unstable"}]}'
            $xmlPath = New-TempFile -Name 'results-all-tolerated.xml' -Content @'
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="300 A" tests="1" failures="1">
    <properties><property name="extensionid" value="ext1" /></properties>
    <testcase classname="300 A" name="T1"><failure message="boom">stack</failure></testcase>
  </testsuite>
</testsuites>
'@
            Test-ShouldTolerateFailures -TestResultsPath $xmlPath -UnstableTestsPath $unstablePath | Should -BeTrue

            # Verify the XML was rewritten
            [xml]$result = Get-Content -Raw -Path $xmlPath
            $result.DocumentElement.testsuite.GetAttribute('failures') | Should -Be '0'
        }

        It "returns false when some failures are not tolerated" {
            $unstablePath = New-TempFile -Name 'unstable-partial.json' -Content '{"tests":[{"extensionId":"ext1","codeunitId":300,"codeunitName":"A","testMethod":"T1"}]}'
            $xmlPath = New-TempFile -Name 'results-partial.xml' -Content @'
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="300 A" tests="2" failures="2">
    <properties><property name="extensionid" value="ext1" /></properties>
    <testcase classname="300 A" name="T1"><failure message="m1">s1</failure></testcase>
    <testcase classname="300 A" name="T2"><failure message="m2">s2</failure></testcase>
  </testsuite>
</testsuites>
'@
            Test-ShouldTolerateFailures -TestResultsPath $xmlPath -UnstableTestsPath $unstablePath | Should -BeFalse
        }

        It "returns true when test results have no failures" {
            $unstablePath = New-TempFile -Name 'unstable-nofail.json' -Content '{"tests":[{"extensionId":"ext1","codeunitId":300,"codeunitName":"A","testMethod":"T1"}]}'
            $xmlPath = New-TempFile -Name 'results-nofail.xml' -Content @'
<?xml version="1.0"?>
<testsuites><testsuite name="300 A" tests="1" failures="0"><properties><property name="extensionid" value="ext1" /></properties><testcase classname="300 A" name="T1" /></testsuite></testsuites>
'@
            Test-ShouldTolerateFailures -TestResultsPath $xmlPath -UnstableTestsPath $unstablePath | Should -BeTrue
        }
    }

    Context "Receive-UnstableTestsArtifact" {
        It "returns null on unsupported branch" {
            Receive-UnstableTestsArtifact -Branch 'feature/foo' -OutputDirectory $script:tempRoot | Should -BeNullOrEmpty
        }

        It "returns null when no token is available" {
            $savedGhToken = $env:GH_TOKEN
            $savedGithubToken = $env:GITHUB_TOKEN
            $savedToken = $env:_token
            try {
                $env:GH_TOKEN = $null
                $env:GITHUB_TOKEN = $null
                $env:_token = $null
                Receive-UnstableTestsArtifact -Branch 'main' -OutputDirectory $script:tempRoot | Should -BeNullOrEmpty
            }
            finally {
                $env:GH_TOKEN = $savedGhToken
                $env:GITHUB_TOKEN = $savedGithubToken
                $env:_token = $savedToken
            }
        }
    }

    Context "Update-UnstableTestsList" {
        It "marks any failed test as unstable, including single failures" {
            $failed = @{
                '::300::t1' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'boom' }
            }

            $result = Update-UnstableTestsList -FailedTests $failed
            $result.Count | Should -Be 1
            $result.ContainsKey('::300::t1') | Should -BeTrue
        }

        It "marks all failed tests across the window as unstable" {
            $failed = @{
                '::300::t1' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1' }
                '::400::t2' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 400; CodeunitName = 'B'; TestMethod = 'T2'; FailureMessage = 'm2' }
            }

            $result = Update-UnstableTestsList -FailedTests $failed
            $result.Count | Should -Be 2
            $result['::300::t1'].Reason | Should -Match 'Auto-detected'
            $result['::400::t2'].Reason | Should -Match 'Auto-detected'
        }

        It "reason mentions the run window" {
            $failed = @{
                '::300::t1' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'x' }
            }

            $result = Update-UnstableTestsList -FailedTests $failed -RunWindow 5
            $result['::300::t1'].Reason | Should -Match '5'
        }

        It "returns empty when no tests failed" {
            $result = Update-UnstableTestsList -FailedTests @{}
            $result.Count | Should -Be 0
        }

        It "preserves ExtensionId" {
            $failed = @{
                'ext-1::300::t1' = [pscustomobject]@{ ExtensionId = 'ext-1'; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1'; FailureDetail = 's1' }
                'ext-2::400::t2' = [pscustomobject]@{ ExtensionId = 'ext-2'; CodeunitId = 400; CodeunitName = 'B'; TestMethod = 'T2'; FailureMessage = 'm2'; FailureDetail = 's2' }
            }

            $result = Update-UnstableTestsList -FailedTests $failed
            $result['ext-1::300::t1'].ExtensionId | Should -Be 'ext-1'
            $result['ext-2::400::t2'].ExtensionId | Should -Be 'ext-2'
            $result['ext-1::300::t1'].FailureMessage | Should -Be 'm1'
            $result['ext-1::300::t1'].FailureDetail | Should -Be 's1'
        }
    }
}
