BeforeAll {
    function global:Test-BcContainer {param($containerName) throw 'Live call forbidden.'}
    function global:New-BcContainer {param($useGenericImage) throw 'Live call forbidden.'}
}
Describe 'Tenant-count provisioning ownership and immutable runtime' {
    BeforeEach {
        $script:saved=@{}
        $values=@{
            GITHUB_REPOSITORY='microsoft/BCApps';GITHUB_REF='refs/heads/features/646383-sql-api-tenant-count-comparison'
            GITHUB_EVENT_NAME='workflow_dispatch';GITHUB_RUN_ATTEMPT='1';GITHUB_RUN_ID='123'
            BC_SQL_PILOT_ARM='control';BC_SQL_API_EXPERIMENT='control';BC_SQL_TENANT_COUNT='1'
            BC_SQL_PILOT_COUNTRY='W1';BC_SQL_PILOT_TRIAL='1';BC_SQL_PILOT_OUTPUT=$TestDrive
            Settings=(@{country='W1';testType='IntegrationTest';numberOfTenantsForTesting=1;companyName='My Company'
                enableCleanTestCodeunitExecution=$true;enableTaskScheduler=$false}|ConvertTo-Json)
        }
        foreach($envKey in $values.Keys){$script:saved[$envKey]=[Environment]::GetEnvironmentVariable($envKey);[Environment]::SetEnvironmentVariable($envKey,$values[$envKey])}
        $script:parameters=@{
            ContainerName='bcbuildprojectsTestAppsW1Trial1t1123';memoryLimit='16G';multitenant=$true
            platformArtifactUrl='https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/30.0.55665.0/platform'
        }
        Mock Test-BcContainer {$false}
        Mock Get-Module { { '6.1.19-preview2811389' } } -ParameterFilter {$Name -eq 'BcContainerHelper'}
    }
    AfterEach {foreach($envKey in $script:saved.Keys){[Environment]::SetEnvironmentVariable($envKey,$script:saved[$envKey])}}
    It 'records exact requested count <count>, workers and 16G without modifying auth' -ForEach @(@{count=1},@{count=2}) {
        $env:BC_SQL_TENANT_COUNT=[string]$count
        $settings=$env:Settings|ConvertFrom-Json
        $settings.numberOfTenantsForTesting=$count
        $env:Settings=$settings|ConvertTo-Json
        $script:parameters.ContainerName="bcbuildprojectsTestAppsW1Trial1t${count}123"
        & (Join-Path $PSScriptRoot 'TenantContainerPreflight.ps1') -Parameters $script:parameters
        $proof=Get-Content (Join-Path $TestDrive 'container-ownership.json') -Raw|ConvertFrom-Json
        $proof.tenantCount | Should -Be $count
        $proof.intendedWorkers | Should -Be $count
        $proof.memoryLimit | Should -Be '16G'
        $proof.multitenant | Should -BeTrue
        $proof.image | Should -Be 'mcr.microsoft.com/businesscentral@sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492'
    }
    It 'refuses preexisting owned name instead of replacing it' {
        Mock Test-BcContainer {$true}
        {& (Join-Path $PSScriptRoot 'TenantContainerPreflight.ps1') -Parameters $script:parameters}|Should -Throw '*already exists*'
    }
    It 'rejects count fallback or changed memory or single-tenant NST mode' {
        $env:BC_SQL_TENANT_COUNT='2'
        $script:parameters.ContainerName='bcbuildprojectsTestAppsW1Trial1t2123'
        {& (Join-Path $PSScriptRoot 'TenantContainerPreflight.ps1') -Parameters $script:parameters}|Should -Throw '*settings differ*'
        $env:BC_SQL_TENANT_COUNT='1';$script:parameters.ContainerName='bcbuildprojectsTestAppsW1Trial1t1123'
        $script:parameters.memoryLimit='32G'
        {& (Join-Path $PSScriptRoot 'TenantContainerPreflight.ps1') -Parameters $script:parameters}|Should -Throw '*settings differ*'
        $script:parameters.memoryLimit='16G';$script:parameters.multitenant=$false
        {& (Join-Path $PSScriptRoot 'TenantContainerPreflight.ps1') -Parameters $script:parameters}|Should -Throw '*settings differ*'
    }
}
