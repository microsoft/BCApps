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
        foreach ($key in $script:environment.Keys) { $script:oldEnvironment[$key] = [Environment]::GetEnvironmentVariable($key) }
    }
    BeforeEach {
        foreach ($environmentName in $script:environment.Keys) { [Environment]::SetEnvironmentVariable($environmentName, $script:environment[$environmentName]) }
    }
    AfterAll {
        foreach ($key in $script:oldEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $script:oldEnvironment[$key]) }
    }

    It 'contains thirty unique balanced original cells' {
        $cells = @(Get-WorkerWarmupCell)
        $cells.Count | Should -Be 30
        @($cells | ForEach-Object { "$($_.experiment)/$($_.country)/$($_.trial)" } | Sort-Object -Unique).Count | Should -Be 30
        @($cells | Group-Object experiment, country | Where-Object Count -ne 5).Count | Should -Be 0
        foreach ($index in 0..4) {
            $block = @($cells | Select-Object -Skip ($index * 6) -First 6)
            @($block | Group-Object experiment, country).Count | Should -Be 6
        }
    }
    It 'accepts each authorized arm: <Arm>' -ForEach @(@{ Arm = 'control' }, @{ Arm = 'workerwarmup' }, @{ Arm = 'navreadiness' }) {
        $env:BC_SQL_API_EXPERIMENT = $Arm
        Test-WorkerWarmupExperiment | Should -BeTrue
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

    Describe 'Per-remount phases' {
        InModuleScope WorkerWarmup {
            BeforeEach {
                Remove-Item "$TestDrive\worker-warmup" -Recurse -Force -ErrorAction SilentlyContinue
                Get-ChildItem $TestDrive -Filter 'worker-postmount-*.json' | Remove-Item
                $script:order = [Collections.Generic.List[string]]::new()
                $script:initialization = @{
                    Parameters = @{
                        containerName = 'bcbuildprojectsTestAppsW1Trial1workerwarmup123'
                        tenant = 'default'; companyName = 'My Company'
                        credential = [PSCredential]::new('test', [Security.SecureString]::new())
                        JUnitResultFileName = "$TestDrive\results\TestResults.xml"
                    }
                    AppIdByName = @{ 'System Application Test Library' = '11111111-1111-1111-1111-111111111111' }
                    AppNames = @('System Application Test Library', 'Expense Agent Tests')
                    Tenants = @('default', 'tenant2', 'tenant3', 'tenant4')
                    ScriptPath = 'original-runner.ps1'; TestType = 'IntegrationTest'
                    WarmupAction = {
                        param($context, $tenant, $directory)
                        $context.AppNames[0] | Should -Be 'System Application Test Library'
                        $script:order.Add("warmup:$tenant")
                        '<testsuites />' | Set-Content (Join-Path $directory 'TestResults-tenant2.xml')
                    }
                    ProbeAction = {
                        param($parameters, $tenant)
                        $parameters.companyName | Should -Be 'My Company'
                        $script:order.Add("probe:$tenant")
                    }
                }
                Initialize-WorkerWarmup @script:initialization
                @{
                    phase = 'reset-complete'; utc = '2026-10-08T00:00:00Z'
                    plan = @{ Tenant = 'tenant2'; Destination = 'tenant2'; Template = 'default-test-template'; Generation = 1 }
                } | ConvertTo-Json -Compress | Set-Content "$TestDrive\reset-timeline.jsonl"
                Mock Start-Sleep { $script:order.Add("sleep:$Seconds") }
            }
            It 'runs existing app callback once and accepts empty XML without extra waits or probe' {
                Invoke-WorkerPostMountDelay tenant2
                Invoke-WorkerRemountWarmup tenant2 139700
                ($script:order -join ',') | Should -Be 'warmup:tenant2'
                Should -Invoke Start-Sleep -Times 0 -Exactly
                Assert-WorkerWarmupReady tenant2 139700
                { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
                $record = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
                $record.passed | Should -BeTrue
                $record.app | Should -Be 'System Application Test Library'
                $record.phases.phase | Should -Be 'app-warmup'
                $record.probeAttempts | Should -Be 0
                $script:initialization.AppNames.Count | Should -Be 2
                $script:initialization.Parameters.tenant | Should -Be 'default'
            }
            It 'never warms probes or waits in control' {
                $env:BC_SQL_API_EXPERIMENT = 'control'
                Invoke-WorkerPostMountDelay tenant2
                Invoke-WorkerRemountWarmup tenant2 139700
                $script:order.Count | Should -Be 0
                Assert-WorkerWarmupReady tenant2 139700
            }
            It 'performs NAV-inspired delay, app, same-tenant probe and final delay in order' {
                $env:BC_SQL_API_EXPERIMENT = 'navreadiness'
                Invoke-WorkerPostMountDelay tenant2
                ($script:order -join ',') | Should -Be 'sleep:30'
                Invoke-WorkerRemountWarmup tenant2 139700
                ($script:order -join ',') | Should -Be 'sleep:30,warmup:tenant2,probe:tenant2,sleep:30'
                Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 30 }
                Assert-WorkerWarmupReady tenant2 139700
                $record = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
                ($record.phases.phase -join ',') | Should -Be 'app-warmup,companies-probe,pretest-delay'
                $record.postMount.phases[0].phase | Should -Be 'postmount-delay'
                $record.postMount.passed | Should -BeTrue
                $record.probeAttempts | Should -Be 1
                foreach ($phase in $record.phases) {
                    $phase.passed | Should -BeTrue
                    $phase.startedUtc | Should -Not -BeNullOrEmpty
                    $phase.completedUtc | Should -Not -BeNullOrEmpty
                    $phase.elapsedMilliseconds | Should -BeGreaterOrEqual 0
                }
            }
            It 'fails closed on app failure without retry, probe or ready receipt' {
                $env:BC_SQL_API_EXPERIMENT = 'navreadiness'
                $script:workerWarmup.WarmupAction = { throw 'simulated app failure' }
                Invoke-WorkerPostMountDelay tenant2
                { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw '*simulated app failure*'
                { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
                ($script:order -join ',') | Should -Be 'sleep:30'
                $record = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
                $record.passed | Should -BeFalse
                $record.failedPhase | Should -Be 'app-warmup'
                $record.failureCategory | Should -Be 'readiness_failure'
                $record.attempts | Should -Be 1
                $record.probeAttempts | Should -Be 0
            }
            It 'fails visibly on a single failed probe and never waits or retries afterward' {
                $env:BC_SQL_API_EXPERIMENT = 'navreadiness'
                $script:workerWarmup.ProbeAction = { $script:order.Add('failed-probe'); throw 'simulated HTTP500' }
                Invoke-WorkerPostMountDelay tenant2
                { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw '*simulated HTTP500*'
                { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
                ($script:order -join ',') | Should -Be 'sleep:30,warmup:tenant2,failed-probe'
                $record = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
                $record.failedPhase | Should -Be 'companies-probe'
                $record.failureCategory | Should -Be 'readiness_failure'
                $record.probeAttempts | Should -Be 1
            }
            It 'records a failed postmount delay and prevents warmup' {
                $env:BC_SQL_API_EXPERIMENT = 'navreadiness'
                Mock Start-Sleep { throw 'interrupted wait' }
                { Invoke-WorkerPostMountDelay tenant2 } | Should -Throw
                { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw '*postmount*'
                $record = Get-Content "$TestDrive\worker-postmount-tenant2-g1.json" -Raw | ConvertFrom-Json
                $record.passed | Should -BeFalse
                $record.failedPhase | Should -Be 'postmount-delay'
            }
            It 'does not authorize dispatch when the final pretest wait fails' {
                $env:BC_SQL_API_EXPERIMENT = 'navreadiness'
                Invoke-WorkerPostMountDelay tenant2
                Mock Start-Sleep { throw 'interrupted pretest wait' }
                { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw
                { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
                $record = Get-Content "$TestDrive\worker-warmup\tenant2-g1-cu139700\warmup.json" -Raw | ConvertFrom-Json
                $record.failedPhase | Should -Be 'pretest-delay'
                $record.passed | Should -BeFalse
                $record.probeAttempts | Should -Be 1
            }
            It 'warms the post-discovery restore too' {
                (Get-Content "$TestDrive\reset-timeline.jsonl" -Raw).Replace('default-test-template', 'default') |
                    Set-Content "$TestDrive\reset-timeline.jsonl"
                Invoke-WorkerPostMountDelay tenant2
                Invoke-WorkerRemountWarmup tenant2 0
                Test-Path "$TestDrive\worker-warmup\tenant2-g1-cu0\warmup.json" | Should -BeTrue
            }
            It 'rejects duplicate pacing/warmup, missing pacing, wrong CU, stale generation and default' {
                { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw
                Invoke-WorkerPostMountDelay tenant2
                { Invoke-WorkerPostMountDelay tenant2 } | Should -Throw
                Invoke-WorkerRemountWarmup tenant2 139700
                { Invoke-WorkerRemountWarmup tenant2 139700 } | Should -Throw
                { Assert-WorkerWarmupReady tenant2 139702 } | Should -Throw
                { Invoke-WorkerRemountWarmup default 139700 } | Should -Throw
                (Get-Content "$TestDrive\reset-timeline.jsonl" -Raw).Replace('"Generation":1', '"Generation":2') |
                    Set-Content "$TestDrive\reset-timeline.jsonl"
                { Assert-WorkerWarmupReady tenant2 139700 } | Should -Throw
                { Invoke-WorkerRemountWarmup tenant2 139702 } | Should -Throw
                Invoke-WorkerPostMountDelay tenant2
                Invoke-WorkerRemountWarmup tenant2 139702
                Assert-WorkerWarmupReady tenant2 139702
            }
            It 'rejects a failed remount' {
                (Get-Content "$TestDrive\reset-timeline.jsonl" -Raw).Replace('reset-complete', 'reset-failed') |
                    Set-Content "$TestDrive\reset-timeline.jsonl"
                { Invoke-WorkerPostMountDelay tenant2 } | Should -Throw
            }
            It 'rejects changed original app selection or missing package' {
                $script:initialization.AppNames = @('System Application Test', 'Expense Agent Tests')
                { Initialize-WorkerWarmup @script:initialization } | Should -Throw
                $script:initialization.AppNames = @('System Application Test Library', 'Expense Agent Tests')
                $script:initialization.AppIdByName = @{}
                { Initialize-WorkerWarmup @script:initialization } | Should -Throw
            }
        }
    }
    It 'requires all 22 unique remount/CU receipts, not a subset or duplicates' {
        Remove-Item "$TestDrive\worker-warmup" -Recurse -Force -ErrorAction SilentlyContinue
        $ids = @(0,139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343)
        foreach ($id in $ids) {
            $null = New-Item "$TestDrive\worker-warmup\$id" -ItemType Directory -Force
            @{ passed = $true; executed = $true; attempts = 1; probeAttempts = 0; nextCodeunit = $id } |
                ConvertTo-Json | Set-Content "$TestDrive\worker-warmup\$id\warmup.json"
        }
        Test-WorkerWarmupComplete | Should -BeTrue
        @{ passed = $true; executed = $true; attempts = 1; probeAttempts = 0; nextCodeunit = 139700 } |
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
    It 'aggregates phase timing by worker without double counting nested postmount receipts' {
        $oldWorkspace = $env:GITHUB_WORKSPACE
        try {
            $env:GITHUB_WORKSPACE = "$TestDrive\phase-measurement"
            $output = "$env:GITHUB_WORKSPACE\sql-reset-pilot-output"
            $null = New-Item "$output\worker-warmup\one" -ItemType Directory -Force
            $postMount = @{ tenant = 'tenant2'; generation = 1; phases = @(
                @{ phase = 'postmount-delay'; passed = $true; elapsedMilliseconds = 30000 }
            ) }
            $postMount | ConvertTo-Json -Depth 6 | Set-Content "$output\worker-postmount-tenant2-g1.json"
            @{ tenant = 'tenant2'; generation = 1; postMount = $postMount; phases = @(
                @{ phase = 'app-warmup'; passed = $true; elapsedMilliseconds = 5000 }
                @{ phase = 'companies-probe'; passed = $false; elapsedMilliseconds = 75 }
            ) } | ConvertTo-Json -Depth 8 | Set-Content "$output\worker-warmup\one\warmup.json"
            & (Join-Path $PSScriptRoot 'WorkerMeasurements.ps1')
            $result = Get-Content "$output\worker-performance.json" -Raw | ConvertFrom-Json
            $result.readinessPhaseMilliseconds | Should -Be 35075
            $result.readinessPhaseTotalsByWorker.Count | Should -Be 3
            $result.readinessFailures.Count | Should -Be 1
            $result.readinessFailures[0].phase | Should -Be 'companies-probe'
        } finally { $env:GITHUB_WORKSPACE = $oldWorkspace }
    }
}
