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
        function Get-TestChange([string] $Name = 'pull_request', [switch] $FetchMissingBase) {
            Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName $Name -EventPath (New-ChangeEvent $Name) `
                -ExpectedHead $script:headSha -FetchMissingBase:$FetchMissingBase
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
            FetchFails = $false
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
                'fetch' {
                    if ($script:gitState.FetchFails) { throw 'Fetch unavailable.' }
                    $script:gitState.BaseMissing = $false
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

    It 'watches PA sources, all checker entry points/tests and both invoking workflows' {
        $null = Get-TestChange
        $diff = @($script:calls | Where-Object { $_.Arguments[0] -eq 'diff' })[0].Arguments
        Assert-ChangeValue ($diff -contains '--') $true
        foreach ($path in @('src/Apps/W1/PayablesAgent/', 'build/scripts/Test-PayablesAgentArchitecture*.ps1', 'build/scripts/*Architecture*.psm1', 'build/scripts/tests/ALArchitecture*.Test.ps1', '.github/workflows/PullRequestHandler.yaml', '.github/workflows/_BuildALGoProject.yaml')) {
            Assert-ChangeValue ($diff -contains $path) $true
        }
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

    It 'runs if a shallow checkout lacks the base and fetching was not authorized' {
        $script:gitState.BaseMissing = $true
        Assert-ChangeValue (Get-TestChange).Required $true
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'fetch' }).Count 0
    }

    It 'can fetch only the missing comparison commit for shallow CI checkouts' {
        $script:gitState.BaseMissing = $true
        Assert-ChangeValue (Get-TestChange -FetchMissingBase).Required $false
        $fetch = @($script:calls | Where-Object { $_.Arguments[0] -eq 'fetch' })
        Assert-ChangeValue $fetch.Count 1
        Assert-ChangeValue ($fetch[0].Arguments -join ' ') "fetch --no-tags --depth=1 origin $script:baseSha"
    }

    It 'does not fetch when the base is already available' {
        Assert-ChangeValue (Get-TestChange -FetchMissingBase).Required $false
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'fetch' }).Count 0
    }

    It 'runs on failed fetches or diff commands rather than treating an error as an empty diff' {
        $script:gitState.BaseMissing = $true
        $script:gitState.FetchFails = $true
        Assert-ChangeValue (Get-TestChange -FetchMissingBase).Required $true
        $script:gitState.BaseMissing = $false
        $script:gitState.DiffFails = $true
        Assert-ChangeValue (Get-TestChange).Required $true
    }

    It 'does not fetch arbitrary unresolved baseline refs' {
        $script:gitState.BaseMissing = $true
        $result = Get-PayablesAgentArchitectureChange -RepoRoot $script:repo -EventName workflow_dispatch -BaselineRef 'missing-branch' -FetchMissingBase
        Assert-ChangeValue $result.Required $true
        Assert-ChangeValue @($script:calls | Where-Object { $_.Arguments[0] -eq 'fetch' }).Count 0
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

    It 'guards both PR checks and the Apps W1 scan with the same conservative step output' {
        foreach ($workflow in @('PullRequestHandler.yaml', '_BuildALGoProject.yaml')) {
            $text = [IO.File]::ReadAllText((Join-Path $script:repo ".github/workflows/$workflow"))
            if (-not $text.Contains('id: payablesAgentChanges') -or -not $text.Contains('run: ./build/scripts/Test-PayablesAgentArchitectureChanges.ps1')) { throw "Missing shared path detector in $workflow" }
            $steps = @([regex]::Matches($text, '(?ms)^      - name: .*?(?=^      - |\z)'))
            $checks = @($steps | Where-Object { $_.Value -match '- name: (?:Test Payables Agent architecture checker|Validate Payables Agent architecture)\r?\n' })
            Assert-ChangeValue $checks.Count $(if ($workflow -eq 'PullRequestHandler.yaml') { 2 } else { 1 })
            foreach ($check in $checks) {
                if (-not $check.Value.Contains("steps.payablesAgentChanges.outputs.required != 'false'")) { throw "Unguarded architecture check in $workflow" }
            }
            if ($text.IndexOf('Detect Payables Agent architecture changes') -gt $text.IndexOf('Validate Payables Agent architecture')) { throw 'Change detection must precede validation.' }
            if ($workflow -eq '_BuildALGoProject.yaml' -and (-not $text.Contains('PA_ARCHITECTURE_BASELINE_SHA: ${{ inputs.baselineWorkflowSHA }}') -or -not $text.Contains("inputs.projectName == 'Apps W1' && steps.payablesAgentChanges.outputs.required"))) { throw 'Preserve the Apps W1 filter and manual-build baseline.' }
        }
    }
}
