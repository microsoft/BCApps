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

Describe "ParallelTestExecution transient retry scheduling" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
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
            Mock Get-CleanTenantTestAppNames { @() }
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

    It "discovers enabled Disabled-isolation codeunits per app" {
        InModuleScope ParallelTestExecution {
            Mock Get-ParametersForCommand { @{ containerName = 'c'; tenant = 'default' } }
            Mock Get-DisabledTestsForApp {
                @([PSCustomObject]@{ codeunitId = 999; method = 'DisabledMethod' })
            }
            Mock Get-TestsFromBcContainer {
                @([PSCustomObject]@{ Id = '500'; Name = 'API E2E'; Tests = @('Create', 'Modify') })
            }

            $result = @(
                Get-RequiredDisabledWorkItems -Parameters @{ containerName = 'c'; tenant = 'default' } `
                    -TestType 'IntegrationTest' -AppNamesToTest @('API Tests') `
                    -AppIdByName @{ 'API Tests' = 'app-id' }
            )

            $result.Count | Should -Be 1
            $result[0].CodeunitId | Should -Be '500'
            Should -Invoke Get-TestsFromBcContainer -Times 1 -ParameterFilter {
                $extensionId -eq 'app-id' -and
                $requiredTestIsolation -eq 'Disabled' -and
                $testType -eq 'IntegrationTest' -and
                $disabledTests.Count -eq 1
            }
        }
    }

    It "does not apply a test type filter to Legacy buckets" {
        InModuleScope ParallelTestExecution {
            Mock Get-ParametersForCommand { @{ containerName = 'c'; tenant = 'default'; testType = 'stale' } }
            Mock Get-DisabledTestsForApp { @() }
            Mock Get-TestsFromBcContainer { @() }

            $null = Get-RequiredDisabledWorkItems -Parameters @{ containerName = 'c' } `
                -TestType 'Legacy' -AppNamesToTest @('Legacy Tests') `
                -AppIdByName @{ 'Legacy Tests' = 'legacy-id' }

            Should -Invoke Get-TestsFromBcContainer -Times 1 -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('testType')
            }
        }
    }
}

Describe "ParallelTestExecution clean tenant scheduling" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "does not create a database template when no Disabled-isolation codeunits are enabled" {
        InModuleScope ParallelTestExecution {
            Mock Get-AvailableBcTenantInfo {
                @([PSCustomObject]@{ Id = 'default'; DatabaseName = 'default' })
            }
            Mock Get-BcContainerAppInfo {
                @([PSCustomObject]@{ IsInstalled = $true; Name = 'Tests'; AppId = 'tests-id' })
            }
            Mock Get-CleanTenantTestAppNames { @() }
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

    Describe "API test isolation metadata" {
        It "matches every NAV API execution path and its isolation mode" {
            $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
            $typedIntegrationCodeunits = @(139917, 139918, 139919, 139920, 139921)
            foreach ($apiVersion in @('APIV1', 'APIV2')) {
                $testSource = Join-Path $repoRoot "src\Apps\W1\$apiVersion\test\src"
                $disabledManifest = Join-Path $repoRoot "src\DisabledTests\_Exclude_${apiVersion}__Tests\_Exclude_${apiVersion}__Tests.DisabledTest.json"
                $disabledCodeunitIds = @(
                    Get-Content $disabledManifest -Raw |
                        ConvertFrom-Json |
                        Where-Object method -eq '*' |
                        ForEach-Object { [int]$_.codeunitId }
                )
                $enabledCodeunitCount = 0
                foreach ($file in (Get-ChildItem $testSource -Filter '*.al' -File)) {
                    $content = Get-Content $file.FullName -Raw
                    if ($content -match 'Subtype\s*=\s*Test\s*;') {
                        $codeunitId = [int]([regex]::Match($content, 'codeunit\s+(\d+)').Groups[1].Value)
                        if ($codeunitId -in $disabledCodeunitIds) {
                            continue
                        }

                        $enabledCodeunitCount++
                        if ($codeunitId -in $typedIntegrationCodeunits) {
                            $content | Should -Match 'TestType\s*=\s*IntegrationTest\s*;' `
                                -Because "$($file.Name) runs through NAV's typed Integration task"
                            $content | Should -Not -Match 'RequiredTestIsolation\s*=\s*Disabled\s*;' `
                                -Because "$($file.Name) runs with normal Codeunit isolation in NAV"
                            $content | Should -Match 'LibraryGraphMgt\.BindAuthentication\(\);'
                        } else {
                            $content | Should -Match 'RequiredTestIsolation\s*=\s*Disabled\s*;' `
                                -Because "$($file.Name) runs in a NAV Disabled-isolation path"
                            $content | Should -Match 'LibraryGraphMgt\.InitializeApiTest\(\);' `
                                -Because "$($file.Name) must bind authentication and use a license-safe work date"
                            $content | Should -Not -Match 'LibraryERM\.SetWorkDate\(\);' `
                                -Because "$($file.Name) must not overwrite the API test license-safe work date"
                        }
                    }
                }

                $expectedEnabledCodeunits = if ($apiVersion -eq 'APIV1') { 44 } else { 75 }
                $enabledCodeunitCount | Should -Be $expectedEnabledCodeunits `
                    -Because "$apiVersion must match the union of NAV's web-service and typed test tasks"
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

    It "dispatches one codeunit with Disabled isolation after requesting a tenant refresh" {
        InModuleScope ParallelTestExecution {
            $script:capturedParameters = $null
            $script:capturedDatabaseName = $null
            $script:capturedTemplateName = $null

            Mock Get-DisabledTestsForApp { @() }
            Mock Start-Sleep { }
            Mock Start-TestJob {
                $script:capturedParameters = $parameters
                $script:capturedDatabaseName = $tenantDatabaseName
                $script:capturedTemplateName = $templateDatabaseName
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
            }) -TemplateDatabaseName 'default-test-template' -ScriptPath 'runner.ps1' `
                -TestType 'IntegrationTest' -State $state

            $script:capturedParameters.testCodeunit | Should -Be '500'
            $script:capturedParameters.requiredTestIsolation | Should -Be 'Disabled'
            $script:capturedParameters.testRunnerCodeunitId | Should -Be '130451'
            $script:capturedParameters.AppendToJUnitResultFile | Should -BeTrue
            $script:capturedDatabaseName | Should -Be 'tenant2'
            $script:capturedTemplateName | Should -Be 'default-test-template'
            $state.jobs.Count | Should -Be 1
        }
    }

    It "marks scheduler retries as reruns so existing XML entries are replaced" {
        InModuleScope ParallelTestExecution {
            $script:capturedParameters = $null

            Mock Get-DisabledTestsForApp { @() }
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
            }) -TemplateDatabaseName 'default-test-template' -ScriptPath 'runner.ps1' `
                -TestType 'IntegrationTest' -State ([PSCustomObject]@{ jobs = @() }) `
                -Verb 'Re-dispatching'

            $script:capturedParameters.ReRun | Should -BeTrue
        }
    }

    It "retries a clean codeunit on its original tenant" {
        InModuleScope ParallelTestExecution {
            $script:dispatchTenants = [System.Collections.Generic.List[string]]::new()
            $script:firstDispatch = $true

            Mock Wait-ForFreeTenant { 'tenant2' }
            Mock Wait-ForSpecificTenant { $tenant }
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

    It "creates one template and invokes clean-tenant execution when codeunits require Disabled isolation" {
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
            Mock Get-CleanTenantTestAppNames { @('Tests') }
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
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch { }
            Mock Wait-ForAllTestJobs { $true }
            Mock Invoke-RequiredDisabledTestExecution { $true }
            Mock Remove-BcTestTenantTemplate { }
            Mock Enable-BcTestTaskScheduler { }
            Mock Merge-TenantTestResults { }

            $result = Invoke-ParallelTestExecution -parameters @{
                containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                tenant = 'default'
            } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests')

            $result | Should -BeTrue
            Should -Invoke New-BcTestTenantTemplate -Times 1
            Should -Invoke Enable-BcTestTaskScheduler -Times 1
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
}
