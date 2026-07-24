Describe "TestTolerance" {
    BeforeAll {
        Import-Module "$PSScriptRoot/TestTolerance.psm1" -Force

        $script:tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("TestTolerance-Tests-" + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        function New-TempFile {
            param([string] $Name, [string] $Content)
            $path = Join-Path -Path $script:tempRoot -ChildPath $Name
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
            $result = Read-UnstableTestsList -Path (Join-Path -Path $script:tempRoot -ChildPath 'does-not-exist.json')
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
            $suite.GetAttribute('skipped') | Should -Be '1'
            $t1 = $suite.SelectSingleNode("testcase[@name='T1 (tolerated)']")
            $t1 | Should -Not -BeNullOrEmpty
            $t1.SelectSingleNode('failure') | Should -BeNullOrEmpty
            $t1.SelectSingleNode('skipped') | Should -Not -BeNullOrEmpty
            $suite.SelectSingleNode("testcase[@name='T2']").SelectSingleNode('failure') | Should -Not -BeNullOrEmpty
        }

        It "reclassifies tolerated failures as skipped and decrements failure count" {
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
            $suite.GetAttribute('skipped') | Should -Be '1'

            $t1 = $suite.SelectSingleNode("testcase[@name='T1 (tolerated)']")
            $t1 | Should -Not -BeNullOrEmpty
            $t1.SelectSingleNode('failure') | Should -BeNullOrEmpty
            $skipped = $t1.SelectSingleNode('skipped')
            $skipped | Should -Not -BeNullOrEmpty
            $skipped.GetAttribute('message') | Should -Match 'tolerated'
            $skipped.InnerText | Should -Match 'm1'
            $t1.SelectSingleNode('system-out').InnerText | Should -Match 'TOLERATED'

            $t2 = $suite.SelectSingleNode("testcase[@name='T2']")
            $t2.SelectSingleNode('failure') | Should -Not -BeNullOrEmpty
            $t2.SelectSingleNode('skipped') | Should -BeNullOrEmpty
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
            Test-ShouldTolerateFailures -TestResultsPath 'any' -UnstableTestsPath (Join-Path -Path $script:tempRoot -ChildPath 'no-file.json') | Should -BeFalse
        }

        It "returns false when test results file does not exist" {
            $unstablePath = New-TempFile -Name 'unstable-for-tolerate.json' -Content '{"tests":[{"extensionId":"ext1","codeunitId":300,"codeunitName":"A","testMethod":"T1"}]}'
            Test-ShouldTolerateFailures -TestResultsPath (Join-Path -Path $script:tempRoot -ChildPath 'no-results.xml') -UnstableTestsPath $unstablePath | Should -BeFalse
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

        It "marks all failed tests across the artifacts as unstable" {
            $failed = @{
                '::300::t1' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1' }
                '::400::t2' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 400; CodeunitName = 'B'; TestMethod = 'T2'; FailureMessage = 'm2' }
            }

            $result = Update-UnstableTestsList -FailedTests $failed
            $result.Count | Should -Be 2
            $result['::300::t1'].Reason | Should -Match 'Auto-detected'
            $result['::400::t2'].Reason | Should -Match 'Auto-detected'
        }

        It "reason mentions the run count" {
            $failed = @{
                '::300::t1' = [pscustomobject]@{ ExtensionId = ''; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'x' }
            }

            $result = Update-UnstableTestsList -FailedTests $failed -RunCount 5
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

    Context "Add-FailedTestsToUnstableTests" {
        It "appends new failed tests to an empty existing list" {
            $failed = @{
                'ext-1::300::t1' = [pscustomobject]@{ ExtensionId = 'ext-1'; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1'; FailureDetail = 's1'; SourceRunId = '999' }
            }

            $merged = @(Add-FailedTestsToUnstableTests -ExistingTests @() -FailedTests $failed -Repository 'microsoft/BCApps')
            $merged.Count | Should -Be 1
            $merged[0].extensionId | Should -Be 'ext-1'
            $merged[0].codeunitId | Should -Be 300
            $merged[0].testMethod | Should -Be 'T1'
            $merged[0].reason | Should -Match '999'
            $merged[0].sourceRunUrl | Should -Be 'https://github.com/microsoft/BCApps/actions/runs/999'
        }

        It "preserves existing entries verbatim and only appends new ones" {
            $existing = @(
                [pscustomobject]@{ extensionId = 'ext-1'; codeunitId = 300; codeunitName = 'A'; testMethod = 'T1'; failureMessage = 'old'; failureDetail = 'olddetail'; reason = 'pre-existing'; linkedIssue = 'https://example/1'; sourceRunUrl = 'https://example/run' }
            )
            $failed = @{
                'ext-2::400::t2' = [pscustomobject]@{ ExtensionId = 'ext-2'; CodeunitId = 400; CodeunitName = 'B'; TestMethod = 'T2'; FailureMessage = 'm2'; FailureDetail = 's2'; SourceRunId = '1000' }
            }

            $merged = @(Add-FailedTestsToUnstableTests -ExistingTests $existing -FailedTests $failed -Repository 'owner/repo')
            $merged.Count | Should -Be 2
            $merged[0].reason | Should -Be 'pre-existing'
            $merged[0].linkedIssue | Should -Be 'https://example/1'
            $merged[1].testMethod | Should -Be 'T2'
        }

        It "does not duplicate a failed test that is already in the list" {
            $existing = @(
                [pscustomobject]@{ extensionId = 'ext-1'; codeunitId = 300; codeunitName = 'A'; testMethod = 'T1'; reason = 'pre-existing' }
            )
            $failed = @{
                'ext-1::300::t1' = [pscustomobject]@{ ExtensionId = 'ext-1'; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1'; SourceRunId = '1001' }
            }

            $merged = @(Add-FailedTestsToUnstableTests -ExistingTests $existing -FailedTests $failed -Repository 'owner/repo')
            $merged.Count | Should -Be 1
            $merged[0].reason | Should -Be 'pre-existing'
        }

        It "returns existing list unchanged when there are no failed tests" {
            $existing = @(
                [pscustomobject]@{ extensionId = 'ext-1'; codeunitId = 300; codeunitName = 'A'; testMethod = 'T1'; reason = 'pre-existing' }
            )

            $merged = @(Add-FailedTestsToUnstableTests -ExistingTests $existing -FailedTests @{} -Repository 'owner/repo')
            $merged.Count | Should -Be 1
            $merged[0].testMethod | Should -Be 'T1'
        }

        It "preserves existing entries with an unexpected/legacy shape (missing testMethod)" {
            $existing = @(
                [pscustomobject]@{ codeunit = '300'; testMethod = ''; note = 'legacy' },
                [pscustomobject]@{ extensionId = 'ext-1'; codeunitId = 300; codeunitName = 'A'; testMethod = 'T1'; reason = 'pre-existing' }
            )
            $failed = @{
                'ext-2::400::t2' = [pscustomobject]@{ ExtensionId = 'ext-2'; CodeunitId = 400; CodeunitName = 'B'; TestMethod = 'T2'; FailureMessage = 'm2'; SourceRunId = '1002' }
            }

            $merged = @(Add-FailedTestsToUnstableTests -ExistingTests $existing -FailedTests $failed -Repository 'owner/repo')
            $merged.Count | Should -Be 3
            $merged[0].note | Should -Be 'legacy'
            $merged[1].reason | Should -Be 'pre-existing'
            $merged[2].testMethod | Should -Be 'T2'
        }

        It "uses the test's own Reason when the failed test carries one" {
            $failed = @{
                'ext-1::300::t1' = [pscustomobject]@{ ExtensionId = 'ext-1'; CodeunitId = 300; CodeunitName = 'A'; TestMethod = 'T1'; FailureMessage = 'm1'; SourceRunId = '2001'; Reason = 'Auto-detected: failed on 3 distinct PRs' }
            }

            $merged = @(Add-FailedTestsToUnstableTests -ExistingTests @() -FailedTests $failed -Repository 'owner/repo')
            $merged.Count | Should -Be 1
            $merged[0].reason | Should -Be 'Auto-detected: failed on 3 distinct PRs'
        }
    }

    Context "Select-CrossPrUnstableTests" {
        BeforeAll {
            function New-FailedTest {
                param([string] $Ext = '', [int] $Cu = 300, [string] $Method = 'T1', [string] $Key)
                return [pscustomobject]@{
                    ExtensionId    = $Ext
                    CodeunitId     = $Cu
                    CodeunitName   = 'A'
                    TestMethod     = $Method
                    FailureMessage = 'boom'
                    FailureDetail  = 'stack'
                    Key            = $Key
                }
            }
        }

        It "marks a test failing on two distinct PRs as unstable" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FailedTest -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 102; RunId = '901'; FailedTests = @((New-FailedTest -Key '::300::t1')) }
            )
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 1
            $result.ContainsKey('::300::t1') | Should -BeTrue
            $result['::300::t1'].SourceRunId | Should -Be '900'
        }

        It "ignores a test failing on only one PR" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FailedTest -Key '::300::t1')) }
            )
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 0
        }

        It "counts distinct PRs, not runs (same PR retried does not qualify)" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FailedTest -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 101; RunId = '901'; FailedTests = @((New-FailedTest -Key '::300::t1')) }
            )
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 0
        }

        It "distinguishes tests by extensionId" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FailedTest -Ext 'ext-a' -Key 'ext-a::300::t1')) },
                [pscustomobject]@{ PrNumber = 102; RunId = '901'; FailedTests = @((New-FailedTest -Ext 'ext-b' -Key 'ext-b::300::t1')) }
            )
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 0
        }

        It "reason mentions the distinct PR count, branch, and window" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FailedTest -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 102; RunId = '901'; FailedTests = @((New-FailedTest -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 103; RunId = '902'; FailedTests = @((New-FailedTest -Key '::300::t1')) }
            )
            $result = Select-CrossPrUnstableTests -Branch 'releases/26.0' -Observations $obs -MinDistinctPrs 2 -WindowHours 6
            $result['::300::t1'].Reason | Should -Match '3 distinct PRs'
            $result['::300::t1'].Reason | Should -Match 'releases/26.0'
            $result['::300::t1'].Reason | Should -Match '6 h'
        }

        It "respects a higher MinDistinctPrs threshold" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FailedTest -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 102; RunId = '901'; FailedTests = @((New-FailedTest -Key '::300::t1')) }
            )
            (Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 3).Count | Should -Be 0
            (Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 2).Count | Should -Be 1
        }

        It "returns an empty hashtable for no observations" {
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations @() -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 0
        }

        It "skips observations without a PR number" {
            $obs = @(
                [pscustomobject]@{ PrNumber = ''; RunId = '900'; FailedTests = @((New-FailedTest -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 102; RunId = '901'; FailedTests = @((New-FailedTest -Key '::300::t1')) }
            )
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations $obs -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 0
        }

        It "handles observations whose FailedTests is a List[object] (as produced by Find-CrossPrUnstableTests)" {
            # Find-CrossPrUnstableTests stores each run's failures in a System.Collections.Generic.List[object].
            # Wrapping such a list in the array-subexpression operator @() throws "Argument types do not match"
            # on some PowerShell/.NET builds, so the selection must enumerate it without @().
            $obs = New-Object System.Collections.Generic.List[object]
            foreach ($pr in 101, 102) {
                $failed = New-Object System.Collections.Generic.List[object]
                $failed.Add((New-FailedTest -Key '::300::t1')) | Out-Null
                $obs.Add([pscustomobject]@{ PrNumber = $pr; RunId = "90$pr"; FailedTests = $failed }) | Out-Null
            }
            $result = Select-CrossPrUnstableTests -Branch 'main' -Observations $obs.ToArray() -WindowHours 6 -MinDistinctPrs 2
            $result.Count | Should -Be 1
            $result.ContainsKey('::300::t1') | Should -BeTrue
        }
    }

    Context "Get-PrFailingTestsMap" {
        BeforeAll {
            function New-FT {
                param([string] $Key)
                return [pscustomobject]@{ Key = $Key }
            }
        }

        It "returns an empty map for no observations" {
            $map = Get-PrFailingTestsMap -Observations @()
            $map.Count | Should -Be 0
        }

        It "unions a PR's failing tests across its attempts (same PR, multiple runs)" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FT -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 101; RunId = '901'; FailedTests = @((New-FT -Key '::300::t2')) }
            )
            $map = Get-PrFailingTestsMap -Observations $obs
            $map.Count | Should -Be 1
            $map['101'] | Should -Be @('::300::t1', '::300::t2')
        }

        It "de-duplicates the same test failing on several attempts of one PR" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FT -Key '::300::t1')) },
                [pscustomobject]@{ PrNumber = 101; RunId = '901'; FailedTests = @((New-FT -Key '::300::t1')) }
            )
            $map = Get-PrFailingTestsMap -Observations $obs
            $map['101'].Count | Should -Be 1
            $map['101'][0] | Should -Be '::300::t1'
        }

        It "keeps each PR's failing tests separate and orders PRs numerically" {
            $obs = @(
                [pscustomobject]@{ PrNumber = 102; RunId = '901'; FailedTests = @((New-FT -Key '::300::t2')) },
                [pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = @((New-FT -Key '::300::t1')) }
            )
            $map = Get-PrFailingTestsMap -Observations $obs
            @($map.Keys) | Should -Be @('101', '102')
            $map['101'] | Should -Be @('::300::t1')
            $map['102'] | Should -Be @('::300::t2')
        }

        It "handles a FailedTests value that is a List[object]" {
            $failed = New-Object System.Collections.Generic.List[object]
            $failed.Add((New-FT -Key '::300::t1')) | Out-Null
            $obs = @([pscustomobject]@{ PrNumber = 101; RunId = '900'; FailedTests = $failed })
            $map = Get-PrFailingTestsMap -Observations $obs
            $map['101'] | Should -Be @('::300::t1')
        }
    }

    Context "Save-UnstableTestsArtifact" {
        BeforeEach {
            $script:outFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("ut-save-" + [System.Guid]::NewGuid().ToString('N') + ".json")
        }
        AfterEach {
            if ($script:outFile -and (Test-Path $script:outFile)) { Remove-Item $script:outFile -Force -ErrorAction SilentlyContinue }
        }

        It "writes an empty tests array when the list is empty" {
            # An empty run (no Path A recompute, no cross-PR detections) still writes the artifact. The
            # empty case previously threw when the tests value was normalized with [object[]] (which yields
            # $null for an empty collection) and then '.Count' was read under StrictMode.
            Save-UnstableTestsArtifact -Branch 'main' -RunIds @('1') -Tests ([System.Collections.IList]@()) -OutputPath $script:outFile
            $json = Get-Content -Raw -Path $script:outFile | ConvertFrom-Json
            $json.branch | Should -Be 'main'
            @($json.tests).Count | Should -Be 0
        }

        It "writes all entries when Tests is a List[object]" {
            # The combined driver passes the merged list; enumerating a List[object] via @() would throw
            # "Argument types do not match" on some PowerShell/.NET builds.
            $tests = New-Object System.Collections.Generic.List[object]
            $tests.Add([pscustomobject]@{ extensionId = 'e'; codeunitId = 1; testMethod = 'T1' }) | Out-Null
            $tests.Add([pscustomobject]@{ extensionId = 'e'; codeunitId = 2; testMethod = 'T2' }) | Out-Null
            Save-UnstableTestsArtifact -Branch 'main' -RunIds @('1', '2') -Tests $tests -OutputPath $script:outFile
            $json = Get-Content -Raw -Path $script:outFile | ConvertFrom-Json
            @($json.tests).Count | Should -Be 2
        }
    }
}
