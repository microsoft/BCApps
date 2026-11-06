$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

Describe "W1 verification project discovery and workflow" {
    BeforeAll {
        $script:root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
        $script:settings = Get-Content (Join-Path $script:root ".github\AL-Go-Settings.json") -Raw | ConvertFrom-Json
        $script:workflow = Get-Content (Join-Path $script:root ".github\workflows\_BuildALGoProject.yaml") -Raw
    }

    It "selects exactly the production and test W1 projects in every repository override" {
        $expected = @("build\projects\Apps W1", "build\projects\Test Apps W1")
        @($script:settings.projects) | Should -Be $expected
        foreach ($file in @("CICD.settings.json", "Pull Request Build.settings.json")) {
            $override = Get-Content (Join-Path $script:root ".github\$file") -Raw | ConvertFrom-Json
            foreach ($rule in $override.conditionalSettings) {
                @($rule.settings.projects) | Should -Be $expected
            }
        }
        foreach ($project in $expected) {
            Test-Path (Join-Path $script:root "$project\.AL-Go\settings.json") | Should -BeTrue
        }
    }

    It "keeps all existing test folders and adds an explicit unit-test lane" {
        $apps = Get-Content (Join-Path $script:root "build\projects\Apps W1\.AL-Go\settings.json") -Raw | ConvertFrom-Json
        $tests = Get-Content (Join-Path $script:root "build\projects\Test Apps W1\.AL-Go\settings.json") -Raw | ConvertFrom-Json
        @($tests.projectsToTest) | Should -Be @("build\projects\Apps W1")
        @($tests.overwriteSettings) | Should -Contain "buildModes"
        @($tests.buildModes) | Should -Be @("UnitTests", "IntegrationTests", "UncategorizedTests", "LegacyTestsBucket1", "LegacyTestsBucket2")
        $apps.testFolders.Count | Should -BeGreaterThan 100
        foreach ($framework in @("Test Runner", "Test Libraries/Permissions Mock")) {
            $apps.appFolders | Should -Contain "../../../src/Tools/Test Framework/$framework"
        }
    }

    It "requires native execution and prepares the tracked custom tool before tests" {
        $script:workflow | Should -Match "BCAPPS_ALTOOL_VERIFICATION: 'true'"
        $script:workflow | Should -Match 'BCAPPS_FRAMEWORK_APPS_JSON:.*DownloadedApps'
        $script:workflow | Should -Match 'dotnet-version: ''10.0.x'''
        $script:workflow | Should -Match 'BCH fallback is forbidden'
        $script:workflow | Should -Not -Match 'CodeCoverage|BCAPPS_ALTOOL_URL'
        $script:workflow.IndexOf("- name: Build") | Should -BeLessThan $script:workflow.IndexOf("- name: Run Tests")
        $script:workflow.IndexOf("- name: Prepare verification ALTool") | Should -BeLessThan $script:workflow.IndexOf("- name: Run Tests")
        $guard = "inputs.project == 'build/projects/Test Apps W1' || inputs.project == 'build\projects\Test Apps W1'"
        @([regex]::Matches($script:workflow, [regex]::Escape($guard))).Count | Should -Be 3
    }

    It "does not let the pinned analyzer report infrastructure error cases as passes" {
        $script:workflow | Should -Match 'Write-BcAppsNativeTestSummary'
        $script:workflow | Should -Match "steps.nativeTestSummary.outputs.hasInfrastructureErrors != 'true'"
        $script:workflow.IndexOf("- name: Report native test infrastructure errors") |
            Should -BeLessThan $script:workflow.IndexOf("- name: Analyze Test Results")
        $script:workflow.IndexOf("- name: Publish artifacts - test results") |
            Should -BeLessThan $script:workflow.IndexOf("- name: Report native test infrastructure errors")
    }

    It "pins the tracked archive to the exact verified staged-source build" {
        $provenance = Get-Content (Join-Path $script:root "build\scripts\VerificationAlTool.json") -Raw | ConvertFrom-Json
        $zip = Join-Path $script:root "build\tools\altool-dev-net10.zip"
        (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash | Should -Be $provenance.archiveSha256
        $provenance.stagedSourcePatchSha256 | Should -Be "E9EA98940D4CD6D687502CF3109C461F6348F3D8311BB54C7DF734D6D6FBC527"
    }

    It "uses the existing clean-container and Global publication overrides before native initialization" {
        $newContainer = Get-Content (Join-Path $script:root "build\scripts\NewBcContainer.ps1") -Raw
        $publish = Get-Content (Join-Path $script:root "build\scripts\PublishBcContainerApp.ps1") -Raw
        $toolkit = Get-Content (Join-Path $script:root "build\projects\Test Apps W1\.AL-Go\ImportTestToolkitToBcContainer.ps1") -Raw
        $importData = Get-Content (Join-Path $script:root "build\scripts\ImportTestDataInBcContainer.ps1") -Raw
        $newContainer | Should -Match '\$AppsToUnpublish = @\("All"\)'
        $newContainer | Should -Match 'Unpublish-BcContainerApp'
        $publish | Should -Match '\$parameters\["scope"\] = "Global"'
        $publish | Should -Not -Match 'useDevEndpoint|Test Runner|Permissions Mock'
        $toolkit | Should -Match 'Skipping Test Toolkit import'
        $importData.IndexOf("Install-AllApps -ContainerName") | Should -BeLessThan $importData.LastIndexOf("New-AdditionalTenants -ContainerName")
    }
}

Describe "Quality permission fixture CI compiler contracts" {
    It "omits compiler-rejected unused import <Namespace> from <File>" -ForEach @(
        @{ File = "QltyTestsPermissionFixture.Codeunit.al"; Namespace = "System.Security.User" }
        @{ File = "QltyTestsPermissionFixture.Codeunit.al"; Namespace = "System.Testability" }
        @{ File = "QltyTestsPermissionMgmt.Codeunit.al"; Namespace = "System.Testability" }
    ) {
        $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
        $source = Get-Content (Join-Path $root "src\Apps\W1\Quality Management\test\src\$File") -Raw
        # CI run 42217433860 reports AL0792 for these imports under the base ruleset.
        $source | Should -Not -Match "(?m)^using $([regex]::Escape($Namespace));\r?$"
    }
}

Describe "Native ALTool verification adapter" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot "..\ParallelTestExecution.psm1") -Force
        Import-Module (Join-Path $PSScriptRoot "..\AlToolTestAdapter.psm1") -Force
        $script:fixture = New-Module -Name BcAppsActionRunnerFixture -ScriptBlock {
            function Get-AlToolConnection { param($ContainerName) throw "Must be mocked: $ContainerName" }
            function Get-DisabledTestKeySet { param($DisabledTests) throw "Must be mocked: $DisabledTests" }
            function New-AlTestGroupsFile {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test stub; every invocation is mocked.')]
                param($Codeunits)
                throw "Must be mocked: $Codeunits"
            }
            function Invoke-AlNativeCommand { param($FilePath, $ArgumentList) throw "Must be mocked: $FilePath $ArgumentList" }
            function ConvertFrom-AlTestGroupsOutput { param($OutputLines) throw "Must be mocked: $OutputLines" }
            function Add-JUnitTestSuite {
                param($Doc, $TestSuitesNode, $Codeunit, $RequestedMethods, $MethodResults, $ExtensionId, $AppName, $Hostname)
                $null = $Doc, $TestSuitesNode, $Codeunit, $RequestedMethods, $MethodResults, $ExtensionId, $AppName, $Hostname
                throw "Must be mocked"
            }
        }
        Import-Module $script:fixture
        $script:credential = [pscredential]::new("test-user", [securestring]::new())
        $script:savedUsername = $env:BC_SERVER_USERNAME
        $script:savedPassword = $env:BC_SERVER_PASSWORD
    }

    Describe "Pinned AL-Go native contracts" -Skip:([string]::IsNullOrWhiteSpace($env:BCAPPS_ALGO_COVERAGE_ROOT)) {
        BeforeAll {
            $script:root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
            $script:settings = Get-Content (Join-Path $script:root ".github\AL-Go-Settings.json") -Raw | ConvertFrom-Json
            $script:actionModulePath = Join-Path $env:BCAPPS_ALGO_COVERAGE_ROOT "Actions\RunTests\AlToolTestRunner.psm1"
            $script:actionModule = Import-Module $script:actionModulePath -PassThru
            Import-Module (Join-Path $PSScriptRoot "..\AlToolTestAdapter.psm1") -Force
        }

        BeforeEach {
            Mock -ModuleName AlToolTestAdapter Import-Module { $script:actionModule }
        }

        It "discovers only the two W1 project IDs using the actual AL-Go helper" {
            $projects = & $script:actionModule {
                param($root)
                $settings = Get-Content (Join-Path $root ".github\AL-Go-Settings.json") -Raw | ConvertFrom-Json
                GetProjectsFromRepository -baseFolder $root -projectsFromSettings $settings.projects
            } $script:root
            @($projects) | Should -Be @("build\projects\Apps W1", "build\projects\Test Apps W1")
        }

        It "resolves the full pinned dependency graph and build matrix in Windows PowerShell 5.1" {
            if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
                Set-ItResult -Skipped -Because "The CI action uses Windows PowerShell."
                return
            }
            $shell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
            $resultPath = Join-Path $TestDrive "project-graph.json"
            $output = & $shell -NoProfile -NonInteractive -ExecutionPolicy Bypass `
                -File (Join-Path $PSScriptRoot "Invoke-W1ProjectGraph.ps1") `
                -RepositoryRoot $script:root -ALGoRoot $env:BCAPPS_ALGO_COVERAGE_ROOT `
                -ResultPath $resultPath 2>&1
            $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
            $results = @(Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json)
            @($results.Trigger) | Should -Be @("workflow_dispatch", "push", "merge_group")
            $production = "build\projects\Apps W1"
            $tests = "build\projects\Test Apps W1"
            foreach ($result in $results) {
                $result.Shell | Should -BeLike "5.1.*"
                @($result.Projects) | Should -Be @($production, $tests)
                @($result.Selected) | Should -Be @($production, $tests)
                @($result.Dependencies.$tests) | Should -Be @($production)
                $result.BuildOrder.Count | Should -Be 2
                @($result.BuildOrder[0].projects) | Should -Be @($production)
                @($result.BuildOrder[1].projects) | Should -Be @($tests)
                @($result.BuildOrder[1].buildDimensions.buildMode) | Should -Be @(
                    "UnitTests", "IntegrationTests", "UncategorizedTests", "LegacyTestsBucket1", "LegacyTestsBucket2"
                )
                @($result.BuildOrder[1].buildDimensions | Where-Object codeCoverageExpected).Count | Should -Be 0
            }
        }

        It "preserves CI-generated framework versions above the pinned stock artifact" {
            $version = & $script:actionModule {
                param($root)
                $settings = ReadSettings -baseFolder $root -repoName "microsoft/BCApps" `
                    -project "build/projects/Apps W1" -workflowName "CI/CD" `
                    -branchName "spetersen-microsoft-w1-altool-verification" -trigger "workflow_dispatch"
                $settings.versioningStrategy | Should -Be 0
                $settings.appBuild = $settings.runNumberOffset + 1
                $settings.appRevision = 0
                Get-VersionNumber -Settings $settings
            } $script:root
            $version.BuildNumber | Should -Be 60001
            $version.BuildNumber | Should -BeGreaterThan ([version]$script:settings.artifact.Split("/")[2]).Build
            $readSettings = Get-Content (Join-Path $env:BCAPPS_ALGO_COVERAGE_ROOT "Actions\ReadSettings\ReadSettings.ps1") -Raw
            $readSettings | Should -Match '\$settings.appBuild = \$settings.runNumberOffset \+ \[Int32\]\(\$ENV:GITHUB_RUN_NUMBER\)'
        }

        It "serializes explicit methods and persists unreported methods as infrastructure errors" {
            Mock -ModuleName AlToolTestRunner Get-TestsFromBcContainer {
                [pscustomobject]@{ Id = 50000; Name = "Selected"; Tests = @("First", "Disabled", "Last") }
            }
            Mock -ModuleName AlToolTestRunner Get-BcContainerServerConfiguration {
                @{ ServerInstance = "BC"; DeveloperServicesPort = 7049 }
            }
            Mock -ModuleName AlToolTestRunner Invoke-AlNativeCommand {
                $ArgumentList | Should -Contain "--renewsession"
                $index = [array]::IndexOf($ArgumentList, "--testgroups")
                $groups = @(Get-Content -LiteralPath $ArgumentList[$index + 1] -Raw | ConvertFrom-Json)
                $groups.Count | Should -Be 1
                $groups[0].codeunitId | Should -Be 50000
                @($groups[0].testMethods) | Should -Be @("First", "Last")
                @{
                    ExitCode = 0
                    StandardError = @()
                    StandardOutput = @('{"succeeded":true,"data":{"results":[{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1}]}}')
                }
            }
            $resultPath = Join-Path $TestDrive "actual-results.xml"
            $parameters = @{
                _bcAppsAlToolPath = "verified-altool.exe"
                _bcAppsAlToolModulePath = $script:actionModulePath
                containerName = "mocked"
                credential = [pscredential]::new("test-user", [securestring]::new())
                extensionId = "test-app-id"
                appName = "Tests"
                companyName = "My Company"
                tenant = "default"
                testType = "IntegrationTest"
                disabledTests = @([pscustomobject]@{ codeunitName = "Selected"; method = "Disabled" })
                JUnitResultFileName = $resultPath
            }
            { Invoke-BcAppsNativeTestRun -Parameters $parameters } | Should -Throw "*unreported*"
            $xml = [xml](Get-Content -LiteralPath $resultPath -Raw)
            @($xml.SelectNodes("//testcase[@classname='50000 Selected']")).Count | Should -Be 2
            @($xml.SelectNodes("//testcase/failure")).Count | Should -Be 0
            @($xml.SelectNodes("//testcase[@name='Last']/error[@type='NativeTestResultUnreported']")).Count | Should -Be 1
        }

        Describe "Durable native result accounting with the real pinned parser and JUnit writer" {
            BeforeEach {
                $script:parameters = @{
                    _bcAppsAlToolPath = "verified-altool.exe"
                    _bcAppsAlToolModulePath = $script:actionModulePath
                    containerName = "mocked"
                    credential = [pscredential]::new("test-user", [securestring]::new())
                    extensionId = "test-app-id"
                    appName = "Tests"
                    companyName = "My Company"
                    tenant = "default"
                    disabledTests = @()
                    JUnitResultFileName = Join-Path $TestDrive ("durable-" + [guid]::NewGuid().ToString("N") + ".xml")
                }
                $script:nativeResponse = @{
                    ExitCode = 1
                    StandardError = @("original native cause")
                    StandardOutput = @('{"succeeded":false,"message":"A task was canceled.","errorDetails":{"code":"CommandExecutionFailed"},"data":{"success":true,"passed":0,"failed":0,"skipped":0,"total":0,"results":[]}}')
                }
                Mock -ModuleName AlToolTestRunner Get-TestsFromBcContainer {
                    [pscustomobject]@{ Id = 50000; Name = "Selected"; Tests = @("First", "Last") }
                }
                Mock -ModuleName AlToolTestRunner Get-BcContainerServerConfiguration {
                    @{ ServerInstance = "BC"; DeveloperServicesPort = 7049 }
                }
                Mock -ModuleName AlToolTestRunner Invoke-AlNativeCommand { $script:nativeResponse }
            }

            It "persists zero-result cancellation without inventing AL test failures or skips" {
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*A task was canceled*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@classname='50000 Selected']/error[@type='NativeTestResultUnreported']")).Count | Should -Be 2
                @($xml.SelectNodes("//failure|//skipped")).Count | Should -Be 0
                $xml.OuterXml | Should -Match "original native cause"
                $script:parameters._bcAppsTestInfrastructureBlocksTolerance | Should -BeTrue
            }

            It "retains completed outcomes and the original cause when the remaining methods are canceled" {
                $script:nativeResponse.StandardOutput = @('{"succeeded":false,"message":"A task was canceled.","errorDetails":{"code":"CommandExecutionFailed"},"data":{"success":true,"passed":1,"failed":0,"skipped":0,"total":1,"results":[{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*A task was canceled*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@name='First' and not(error) and not(failure)]")).Count | Should -Be 1
                @($xml.SelectNodes("//testcase[@name='Last']/error[@type='NativeTestResultUnreported']")).Count | Should -Be 1
                @($xml.SelectNodes("//failure|//skipped")).Count | Should -Be 0
            }

            It "persists actual native CLI <Fixture> outcomes while failing the request" -ForEach @(
                @{ Fixture = "NativePartialResults.json"; CodeunitId = 52980; FirstMethod = "LeaveSingletonState"; Completed = 1; Lifecycle = 0 }
                @{ Fixture = "NativeZeroResults.json"; CodeunitId = 52980; FirstMethod = "LeaveSingletonState"; Completed = 0; Lifecycle = 0 }
                @{ Fixture = "NativeOnRunMissingResults.json"; CodeunitId = 132604; FirstMethod = "TestReadNote"; Completed = 0; Lifecycle = 1 }
                @{ Fixture = "NativeOnRunPartialResults.json"; CodeunitId = 132508; FirstMethod = "TestReadNote"; Completed = 1; Lifecycle = 2 }
            ) {
                # Captured from live --renewsession execution. data.success summarizes only completed assertions.
                $script:producerMethods = @("MethodThatDoesNotExist")
                if ($Completed -gt 0) {
                    $script:producerMethods = @($FirstMethod) + $script:producerMethods
                }
                $script:producerCodeunitId = $CodeunitId
                Mock -ModuleName AlToolTestRunner Get-TestsFromBcContainer {
                    [pscustomobject]@{ Id = $script:producerCodeunitId; Name = "Native fixture"; Tests = $script:producerMethods }
                }
                $script:nativeResponse.ExitCode = 1
                $script:nativeResponse.StandardError = @()
                $script:nativeResponse.StandardOutput = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot "fixtures\$Fixture"))
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*MethodThatDoesNotExist*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@name='$FirstMethod' and not(error) and not(failure)]")).Count |
                    Should -Be $Completed
                @($xml.SelectNodes("//testcase[@name='MethodThatDoesNotExist']/error[@type='NativeTestResultUnreported']")).Count |
                    Should -Be 1
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
                @($xml.SelectNodes("//failure|//skipped")).Count | Should -Be 0
                @($xml.SelectNodes("//system-out") | ForEach-Object {
                    $_.InnerText -split "\r?\n" | Where-Object { $_ -like "Native lifecycle OnRun:*" }
                }).Count | Should -Be $Lifecycle
                $xml.OuterXml | Should -Match "CommandExecutionFailed"
                $script:parameters._bcAppsTestInfrastructureBlocksTolerance | Should -BeTrue
            }

            It "publishes infrastructure accounting before propagating a malformed response" {
                $script:nativeResponse.StandardOutput = @("{not-json")
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*parsed as JSON*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase/error[@type='NativeTestResultUnreported']")).Count | Should -Be 2
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
            }

            It "parses partial output even when native exits with an unexpected nonzero code" {
                $script:nativeResponse.ExitCode = 2
                $script:nativeResponse.StandardOutput = @('{"succeeded":false,"message":"connection lost","data":{"results":[{"codeunitId":50000,"methodName":"First","status":"failed","output":"actual assertion","durationMs":2}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*exited 2*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@name='First']/failure")).Count | Should -Be 1
                $xml.SelectSingleNode("//testcase[@name='First']/failure").InnerText | Should -Be "actual assertion"
                @($xml.SelectNodes("//testcase[@name='Last']/error")).Count | Should -Be 1
                $xml.OuterXml | Should -Match "connection lost"
            }

            It "keeps ordinary complete test failures distinct from infrastructure errors" {
                $script:nativeResponse.StandardError = @()
                $script:nativeResponse.StandardOutput = @('{"succeeded":false,"message":"One or more tests failed.","errorDetails":{"code":"TestRunFailed"},"data":{"results":[{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"Last","status":"failed","output":"expected assertion","durationMs":1}]}}')
                Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeFalse
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase")).Count | Should -Be 2
                @($xml.SelectNodes("//failure")).Count | Should -Be 1
                @($xml.SelectNodes("//error")).Count | Should -Be 0
            }

            It "does not hide infrastructure failure when every method already has an outcome" {
                $script:nativeResponse.StandardOutput = @('{"succeeded":false,"message":"cleanup failed","errorDetails":{"code":"CommandExecutionFailed"},"data":{"results":[{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"Last","status":"passed","durationMs":1}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*cleanup failed*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@classname='50000 Selected' and not(error)]")).Count | Should -Be 2
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
            }

            It "retains duplicate conflicting outcomes as evidence but fails the batch explicitly" {
                $script:nativeResponse.StandardOutput = @('{"succeeded":false,"message":"One or more tests failed.","errorDetails":{"code":"TestRunFailed"},"data":{"results":[{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"First","status":"failed","output":"conflict","durationMs":1},{"codeunitId":50000,"methodName":"Last","status":"passed","durationMs":1}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*duplicate*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@name='First']")).Count | Should -Be 2
                @($xml.SelectNodes("//testcase[@name='First']/failure")).Count | Should -Be 1
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
            }

            It "preserves earlier app results and publishes errors when the native process cannot start" {
                '<testsuites><testsuite name="Earlier" tests="1"><testcase classname="Earlier" name="Done"/></testsuite></testsuites>' |
                    Set-Content -LiteralPath $script:parameters.JUnitResultFileName
                Mock -ModuleName AlToolTestRunner Invoke-AlNativeCommand { throw "process start failed" }
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*process start failed*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@name='Done']")).Count | Should -Be 1
                @($xml.SelectNodes("//testcase/error[@type='NativeTestResultUnreported']")).Count | Should -Be 2
            }

            It "preserves the original cause and existing artifact if result publication fails" {
                $previous = '<testsuites><testsuite name="Earlier"><testcase name="Done"/></testsuite></testsuites>'
                $previous | Set-Content -LiteralPath $script:parameters.JUnitResultFileName
                Mock -ModuleName AlToolTestRunner Move-Item { throw "blocked destination" }
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } |
                    Should -Throw "*Could not publish*blocked destination*A task was canceled*"
                (Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw).Trim() | Should -Be $previous
                @(Get-ChildItem -LiteralPath $TestDrive -Filter "*.tmp").Count | Should -Be 0
            }

            It "accepts successful parameterized outcomes without treating their base method as unreported" {
                $script:nativeResponse.ExitCode = 0
                $script:nativeResponse.StandardError = @()
                $script:nativeResponse.StandardOutput = @('{"succeeded":true,"data":{"results":[{"codeunitId":50000,"methodName":"First[row1]","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"First[row2]","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"Last","status":"passed","durationMs":1}]}}')
                Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeTrue
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase")).Count | Should -Be 3
                @($xml.SelectNodes("//error|//failure")).Count | Should -Be 0
            }

            It "retains repeated OnRun lifecycle callbacks without inflating selected-test counts" {
                $script:nativeResponse.ExitCode = 0
                $script:nativeResponse.StandardOutput = @('{"succeeded":true,"data":{"results":[{"codeunitId":50000,"methodName":"OnRun","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"OnRun","status":"passed","durationMs":2},{"codeunitId":50000,"methodName":"Last","status":"passed","durationMs":1}]}}')
                Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeTrue
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase")).Count | Should -Be 2
                @($xml.SelectNodes("//error|//failure")).Count | Should -Be 0
                @($xml.SelectNodes("//system-out")).Count | Should -Be 1
                @($xml.SelectSingleNode("//system-out").InnerText -split "\r?\n").Count | Should -Be 2
                $xml.SelectSingleNode("//system-out").InnerText | Should -Match "OnRun: Pass \(2 ms\)"
            }

            It "preserves and fails a lifecycle failure even when selected test methods passed" {
                $script:nativeResponse.StandardOutput = @('{"succeeded":false,"errorDetails":{"code":"TestRunFailed"},"data":{"results":[{"codeunitId":50000,"methodName":"OnRun","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"OnRun","status":"failed","output":"setup failure","durationMs":2},{"codeunitId":50000,"methodName":"Last","status":"passed","durationMs":1}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*OnRun failed*setup failure*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@classname='50000 Selected' and not(error) and not(failure)]")).Count | Should -Be 2
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
                @($xml.SelectNodes("//failure|//skipped")).Count | Should -Be 0
                $xml.SelectSingleNode("//system-out").InnerText | Should -Match "setup failure"
            }

            It "rejects native success with only OnRun callbacks and no selected-method outcomes" {
                $script:nativeResponse.ExitCode = 0
                $script:nativeResponse.StandardOutput = @('{"succeeded":true,"data":{"success":true,"passed":1,"failed":0,"skipped":0,"total":1,"results":[{"codeunitId":50000,"methodName":"OnRun","status":"passed","durationMs":1}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*2 selected native test methods are unreported*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@classname='50000 Selected']/error[@type='NativeTestResultUnreported']")).Count | Should -Be 2
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
                @($xml.SelectNodes("//testcase[not(error)]|//failure|//skipped")).Count | Should -Be 0
                $xml.SelectSingleNode("//system-out").InnerText | Should -Match "OnRun: Pass"
            }

            It "fails explicitly on unrequested results while retaining requested completed outcomes" {
                $script:nativeResponse.ExitCode = 0
                $script:nativeResponse.StandardOutput = @('{"succeeded":true,"data":{"results":[{"codeunitId":50000,"methodName":"First","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"Last","status":"passed","durationMs":1},{"codeunitId":50000,"methodName":"Unexpected","status":"passed","durationMs":1}]}}')
                { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*unrequested method*Unexpected*"
                $xml = [xml](Get-Content -LiteralPath $script:parameters.JUnitResultFileName -Raw)
                @($xml.SelectNodes("//testcase[@classname='50000 Selected' and not(error)]")).Count | Should -Be 2
                @($xml.SelectNodes("//testcase/error[@type='NativeTestInfrastructure']")).Count | Should -Be 1
                $xml.OuterXml | Should -Match "Unexpected"
            }
        }
    }

    Describe "Actual custom ALTool artifact preparation" -Skip:($env:BCAPPS_VERIFY_NATIVE_TOOL -ne "true") {
        It "checks exact hashes, executable version and native renewal support without publishing" {
            $savedRunnerTemp = $env:RUNNER_TEMP
            $savedGitHubEnv = $env:GITHUB_ENV
            $env:RUNNER_TEMP = $TestDrive
            $env:GITHUB_ENV = Join-Path $TestDrive "github-env"
            try {
                & (Join-Path $PSScriptRoot "..\Prepare-VerificationAlTool.ps1")
                $export = Get-Content -LiteralPath $env:GITHUB_ENV -Raw
                $export | Should -Match "^AlToolPath=.+altool.exe"
            }
            finally {
                $env:RUNNER_TEMP = $savedRunnerTemp
                $env:GITHUB_ENV = $savedGitHubEnv
            }
        }
    }

    AfterAll {
        $env:BC_SERVER_USERNAME = $script:savedUsername
        $env:BC_SERVER_PASSWORD = $script:savedPassword
        Remove-Module BcAppsActionRunnerFixture -Force
    }

    BeforeEach {
        $script:parameters = @{
            _bcAppsAlToolPath = "verified-altool.exe"
            _bcAppsAlToolModulePath = "fixture"
            containerName = "verification"
            credential = $script:credential
            extensionId = "test-app-id"
            appName = "Tests"
            companyName = "My Company"
            tenant = "tenant2"
            testType = "IntegrationTest"
            disabledTests = @([pscustomobject]@{ codeunitName = "Selected"; method = @("Disabled") })
            JUnitResultFileName = Join-Path $TestDrive "results.xml"
        }
        Mock -ModuleName AlToolTestAdapter Import-Module { $script:fixture }
        Mock -ModuleName BcAppsActionRunnerFixture Get-AlToolConnection {
            @{ Server = "http://verification"; ServerInstance = "BC"; Port = 7049 }
        }
        Mock -ModuleName BcAppsActionRunnerFixture Get-TestsFromBcContainer {
            @(
                [pscustomobject]@{ Id = 50000; Name = "Selected"; Tests = @("First", "Disabled", "Last") }
                [pscustomobject]@{ Id = 50001; Name = "Whole Disabled"; Tests = @("Never") }
            )
        }
        Mock -ModuleName BcAppsActionRunnerFixture Get-DisabledTestKeySet {
            @{ Methods = @{ "selected::disabled" = $true }; Codeunits = @{ "whole disabled" = $true } }
        }
        Mock -ModuleName BcAppsActionRunnerFixture New-AlTestGroupsFile {
            $Codeunits.Count | Should -Be 1
            $Codeunits[0].Id | Should -Be 50000
            @($Codeunits[0].Tests) | Should -Be @("First", "Last")
            $path = Join-Path $TestDrive "groups.json"
            ConvertTo-Json -InputObject @(@{ codeunitId = 50000; testMethods = @($Codeunits[0].Tests) }) |
                Set-Content -LiteralPath $path
            $path
        }
        Mock -ModuleName BcAppsActionRunnerFixture Invoke-AlNativeCommand {
            $FilePath | Should -Be "verified-altool.exe"
            $ArgumentList | Should -Contain "--renewsession"
            $ArgumentList | Should -Contain "--testgroups"
            ($ArgumentList -join " ") | Should -Not -Match "\-\-coverage"
            $groupsIndex = [array]::IndexOf($ArgumentList, "--testgroups")
            $groups = @(Get-Content -LiteralPath $ArgumentList[$groupsIndex + 1] -Raw | ConvertFrom-Json)
            @($groups[0].testMethods) | Should -Be @("First", "Last")
            @{ ExitCode = 0; StandardOutput = @('{"succeeded":true,"data":{"results":[]}}'); StandardError = @() }
        }
        Mock -ModuleName BcAppsActionRunnerFixture ConvertFrom-AlTestGroupsOutput {
            @{ Succeeded = $true; Results = @{ "50000" = @(
                @{ MethodName = "First"; Outcome = "Pass" }
                @{ MethodName = "Last"; Outcome = "Pass" }
            ) }; Message = "" }
        }
        Mock -ModuleName BcAppsActionRunnerFixture Add-JUnitTestSuite {
            $suite = $Doc.CreateElement("testsuite")
            $suite.SetAttribute("name", "$($Codeunit.Id) $($Codeunit.Name)")
            $null = $TestSuitesNode.AppendChild($suite)
            0
        }
    }

    It "runs every selected method in one native app batch, excludes disabled tests and cleans up" {
        $env:BC_SERVER_USERNAME = "previous-user"
        $env:BC_SERVER_PASSWORD = "previous-test-password"
        Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeTrue
        Should -Invoke -ModuleName BcAppsActionRunnerFixture Invoke-AlNativeCommand -Times 1 -Exactly
        Should -Invoke -ModuleName BcAppsActionRunnerFixture Get-TestsFromBcContainer -Times 1 -Exactly -ParameterFilter {
            $testType -eq "IntegrationTest" -and $tenant -eq "tenant2" -and $extensionId -eq "test-app-id"
        }
        Should -Invoke -ModuleName BcAppsActionRunnerFixture Get-DisabledTestKeySet -Times 1 -Exactly -ParameterFilter {
            $DisabledTests[0] -is [hashtable] -and $DisabledTests[0].codeunitName -eq "Selected"
        }
        Test-Path (Join-Path $TestDrive "groups.json") | Should -BeFalse
        $env:BC_SERVER_USERNAME | Should -Be "previous-user"
        $env:BC_SERVER_PASSWORD | Should -Be "previous-test-password"
        Test-Path $script:parameters.JUnitResultFileName | Should -BeTrue
    }

    It "preserves clean-tenant codeunit and required-isolation selection" {
        $script:parameters.testCodeunit = "50000"
        $script:parameters.requiredTestIsolation = "Disabled"
        Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeTrue
        Should -Invoke -ModuleName BcAppsActionRunnerFixture Get-TestsFromBcContainer -Times 1 -Exactly -ParameterFilter {
            $testCodeunit -eq "50000" -and $requiredTestIsolation -eq "Disabled"
        }
    }

    It "fails on missing requested method results rather than returning native success alone" {
        Mock -ModuleName BcAppsActionRunnerFixture Add-JUnitTestSuite {
            $null = $TestSuitesNode.AppendChild($Doc.CreateElement("testsuite"))
            1
        }
        Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeFalse
    }

    It "preserves native process failures and cleans the request file" {
        Mock -ModuleName BcAppsActionRunnerFixture Invoke-AlNativeCommand {
            @{ ExitCode = 2; StandardOutput = @(); StandardError = @("native failure") }
        }
        { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*native failure*"
        Test-Path (Join-Path $TestDrive "groups.json") | Should -BeFalse
    }

    It "does not invoke a native process when all methods are disabled" {
        Mock -ModuleName BcAppsActionRunnerFixture Get-TestsFromBcContainer { @() }
        Invoke-BcAppsNativeTestRun -Parameters $script:parameters | Should -BeTrue
        Should -Invoke -ModuleName BcAppsActionRunnerFixture Invoke-AlNativeCommand -Times 0
    }

    It "rejects coverage settings and incomplete native wiring" {
        $script:parameters.codeCoverageOutputPath = "not-allowed"
        { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*must not collect coverage*"
        $script:parameters.Remove("codeCoverageOutputPath")
        $script:parameters.Remove("_bcAppsAlToolPath")
        { Invoke-BcAppsNativeTestRun -Parameters $script:parameters } | Should -Throw "*_bcAppsAlToolPath*"
    }
}

Describe "Native infrastructure summaries" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot "..\AlToolTestAdapter.psm1") -Force
    }

    It "reports real outcomes and unreported methods without turning error nodes into passes" {
        $results = Join-Path $TestDrive "incomplete.xml"
        $summary = Join-Path $TestDrive "summary.txt"
        @'
<testsuites><testsuite><properties><property name="appName" value="Tests"/></properties>
<testcase name="Done"/><testcase name="Failed"><failure>actual assertion</failure></testcase>
<testcase name="Skipped"><skipped/></testcase>
<testcase name="Missing"><error type="NativeTestResultUnreported"/></testcase>
<testcase name="Request"><error type="NativeTestInfrastructure">original cause</error></testcase>
</testsuite></testsuites>
'@ | Set-Content -LiteralPath $results
        Write-BcAppsNativeTestSummary -ResultPath $results -SummaryPath $summary | Should -BeTrue
        Get-Content -LiteralPath $summary -Raw | Should -Match '\| Tests \| 1 \| 1 \| 1 \| 1 \| 1 \|'
        Get-Content -LiteralPath $results -Raw | Should -Match "original cause"
    }

    It "leaves complete test-only failures to the normal AL-Go analyzer" {
        $results = Join-Path $TestDrive "complete.xml"
        $summary = Join-Path $TestDrive "unused-summary.txt"
        '<testsuites><testsuite><testcase name="Failed"><failure>assertion</failure></testcase></testsuite></testsuites>' |
            Set-Content -LiteralPath $results
        Write-BcAppsNativeTestSummary -ResultPath $results -SummaryPath $summary | Should -BeFalse
        Test-Path -LiteralPath $summary | Should -BeFalse
    }
}

Describe "Source-built framework verification" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot "..\AlToolTestAdapter.psm1") -Force
        $script:savedPackagesJson = $env:BCAPPS_FRAMEWORK_APPS_JSON
    }
    AfterAll { $env:BCAPPS_FRAMEWORK_APPS_JSON = $script:savedPackagesJson }
    BeforeEach {
        $env:BCAPPS_FRAMEWORK_APPS_JSON = Join-Path $TestDrive "packages.json"
        $script:runnerPath = Join-Path $TestDrive "runner.app"
        $script:permissionsPath = Join-Path $TestDrive "permissions.app"
        ConvertTo-Json -InputObject @($script:runnerPath, $script:permissionsPath) | Set-Content $env:BCAPPS_FRAMEWORK_APPS_JSON
        $script:frameworks = @(
            @{ AppId = "23de40a6-dfe8-4f80-80db-d70f83ce8caf"; Name = "Test Runner"; PackageId = "f779c2b4-a38c-48a7-b107-822d99232f32"; Path = $script:runnerPath },
            @{ AppId = "40860557-a18d-42ad-aecb-22b7dd80dc80"; Name = "Permissions Mock"; PackageId = "a99fcf41-0775-4bd4-b732-3ebcfd9d69cf"; Path = $script:permissionsPath }
        )
        foreach ($app in $script:frameworks) {
            $writer = [IO.BinaryWriter]::new([IO.File]::Create($app.Path))
            try {
                $writer.Write([uint32]0x5856414e)
                $writer.Write([uint32]40)
                $writer.Write([uint32]2)
                $writer.Write(([guid]$app.PackageId).ToByteArray())
                $writer.Write([int64]0)
                $writer.Write([uint32]0x5856414e)
            }
            finally { $writer.Dispose() }
        }
        $script:publishedFrameworks = @{}
        $script:installedFrameworks = @{}
        $script:sourceVersion = "30.0.60000.0"
        $script:stockVersion = "30.0.57340.0"
        $script:stockPackageId = "10000000-0000-0000-0000-000000000001"
        $script:alreadyPublished = $false
        $script:alreadyInstalled = $false
        $script:tenantAbsent = $false
        $script:retainedData = $false
        $script:wrongInstalledPackage = $false
        $script:wrongInstalledScope = $false
        $script:pendingUpgrade = $false
        $script:dependentLost = $false
        Mock -ModuleName AlToolTestAdapter Get-AppJsonFromAppFile {
            $app = $script:frameworks | Where-Object Path -EQ $appFile
            [pscustomobject]@{ id = $app.AppId; name = $app.Name; publisher = "Microsoft"; version = $script:sourceVersion }
        }
        Mock -ModuleName AlToolTestAdapter Get-FileHash { @{ Hash = "verified-source-package" } }
        Mock -ModuleName AlToolTestAdapter Publish-BcContainerApp {
            $app = $script:frameworks | Where-Object Path -EQ $appFile
            $script:publishedFrameworks[$app.Name] = $true
        }
        Mock -ModuleName AlToolTestAdapter Sync-BcContainerApp { }
        Mock -ModuleName AlToolTestAdapter Start-BcContainerAppDataUpgrade {
            $script:installedFrameworks["$tenant|$appName"] = $true
        }
        Mock -ModuleName AlToolTestAdapter Install-BcContainerApp {
            $script:installedFrameworks["$tenant|$appName"] = $true
        }
        Mock -ModuleName AlToolTestAdapter Get-BcContainerAppInfo {
            foreach ($app in $script:frameworks) {
                $isSource = if ($publishedOnly) {
                    $script:alreadyPublished -or $script:publishedFrameworks.ContainsKey($app.Name)
                }
                else {
                    $script:alreadyInstalled -or $script:installedFrameworks.ContainsKey("$tenant|$($app.Name)")
                }
                if (-not $publishedOnly -and $script:tenantAbsent -and -not $isSource -and -not $script:retainedData) { continue }
                [pscustomobject]@{
                    AppId = $app.AppId
                    Version = if ($isSource) { $script:sourceVersion } else { $script:stockVersion }
                    PackageId = if ($isSource -and -not $script:wrongInstalledPackage) { $app.PackageId } else { $script:stockPackageId }
                    Scope = if ($isSource -and $script:wrongInstalledScope) { "Tenant" } else { "Global" }
                    IsInstalled = -not $publishedOnly -and (-not $script:tenantAbsent -or $isSource)
                    NeedsUpgrade = $isSource -and $script:pendingUpgrade
                    ExtensionDataVersion = if ($script:retainedData -and -not $isSource) { $script:stockVersion } else { $null }
                }
            }
            # A global dependent must survive without uninstalling or changing its package.
            if (-not $script:dependentLost -or $script:installedFrameworks.Count -eq 0) {
                [pscustomobject]@{
                    AppId = "10000000-0000-0000-0000-000000000002"; Version = "30.0.57340.0"
                    PackageId = "10000000-0000-0000-0000-000000000003"; Scope = "Global"
                    IsInstalled = -not $publishedOnly; NeedsUpgrade = $false
                }
            }
        }
    }

    It "publishes globally once and additively upgrades every tenant without replacing global dependents" {
        Install-BcAppsVerificationFramework -Parameters @{ containerName = "test"; credential = $null } `
            -Tenants @("default", "tenant2")
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 2 -Exactly -ParameterFilter {
            $scope -eq "Global" -and $skipVerification -and -not $useDevEndpoint -and
            -not $replacePackageId -and -not $install -and -not $upgrade -and -not $sync -and -not $checkAlreadyInstalled
        }
        Should -Invoke -ModuleName AlToolTestAdapter Sync-BcContainerApp -Times 4 -Exactly -ParameterFilter { $Mode -eq "Add" }
        Should -Invoke -ModuleName AlToolTestAdapter Start-BcContainerAppDataUpgrade -Times 4 -Exactly -ParameterFilter { -not $skipVersionCheck }
        Should -Invoke -ModuleName AlToolTestAdapter Install-BcContainerApp -Times 0
    }

    It "reuses identical globally published source packages and prepares only remaining tenants" {
        $script:alreadyPublished = $true
        $script:installedFrameworks["default|Test Runner"] = $true
        $script:installedFrameworks["default|Permissions Mock"] = $true
        Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default", "tenant2")
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 0
        Should -Invoke -ModuleName AlToolTestAdapter Start-BcContainerAppDataUpgrade -Times 2 -Exactly -ParameterFilter { $tenant -eq "tenant2" }
    }

    It "does not republish or re-upgrade identical installed source packages" {
        $script:alreadyPublished = $true
        $script:alreadyInstalled = $true
        Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default")
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 0
        Should -Invoke -ModuleName AlToolTestAdapter Sync-BcContainerApp -Times 0
        Should -Invoke -ModuleName AlToolTestAdapter Start-BcContainerAppDataUpgrade -Times 0
    }

    It "rejects same-version different-package publication before any mutations" {
        $script:sourceVersion = $script:stockVersion
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*same-version package replacement is forbidden*"
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 0
        Should -Invoke -ModuleName AlToolTestAdapter Sync-BcContainerApp -Times 0
    }

    It "rejects a downgrade before any mutations" {
        $script:sourceVersion = "30.0.57339.0"
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*Rebuild with a higher CI version*"
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 0
    }

    It "installs globally published packages on tenants without installed apps or retained older data" {
        $script:tenantAbsent = $true
        Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default", "tenant2")
        Should -Invoke -ModuleName AlToolTestAdapter Install-BcContainerApp -Times 4 -Exactly
        Should -Invoke -ModuleName AlToolTestAdapter Start-BcContainerAppDataUpgrade -Times 0
    }

    It "upgrades retained older extension data instead of treating it as a new installation" {
        $script:tenantAbsent = $true
        $script:retainedData = $true
        Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default")
        Should -Invoke -ModuleName AlToolTestAdapter Start-BcContainerAppDataUpgrade -Times 2 -Exactly
        Should -Invoke -ModuleName AlToolTestAdapter Install-BcContainerApp -Times 0
    }

    It "rejects a mismatched installed PackageId even when AppId and version match" {
        $script:wrongInstalledPackage = $true
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*package identity was not installed*"
    }

    It "rejects tenant-scoped installed packages even with matching PackageId and version" {
        $script:wrongInstalledScope = $true
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*package identity was not installed*"
    }

    It "rejects incomplete upgrades" {
        $script:pendingUpgrade = $true
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*package identity was not installed*"
    }

    It "detects a lost global dependent" {
        $script:dependentLost = $true
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*changed unrelated installed app identities*"
    }

    It "propagates global publication failure without syncing or running an upgrade" {
        Mock -ModuleName AlToolTestAdapter Publish-BcContainerApp { throw "global publication failed" }
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*global publication failed*"
        Should -Invoke -ModuleName AlToolTestAdapter Sync-BcContainerApp -Times 0
    }

    It "rejects an incorrect source manifest AppId" {
        Mock -ModuleName AlToolTestAdapter Get-AppJsonFromAppFile {
            [pscustomobject]@{ id = "10000000-0000-0000-0000-000000000000"; name = "Test Runner"; publisher = "Microsoft"; version = "30.0.60000.0" }
        }
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*Unexpected AppId*"
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 0
    }

    It "rejects malformed source package headers" {
        [IO.File]::WriteAllBytes($script:runnerPath, [byte[]]::new(40))
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*Unsupported NAVX framework package*"
        Should -Invoke -ModuleName AlToolTestAdapter Publish-BcContainerApp -Times 0
    }

    It "requires source-built packages rather than silently accepting stock framework apps" {
        ConvertTo-Json -InputObject @($script:runnerPath) | Set-Content $env:BCAPPS_FRAMEWORK_APPS_JSON
        { Install-BcAppsVerificationFramework -Parameters @{ containerName = "test" } -Tenants @("default") } |
            Should -Throw "*Permissions Mock*missing*"
    }
}
