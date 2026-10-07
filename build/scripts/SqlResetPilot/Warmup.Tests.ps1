$discoveryArm = $env:BC_SQL_PILOT_ARM
try {
    $env:BC_SQL_PILOT_ARM = 'control'
    Import-Module (Join-Path $PSScriptRoot '..\ParallelTestExecution.psm1') -Force
} finally {
    $env:BC_SQL_PILOT_ARM = $discoveryArm
}
BeforeAll {
    $script:oldArm = $env:BC_SQL_PILOT_ARM
    $script:oldOutput = $env:BC_SQL_PILOT_OUTPUT
    $script:oldRun = $env:GITHUB_RUN_ID
    $script:oldRunnerTemp = $env:RUNNER_TEMP
    $env:BC_SQL_PILOT_ARM = 'control'
    $env:BC_SQL_PILOT_OUTPUT = $TestDrive
    $env:GITHUB_RUN_ID = '123'
    $env:RUNNER_TEMP = $TestDrive
    function global:Get-BcContainerAppInfo {
        param($containerName, $tenant, [switch]$tenantSpecificProperties)
        $null = $containerName, $tenant, $tenantSpecificProperties
        throw 'Live container call forbidden.'
    }
}
AfterAll {
    $env:BC_SQL_PILOT_ARM = $script:oldArm
    $env:BC_SQL_PILOT_OUTPUT = $script:oldOutput
    $env:GITHUB_RUN_ID = $script:oldRun
    $env:RUNNER_TEMP = $script:oldRunnerTemp
}

Describe 'Diagnostic first-app warmup' {
    InModuleScope ParallelTestExecution {
        BeforeEach {
            $script:parameters = @{
                containerName = 'owned'; tenant = 'default'; companyName = 'My Company'
                JUnitResultFileName = (Join-Path $TestDrive 'TestResults.xml')
            }
            Mock Invoke-WarmupDispatch { @($Pending | Select-Object -Skip 1) }
        }
        It 'calls the original warmup once on default and keeps results outside prefix coverage' {
            Invoke-SqlPilotWarmup -Parameters $script:parameters -AppNames @('First', 'Second') `
                -AppIdByName @{ First = 'id' } -Tenants @('default','tenant2','tenant3','tenant4') `
                -ScriptPath 'runner.ps1' -TestType 'IntegrationTest' -CleanTenantAppNames @('First','Second')
            Should -Invoke Invoke-WarmupDispatch -Times 1 -Exactly -ParameterFilter {
                $Parameters.tenant -eq 'default' -and $Tenants[0] -eq 'default' -and
                $Parameters.JUnitResultFileName -like '*\warmup\TestResults.xml' -and
                $State.rerunBudget -eq 0 -and $CleanTenantAppNames -contains 'First'
            }
            $script:parameters.JUnitResultFileName | Should -Not -Match '\\warmup\\'
        }
        It 'stops on warmup failure without retrying' {
            Mock Invoke-WarmupDispatch { $State.hasFailures = $true; @($Pending | Select-Object -Skip 1) }
            { Invoke-SqlPilotWarmup $script:parameters @('First','Second') @{ First = 'id' } `
                @('default','tenant2') 'runner.ps1' 'IntegrationTest' @('First') } | Should -Throw '*warmup failed*'
            Should -Invoke Invoke-WarmupDispatch -Times 1 -Exactly
        }
        It 'stops on any transient queue without retrying' {
            Mock Invoke-WarmupDispatch { $State.transient = @('failed'); @($Pending | Select-Object -Skip 1) }
            { Invoke-SqlPilotWarmup $script:parameters @('First','Second') @{ First = 'id' } `
                @('default','tenant2') 'runner.ps1' 'IntegrationTest' @('First') } | Should -Throw '*warmup failed*'
            Should -Invoke Invoke-WarmupDispatch -Times 1 -Exactly
        }
        It 'rejects a skipped warmup or a nondefault primary tenant' {
            { Invoke-SqlPilotWarmup $script:parameters @('First','Second') @{} `
                @('default','tenant2') 'runner.ps1' 'IntegrationTest' @('First') } | Should -Throw
            $script:parameters.tenant = 'tenant2'
            { Invoke-SqlPilotWarmup $script:parameters @('First','Second') @{ First = 'id' } `
                @('tenant2','default') 'runner.ps1' 'IntegrationTest' @('First') } | Should -Throw
            Should -Invoke Invoke-WarmupDispatch -Times 0
        }
        It 'freezes the template before warmup and only then starts the clean lane' {
            $script:order = [Collections.Generic.List[string]]::new()
            Mock Test-Path { $false }
            Mock Set-Content {}
            Mock Get-AvailableBcTenantInfo {
                @('default','tenant2','tenant3','tenant4') | ForEach-Object {
                    [PSCustomObject]@{ Id = $_; DatabaseName = $_ }
                }
            }
            Mock Get-BcContainerAppInfo {
                [PSCustomObject]@{ IsInstalled = $true; Name = 'First'; AppId = 'id' }
            }
            Mock Get-ALGoSetting { $true }
            Mock Get-AppRerunBudget { 0 }
            Mock Get-RequiredDisabledWorkItems { [PSCustomObject]@{ CodeunitId = 139700 } }
            Mock Select-SqlPilotPrefix { $WorkItems }
            Mock Reset-BcTestTenant { $script:order.Add('discovery-reset') }
            Mock New-BcTestTenantTemplate { $script:order.Add('template'); 'default-test-template' }
            Mock Invoke-SqlPilotWarmup { $script:order.Add('warmup') }
            Mock Invoke-RequiredDisabledTestExecution { $script:order.Add('clean'); $true }
            Mock Merge-TenantTestResults {}
            Invoke-ParallelTestExecution $script:parameters 'runner.ps1' 'IntegrationTest' @('First','Second') |
                Should -BeTrue
            ($script:order -join ',') | Should -Be 'discovery-reset,template,warmup,clean'
        }
        It 'never dispatches clean tests when warmup fails' {
            $script:order = [Collections.Generic.List[string]]::new()
            Mock Test-Path { $false }
            Mock Set-Content {}
            Mock Get-AvailableBcTenantInfo {
                @('default','tenant2','tenant3','tenant4') | ForEach-Object {
                    [PSCustomObject]@{ Id = $_; DatabaseName = $_ }
                }
            }
            Mock Get-BcContainerAppInfo { [PSCustomObject]@{ IsInstalled = $true; Name = 'First'; AppId = 'id' } }
            Mock Get-ALGoSetting { $true }
            Mock Get-AppRerunBudget { 0 }
            Mock Get-RequiredDisabledWorkItems { [PSCustomObject]@{ CodeunitId = 139700 } }
            Mock Select-SqlPilotPrefix { $WorkItems }
            Mock Reset-BcTestTenant {}
            Mock New-BcTestTenantTemplate { 'default-test-template' }
            Mock Invoke-SqlPilotWarmup { throw 'warmup failed' }
            Mock Invoke-RequiredDisabledTestExecution { $true }
            { Invoke-ParallelTestExecution $script:parameters 'runner.ps1' 'IntegrationTest' @('First','Second') } |
                Should -Throw '*warmup failed*'
            Should -Invoke Invoke-RequiredDisabledTestExecution -Times 0
        }
        It 'makes failures terminal even if the ordinary rerun budget is positive' {
            foreach ($outcome in @('Failed', 'Transient')) {
                $state = [PSCustomObject]@{
                    hasFailures = $false; transient = @(); rerun = @()
                    rerunBudget = 2; tenantCount = 4; rerunDone = @{}
                }
                Register-TestJobOutcome -Result ([PSCustomObject]@{ Outcome = $outcome }) -State $state
                $state.hasFailures | Should -BeTrue
                $state.transient.Count | Should -Be 0
                $state.rerun.Count | Should -Be 0
            }
        }
    }
}

Describe 'Companies probe batch barrier' {
    InModuleScope ParallelTestExecution {
        BeforeEach {
            $script:order = [Collections.Generic.List[string]]::new()
            $script:items = @(1..6 | ForEach-Object { [PSCustomObject]@{ Key = "CU$_" } })
            $script:tenants = @('tenant2','tenant3','tenant4') | ForEach-Object {
                [PSCustomObject]@{ Id = $_; DatabaseName = $_ }
            }
            $script:parameters = @{ containerName = 'owned'; companyName = 'My Company'; credential = [PSCredential]::Empty }
            Mock Reset-BcTestTenant { $script:order.Add("reset:$Tenant") }
            Mock Invoke-SqlPilotCompaniesProbe { $script:order.Add("probe:$Tenant") }
            Mock Start-RequiredDisabledDispatch { $script:order.Add("dispatch:$($TenantInfo.Id)") }
            Mock Wait-ForAllTestJobs {}
        }
        It 'probes each fresh worker once after every reset and before any dispatch in each batch' {
            Invoke-RequiredDisabledTestExecution $script:parameters $script:items $script:tenants `
                'default-test-template' 'runner.ps1' 'IntegrationTest' | Should -BeTrue
            $batch = 'reset:tenant2,reset:tenant3,reset:tenant4,probe:tenant2,probe:tenant3,probe:tenant4,dispatch:tenant2,dispatch:tenant3,dispatch:tenant4'
            ($script:order -join ',') | Should -Be "$batch,$batch"
            Should -Invoke Invoke-SqlPilotCompaniesProbe -Times 6 -Exactly
        }
        It 'stops without dispatch or retry when a probe fails' {
            Mock Invoke-SqlPilotCompaniesProbe { throw 'probe failed' }
            { Invoke-RequiredDisabledTestExecution $script:parameters $script:items $script:tenants `
                'default-test-template' 'runner.ps1' 'IntegrationTest' } | Should -Throw '*probe failed*'
            Should -Invoke Reset-BcTestTenant -Times 3 -Exactly
            Should -Invoke Invoke-SqlPilotCompaniesProbe -Times 1 -Exactly
            Should -Invoke Start-RequiredDisabledDispatch -Times 0
        }
        It 'does not execute another batch or retry after a failed test batch' {
            Mock Wait-ForAllTestJobs { $state.hasFailures = $true }
            Invoke-RequiredDisabledTestExecution $script:parameters $script:items $script:tenants `
                'default-test-template' 'runner.ps1' 'IntegrationTest' | Should -BeFalse
            Should -Invoke Start-RequiredDisabledDispatch -Times 3 -Exactly
            Should -Invoke Invoke-SqlPilotCompaniesProbe -Times 3 -Exactly
        }
    }
}
