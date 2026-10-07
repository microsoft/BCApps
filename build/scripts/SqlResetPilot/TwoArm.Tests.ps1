$discoveryArm = $env:BC_SQL_PILOT_ARM
try {
    $env:BC_SQL_PILOT_ARM = 'control'
    Import-Module (Join-Path $PSScriptRoot '..\ParallelTestExecution.psm1') -Force
} finally {
    $env:BC_SQL_PILOT_ARM = $discoveryArm
}
Describe 'Exact manual two-arm experiment isolation' {
    BeforeEach {
        $script:saved = @{}
        foreach ($key in @('GITHUB_REPOSITORY','GITHUB_REF','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT',
            'BC_SQL_PILOT_ARM','BC_SQL_API_EXPERIMENT','BC_SQL_PILOT_OUTPUT')) {
            $script:saved[$key] = [Environment]::GetEnvironmentVariable($key)
        }
        $env:GITHUB_REPOSITORY = 'microsoft/BCApps'
        $env:GITHUB_REF = 'refs/heads/features/646383-sql-api-two-arm-experiment'
        $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
        $env:GITHUB_RUN_ATTEMPT = '1'
        $env:BC_SQL_PILOT_ARM = 'control'
        $env:BC_SQL_API_EXPERIMENT = 'B'
        $env:BC_SQL_PILOT_OUTPUT = $TestDrive
    }
    AfterEach {
        foreach ($key in $script:saved.Keys) { [Environment]::SetEnvironmentVariable($key, $script:saved[$key]) }
    }
    InModuleScope ParallelTestExecution {
      Context 'Runner and scheduler hooks' {
        BeforeEach {
            Mock Get-ChildItem { @() }
            Mock Start-Sleep {}
            Mock Start-TestJob { [PSCustomObject]@{ Id = 1 } }
            $script:state = [PSCustomObject]@{
                jobs = @(); hasFailures = $false; transient = @(); retried = @{}; retryTenant = @{}; sqlRetryEvidence = @{}
            }
            $script:item = [PSCustomObject]@{
                Key = 'Test App::148318'; AppName = 'Test App'; AppId = 'id'
                CodeunitId = '148318'; CodeunitName = 'Capabilities'; TestCount = 3
            }
            $script:tenant = [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
            $script:parameters = @{
                containerName = 'owned'; JUnitResultFileName = (Join-Path $TestDrive 'TestResults.xml')
                credential = [PSCredential]::Empty; companyName = 'My Company'
            }
        }
        It 'adds exactly the one named method only in A and does not mutate baseline config' {
            $env:BC_SQL_API_EXPERIMENT = 'A'
            $disabled = @(Get-DisabledTestsForApp 'Test App')
            $disabled.Count | Should -Be 1
            $disabled[0].codeunitId | Should -Be 148318
            $disabled[0].method | Should -BeExactly 'CapabilitiesProjectsEnabledViaAPI'
            $env:BC_SQL_API_EXPERIMENT = 'B'
            @(Get-DisabledTestsForApp 'Test App').Count | Should -Be 0
        }
        It 'cannot activate on <Kind>' -ForEach @(
            @{ Kind = 'PR'; Key = 'GITHUB_EVENT_NAME'; Value = 'pull_request' }
            @{ Kind = 'another branch'; Key = 'GITHUB_REF'; Value = 'refs/heads/main' }
            @{ Kind = 'rerun'; Key = 'GITHUB_RUN_ATTEMPT'; Value = '2' }
            @{ Kind = 'other repository'; Key = 'GITHUB_REPOSITORY'; Value = 'other/BCApps' }
            @{ Kind = 'fresh SQL'; Key = 'BC_SQL_PILOT_ARM'; Value = 'fresh' }
        ) {
            [Environment]::SetEnvironmentVariable($Key, $Value)
            Test-SqlApiExperiment | Should -BeFalse
        }
        It 'queues only a confirmed B failure and never a generic transient' {
            $result = [PSCustomObject]@{ Outcome = 'SqlPoolRetry'; AppName = $script:item.Key; Tenant = 'tenant2'; SqlRetryEvidence = @{ TestCases = @('one') } }
            Register-TestJobOutcome $result $script:state
            $script:state.transient.Count | Should -Be 1
            $script:state.hasFailures | Should -BeFalse
            $script:state.retried[$script:item.Key] = $true
            Register-TestJobOutcome $result $script:state
            $script:state.transient.Count | Should -Be 1
            $script:state.hasFailures | Should -BeTrue
        }
        It 'never queues SQL retry in A' {
            $env:BC_SQL_API_EXPERIMENT = 'A'
            Register-TestJobOutcome ([PSCustomObject]@{ Outcome = 'SqlPoolRetry' }) $script:state
            $script:state.hasFailures | Should -BeTrue
            $script:state.transient.Count | Should -Be 0
        }
        It 'retries the full CU without BCH ReRun and writes to a separate result file' {
            $script:state.sqlRetryEvidence[$script:item.Key] = @{ TestCases = @(@{ Name = 'one'; Skipped = $false }) }
            Start-RequiredDisabledDispatch $script:parameters $script:item $script:tenant 'runner.ps1' 'IntegrationTest' $script:state 'Re-dispatching'
            Should -Invoke Start-TestJob -Times 1 -Exactly -ParameterFilter {
                -not $parameters.ContainsKey('ReRun') -and $parameters.testCodeunit -eq '148318' -and
                $fileSuffix -eq 'tenant2-sqlretry-148318' -and $skipAutomaticDisabledPass
            }
            $script:state.jobs[0].SqlRetryContext.Attempt | Should -Be 2
            $script:state.jobs[0].SqlRetryContext.ResultFiles.JUnitResultFileName | Should -Match 'tenant2-sqlretry-148318'
        }
        It 'restores and probes again before a once-only retry and drains failures' {
            $script:order = [Collections.Generic.List[string]]::new()
            $script:waits = 0
            Mock Reset-BcTestTenant { $script:order.Add('restore') }
            Mock Invoke-SqlPilotCompaniesProbe { $script:order.Add('probe') }
            Mock Start-RequiredDisabledDispatch { $script:order.Add("dispatch:$Verb") }
            Mock Wait-ForAllTestJobs {
                $script:waits++
                if ($script:waits -eq 1) {
                    $state.sqlRetryEvidence[$script:item.Key] = @{ TestCases = @('one') }
                    $state.transient = @([PSCustomObject]@{ Key = $script:item.Key; Tenant = 'tenant2' })
                } else { $state.hasFailures = $true }
            }
            Invoke-RequiredDisabledTestExecution $script:parameters @($script:item) @($script:tenant) `
                'default-test-template' 'runner.ps1' 'IntegrationTest' | Should -BeFalse
            ($script:order -join ',') | Should -Be 'restore,probe,dispatch:Dispatching,restore,probe,dispatch:Re-dispatching'
            $script:waits | Should -Be 2
        }
        It 'preserves first failure and separate full retry, merging only validated recovery' {
            Mock Receive-Job {} -RemoveParameterType Job
            Mock Remove-Job {} -RemoveParameterType Job
            Mock Get-SqlApiTestRetryEvidence { @{ TestCases = @(@{ Name = 'CapabilitiesProjectsEnabledViaAPI'; Skipped = $false }) } }
            $originalPath = Join-Path $TestDrive 'TestResults-tenant2.xml'
            $retryPath = Join-Path $TestDrive 'TestResults-tenant2-sqlretry-148318.xml'
            $original = '<testsuites><testsuite name="148318 Capabilities"><testcase name="CapabilitiesProjectsEnabledViaAPI" result="Fail"><failure message="original failure"/></testcase></testsuite></testsuites>'
            $passed = '<testsuites><testsuite name="148318 Capabilities"><testcase name="CapabilitiesProjectsEnabledViaAPI" result="Pass"/></testsuite></testsuites>'
            $original | Set-Content $originalPath
            $context = [PSCustomObject]@{
                CodeunitId = 148318; Tenant = 'tenant2'; StartedUtc = [datetime]::UtcNow
                TestCount = 1; Attempt = 1; ResultFiles = @{ JUnitResultFileName = $originalPath }
                FinalResultFiles = @{ JUnitResultFileName = $originalPath }; OutputDirectory = $TestDrive
            }
            $entry = [PSCustomObject]@{ appName = $script:item.Key; tenant = 'tenant2'; SqlRetryContext = $context; SqlRetryExpectedTests = @() }
            $firstResult = Receive-TestJobResult $entry @{ Id = 91; State = 'Failed' } @{}
            $firstResult.Outcome | Should -Be 'SqlPoolRetry'
            $firstSaved = Join-Path $TestDrive 'test-attempts\tenant2-148318-1\JUnitResultFileName'
            (Get-Content $firstSaved -Raw).Trim() | Should -Be $original
            $passed | Set-Content $retryPath
            $context.Attempt = 2
            $context.ResultFiles = @{ JUnitResultFileName = $retryPath }
            $entry.SqlRetryExpectedTests = $firstResult.SqlRetryEvidence.TestCases
            (Receive-TestJobResult $entry @{ Id = 92; State = 'Completed' } @{ $script:item.Key = $true }).Outcome | Should -Be 'Passed'
            ([xml](Get-Content $originalPath -Raw)).SelectNodes('//failure').Count | Should -Be 0
            (Get-Content $firstSaved -Raw).Trim() | Should -Be $original
            Test-Path (Join-Path $TestDrive 'test-attempts\tenant2-148318-2\JUnitResultFileName') | Should -BeTrue
            Should -Invoke Get-SqlApiTestRetryEvidence -Times 1 -Exactly
        }
        It 'does not classify stopped or already-retried failures as eligible' {
            Mock Receive-Job {} -RemoveParameterType Job
            Mock Remove-Job {} -RemoveParameterType Job
            Mock Get-SqlApiTestRetryEvidence { throw 'Evidence classifier must not be called.' }
            Mock Test-SqlApiExperimentSelection { $true }
            $context = [PSCustomObject]@{
                CodeunitId = 148318; Tenant = 'tenant2'; StartedUtc = [datetime]::UtcNow
                TestCount = 1; Attempt = 2; ResultFiles = @{}
            }
            $entry = [PSCustomObject]@{ appName = $script:item.Key; tenant = 'tenant2'; SqlRetryContext = $context; SqlRetryExpectedTests = @() }
            foreach ($jobState in @('Stopped','Failed')) {
                (Receive-TestJobResult $entry @{ Id = 91; State = $jobState } @{ $script:item.Key = $true }).Outcome | Should -Be 'Failed'
            }
            Should -Invoke Get-SqlApiTestRetryEvidence -Times 0
        }
        It 'rejects silently reenabled A and inherited B exclusions in actual JUnit' {
            $path = Join-Path $TestDrive 'selection.xml'
            $context = [PSCustomObject]@{ CodeunitId = 148318; ResultFiles = @{ JUnitResultFileName = $path } }
            '<testsuites><testsuite name="148318 Capabilities"><testcase name="CapabilitiesProjectsEnabledViaAPI"><skipped/></testcase></testsuite></testsuites>' | Set-Content $path
            Test-SqlApiExperimentSelection $context 'A' | Should -BeTrue
            Test-SqlApiExperimentSelection $context 'B' | Should -BeFalse
            '<testsuites><testsuite name="148318 Capabilities"><testcase name="CapabilitiesProjectsEnabledViaAPI"/></testsuite></testsuites>' | Set-Content $path
            Test-SqlApiExperimentSelection $context 'A' | Should -BeFalse
            Test-SqlApiExperimentSelection $context 'B' | Should -BeTrue
        }
      }
    }
}
