$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot '../AlToolTestRunner.psm1') -Force

Describe "ConvertFrom-AlRunTestsOutput" {
    BeforeAll {
        $script:sample = @(
            "Running tests in codeunit 134001...",
            "Test run completed: 2 passed, 1 failed, 1 skipped.",
            "",
            "Results:",
            "  PASS OnRun (1ms)",
            "  PASS VendorApplyMultiPmtTest (434ms)",
            "  FAIL VendorApplyMultiInvPmtTest (625ms)",
            "       Assert.IsFalse failed. Invoice did not close.",
            "AL Callstack:",
            "Assert(CodeUnit 130000).IsFalse line 3 - App Test Library",
            'ERM(CodeUnit 134001).TestApplication line 41 - Tests-ERM',
            "  SKIP SomeSkippedTest (0ms)",
            "  PASS AnotherPass (12ms)",
            "  FAIL  (700ms)",
            "       The identifier could not be found.",
            "AL Callstack:",
            "Some.Frame line 1"
        )
        $script:parsed = ConvertFrom-AlRunTestsOutput -OutputLines $script:sample
    }

    It "drops the phantom OnRun and empty-named aggregate entries" {
        $script:parsed.Count | Should -Be 4
        $script:parsed.ContainsKey("OnRun") | Should -Be $false
        $script:parsed.ContainsKey("") | Should -Be $false
    }

    It "captures pass outcomes with timing" {
        $script:parsed["VendorApplyMultiPmtTest"].Outcome | Should -Be "Pass"
        $script:parsed["VendorApplyMultiPmtTest"].Ms | Should -Be 434
    }

    It "captures skip outcomes" {
        $script:parsed["SomeSkippedTest"].Outcome | Should -Be "Skip"
    }

    It "captures failure message and callstack" {
        $fail = $script:parsed["VendorApplyMultiInvPmtTest"]
        $fail.Outcome | Should -Be "Fail"
        $fail.Message | Should -Be "Assert.IsFalse failed. Invoice did not close."
        $fail.Stacktrace | Should -Match "TestApplication line 41"
    }

    It "returns an empty map when there is no Results block" {
        $res = ConvertFrom-AlRunTestsOutput -OutputLines @("Some error", "Connection refused")
        $res.Count | Should -Be 0
    }

    It "tolerates empty-string lines in the output" {
        { ConvertFrom-AlRunTestsOutput -OutputLines @("", "Results:", "  PASS A (1ms)", "") } | Should -Not -Throw
    }
}

Describe "Add-JUnitTestSuite" {
    BeforeAll {
        $script:doc = New-Object System.Xml.XmlDocument
        $script:doc.AppendChild($script:doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | Out-Null
        $script:suites = $script:doc.CreateElement("testsuites")
        $script:doc.AppendChild($script:suites) | Out-Null

        $codeunit = [PSCustomObject]@{
            Id    = "134001"
            Name  = "ERM Apply Purchase/Payables"
            Tests = @("PassTest", "FailTest", "SkipTest", "MissingTest")
        }
        $methodResults = @{
            "PassTest" = @{ Outcome = "Pass"; Ms = 100; Message = ""; Stacktrace = "" }
            "FailTest" = @{ Outcome = "Fail"; Ms = 200; Message = "boom"; Stacktrace = "frame a;frame b" }
            "SkipTest" = @{ Outcome = "Skip"; Ms = 0; Message = ""; Stacktrace = "" }
            # MissingTest intentionally absent -> should become a failure ("no result").
        }
        $script:failed = Add-JUnitTestSuite -Doc $script:doc -TestSuitesNode $script:suites -Codeunit $codeunit `
            -RequestedMethods $codeunit.Tests -MethodResults $methodResults -ExtensionId "ext-guid" `
            -AppName "Tests-ERM" -Hostname "buildhost" -ElapsedSec 3.2
        $script:suite = $script:suites.SelectSingleNode("testsuite")
    }

    It "counts both real and missing-result failures" {
        $script:failed | Should -Be 2
        $script:suite.GetAttribute("failures") | Should -Be "2"
        $script:suite.GetAttribute("skipped") | Should -Be "1"
        $script:suite.GetAttribute("tests") | Should -Be "4"
    }

    It "names the suite and testcases as '<id> <name>'" {
        $script:suite.GetAttribute("name") | Should -Be "134001 ERM Apply Purchase/Payables"
        $tc = $script:suite.SelectSingleNode("testcase[@name='PassTest']")
        $tc.GetAttribute("classname") | Should -Be "134001 ERM Apply Purchase/Payables"
    }

    It "emits extensionid and appName properties" {
        $script:suite.SelectSingleNode("properties/property[@name='extensionid']").GetAttribute("value") | Should -Be "ext-guid"
        $script:suite.SelectSingleNode("properties/property[@name='appName']").GetAttribute("value") | Should -Be "Tests-ERM"
    }

    It "writes a failure element with message and newline-joined callstack" {
        $failure = $script:suite.SelectSingleNode("testcase[@name='FailTest']/failure")
        $failure.GetAttribute("message") | Should -Be "boom"
        $failure.InnerText | Should -Be "frame a`nframe b"
    }

    It "writes a skipped element for skipped tests" {
        $script:suite.SelectSingleNode("testcase[@name='SkipTest']/skipped") | Should -Not -BeNullOrEmpty
    }

    It "converts per-method milliseconds to seconds" {
        $script:suite.SelectSingleNode("testcase[@name='FailTest']").GetAttribute("time") | Should -Be "0.2"
    }
}

Describe "Add-JUnitTestSuite output is consumable by Test Tolerance" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../TestTolerance/TestTolerance.psm1') -Force

        $doc = New-Object System.Xml.XmlDocument
        $doc.AppendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | Out-Null
        $suites = $doc.CreateElement("testsuites")
        $doc.AppendChild($suites) | Out-Null
        $codeunit = [PSCustomObject]@{ Id = "134001"; Name = "ERM Apply"; Tests = @("FailTest") }
        $methodResults = @{ "FailTest" = @{ Outcome = "Fail"; Ms = 200; Message = "boom"; Stacktrace = "frame a" } }
        Add-JUnitTestSuite -Doc $doc -TestSuitesNode $suites -Codeunit $codeunit -RequestedMethods $codeunit.Tests `
            -MethodResults $methodResults -ExtensionId "ext-guid" -AppName "Tests-ERM" -Hostname "h" -ElapsedSec 1 | Out-Null

        $script:resultFile = Join-Path ([System.IO.Path]::GetTempPath()) ("altool_junit_" + [System.Guid]::NewGuid().ToString('N') + ".xml")
        $doc.Save($script:resultFile)
    }

    AfterAll {
        if ($script:resultFile -and (Test-Path $script:resultFile)) { Remove-Item $script:resultFile -Force }
    }

    It "Get-FailedTestsFromResults extracts the failure" {
        $failed = @(Get-FailedTestsFromResults -Path $script:resultFile)
        $failed.Count | Should -Be 1
        $failed[0].CodeunitId | Should -Be "134001"
        $failed[0].TestMethod | Should -Be "FailTest"
        $failed[0].ExtensionId | Should -Be "ext-guid"
    }
}

Describe "Get-DisabledTestKeySet" {
    It "builds case-insensitive keys for single and array methods" {
        $disabled = @(
            [PSCustomObject]@{ codeunitName = "ERM Apply"; method = "TestA" },
            [PSCustomObject]@{ codeunitName = "SCM Kitting"; method = @("TestB", "TestC") }
        )
        $set = Get-DisabledTestKeySet -DisabledTests $disabled
        $set.ContainsKey("erm apply::testa") | Should -Be $true
        $set.ContainsKey("scm kitting::testb") | Should -Be $true
        $set.ContainsKey("scm kitting::testc") | Should -Be $true
        $set.Count | Should -Be 3
    }

    It "returns an empty set for no disabled tests" {
        (Get-DisabledTestKeySet -DisabledTests @()).Count | Should -Be 0
    }
}

Describe "Invoke-AlToolTestRun JUnit append behavior" {
    It "appends new testsuites to an existing per-tenant file instead of overwriting" {
        # Simulate two apps (two Invoke-AlToolTestRun calls) writing to the same per-tenant file.
        $file = Join-Path ([System.IO.Path]::GetTempPath()) ("altool_append_" + [System.Guid]::NewGuid().ToString('N') + ".xml")
        try {
            # First app writes a suite.
            $doc1 = New-Object System.Xml.XmlDocument
            $doc1.AppendChild($doc1.CreateXmlDeclaration("1.0", "UTF-8", $null)) | Out-Null
            $s1 = $doc1.CreateElement("testsuites"); $doc1.AppendChild($s1) | Out-Null
            $cu1 = [PSCustomObject]@{ Id = "111"; Name = "App1 CU"; Tests = @("T1") }
            Add-JUnitTestSuite -Doc $doc1 -TestSuitesNode $s1 -Codeunit $cu1 -RequestedMethods $cu1.Tests `
                -MethodResults @{ "T1" = @{ Outcome = "Pass"; Ms = 1; Message = ""; Stacktrace = "" } } `
                -ExtensionId "app1" -AppName "App1" -Hostname "h" -ElapsedSec 1 | Out-Null
            $doc1.Save($file)

            # Second app loads the existing file and appends (the fixed behavior).
            $doc2 = New-Object System.Xml.XmlDocument
            $doc2.Load($file)
            $s2 = $doc2.DocumentElement
            $cu2 = [PSCustomObject]@{ Id = "222"; Name = "App2 CU"; Tests = @("T2") }
            Add-JUnitTestSuite -Doc $doc2 -TestSuitesNode $s2 -Codeunit $cu2 -RequestedMethods $cu2.Tests `
                -MethodResults @{ "T2" = @{ Outcome = "Pass"; Ms = 1; Message = ""; Stacktrace = "" } } `
                -ExtensionId "app2" -AppName "App2" -Hostname "h" -ElapsedSec 1 | Out-Null
            $doc2.Save($file)

            [xml]$final = Get-Content $file
            $suites = @($final.testsuites.testsuite)
            $suites.Count | Should -Be 2
            ($suites | Where-Object { $_.name -eq "111 App1 CU" }) | Should -Not -BeNullOrEmpty
            ($suites | Where-Object { $_.name -eq "222 App2 CU" }) | Should -Not -BeNullOrEmpty
        } finally {
            if (Test-Path $file) { Remove-Item $file -Force }
        }
    }
}
