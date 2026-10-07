BeforeAll {
    function global:Test-BcContainer { param($containerName) $null = $containerName; throw 'Live call forbidden.' }
    function global:New-BcContainer { param($useGenericImage) $null = $useGenericImage; throw 'Live call forbidden.' }
}
Describe 'Experiment country and trial container ownership' {
    BeforeEach {
        $script:saved = @{}
        foreach ($name in @('GITHUB_REF','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT','GITHUB_RUN_ID',
            'BC_SQL_PILOT_ARM','BC_SQL_PILOT_COUNTRY','BC_SQL_PILOT_TRIAL','BC_SQL_PILOT_OUTPUT','Settings')) {
            $script:saved[$name] = [Environment]::GetEnvironmentVariable($name)
        }
        $env:GITHUB_REF = 'refs/heads/features/646383-sql-api-warmup-experiment'
        $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
        $env:GITHUB_RUN_ATTEMPT = '1'
        $env:GITHUB_RUN_ID = '123'
        $env:BC_SQL_PILOT_ARM = 'control'
        $env:BC_SQL_PILOT_COUNTRY = 'DE'
        $env:BC_SQL_PILOT_TRIAL = '2'
        $env:BC_SQL_PILOT_OUTPUT = $TestDrive
        $env:Settings = @{
            country = 'DE'; testType = 'IntegrationTest'; numberOfTenantsForTesting = 4
            companyName = 'My Company'; enableCleanTestCodeunitExecution = $true; enableTaskScheduler = $false
        } | ConvertTo-Json
        $script:parameters = @{
            ContainerName = 'bcbuildprojectsTestAppsDETrial2123'
            platformArtifactUrl = 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/30.0.55665.0/platform'
        }
        Mock Get-Module { { '6.1.19-preview2811389' } } -ParameterFilter { $Name -eq 'BcContainerHelper' }
        Mock Test-BcContainer { $false }
    }
    AfterEach {
        foreach ($name in $script:saved.Keys) { [Environment]::SetEnvironmentVariable($name, $script:saved[$name]) }
    }
    It 'pins image and registers the exact country-trial-run container' {
        & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters
        $record = Get-Content (Join-Path $TestDrive 'container-ownership.json') -Raw | ConvertFrom-Json
        $record.country | Should -Be 'DE'
        $record.trial | Should -Be '2'
        $record.container | Should -Be 'bcbuildprojectsTestAppsDETrial2123'
        $script:parameters.useGenericImage | Should -Be 'mcr.microsoft.com/businesscentral@sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492'
    }
    It 'refuses a preexisting container rather than replacing it' {
        Mock Test-BcContainer { $true }
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw '*already exists*'
    }
    It 'rejects original non-trial container names' {
        $script:parameters.ContainerName = 'bcbuildprojectsTestAppsDE123'
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw
    }
    It 'rejects another trial or country mapping' {
        $env:BC_SQL_PILOT_TRIAL = '3'
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw
        $env:BC_SQL_PILOT_TRIAL = '2'
        $env:BC_SQL_PILOT_COUNTRY = 'W1'
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw
    }
    It 'rejects reruns and fresh-name treatment' {
        $env:GITHUB_RUN_ATTEMPT = '2'
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw
        $env:GITHUB_RUN_ATTEMPT = '1'
        $env:BC_SQL_PILOT_ARM = 'fresh'
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw
    }
    It 'rejects effective country drift' {
        $settings = $env:Settings | ConvertFrom-Json
        $settings.country = 'W1'
        $env:Settings = $settings | ConvertTo-Json
        { & (Join-Path $PSScriptRoot 'ContainerPreflight.ps1') -Parameters $script:parameters } | Should -Throw '*settings differ*'
    }
}
