$errorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TeamOwnership.psm1') -Force

Describe 'TeamOwnership contract validation' {
    BeforeAll {
        function New-ValidOwnershipResult {
            param(
                [string] $Team = 'Finance',
                [string] $Source = 'issue:path',
                [string] $Confidence = 'high',
                [string] $Token = 'test-token',
                [string] $Kind = 'issue',
                [int] $Number = 42
            )

            return [pscustomobject]@{
                schemaVersion   = 1
                correlationToken = $Token
                subject         = [pscustomobject]@{
                    repository = 'microsoft/BCApps'
                    kind       = $Kind
                    number     = $Number
                }
                ownership       = [pscustomobject]@{
                    team       = $Team
                    source     = $Source
                    reason     = 'A deterministic test reason.'
                    confidence = $Confidence
                    evidence   = @(
                        [pscustomobject]@{
                            kind = 'path'
                            value = 'src/Finance'
                            team = 'Finance'
                            path = 'src/Finance'
                        }
                    )
                }
            }
        }
    }

    It 'accepts a valid issue result' {
        $validated = Assert-OwnershipResult -Result (New-ValidOwnershipResult) `
            -ExpectedCorrelationToken 'test-token' -ExpectedSubjectKind issue -ExpectedSubjectNumber 42
        $validated.Team | Should -BeExactly 'Finance'
        $validated.Confidence | Should -BeExactly 'high'
    }

    It 'accepts every team, confidence, source, and evidence enum' {
        $config = Get-TeamOwnershipConfiguration
        foreach ($team in $config.TeamLabels) {
            foreach ($confidence in $config.ConfidenceValues) {
                foreach ($source in $config.SourceValues) {
                    $result = New-ValidOwnershipResult -Team $team -Confidence $confidence -Source $source
                    $validated = Assert-OwnershipResult -Result $result `
                        -ExpectedCorrelationToken 'test-token' -ExpectedSubjectKind issue -ExpectedSubjectNumber 42
                    $validated.Team | Should -BeExactly $team
                }
            }
        }

        foreach ($kind in $config.EvidenceKinds) {
            $result = New-ValidOwnershipResult
            $result.ownership.evidence[0].kind = $kind
            { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                    -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Not -Throw
        }
    }

    It 'rejects an invalid schema version or unexpected shape' {
        $result = New-ValidOwnershipResult
        $result.schemaVersion = 2
        { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw '*schema version*'

        $result = New-ValidOwnershipResult
        $result | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw '*not allowed*'
    }

    It 'rejects correlation mismatch and invalid token syntax' {
        $result = New-ValidOwnershipResult
        { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'different' `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw '*correlation token*'

        $result.correlationToken = 'bad token'
        { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'bad token' `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw '*invalid format*'
    }

    It 'rejects repository, kind, and number identity mismatches' {
        $cases = @(
            @{ Property = 'repository'; Value = 'microsoft/Other'; Message = '*repository identity*' },
            @{ Property = 'kind'; Value = 'pull_request'; Message = '*subject kind*' },
            @{ Property = 'number'; Value = 43; Message = '*subject number*' }
        )
        foreach ($case in $cases) {
            $result = New-ValidOwnershipResult
            $result.subject.($case.Property) = $case.Value
            { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                    -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw $case.Message
        }
    }

    It 'rejects invalid team, source, confidence, reason, and evidence values' {
        $mutations = @(
            { param($r) $r.ownership.team = 'Unknown' },
            { param($r) $r.ownership.source = 'issue:unknown' },
            { param($r) $r.ownership.confidence = 'certain' },
            { param($r) $r.ownership.reason = ' ' },
            { param($r) $r.ownership.evidence[0].kind = 'unknown' },
            { param($r) $r.ownership.evidence[0].team = 'Unknown' },
            { param($r) $r.ownership.evidence[0].value = '' }
        )
        foreach ($mutate in $mutations) {
            $result = New-ValidOwnershipResult
            & $mutate $result
            { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                    -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw
        }
    }

    It 'accepts nullable evidence teams and rejects malformed optional evidence' {
        $result = New-ValidOwnershipResult
        $result.ownership.evidence[0].team = $null
        { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Not -Throw

        $result.ownership.evidence[0].path = 123
        { Assert-OwnershipResult -Result $result -ExpectedCorrelationToken 'test-token' `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 } | Should -Throw '*path*'
    }
}

Describe 'TeamOwnership label reconciliation' {
    It 'plans add-before-remove operations and preserves unrelated labels' {
        $plan = Get-OwnershipMutationPlan -SelectedTeam Finance -Confidence high `
            -CurrentLabels @('SCM', 'bug', 'Ownership: Needs Review')
        $plan.Add | Should -Be @('Finance')
        $plan.Remove | Should -Be @('SCM', 'Ownership: Needs Review')
        @($plan.Add + $plan.Remove) | Should -Not -Contain 'bug'
    }

    It 'is idempotent when exactly the desired labels are present' {
        $plan = Get-OwnershipMutationPlan -SelectedTeam Integration -Confidence medium `
            -CurrentLabels @('Integration', 'bug')
        $plan.AlreadyConverged | Should -BeTrue
        $plan.Add.Count | Should -Be 0
        $plan.Remove.Count | Should -Be 0
    }

    It 'marks Other and low confidence for review' {
        (Get-OwnershipMutationPlan -SelectedTeam Other -Confidence high -CurrentLabels @()).Add |
            Should -Contain 'Ownership: Needs Review'
        (Get-OwnershipMutationPlan -SelectedTeam SCM -Confidence low -CurrentLabels @()).Add |
            Should -Contain 'Ownership: Needs Review'
    }

    It 'removes review visibility only for non-Other non-low decisions' {
        $plan = Get-OwnershipMutationPlan -SelectedTeam SCM -Confidence medium `
            -CurrentLabels @('SCM', 'Ownership: Needs Review')
        $plan.Remove | Should -Contain 'Ownership: Needs Review'
    }

    It 'refuses to plan automated team changes under manual override' {
        { Get-OwnershipMutationPlan -SelectedTeam Finance -Confidence high `
                -CurrentLabels @('Ownership: Manual', 'SCM') } | Should -Throw '*manual override*'
    }

    It 'detects valid and invalid exact-one manual states' {
        $valid = Get-OwnershipLabelState -LabelNames @('Ownership: Manual', 'Finance')
        $valid.HasManualOverride | Should -BeTrue
        $valid.TeamCount | Should -Be 1
        $valid.SelectedTeam | Should -BeExactly 'Finance'

        (Get-OwnershipLabelState -LabelNames @('Ownership: Manual')).TeamCount | Should -Be 0
        (Get-OwnershipLabelState -LabelNames @('Ownership: Manual', 'Finance', 'SCM')).TeamCount |
            Should -Be 2
    }
}

Describe 'TeamOwnership event normalization' {
    It 'normalizes issue and pull request subjects' {
        $issue = Get-OwnershipSubjectFromEvent -EventName issues `
            -EventPayload ([pscustomobject]@{ issue = [pscustomobject]@{ number = 7; state = 'open' } })
        $issue.Kind | Should -BeExactly 'issue'
        $issue.Number | Should -Be 7

        $pullRequest = Get-OwnershipSubjectFromEvent -EventName pull_request_target `
            -EventPayload ([pscustomobject]@{ pull_request = [pscustomobject]@{ number = 8; state = 'open' } })
        $pullRequest.Kind | Should -BeExactly 'pull_request'
        $pullRequest.Number | Should -Be 8
    }

    It 'rejects closed or malformed subjects' {
        { Get-OwnershipSubjectFromEvent -EventName issues `
                -EventPayload ([pscustomobject]@{ issue = [pscustomobject]@{ number = 7; state = 'closed' } }) } |
            Should -Throw '*not open*'
        { Get-OwnershipSubjectFromEvent -EventName issues -EventPayload ([pscustomobject]@{}) } |
            Should -Throw '*valid subject number*'
    }

    It 'classifies every supported content event' {
        foreach ($action in @('opened', 'reopened', 'edited')) {
            Get-OwnershipEventOperation -EventName issues -Action $action -HasManualOverride:$false |
                Should -BeExactly 'classify'
        }
        foreach ($action in @('opened', 'reopened', 'edited', 'synchronize', 'ready_for_review')) {
            Get-OwnershipEventOperation -EventName pull_request_target -Action $action `
                -HasManualOverride:$false | Should -BeExactly 'classify'
        }
    }

    It 'audits override additions and reclassifies override removals' {
        Get-OwnershipEventOperation -EventName issues -Action labeled `
            -LabelName 'Ownership: Manual' -HasManualOverride:$true | Should -BeExactly 'audit'
        Get-OwnershipEventOperation -EventName issues -Action unlabeled `
            -LabelName 'Ownership: Manual' -HasManualOverride:$false | Should -BeExactly 'classify'
    }

    It 'audits team edits only while overridden and ignores unrelated labels' {
        Get-OwnershipEventOperation -EventName issues -Action labeled -LabelName Finance `
            -HasManualOverride:$true | Should -BeExactly 'audit'
        Get-OwnershipEventOperation -EventName issues -Action unlabeled -LabelName Finance `
            -HasManualOverride:$false | Should -BeExactly 'ignore'
        Get-OwnershipEventOperation -EventName issues -Action labeled -LabelName bug `
            -HasManualOverride:$false | Should -BeExactly 'ignore'
    }
}

Describe 'TeamOwnership reconciliation state' {
    It 'enforces manual and scheduled batch bounds' {
        Assert-ReconciliationLimit -Limit 1 | Should -Be 1
        Assert-ReconciliationLimit -Limit 100 | Should -Be 100
        { Assert-ReconciliationLimit -Limit 0 } | Should -Throw '*between 1 and 100*'
        { Assert-ReconciliationLimit -Limit 101 } | Should -Throw '*between 1 and 100*'
    }

    It 'continues the current kind when another page exists' {
        $next = Get-NextReconciliationState -CurrentKind issue -EndCursor cursor-2 -HasNextPage:$true
        $next.Kind | Should -BeExactly 'issue'
        $next.Cursor | Should -BeExactly 'cursor-2'
    }

    It 'rotates between issues and pull requests at the end of a pass' {
        $next = Get-NextReconciliationState -CurrentKind issue -EndCursor cursor-2 -HasNextPage:$false
        $next.Kind | Should -BeExactly 'pull_request'
        $next.Cursor | Should -BeNullOrEmpty

        $next = Get-NextReconciliationState -CurrentKind pull_request -EndCursor cursor-3 -HasNextPage:$false
        $next.Kind | Should -BeExactly 'issue'
    }

    It 'rejects pagination without a continuation cursor' {
        { Get-NextReconciliationState -CurrentKind issue -EndCursor $null -HasNextPage:$true } |
            Should -Throw '*cursor*'
    }

    It 'always emits a matrix array for zero, one, or multiple subjects' {
        ConvertTo-OwnershipMatrixJson -Subjects @() | Should -BeExactly '[]'
        $one = ConvertTo-OwnershipMatrixJson -Subjects @([pscustomobject]@{ kind = 'issue'; number = 1 })
        $one | Should -Match '^\['
        ($one | ConvertFrom-Json).Count | Should -Be 1

        $many = ConvertTo-OwnershipMatrixJson -Subjects @(
            [pscustomobject]@{ kind = 'issue'; number = 1 },
            [pscustomobject]@{ kind = 'issue'; number = 2 }
        )
        ($many | ConvertFrom-Json).Count | Should -Be 2
    }
}

Describe 'TeamOwnership summary safety' {
    It 'normalizes line breaks and bounds reason text' {
        Get-SafeOwnershipSummaryText -Text "first`r`nsecond" | Should -BeExactly 'first second'
        (Get-SafeOwnershipSummaryText -Text ('x' * 600)).Length | Should -Be 500
        Get-SafeOwnershipSummaryText -Text 'first|second' | Should -BeExactly 'first\|second'
    }
}

Describe 'TeamOwnership result application boundaries' {
    BeforeAll {
        $script:applicationTemp = Join-Path ([System.IO.Path]::GetTempPath()) "OwnershipApplication_$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:applicationTemp | Out-Null
        $script:setResultScript = Join-Path $PSScriptRoot 'Set-OwnershipResult.ps1'

        function Write-ApplicationResult {
            param(
                [Parameter(Mandatory)][string] $Path,
                [string] $Token = 'expected-token'
            )

            [pscustomobject]@{
                schemaVersion = 1
                correlationToken = $Token
                subject = [pscustomobject]@{
                    repository = 'microsoft/BCApps'
                    kind = 'issue'
                    number = 42
                }
                ownership = [pscustomobject]@{
                    team = 'Finance'
                    source = 'issue:path'
                    reason = 'Fixture'
                    confidence = 'high'
                    evidence = @(
                        [pscustomobject]@{ kind = 'path'; value = 'src/Finance'; team = 'Finance' }
                    )
                }
            } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
        }

        function global:gh {
            $global:OwnershipTestGhCalls++
            $global:LASTEXITCODE = 0
            if ($global:OwnershipTestGhResponse) {
                return $global:OwnershipTestGhResponse
            }
            throw 'GitHub API should not have been called.'
        }
    }

    BeforeEach {
        $global:OwnershipTestGhCalls = 0
        $global:OwnershipTestGhResponse = $null
        $env:GITHUB_STEP_SUMMARY = $null
    }

    AfterAll {
        Remove-Item -Path Function:\global:gh -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force -Path $script:applicationTemp -ErrorAction SilentlyContinue
        Remove-Variable -Name OwnershipTestGhCalls -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name OwnershipTestGhResponse -Scope Global -ErrorAction SilentlyContinue
    }

    It 'does not call GitHub for a missing, malformed, or identity-mismatched result' {
        { & $script:setResultScript -ResultPath (Join-Path $script:applicationTemp 'missing.json') `
                -ExpectedCorrelationToken expected-token -ExpectedSubjectKind issue `
                -ExpectedSubjectNumber 42 -Repository microsoft/BCApps -DryRun } | Should -Throw

        $malformed = Join-Path $script:applicationTemp 'malformed.json'
        Set-Content -LiteralPath $malformed -Value '{' -Encoding UTF8
        { & $script:setResultScript -ResultPath $malformed -ExpectedCorrelationToken expected-token `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 -Repository microsoft/BCApps -DryRun } |
            Should -Throw

        $mismatch = Join-Path $script:applicationTemp 'mismatch.json'
        Write-ApplicationResult -Path $mismatch -Token wrong-token
        { & $script:setResultScript -ResultPath $mismatch -ExpectedCorrelationToken expected-token `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 -Repository microsoft/BCApps -DryRun } |
            Should -Throw

        $global:OwnershipTestGhCalls | Should -Be 0
    }

    It 'reads labels but performs no mutation during a valid dry run' {
        $valid = Join-Path $script:applicationTemp 'valid.json'
        Write-ApplicationResult -Path $valid
        $global:OwnershipTestGhResponse = '[[{"name":"SCM"},{"name":"bug"}]]'

        { & $script:setResultScript -ResultPath $valid -ExpectedCorrelationToken expected-token `
                -ExpectedSubjectKind issue -ExpectedSubjectNumber 42 -Repository microsoft/BCApps -DryRun } |
            Should -Not -Throw
        $global:OwnershipTestGhCalls | Should -Be 1
    }
}

Describe 'TeamOwnership reconciliation batching integration' {
    BeforeAll {
        $script:batchTemp = Join-Path ([System.IO.Path]::GetTempPath()) "OwnershipBatch_$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:batchTemp | Out-Null
        $script:batchScript = Join-Path $PSScriptRoot 'Get-OwnershipReconciliationBatch.ps1'

        function global:gh {
            $global:OwnershipBatchGhCalls++
            $global:LASTEXITCODE = 0
            return $global:OwnershipBatchGhResponse
        }
    }

    BeforeEach {
        $global:OwnershipBatchGhCalls = 0
        $global:OwnershipBatchGhResponse = $null
        $env:GITHUB_OUTPUT = Join-Path $script:batchTemp "output_$([guid]::NewGuid()).txt"
        $env:GITHUB_STEP_SUMMARY = Join-Path $script:batchTemp "summary_$([guid]::NewGuid()).md"
    }

    AfterAll {
        Remove-Item -Path Function:\global:gh -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force -Path $script:batchTemp -ErrorAction SilentlyContinue
        Remove-Variable -Name OwnershipBatchGhCalls -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name OwnershipBatchGhResponse -Scope Global -ErrorAction SilentlyContinue
        $env:GITHUB_OUTPUT = $null
        $env:GITHUB_STEP_SUMMARY = $null
    }

    It 'emits a bounded one-item matrix and continuation cursor' {
        $global:OwnershipBatchGhResponse = [pscustomobject]@{
            data = [pscustomobject]@{
                repository = [pscustomobject]@{
                    issues = [pscustomobject]@{
                        nodes = @(
                            [pscustomobject]@{
                                number = 17
                                labels = [pscustomobject]@{
                                    nodes = @([pscustomobject]@{ name = 'Finance' })
                                    pageInfo = [pscustomobject]@{ hasNextPage = $false }
                                }
                            }
                        )
                        pageInfo = [pscustomobject]@{ hasNextPage = $true; endCursor = 'cursor2' }
                    }
                }
            }
        } | ConvertTo-Json -Depth 10 -Compress

        & $script:batchScript -Repository microsoft/BCApps -SubjectKind issue -Limit 1

        $outputs = Get-Content -LiteralPath $env:GITHUB_OUTPUT
        ($outputs | Where-Object { $_ -like 'matrix=*' }) | Should -Match '^matrix=\['
        $outputs | Should -Contain 'has_items=true'
        $outputs | Should -Contain 'next_kind=issue'
        $outputs | Should -Contain 'next_cursor=cursor2'
        $global:OwnershipBatchGhCalls | Should -Be 1
    }

    It 'rejects an out-of-bounds batch before calling GitHub' {
        { & $script:batchScript -Repository microsoft/BCApps -SubjectKind issue -Limit 101 } |
            Should -Throw '*between 1 and 100*'
        $global:OwnershipBatchGhCalls | Should -Be 0
    }
}
