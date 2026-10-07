Import-Module (Join-Path $PSScriptRoot 'TenantCount.psm1') -Force
BeforeAll {
    function global:Test-BcContainer {param($containerName) throw 'Live call forbidden.'}
    function global:Get-BcContainerEventLog {param($containerName,[switch]$doNotOpen) throw 'Live call forbidden.'}
    function global:Remove-BcContainer {param($containerName) throw 'Live call forbidden.'}
}
Describe 'Tenant-count finalization ownership' {
    BeforeEach {
        $script:saved=@{}
        $values=@{
            GITHUB_REPOSITORY='microsoft/BCApps';GITHUB_REF='refs/heads/features/646383-sql-api-tenant-count-comparison'
            GITHUB_EVENT_NAME='workflow_dispatch';GITHUB_RUN_ATTEMPT='1';GITHUB_RUN_ID='123'
            BC_SQL_PILOT_ARM='control';BC_SQL_API_EXPERIMENT='control';BC_SQL_TENANT_COUNT='1'
            BC_SQL_PILOT_COUNTRY='W1';BC_SQL_PILOT_TRIAL='1';GITHUB_WORKSPACE=$TestDrive
            BcContainerHelperPath=(Join-Path $TestDrive 'BcContainerHelper.ps1')
        }
        foreach($envKey in $values.Keys){$script:saved[$envKey]=[Environment]::GetEnvironmentVariable($envKey);[Environment]::SetEnvironmentVariable($envKey,$values[$envKey])}
        Mock Import-Module {}
        Mock Test-Path {$true}
        Mock Get-Content {
            @{runId='123';arm='control';experiment='control';tenantCount=[int]$env:BC_SQL_TENANT_COUNT
              country='W1';trial='1';container="bcbuildprojectsTestAppsW1Trial1t$($env:BC_SQL_TENANT_COUNT)123"}|ConvertTo-Json
        }
        Mock Get-ChildItem {}
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Set-Content {}
        $global:sqlTenantFinalizeTestExists=$true
        Mock Test-BcContainer {$global:sqlTenantFinalizeTestExists}
        Mock Get-BcContainerEventLog {'events.evtx'}
        Mock Remove-BcContainer {$global:sqlTenantFinalizeTestExists=$false}
    }
    AfterEach {
        foreach($envKey in $script:saved.Keys){[Environment]::SetEnvironmentVariable($envKey,$script:saved[$envKey])}
        Remove-Variable sqlTenantFinalizeTestExists -Scope Global
    }
    It 'removes only exact owned count <count> and preserves both result locations' -ForEach @(@{count=1},@{count=2}) {
        $env:BC_SQL_TENANT_COUNT=[string]$count
        & (Join-Path $PSScriptRoot 'TenantFinalize.ps1')
        Should -Invoke Remove-BcContainer -Times 1 -Exactly -ParameterFilter {$containerName -eq "bcbuildprojectsTestAppsW1Trial1t$($env:BC_SQL_TENANT_COUNT)123"}
        Should -Invoke Get-ChildItem -Times 2 -Exactly
    }
    It 'still removes owned container when exporting diagnostics fails' {
        Mock Get-BcContainerEventLog {throw 'export failure'}
        {& (Join-Path $PSScriptRoot 'TenantFinalize.ps1')} | Should -Throw '*export failure*'
        Should -Invoke Remove-BcContainer -Times 1 -Exactly
    }
    It 'never removes another count or a missing ownership record' {
        Mock Get-Content {'{"tenantCount":2}'}
        {& (Join-Path $PSScriptRoot 'TenantFinalize.ps1')} | Should -Throw '*identity mismatch*'
        Mock Test-Path {$false}
        & (Join-Path $PSScriptRoot 'TenantFinalize.ps1')
        Should -Invoke Remove-BcContainer -Times 0 -Exactly
    }
    It 'reports teardown failure rather than claiming success' {
        Mock Remove-BcContainer {}
        {& (Join-Path $PSScriptRoot 'TenantFinalize.ps1')} | Should -Throw '*teardown did not complete*'
    }
}
