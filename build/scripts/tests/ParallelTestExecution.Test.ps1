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
            Should -Invoke Remove-Job -Times 5 -Exactly
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

Describe "ParallelTestExecution disabled-test exclusions" {
    It "loads all app exclusions without consulting country settings" {
        InModuleScope ParallelTestExecution {
            $script:disabledTestRoot = Join-Path $TestDrive 'exclusions'
            Mock Get-BaseFolder { $script:disabledTestRoot }
            Mock Get-ALGoSetting { throw 'Exclusions must not depend on country settings' }
            $appFolder = Join-Path $script:disabledTestRoot 'DisabledTests\Example_Tests'
            $null = New-Item -Path $appFolder -ItemType Directory -Force
            '[{"codeunitId":500,"method":"First"}]' |
                Set-Content (Join-Path $appFolder 'first.json')
            '[{"codeunitId":501,"method":"*"}]' |
                Set-Content (Join-Path $appFolder 'second.json')

            $result = @(Get-DisabledTestsForApp -AppName 'Example Tests')

            $result.Count | Should -Be 2
            ($result | Where-Object codeunitId -eq 500).method | Should -Be 'First'
            ($result | Where-Object codeunitId -eq 501).method | Should -Be '*'
            @(Get-DisabledTestsForApp -AppName 'Other Tests').Count | Should -Be 0
            Should -Invoke Get-ALGoSetting -Times 0
        }
    }
}

Describe "ParallelTestExecution app-level phases" {
    BeforeEach {
        InModuleScope ParallelTestExecution {
            $script:dispatches = [System.Collections.Generic.List[object]]::new()
            $script:active = [System.Collections.Generic.List[int]]::new()
            $script:outcomes = @{}
            $script:attempts = @{}
            $script:testParameters = @{
                containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                tenant = 'default'
            }
            Mock Get-AvailableBcTenantInfo {
                @(
                    [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' }
                    [PSCustomObject]@{ Id = 'tenant2'; DatabaseName = 'tenant2' }
                )
            }
            Mock Get-BcContainerAppInfo {
                @('A', 'B', 'C') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Get-AppRerunBudget { 2 }
            Mock Start-Sleep {}
            Mock Write-Host {}
            Mock Merge-TenantTestResults {}
            Mock Get-TestsFromBcContainer { throw 'Discovery must not run' }
            Mock Invoke-ScriptInBcContainer { throw 'Database resets must not run' }
            Mock Start-TestJob {
                $phase = if ($parameters['requiredTestIsolation'] -eq 'Disabled') { 'Disabled' } else { 'Codeunit' }
                foreach ($id in $script:active) {
                    $script:dispatches[$id - 1].Phase | Should -Be $phase
                }
                Get-CachedTestRunResult -ContainerName $parameters.containerName | Should -BeNullOrEmpty
                $id = $script:dispatches.Count + 1
                $script:dispatches.Add([PSCustomObject]@{
                    Phase = $phase; App = $parameters.appName; Tenant = $tenant
                    Parameters = $parameters.Clone(); Suffix = $fileSuffix; TestType = $testType
                    SkipDisabled = $skipAutomaticDisabledPass.IsPresent
                })
                $script:active.Add($id)
                [PSCustomObject]@{ Id = $id }
            }
            Mock Get-Job { [PSCustomObject]@{ Id = $Id; State = 'Completed' } }
            Mock Wait-Job {} -RemoveParameterType Job
            Mock Receive-TestJobResult {
                $dispatch = $script:dispatches[$Entry.jobId - 1]
                $key = "$($dispatch.Phase):$($dispatch.App)"
                $attempt = [int]$script:attempts[$key]
                $script:attempts[$key] = $attempt + 1
                $outcome = if ($script:outcomes.ContainsKey($key) -and $attempt -lt $script:outcomes[$key].Count) {
                    $script:outcomes[$key][$attempt]
                } else { 'Passed' }
                $script:active.Remove($Entry.jobId) | Out-Null
                [PSCustomObject]@{
                    Outcome = $outcome; AppName = $Entry.appName; Tenant = $Entry.tenant; JobState = 'Completed'
                }
            }
        }
    }

    AfterEach {
        InModuleScope ParallelTestExecution {
            $tempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } elseif ($env:TEMP) { $env:TEMP } else { [IO.Path]::GetTempPath() }
            $stateFile = Join-Path $tempDir "parallelTests_$($script:testParameters.containerName).json"
            if (Test-Path $stateFile) { Remove-Item $stateFile }
            Should -Invoke Get-TestsFromBcContainer -Times 0
            Should -Invoke Invoke-ScriptInBcContainer -Times 0
        }
    }

    It "writes and reads cached state without temp environment variables" {
        InModuleScope ParallelTestExecution {
            $previousRunnerTemp = $env:RUNNER_TEMP
            $previousTemp = $env:TEMP
            $stateFile = $null
            try {
                $env:RUNNER_TEMP = $null
                $env:TEMP = $null
                $stateFile = Join-Path ([System.IO.Path]::GetTempPath()) `
                    "parallelTests_$($script:testParameters.containerName).json"

                Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                    -testType 'IntegrationTest' -appNamesToTest @('A') | Should -BeTrue

                $script:dispatches.Phase | Should -Be @('Codeunit', 'Disabled')
                Test-Path $stateFile | Should -BeTrue
                $state = Get-Content $stateFile -Raw | ConvertFrom-Json
                $state.completed | Should -BeTrue
                $state.finalResult | Should -BeTrue
                Get-CachedTestRunResult -ContainerName $script:testParameters.containerName | Should -BeTrue
            } finally {
                $env:RUNNER_TEMP = $previousRunnerTemp
                $env:TEMP = $previousTemp
                if ($stateFile -and (Test-Path $stateFile)) {
                    Remove-Item $stateFile -Force
                }
            }
        }
    }

    It "drains Codeunit work and late retries before the Disabled phase for <Lane>" -ForEach @(
        @{ Lane = 'UnitTest' }
        @{ Lane = 'IntegrationTest' }
        @{ Lane = 'Uncategorized' }
    ) {
        InModuleScope ParallelTestExecution -Parameters @{ Lane = $Lane } {
            $script:outcomes = @{ 'Codeunit:C' = @('Failed', 'Transient', 'Passed') }
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType $Lane -appNamesToTest @('A', 'B', 'C') | Should -BeTrue

            ($script:dispatches | ForEach-Object { "$($_.Phase):$($_.App)" }) |
                Should -Be @('Codeunit:A', 'Codeunit:B', 'Codeunit:C', 'Codeunit:C', 'Codeunit:C',
                    'Disabled:A', 'Disabled:B', 'Disabled:C')
            $script:dispatches[3].Tenant | Should -Not -Be $script:dispatches[2].Tenant
            $script:dispatches[4].Tenant | Should -Be $script:dispatches[3].Tenant
            foreach ($dispatch in $script:dispatches) {
                $dispatch.SkipDisabled | Should -BeTrue
                $dispatch.TestType | Should -Be $Lane
                $dispatch.Parameters.extensionId | Should -Be "id-$($dispatch.App)"
                $dispatch.Parameters.ContainsKey('testCodeunit') | Should -BeFalse
                if ($dispatch.Phase -eq 'Disabled') {
                    $dispatch.Parameters.requiredTestIsolation | Should -Be 'Disabled'
                    $dispatch.Parameters.testRunnerCodeunitId | Should -Be '130451'
                } else {
                    $dispatch.Parameters.ContainsKey('requiredTestIsolation') | Should -BeFalse
                    $dispatch.Parameters.ContainsKey('testRunnerCodeunitId') | Should -BeFalse
                }
            }
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
                $Object -eq "Starting Codeunit app-level test phase ($Lane)."
            }
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
                $Object -eq "Completed Codeunit app-level test phase ($Lane), including retries."
            }
            $script:active.Count | Should -Be 0
            Get-CachedTestRunResult -ContainerName $script:testParameters.containerName | Should -BeTrue
            Should -Invoke Merge-TenantTestResults -Times 1 -Exactly -ParameterFilter {
                ($resultSuffixes -join ',') -eq 'default,tenant2,rerun1,disabled-default,disabled-tenant2'
            }
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType $Lane -appNamesToTest @('A', 'B', 'C') | Should -BeTrue
            $script:dispatches.Count | Should -Be 8
        }
    }

    It "keeps retries phase-specific while sharing the job-wide budget" {
        InModuleScope ParallelTestExecution {
            $script:outcomes = @{
                'Codeunit:A' = @('Failed', 'Passed')
                'Disabled:A' = @('Failed', 'Transient', 'Passed')
            }
            Mock Remove-RerunResultFile {}
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType 'UnitTest' -appNamesToTest @('A') | Should -BeTrue
            ($script:dispatches | ForEach-Object { "$($_.Phase):$($_.App)" }) |
                Should -Be @('Codeunit:A', 'Codeunit:A', 'Disabled:A', 'Disabled:A', 'Disabled:A')
            Should -Invoke Remove-RerunResultFile -Times 1 -Exactly -ParameterFilter {
                $parameters.requiredTestIsolation -eq 'Disabled' -and $suffix -eq 'rerun1'
            }
            Should -Invoke Merge-TenantTestResults -Times 1 -Exactly -ParameterFilter {
                ($resultSuffixes -join ',') -eq 'default,tenant2,rerun1,disabled-default,disabled-tenant2,disabled-rerun1'
            }
        }
    }

    It "does not replenish the rerun budget at the phase barrier" {
        InModuleScope ParallelTestExecution {
            Mock Get-AppRerunBudget { 1 }
            $script:outcomes = @{ 'Codeunit:A' = @('Failed', 'Passed'); 'Disabled:A' = @('Failed') }
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType 'UnitTest' -appNamesToTest @('A') | Should -BeFalse
            $script:dispatches.Count | Should -Be 3
            Get-CachedTestRunResult -ContainerName $script:testParameters.containerName | Should -BeFalse
        }
    }

    It "retains a Codeunit failure even when the Disabled phase passes" {
        InModuleScope ParallelTestExecution {
            Mock Get-AppRerunBudget { 0 }
            $script:outcomes = @{ 'Codeunit:A' = @('Failed') }
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType 'IntegrationTest' -appNamesToTest @('A') | Should -BeFalse
            $script:dispatches.Phase | Should -Be @('Codeunit', 'Disabled')
        }
    }

    It "supports one tenant without a separate clean fixture" {
        InModuleScope ParallelTestExecution {
            Mock Get-AvailableBcTenantInfo { [PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' } }
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType 'Uncategorized' -appNamesToTest @('A', 'B') | Should -BeTrue
            $script:dispatches.Phase | Should -Be @('Codeunit', 'Codeunit', 'Disabled', 'Disabled')
        }
    }

    It "leaves Legacy on its ordinary unfiltered path" {
        InModuleScope ParallelTestExecution {
            Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                -testType 'Legacy' -appNamesToTest @('A', 'B') | Should -BeTrue
            $script:dispatches.Phase | Should -Be @('Codeunit', 'Codeunit')
        }
    }

    It "does not cache completion when Disabled dispatch throws" {
        InModuleScope ParallelTestExecution {
            Mock Start-TestJob { throw 'dispatch error' } -ParameterFilter {
                $parameters['requiredTestIsolation'] -eq 'Disabled'
            }
            {
                Invoke-ParallelTestExecution -parameters $script:testParameters -scriptPath 'unused.ps1' `
                    -testType 'UnitTest' -appNamesToTest @('A')
            } | Should -Throw '*dispatch error*'
            Get-CachedTestRunResult -ContainerName $script:testParameters.containerName | Should -BeNullOrEmpty
        }
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

    It "accepts a successful empty selection without turning execution errors into success" {
        $script:transcript = ''
        Mock Run-TestsInBcContainer { $true }
        Invoke-RunTestsWithCancellationDetection -parameters @{ appName = 'Empty'; tenant = 'default' } |
            Should -BeTrue
        Mock Run-TestsInBcContainer { throw 'selection failed' }
        Invoke-RunTestsWithCancellationDetection -parameters @{ appName = 'Empty'; tenant = 'default' } |
            Should -BeFalse
    }

    It "rejects cancellation even if BCH returns success" -ForEach @(
        @{ Transcript = 'ERROR DIALOG: unexpected client error' }
        @{ Transcript = 'The database command was cancelled' }
    ) {
        $script:transcript = $Transcript
        Mock Run-TestsInBcContainer { $true }
        Invoke-RunTestsWithCancellationDetection -parameters @{ appName = 'Tests'; tenant = 'default' } |
            Should -BeFalse
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

Describe "RunTestsInBcContainer Disabled routing" {
    BeforeAll {
        function Run-TestsInBcContainer {
            param($appName, $tenant, $extensionId, $testType, $requiredTestIsolation, $testRunnerCodeunitId, $disabledTests)
            $null = $appName, $tenant, $extensionId, $testType, $requiredTestIsolation, $testRunnerCodeunitId, $disabledTests
            throw 'Container test execution must be mocked.'
        }
        $script:runScript = Join-Path $PSScriptRoot '../RunTestsInBcContainer.ps1'
        $script:originalEvent = $env:GITHUB_EVENT_NAME
    }

    BeforeEach {
        $env:GITHUB_EVENT_NAME = 'push'
        $script:calls = [System.Collections.Generic.List[object]]::new()
        Mock Import-Module {}
        Mock Get-DisabledTestsForApp { @(@{ Codeunit = '50000'; Method = 'Excluded' }) }
        Mock Start-Transcript { Set-Content -LiteralPath $Path -Value '' }
        Mock Stop-Transcript {}
        Mock Run-TestsInBcContainer {
            $script:calls.Add(@{
                App = $appName; Type = $testType; Isolation = $requiredTestIsolation
                Runner = $testRunnerCodeunitId; Exclusions = $disabledTests
            })
            $true
        }
    }

    AfterAll {
        $env:GITHUB_EVENT_NAME = $script:originalEvent
    }

    It "runs only the requested app phase with exclusions for <Lane>" -ForEach @(
        @{ Lane = 'UnitTest' }
        @{ Lane = 'IntegrationTest' }
        @{ Lane = 'Uncategorized' }
    ) {
        foreach ($phase in @('Codeunit', 'Disabled')) {
            $params = @{ appName = 'Tests'; extensionId = 'tests-id'; tenant = 'default' }
            if ($phase -eq 'Disabled') {
                $params.requiredTestIsolation = 'Disabled'
                $params.testRunnerCodeunitId = '130451'
            }
            . $script:runScript -parameters $params -TestType $Lane -SkipAutomaticDisabledPass | Should -BeTrue
        }
        $script:calls.Count | Should -Be 2
        $script:calls[0].Isolation | Should -BeNullOrEmpty
        $script:calls[1].Isolation | Should -Be 'Disabled'
        $script:calls[1].Runner | Should -Be '130451'
        foreach ($call in $script:calls) {
            $call.Type | Should -Be $Lane
            $call.Exclusions.Count | Should -Be 1
            $call.Exclusions[0].Method | Should -Be 'Excluded'
        }
    }

    It "does not repeat an explicit Disabled UnitTest invocation even without the skip switch" {
        . $script:runScript -parameters @{
            appName = 'Tests'; tenant = 'default'; requiredTestIsolation = 'Disabled'; testRunnerCodeunitId = '130451'
        } -TestType 'UnitTest' | Should -BeTrue
        $script:calls.Count | Should -Be 1
    }

    It "preserves the sequential UnitTest fallback outside parallel execution" {
        . $script:runScript -parameters @{ appName = 'Tests'; tenant = 'default' } -TestType 'UnitTest' |
            Should -BeTrue
        $script:calls.Count | Should -Be 2
        $script:calls[1].Isolation | Should -Be 'Disabled'
    }
}

Describe "ParallelTestExecution warmup dispatch" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "defers the Disabled pass during warmup" {
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
                -State $state

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

    It "re-runs a failed <Lane> app on a different tenant" -ForEach @(
        @{ Lane = 'Legacy' }
        @{ Lane = 'UnitTest' }
        @{ Lane = 'IntegrationTest' }
        @{ Lane = 'Uncategorized' }
    ) {
        # A failed app is retried once, and never on the tenant it failed on: tests are not
        # guaranteed to clean up after themselves, so residue from the failed run could
        # re-trigger the same failure and make the retry worthless.
        InModuleScope ParallelTestExecution -Parameters @{ Lane = $Lane } {
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
            $rerun.SkipDisabled | Should -BeTrue
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

    It "separates Codeunit, Disabled and rerun files while retaining append flags" {
        InModuleScope ParallelTestExecution {
            Mock Start-Job {
                $script:jobArguments = $ArgumentList
                [PSCustomObject]@{ Id = 1 }
            }
            $params = @{
                containerName = 'c'; JUnitResultFileName = (Join-Path $TestDrive 'junit.xml')
                XUnitResultFileName = (Join-Path $TestDrive 'xunit.xml')
                AppendToJUnitResultFile = $true; AppendToXUnitResultFile = $true
            }
            foreach ($phase in @('Codeunit', 'Disabled')) {
                if ($phase -eq 'Disabled') { $params.requiredTestIsolation = 'Disabled' }
                foreach ($suffix in @('', 'rerun1')) {
                    $null = Start-TestJob -parameters $params -tenant 'tenant2' -scriptPath 'unused.ps1' `
                        -testType 'IntegrationTest' -skipAutomaticDisabledPass -fileSuffix $suffix
                    $expected = if ($suffix) { $suffix } else { 'tenant2' }
                    if ($phase -eq 'Disabled') { $expected = "disabled-$expected" }
                    $script:jobArguments[0].JUnitResultFileName | Should -Be (Join-Path $TestDrive "junit-$expected.xml")
                    $script:jobArguments[0].XUnitResultFileName | Should -Be (Join-Path $TestDrive "xunit-$expected.xml")
                    $script:jobArguments[0].AppendToJUnitResultFile | Should -BeTrue
                    $script:jobArguments[0].AppendToXUnitResultFile | Should -BeTrue
                    $script:jobArguments[4] | Should -BeTrue
                }
            }
        }
    }

    It "merges both phases and replaces only the retried codeunit for <Format>" -ForEach @(
        @{ Format = 'JUnit'; Root = 'testsuites'; Child = 'testsuite'; Key = 'JUnitResultFileName' }
        @{ Format = 'XUnit'; Root = 'assemblies'; Child = 'assembly'; Key = 'XUnitResultFileName' }
    ) {
        InModuleScope ParallelTestExecution -Parameters @{ Root = $Root; Child = $Child; Key = $Key } {
            $params = @{ $Key = (Join-Path $TestDrive 'results.xml') }
            foreach ($entry in @(
                @{ Suffix = 'default'; Name = 'Codeunit'; Failures = 0 }
                @{ Suffix = 'disabled-default'; Name = 'Disabled'; Failures = 1 }
                @{ Suffix = 'disabled-rerun1'; Name = 'Disabled'; Failures = 0 }
            )) {
                "<$Root><$Child name='$($entry.Name)' failures='$($entry.Failures)' /></$Root>" |
                    Set-Content (Join-Path $TestDrive "results-$($entry.Suffix).xml")
            }
            Merge-TenantTestResults -parameters $params -resultSuffixes @('default', 'disabled-default', 'disabled-rerun1')
            $xml = [xml](Get-Content $params[$Key] -Raw)
            $nodes = @($xml.SelectNodes("//$Root/$Child"))
            $nodes.Count | Should -Be 2
            $nodes.name | Should -Be @('Codeunit', 'Disabled')
            $nodes.failures | Should -Be @('0', '0')
            @(Get-ChildItem $TestDrive -Filter 'results-*.xml').Count | Should -Be 0
        }
    }

    It "removes only the Disabled stale rerun, leaving Codeunit results intact" {
        InModuleScope ParallelTestExecution {
            $codeunit = Join-Path $TestDrive 'results-rerun1.xml'
            $disabled = Join-Path $TestDrive 'results-disabled-rerun1.xml'
            Set-Content $codeunit '<testsuites />'
            Set-Content $disabled '<testsuites />'
            Remove-RerunResultFile -parameters @{
                JUnitResultFileName = (Join-Path $TestDrive 'results.xml'); requiredTestIsolation = 'Disabled'
            } -suffix 'rerun1'
            Test-Path $codeunit | Should -BeTrue
            Test-Path $disabled | Should -BeFalse
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
