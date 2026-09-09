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
            Mock Enable-BcTestTaskScheduler { }
            Mock Disable-BcTestTaskScheduler { }
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
                "Exception occurred while running tests: ClientSession State is InError (Wait time 25 seconds)"
                "GET request failed. Response code is 500 (InternalServerError), expected code is 200. Error message: Object reference not set to an instance of an object."
            ) | ForEach-Object {
                Test-TransientTestFailure -Output $_ | Should -BeTrue
            }
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
                $disabledCodeunitIds = if (Test-Path $disabledManifest) {
                    @(
                        Get-Content $disabledManifest -Raw |
                            ConvertFrom-Json |
                            Where-Object method -eq '*' |
                            ForEach-Object { [int]$_.codeunitId }
                    )
                } else {
                    @()
                }
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
                            $content | Should -Match 'LibraryGraphMgt\.SetAuthenticationProvider\(\s*Enum::"API Test Authentication"::"Microsoft Test Environment"\s*\);'
                        } else {
                            $content | Should -Match 'RequiredTestIsolation\s*=\s*Disabled\s*;' `
                                -Because "$($file.Name) runs in a NAV Disabled-isolation path"
                            $content | Should -Match 'LibraryGraphMgt\.SetAuthenticationProvider\(\s*Enum::"API Test Authentication"::"Microsoft Test Environment"\s*\);' `
                                -Because "$($file.Name) must select Microsoft test-environment authentication"
                            $content | Should -Match 'LibraryGraphMgt\.SetLicenseSafeWorkDate\(\);' `
                                -Because "$($file.Name) must explicitly use a license-safe work date"
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

    Describe "API test authentication extensibility" {
        BeforeAll {
            $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
            $testLibraryRoot = Join-Path $repoRoot 'src\Layers\W1\Tests\TestLibraries'
            $script:authenticationInterface = Get-Content (Join-Path $testLibraryRoot 'APITestAuthProvider.Interface.al') -Raw
            $script:authenticationEnum = Get-Content (Join-Path $testLibraryRoot 'APITestAuthentication.Enum.al') -Raw
            $script:authenticationContext = Get-Content (Join-Path $testLibraryRoot 'APITestAuthContext.Codeunit.al') -Raw
            $script:graphManagement = Get-Content (Join-Path $testLibraryRoot 'LibraryGraphMgt.Codeunit.al') -Raw
            $script:microsoftProvider = Get-Content (Join-Path $testLibraryRoot 'MicrosoftTestAuthProvider.Codeunit.al') -Raw
        }

        It "exposes an extensible provider contract with a no-auth default" {
            $script:authenticationInterface | Should -Match 'interface\s+"API Test Auth Provider"'
            $script:authenticationInterface | Should -Match 'ConfigureAuthentication\(TargetURL:\s*Text;\s*var\s+Authentication:\s*Codeunit\s+"API Test Auth Context"\)'
            $script:authenticationEnum | Should -Match 'Extensible\s*=\s*true\s*;'
            $script:authenticationEnum | Should -Match 'DefaultImplementation\s*=\s*"API Test Auth Provider"\s*=\s*"No API Test Auth Provider"\s*;'
            $script:authenticationEnum | Should -Match 'value\(1;\s*"Microsoft Test Environment"\)'
            $script:authenticationEnum | Should -Not -Match 'UnknownValueImplementation'
        }

        It "keeps request mutation inside the authentication context" {
            $script:authenticationContext | Should -Match 'procedure\s+SetBasicAuthentication\(UserName:\s*Text;\s*Password:\s*SecretText\)'
            $script:authenticationContext | Should -Match 'HttpWebRequestMgt\.AddBasicAuthentication\(BasicUserName,\s*BasicPassword\)'
            $script:microsoftProvider | Should -Not -Match 'HttpWebRequestMgt'
            $script:microsoftProvider | Should -Match 'Authentication\.SetBasicAuthentication\(UserId\(\),\s*Password\)'
            $script:microsoftProvider | Should -Match 'TargetUri\.GetScheme\(\).*CurrentServiceUri\.GetScheme\(\)'
            $script:microsoftProvider | Should -Match 'TargetUri\.GetAuthority\(\).*CurrentServiceUri\.GetAuthority\(\)'
        }

        It "applies the selected provider after URL rewriting and before the final request event" {
            $script:graphManagement | Should -Match 'AuthenticationProviderResolved:\s*Boolean\s*;'
            $script:graphManagement | Should -Match 'HttpWebRequestMgt\.Initialize\(TargetURL\);\s*ApplyAuthentication\(HttpWebRequestMgt\);\s*OnAfterInitializeWebRequestWithURL\(HttpWebRequestMgt\);'
            $script:graphManagement | Should -Match 'ConfigureAuthentication\(HttpWebRequestMgt\.GetUrl\(\),\s*AuthenticationContext\)'
            $script:graphManagement | Should -Not -Match 'Microsoft Test Auth Provider'
        }

        It "selects Microsoft test authentication in every test codeunit that issues Graph requests" {
            $candidateFiles = @(
                & git -C $repoRoot grep -l 'Codeunit "Library - Graph Mgt"' -- '*.al'
            )
            foreach ($candidateFile in $candidateFiles) {
                $content = Get-Content (Join-Path $repoRoot $candidateFile) -Raw
                if (($content -match 'Subtype\s*=\s*Test\s*;') -and
                    ($content -match '\.(GetFromWebService|PostToWebService|PatchToWebService|DeleteFromWebService|InitializeWebRequestWithURL|GetBinaryFromWebService)') -and
                    ($candidateFile -notlike '*APITestAuthProviderTests.Codeunit.al')) {
                    $content | Should -Match 'SetAuthenticationProvider\(\s*Enum::"API Test Authentication"::"Microsoft Test Environment"\s*\);' `
                        -Because "$candidateFile issues API requests"
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

    It "applies country-scoped disabled tests only in matching countries" {
        InModuleScope ParallelTestExecution {
            Test-DisabledTestAppliesToCountry -DisabledTest ([PSCustomObject]@{ method = 'Global' }) -Country 'W1' |
                Should -BeTrue
            Test-DisabledTestAppliesToCountry -DisabledTest ([PSCustomObject]@{
                method = 'IndiaOnly'
                countries = @('IN')
            }) -Country 'IN' | Should -BeTrue
            Test-DisabledTestAppliesToCountry -DisabledTest ([PSCustomObject]@{
                method = 'IndiaOnly'
                countries = @('IN')
            }) -Country 'W1' | Should -BeFalse
        }
    }

    It "dispatches one codeunit with Disabled isolation" {
        InModuleScope ParallelTestExecution {
            $script:capturedParameters = $null

            Mock Get-DisabledTestsForApp { @() }
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

            Mock Get-DisabledTestsForApp { @() }
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
            $script:taskSchedulerEnabled = $false
            Mock New-BcTestTenantTemplate { 'default-test-template' }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Start-TestAppDispatch {
                $script:taskSchedulerEnabled | Should -BeFalse
            }
            Mock Wait-ForAllTestJobs { $true }
            Mock Invoke-RequiredDisabledTestExecution {
                $script:taskSchedulerEnabled | Should -BeTrue
                $true
            }
            Mock Reset-BcTestTenant {
                $script:taskSchedulerEnabled | Should -BeFalse
            }
            Mock Remove-BcTestTenantTemplate { }
            Mock Enable-BcTestTaskScheduler { $script:taskSchedulerEnabled = $true }
            Mock Disable-BcTestTaskScheduler { $script:taskSchedulerEnabled = $false }
            Mock Merge-TenantTestResults { }

            $result = Invoke-ParallelTestExecution -parameters @{
                containerName = "ut-$([guid]::NewGuid().ToString('N'))"
                tenant = 'default'
            } -scriptPath 'unused.ps1' -testType 'IntegrationTest' -appNamesToTest @('Tests')

            $result | Should -BeTrue
            Should -Invoke New-BcTestTenantTemplate -Times 1 -ParameterFilter {
                $SourceDatabaseName -eq 'default'
            }
            Should -Invoke Enable-BcTestTaskScheduler -Times 1
            Should -Invoke Disable-BcTestTaskScheduler -Times 1
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

    It "re-runs a failed app on a different tenant than the one it failed on" {
        # A failed app is retried once, and never on the tenant it failed on: tests are not
        # guaranteed to clean up after themselves, so residue from the failed run could
        # re-trigger the same failure and make the retry worthless.
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
            Mock Get-CleanTenantTestAppNames { @('Big') }
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
                -testType 'Legacy' -appNamesToTest @('Big', 'Small')

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
