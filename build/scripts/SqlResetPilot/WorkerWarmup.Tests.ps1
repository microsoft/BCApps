Import-Module (Join-Path $PSScriptRoot 'WorkerWarmup.psm1') -Force

Describe 'Worker remount comparison contracts' {
BeforeAll {
    $script:environment = @{
        GITHUB_REPOSITORY = 'microsoft/BCApps'
        GITHUB_REF = 'refs/heads/features/646383-sql-api-worker-warmup-comparison'
        GITHUB_EVENT_NAME = 'workflow_dispatch'; GITHUB_RUN_ATTEMPT = '1'; GITHUB_RUN_ID = '123'
        BC_SQL_PILOT_ARM = 'control'; BC_SQL_API_EXPERIMENT = 'workerwarmup'
        BC_SQL_PILOT_COUNTRY = 'W1'; BC_SQL_PILOT_TRIAL = '1'; BC_SQL_PILOT_OUTPUT = $TestDrive
    }
    $script:oldEnvironment = @{}
    foreach ($envKey in $script:environment.Keys) { $script:oldEnvironment[$envKey] = [Environment]::GetEnvironmentVariable($envKey) }
}
BeforeEach {
    foreach ($envKey in $script:environment.Keys) { [Environment]::SetEnvironmentVariable($envKey, $script:environment[$envKey]) }
}
AfterAll {
    foreach ($envKey in $script:oldEnvironment.Keys) { [Environment]::SetEnvironmentVariable($envKey, $script:oldEnvironment[$envKey]) }
}

Describe 'Exact worker protocol identity and matrix' {
    It 'contains twenty unique balanced original cells' {
        $cells = @(Get-WorkerWarmupCell)
        $cells.Count | Should -Be 20
        @($cells | ForEach-Object { "$($_.experiment)/$($_.country)/$($_.trial)" } | Sort-Object -Unique).Count | Should -Be 20
        @($cells | Group-Object experiment, country | Where-Object Count -ne 5).Count | Should -Be 0
        foreach ($index in 0..4) {
            $block = @($cells | Select-Object -Skip ($index * 4) -First 4)
            @($block | Group-Object experiment, country).Count | Should -Be 4
        }
    }
    It 'requires the exact identity: <Key>' -ForEach @(
        @{ Key = 'GITHUB_REPOSITORY'; Value = 'other/BCApps' }
        @{ Key = 'GITHUB_REF'; Value = 'refs/heads/features/646383-sql-api-300-trial-comparison' }
        @{ Key = 'GITHUB_EVENT_NAME'; Value = 'pull_request' }
        @{ Key = 'GITHUB_RUN_ATTEMPT'; Value = '2' }
        @{ Key = 'GITHUB_RUN_ID'; Value = 'bad' }
        @{ Key = 'BC_SQL_API_EXPERIMENT'; Value = 'retry' }
        @{ Key = 'BC_SQL_PILOT_ARM'; Value = 'fresh' }
        @{ Key = 'BC_SQL_PILOT_COUNTRY'; Value = 'US' }
        @{ Key = 'BC_SQL_PILOT_TRIAL'; Value = '6' }
    ) {
        Test-WorkerWarmupExperiment | Should -BeTrue
        [Environment]::SetEnvironmentVariable($Key, $Value)
        Test-WorkerWarmupExperiment | Should -BeFalse
    }

    Describe 'Bounded isolated warmup process cleanup' {
        InModuleScope WorkerWarmup {
            BeforeEach {
                $script:fakeJob = Start-Job { 'synthetic child log, no BC operation' }
                Wait-Job $script:fakeJob | Out-Null
                Mock Get-Module { [PSCustomObject]@{ Path = 'test-only-helper.psm1' } } -ParameterFilter { $Name -eq 'BcContainerHelper' }
                Mock Start-Job { $script:fakeJob }
                Mock Wait-Job { $script:fakeJob }
            }
            AfterEach {
                Get-Job -Id $script:fakeJob.Id -ErrorAction SilentlyContinue | Remove-Job -Force
            }
            It 'uses one child, retains its output and removes it' {
                Invoke-WorkerWarmupTest @{} "$TestDrive\isolated-worker.log"
                Should -Invoke Start-Job -Times 1 -Exactly
                Should -Invoke Wait-Job -Times 1 -Exactly -ParameterFilter { $Timeout -eq 180 }
                Get-Content "$TestDrive\isolated-worker.log" -Raw | Should -Match 'synthetic child log'
                Get-Job -Id $script:fakeJob.Id -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            It 'retains output and removes the child even when its wait times out' {
                Mock Wait-Job { $null }
                { Invoke-WorkerWarmupTest @{} "$TestDrive\isolated-worker.log" } | Should -Throw '*180-second*'
                Should -Invoke Start-Job -Times 1 -Exactly
                Get-Content "$TestDrive\isolated-worker.log" -Raw | Should -Match 'synthetic child log'
                Get-Job -Id $script:fakeJob.Id -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'Complete remount coverage and explicit timing gaps' {
        It 'requires all 22 unique remount/CU receipts, not a subset or duplicates' {
            Remove-Item "$TestDrive\worker-warmup" -Recurse -Force -ErrorAction SilentlyContinue
            $ids = @(0,139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343)
            foreach ($id in $ids) {
                $null = New-Item "$TestDrive\worker-warmup\$id" -ItemType Directory -Force
                @{ passed = $true; executed = $true; attempts = 1; nextCodeunit = $id } |
                    ConvertTo-Json | Set-Content "$TestDrive\worker-warmup\$id\warmup.json"
            }
            Test-WorkerWarmupComplete | Should -BeTrue
            @{ passed = $true; executed = $true; attempts = 1; nextCodeunit = 139700 } |
                ConvertTo-Json | Set-Content "$TestDrive\worker-warmup\148343\warmup.json"
            Test-WorkerWarmupComplete | Should -BeFalse
        }
        It 'reports missing timing as incomplete rather than zero or success' {
            $oldWorkspace = $env:GITHUB_WORKSPACE
            try {
                $env:GITHUB_WORKSPACE = "$TestDrive\measurement"
                & (Join-Path $PSScriptRoot 'WorkerMeasurements.ps1')
                $result = Get-Content "$TestDrive\measurement\sql-reset-pilot-output\worker-performance.json" -Raw | ConvertFrom-Json
                $result.timingComplete | Should -BeFalse
                $result.executionMilliseconds | Should -BeNullOrEmpty
                $result.gaps.Count | Should -BeGreaterThan 0
            } finally { $env:GITHUB_WORKSPACE = $oldWorkspace }
        }
    }
    }

Describe 'Nonempty exact isolated AL result' {
    It 'accepts only the selected successful method' {
        '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest" time="0.001"/></testsuite></testsuites>' |
            Set-Content "$TestDrive\warmup.xml"
        Assert-WorkerWarmupResult "$TestDrive\warmup.xml" | Should -Be '0.001'
    }
    It 'rejects <Reason>' -ForEach @(
        @{ Reason = 'empty suites'; Xml = '<testsuites/>' }
        @{ Reason = 'missing cases'; Xml = '<testsuites><testsuite/></testsuites>' }
        @{ Reason = 'failure'; Xml = '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest"><failure/></testcase></testsuite></testsuites>' }
        @{ Reason = 'error'; Xml = '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest"><error/></testcase></testsuite></testsuites>' }
        @{ Reason = 'skip'; Xml = '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest"><skipped/></testcase></testsuite></testsuites>' }
        @{ Reason = 'wrong method'; Xml = '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetSchemeTest"/></testsuite></testsuites>' }
        @{ Reason = 'wrong codeunit'; Xml = '<testsuites><testsuite><testcase classname="1 Uri Test" name="GetHostTest"/></testsuite></testsuites>' }
        @{ Reason = 'duplicate'; Xml = '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest"/><testcase classname="135070 Uri Test" name="GetHostTest"/></testsuite></testsuites>' }
        @{ Reason = 'failed result'; Xml = '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest" result="Fail"/></testsuite></testsuites>' }
    ) {
        $Xml | Set-Content "$TestDrive\warmup.xml"
        { Assert-WorkerWarmupResult "$TestDrive\warmup.xml" } | Should -Throw
    }
    It 'rejects missing evidence' { { Assert-WorkerWarmupResult "$TestDrive\absent.xml" } | Should -Throw }
}

Describe 'Every pristine remount receives its own bounded operation' {
    InModuleScope WorkerWarmup {
        BeforeEach {
            Remove-Item "$TestDrive\worker-warmup","$TestDrive\results" -Recurse -Force -ErrorAction SilentlyContinue
            $script:selection = @{
                containerName = 'bcbuildprojectsTestAppsW1Trial1workerwarmup123'
                tenant = 'default'; companyName = 'My Company'
                credential = [PSCredential]::new('test', (ConvertTo-SecureString 'test-only' -AsPlainText -Force))
                JUnitResultFileName = "$TestDrive\results\TestResults.xml"
                ReRun = $true; testFunction = 'unrelated'; disabledTests = @('unrelated')
            }
            Initialize-WorkerWarmup -Parameters $script:selection -AppIdByName @{ 'System Application Test' = '11111111-1111-1111-1111-111111111111' }
            @{ phase = 'reset-complete'; utc = '2026-10-08T00:00:00Z'
                plan = @{ Tenant = 'tenant2'; Destination = 'tenant2'; Template = 'default-test-template'; Generation = 1 }
            } | ConvertTo-Json -Compress | Set-Content "$TestDrive\reset-timeline.jsonl"
            Mock Invoke-WorkerWarmupTest {
                '<testsuites><testsuite><testcase classname="135070 Uri Test" name="GetHostTest" time="0.001"/></testsuite></testsuites>' |
                    Set-Content $Parameters.JUnitResultFileName
                'Selected exactly one test' | Set-Content $LogPath
            }
        }
        It 'uses exact selection and isolation, no inherited retry or cohort exclusions' {
            Invoke-WorkerRemountWarmup tenant2 139700
            Should -Invoke Invoke-WorkerWarmupTest -Times 1 -Exactly -ParameterFilter {
                $Parameters.tenant -eq 'tenant2' -and $Parameters.testCodeunit -eq '135070' -and
                $Parameters.testFunction -eq 'GetHostTest' -and $Parameters.testRunnerCodeunitId -eq '130450' -and
                $Parameters.testType -eq '' -and $Parameters.requiredTestIsolation -eq '' -and
                $Parameters.testSuite -eq 'WWARMUP' -and $Parameters.disabledTests.Count -eq 0 -and
                -not $Parameters.ContainsKey('ReRun') -and -not $Parameters.ContainsKey('AppendToJUnitResultFile') -and
                $Parameters.returnTrueIfAllPassed -and $Parameters.renewClientContextBetweenTests -and
                $Parameters.ContainsKey('restartContainerAndRetry') -and -not $Parameters.restartContainerAndRetry
            }
            Assert-WorkerWarmupReady tenant2 139700
            { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
        }
        It 'never runs warmup in control' {
            $env:BC_SQL_API_EXPERIMENT = 'control'
            Invoke-WorkerRemountWarmup tenant2 139700
            Should -Invoke Invoke-WorkerWarmupTest -Times 0 -Exactly
            Assert-WorkerWarmupReady tenant2 139700
            $receipt = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
            $receipt.executed | Should -BeFalse
            $receipt.attempts | Should -Be 0
        }
        It 'warms the discovery remount separately' {
            (Get-Content "$TestDrive\reset-timeline.jsonl" -Raw).Replace('default-test-template', 'default') |
                Set-Content "$TestDrive\reset-timeline.jsonl"
            Invoke-WorkerRemountWarmup tenant2 0
            Test-Path "$TestDrive\worker-warmup\tenant2-g1-cu0\warmup.json" | Should -BeTrue
        }
        It 'rejects duplicate execution, wrong CU, stale generation and protected default' {
            Invoke-WorkerRemountWarmup tenant2 139700
            { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw
            { Assert-WorkerWarmupReady tenant2 139702 } | Should -Throw
            { Invoke-WorkerRemountWarmup default 139700 } | Should -Throw
            (Get-Content "$TestDrive\reset-timeline.jsonl" -Raw).Replace('"Generation":1', '"Generation":2') |
                Set-Content "$TestDrive\reset-timeline.jsonl"
            { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
            Invoke-WorkerRemountWarmup tenant2 139702
            Should -Invoke Invoke-WorkerWarmupTest -Times 2 -Exactly
            Assert-WorkerWarmupReady tenant2 139702
        }
        It 'fails closed on child failure and retains a failed receipt without another attempt' {
            Mock Invoke-WorkerWarmupTest { throw 'simulated failure' }
            { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw
            { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
            Should -Invoke Invoke-WorkerWarmupTest -Times 1 -Exactly
            $receipt = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
            $receipt.passed | Should -BeFalse
            $receipt.attempts | Should -Be 1
            $receipt.elapsedMilliseconds | Should -BeGreaterOrEqual 0
        }
        It 'rejects empty results and failed remounts' {
            Mock Invoke-WorkerWarmupTest { '<testsuites/>' | Set-Content $Parameters.JUnitResultFileName }
            { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw
            (Get-Content "$TestDrive\reset-timeline.jsonl" -Raw).Replace('reset-complete', 'reset-failed') |
                Set-Content "$TestDrive\reset-timeline.jsonl"
            { Get-WorkerWarmupReset tenant2 } | Should -Throw
        }
        It 'rejects missing package and non-owned initialization' {
            { Initialize-WorkerWarmup $script:selection @{} } | Should -Throw
            $script:selection.tenant = 'tenant2'
            { Initialize-WorkerWarmup $script:selection @{ 'System Application Test' = '11111111-1111-1111-1111-111111111111' } } | Should -Throw
        }
    }
}

Describe 'Runner boundaries and immutable selection source' {
    BeforeAll {
        $script:root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
        $script:runner = Get-Content (Join-Path $script:root 'build\scripts\ParallelTestExecution.psm1') -Raw
    }
    It 'finishes batch resets then warmups then unchanged full-CU dispatch' {
        $start = $script:runner.IndexOf('function Invoke-RequiredDisabledTestExecution')
        $body = $script:runner.Substring($start, $script:runner.IndexOf('function Register-TestJobOutcome', $start) - $start)
        $body.IndexOf('Reset-BcTestTenant') | Should -BeLessThan $body.IndexOf('Invoke-WorkerRemountWarmup')
        $body.IndexOf('Invoke-WorkerRemountWarmup') | Should -BeLessThan $body.IndexOf('Start-RequiredDisabledDispatch')
        $body | Should -Match 'foreach \(\$dispatch in \$batch\)'
        $script:runner | Should -Match 'finally \{\s*Reset-BcTestTenant[\s\S]+?Invoke-WorkerRemountWarmup -Tenant \$discoveryTenant.Id -NextCodeunitId 0'
        $script:runner | Should -Match 'Assert-WorkerWarmupReady -Tenant \$TenantInfo.Id -CodeunitId \$WorkItem.CodeunitId'
    }
    It 'disables old first-app/probe behavior and retains whole cohort, no retry code edits' {
        $script:runner | Should -Match 'function Test-SqlApiWarmupEnabled \{\s*if \(Test-WorkerWarmupExperiment\) \{ return \$false \}'
        $script:runner | Should -Match 'Test-WorkerWarmupComplete'
        $diff = git -C $script:root diff 0227094059f2f26f3fcb1b7f85a3285c17e78b8e -- src build/projects .github/AL-Go-Settings.json build/scripts/SqlApiTestRetry.psm1 build/scripts/RunTestsInBcContainer.ps1
        $diff | Should -BeNullOrEmpty
    }
    It 'verifies the pinned test body and explicit runner isolation from source' {
        $test = git -C $script:root show 'c4953dceffe02a017adad34973e1955017bf5d20:src/System Application/Test/URI/src/UriTest.Codeunit.al' | Out-String
        $test | Should -Match "procedure GetHostTest\(\)[\s\S]+?Uri.Init\('http://microsoft.com/test'\);[\s\S]+?LibraryAssert.AreEqual\('microsoft.com', Uri.GetHost\(\)"
        $test | Should -Not -Match 'trigger OnRun'
        $isolation = git -C $script:root show 'c4953dceffe02a017adad34973e1955017bf5d20:src/Tools/Test Framework/Test Runner/src/TestRunnerIsolCodeunit.Codeunit.al' | Out-String
        $isolation | Should -Match 'codeunit 130450'
        $isolation | Should -Match 'TestIsolation = Codeunit'
    }
    It 'bounds one isolated process and always drains/removes it' {
        $module = Get-Content (Join-Path $PSScriptRoot 'WorkerWarmup.psm1') -Raw
        $module | Should -Match 'Wait-Job -Job \$job -Timeout 180'
        $module | Should -Match 'finally \{ Remove-Job -Job \$job -Force \}'
        $module | Should -Match "throw 'Warmup worker failed or exceeded its 180-second bound.'"
        $module | Should -Not -Match 'Invoke-TestsWithReruns|Invoke-SqlPilotCompaniesProbe|Start-Sleep'
    }
}
}
