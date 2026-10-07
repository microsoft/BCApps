$discoveryArm = $env:BC_SQL_PILOT_ARM
try {
    $env:BC_SQL_PILOT_ARM = 'control'
    Import-Module (Join-Path $PSScriptRoot '..\ParallelTestExecution.psm1') -Force
} finally { $env:BC_SQL_PILOT_ARM = $discoveryArm }
BeforeAll {
    $script:oldPilot = $env:BC_SQL_PILOT_ARM
    $env:BC_SQL_PILOT_ARM = 'control'
}
AfterAll { $env:BC_SQL_PILOT_ARM = $script:oldPilot }

Describe 'Worker warmup preserves reset-before-test batch barrier' {
    InModuleScope ParallelTestExecution {
        BeforeEach {
            $script:order = [Collections.Generic.List[string]]::new()
            $script:items = @(1..6 | ForEach-Object { [PSCustomObject]@{ Key = "CU$_"; CodeunitId = $_ } })
            $script:tenants = @('tenant2','tenant3','tenant4') | ForEach-Object { [PSCustomObject]@{ Id = $_; DatabaseName = $_ } }
            $script:parameters = @{ containerName = 'owned'; companyName = 'My Company'; credential = [PSCredential]::Empty }
            Mock Test-WorkerWarmupExperiment { $true }
            Mock Test-SqlApiWarmupEnabled { $false }
            Mock Reset-BcTestTenant { $script:order.Add("reset:$Tenant") }
            Mock Invoke-WorkerRemountWarmup { $script:order.Add("warmup:$Tenant") }
            Mock Invoke-SqlPilotCompaniesProbe { throw 'Old probe must never execute.' }
            Mock Start-RequiredDisabledDispatch { $script:order.Add("dispatch:$($TenantInfo.Id)") }
            Mock Wait-ForAllTestJobs {}
        }
        It 'performs every remount operation in both batches before any cohort dispatch' {
            Invoke-RequiredDisabledTestExecution $script:parameters $script:items $script:tenants `
                'default-test-template' 'runner.ps1' 'IntegrationTest' | Should -BeTrue
            $batch = 'reset:tenant2,reset:tenant3,reset:tenant4,warmup:tenant2,warmup:tenant3,warmup:tenant4,dispatch:tenant2,dispatch:tenant3,dispatch:tenant4'
            ($script:order -join ',') | Should -Be "$batch,$batch"
            Should -Invoke Invoke-WorkerRemountWarmup -Times 6 -Exactly
            Should -Invoke Invoke-SqlPilotCompaniesProbe -Times 0 -Exactly
        }
        It 'cannot dispatch or retry following warmup failure' {
            Mock Invoke-WorkerRemountWarmup { throw 'warmup failed' }
            { Invoke-RequiredDisabledTestExecution $script:parameters $script:items $script:tenants `
                'default-test-template' 'runner.ps1' 'IntegrationTest' } | Should -Throw '*warmup failed*'
            Should -Invoke Reset-BcTestTenant -Times 3 -Exactly
            Should -Invoke Invoke-WorkerRemountWarmup -Times 1 -Exactly
            Should -Invoke Start-RequiredDisabledDispatch -Times 0 -Exactly
        }
        It 'retains terminal failure behavior without warming another batch or retrying' {
            Mock Wait-ForAllTestJobs { $state.hasFailures = $true }
            Invoke-RequiredDisabledTestExecution $script:parameters $script:items $script:tenants `
                'default-test-template' 'runner.ps1' 'IntegrationTest' | Should -BeFalse
            Should -Invoke Invoke-WorkerRemountWarmup -Times 3 -Exactly
            Should -Invoke Start-RequiredDisabledDispatch -Times 3 -Exactly
        }
    }
}
