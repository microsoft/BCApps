BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Producer.psm1') -Force
    & (Get-Module Producer) {
        function script:Get-TestsFromBcContainer {
            param($containerName, $tenant, $companyName, [PSCredential]$credential, $testSuite, $extensionId,
                $testCodeunit, $testType, $requiredTestIsolation, $disabledTests)
            throw "Unmocked discovery: $($PSBoundParameters.Keys -join ',')"
        }
        function script:Run-TestsInBcContainer {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '',
                Justification = 'Stub retains the exact external BCH command name.')]
            [CmdletBinding()]
            param($containerName, $tenant, $companyName, [PSCredential]$credential, $testSuite, $extensionId,
                $testCodeunit, $testType, $requiredTestIsolation, $disabledTests, $ReRun,
                $restartContainerAndRetry, $JUnitResultFileName, $testRunnerCodeunitId)
            throw "Unmocked test execution: $($PSBoundParameters.Keys -join ',')"
        }
    }
}

Describe 'Compiled discovery drives normal versus disabled execution' {
    BeforeAll {
        $script:fixture = Join-Path $PSScriptRoot ".producer-$([guid]::NewGuid().ToString('N'))"
        $null = New-Item -ItemType Directory -Path $fixture
    }
    AfterAll { Remove-Item $fixture -Recurse -Force }
    BeforeEach {
        $script:context = @{
            output = $fixture; cell = @{ country = 'W1' }
            lane = @{ id = 'Default'; settings = @{ testType = 'UnitTest' }; routes = @(
                @{ appId = 'app'; appName = 'Fixture'; codeunit = 100; sourceRequiredTestIsolation = 'unspecified' },
                @{ appId = 'app'; appName = 'Fixture'; codeunit = 101; sourceRequiredTestIsolation = 'Disabled' }
            ) }
        }
        Mock Get-ExpandedDisabledTest -ModuleName Producer { @(@{ codeunitName = 'Normal'; method = 'ExistingSkip' }) }
        Mock Get-TestsFromBcContainer -ModuleName Producer {
            if ($requiredTestIsolation -eq 'Disabled') {
                return [pscustomobject]@{ Id = '101'; Name = 'Disabled'; Tests = @('DisabledTest') }
            }
            $names = if (@($disabledTests).Count) { @('NormalTest') } else { @('NormalTest', 'ExistingSkip') }
            $normal = [pscustomobject]@{ Id = '100'; Name = 'Normal'; Tests = $names }
            if (-not $testType) {
                return @($normal, [pscustomobject]@{ Id = '101'; Name = 'Disabled'; Tests = @('DisabledTest') })
            }
            return $normal
        }
    }
    It 'uses the compiled None/Codeunit partition for130450 and Disabled for130451' {
        $items = @(Get-ExpandedWorkItem -Parameters @{ containerName = 'owned' } -Context $context)
        $items.Count | Should -Be 2
        $items[0].runner | Should -Be '130450'
        $items[1].runner | Should -Be '130451'
        $items[0].cases[1].skipped | Should -BeTrue
        $items[0].cases[0].skipped | Should -BeFalse
        Should -Invoke Get-TestsFromBcContainer -ModuleName Producer -Times 4 -Exactly
    }
    It 'loads Legacy untyped and verifies that no codeunit/method vanished in typed runner classification' {
        $context.lane.id = 'LegacyTestsBucket1'
        $context.lane.settings.testType = 'Legacy'
        $items = @(Get-ExpandedWorkItem -Parameters @{ containerName = 'owned' } -Context $context)
        $items.Count | Should -Be 2
        $items[0].testType | Should -Be 'Legacy'
        Should -Invoke Get-TestsFromBcContainer -ModuleName Producer -Times 1 -Exactly -ParameterFilter {
            -not $testType -and -not $requiredTestIsolation
        }
    }
    It 'rejects a missing compiled selector rather than dropping a codeunit' {
        Mock Get-TestsFromBcContainer -ModuleName Producer { @() }
        { Get-ExpandedWorkItem -Parameters @{} -Context $context } | Should -Throw '*omitted*'
    }
    It 'rejects typed Legacy truncation relative to explicit untyped discovery' {
        $context.lane.settings.testType = 'Legacy'
        Mock Get-TestsFromBcContainer -ModuleName Producer {
            if (-not $testType) { return [pscustomobject]@{ Id = '100'; Name = 'Normal'; Tests = @('NormalTest', 'ExistingSkip', 'Missing') } }
            if ($requiredTestIsolation -eq 'Disabled') { return [pscustomobject]@{ Id = '101'; Name = 'Disabled'; Tests = @('DisabledTest') } }
            return [pscustomobject]@{ Id = '100'; Name = 'Normal'; Tests = @('NormalTest', 'ExistingSkip') }
        }
        { Get-ExpandedWorkItem -Parameters @{} -Context $context } | Should -Throw '*Untyped Legacy*'
    }
    It 'removes all inherited rerun, filter and runner state' {
        $p = Get-ExpandedCommandParameter -Parameters @{
            containerName = 'owned'; tenant = 'tenant4'; ReRun = $true; restartContainerAndRetry = $true
            testCodeunit = 'old'; testType = 'IntegrationTest'; requiredTestIsolation = 'Disabled'
            testRunnerCodeunitId = '130451'; extensionId = 'old'; JUnitResultFileName = 'output.xml'
        } -Command Run-TestsInBcContainer
        $p.ContainsKey('ReRun') | Should -BeFalse
        $p.ContainsKey('restartContainerAndRetry') | Should -BeFalse
        $p.ContainsKey('requiredTestIsolation') | Should -BeFalse
        $p.ContainsKey('testRunnerCodeunitId') | Should -BeFalse
        $p.tenant | Should -Be default
    }
    It 'rejects a stale XML suite even with matching method names' {
        $path = Join-Path $fixture 'wrong.xml'
        Set-Content $path '<testsuites><testsuite name="999 Foreign"><testcase name="NormalTest"/></testsuite></testsuites>'
        { ConvertFrom-ExpandedJUnit -Path $path -Item @{codeunitId='100';appId='app'} -Context $context } | Should -Throw '*Foreign*'
    }
    It 'compares cohorts independent of process-specific JSON property order' {
        $a=[pscustomobject][ordered]@{country='W1';lane='Default';appId='app';codeunitId='100';method='First';skipped=$false;appName='App';codeunitName='CU';compiledIsolationSelector='None';runner='130450'}
        $b=[pscustomobject][ordered]@{runner='130450';compiledIsolationSelector='None';codeunitName='CU';appName='App';skipped=$false;method='First';codeunitId='100';appId='app';lane='Default';country='W1'}
        (Get-ExpandedCohortSignature -Cases @($a)) | Should -Be (Get-ExpandedCohortSignature -Cases @($b))
        $b.skipped=$true
        (Get-ExpandedCohortSignature -Cases @($a)) | Should -Not -Be (Get-ExpandedCohortSignature -Cases @($b))
    }
}

Describe 'Matched baseline protected lifecycle' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot 'Lifecycle.psm1') -Force
        & (Get-Module Lifecycle) {
            function script:Invoke-ScriptInBcContainer { param($containerName, $useSession, $scriptblock, $argumentList)
                throw "Unmocked container operation $($PSBoundParameters.Keys -join ',')" }
        }
        $script:lifecycleFixture = Join-Path $PSScriptRoot ".lifecycle-$([guid]::NewGuid().ToString('N'))"
        $null = New-Item -ItemType Directory -Path $lifecycleFixture
        $script:saved = @{}
        foreach ($key in @('GITHUB_RUN_ID', 'BC_SQL_TENANT_COUNT', 'BC_EXPANDED_PHASE')) {
            $saved[$key] = [Environment]::GetEnvironmentVariable($key)
        }
    }
    AfterAll {
        foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
        Remove-Item $lifecycleFixture -Recurse -Force
    }
    BeforeEach {
        Mock Test-SqlTenantExperiment -ModuleName Lifecycle { $true }
        Mock Get-SqlTenantContainerName -ModuleName Lifecycle { 'owned' }
        Mock Invoke-ScriptInBcContainer -ModuleName Lifecycle { '11111111-1111-1111-1111-111111111111' }
        $env:GITHUB_RUN_ID = '999'
    }
    It 'supports exact1/2/4 mounts and freezes the same detached template' -ForEach @(1, 2, 4) {
        $env:BC_SQL_TENANT_COUNT = [string]$_
        $info = @(@{Id='default';DatabaseName='default'}) + @(2..4 | Where-Object { $_ -le [int]$env:BC_SQL_TENANT_COUNT } | ForEach-Object { @{Id="tenant$_";DatabaseName="tenant$_"} })
        Initialize-SqlResetPilot -ContainerName owned -TenantInfo $info -Arm control -RunId 999 -OutputDirectory $lifecycleFixture -TenantCount ([int]$_)
        Protect-SqlPilotTemplate -ContainerName owned -TemplateDatabaseName default-test-template
        $env:BC_EXPANDED_PHASE = 'discovery'
        $reset = Get-SqlResetPlan -ContainerName owned -Tenant default -DatabaseName default -TemplateDatabaseName default-test-template
        $reset.TenantCount | Should -Be ([int]$_)
        $reset.TemplateIdentity | Should -Be '11111111-1111-1111-1111-111111111111'
    }
    It 'reserves default after discovery only for the four-mount baseline' {
        $env:BC_SQL_TENANT_COUNT = '4'
        $info = @(@{Id='default';DatabaseName='default'}) + @(2..4 | ForEach-Object { @{Id="tenant$_";DatabaseName="tenant$_"} })
        Initialize-SqlResetPilot -ContainerName owned -TenantInfo $info -Arm control -RunId 999 -OutputDirectory $lifecycleFixture -TenantCount 4
        Protect-SqlPilotTemplate -ContainerName owned -TemplateDatabaseName default-test-template
        $env:BC_EXPANDED_PHASE = 'execution'
        { Get-SqlResetPlan -ContainerName owned -Tenant default -DatabaseName default -TemplateDatabaseName default-test-template } | Should -Throw '*reserves default*'
        (Get-SqlResetPlan -ContainerName owned -Tenant tenant4 -DatabaseName tenant4 -TemplateDatabaseName default-test-template).Destination | Should -Be tenant4
        { Get-SqlResetPlan -ContainerName foreign -Tenant tenant4 -DatabaseName tenant4 -TemplateDatabaseName default-test-template } | Should -Throw '*Unowned*'
    }
}
