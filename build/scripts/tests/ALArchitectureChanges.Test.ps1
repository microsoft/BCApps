# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 5.1
Describe 'Payables Agent architecture change selection' {
    BeforeAll {
        $script:changeScript = Join-Path $PSScriptRoot '../Test-PayablesAgentArchitectureChanges.ps1'
        $script:repo = (Get-Item (Join-Path $PSScriptRoot '../../..')).FullName
        Import-Module (Join-Path $PSScriptRoot '../PayablesAgentArchitectureChanges.psm1') -Force
        function Assert-ChangeValue($Actual, $Expected) {
            if ($Actual -cne $Expected) { throw "Expected '$Expected', got '$Actual'." }
        }
        function New-ChangeEvent([string] $Name, [string] $Base = $script:baseSha, [string] $Head = $script:headSha) {
            $eventPayload = switch ($Name) {
                'pull_request' { @{ pull_request = @{ base = @{ sha = $Base }; head = @{ sha = ('3' * 40) } } } }
                'merge_group' { @{ merge_group = @{ base_sha = $Base; head_sha = $Head } } }
                'push' { @{ before = $Base; after = $Head } }
            }
            $path = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N') + '.json')
            $eventPayload | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding utf8
            return $path
        }
        function Get-TestChange([string] $Name = 'pull_request') {
            Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName $Name -EventPath (New-ChangeEvent $Name) `
                -ExpectedHead $script:headSha
        }
    }

    BeforeEach {
        $script:baseSha = '1' * 40
        $script:headSha = '2' * 40
        $script:calls = [Collections.Generic.List[object]]::new()
        $script:gitState = [PSCustomObject]@{
            BaseSha = $script:baseSha
            HeadSha = $script:headSha
            Calls = $script:calls
            DiffOutput = @()
            BaseMissing = $false
            DiffFails = $false
        }
        # Explicit shared state keeps module mocks compatible with both Pester 3 and 5.
        & (Get-Module PayablesAgentArchitectureChanges) { param($State) $script:gitState = $State } $script:gitState
        Mock -ModuleName PayablesAgentArchitectureChanges Invoke-PayablesAgentArchitectureGit {
            param($RepoRoot, $Arguments)
            $script:gitState.Calls.Add([PSCustomObject]@{ RepoRoot = $RepoRoot; Arguments = @($Arguments) })
            switch ($Arguments[0]) {
                'rev-parse' {
                    if ($Arguments -contains 'HEAD^{commit}') { return $script:gitState.HeadSha }
                    if ($script:gitState.BaseMissing) { throw 'Comparison commit is missing.' }
                    return $script:gitState.BaseSha
                }
                'diff' {
                    if ($script:gitState.DiffFails) { throw 'Diff unavailable.' }
                    return $script:gitState.DiffOutput
                }
                default { throw "Unexpected Git command: $($Arguments -join ' ')" }
            }
        }
    }

    It 'skips unrelated PRs using the base SHA and checked-out merge commit, not the raw PR head' {
        $result = Get-TestChange
        Assert-ChangeValue $result.Required $false
        Assert-ChangeValue $result.Base $script:baseSha
        Assert-ChangeValue $result.Head $script:headSha
        $diff = @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' })[0].Arguments
        Assert-ChangeValue $diff[4] $script:baseSha
        Assert-ChangeValue $diff[5] $script:headSha
    }

    It 'runs for matching paths, including deletions, renames and unusual filenames' {
        foreach ($path in @('src/Apps/W1/PayablesAgent/app/Removed.al', 'build/scripts/ALArchitectureRules.psm1', "src/Apps/W1/PayablesAgent/app/line`nbreak.al")) {
            $script:gitState.DiffOutput = @($path + [char]0)
            Assert-ChangeValue (Get-TestChange).Required $true
        }
        $diff = @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' })[0].Arguments
        Assert-ChangeValue ($diff -contains '--no-renames') $true
        Assert-ChangeValue ($diff -contains '-z') $true
    }

    It 'watches PA sources, all checker entry points/tests, the action and the invoking workflow' {
        $null = Get-TestChange
        $diff = @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' })[0].Arguments
        Assert-ChangeValue ($diff -contains '--') $true
        foreach ($path in @('src/Apps/W1/PayablesAgent/', 'build/scripts/Test-PayablesAgentArchitecture*.ps1', 'build/scripts/Test-ALAppArchitecture.ps1', 'build/scripts/*Architecture*.psm1', 'build/scripts/tests/ALArchitecture*.Test.ps1', '.github/actions/TestALAppArchitecture/', '.github/workflows/PullRequestHandler.yaml')) {
            Assert-ChangeValue ($diff -contains $path) $true
        }
        Assert-ChangeValue ($diff -contains '.github/workflows/_BuildALGoProject.yaml') $false
    }

    It 'uses the whole merge group rather than one PR or the last commit' {
        Assert-ChangeValue (Get-TestChange 'merge_group').Required $false
        $diff = @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' })[0].Arguments
        Assert-ChangeValue $diff[4] $script:baseSha
        Assert-ChangeValue $diff[5] $script:headSha
    }

    It 'uses push before/after endpoints so multi-commit pushes are not reduced to HEAD parent' {
        Assert-ChangeValue (Get-TestChange 'push').Required $false
        $arguments = @($script:calls | ForEach-Object { $_.Arguments })
        Assert-ChangeValue ($arguments -contains 'HEAD^') $false
        Assert-ChangeValue ($arguments -contains $script:baseSha) $true
    }

    It 'uses an explicit AL-Go baseline for manual or scheduled builds' {
        foreach ($name in @('workflow_dispatch', 'schedule', 'workflow_call')) {
            $result = Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName $name -BaselineRef $script:baseSha -ExpectedHead $script:headSha
            Assert-ChangeValue $result.Required $false
            Assert-ChangeValue $result.Base $script:baseSha
        }
    }

    It 'runs conservatively for manual/local events without a baseline' {
        foreach ($name in @('', 'workflow_dispatch', 'schedule', 'workflow_call')) {
            Assert-ChangeValue (Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName $name).Required $true
        }
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' }).Count 0
    }

    It 'runs for new-branch pushes without a usable before commit' {
        $result = Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName push -EventPath (New-ChangeEvent push ('0' * 40))
        Assert-ChangeValue $result.Required $true
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' }).Count 0
    }

    It 'runs rather than guessing when event data is absent, malformed or incomplete' {
        $path = Join-Path $TestDrive 'bad-event.json'
        Assert-ChangeValue (Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName pull_request -EventPath $path).Required $true
        foreach ($json in @('{invalid', '{}', '{"pull_request":{"base":{"sha":"main"}}}')) {
            Set-Content -LiteralPath $path -Value $json
            Assert-ChangeValue (Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName pull_request -EventPath $path).Required $true
        }
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' }).Count 0
    }

    It 'runs if Git cannot identify the checkout or returns an invalid commit' {
        Mock -ModuleName PayablesAgentArchitectureChanges Invoke-PayablesAgentArchitectureGit { throw 'Git unavailable.' }
        Assert-ChangeValue (Get-TestChange).Required $true
        Mock -ModuleName PayablesAgentArchitectureChanges Invoke-PayablesAgentArchitectureGit { 'not-a-commit' }
        Assert-ChangeValue (Get-TestChange).Required $true
    }

    It 'runs if the reusable workflow checked out a different ref from the event' {
        $result = Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName pull_request -EventPath (New-ChangeEvent pull_request) -ExpectedHead ('4' * 40)
        Assert-ChangeValue $result.Required $true
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' }).Count 0
    }

    It 'runs on merge-group or push head mismatches even without GITHUB_SHA' {
        foreach ($name in @('merge_group', 'push')) {
            $result = Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName $name -EventPath (New-ChangeEvent -Name $name -Base $script:baseSha -Head ('4' * 40))
            Assert-ChangeValue $result.Required $true
        }
    }

    It 'runs without fetching if the checkout lacks the comparison base' {
        foreach ($name in @('pull_request', 'merge_group')) {
            $script:gitState.BaseMissing = $true
            Assert-ChangeValue (Get-TestChange $name).Required $true
        }
        $result = Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName workflow_dispatch -BaselineRef 'missing-branch'
        Assert-ChangeValue $result.Required $true
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -notin @('rev-parse', 'diff') }).Count 0
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' }).Count 0
    }

    It 'runs on failed diff commands rather than treating an error as an empty diff' {
        $script:gitState.DiffFails = $true
        Assert-ChangeValue (Get-TestChange).Required $true
    }

    It 'writes skip/run outputs at the CLI boundary without running the checker or tests' {
        # The script entry point uses real read-only Git commands on the existing checkout.
        # HEAD-to-HEAD is a known empty range; no temporary repository/commits are needed.
        $previousOutput = $env:GITHUB_OUTPUT
        try {
            $env:GITHUB_OUTPUT = Join-Path $TestDrive 'step-output'
            $result = & $script:changeScript -RepoRoot $script:repo -EventName workflow_dispatch -ExpectedHead '' -BaselineRef HEAD -PassThru 6> $null
            Assert-ChangeValue $result.Required $false
            $result = & $script:changeScript -RepoRoot $script:repo -EventName workflow_dispatch -ExpectedHead '' -PassThru 6> $null
            Assert-ChangeValue $result.Required $true
            Assert-ChangeValue ([IO.File]::ReadAllText($env:GITHUB_OUTPUT).Replace("`r", '').Trim()) "required=false`nrequired=true"
        } finally { $env:GITHUB_OUTPUT = $previousOutput }
    }

    It 'routes PR checks through the TestALAppArchitecture action in the existing PR validation job only' {
        # Like the other gate actions, the reviewed checker comes from main; it validates the checkout.
        $expectedUse = 'uses: microsoft/BCApps/.github/actions/TestALAppArchitecture@main'
        $text = [IO.File]::ReadAllText((Join-Path $script:repo '.github/workflows/PullRequestHandler.yaml'))
        $job = [regex]::Match($text, '(?ms)^  CustomJob-VerifyAppChanges:.*?(?=^  \S|\z)').Value
        Assert-ChangeValue ([regex]::Matches($text, '(?m)^\s*- uses: \S*TestALAppArchitecture').Count) 1
        Assert-ChangeValue ([regex]::Matches($job, '(?m)^      - ' + [regex]::Escape($expectedUse) + '\s*$').Count) 1
        if ($text.Contains('Test-ALAppArchitecture.ps1') -or $text.Contains('payablesAgentChanges') -or $text.Contains('Payables Agent architecture')) { throw 'App-specific gate plumbing remains in PullRequestHandler.yaml' }
        $build = [IO.File]::ReadAllText((Join-Path $script:repo '.github/workflows/_BuildALGoProject.yaml'))
        if ($build.Contains('ALAppArchitecture') -or $build.Contains('AL_APP_ARCHITECTURE')) { throw 'The AL-Go project build must not host the architecture gate.' }
        $actionScript = [IO.File]::ReadAllText((Join-Path $script:repo '.github/actions/TestALAppArchitecture/action.ps1'))
        foreach ($argument in @('build\scripts\Test-ALAppArchitecture.ps1', '-RepoRoot (Get-Location).Path')) {
            if (-not $actionScript.Contains($argument)) { throw "Missing action argument: $argument" }
        }
    }
}
