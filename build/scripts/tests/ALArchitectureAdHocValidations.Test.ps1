#Requires -Version 7.2
Describe 'Ad hoc AL app validations' {
    BeforeAll {
        $script:repo = (Get-Item (Join-Path $PSScriptRoot '../../..')).FullName
        $script:dispatcher = Join-Path $PSScriptRoot '../Test-AdHocALAppValidations.ps1'
        # An empty checkout: registered apps have no policy and there are no self-tests, so a
        # self-test RUN decision is observable as a failure instead of a recursive Pester run.
        $script:emptyCheckout = Join-Path $TestDrive 'empty-checkout'
        New-Item -ItemType Directory -Path $script:emptyCheckout -Force | Out-Null
        function Invoke-Dispatcher([string] $EventName, [string[]] $ChangedFiles) {
            $arguments = @{ RepoRoot = $script:emptyCheckout; EventName = $EventName }
            if ($PSBoundParameters.ContainsKey('ChangedFiles')) { $arguments.ChangedFiles = $ChangedFiles }
            return (& $script:dispatcher @arguments 6>&1 | Out-String)
        }
        function Assert-SelfTestsRun([string] $EventName, [string[]] $ChangedFiles) {
            $failure = $null
            try { Invoke-Dispatcher @PSBoundParameters | Out-Null } catch { $failure = $_ }
            if ($null -eq $failure -or $failure.Exception.Message -notlike '*No AL app architecture tests found*') {
                throw "Expected self-tests to run for '$($ChangedFiles -join ', ')': $failure"
            }
        }
    }

    It 'runs self-tests in PR validation when the checker, its action or a registered app changes' {
        foreach ($name in @('pull_request', 'merge_group')) {
            foreach ($path in @(
                    'build/scripts/ALArchitectureRules.psm1',
                    'build/scripts/Test-AdHocALAppValidations.ps1',
                    'build/scripts/tests/ALArchitectureRules.Test.ps1',
                    '.github/actions/TestAdHocALAppValidations/action.ps1',
                    'src/Apps/W1/PayablesAgent/app/Entities/Setup/PASetup.Codeunit.al')) {
                Assert-SelfTestsRun -EventName $name -ChangedFiles @('README.md', $path)
            }
        }
    }

    It 'runs self-tests when the change set is unknown' {
        Assert-SelfTestsRun -EventName pull_request -ChangedFiles $null
    }

    It 'skips self-tests and app scans for unrelated changes' {
        foreach ($name in @('pull_request', 'merge_group', 'push')) {
            $output = Invoke-Dispatcher -EventName $name -ChangedFiles @('README.md', 'src/Apps/W1/PayablesAgent/test/src/PASetupTests.Codeunit.al')
            if ($name -ne 'push' -and $output -notmatch 'self-tests: SKIP') { throw "Expected a self-test skip ($name): $output" }
            if ($output -notmatch 'Payables Agent architecture: SKIP; neither the app nor the checker files changed') { throw "Expected an app scan skip ($name): $output" }
        }
    }

    It 'scans a registered app when it, the checker files or an unknown change set requires it' {
        foreach ($changed in @(@('src/Apps/W1/PayablesAgent/app/app.json'), @('build/scripts/ALArchitectureRules.psm1'), $null)) {
            $output = Invoke-Dispatcher -EventName push -ChangedFiles $changed
            # The empty checkout has no policy, so an attempted scan reports the missing policy.
            if ($output -notmatch 'Payables Agent architecture: SKIP; this checkout registers no policy') { throw "Expected a scan attempt for '$changed': $output" }
        }
    }

    It 'runs self-tests only in PR validation' {
        foreach ($name in @('', 'push', 'workflow_dispatch')) {
            $output = Invoke-Dispatcher -EventName $name -ChangedFiles @('build/scripts/ALArchitectureRules.psm1')
            if ($output -match 'self-tests') { throw "Self-tests are PR validation only ($name): $output" }
        }
    }

    It 'packages the gate as the TestAdHocALAppValidations action, outside AL-Go project builds' {
        $text = [IO.File]::ReadAllText((Join-Path $script:repo '.github/workflows/PullRequestHandler.yaml'))
        if ($text.Contains('Test-AdHocALAppValidations.ps1') -or $text.Contains('payablesAgentChanges') -or $text.Contains('Payables Agent architecture')) { throw 'App-specific gate plumbing remains in PullRequestHandler.yaml' }
        $build = [IO.File]::ReadAllText((Join-Path $script:repo '.github/workflows/_BuildALGoProject.yaml'))
        if ($build -match 'AdHocALAppValidations|ALAppArchitecture|AL_APP_ARCHITECTURE') { throw 'The AL-Go project build must not host the gate.' }
        $actionScript = [IO.File]::ReadAllText((Join-Path $script:repo '.github/actions/TestAdHocALAppValidations/action.ps1'))
        foreach ($argument in @('build\scripts\EnlistmentHelperFunctions.psm1', 'build\scripts\Test-AdHocALAppValidations.ps1', '-RepoRoot (Get-BaseFolder)')) {
            if (-not $actionScript.Contains($argument)) { throw "Missing action argument: $argument" }
        }
    }

    It 'names apps only in the dispatcher registration' {
        foreach ($file in Get-ChildItem (Join-Path $script:repo 'build/scripts') -File -Filter '*.ps*1') {
            if ($file.Name -eq 'Test-AdHocALAppValidations.ps1') { continue }
            if ([IO.File]::ReadAllText($file.FullName) -match 'PayablesAgent|Payables Agent') { throw "App-specific reference in $($file.Name)" }
        }
    }
}
