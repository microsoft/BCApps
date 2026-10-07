$old=$env:BC_SQL_PILOT_ARM
try {
    $env:BC_SQL_PILOT_ARM='control'
    Import-Module (Join-Path $PSScriptRoot '..\ParallelTestExecution.psm1') -Force
} finally {
    $env:BC_SQL_PILOT_ARM=$old
}
Describe 'Tenant diagnostic integration contracts' {
    BeforeEach {
        Remove-Item (Join-Path $TestDrive 'parallelTests_owned.json') -ErrorAction SilentlyContinue
        $script:saved=@{}
        $values=@{
            GITHUB_REPOSITORY='microsoft/BCApps';GITHUB_REF='refs/heads/features/646383-sql-api-tenant-count-comparison'
            GITHUB_EVENT_NAME='workflow_dispatch';GITHUB_RUN_ATTEMPT='1';GITHUB_RUN_ID='123'
            BC_SQL_PILOT_ARM='control';BC_SQL_API_EXPERIMENT='control';BC_SQL_TENANT_COUNT='1'
            BC_SQL_PILOT_COUNTRY='W1';BC_SQL_PILOT_TRIAL='1';BC_SQL_PILOT_OUTPUT=$TestDrive
        }
        foreach($key in $values.Keys){$script:saved[$key]=[Environment]::GetEnvironmentVariable($key);[Environment]::SetEnvironmentVariable($key,$values[$key])}
    }
    AfterEach {
        foreach($key in $script:saved.Keys){[Environment]::SetEnvironmentVariable($key,$script:saved[$key])}
    }
    InModuleScope ParallelTestExecution {
      Context 'Clean scheduling and measurements' {
        BeforeEach {
            Mock Assert-SqlTenantContainer {}
            Mock Start-SqlTenantSampler { [PSCustomObject]@{Id=5} }
            Mock Stop-SqlTenantSampler {}
            Mock Write-SqlTenantTiming {}
        }
        It 'keeps warmup and retry disabled while enabling coverage and original evidence' {
            Test-SqlApiExperiment | Should -BeTrue
            Test-SqlApiWarmupEnabled | Should -BeFalse
            $state=[PSCustomObject]@{hasFailures=$false;transient=@();retried=@{}}
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{Outcome='SqlPoolRetry';SqlRetryEvidence=@{confirmed=$true};AppName='CU'})
            $state.hasFailures | Should -BeTrue
            $state.transient.Count | Should -Be 0
        }
        It 'always stops sampler and records incomplete execution on exceptions' {
            Mock Invoke-ParallelTestExecutionCore { throw 'test failure' }
            { Invoke-ParallelTestExecution @{containerName='owned'} script.ps1 IntegrationTest @('Tests') } | Should -Throw '*test failure*'
            Should -Invoke Stop-SqlTenantSampler -Times 1 -Exactly
            Should -Invoke Write-SqlTenantTiming -Times 1 -Exactly -ParameterFilter {-not $Completed}
        }
        It 'records completed execution even when returned tests fail' {
            Mock Invoke-ParallelTestExecutionCore {$false}
            Invoke-ParallelTestExecution @{containerName='owned'} script.ps1 IntegrationTest @('Tests') | Should -BeFalse
            Should -Invoke Stop-SqlTenantSampler -Times 1 -Exactly
            Should -Invoke Write-SqlTenantTiming -Times 1 -Exactly -ParameterFilter {$Completed}
        }
        It 'returns cached completed result <passed> without repeating measurements or tests' -ForEach @(@{passed=$true},@{passed=$false}) {
            @{completed=$true;finalResult=$passed}|ConvertTo-Json|Set-Content (Join-Path $TestDrive 'parallelTests_owned.json')
            Get-CachedTestRunResult -ContainerName owned | Should -Be $passed
            Mock Invoke-ParallelTestExecutionCore {throw 'must not execute again'}
            Invoke-ParallelTestExecution @{containerName='owned'} script.ps1 IntegrationTest @('Tests') | Should -Be $passed
            Should -Invoke Start-SqlTenantSampler -Times 0 -Exactly
            Should -Invoke Invoke-ParallelTestExecutionCore -Times 0 -Exactly
        }
        It 'rejects invalid lane before any template or discovery mutation' {
            Mock Get-ALGoSetting {$false}
            Mock New-BcTestTenantTemplate {throw 'must not copy'}
            Mock Get-RequiredDisabledWorkItems {throw 'must not discover'}
            {Invoke-ParallelTestExecutionCore @{containerName='owned';tenant='default'} script.ps1 IntegrationTest @('Tests')} |
                Should -Throw '*clean IntegrationTest lane*'
            Should -Invoke New-BcTestTenantTemplate -Times 0 -Exactly
            Should -Invoke Get-RequiredDisabledWorkItems -Times 0 -Exactly
        }
        It 'freezes before discovery and resets default after discovery failure for <count> tenants' -ForEach @(@{count=1},@{count=2}) {
            $env:BC_SQL_TENANT_COUNT=[string]$count
            $script:sequence=[Collections.Generic.List[string]]::new()
            Mock Get-AvailableBcTenantInfo {
                [PSCustomObject]@{Id='default';DatabaseName='default'}
                if($env:BC_SQL_TENANT_COUNT -eq '2'){[PSCustomObject]@{Id='tenant2';DatabaseName='tenant2'}}
            }
            Mock Initialize-SqlResetPilot {}
            Mock Get-BcContainerAppInfo { [PSCustomObject]@{Name='Tests';AppId='id';IsInstalled=$true} }
            Mock Get-ALGoSetting {$true}
            Mock New-BcTestTenantTemplate {$script:sequence.Add('copy');'default-test-template'}
            Mock Protect-SqlPilotTemplate {$script:sequence.Add('protect')}
            Mock Get-RequiredDisabledWorkItems {$script:sequence.Add("discover-$($Parameters.tenant)");throw 'discovery failed'}
            Mock Reset-BcTestTenant {$script:sequence.Add("reset-$Tenant-$TemplateDatabaseName")}
            { Invoke-ParallelTestExecutionCore @{containerName='owned';tenant='default'} script.ps1 IntegrationTest @('Tests') } | Should -Throw '*discovery failed*'
            @($script:sequence) | Should -Be @('copy','protect','discover-default','reset-default-default-test-template')
            Should -Invoke New-BcTestTenantTemplate -Times 1 -Exactly
            Should -Invoke Reset-BcTestTenant -Times 1 -Exactly -ParameterFilter {$Tenant -eq 'default' -and $TemplateDatabaseName -eq 'default-test-template'}
        }
        It 'uses every mounted worker and accepts only complete 253/19/21 results for count <count> complete <complete>' -ForEach @(
            @{count=1;complete=$true},@{count=2;complete=$true},@{count=1;complete=$false}
        ) {
            $env:BC_SQL_TENANT_COUNT=[string]$count
            Mock Get-AvailableBcTenantInfo {
                [PSCustomObject]@{Id='default';DatabaseName='default'}
                if($env:BC_SQL_TENANT_COUNT -eq '2'){[PSCustomObject]@{Id='tenant2';DatabaseName='tenant2'}}
            }
            Mock Initialize-SqlResetPilot {}
            Mock Get-BcContainerAppInfo { [PSCustomObject]@{Name='Tests';AppId='id';IsInstalled=$true} }
            Mock Get-ALGoSetting {$true}
            Mock New-BcTestTenantTemplate {'default-test-template'}
            Mock Protect-SqlPilotTemplate {}
            Mock Get-RequiredDisabledWorkItems {
                @(139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343)|
                    ForEach-Object {[PSCustomObject]@{CodeunitId=$_;Key="Tests::$_";TestCount=1;AppName='Tests';AppId='id'}}
            }
            Mock Reset-BcTestTenant {}
            Mock Invoke-RequiredDisabledTestExecution {
                $TenantInfo.Count | Should -Be ([int]$env:BC_SQL_TENANT_COUNT)
                $TenantInfo.Id | Should -Contain 'default'
                $TemplateDatabaseName | Should -Be 'default-test-template'
                $WorkItems.Count | Should -Be 21
                $true
            }
            Mock Merge-TenantTestResults {}
            Mock Get-ChildItem {@()}
            $xml='<testsuites>'
            foreach($suite in 1..21) {
                $xml+="<testsuite name=`"$suite Test`">"
                foreach($case in 1..12) {
                    $skip=if($suite -le 19 -and $case -eq 1){'<skipped />'}else{''}
                    $xml+="<testcase name=`"C${suite}T$case`">$skip</testcase>"
                }
                if($suite -eq 20 -and $complete){$xml+='<testcase name="CapabilitiesProjectsEnabledViaAPI"/>'}
                $xml+='</testsuite>'
            }
            $xml+='</testsuites>'
            $path=Join-Path $TestDrive 'final.xml'
            $xml|Set-Content $path
            Invoke-ParallelTestExecutionCore @{containerName='owned';tenant='default';JUnitResultFileName=$path} script.ps1 IntegrationTest @('Tests')|
                Should -Be $complete
            $counts=Get-Content (Join-Path $TestDrive 'final-counts.json') -Raw|ConvertFrom-Json
            $counts.completeCohort | Should -Be $complete
            $counts.skipped | Should -Be 19
            $counts.suites | Should -Be 21
            Should -Invoke Invoke-RequiredDisabledTestExecution -Times 1 -Exactly
        }
      }
    }
}
