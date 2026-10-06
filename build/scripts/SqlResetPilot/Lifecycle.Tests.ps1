Import-Module (Join-Path $PSScriptRoot 'Lifecycle.psm1') -Force
function global:Invoke-ScriptInBcContainer {
    param($containerName, $useSession, $scriptblock, $argumentList)
    throw 'No live container calls are permitted in unit tests.'
}

Describe 'SQL reset pilot ownership and mapping' {
    BeforeEach {
        $script:tenants = @('default','tenant2','tenant3','tenant4') | ForEach-Object {
            [PSCustomObject]@{ Id = $_; DatabaseName = $_ }
        }
        Initialize-SqlResetPilot 'owned' $script:tenants 'fresh' '123456789' $PSScriptRoot
    }
    It 'uses a fresh database target and updates the original caller mapping for the next cycle' {
        $first = Get-SqlResetPlan 'owned' 'tenant2' 'tenant2' 'default'
        $first.Destination | Should -Be 'tenant2_r123456789_g1'
        Complete-SqlResetPlan $first
        $script:tenants[1].DatabaseName | Should -Be $first.Destination
        $second = Get-SqlResetPlan 'owned' 'tenant2' $script:tenants[1].DatabaseName 'default-test-template'
        $second.Previous | Should -Be $first.Destination
        $second.Destination | Should -Be 'tenant2_r123456789_g2'
    }
    It 'retains the original SQL target in control while increasing its observation label' {
        Initialize-SqlResetPilot 'owned' $script:tenants 'control' '123456789' $PSScriptRoot
        $first = Get-SqlResetPlan 'owned' 'tenant3' 'tenant3' 'default-test-template'
        Complete-SqlResetPlan $first
        $second = Get-SqlResetPlan 'owned' 'tenant3' 'tenant3' 'default-test-template'
        $second.Destination | Should -Be 'tenant3'
        $second.Generation | Should -Be 2
    }
    It 'rejects stale mappings after a successful rename' {
        Complete-SqlResetPlan (Get-SqlResetPlan 'owned' 'tenant2' 'tenant2' 'default')
        { Get-SqlResetPlan 'owned' 'tenant2' 'tenant2' 'default' } | Should -Throw
    }
    It 'never accepts the primary or template as a deletion target' {
        { Get-SqlResetPlan 'owned' 'default' 'default' 'default-test-template' } | Should -Throw
        { Get-SqlResetPlan 'owned' 'tenant2' 'default-test-template' 'default' } | Should -Throw
        { Get-SqlResetPlan 'owned' 'tenant2' 'app' 'default' } | Should -Throw
    }
    It 'rejects unowned containers, workers and source databases' {
        { Get-SqlResetPlan 'shared' 'tenant2' 'tenant2' 'default' } | Should -Throw
        { Get-SqlResetPlan 'owned' 'tenant5' 'tenant5' 'default' } | Should -Throw
        { Get-SqlResetPlan 'owned' 'tenant2' 'tenant2' 'shared' } | Should -Throw
    }
    It 'rejects unsafe run identities and unexpected original mappings' {
        { Initialize-SqlResetPilot 'owned' $script:tenants 'fresh' '1;drop' $PSScriptRoot } | Should -Throw
        $script:tenants[1].DatabaseName = 'default'
        { Initialize-SqlResetPilot 'owned' $script:tenants 'fresh' '123' $PSScriptRoot } | Should -Throw
    }
    It 'preserves the seven original three-worker batches and stops after the target batch' {
        $ids = @(139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343,148344)
        $items = @($ids | ForEach-Object { [PSCustomObject]@{ CodeunitId = $_ } })
        $prefix = @(Select-SqlPilotPrefix $items)
        $prefix.Count | Should -Be 21
        $prefix[18].CodeunitId | Should -Be 148315
        $prefix[20].CodeunitId | Should -Be 148343
        $items[0].CodeunitId = 1
        { Select-SqlPilotPrefix $items } | Should -Throw
    }
    It 'advances mapping only after the container operation succeeds' {
        Mock Invoke-ScriptInBcContainer -ModuleName Lifecycle { @{ state = 'Operational' } }
        Mock Add-Content -ModuleName Lifecycle {}
        Invoke-SqlPilotReset 'owned' 'tenant2' 'tenant2' 'default'
        $script:tenants[1].DatabaseName | Should -Be 'tenant2_r123456789_g1'
        Assert-MockCalled Invoke-ScriptInBcContainer -ModuleName Lifecycle -Times 1 -Exactly -Scope It -ParameterFilter {
            $containerName -eq 'owned' -and $argumentList.Previous -eq 'tenant2' -and
            $argumentList.Destination -eq 'tenant2_r123456789_g1'
        }
    }
    It 'leaves mapping unchanged and propagates a failed restore without retrying' {
        Mock Invoke-ScriptInBcContainer -ModuleName Lifecycle { throw 'copy failed' }
        Mock Add-Content -ModuleName Lifecycle {}
        { Invoke-SqlPilotReset 'owned' 'tenant2' 'tenant2' 'default' } | Should -Throw
        $script:tenants[1].DatabaseName | Should -Be 'tenant2'
        Assert-MockCalled Invoke-ScriptInBcContainer -ModuleName Lifecycle -Times 1 -Exactly -Scope It
    }
}
