function global:Test-BcContainer { param($containerName) throw 'Live container call forbidden.' }
function global:Get-BcContainerEventLog { param($containerName, [switch]$doNotOpen) throw 'Live container call forbidden.' }
function global:Remove-BcContainer { param($containerName) throw 'Live container call forbidden.' }

Describe 'SQL pilot final cleanup ownership' {
    BeforeEach {
        $script:oldWorkspace = $env:GITHUB_WORKSPACE
        $script:oldRun = $env:GITHUB_RUN_ID
        $script:oldArm = $env:BC_SQL_PILOT_ARM
        $script:oldHelper = $env:BcContainerHelperPath
        $script:oldCountry = $env:BC_SQL_PILOT_COUNTRY
        $script:oldTrial = $env:BC_SQL_PILOT_TRIAL
        $script:oldExperiment = $env:BC_SQL_API_EXPERIMENT
        $env:GITHUB_WORKSPACE = $PSScriptRoot
        $env:GITHUB_RUN_ID = '123'
        $env:BC_SQL_PILOT_ARM = 'control'
        $env:BC_SQL_PILOT_COUNTRY = 'DE'
        $env:BC_SQL_PILOT_TRIAL = '2'
        $env:BC_SQL_API_EXPERIMENT = 'retry'
        $env:BcContainerHelperPath = Join-Path $PSScriptRoot 'BcContainerHelper.ps1'
        Mock Import-Module {}
        Mock Test-Path { $true }
        Mock Get-Content { '{"runId":"123","arm":"control","country":"DE","trial":"2","experiment":"retry","container":"bcbuildprojectsTestAppsDETrial2retry123"}' }
        Mock Get-ChildItem {}
        Mock New-Item {}
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
        $env:BC_SQL_PILOT_COUNTRY = $script:oldCountry
        $env:BC_SQL_PILOT_TRIAL = $script:oldTrial
        $env:BC_SQL_API_EXPERIMENT = $script:oldExperiment
        Remove-Variable sqlPilotTestContainerExists -Scope Global
    }
    It 'exports before disposing only the registered container' {
        & (Join-Path $PSScriptRoot 'Finalize.ps1')
        Should -Invoke Get-BcContainerEventLog -Times 1 -Exactly -Scope It
        Should -Invoke Remove-BcContainer -Times 1 -Exactly -Scope It -ParameterFilter { $containerName -eq 'bcbuildprojectsTestAppsDETrial2retry123' }
    }
    It 'still tears down if exporting fails and keeps that failure visible' {
        Mock Get-BcContainerEventLog { throw 'event export failed' }
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw
        Should -Invoke Remove-BcContainer -Times 1 -Exactly -Scope It
    }
    It 'collects root and nested runner results separately from warmup' {
        Mock Get-ChildItem { [PSCustomObject]@{ FullName = 'TestResults.xml' } }
        & (Join-Path $PSScriptRoot 'Finalize.ps1')
        Should -Invoke Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter {
            $Path -like '*Test Apps DE Trial2retry\.buildartifacts' -and $Filter -eq 'TestResults*.xml' -and $File
        }
        Should -Invoke Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter {
            $Destination -like '*clean-results\buildartifacts'
        }
        Should -Invoke Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter {
            $Destination -like '*clean-results\project-root'
        }
        Should -Invoke Copy-Item -Times 0 -Exactly -Scope It -ParameterFilter {
            $Destination -like '*sql-reset-pilot-output\warmup*'
        }
    }
    It 'does not fail cleanup when nested runner results are absent' {
        Mock Test-Path { $false } -ParameterFilter { $Path -like '*\.buildartifacts' }
        & (Join-Path $PSScriptRoot 'Finalize.ps1')
        Should -Invoke Get-ChildItem -Times 0 -Exactly -Scope It -ParameterFilter {
            $Path -like '*\.buildartifacts'
        }
        Should -Invoke Remove-BcContainer -Times 1 -Exactly -Scope It
    }
    It 'refuses deletion if ownership was not recorded' {
        Mock Test-Path { $false }
        & (Join-Path $PSScriptRoot 'Finalize.ps1')
        Should -Invoke Remove-BcContainer -Times 0 -Exactly -Scope It
    }
    It 'refuses deletion when run, arm or exact name differs' {
        Mock Get-Content { '{"runId":"999","arm":"fresh","container":"shared"}' }
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw
        Should -Invoke Remove-BcContainer -Times 0 -Exactly -Scope It
    }
    It 'refuses deletion of another trial in the same country and run' {
        $env:BC_SQL_PILOT_TRIAL = '3'
        { & (Join-Path $PSScriptRoot 'Finalize.ps1') } | Should -Throw
        Should -Invoke Remove-BcContainer -Times 0 -Exactly -Scope It
    }
}
