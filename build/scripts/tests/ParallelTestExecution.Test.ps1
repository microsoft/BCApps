$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

if (-not (Get-Command Get-TestsFromBcContainer -ErrorAction SilentlyContinue)) {
    function global:Get-TestsFromBcContainer {
        param(
            [string]$containerName,
            [string]$tenant,
            [string]$extensionId,
            [string]$requiredTestIsolation,
            [string]$testType,
            [array]$disabledTests
        )
        $null = $containerName, $tenant, $extensionId, $requiredTestIsolation, $testType, $disabledTests
        throw "Get-TestsFromBcContainer stub should never be called; a Pester mock must intercept it."
    }
}

if (-not (Get-Command Invoke-ScriptInBcContainer -ErrorAction SilentlyContinue)) {
    function global:Invoke-ScriptInBcContainer {
        param(
            [string]$containerName,
            [scriptblock]$scriptblock,
            [object[]]$argumentList,
            [bool]$useSession
        )
        $null = $containerName, $scriptblock, $argumentList, $useSession
        throw "Invoke-ScriptInBcContainer stub should never be called; a Pester mock must intercept it."
    }
}

Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force

Describe "ParallelTestExecution app-name resolution" {
    BeforeEach {
        Mock -ModuleName ParallelTestExecution Get-ALGoSetting { $true } -ParameterFilter {
            $Key -eq 'enableCleanTestCodeunitExecution'
        }
    }
    BeforeAll {
        # Get-BcContainerAppInfo comes from BcContainerHelper, which is present when the module
        # runs inside a BC container but is NOT loaded in the "Run PS Tests" runner. Pester cannot
        # mock a command that does not exist, so define a no-op stub (guarded so we never shadow the
        # real cmdlet) declaring the parameters the module passes, letting the mock bind correctly.
        $script:createdBcContainerAppInfoStub = $false
        if (-not (Get-Command Get-BcContainerAppInfo -ErrorAction SilentlyContinue)) {
            function global:Get-BcContainerAppInfo {
                param(
                    [string]$containerName,
                    [string]$tenant,
                    [switch]$tenantSpecificProperties
                )
                # The parameters exist only so the stub matches the mocked BcContainerHelper cmdlet
                # signature; reference them so PSScriptAnalyzer does not flag them as unused.
                $null = $containerName, $tenant, $tenantSpecificProperties
                # This body must never run: it exists only so Pester can resolve and mock the
                # command. Every module call to it in these tests is intercepted by Pester's mock.
                throw "Get-BcContainerAppInfo stub should never be called; a Pester mock must intercept it."
            }
            $script:createdBcContainerAppInfoStub = $true
        }

        # Create real app.json files on disk so Get-AppNameFromMetadata can read them.
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("patest_" + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        function New-AppJson {
            param([string]$Folder, [string]$Name)
            $dir = Join-Path $script:tempRoot $Folder
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $path = Join-Path $dir 'app.json'
            @{ name = $Name; id = [System.Guid]::NewGuid().ToString() } | ConvertTo-Json | Set-Content -Path $path -Encoding utf8
            return $path
        }

        # A metadata record whose projects.json key (ApplicationName) differs from its app.json name.
        $script:mismatchAppJson = New-AppJson -Folder 'Mismatch' -Name 'Real App Name'
        # A metadata record whose key and app.json name agree.
        $script:matchAppJson = New-AppJson -Folder 'Match' -Name 'Aligned Tests'
    }

    AfterAll {
        if ($script:createdBcContainerAppInfoStub -and (Test-Path 'function:global:Get-BcContainerAppInfo')) {
            Remove-Item 'function:global:Get-BcContainerAppInfo' -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $script:tempRoot) { Remove-Item $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Context "Get-AppNameFromMetadata" {
        It "returns the app.json name when it differs from the projects.json key" {
            $md = [PSCustomObject]@{ ApplicationName = 'Projects-Json-Key'; AppJsonPath = $script:mismatchAppJson }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Real App Name'
        }

        It "returns the app.json name when it matches the projects.json key" {
            $md = [PSCustomObject]@{ ApplicationName = 'Aligned Tests'; AppJsonPath = $script:matchAppJson }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Aligned Tests'
        }

        It "falls back to ApplicationName when the app.json path is missing" {
            $md = [PSCustomObject]@{ ApplicationName = 'Fallback Name'; AppJsonPath = (Join-Path $script:tempRoot 'does-not-exist\app.json') }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Fallback Name'
        }

        It "falls back to ApplicationName when AppJsonPath is empty" {
            $md = [PSCustomObject]@{ ApplicationName = 'Fallback Name'; AppJsonPath = '' }
            Get-AppNameFromMetadata -BuildMetadata $md | Should -Be 'Fallback Name'
        }
    }

    Context "Get-InstalledTestAppNames resilience to key/name drift" {
        It "dispatches a test app whose projects.json key differs from its installed (app.json) name" {
            Mock -ModuleName ParallelTestExecution -CommandName Get-ApplicationGroup -MockWith {
                @(
                    [PSCustomObject]@{ IsTest = $true;  ApplicationName = 'Projects-Json-Key'; AppJsonPath = $script:mismatchAppJson }
                    [PSCustomObject]@{ IsTest = $true;  ApplicationName = 'Aligned Tests';     AppJsonPath = $script:matchAppJson }
                    [PSCustomObject]@{ IsTest = $false; ApplicationName = 'Some Prod App';     AppJsonPath = $null }
                )
            }
            Mock -ModuleName ParallelTestExecution -CommandName Get-BcContainerAppInfo -MockWith {
                @(
                    [PSCustomObject]@{ IsInstalled = $true; Name = 'Real App Name' }   # installed under the app.json name
                    [PSCustomObject]@{ IsInstalled = $true; Name = 'Aligned Tests' }
                )
            }

            $result = Get-InstalledTestAppNames -ContainerName 'c' -Tenant 'default' -Country 'w1'

            $result | Should -Contain 'Real App Name'
            $result | Should -Contain 'Aligned Tests'
            $result | Should -Not -Contain 'Projects-Json-Key'
        }
    }

    It "uses docker exec for the long-running template database copy" {
        InModuleScope ParallelTestExecution {
            Mock Invoke-ScriptInBcContainer { 'default-test-template' }

            New-BcTestTenantTemplate -ContainerName 'bc' -SourceDatabaseName 'default' | Should -Be 'default-test-template'

            Should -Invoke Invoke-ScriptInBcContainer -Times 1 -ParameterFilter {
                $containerName -eq 'bc' -and $useSession -eq $false
            }
        }
    }

    It "uses docker exec for long-running tenant database refreshes" {
        InModuleScope ParallelTestExecution {
            Mock Invoke-ScriptInBcContainer { }

            Reset-BcTestTenant -ContainerName 'bc' -Tenant 'tenant2' `
                -TenantDatabaseName 'tenant2' -TemplateDatabaseName 'default-test-template'

            Should -Invoke Invoke-ScriptInBcContainer -Times 1 -ParameterFilter {
                $containerName -eq 'bc' -and $useSession -eq $false
            }
        }
    }

    It "removes the clean template when normal app dispatch aborts" {
        InModuleScope ParallelTestExecution {
            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
            }
            Mock Get-RequiredDisabledWorkItems {
                @([PSCustomObject]@{
                    Key = 'Tests::500'
                    AppName = 'Tests'
                    AppId = 'tests-id'
                    CodeunitId = '500'
                    CodeunitName = 'API E2E'
                    TestCount = 2
                })
            }
            Mock New-BcTestTenantTemplate { 'default-test-template' }
            Mock Invoke-RequiredDisabledTestExecution { $true }
            Mock Reset-BcTestTenant { }
            Mock Invoke-WarmupDispatch { @($Pending) }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch { throw 'dispatch failed' }
            Mock Remove-BcTestTenantTemplate { }

            {
                Invoke-ParallelTestExecution -parameters @{
                    containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                    tenant = 'default'
                } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests')
            } | Should -Throw '*dispatch failed*'

            Should -Invoke Remove-BcTestTenantTemplate -Times 1 -ParameterFilter {
                $TemplateDatabaseName -eq 'default-test-template'
            }
        }
    }
}

Describe "Separate RunTests action override contract" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    BeforeEach {
        $script:savedSettings = $env:settings
        $env:settings = @'
{
  "testType": "IntegrationTest",
  "useSeparateTestAction": {
    "enabled": true,
    "testType": "IntegrationTest",
    "codeCoverageEnabled": true
  }
}
'@
    }

    AfterEach {
        $env:settings = $script:savedSettings
    }

    It "uses the test type supplied by the separate action when it matches the bucket" {
        InModuleScope ParallelTestExecution {
            Resolve-TestTypeForRun -Parameters @{ testType = "IntegrationTest" } | Should -Be "IntegrationTest"
        }
    }

    It "uses the merged bucket setting for the Run-AlPipeline compatibility path" {
        InModuleScope ParallelTestExecution {
            Resolve-TestTypeForRun -Parameters @{} | Should -Be "IntegrationTest"
        }
    }

    It "fails before dispatch when the action and bucket test types differ" {
        InModuleScope ParallelTestExecution {
            {
                Resolve-TestTypeForRun -Parameters @{ testType = "Uncategorized" }
            } | Should -Throw "*supplied testType 'Uncategorized'*configured as 'IntegrationTest'*"
        }
    }

    It "defaults the omitted separate-action tenant to default" {
        InModuleScope ParallelTestExecution {
            $parameters = @{}
            Initialize-TestActionParameters -Parameters $parameters
            $parameters.tenant | Should -Be "default"
        }
    }

    It "preserves an explicitly supplied tenant" {
        InModuleScope ParallelTestExecution {
            $parameters = @{ tenant = "tenant2" }
            Initialize-TestActionParameters -Parameters $parameters
            $parameters.tenant | Should -Be "tenant2"
        }
    }

    It "uses only the historical single-parameter override contract" {
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
        $projectOverrides = @(
            Get-ChildItem (Join-Path $repositoryRoot "build\projects") `
                -Filter "RunTestsInBcContainer.ps1" -Recurse -File
        )

        $projectOverrides.Count | Should -BeGreaterThan 0
        foreach ($override in $projectOverrides) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $override.FullName,
                [ref]$tokens,
                [ref]$errors
            )
            @($errors).Count | Should -Be 0
            @($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) |
                Should -Be @("parameters")
        }
        @(
            Get-ChildItem (Join-Path $repositoryRoot "build\projects") `
                -Filter "RunTestsInBcContainerV2.ps1" -Recurse -File
        ).Count | Should -Be 0
    }

    It "routes coverage parameters directly to the per-app coverage adapter" {
        InModuleScope ParallelTestExecution {
            $parameters = @{
                containerName = "test"
                tenant = "default"
                appName = "Tests"
                codeCoverageOutputPath = "coverage"
            }

            Mock Invoke-BcAppsCoverageAwareTestRun {
                $Parameters.containerName | Should -Be "test"
                $Parameters.codeCoverageOutputPath | Should -Be "coverage"
                $true
            }
            Mock Get-CachedTestRunResult {
                throw "Coverage-aware per-app calls must bypass the scheduler cache."
            }
            Mock Get-InstalledTestAppNames {
                throw "Coverage-aware per-app calls must bypass bucket discovery."
            }

            Invoke-PerProjectTestRun -parameters $parameters | Should -BeTrue

            Should -Invoke Invoke-BcAppsCoverageAwareTestRun -Times 1 -Exactly
            Should -Invoke Get-CachedTestRunResult -Times 0
            Should -Invoke Get-InstalledTestAppNames -Times 0
        }
    }

    It "removes stray coverage keys before using the historical path" {
        InModuleScope ParallelTestExecution {
            $parameters = @{
                containerName = "coverage-disabled"
                appName = "Tests"
                codeCoverageMode = "line"
                codeCoverageFormats = @("bc-json")
            }

            $historical = Get-BcAppsHistoricalTestParameters -Parameters $parameters

            $historical.ContainsKey("codeCoverageMode") | Should -BeFalse
            $historical.ContainsKey("codeCoverageFormats") | Should -BeFalse
            $historical.containerName | Should -Be "coverage-disabled"
            $historical.appName | Should -Be "Tests"
            $parameters.ContainsKey("codeCoverageMode") | Should -BeTrue
            $parameters.ContainsKey("codeCoverageFormats") | Should -BeTrue
        }
    }

    It "preserves the exact historical parameter object when coverage keys are absent" {
        InModuleScope ParallelTestExecution {
            $parameters = @{
                containerName = "coverage-disabled"
                appName = "Tests"
            }

            $historical = Get-BcAppsHistoricalTestParameters -Parameters $parameters

            [object]::ReferenceEquals($historical, $parameters) | Should -BeTrue
        }
    }
}

Describe "RunTestsInBcContainer BCH parameter forwarding" {
    BeforeAll {
        $script:runTestsScript = (Resolve-Path (Join-Path $PSScriptRoot '../RunTestsInBcContainer.ps1')).Path
        Import-Module (Join-Path $PSScriptRoot '../AlToolCoverageAdapter.psm1') -Force
        Import-Module (Join-Path $PSScriptRoot '../TestTolerance/TestTolerance.psm1') -Force
        $script:savedGitHubEventName = $env:GITHUB_EVENT_NAME
        function Run-TestsInBcContainer {
            param(
                [string]$appName,
                [string]$tenant,
                [string]$testType,
                [array]$disabledTests,
                [bool]$renewClientContextBetweenTests
            )
            $null = $appName, $tenant, $testType, $disabledTests, $renewClientContextBetweenTests
            throw 'Run-TestsInBcContainer must be mocked.'
        }
    }

    AfterAll {
        $env:GITHUB_EVENT_NAME = $script:savedGitHubEventName
    }

    BeforeEach {
        Mock Get-BcAppsDisabledTestsForApp { @() }
        Mock Run-TestsInBcContainer { $true }
        Mock Start-Transcript { }
        Mock Stop-Transcript { }
        Mock Test-TransientTestFailure { $false }
        Mock Write-Host { }
    }

    It "removes an action-supplied Legacy testType before BCH execution" {
        $parameters = @{
            appName = 'Legacy Tests'
            tenant = 'default'
            testType = 'Legacy'
        }

        & $script:runTestsScript -parameters $parameters -TestType Legacy -SkipAutomaticDisabledPass |
            Should -BeTrue

        Should -Invoke Run-TestsInBcContainer -Times 1 -Exactly -ParameterFilter {
            -not $PSBoundParameters.ContainsKey('testType')
        }
        $parameters.testType | Should -Be 'Legacy'
    }

    It "preserves typed BCH lane <Lane>" -ForEach @(
        @{ Lane = 'UnitTest' }
        @{ Lane = 'IntegrationTest' }
        @{ Lane = 'Uncategorized' }
    ) {
        $parameters = @{
            appName = "$Lane Tests"
            tenant = 'default'
            testType = $Lane
        }

        & $script:runTestsScript -parameters $parameters -TestType $Lane -SkipAutomaticDisabledPass |
            Should -BeTrue

        Should -Invoke Run-TestsInBcContainer -Times 1 -Exactly -ParameterFilter {
            $testType -eq $Lane
        }
        $parameters.testType | Should -Be $Lane
    }

    It "uses supplied disabled tests in the explicit single-app BCH path" {
        $suppliedDisabledTests = @(
            [PSCustomObject]@{
                codeunitName = "Configured Codeunit"
                method = @("Configured Method")
            }
        )
        $parameters = @{
            appName = "Integration Tests"
            tenant = "default"
            testType = "IntegrationTest"
            disabledTests = $suppliedDisabledTests
        }
        Mock Get-BcAppsDisabledTestsForApp {
            throw "The explicit single-app path must not replace supplied exclusions."
        }

        & $script:runTestsScript `
            -parameters $parameters `
            -TestType IntegrationTest `
            -UseSuppliedDisabledTests `
            -SkipAutomaticDisabledPass `
            -SkipTestTolerance |
            Should -BeTrue

        Should -Invoke Get-BcAppsDisabledTestsForApp -Times 0
        Should -Invoke Run-TestsInBcContainer -Times 1 -Exactly -ParameterFilter {
            $disabledTests.Count -eq 1 -and
            $disabledTests[0].codeunitName -eq "Configured Codeunit"
        }
    }

    It "persists final parent tolerance for subsequent AL-Go app callbacks" {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        Mock Get-ToleranceBranch { 'main' }
        Mock Receive-UnstableTestsArtifact { 'unstable-tests.json' }
        Mock Test-ShouldTolerateFailures { $true }
        Mock Get-InstalledTestAppNames {
            throw 'The second AL-Go app callback must use the final cached result.'
        }
        $previousRunnerTemp = $env:RUNNER_TEMP
        $containerName = "ut-$([guid]::NewGuid().ToString('N'))"
        $stateFile = Join-Path $TestDrive "parallelTests_$containerName.json"
        Mock Invoke-ParallelTestExecution {
            @{
                completed = $true
                finalResult = $false
            } | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding utf8
            return $false
        }
        try {
            $env:RUNNER_TEMP = $TestDrive
            & $script:runTestsScript -parameters @{
                appName = 'First AL-Go App'
                containerName = $containerName
                tenant = 'default'
                JUnitResultFileName = 'merged-results.xml'
            } -TestType IntegrationTest -AppNamesToTest @('Tests A', 'Tests B') |
                Should -BeTrue

            Invoke-PerProjectTestRun -parameters @{
                containerName = $containerName
                appName = 'Second AL-Go App'
            } | Should -BeTrue

            (Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json).finalResult |
                Should -BeTrue
            Should -Invoke Invoke-ParallelTestExecution -Times 1 -Exactly
            Should -Invoke Test-ShouldTolerateFailures -Times 1 -Exactly -ParameterFilter {
                $TestResultsPath -eq 'merged-results.xml' -and
                $UnstableTestsPath -eq 'unstable-tests.json'
            }
            Should -Invoke Get-InstalledTestAppNames -Times 0
            Should -Invoke Run-TestsInBcContainer -Times 0
        }
        finally {
            $env:RUNNER_TEMP = $previousRunnerTemp
        }
    }

    It "does not apply test tolerance inside scheduler workers" {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        Mock Run-TestsInBcContainer { $false }
        Mock Test-ShouldTolerateFailures { throw 'Worker tolerance must be deferred to the parent.' }

        & $script:runTestsScript -parameters @{
            appName = 'Worker Tests'
            tenant = 'default'
            JUnitResultFileName = 'worker-results.xml'
        } -TestType IntegrationTest -SkipAutomaticDisabledPass -SkipTestTolerance |
            Should -BeFalse

        Should -Invoke Test-ShouldTolerateFailures -Times 0
    }

    It "does not tolerate a final test infrastructure failure" {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        $previousRunnerTemp = $env:RUNNER_TEMP
        $containerName = "ut-$([guid]::NewGuid().ToString('N'))"
        $stateFile = Join-Path $TestDrive "parallelTests_$containerName.json"
        Mock Invoke-ParallelTestExecution {
            @{
                completed = $true
                finalResult = $false
            } | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding utf8
            $parameters["_bcAppsTestInfrastructureBlocksTolerance"] = $true
            return $false
        }
        Mock Test-ShouldTolerateFailures {
            throw 'Infrastructure failures must bypass test tolerance.'
        }
        try {
            $env:RUNNER_TEMP = $TestDrive
            & $script:runTestsScript -parameters @{
                appName = 'First AL-Go App'
                containerName = $containerName
                tenant = 'default'
                JUnitResultFileName = 'merged-results.xml'
            } -TestType IntegrationTest -AppNamesToTest @('Tests A') |
                Should -BeFalse

            Should -Invoke Test-ShouldTolerateFailures -Times 0
            (Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json).finalResult |
                Should -BeFalse
        }
        finally {
            $env:RUNNER_TEMP = $previousRunnerTemp
        }
    }
}

Describe "ParallelTestExecution command isolation" {
    It "does not shadow the AL-Go disabled-test helper across override iterations" {
        function Get-DisabledTestsForApp {
            param(
                [hashtable]$settings,
                [string]$projectPath,
                [string]$appId
            )
            "$($settings.marker):${projectPath}:$appId"
        }

        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force

        $module = Get-Module ParallelTestExecution
        $module.ExportedCommands.Keys | Should -Contain 'Get-BcAppsDisabledTestsForApp'
        $module.ExportedCommands.Keys | Should -Not -Contain 'Get-DisabledTestsForApp'

        foreach ($appId in @('first-app', 'second-app')) {
            Get-DisabledTestsForApp -settings @{ marker = 'algo' } `
                -projectPath 'project' -appId $appId |
                Should -Be "algo:project:$appId"
        }
    }
}

Describe "Separate RunTests action bucket configuration" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
        $script:configurationRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $script:repoSettings = Get-Content (Join-Path $script:configurationRepoRoot '.github\AL-Go-Settings.json') -Raw |
            ConvertFrom-Json
        $script:testConfiguration = Get-Content (Join-Path $script:configurationRepoRoot 'build\scripts\TestConfiguration.json') -Raw |
            ConvertFrom-Json
        $script:testProjects = @(Get-ChildItem (Join-Path $script:configurationRepoRoot 'build\projects') -Directory -Filter 'Test Apps *')
        $script:expectedCoverage = @{
            IntegrationTests = $true
            UncategorizedTests = $true
            LegacyTestsBucket1 = $false
            LegacyTestsBucket2 = $false
        }
        $script:expectedCoverageFormats = @{
            IntegrationTests = @('bc-json')
            UncategorizedTests = @('bc-json')
            LegacyTestsBucket1 = @('bc-json', 'cobertura')
            LegacyTestsBucket2 = @('bc-json', 'cobertura')
        }
        $script:expectedTestType = @{
            IntegrationTests = 'IntegrationTest'
            UncategorizedTests = 'Uncategorized'
            LegacyTestsBucket1 = 'Legacy'
            LegacyTestsBucket2 = 'Legacy'
        }
        $script:expectedCompany = @{
            IntegrationTests = 'My Company'
            UncategorizedTests = 'CRONUS International Ltd.'
            LegacyTestsBucket1 = 'CRONUS International Ltd.'
            LegacyTestsBucket2 = 'CRONUS International Ltd.'
        }
        $script:expectedBucket = @{
            IntegrationTests = $null
            UncategorizedTests = $null
            LegacyTestsBucket1 = 1
            LegacyTestsBucket2 = 2
        }
        $script:expectedDemoData = @{
            IntegrationTests = @()
            UncategorizedTests = @()
            LegacyTestsBucket1 = @('Standard', 'Evaluation')
            LegacyTestsBucket2 = @()
        }
    }

    It "maps both project path separator forms to the same separate-action rule" {
        $script:testProjects.Count | Should -BeGreaterThan 0

        foreach ($project in $script:testProjects) {
            $projectSettings = Get-Content (Join-Path $project.FullName '.AL-Go\settings.json') -Raw | ConvertFrom-Json

            foreach ($buildMode in @($projectSettings.buildModes)) {
                $bucketRule = @($projectSettings.ConditionalSettings | Where-Object {
                    @($_.buildModes) -contains $buildMode
                })
                $bucketRule.Count | Should -Be 1

                foreach ($projectPath in @(
                    "build/projects/$($project.Name)",
                    "build\projects\$($project.Name)"
                )) {
                    $rules = @($script:repoSettings.conditionalSettings | Where-Object {
                        $_.PSObject.Properties.Name -contains 'projects' -and
                        @($_.projects | Where-Object { $projectPath -like $_ }).Count -gt 0 -and
                        @($_.buildModes) -contains $buildMode -and
                        $_.settings.PSObject.Properties.Name -contains 'useSeparateTestAction'
                    })
                    $rules.Count | Should -Be 1

                    $separateSettings = $rules[0].settings.useSeparateTestAction
                    $separateSettings.enabled | Should -BeTrue
                    $separateSettings.testType | Should -Be $bucketRule[0].settings.testType
                    $separateSettings.codeCoverageEnabled | Should -Be $script:expectedCoverage[$buildMode]
                    @($separateSettings.codeCoverageFormats) |
                        Should -Be $script:expectedCoverageFormats[$buildMode]
                }
            }
        }
    }

    It "resolves both separator forms through the coverage-branch ReadSettings module" {
        $readSettingsModule = @(
            if (-not [string]::IsNullOrWhiteSpace($env:BCAPPS_ALGO_COVERAGE_ROOT)) {
                Join-Path $env:BCAPPS_ALGO_COVERAGE_ROOT 'Actions\.Modules\ReadSettings.psm1'
            }
        ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($readSettingsModule)) {
            Set-ItResult -Skipped -Because 'the AL-Go coverage branch checkout is unavailable'
            return
        }

        Import-Module $readSettingsModule -Force
        $readSettingsParameters = @{
            baseFolder = $script:configurationRepoRoot
            repoName = 'microsoft/BCApps'
            workflowName = 'CI/CD'
            branchName = 'spetersen/runTestsCC'
            userName = 'spetersenms'
            trigger = 'workflow_dispatch'
            orgSettingsVariableValue = ''
            repoSettingsVariableValue = ''
            environmentSettingsVariableValue = ''
            environmentName = ''
        }

        foreach ($project in $script:testProjects) {
            $projectSettings = Get-Content (Join-Path $project.FullName '.AL-Go\settings.json') -Raw |
                ConvertFrom-Json
            foreach ($projectPath in @(
                "build/projects/$($project.Name)",
                "build\projects\$($project.Name)"
            )) {
                foreach ($buildMode in @($projectSettings.buildModes)) {
                    $settings = ReadSettings @readSettingsParameters -project $projectPath -buildMode $buildMode
                    $settings.useSeparateTestAction.enabled | Should -BeTrue
                    $settings.useSeparateTestAction.testType | Should -Be $script:expectedTestType[$buildMode]
                    $settings.useSeparateTestAction.codeCoverageEnabled |
                        Should -Be $script:expectedCoverage[$buildMode]
                    @($settings.useSeparateTestAction.codeCoverageFormats) |
                        Should -Be $script:expectedCoverageFormats[$buildMode]
                    $settings.useSeparateTestAction.codeCoverageSummary | Should -Be 'both'
                    $settings.testType | Should -Be $script:expectedTestType[$buildMode]
                    $settings.companyName | Should -Be $script:expectedCompany[$buildMode]
                    [int]$settings.numberOfTenantsForTesting | Should -Be 4
                    $settings.artifact | Should -Be 'bcinsider/Sandbox/30.0.56342.0//latest'
                    [bool]$settings.enableTaskScheduler |
                        Should -Be ($buildMode -eq 'UncategorizedTests')
                    if ($null -eq $script:expectedBucket[$buildMode]) {
                        $settings.Contains('bucketNumber') | Should -BeFalse
                    }
                    else {
                        [int]$settings.bucketNumber | Should -Be $script:expectedBucket[$buildMode]
                    }
                    $expectedDemoData = @($script:expectedDemoData[$buildMode])
                    $demoDataOverride = @($projectSettings.ConditionalSettings | Where-Object {
                        @($_.buildModes) -contains $buildMode -and
                        $_.settings.PSObject.Properties.Name -contains 'overwriteSettings' -and
                        @($_.settings.overwriteSettings) -contains 'additionalDemoDataTypes'
                    }) | Select-Object -Last 1
                    if ($demoDataOverride) {
                        $expectedDemoData = @($demoDataOverride.settings.additionalDemoDataTypes)
                    }
                    $actualDemoData = if ($settings.Contains('additionalDemoDataTypes')) {
                        @($settings.additionalDemoDataTypes)
                    }
                    else {
                        @()
                    }
                    $actualDemoData | Should -Be $expectedDemoData
                }
            }
        }
    }

    It "keeps the BC artifact selection unchanged" {
        $script:repoSettings.artifact | Should -Be "bcinsider/Sandbox/30.0.56342.0//latest"
    }

    It "preserves each legacy bucket's configured membership and order" {
        InModuleScope ParallelTestExecution -Parameters @{ Configuration = $script:testConfiguration } {
            $installed = @($Configuration."LegacyTests-Bucket2") +
                @("Modern Tests") +
                @($Configuration."LegacyTests-Bucket1")

            @(Get-AppNamesForBucket -InstalledTestAppNames $installed -TestType "Legacy" -BucketNumber 1) |
                Should -Be @($Configuration."LegacyTests-Bucket1")
            @(Get-AppNamesForBucket -InstalledTestAppNames $installed -TestType "Legacy" -BucketNumber 2) |
                Should -Be @($Configuration."LegacyTests-Bucket2")
        }
    }

    It "keeps legacy apps out of the IntegrationTest and Uncategorized lanes" {
        InModuleScope ParallelTestExecution -Parameters @{ Configuration = $script:testConfiguration } {
            $installed = @(
                $Configuration."LegacyTests-Bucket1"[0]
                "Modern Tests A"
                $Configuration."LegacyTests-Bucket2"[0]
                "Modern Tests B"
            )

            @(Get-AppNamesForBucket -InstalledTestAppNames $installed -TestType "IntegrationTest") |
                Should -Be @("Modern Tests A", "Modern Tests B")
            @(Get-AppNamesForBucket -InstalledTestAppNames $installed -TestType "Uncategorized") |
                Should -Be @("Modern Tests A", "Modern Tests B")
        }
    }
}

Describe "ParallelTestExecution background-task profile" {
    BeforeAll {
        $script:profileRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $script:repoSettings = Get-Content (Join-Path $script:profileRepoRoot '.github\AL-Go-Settings.json') -Raw |
            ConvertFrom-Json
    }

    It "opts only UncategorizedTests into background task execution" {
        $script:repoSettings.PSObject.Properties.Name | Should -Not -Contain 'enableTaskScheduler'
        $rules = @($script:repoSettings.conditionalSettings | Where-Object {
            $_.settings.PSObject.Properties.Name -contains 'enableTaskScheduler'
        })
        $rules.Count | Should -Be 1
        @($rules[0].buildModes).Count | Should -Be 1
        $rules[0].buildModes[0] | Should -Be 'UncategorizedTests'
        $rules[0].settings.enableTaskScheduler | Should -BeTrue
        $rules[0].PSObject.Properties.Name | Should -Not -Contain 'projects'
    }

    It "retains the profile for every country test project without scheduler overrides" {
        $projects = @(Get-ChildItem (Join-Path $script:profileRepoRoot 'build\projects') -Directory -Filter 'Test Apps *')
        $projects.Count | Should -BeGreaterThan 0
        foreach ($project in $projects) {
            $settings = Get-Content (Join-Path $project.FullName '.AL-Go\settings.json') -Raw | ConvertFrom-Json
            $settings.PSObject.Properties.Name | Should -Not -Contain 'enableTaskScheduler'
            $profiles = @($settings.ConditionalSettings | Where-Object { $_.buildModes -contains 'UncategorizedTests' })
            $profiles.Count | Should -Be @($settings.buildModes | Where-Object { $_ -eq 'UncategorizedTests' }).Count
            foreach ($testProfile in $profiles) {
                $testProfile.settings.testType | Should -Be 'Uncategorized'
            }
            foreach ($rule in $settings.ConditionalSettings) {
                $rule.settings.PSObject.Properties.Name | Should -Not -Contain 'enableTaskScheduler'
            }
        }
    }

    It "runs APIV<Version> RapidStart polling tests in the background-enabled profile" -ForEach @(
        @{ Version = '1' }
        @{ Version = '2' }
    ) {
        $path = Join-Path $script:profileRepoRoot "src\Apps\W1\APIV$Version\test\src\APIV${Version}AutomationRSPackage.Codeunit.al"
        $source = Get-Content $path -Raw
        $source | Should -Match 'TestType\s*=\s*Uncategorized\s*;'
        $source | Should -Match 'procedure TestImportRSPackage\('
        $source | Should -Match 'procedure TestImportWrongRSPackage\('
        $source | Should -Match 'procedure TestApplyRSPackage\('
    }
}

Describe "ParallelTestExecution transient retry scheduling" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "classifies page 130455 metadata-resolution runtime failures as transient" {
        InModuleScope ParallelTestExecution {
            @(
                "ObjName:Command Line Test Tool, ObjID:130455, Type:Form, MethodName:ExtensionId_a45_OnValidate`nOffset and length were out of bounds for the array"
                "ObjName:Command Line Test Tool, ObjID:130455, Type:Form, MethodName:ExtensionId_a45_OnValidate`nNullable object must have a value."
                "TRANSIENT TEST PLATFORM RACE detected for app 'Tests' on tenant 'tenant2'."
                "Cannot open page 130455"
                "InvokeInteractions failed with status code 500"
                "at InteractionManager.InvokeInteractions in InteractionManager.cs:line 203"
                "Cannot open page 130455`nClientSession State is InError (Wait time 25 seconds)"
            ) | ForEach-Object {
                Test-TransientTestFailure -Output $_ | Should -BeTrue
            }
        }
    }

    It "does not classify generic session errors or unrelated failures as transient" {
        InModuleScope ParallelTestExecution {
            @(
                $null
                ''
                'ClientSession State is InError (Wait time 25 seconds)'
                "Assertion failed: expected 2 but was 1`nClientSession State is InError"
                "Permission denied opening page 42`nClientSession State is InError"
                'Cannot open page 130456'
                'InvokeInteractions failed with status code 403'
                'Nullable object must have a value.'
                'Object reference not set to an instance of an object.'
                'Assertion failed: expected 2 but was 1'
                'GET request failed. Response code is 500 (InternalServerError), expected code is 200. Error message: Object reference not set to an instance of an object.'
                "Opened page 130455 successfully.`nGET request failed. Response code is 500 (InternalServerError), expected code is 200. Error message: Object reference not set to an instance of an object."
            ) | ForEach-Object {
                Test-TransientTestFailure -Output $_ | Should -BeFalse
            }
        }
    }

    It "retries known races only once and never retries ordinary InError failures" {
        InModuleScope ParallelTestExecution {
            Mock Receive-Job { 'Cannot open page 130455' } -RemoveParameterType Job
            Mock Remove-Job {} -RemoveParameterType Job
            $entry = @{ appName = 'Tests'; tenant = 'default' }
            $job = @{ State = 'Failed' }

            (Receive-TestJobResult -Entry $entry -Job $job -Retried @{}).Outcome | Should -Be 'Transient'
            (Receive-TestJobResult -Entry $entry -Job $job -Retried @{ Tests = $true }).Outcome | Should -Be 'Failed'

            Mock Receive-Job { "Assertion failed`nClientSession State is InError" } -RemoveParameterType Job
            (Receive-TestJobResult -Entry $entry -Job $job -Retried @{}).Outcome | Should -Be 'Failed'
            Mock Receive-Job { 'GET request failed. Response code is 500 (InternalServerError), expected code is 200. Error message: Object reference not set to an instance of an object.' } -RemoveParameterType Job
            (Receive-TestJobResult -Entry $entry -Job $job -Retried @{}).Outcome | Should -Be 'Failed'
            $job.State = 'Completed'
            (Receive-TestJobResult -Entry $entry -Job $job -Retried @{}).Outcome | Should -Be 'Passed'
            Mock Receive-Job { throw 'Result stream failed.' } -RemoveParameterType Job
            (Receive-TestJobResult -Entry $entry -Job $job -Retried @{}).Outcome | Should -Be 'Failed'
            Should -Invoke Remove-Job -Times 6 -Exactly
        }
    }

    It "re-dispatches a transient platform-race victim ahead of the apps still queued" {
        # The dispatch order is what decides the critical path: a platform race normally kills a
        # job within a minute of dispatch, so the victim is one of the first (longest) apps. If the
        # retry went to the back of the queue, the longest app would restart only after every other
        # app had been dispatched, adding its whole duration to the tail of the run.
        InModuleScope ParallelTestExecution {
            $script:dispatched = [System.Collections.Generic.List[string]]::new()
            $script:raced = $false

            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @('Big', 'Medium', 'Small') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Wait-ForSpecificTenant { 'default' }
            Mock Wait-ForAllTestJobs { $true }
            Mock Merge-TenantTestResults { }
            Mock Start-TestAppDispatch {
                $script:dispatched.Add($AppName)
                # 'Big' loses the platform race on its very first dispatch, exactly once.
                if ($AppName -eq 'Big' -and -not $script:raced) {
                    $script:raced = $true
                    $State.transient = @($State.transient) + @(
                        [PSCustomObject]@{ Key = $AppName; Tenant = $Tenant }
                    )
                }
            }

            $params = @{ containerName = "ut-$([guid]::NewGuid().ToString('N'))"; tenant = 'default' }
            $null = Invoke-ParallelTestExecution -parameters $params -scriptPath 'unused.ps1' `
                -testType 'Legacy' -appNamesToTest @('Big', 'Medium', 'Small')

            $script:dispatched | Should -Be @('Big', 'Big', 'Medium', 'Small')
        }
    }
}

Describe "ParallelTestExecution RequiredTestIsolation discovery" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "flattens discovered codeunits and excludes codeunits without enabled methods" {
        InModuleScope ParallelTestExecution {
            $discovered = @(
                [PSCustomObject]@{ Id = '100'; Name = 'Direct'; Tests = @('A', 'B') }
                [PSCustomObject]@{
                    Group = 'G'
                    Codeunits = @(
                        [PSCustomObject]@{ Id = '200'; Name = 'Grouped'; Tests = @('C') }
                        [PSCustomObject]@{ Id = '300'; Name = 'Disabled'; Tests = @() }
                    )
                }
            )

            $result = @(ConvertTo-RequiredDisabledWorkItems -DiscoveredTests $discovered -AppName 'API Tests' -AppId 'app-id')

            $result.Count | Should -Be 2
            $result[0].Key | Should -Be 'API Tests::100'
            $result[0].TestCount | Should -Be 2
            $result[1].CodeunitId | Should -Be '200'
        }
    }

    It "discovers selected apps once each while preserving isolation, lane and exclusion filters" {
        InModuleScope ParallelTestExecution {
            Mock Get-ParametersForCommand { @{ containerName = 'c'; tenant = 'default' } }
            Mock Get-BcAppsDisabledTestsForApp {
                @([PSCustomObject]@{ codeunitId = 999; method = 'DisabledMethod' })
            }
            Mock Get-TestsFromBcContainer {
                @([PSCustomObject]@{ Id = '500'; Name = 'API E2E'; Tests = @('Create', 'Modify') })
            }

            $result = @(
                Get-RequiredDisabledWorkItems -Parameters @{ containerName = 'c'; tenant = 'default' } `
                    -TestType 'IntegrationTest' -AppNamesToTest @('API Tests', 'New API Tests') `
                    -AppIdByName @{ 'API Tests' = 'app-id'; 'New API Tests' = 'new-app-id'; 'Unselected Tests' = 'other-id' }
            )

            $result.Count | Should -Be 2
            $result[0].CodeunitId | Should -Be '500'
            $result[1].AppName | Should -Be 'New API Tests'
            Should -Invoke Get-TestsFromBcContainer -Times 1 -ParameterFilter {
                $extensionId -eq 'app-id' -and
                $requiredTestIsolation -eq 'Disabled' -and
                $testType -eq 'IntegrationTest' -and
                $disabledTests.Count -eq 1
            }
            Should -Invoke Get-TestsFromBcContainer -Times 1 -Exactly -ParameterFilter {
                $extensionId -eq 'new-app-id' -and
                $requiredTestIsolation -eq 'Disabled' -and
                $testType -eq 'IntegrationTest' -and
                $disabledTests.Count -eq 1
            }
            Should -Invoke Get-TestsFromBcContainer -Times 0 -ParameterFilter {
                $extensionId -eq 'other-id'
            }
        }
    }

    It "does not use unfiltered discovery for Legacy buckets" {
        InModuleScope ParallelTestExecution {
            Mock Get-ParametersForCommand { @{ containerName = 'c'; tenant = 'default'; testType = 'stale' } }
            Mock Get-BcAppsDisabledTestsForApp { @() }
            Mock Get-TestsFromBcContainer { @() }

            $result = @(Get-RequiredDisabledWorkItems -Parameters @{ containerName = 'c' } `
                -TestType 'Legacy' -AppNamesToTest @('Legacy Tests') `
                -AppIdByName @{ 'Legacy Tests' = 'legacy-id' })

            $result.Count | Should -Be 0
            Should -Invoke Get-TestsFromBcContainer -Times 0
        }
    }
}

Describe "ParallelTestExecution clean tenant scheduling" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    BeforeEach {
        Mock -ModuleName ParallelTestExecution Get-ALGoSetting { $true } -ParameterFilter {
            $Key -eq 'enableCleanTestCodeunitExecution'
        }
        Mock -ModuleName ParallelTestExecution Invoke-ScriptInBcContainer {
            throw 'Unexpected unmocked container access.'
        }
        Mock -ModuleName ParallelTestExecution Reset-BcTestTenant {
            throw 'Tenant resets require an explicit test mock.'
        }
    }

    It "writes and reads cached state without temp environment variables" {
        InModuleScope ParallelTestExecution {
            $previousRunnerTemp = $env:RUNNER_TEMP
            $previousTemp = $env:TEMP
            $containerName = "ut-$([guid]::NewGuid().ToString('N'))"
            $stateFile = Join-Path ([System.IO.Path]::GetTempPath()) "parallelTests_$containerName.json"
            Mock Get-AvailableBcTenantInfo {
                @([PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' })
            }
            Mock Get-BcContainerAppInfo {
                @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
            }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Get-InstalledTestAppNames { throw 'The cached override must not rediscover apps.' }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch { }
            Mock Wait-ForAllTestJobs { $true }
            Mock Merge-TenantTestResults { }
            try {
                $env:RUNNER_TEMP = $null
                $env:TEMP = $null
                $stateFile = Join-Path ([System.IO.Path]::GetTempPath()) "parallelTests_$containerName.json"

                Invoke-ParallelTestExecution -parameters @{
                    containerName = $containerName
                    tenant = 'default'
                } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests') |
                    Should -BeTrue

                Test-Path $stateFile | Should -BeTrue
                Get-CachedTestRunResult -ContainerName $containerName | Should -BeTrue
                Invoke-PerProjectTestRun -parameters @{
                    containerName = $containerName
                    appName = 'second-algo-app'
                } | Should -BeTrue
                Should -Invoke Get-InstalledTestAppNames -Times 0
            } finally {
                $env:RUNNER_TEMP = $previousRunnerTemp
                $env:TEMP = $previousTemp
                if (Test-Path $stateFile) {
                    Remove-Item $stateFile -Force
                }
            }
        }
    }

    It "fails immediately when the container has no operational tenants" {
        InModuleScope ParallelTestExecution {
            Mock Get-AvailableBcTenantInfo { @() }

            {
                Invoke-ParallelTestExecution -parameters @{
                    containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                    tenant = 'default'
                } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests')
            } | Should -Throw "*No operational tenants are available*"
        }
    }

    It "marks vanished tracked jobs as failures" {
        InModuleScope ParallelTestExecution {
            Mock Get-Job { $null }
            $state = [PSCustomObject]@{
                jobs = @([PSCustomObject]@{ jobId = 42; tenant = 'default'; appName = 'Tests' })
                hasFailures = $false
                retried = @{}
            }

            @(Get-FreeTenants -state $state -tenants @('default')) | Should -Be @('default')
            $state.hasFailures | Should -BeTrue
            $state.jobs.Count | Should -Be 0

            $state.jobs = @([PSCustomObject]@{ jobId = 43; tenant = 'default'; appName = 'Tests' })
            $state.hasFailures = $false
            Wait-ForAllTestJobs -state $state
            $state.hasFailures | Should -BeTrue
            $state.jobs.Count | Should -Be 0
        }
    }

    It "requires every configured aggregate result file to exist and contain supported XML" {
        InModuleScope ParallelTestExecution {
            $validFile = Join-Path $TestDrive 'valid-results.xml'
            $invalidFile = Join-Path $TestDrive 'invalid-results.xml'
            '<testsuites />' | Set-Content -LiteralPath $validFile -Encoding utf8
            '<not-test-results />' | Set-Content -LiteralPath $invalidFile -Encoding utf8

            Test-BcAppsExpectedTestResults -Parameters @{
                JUnitResultFileName = $validFile
            } | Should -BeTrue
            Test-BcAppsExpectedTestResults -Parameters @{
                JUnitResultFileName = (Join-Path $TestDrive 'missing-results.xml')
            } | Should -BeFalse
            Test-BcAppsExpectedTestResults -Parameters @{
                JUnitResultFileName = $invalidFile
            } | Should -BeFalse
        }
    }

    It "blocks tolerance when the scheduler finishes without its configured aggregate result" {
        InModuleScope ParallelTestExecution {
            $previousRunnerTemp = $env:RUNNER_TEMP
            $containerName = "ut-$([guid]::NewGuid().ToString('N'))"
            $stateFile = Join-Path $TestDrive "parallelTests_$containerName.json"
            $parameters = @{
                containerName = $containerName
                tenant = 'default'
                JUnitResultFileName = (Join-Path $TestDrive 'missing-aggregate.xml')
            }
            Mock Get-AvailableBcTenantInfo {
                @([PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' })
            }
            Mock Get-BcContainerAppInfo {
                @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
            }
            Mock Get-ALGoSetting { $false } -ParameterFilter {
                $Key -eq 'enableCleanTestCodeunitExecution'
            }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch {}
            Mock Wait-ForAllTestJobs { $true }
            Mock Merge-TenantTestResults {}

            try {
                $env:RUNNER_TEMP = $TestDrive
                Invoke-ParallelTestExecution -parameters $parameters `
                    -scriptPath 'unused.ps1' -testType 'IntegrationTest' `
                    -appNamesToTest @('Tests') |
                    Should -BeFalse
                $parameters['_bcAppsTestInfrastructureBlocksTolerance'] |
                    Should -BeTrue
            }
            finally {
                $env:RUNNER_TEMP = $previousRunnerTemp
                Remove-Item -LiteralPath $stateFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "does not create a database template when no Disabled-isolation codeunits are enabled" {
        InModuleScope ParallelTestExecution {
            Mock Get-AvailableBcTenantInfo {
                @([PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' })
            }
            Mock Get-BcContainerAppInfo {
                @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
            }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock New-BcTestTenantTemplate { throw 'Template must not be created' }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch { }
            Mock Wait-ForAllTestJobs { $true }
            Mock Merge-TenantTestResults { }

            $result = Invoke-ParallelTestExecution -parameters @{
                containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                tenant = 'default'
            } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests')

            $result | Should -BeTrue
            Should -Invoke New-BcTestTenantTemplate -Times 0
            Should -Invoke Get-RequiredDisabledWorkItems -Times 1 -Exactly -ParameterFilter {
                $AppNamesToTest.Count -eq 1 -and $AppNamesToTest[0] -eq 'Tests'
            }
            Should -Invoke Start-TestAppDispatch -Times 1 -Exactly -ParameterFilter {
                $SkipAutomaticDisabledPass
            }
        }
    }

    Describe "ParallelTestExecution result metadata" {
        BeforeAll {
            Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
        }

        It "adds app properties to clean-codeunit JUnit suites" {
            InModuleScope ParallelTestExecution {
                $resultFile = Join-Path ([System.IO.Path]::GetTempPath()) "junit-$([guid]::NewGuid().ToString('N')).xml"
                try {
                    @(
                        '<?xml version="1.0" encoding="UTF-8"?>'
                        '<testsuites>'
                        '  <testsuite name="139800 APIV2 - Items E2E" tests="1" failures="0">'
                        '    <testcase name="TestGetItem" />'
                        '  </testsuite>'
                        '</testsuites>'
                    ) | Set-Content -Path $resultFile -Encoding utf8

                    Add-MissingJUnitTestProperties -ResultFile $resultFile -WorkItems @(
                        [PSCustomObject]@{
                            CodeunitId = '139800'
                            AppId = 'app-id'
                            AppName = '_Exclude_APIV2_ Tests'
                        }
                    )

                    [xml]$xml = Get-Content $resultFile -Raw
                    $properties = @($xml.testsuites.testsuite.properties.property)
                    ($properties | Where-Object name -eq 'extensionid').value | Should -Be 'app-id'
                    ($properties | Where-Object name -eq 'appName').value | Should -Be '_Exclude_APIV2_ Tests'
                } finally {
                    Remove-Item $resultFile -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It "defers the automatic Unit disabled pass only for clean-tenant apps" {
        InModuleScope ParallelTestExecution {
            $script:skipValues = [System.Collections.Generic.List[bool]]::new()
            Mock Start-Sleep { }
            Mock Start-TestJob {
                $script:skipValues.Add($skipAutomaticDisabledPass.IsPresent)
                [PSCustomObject]@{ Id = $script:skipValues.Count }
            }

            $state = [PSCustomObject]@{ jobs = @() }
            Start-TestAppDispatch -Parameters @{} -AppName 'Normal Tests' -AppId 'normal-id' `
                -Tenant 'default' -ScriptPath 'runner.ps1' -TestType 'UnitTest' -State $state
            Start-TestAppDispatch -Parameters @{} -AppName 'API Tests' -AppId 'api-id' `
                -Tenant 'tenant2' -ScriptPath 'runner.ps1' -TestType 'UnitTest' -State $state `
                -SkipAutomaticDisabledPass

            $script:skipValues | Should -Be @($false, $true)
        }
    }

    It "loads all app exclusions without consulting country settings" {
        InModuleScope ParallelTestExecution {
            $script:disabledTestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
            Mock Get-BaseFolder { $script:disabledTestRoot }
            Mock Get-ALGoSetting { throw 'Exclusions must not depend on country settings' }
            try {
                $appFolder = Join-Path $script:disabledTestRoot 'DisabledTests\Example_Tests'
                $null = New-Item -Path $appFolder -ItemType Directory -Force
                '[{"codeunitId":500,"method":"First"}]' |
                    Set-Content (Join-Path $appFolder 'first.json')
                '[{"codeunitId":501,"method":"*"}]' |
                    Set-Content (Join-Path $appFolder 'second.json')

                $result = @(Get-BcAppsDisabledTestsForApp -AppName 'Example Tests')

                $result.Count | Should -Be 2
                $result.codeunitId | Should -Contain 500
                $result.codeunitId | Should -Contain 501
                @(Get-BcAppsDisabledTestsForApp -AppName 'Other Tests').Count | Should -Be 0
                Should -Invoke Get-ALGoSetting -Times 0
            } finally {
                Remove-Item $script:disabledTestRoot -Recurse -Force
            }
        }
    }

    It "dispatches one codeunit with Disabled isolation" {
        InModuleScope ParallelTestExecution {
            $script:capturedParameters = $null

            Mock Get-BcAppsDisabledTestsForApp { @() }
            Mock Start-Sleep { }
            Mock Start-TestJob {
                $script:capturedParameters = $parameters
                [PSCustomObject]@{ Id = 42 }
            }

            $state = [PSCustomObject]@{ jobs = @() }
            $workItem = [PSCustomObject]@{
                Key = 'Tests::500'
                AppName = 'Tests'
                AppId = 'tests-id'
                CodeunitId = '500'
                CodeunitName = 'API E2E'
            }

            Start-RequiredDisabledDispatch -Parameters @{
                containerName = 'c'
                JUnitResultFileName = 'results.xml'
            } -WorkItem $workItem -TenantInfo ([PSCustomObject]@{
                Id = 'tenant2'
                DatabaseName = 'tenant2'
            }) -ScriptPath 'runner.ps1' `
                -TestType 'IntegrationTest' -State $state

            $script:capturedParameters.testCodeunit | Should -Be '500'
            $script:capturedParameters.requiredTestIsolation | Should -Be 'Disabled'
            $script:capturedParameters.testRunnerCodeunitId | Should -Be '130451'
            $script:capturedParameters.AppendToJUnitResultFile | Should -BeTrue
            $state.jobs.Count | Should -Be 1
        }
    }

    It "marks scheduler retries as reruns so existing XML entries are replaced" {
        InModuleScope ParallelTestExecution {
            $script:capturedParameters = $null

            Mock Get-BcAppsDisabledTestsForApp { @() }
            Mock Reset-BcTestTenant { }
            Mock Start-Sleep { }
            Mock Start-TestJob {
                $script:capturedParameters = $parameters
                [PSCustomObject]@{ Id = 42 }
            }

            Start-RequiredDisabledDispatch -Parameters @{ containerName = 'c' } -WorkItem ([PSCustomObject]@{
                Key = 'Tests::500'
                AppName = 'Tests'
                AppId = 'tests-id'
                CodeunitId = '500'
                CodeunitName = 'API E2E'
            }) -TenantInfo ([PSCustomObject]@{
                Id = 'tenant2'
                DatabaseName = 'tenant2'
            }) -ScriptPath 'runner.ps1' `
                -TestType 'IntegrationTest' -State ([PSCustomObject]@{ jobs = @() }) `
                -Verb 'Re-dispatching'

            $script:capturedParameters.ReRun | Should -BeTrue
        }
    }

    It "retries a clean codeunit on its original tenant" {
        InModuleScope ParallelTestExecution {
            $script:dispatchTenants = [System.Collections.Generic.List[string]]::new()
            $script:firstDispatch = $true

            Mock Reset-BcTestTenant { }
            Mock Wait-ForAllTestJobs { $true }
            Mock Start-RequiredDisabledDispatch {
                $script:dispatchTenants.Add($TenantInfo.Id)
                if ($script:firstDispatch) {
                    $script:firstDispatch = $false
                    $State.transient = @(
                        [PSCustomObject]@{ Key = $WorkItem.Key; Tenant = $TenantInfo.Id }
                    )
                }
            }

            $workItem = [PSCustomObject]@{
                Key = 'Tests::500'
                AppName = 'Tests'
                AppId = 'tests-id'
                CodeunitId = '500'
                CodeunitName = 'API E2E'
            }
            $tenantInfo = @(
                [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                [PSCustomObject]@{ Id = 'tenant3'; DatabaseName = 'tenant3' }
            )

            $result = Invoke-RequiredDisabledTestExecution -Parameters @{ containerName = 'c' } `
                -WorkItems @($workItem) -TenantInfo $tenantInfo -TemplateDatabaseName 'template' `
                -ScriptPath 'runner.ps1' -TestType 'UnitTest'

            $result | Should -BeTrue
            $script:dispatchTenants | Should -Be @('tenant2', 'tenant2')
        }
    }

    It "finishes all tenant resets before dispatching a clean-codeunit batch" {
        InModuleScope ParallelTestExecution {
            $script:events = [System.Collections.Generic.List[string]]::new()
            Mock Reset-BcTestTenant {
                $script:events.Add("reset:$Tenant")
            }
            Mock Start-RequiredDisabledDispatch {
                $script:events.Add("dispatch:$($TenantInfo.Id)")
            }
            Mock Wait-ForAllTestJobs { }

            $workItems = @(
                [PSCustomObject]@{ Key = 'Tests::500'; AppName = 'Tests'; AppId = 'id'; CodeunitId = '500'; CodeunitName = 'A' }
                [PSCustomObject]@{ Key = 'Tests::501'; AppName = 'Tests'; AppId = 'id'; CodeunitId = '501'; CodeunitName = 'B' }
            )
            $tenantInfo = @(
                [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                [PSCustomObject]@{ Id = 'tenant3'; DatabaseName = 'tenant3' }
            )

            Invoke-RequiredDisabledTestExecution -Parameters @{ containerName = 'c' } `
                -WorkItems $workItems -TenantInfo $tenantInfo -TemplateDatabaseName 'template' `
                -ScriptPath 'runner.ps1' -TestType 'UnitTest' | Should -BeTrue

            $script:events | Should -Be @('reset:tenant2', 'reset:tenant3', 'dispatch:tenant2', 'dispatch:tenant3')
        }
    }

    It "preserves configured Task Scheduler state <Enabled> during clean and ordinary execution" -ForEach @(
        @{ Enabled = $false }
        @{ Enabled = $true }
    ) {
        InModuleScope ParallelTestExecution -Parameters @{ Enabled = $Enabled } {
            param($Enabled)

            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
            }
            Mock Get-RequiredDisabledWorkItems {
                @([PSCustomObject]@{
                    Key = 'Tests::500'
                    AppName = 'Tests'
                    AppId = 'tests-id'
                    CodeunitId = '500'
                    CodeunitName = 'API E2E'
                    TestCount = 2
                })
            }
            $script:taskSchedulerEnabled = $Enabled
            $script:expectedTaskSchedulerEnabled = $Enabled
            Mock New-BcTestTenantTemplate { 'default-test-template' }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch {
                $script:taskSchedulerEnabled | Should -Be $script:expectedTaskSchedulerEnabled
            }
            Mock Wait-ForAllTestJobs { $true }
            Mock Invoke-RequiredDisabledTestExecution {
                $script:taskSchedulerEnabled | Should -Be $script:expectedTaskSchedulerEnabled
                $true
            }
            Mock Reset-BcTestTenant {
                $script:taskSchedulerEnabled | Should -Be $script:expectedTaskSchedulerEnabled
            }
            Mock Remove-BcTestTenantTemplate { }
            Mock Merge-TenantTestResults { }

            $result = Invoke-ParallelTestExecution -parameters @{
                containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                tenant = 'default'
            } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests')

            $result | Should -BeTrue
            Should -Invoke Get-RequiredDisabledWorkItems -Times 1 -Exactly -ParameterFilter {
                $AppNamesToTest.Count -eq 1 -and $AppNamesToTest[0] -eq 'Tests'
            }
            Should -Invoke New-BcTestTenantTemplate -Times 1 -ParameterFilter {
                $SourceDatabaseName -eq 'default'
            }
            Should -Invoke Invoke-ScriptInBcContainer -Times 0
            Should -Invoke Reset-BcTestTenant -Times 1 -Exactly -ParameterFilter {
                $Tenant -eq 'tenant2' -and
                $TenantDatabaseName -eq 'tenant2' -and
                $TemplateDatabaseName -eq 'default'
            }
            Should -Invoke Reset-BcTestTenant -Times 1 -ParameterFilter {
                $Tenant -eq 'tenant2' -and
                $TenantDatabaseName -eq 'tenant2' -and
                $TemplateDatabaseName -eq 'default-test-template'
            }
            Should -Invoke Invoke-RequiredDisabledTestExecution -Times 1 -ParameterFilter {
                $TemplateDatabaseName -eq 'default-test-template' -and
                $WorkItems.Count -eq 1 -and
                $TenantInfo.Count -eq 1 -and
                $TenantInfo[0].Id -eq 'tenant2'
            }
            Should -Invoke Remove-BcTestTenantTemplate -Times 1 -ParameterFilter {
                $TemplateDatabaseName -eq 'default-test-template'
            }
        }
    }

    Context "discovery fixture preservation" {
        BeforeEach {
            InModuleScope ParallelTestExecution {
                $script:fixtureEvents = [System.Collections.Generic.List[string]]::new()
                $script:fixtureTenants = @(
                    [PSCustomObject]@{ Id = 'worker-a'; DatabaseName = 'worker-a-db' }
                    [PSCustomObject]@{ Id = 'primary'; DatabaseName = 'primary-db' }
                    [PSCustomObject]@{ Id = 'worker-b'; DatabaseName = 'worker-b-db' }
                )
                $script:fixtures = @{
                    'primary-db' = 'pristine'
                    'worker-a-db' = 'pristine'
                    'worker-b-db' = 'pristine'
                }
                $script:fixtureParameters = @{
                    containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                    tenant = 'primary'
                    extensionId = 'caller-app-id'
                    testSuite = 'CALLER'
                    disabledTests = @([PSCustomObject]@{ codeunitId = 999; method = 'Excluded' })
                }
                $script:originalFixtureParameters = $script:fixtureParameters | ConvertTo-Json -Depth 5
                $script:fixtureWorkItems = @([PSCustomObject]@{
                    Key = 'Tests::500'; AppName = 'Tests'; AppId = 'tests-id'
                    CodeunitId = '500'; CodeunitName = 'API E2E'; TestCount = 2
                })
                $script:discoveryThrows = $false
                $script:cleanThrows = $false
                $script:cleanPassed = $true
                Mock Get-AvailableBcTenantInfo { $script:fixtureTenants }
                Mock Get-BcContainerAppInfo {
                    @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
                }
                Mock Get-RequiredDisabledWorkItems {
                    $script:fixtureEvents.Add("discover:$($Parameters.tenant)")
                    [object]::ReferenceEquals($Parameters, $script:fixtureParameters) | Should -BeFalse
                    $expected = $script:fixtureParameters.Clone()
                    $expected.tenant = 'worker-a'
                    ($Parameters | ConvertTo-Json -Depth 5) | Should -Be ($expected | ConvertTo-Json -Depth 5)
                    $discoveryDatabase = ($script:fixtureTenants |
                        Where-Object Id -eq $Parameters.tenant).DatabaseName
                    $script:fixtures[$discoveryDatabase] = 'discovery-dirty'
                    if ($script:discoveryThrows) {
                        throw 'discovery failed'
                    }
                    $script:fixtureWorkItems
                }
                Mock Reset-BcTestTenant {
                    $Tenant | Should -Not -Be 'primary'
                    $TenantDatabaseName | Should -Not -Be 'primary-db'
                    $script:fixtureEvents.Add("restore:${Tenant}:$TemplateDatabaseName")
                    $script:fixtures[$TenantDatabaseName] = $script:fixtures[$TemplateDatabaseName]
                }
                Mock New-BcTestTenantTemplate {
                    $SourceDatabaseName | Should -Be 'primary-db'
                    $script:fixtures['primary-db'] | Should -Be 'pristine'
                    $script:fixtures['worker-a-db'] | Should -Be 'pristine'
                    $script:fixtureEvents.Add("template:$SourceDatabaseName")
                    $script:fixtures['template-db'] = $script:fixtures[$SourceDatabaseName]
                    'template-db'
                }
                Mock Invoke-RequiredDisabledTestExecution {
                    $script:fixtureEvents.Add('clean')
                    $script:fixtures['primary-db'] | Should -Be 'pristine'
                    foreach ($worker in $TenantInfo) {
                        $script:fixtures[$worker.DatabaseName] = 'clean-dirty'
                    }
                    if ($script:cleanThrows) {
                        throw 'clean execution failed'
                    }
                    $script:cleanPassed
                }
                Mock Invoke-WarmupDispatch {
                    $script:fixtureEvents.Add('warmup')
                    @($Pending)
                }
                Mock Get-AppRerunBudget { 0 }
                Mock Wait-ForFreeTenant { 'primary' }
                Mock Start-TestAppDispatch {
                    $script:fixtureEvents.Add("ordinary:$Tenant")
                    foreach ($info in $script:fixtureTenants) {
                        $script:fixtures[$info.DatabaseName] | Should -Be 'pristine'
                    }
                }
                Mock Wait-ForAllTestJobs { $true }
                Mock Merge-TenantTestResults { }
                Mock Remove-BcTestTenantTemplate {
                    $script:fixtureEvents.Add('remove-template')
                }
            }
        }

        It "preserves ordinary <Lane> execution when clean-codeunit activation is <Activation>" -ForEach @(
            @{ Lane = 'IntegrationTest'; Activation = 'absent'; Enabled = $null }
            @{ Lane = 'IntegrationTest'; Activation = 'false'; Enabled = $false }
            @{ Lane = 'UnitTest'; Activation = 'absent'; Enabled = $null }
            @{ Lane = 'UnitTest'; Activation = 'false'; Enabled = $false }
            @{ Lane = 'Legacy'; Activation = 'absent'; Enabled = $null }
            @{ Lane = 'Legacy'; Activation = 'false'; Enabled = $false }
        ) {
            InModuleScope ParallelTestExecution -Parameters @{ Lane = $Lane; Enabled = $Enabled } {
                $script:activationUnderTest = $Enabled
                Mock Get-ALGoSetting { $script:activationUnderTest } -ParameterFilter {
                    $Key -eq 'enableCleanTestCodeunitExecution'
                }
                Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                    -testType $Lane -appNamesToTest @('Tests') | Should -BeTrue

                $script:fixtureEvents | Should -Be @('warmup', 'ordinary:primary')
                Should -Invoke Get-RequiredDisabledWorkItems -Times 0
                Should -Invoke Reset-BcTestTenant -Times 0
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-RequiredDisabledTestExecution -Times 0
                Should -Invoke Invoke-WarmupDispatch -Times 1 -Exactly -ParameterFilter {
                    $CleanTenantAppNames.Count -eq 0
                }
                Should -Invoke Start-TestAppDispatch -Times 1 -Exactly -ParameterFilter {
                    -not $SkipAutomaticDisabledPass
                }
                ($script:fixtureParameters | ConvertTo-Json -Depth 5) | Should -Be $script:originalFixtureParameters
            }
        }

        It "restores secondary discovery before copying the pristine primary and dispatching tests" {
            InModuleScope ParallelTestExecution {
                Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                    -testType 'UnitTest' -appNamesToTest @('Tests') | Should -BeTrue

                $script:fixtureEvents | Should -Be @(
                    'discover:worker-a', 'restore:worker-a:primary-db', 'template:primary-db', 'clean',
                    'restore:worker-a:template-db', 'restore:worker-b:template-db',
                    'warmup', 'ordinary:primary', 'remove-template'
                )
                $script:fixtures['template-db'] | Should -Be 'pristine'
                ($script:fixtureParameters | ConvertTo-Json -Depth 5) | Should -Be $script:originalFixtureParameters
                Should -Invoke Get-RequiredDisabledWorkItems -Times 1 -Exactly -ParameterFilter {
                    $Parameters.tenant -eq 'worker-a' -and $TestType -eq 'UnitTest' -and
                    $AppNamesToTest.Count -eq 1 -and $AppIdByName.Tests -eq 'tests-id'
                }
                Should -Invoke Invoke-WarmupDispatch -Times 1 -Exactly -ParameterFilter {
                    $CleanTenantAppNames.Count -eq 1 -and $CleanTenantAppNames[0] -eq 'Tests'
                }
                Should -Invoke Start-TestAppDispatch -Times 1 -Exactly -ParameterFilter {
                    $SkipAutomaticDisabledPass
                }
                Should -Invoke Invoke-ScriptInBcContainer -Times 0
            }
        }

        It "restores discovery even when there are no clean work items without creating a template" {
            InModuleScope ParallelTestExecution {
                $script:fixtureWorkItems = @()
                Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                    -testType 'IntegrationTest' -appNamesToTest @('Tests') | Should -BeTrue

                $script:fixtureEvents | Should -Be @(
                    'discover:worker-a', 'restore:worker-a:primary-db', 'warmup', 'ordinary:primary'
                )
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-RequiredDisabledTestExecution -Times 0
                ($script:fixtureParameters | ConvertTo-Json -Depth 5) | Should -Be $script:originalFixtureParameters
            }
        }

        It "restores discovery after an exception without copying or dispatching tainted fixtures" {
            InModuleScope ParallelTestExecution {
                $script:discoveryThrows = $true
                {
                    Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                        -testType 'IntegrationTest' -appNamesToTest @('Tests')
                } | Should -Throw '*discovery failed*'

                $script:fixtureEvents | Should -Be @('discover:worker-a', 'restore:worker-a:primary-db')
                $script:fixtures['primary-db'] | Should -Be 'pristine'
                $script:fixtures['worker-a-db'] | Should -Be 'pristine'
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-RequiredDisabledTestExecution -Times 0
                Should -Invoke Invoke-WarmupDispatch -Times 0
                ($script:fixtureParameters | ConvertTo-Json -Depth 5) | Should -Be $script:originalFixtureParameters
            }
        }

        It "stops before template creation or dispatch when restoring discovery fails" {
            InModuleScope ParallelTestExecution {
                Mock Reset-BcTestTenant { throw 'discovery restore failed' }
                {
                    Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                        -testType 'IntegrationTest' -appNamesToTest @('Tests')
                } | Should -Throw '*discovery restore failed*'

                Should -Invoke Reset-BcTestTenant -Times 1 -Exactly
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-RequiredDisabledTestExecution -Times 0
                Should -Invoke Invoke-WarmupDispatch -Times 0
                ($script:fixtureParameters | ConvertTo-Json -Depth 5) | Should -Be $script:originalFixtureParameters
            }
        }

        It "restores every clean worker and removes the template when clean execution throws" {
            InModuleScope ParallelTestExecution {
                $script:cleanThrows = $true
                {
                    Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                        -testType 'IntegrationTest' -appNamesToTest @('Tests')
                } | Should -Throw '*clean execution failed*'

                $script:fixtureEvents | Should -Be @(
                    'discover:worker-a', 'restore:worker-a:primary-db', 'template:primary-db', 'clean',
                    'restore:worker-a:template-db', 'restore:worker-b:template-db', 'remove-template'
                )
                $script:fixtures['worker-a-db'] | Should -Be 'pristine'
                $script:fixtures['worker-b-db'] | Should -Be 'pristine'
                Should -Invoke Invoke-WarmupDispatch -Times 0
                Should -Invoke Invoke-ScriptInBcContainer -Times 0
            }
        }

        It "restores every clean worker while retaining a failed test result" {
            InModuleScope ParallelTestExecution {
                $script:cleanPassed = $false
                Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                    -testType 'IntegrationTest' -appNamesToTest @('Tests') | Should -BeFalse

                $script:fixtures['worker-a-db'] | Should -Be 'pristine'
                $script:fixtures['worker-b-db'] | Should -Be 'pristine'
                $script:fixtureEvents.IndexOf('ordinary:primary') |
                    Should -BeGreaterThan $script:fixtureEvents.IndexOf('restore:worker-b:template-db')
                Should -Invoke Remove-BcTestTenantTemplate -Times 1 -Exactly
            }
        }

        It "keeps Legacy discovery on the original parameters without copying or resetting tenants" {
            InModuleScope ParallelTestExecution {
                Mock Get-RequiredDisabledWorkItems {
                    [object]::ReferenceEquals($Parameters, $script:fixtureParameters) | Should -BeTrue
                    $TestType | Should -Be 'Legacy'
                    @()
                }
                Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                    -testType 'Legacy' -appNamesToTest @('Tests') | Should -BeTrue

                Should -Invoke Get-RequiredDisabledWorkItems -Times 1 -Exactly
                Should -Invoke Reset-BcTestTenant -Times 0
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-RequiredDisabledTestExecution -Times 0
                ($script:fixtureParameters | ConvertTo-Json -Depth 5) | Should -Be $script:originalFixtureParameters
            }
        }

        It "preserves single-tenant discovery and ordinary execution without clean work items" {
            InModuleScope ParallelTestExecution {
                $script:fixtureTenants = @($script:fixtureTenants | Where-Object Id -eq 'primary')
                Mock Get-RequiredDisabledWorkItems {
                    [object]::ReferenceEquals($Parameters, $script:fixtureParameters) | Should -BeTrue
                    @()
                }
                Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                    -testType 'IntegrationTest' -appNamesToTest @('Tests') | Should -BeTrue

                Should -Invoke Get-RequiredDisabledWorkItems -Times 1 -Exactly
                Should -Invoke Reset-BcTestTenant -Times 0
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Start-TestAppDispatch -Times 1 -Exactly
            }
        }

        It "retains the single-tenant error when clean work items are discovered" {
            InModuleScope ParallelTestExecution {
                $script:fixtureTenants = @($script:fixtureTenants | Where-Object Id -eq 'primary')
                Mock Get-RequiredDisabledWorkItems { $script:fixtureWorkItems }
                {
                    Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                        -testType 'IntegrationTest' -appNamesToTest @('Tests')
                } | Should -Throw '*at least one secondary tenant*'

                Should -Invoke Reset-BcTestTenant -Times 0
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-WarmupDispatch -Times 0
            }
        }

        It "rejects unsafe tenant metadata before discovery: <Fault>" -ForEach @(
            @{ Fault = 'missing primary'; MessagePattern = '*source tenant*' }
            @{ Fault = 'blank primary database'; MessagePattern = '*source tenant*' }
            @{ Fault = 'blank worker ID'; MessagePattern = '*unique tenant IDs and database names*' }
            @{ Fault = 'blank worker database'; MessagePattern = '*unique tenant IDs and database names*' }
            @{ Fault = 'duplicate worker ID'; MessagePattern = '*unique tenant IDs and database names*' }
            @{ Fault = 'duplicate worker database'; MessagePattern = '*unique tenant IDs and database names*' }
            @{ Fault = 'worker aliases primary database'; MessagePattern = '*unique tenant IDs and database names*' }
            @{ Fault = 'duplicate primary ID'; MessagePattern = '*source tenant*' }
        ) {
            InModuleScope ParallelTestExecution -Parameters @{ Fault = $Fault; ExpectedError = $MessagePattern } {
                param($Fault, $ExpectedError)

                switch ($Fault) {
                    'missing primary' { $script:fixtureParameters.tenant = 'missing' }
                    'blank primary database' { $script:fixtureTenants[1].DatabaseName = ' ' }
                    'blank worker ID' { $script:fixtureTenants[0].Id = ' ' }
                    'blank worker database' { $script:fixtureTenants[0].DatabaseName = ' ' }
                    'duplicate worker ID' { $script:fixtureTenants[2].Id = 'WORKER-A' }
                    'duplicate worker database' { $script:fixtureTenants[2].DatabaseName = 'WORKER-A-DB' }
                    'worker aliases primary database' { $script:fixtureTenants[0].DatabaseName = 'PRIMARY-DB' }
                    'duplicate primary ID' { $script:fixtureTenants[2].Id = 'PRIMARY' }
                }
                {
                    Invoke-ParallelTestExecution -parameters $script:fixtureParameters -scriptPath 'unused.ps1' `
                        -testType 'IntegrationTest' -appNamesToTest @('Tests')
                } | Should -Throw $ExpectedError

                Should -Invoke Get-RequiredDisabledWorkItems -Times 0
                Should -Invoke Reset-BcTestTenant -Times 0
                Should -Invoke New-BcTestTenantTemplate -Times 0
                Should -Invoke Invoke-WarmupDispatch -Times 0
                Should -Invoke Invoke-ScriptInBcContainer -Times 0
            }
        }
    }

    It "contains no Task Scheduler override or server restart commands" {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Get-Module ParallelTestExecution).Path, [ref]$tokens, [ref]$parseErrors)
        $parseErrors.Count | Should -Be 0
        $overrides = @($ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.GetCommandName() -in @(
                'Set-NAVServerConfiguration', 'Set-NAVServerInstance',
                'Set-BcTestTaskScheduler', 'Enable-BcTestTaskScheduler', 'Disable-BcTestTaskScheduler'
            )
        }, $true))
        $overrides.Count | Should -Be 0
    }
}

Describe "RunTestsInBcContainer platform-race transcript classification" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
        function Run-TestsInBcContainer {
            param([string]$appName, [string]$tenant)
            $null = $appName, $tenant
            throw 'Container test execution must be mocked.'
        }
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $PSScriptRoot '../RunTestsInBcContainer.ps1'), [ref]$tokens, [ref]$parseErrors)
        $parseErrors.Count | Should -Be 0
        $function = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Invoke-RunTestsWithCancellationDetection'
        }, $true)
        . ([scriptblock]::Create($function.Extent.Text))
    }

    BeforeEach {
        $script:transcriptPath = $null
        Mock Start-Transcript {
            $script:transcriptPath = $Path
            Set-Content -LiteralPath $Path -Value $script:transcript
        }
        Mock Stop-Transcript {}
        Mock Run-TestsInBcContainer { $false }
        Mock Write-Host {}
    }

    AfterEach {
        $script:transcriptPath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $script:transcriptPath | Should -BeFalse
    }

    It "does not emit a platform marker for an ordinary API failure or unrelated page mention" -ForEach @(
        @{ Transcript = 'GET request failed. Response code is 500 (InternalServerError), expected code is 200. Error message: Object reference not set to an instance of an object.' }
        @{ Transcript = "Opened page 130455 successfully.`nGET request failed. Response code is 500 (InternalServerError), expected code is 200. Error message: Object reference not set to an instance of an object." }
        @{ Transcript = 'Assertion failed: expected 2 but was 1' }
    ) {
        $script:transcript = $Transcript
        Invoke-RunTestsWithCancellationDetection -parameters @{ appName = 'API Tests'; tenant = 'default' } |
            Should -BeFalse
        Should -Invoke Write-Host -Times 0 -ParameterFilter { $Object -like '*TRANSIENT TEST PLATFORM RACE*' }
    }

    It "emits the platform marker for established runtime races" -ForEach @(
        @{ Transcript = 'Cannot open page 130455' }
        @{ Transcript = 'InvokeInteractions failed with status code 500' }
        @{ Transcript = 'at InteractionManager.InvokeInteractions in InteractionManager.cs:line 203' }
        @{ Transcript = "ObjName:Command Line Test Tool, ObjID:130455, Type:Form, MethodName:ExtensionId_a45_OnValidate`nOffset and length were out of bounds for the array" }
        @{ Transcript = "ObjName:Command Line Test Tool, ObjID:130455, Type:Form, MethodName:ExtensionId_a45_OnValidate`nNullable object must have a value." }
    ) {
        $script:transcript = $Transcript
        Invoke-RunTestsWithCancellationDetection -parameters @{ appName = 'API Tests'; tenant = 'default' } |
            Should -BeFalse
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*TRANSIENT TEST PLATFORM RACE*' }
    }
}

Describe "ParallelTestExecution warmup dispatch" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "defers the Disabled pass when the warmup app uses clean-codeunit execution" {
        InModuleScope ParallelTestExecution {
            $script:skipDisabledPass = $false
            Mock Start-TestAppDispatch {
                $script:skipDisabledPass = $SkipAutomaticDisabledPass.IsPresent
            }
            Mock Wait-ForAllTestJobs { }

            $state = [PSCustomObject]@{ jobs = @(); hasFailures = $false; transient = @(); retried = @{} }
            $result = Invoke-WarmupDispatch -Parameters @{ containerName = 'c' } `
                -Pending @('API Tests', 'Other Tests') `
                -AppIdByName @{ 'API Tests' = 'api-id'; 'Other Tests' = 'other-id' } `
                -Tenants @('default', 'tenant2') -ScriptPath 'unused.ps1' -TestType 'UnitTest' `
                -State $state -CleanTenantAppNames @('API Tests')

            $result | Should -Be @('Other Tests')
            $script:skipDisabledPass | Should -BeTrue
        }
    }

    It "dispatches the first app alone and awaits it before fanning out the rest" {
        # The first app must run alone and be awaited before any parallel dispatch. This asserts
        # exactly that ordering: dispatch(first) -> wait -> rest.
        InModuleScope ParallelTestExecution {
            $script:events = [System.Collections.Generic.List[string]]::new()

            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @('Big', 'Medium', 'Small') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Wait-ForFreeTenant { 'tenant2' }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Merge-TenantTestResults { }
            Mock Start-TestAppDispatch { $script:events.Add("dispatch:$AppName") }
            Mock Wait-ForAllTestJobs { $script:events.Add('wait'); $true }

            $params = @{ containerName = "ut-$([guid]::NewGuid().ToString('N'))"; tenant = 'default' }
            $null = Invoke-ParallelTestExecution -parameters $params -scriptPath 'unused.ps1' `
                -testType 'Legacy' -appNamesToTest @('Big', 'Medium', 'Small')

            # First app dispatched alone, then awaited, before any other app is dispatched.
            $script:events[0] | Should -Be 'dispatch:Big'
            $script:events[1] | Should -Be 'wait'
            $waitIndex = $script:events.IndexOf('wait')
            $script:events.IndexOf('dispatch:Medium') | Should -BeGreaterThan $waitIndex
            $script:events.IndexOf('dispatch:Small')  | Should -BeGreaterThan $waitIndex
        }
    }

    It "skips the warmup dispatch when only one tenant is available" {
        InModuleScope ParallelTestExecution {
            $script:events = [System.Collections.Generic.List[string]]::new()

            Mock Get-AvailableBcTenantInfo {
                @([PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' })
            }
            Mock Get-BcContainerAppInfo {
                @('Big', 'Medium') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Merge-TenantTestResults { }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Start-TestAppDispatch { $script:events.Add("dispatch:$AppName") }
            Mock Wait-ForAllTestJobs { $script:events.Add('wait'); $true }

            $params = @{ containerName = "ut-$([guid]::NewGuid().ToString('N'))"; tenant = 'default' }
            $null = Invoke-ParallelTestExecution -parameters $params -scriptPath 'unused.ps1' `
                -testType 'Legacy' -appNamesToTest @('Big', 'Medium')

            # No warmup dispatch: the two apps are dispatched by the normal loop with no leading
            # solo dispatch+await. (Start-TestAppDispatch is mocked so no jobs accumulate, hence
            # the loop's terminal Wait-ForAllTestJobs is not reached.)
            $script:events | Should -Be @('dispatch:Big', 'dispatch:Medium')
            $script:events | Should -Not -Contain 'wait'
        }
    }

    It "returns the pending list unchanged when there is a single tenant" {
        InModuleScope ParallelTestExecution {
            $state = [PSCustomObject]@{ jobs = @(); hasFailures = $false; transient = @(); retried = @{} }
            $result = Invoke-WarmupDispatch -Parameters @{ containerName = 'c' } `
                -Pending @('A', 'B', 'C') -AppIdByName @{ A = 'id-A'; B = 'id-B'; C = 'id-C' } `
                -Tenants @('default') -ScriptPath 'unused.ps1' -TestType 'Legacy' -State $state
            $result | Should -Be @('A', 'B', 'C')
        }
    }

    It "returns the pending list unchanged when there is a single app" {
        InModuleScope ParallelTestExecution {
            Mock Start-TestAppDispatch { }
            Mock Wait-ForAllTestJobs { $true }
            $state = [PSCustomObject]@{ jobs = @(); hasFailures = $false; transient = @(); retried = @{} }
            $result = Invoke-WarmupDispatch -Parameters @{ containerName = 'c' } `
                -Pending @('Only') -AppIdByName @{ Only = 'id-Only' } `
                -Tenants @('default', 'tenant2') -ScriptPath 'unused.ps1' -TestType 'Legacy' -State $state
            $result | Should -Be @('Only')
            Should -Invoke Start-TestAppDispatch -Times 0
        }
    }

    It "warms up the first app and returns the remaining apps" {
        InModuleScope ParallelTestExecution {
            Mock Start-TestAppDispatch { }
            Mock Wait-ForAllTestJobs { $true }
            $state = [PSCustomObject]@{ jobs = @(); hasFailures = $false; transient = @(); retried = @{} }
            $result = Invoke-WarmupDispatch -Parameters @{ containerName = 'c' } `
                -Pending @('A', 'B', 'C') -AppIdByName @{ A = 'id-A'; B = 'id-B'; C = 'id-C' } `
                -Tenants @('default', 'tenant2') -ScriptPath 'unused.ps1' -TestType 'Legacy' -State $state
            $result | Should -Be @('B', 'C')
            Should -Invoke Start-TestAppDispatch -Times 1
        }
    }

    It "leaves a transient warmup failure in State.transient for the caller to re-queue" {
        InModuleScope ParallelTestExecution {
            Mock Start-TestAppDispatch { }
            # Simulate Wait-ForAllTestJobs classifying the warmup app as a transient race.
            Mock Wait-ForAllTestJobs {
                $State.transient = @([PSCustomObject]@{ Key = 'A'; Tenant = 'default' })
            }
            $state = [PSCustomObject]@{ jobs = @(); hasFailures = $false; transient = @(); retried = @{} }
            $result = Invoke-WarmupDispatch -Parameters @{ containerName = 'c' } `
                -Pending @('A', 'B', 'C') -AppIdByName @{ A = 'id-A'; B = 'id-B'; C = 'id-C' } `
                -Tenants @('default', 'tenant2') -ScriptPath 'unused.ps1' -TestType 'Legacy' -State $state
            $result | Should -Be @('B', 'C')
            $state.transient.Key | Should -Contain 'A'
            $state.hasFailures | Should -BeFalse
        }
    }
}

Describe "ParallelTestExecution failed-app rerun scheduling" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "re-runs a failed <Lane> app on a different tenant with clean activation <Enabled>" -ForEach @(
        @{ Lane = 'Legacy'; Enabled = $false }
        @{ Lane = 'UnitTest'; Enabled = $false }
        @{ Lane = 'UnitTest'; Enabled = $true }
    ) {
        # A failed app is retried once, and never on the tenant it failed on: tests are not
        # guaranteed to clean up after themselves, so residue from the failed run could
        # re-trigger the same failure and make the retry worthless.
        InModuleScope ParallelTestExecution -Parameters @{ Lane = $Lane; Enabled = $Enabled } {
            $script:activationUnderTest = $Enabled
            Mock Get-ALGoSetting { $script:activationUnderTest } -ParameterFilter {
                $Key -eq 'enableCleanTestCodeunitExecution'
            }
            Mock Reset-BcTestTenant { }
            $script:dispatched = [System.Collections.Generic.List[object]]::new()
            $script:failed = $false

            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @('Big', 'Small') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Invoke-WarmupDispatch { @($Pending) }
            Mock Get-AppRerunBudget { 1 }
            Mock Wait-ForAllTestJobs { $true }
            Mock Merge-TenantTestResults { }
            Mock Wait-ForFreeTenant {
                # 'default' is always free; the exclusion must push the rerun onto 'tenant2'.
                @('default', 'tenant2') | Where-Object { $_ -ne $excludeTenant } | Select-Object -First 1
            }
            Mock Start-TestAppDispatch {
                $script:dispatched.Add([PSCustomObject]@{
                    App = $AppName
                    Tenant = $Tenant
                    Suffix = $FileSuffix
                    SkipDisabled = $SkipAutomaticDisabledPass.IsPresent
                })
                # 'Big' fails on its first dispatch, exactly once.
                if ($AppName -eq 'Big' -and -not $script:failed) {
                    $script:failed = $true
                    Register-TestJobOutcome -State $State -Result ([PSCustomObject]@{
                        Outcome = 'Failed'; AppName = $AppName; Tenant = $Tenant; JobState = 'Failed'
                    })
                }
            }

            $params = @{ containerName = "ut-$([guid]::NewGuid().ToString('N'))"; tenant = 'default' }
            $result = Invoke-ParallelTestExecution -parameters $params -scriptPath 'unused.ps1' `
                -testType $Lane -appNamesToTest @('Big', 'Small')

            $rerun = $script:dispatched | Where-Object { $_.Suffix }
            $rerun.App | Should -Be 'Big'
            $rerun.Tenant | Should -Be 'tenant2'
            $rerun.Suffix | Should -Be 'rerun1'
            $rerun.SkipDisabled | Should -Be $Enabled
            # The rerun passed, so the run as a whole passed.
            $result | Should -BeTrue
        }
    }

    It "fails the run when the rerun budget is already spent" {
        InModuleScope ParallelTestExecution {
            $state = [PSCustomObject]@{
                hasFailures = $false; transient = @(); rerun = @(); rerunDone = @{}
                rerunBudget = 1; tenantCount = 4
            }
            $failure = [PSCustomObject]@{ Outcome = 'Failed'; AppName = 'A'; Tenant = 'default'; JobState = 'Failed' }

            Register-TestJobOutcome -Result $failure -State $state
            $state.rerun.Count | Should -Be 1
            $state.hasFailures | Should -BeFalse

            # Budget is spent, so a second failing app is final.
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                Outcome = 'Failed'; AppName = 'B'; Tenant = 'tenant2'; JobState = 'Failed'
            })
            $state.rerun.Count | Should -Be 1
            $state.hasFailures | Should -BeTrue
        }
    }

    It "does not re-run an app that already had its rerun" {
        InModuleScope ParallelTestExecution {
            $state = [PSCustomObject]@{
                hasFailures = $false; transient = @(); rerun = @(); rerunDone = @{ A = $true }
                rerunBudget = 1; tenantCount = 4
            }
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                Outcome = 'Failed'; AppName = 'A'; Tenant = 'tenant2'; JobState = 'Failed'
            })
            $state.rerun.Count | Should -Be 0
            $state.hasFailures | Should -BeTrue
        }
    }

    It "does not re-run when there is only one tenant, since a different one cannot be used" {
        InModuleScope ParallelTestExecution {
            $state = [PSCustomObject]@{
                hasFailures = $false; transient = @(); rerun = @(); rerunDone = @{}
                rerunBudget = 1; tenantCount = 1
            }
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                Outcome = 'Failed'; AppName = 'A'; Tenant = 'default'; JobState = 'Failed'
            })
            $state.rerun.Count | Should -Be 0
            $state.hasFailures | Should -BeTrue
        }
    }
}

Describe "ParallelTestExecution rerun budget is limited to pull request builds" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    BeforeEach {
        $script:savedEvent = $env:GITHUB_EVENT_NAME
        $script:savedSettings = $env:settings
        # Get-ALGoSetting reads the merged AL-Go settings out of $env:settings.
        $env:settings = '{ "maxTestAppReruns": 2 }'
    }

    AfterEach {
        $env:GITHUB_EVENT_NAME = $script:savedEvent
        $env:settings = $script:savedSettings
    }

    It "grants the configured budget on pull request builds" {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        Get-AppRerunBudget | Should -Be 2
    }

    It "grants no rerun budget on push (CI/CD) builds even when the setting is present" {
        # CI/CD runs are the signal for the real state of the branch and feed the unstable-tests
        # data, so a failure there must stay a failure.
        $env:GITHUB_EVENT_NAME = 'push'
        Get-AppRerunBudget | Should -Be 0
    }

    It "grants no rerun budget for schedule, merge_group or workflow_dispatch builds" {
        foreach ($evt in @('schedule', 'merge_group', 'workflow_dispatch')) {
            $env:GITHUB_EVENT_NAME = $evt
            Get-AppRerunBudget | Should -Be 0
        }
    }

    It "grants no rerun budget outside of GitHub Actions" {
        $env:GITHUB_EVENT_NAME = $null
        Get-AppRerunBudget | Should -Be 0
    }

    It "grants no rerun budget when the setting is missing" {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        $env:settings = '{ }'
        Get-AppRerunBudget | Should -Be 0
    }

    It "honours a budget of 0 as a way to switch reruns off" {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        $env:settings = '{ "maxTestAppReruns": 0 }'
        Get-AppRerunBudget | Should -Be 0
    }

    It "re-runs several different apps up to the configured budget" {
        # The budget caps how many DIFFERENT apps may be re-run; an individual app is still only
        # ever re-run once.
        $env:GITHUB_EVENT_NAME = 'pull_request'
        InModuleScope ParallelTestExecution {
            $state = [PSCustomObject]@{
                hasFailures = $false; transient = @(); rerun = @(); rerunDone = @{}
                rerunBudget = 2; tenantCount = 4
            }
            foreach ($app in @('A', 'B')) {
                Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                    Outcome = 'Failed'; AppName = $app; Tenant = 'tenant2'; JobState = 'Failed'
                })
            }
            $state.rerun.Count | Should -Be 2
            $state.rerun.suffix | Should -Be @('rerun1', 'rerun2')
            $state.hasFailures | Should -BeFalse

            # Budget spent: a third app is a final failure.
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                Outcome = 'Failed'; AppName = 'C'; Tenant = 'tenant3'; JobState = 'Failed'
            })
            $state.rerun.Count | Should -Be 2
            $state.hasFailures | Should -BeTrue
        }
    }

    It "discards a stale rerun result file when the rerun is re-dispatched after a transient race" {
        # Sequence: app fails -> rerun on another tenant -> that rerun hits the platform race ->
        # app is re-dispatched through the NORMAL queue, writing to a tenant file. Tenant files
        # merge before rerun files, so the stale rerun file would otherwise overwrite the newer
        # (passing) result and report a passing app as failed.
        $env:GITHUB_EVENT_NAME = 'pull_request'
        InModuleScope ParallelTestExecution {
            $dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $dir | Out-Null
            try {
                $params = @{
                    containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                    tenant = 'default'
                    JUnitResultFileName = (Join-Path $dir 'results.xml')
                }
                $staleFile = Join-Path $dir 'results-rerun1.xml'
                Set-Content -Path $staleFile -Value '<testsuites />'

                $script:raced = $false
                Mock Get-AvailableBcTenantInfo {
                    @(
                        [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                        [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                    )
                }
                Mock Get-BcContainerAppInfo { @([PSCustomObject]@{ IsInstalled = $true; Name = 'A'; AppId = 'id-A' }) }
                Mock Invoke-WarmupDispatch { @($Pending) }
                Mock Wait-ForAllTestJobs { }
                Mock Merge-TenantTestResults { }
                Mock Wait-ForFreeTenant { 'tenant2' }
                Mock Start-TestAppDispatch {
                    if ($FileSuffix -and -not $script:raced) {
                        # The rerun job hits the platform race.
                        $script:raced = $true
                        $State.transient = @($State.transient) + @(
                            [PSCustomObject]@{ Key = $AppName; Tenant = $Tenant }
                        )
                    }
                }
                # Pre-seed the state as though 'A' already had its rerun dispatched.
                Mock Register-TestJobOutcome { }

                $state = [PSCustomObject]@{
                    jobs = @(); hasFailures = $false; transient = @(); retried = @{}
                    rerun = @(); rerunDone = @{}; rerunBudget = 1; tenantCount = 2
                }
                $state.rerunDone['A'] = 'rerun1'
                $state.transient = @([PSCustomObject]@{ Key = 'A'; Tenant = 'tenant2' })

                # Exercise just the promotion path the loop performs.
                foreach ($transient in @($state.transient)) {
                    $appName = $transient.Key
                    if ($state.rerunDone.ContainsKey($appName)) {
                        Remove-RerunResultFile -parameters $params -suffix $state.rerunDone[$appName]
                    }
                }

                Test-Path $staleFile | Should -BeFalse
            }
            finally {
                Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "records the rerun suffix so a stale rerun file can be found later" {
        InModuleScope ParallelTestExecution {
            $state = [PSCustomObject]@{
                hasFailures = $false; transient = @(); rerun = @(); rerunDone = @{}
                rerunBudget = 2; tenantCount = 4
            }
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                Outcome = 'Failed'; AppName = 'A'; Tenant = 'tenant2'; JobState = 'Failed'
            })
            Register-TestJobOutcome -State $state -Result ([PSCustomObject]@{
                Outcome = 'Failed'; AppName = 'B'; Tenant = 'tenant3'; JobState = 'Failed'
            })
            $state.rerunDone['A'] | Should -Be 'rerun1'
            $state.rerunDone['B'] | Should -Be 'rerun2'
            $state.rerun.suffix | Should -Be @('rerun1', 'rerun2')
        }
    }

    It "does not re-dispatch a failed app on a CI/CD build" {
        # End-to-end guard: the budget gate must actually suppress the rerun dispatch, not just
        # return 0 from the helper.
        $env:GITHUB_EVENT_NAME = 'push'
        InModuleScope ParallelTestExecution {
            $script:dispatched = [System.Collections.Generic.List[object]]::new()
            $script:failed = $false

            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @('Big', 'Small') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Invoke-WarmupDispatch { @($Pending) }
            Mock Wait-ForAllTestJobs { $true }
            Mock Get-RequiredDisabledWorkItems { @() }
            Mock Merge-TenantTestResults { }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch {
                $script:dispatched.Add($AppName)
                if ($AppName -eq 'Big' -and -not $script:failed) {
                    $script:failed = $true
                    Register-TestJobOutcome -State $State -Result ([PSCustomObject]@{
                        Outcome = 'Failed'; AppName = $AppName; Tenant = $Tenant; JobState = 'Failed'
                    })
                }
            }

            $params = @{ containerName = "ut-$([guid]::NewGuid().ToString('N'))"; tenant = 'default' }
            $result = Invoke-ParallelTestExecution -parameters $params -scriptPath 'unused.ps1' `
                -testType 'Legacy' -appNamesToTest @('Big', 'Small')

            # Each app dispatched exactly once, and the failure is final.
            $script:dispatched | Should -Be @('Big', 'Small')
            $result | Should -BeFalse
        }
    }
}

Describe "ParallelTestExecution result merging" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force

        function New-JUnitFile {
            param([string]$Path, [string]$SuiteName, [int]$Failures)
            @"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="$SuiteName" tests="1" failures="$Failures" />
</testsuites>
"@ | Set-Content -Path $Path -Encoding UTF8
        }
    }

    It "lets a rerun's results replace those of the run it re-ran" {
        # The rerun runs the whole app again on another tenant and writes its own file. Without
        # replace-by-name the merged report would contain the app twice - once failed, once
        # passed - and the failed copy would fail the build.
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir | Out-Null
        try {
            $failedRun = Join-Path $dir 'results-tenant2.xml'
            $rerun = Join-Path $dir 'results-rerun1.xml'
            $target = Join-Path $dir 'results.xml'

            New-JUnitFile -Path $failedRun -SuiteName '134000 Some Codeunit' -Failures 1
            New-JUnitFile -Path $rerun -SuiteName '134000 Some Codeunit' -Failures 0

            Merge-TestResultFiles -targetFile $target -sourceFiles @($failedRun, $rerun)

            $merged = [xml](Get-Content $target -Raw)
            $suites = @($merged.SelectNodes('//testsuites/testsuite'))
            $suites.Count | Should -Be 1
            $suites[0].failures | Should -Be '0'
        }
        finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps results for different codeunits side by side" {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir | Out-Null
        try {
            $first = Join-Path $dir 'results-default.xml'
            $second = Join-Path $dir 'results-tenant2.xml'
            $target = Join-Path $dir 'results.xml'

            New-JUnitFile -Path $first -SuiteName '134000 One' -Failures 0
            New-JUnitFile -Path $second -SuiteName '134001 Two' -Failures 0

            Merge-TestResultFiles -targetFile $target -sourceFiles @($first, $second)

            $merged = [xml](Get-Content $target -Raw)
            @($merged.SelectNodes('//testsuites/testsuite')).Count | Should -Be 2
        }
        finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
