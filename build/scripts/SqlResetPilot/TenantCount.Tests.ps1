BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'TenantCount.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot 'Lifecycle.psm1') -Force
    function global:Invoke-ScriptInBcContainer { param($containerName,$useSession,$scriptblock,$argumentList) throw 'Live call forbidden.' }
    function global:Get-BcContainerServerConfiguration { param($ContainerName) throw 'Live call forbidden.' }
}
Describe 'Isolated tenant-count identity and scheduling' {
    It 'uses an independent two-slot matrix and records scheduling-only supersession' {
        $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $workflow = Get-Content (Join-Path $root '.github\workflows\CICD.yaml') -Raw
        $batch = Get-Content (Join-Path $root '.github\workflows\SqlApiComparisonBatch.yaml') -Raw
        $planner = Get-Content (Join-Path $PSScriptRoot 'PlanTenantCount.ps1') -Raw
        $workflow | Should -Match 'group: sql-api-646383-tenant-count-comparison'
        $workflow | Should -Not -Match 'group: sql-api-646383-300-trial-comparison'
        $workflow | Should -Match 'cancel-in-progress: false'
        $workflow | Should -Match 'needs: Plan'
        $batch | Should -Match 'max-parallel: 2'
        $batch | Should -Match 'fail-fast: false'
        $planner | Should -Match "concurrencyGroup = 'sql-api-646383-tenant-count-comparison'; maxParallel = 2"
        $planner | Should -Match "schedulingSupersedesRunId = '37695638367'; schedulingOnlySuccessor = \`$true; testRerun = \`$false"
    }
    BeforeEach {
        $script:saved = @{}
        $values = @{
            GITHUB_REPOSITORY='microsoft/BCApps'; GITHUB_REF='refs/heads/features/646383-sql-api-tenant-count-comparison'
            GITHUB_EVENT_NAME='workflow_dispatch'; GITHUB_RUN_ATTEMPT='1'; GITHUB_RUN_ID='123'
            BC_SQL_PILOT_ARM='control'; BC_SQL_API_EXPERIMENT='control'; BC_SQL_TENANT_COUNT='1'
            BC_SQL_PILOT_COUNTRY='W1'; BC_SQL_PILOT_TRIAL='1'; BC_SQL_PILOT_OUTPUT=$TestDrive
        }
        foreach ($envKey in $values.Keys) {
            $script:saved[$envKey] = [Environment]::GetEnvironmentVariable($envKey)
            [Environment]::SetEnvironmentVariable($envKey,$values[$envKey])
        }
    }
    AfterEach {
        foreach ($key in $script:saved.Keys) { [Environment]::SetEnvironmentVariable($key,$script:saved[$key]) }
    }
    It 'has exactly 20 unique balanced cells, including all five indices' {
        $cells = @(Get-SqlTenantCell)
        $cells.Count | Should -Be 20
        @($cells | ForEach-Object { "$($_.tenantCount)/$($_.country)/$($_.trial)" } | Sort-Object -Unique).Count | Should -Be 20
        foreach ($count in 1,2) {
            foreach ($country in 'W1','DE') {
                @($cells | Where-Object { $_.tenantCount -eq $count -and $_.country -eq $country }).trial | Should -Be @(1,2,3,4,5)
            }
        }
    }
    It 'rejects <key>=<value>' -ForEach @(
        @{key='GITHUB_REF';value='refs/heads/features/646383-sql-api-300-trial-comparison'}
        @{key='GITHUB_REPOSITORY';value='other/BCApps'}
        @{key='GITHUB_EVENT_NAME';value='pull_request'}
        @{key='GITHUB_RUN_ATTEMPT';value='2'}
        @{key='BC_SQL_TENANT_COUNT';value='4'}
        @{key='BC_SQL_TENANT_COUNT';value='0'}
        @{key='BC_SQL_API_EXPERIMENT';value='retry'}
        @{key='BC_SQL_API_EXPERIMENT';value='warmup'}
        @{key='BC_SQL_PILOT_TRIAL';value='6'}
        @{key='BC_SQL_PILOT_COUNTRY';value='US'}
    ) {
        [Environment]::SetEnvironmentVariable($key,$value)
        Test-SqlTenantExperiment | Should -BeFalse
        { Get-SqlTenantContainerName } | Should -Throw
    }
    It 'observes exactly <count> mounted tenants and actual workers' -ForEach @(@{count=1},@{count=2}) {
        $env:BC_SQL_TENANT_COUNT = [string]$count
        Mock Get-BcContainerServerConfiguration -ModuleName TenantCount { @{Multitenant='true'} }
        Mock Invoke-ScriptInBcContainer -ModuleName TenantCount {
            @{id='default';database='default';server='.';state='Operational'}
            if ($env:BC_SQL_TENANT_COUNT -eq '2') { @{id='tenant2';database='tenant2';server='.';state='Operational'} }
        }
        Assert-SqlTenantContainer (Get-SqlTenantContainerName)
        $proof = Get-Content (Join-Path $TestDrive 'mounted-tenants.json') -Raw | ConvertFrom-Json
        $proof.actualMountedTenants | Should -Be $count
        $proof.workerCount | Should -Be $count
        $proof.actualWorkers | Should -Contain default
    }
    It 'rejects non-multitenant NST or unexpected additional mount' {
        Mock Get-BcContainerServerConfiguration -ModuleName TenantCount { @{Multitenant='false'} }
        { Assert-SqlTenantContainer (Get-SqlTenantContainerName) } | Should -Throw '*multitenant*'
        Mock Get-BcContainerServerConfiguration -ModuleName TenantCount { @{Multitenant='true'} }
        Mock Invoke-ScriptInBcContainer -ModuleName TenantCount {
            @{id='default';database='default';state='Operational'}
            @{id='tenant2';database='tenant2';state='Operational'}
        }
        { Assert-SqlTenantContainer (Get-SqlTenantContainerName) } | Should -Throw '*mounted tenants*'
    }
    It 'uses a detached protected source for <count> workers including default' -ForEach @(@{count=1},@{count=2}) {
        $env:BC_SQL_TENANT_COUNT = [string]$count
        $name = Get-SqlTenantContainerName
        $ids = if($count -eq 1){@('default')}else{@('default','tenant2')}
        $tenants = @($ids | ForEach-Object { [PSCustomObject]@{Id=$_;DatabaseName=$_} })
        Initialize-SqlResetPilot $name $tenants control 123 $TestDrive -TenantCount $count
        { Get-SqlResetPlan $name default default default } | Should -Throw
        { Get-SqlResetPlan $name default default default-test-template } | Should -Throw '*read-only*'
        Mock Invoke-ScriptInBcContainer -ModuleName Lifecycle { '12345678-1234-1234-1234-123456789012' }
        Protect-SqlPilotTemplate $name default-test-template
        foreach ($id in $ids) {
            $plan = Get-SqlResetPlan $name $id $id default-test-template
            $plan.Destination | Should -Be $id
            $plan.Template | Should -Be default-test-template
            $plan.TenantCount | Should -Be $count
            Complete-SqlResetPlan $plan
            (Get-SqlResetPlan $name $id $id default-test-template).Generation | Should -Be 2
        }
        Mock Invoke-ScriptInBcContainer -ModuleName Lifecycle {
            $argumentList.Previous | Should -Be 'default'
            $argumentList.Destination | Should -Be 'default'
            $argumentList.Template | Should -Be 'default-test-template'
            $body=$scriptblock.ToString()
            $body | Should -Match 'is_read_only = 1'
            $body | Should -Match 'TemplateIdentity'
            $body | Should -Match "Destination -notin @\('default', 'tenant2'\)"
            $body | Should -Match 'Remove-NAVDatabase -DatabaseName \$plan.Previous'
            $body | Should -Match 'Copy-NAVDatabase -SourceDatabaseName \$plan.Template -DestinationDatabaseName \$plan.Destination'
            $body | Should -Match 'SET READ_WRITE WITH NO_WAIT'
            $body | Should -Match 'OverwriteTenantIdInDatabase -Force'
            $body.IndexOf('Dismount-NAVTenant') | Should -BeLessThan $body.IndexOf('Remove-NAVDatabase')
            $body.IndexOf('Remove-NAVDatabase') | Should -BeLessThan $body.IndexOf('Copy-NAVDatabase')
            $body.IndexOf('Copy-NAVDatabase') | Should -BeLessThan $body.IndexOf('SET READ_WRITE')
            $body.IndexOf('SET READ_WRITE') | Should -BeLessThan $body.IndexOf('Mount-NAVTenant')
            @{state='Operational'}
        }
        Invoke-SqlPilotReset $name default default default-test-template
        (Get-SqlResetPlan $name default default default-test-template).Generation | Should -Be 3
        { Protect-SqlPilotTemplate $name default-test-template } | Should -Throw
        { Get-SqlResetPlan $name default default-test-template default } | Should -Throw
        { Get-SqlResetPlan $name default default default } | Should -Throw
        { Get-SqlResetPlan $name tenant3 tenant3 default-test-template } | Should -Throw
    }
    It 'cannot enable default reset on the original four-tenant gate' {
        $name = Get-SqlTenantContainerName
        $env:GITHUB_REF = 'refs/heads/features/646383-sql-api-300-trial-comparison'
        { Initialize-SqlResetPilot $name @([PSCustomObject]@{Id='default';DatabaseName='default'}) control 123 $TestDrive -TenantCount 1 } | Should -Throw
    }
    It 'records nonnegative monotonic timing and explicit incomplete state' {
        $ticks=[Diagnostics.Stopwatch]::GetTimestamp()
        Write-SqlTenantTiming reset $ticks ([datetime]::UtcNow.ToString('o')) $false
        $record=Get-Content (Join-Path $TestDrive 'phase-timing.jsonl') -Raw | ConvertFrom-Json
        $record.elapsedMilliseconds | Should -BeGreaterOrEqual 0
        $record.completed | Should -BeFalse
    }
}
