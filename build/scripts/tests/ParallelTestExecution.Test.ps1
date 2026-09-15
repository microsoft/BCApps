$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

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

            Mock Get-AvailableBcTenants { @('default') }
            Mock Get-BcContainerAppInfo {
                @('Big', 'Medium', 'Small') | ForEach-Object {
                    [PSCustomObject]@{ IsInstalled = $true; Name = $_; AppId = "id-$_" }
                }
            }
            Mock Wait-ForFreeTenant { 'default' }
            Mock Wait-ForAllTestJobs { $true }
            Mock Merge-TenantTestResults { }
            Mock Start-TestAppDispatch {
                $script:dispatched.Add($AppName)
                # 'Big' loses the platform race on its very first dispatch, exactly once.
                if ($AppName -eq 'Big' -and -not $script:raced) {
                    $script:raced = $true
                    $State.transient = @($State.transient) + @($AppName)
                }
            }

            $params = @{ containerName = "ut-$([guid]::NewGuid().ToString('N'))"; tenant = 'default' }
            $null = Invoke-ParallelTestExecution -parameters $params -scriptPath 'unused.ps1' `
                -testType 'Legacy' -appNamesToTest @('Big', 'Medium', 'Small')

            $script:dispatched | Should -Be @('Big', 'Big', 'Medium', 'Small')
        }
    }
}

Describe "ParallelTestExecution warmup dispatch" {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../ParallelTestExecution.psm1') -Force
    }

    It "dispatches the first app alone and awaits it before fanning out the rest" {
        # The first app must run alone and be awaited before any parallel dispatch. This asserts
        # exactly that ordering: dispatch(first) -> wait -> rest.
        InModuleScope ParallelTestExecution {
            $script:events = [System.Collections.Generic.List[string]]::new()

            Mock Get-AvailableBcTenants { @('default', 'tenant2') }
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

            Mock Get-AvailableBcTenants { @('default') }
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
            Mock Wait-ForAllTestJobs { $State.transient = @('A'); $true }
            $state = [PSCustomObject]@{ jobs = @(); hasFailures = $false; transient = @(); retried = @{} }
            $result = Invoke-WarmupDispatch -Parameters @{ containerName = 'c' } `
                -Pending @('A', 'B', 'C') -AppIdByName @{ A = 'id-A'; B = 'id-B'; C = 'id-C' } `
                -Tenants @('default', 'tenant2') -ScriptPath 'unused.ps1' -TestType 'Legacy' -State $state
            $result | Should -Be @('B', 'C')
            $state.transient | Should -Contain 'A'
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

            Mock Get-AvailableBcTenants { @('default', 'tenant2') }
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
                $script:dispatched.Add([PSCustomObject]@{ App = $AppName; Tenant = $Tenant; Suffix = $FileSuffix })
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
                Mock Get-AvailableBcTenants { @('default', 'tenant2') }
                Mock Get-BcContainerAppInfo { @([PSCustomObject]@{ IsInstalled = $true; Name = 'A'; AppId = 'id-A' }) }
                Mock Invoke-WarmupDispatch { @($Pending) }
                Mock Wait-ForAllTestJobs { }
                Mock Merge-TenantTestResults { }
                Mock Wait-ForFreeTenant { 'tenant2' }
                Mock Start-TestAppDispatch {
                    if ($FileSuffix -and -not $script:raced) {
                        # The rerun job hits the platform race.
                        $script:raced = $true
                        $State.transient = @($State.transient) + @($AppName)
                    }
                }
                # Pre-seed the state as though 'A' already had its rerun dispatched.
                Mock Register-TestJobOutcome { }

                $state = [PSCustomObject]@{
                    jobs = @(); hasFailures = $false; transient = @(); retried = @{}
                    rerun = @(); rerunDone = @{}; rerunBudget = 1; tenantCount = 2
                }
                $state.rerunDone['A'] = 'rerun1'
                $state.transient = @('A')

                # Exercise just the promotion path the loop performs.
                foreach ($appName in @($state.transient)) {
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

            Mock Get-AvailableBcTenants { @('default', 'tenant2') }
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
