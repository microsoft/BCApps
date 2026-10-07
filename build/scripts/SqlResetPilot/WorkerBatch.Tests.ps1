$discoveryArm = $env:BC_SQL_PILOT_ARM
try {
    $env:BC_SQL_PILOT_ARM = 'control'
    Import-Module (Join-Path $PSScriptRoot '..\ParallelTestExecution.psm1') -Force
} finally { $env:BC_SQL_PILOT_ARM = $discoveryArm }
BeforeAll {
    $script:oldPilot = $env:BC_SQL_PILOT_ARM
    $env:BC_SQL_PILOT_ARM = 'control'
}

Describe 'Original first-app mechanism is reused without consuming cohort work' {
    InModuleScope ParallelTestExecution {
        BeforeEach {
            $script:oldEnvironment = @{}
            $values = @{
                GITHUB_REPOSITORY = 'microsoft/BCApps'
                GITHUB_REF = 'refs/heads/features/646383-sql-api-worker-readiness-comparison'
                GITHUB_EVENT_NAME = 'workflow_dispatch'; GITHUB_RUN_ATTEMPT = '1'; GITHUB_RUN_ID = '123'
                BC_SQL_PILOT_ARM = 'control'; BC_SQL_API_EXPERIMENT = 'workerwarmup'
                BC_SQL_PILOT_COUNTRY = 'W1'; BC_SQL_PILOT_TRIAL = '1'; BC_SQL_PILOT_OUTPUT = $TestDrive
            }
            foreach ($key in $values.Keys) {
                $script:oldEnvironment[$key] = [Environment]::GetEnvironmentVariable($key)
                [Environment]::SetEnvironmentVariable($key, $values[$key])
            }
            $script:dispatches = @()
            $script:parameters = @{
                containerName = 'bcbuildprojectsTestAppsW1Trial1workerwarmup123'
                tenant = 'default'; companyName = 'My Company'
                credential = [PSCredential]::new('test', (ConvertTo-SecureString 'test-only' -AsPlainText -Force))
                JUnitResultFileName = "$TestDrive\results\TestResults.xml"
                XUnitResultFileName = "$TestDrive\results\XUnit.xml"
            }
            $script:appNames = @('System Application Test Library','Real App')
            $script:appIds = @{ 'System Application Test Library' = '11111111-1111-1111-1111-111111111111' }
            $script:tenants = @('default','tenant2','tenant3','tenant4')
            Remove-Item "$TestDrive\worker-warmup","$TestDrive\results" -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem $TestDrive -Filter 'worker-postmount-*.json' | Remove-Item
            $script:warmupAction = {
                param($context, $workerTenant, $directory)
                Invoke-SqlPilotWarmup -Parameters $context.Parameters -AppNames $context.AppNames `
                    -AppIdByName $context.AppIdByName -Tenants $context.Tenants -ScriptPath $context.ScriptPath `
                    -TestType $context.TestType -CleanTenantAppNames $context.AppNames `
                    -WarmupTenant $workerTenant -WarmupDirectory $directory
            }
            Mock Start-TestAppDispatch {
                $script:dispatches += @{
                    Parameters = $Parameters.Clone(); AppName = $AppName; AppId = $AppId
                    Tenant = $Tenant; ScriptPath = $ScriptPath; TestType = $TestType
                    SkipAutomaticDisabledPass = [bool]$SkipAutomaticDisabledPass; Verb = $Verb
                }
            }
            Mock Wait-ForAllTestJobs {}
        }
        AfterEach {
            foreach ($key in $script:oldEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $script:oldEnvironment[$key]) }
        }
        It 'calls the same original dispatcher with identical runner settings except tenant and evidence paths' {
            Invoke-SqlPilotWarmup -Parameters $script:parameters -AppNames $script:appNames -AppIdByName $script:appIds `
                -Tenants $script:tenants -ScriptPath 'original-runner.ps1' -TestType 'IntegrationTest' -CleanTenantAppNames $script:appNames
            Initialize-WorkerWarmup -Parameters $script:parameters -AppNames $script:appNames -AppIdByName $script:appIds `
                -Tenants $script:tenants -ScriptPath 'original-runner.ps1' -TestType 'IntegrationTest' `
                -WarmupAction $script:warmupAction -ProbeAction { throw 'No probe in warmup-only' }
            foreach ($tenant in @('tenant2','tenant3','tenant4')) {
                @{ phase = 'reset-complete'; utc = '2026-10-08T00:00:00Z'
                    plan = @{ Tenant = $tenant; Destination = $tenant; Template = 'default-test-template'; Generation = 1 }
                } | ConvertTo-Json -Compress | Add-Content "$TestDrive\reset-timeline.jsonl"
                Invoke-WorkerPostMountDelay -Tenant $tenant
                Invoke-WorkerRemountWarmup -Tenant $tenant -NextCodeunitId 139700
            }
            Should -Invoke Start-TestAppDispatch -Times 4 -Exactly
            Should -Invoke Wait-ForAllTestJobs -Times 4 -Exactly
            $original = $script:dispatches[0]
            foreach ($worker in $script:dispatches | Select-Object -Skip 1) {
                foreach ($key in @('AppName','AppId','ScriptPath','TestType','SkipAutomaticDisabledPass','Verb')) {
                    $worker[$key] | Should -Be $original[$key]
                }
                $worker.Tenant | Should -BeIn @('tenant2','tenant3','tenant4')
                $worker.Parameters.tenant | Should -Be 'default'
                foreach ($key in $original.Parameters.Keys | Where-Object { $_ -notin @('tenant','JUnitResultFileName','XUnitResultFileName') }) {
                    $worker.Parameters[$key] | Should -Be $original.Parameters[$key]
                }
                $worker.Parameters.JUnitResultFileName | Should -Match 'worker-warmup'
            }
            $script:parameters.tenant | Should -Be 'default'
            ($script:appNames -join ',') | Should -Be 'System Application Test Library,Real App'
            Mock Add-MissingJUnitTestProperties {}
            Mock Merge-TestResultFiles {}
            Merge-TenantTestResults -parameters $script:parameters -tenants $script:tenants
            Should -Invoke Merge-TestResultFiles -Times 2 -Exactly -ParameterFilter {
                -not ($sourceFiles -match 'worker-warmup') -and $sourceFiles.Count -eq 4
            }
        }
        It 'does not reinterpret an original dispatcher failure as an empty-suite success' {
            Initialize-WorkerWarmup -Parameters $script:parameters -AppNames $script:appNames -AppIdByName $script:appIds `
                -Tenants $script:tenants -ScriptPath 'original-runner.ps1' -TestType 'IntegrationTest' `
                -WarmupAction $script:warmupAction -ProbeAction { throw 'No probe in warmup-only' }
            @{ phase = 'reset-complete'; utc = '2026-10-08T00:00:00Z'
                plan = @{ Tenant = 'tenant2'; Destination = 'tenant2'; Template = 'default-test-template'; Generation = 1 }
            } | ConvertTo-Json -Compress | Set-Content "$TestDrive\reset-timeline.jsonl"
            Mock Wait-ForAllTestJobs { $state.hasFailures = $true }
            Invoke-WorkerPostMountDelay tenant2
            { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw '*failed or did not complete*'
            Should -Invoke Start-TestAppDispatch -Times 1 -Exactly
            { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
        }
    }
}
AfterAll { $env:BC_SQL_PILOT_ARM = $script:oldPilot }

Describe 'Worker warmup preserves reset-before-test batch barrier' {
    InModuleScope ParallelTestExecution {
        BeforeAll {
            $script:realResetBody = ${function:Reset-BcTestTenant}
        }
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
        It 'places postmount pacing between real serial restores and before app warmup' {
            # Use the real reset wrapper so the placement is checked, not mocked into existence.
            Mock Invoke-SqlPilotReset { $script:order.Add("restore:$Tenant") }
            Mock Invoke-WorkerPostMountDelay { $script:order.Add("postmount:$Tenant") }
            $oldOutput = $env:BC_SQL_PILOT_OUTPUT
            try {
                $env:BC_SQL_PILOT_OUTPUT = $TestDrive
                foreach ($tenant in @('tenant2','tenant3','tenant4')) {
                    & $script:realResetBody -ContainerName 'owned' -Tenant $tenant -TenantDatabaseName $tenant -TemplateDatabaseName 'default-test-template'
                }
                ($script:order -join ',') | Should -Be 'restore:tenant2,postmount:tenant2,restore:tenant3,postmount:tenant3,restore:tenant4,postmount:tenant4'
            } finally { $env:BC_SQL_PILOT_OUTPUT = $oldOutput }
        }
    }
}
