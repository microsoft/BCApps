function global:Test-BcContainer { param($containerName) throw 'Live container call forbidden.' }
function global:Get-BcContainerEventLog { param($containerName, [switch]$doNotOpen) throw 'Live container call forbidden.' }
function global:Remove-BcContainer { param($containerName) throw 'Live container call forbidden.' }

Describe 'SQL pilot final cleanup ownership' {
    BeforeEach {
        $script:oldWorkspace = $env:GITHUB_WORKSPACE
        $script:oldRun = $env:GITHUB_RUN_ID
        $script:oldArm = $env:BC_SQL_PILOT_ARM
        $script:oldHelper = $env:BcContainerHelperPath
        $env:GITHUB_WORKSPACE = $PSScriptRoot
        $env:GITHUB_RUN_ID = '123'
        $env:BC_SQL_PILOT_ARM = 'fresh'
        $env:BcContainerHelperPath = Join-Path $PSScriptRoot 'BcContainerHelper.ps1'
        Mock Import-Module {}
        Mock Test-Path { $true }
        Mock Get-Content { '{"runId":"123","arm":"fresh","container":"bcbuildprojectsTestAppsW1123"}' }
        Mock Get-ChildItem {}
        Mock Copy-Item {}
        Mock Set-Content {}
        $global:sqlPilotTestContainerExists = $true
        Mock Test-BcContainer { $global:sqlPilotTestContainerExists }
        Mock Get-BcContainerEventLog { 'events.evtx' }
        Mock Remove-BcContainer { $global:sqlPilotTestContainerExists = $false }
    }
    AfterEach {
        $env:GITHUB_WORKSPACE = $script:oldWorkspace
        $env:GITHUB_RUN_ID = $script:oldRun
        $env:BC_SQL_PILOT_ARM = $script:oldArm
        $env:BcContainerHelperPath = $script:oldHelper
        Remove-Variable sqlPilotTestContainerExists -Scope Global
    }
    It 'exports before disposing only the registered container' {
        & (Join-Path $PSScriptRoot 'Finalize.ps1')
        Assert-MockCalled Get-BcContainerEventLog -Times 1 -Exactly -Scope It
        Assert-MockCalled Remove-BcContainer -Times 1 -Exactly -Scope It -ParameterFilter { $containerName -eq 'bcbuildprojectsTestAppsW1123' }
    }
    It 'still tears down if exporting fails and keeps that failure visible' {
        Mock Get-BcContainerEventLog { throw 'event export failed' }
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw
        Assert-MockCalled Remove-BcContainer -Times 1 -Exactly -Scope It
    }
    It 'refuses deletion if ownership was not recorded' {
        Mock Test-Path { $false }
        & (Join-Path $PSScriptRoot 'Finalize.ps1')
        Assert-MockCalled Remove-BcContainer -Times 0 -Exactly -Scope It
    }
    It 'refuses deletion when run, arm or exact name differs' {
        Mock Get-Content { '{"runId":"999","arm":"fresh","container":"shared"}' }
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw
        Assert-MockCalled Remove-BcContainer -Times 0 -Exactly -Scope It
    }
}
