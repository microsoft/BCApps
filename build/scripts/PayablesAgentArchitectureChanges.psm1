# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Invoke-PayablesAgentArchitectureGit {
    param(
        [string] $RepoRoot,
        [string[]] $Arguments
    )

    # Like BuildOptimization.psm1, inspect the native exit code explicitly. Git can
    # write progress/errors to stderr even when PowerShell treats stderr as errors.
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -C $RepoRoot @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }

    if ($exitCode -ne 0) {
        throw "Git $($Arguments[0]) failed: $($output -join ' ')"
    }
    return $output | ForEach-Object { $_.ToString() }
}

<#
.SYNOPSIS
    Determines whether CI needs the Payables Agent architecture validation.
.DESCRIPTION
    Uses the checked-out commit and the event's comparison base. Unlike the test-skip
    helper Get-ChangedFilesForCI, this compares the PR merge commit rather than its raw
    head, and distinguishes a known empty diff from an unavailable comparison.
    Unknown/failed comparisons conservatively require validation.
.PARAMETER RepoRoot
    Root of the checked-out repository.
.PARAMETER EventName
    GitHub event name (pull_request, merge_group, push, or a manual/scheduled event).
.PARAMETER EventPath
    GitHub event payload JSON. Required for pull_request, merge_group and push.
.PARAMETER ExpectedHead
    Workflow commit SHA. A different checkout requires validation instead of skipping.
.PARAMETER BaselineRef
    AL-Go baseline SHA for manual/scheduled builds, or a local ref for explicit checks.
.PARAMETER FetchMissingBase
    Allows a shallow fetch of a missing comparison SHA. Does not fetch arbitrary refs.
.OUTPUTS
    An object containing Required, Base, Head and a human-readable Reason.
#>
function Get-PayablesAgentArchitectureChange {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,
        [string] $EventName,
        [string] $EventPath,
        [string] $ExpectedHead,
        [string] $BaselineRef,
        [switch] $FetchMissingBase
    )

    $shaPattern = '^(?:[0-9a-f]{40}|[0-9a-f]{64})$'
    $base = ''
    $head = ''
    try {
        $head = (@(Invoke-PayablesAgentArchitectureGit -RepoRoot $RepoRoot -Arguments @('rev-parse', '--verify', 'HEAD^{commit}')) -join '').Trim()
        if ($head -notmatch $shaPattern) {
            throw 'Cannot identify the checked-out commit.'
        }
        if ($ExpectedHead -and $head -ne $ExpectedHead) {
            throw 'Checkout does not match the workflow event commit.'
        }

        $eventHead = ''
        if ($EventName -in @('pull_request', 'merge_group', 'push')) {
            $eventPayload = Get-Content -LiteralPath $EventPath -Raw -Encoding UTF8 | ConvertFrom-Json
            switch ($EventName) {
                'pull_request' {
                    $base = [string] $eventPayload.pull_request.base.sha
                }
                'merge_group' {
                    $base = [string] $eventPayload.merge_group.base_sha
                    $eventHead = [string] $eventPayload.merge_group.head_sha
                }
                'push' {
                    $base = [string] $eventPayload.before
                    $eventHead = [string] $eventPayload.after
                }
            }
            if ($base -notmatch $shaPattern -or $base -match '^0+$') {
                throw 'Event has no valid comparison base.'
            }
            if ($EventName -ne 'pull_request' -and $eventHead -ne $head) {
                throw 'Checkout does not match the event head.'
            }
        }
        else {
            if (-not $BaselineRef) {
                throw 'No reliable change base for this event; run the full validation.'
            }
            $base = $BaselineRef
        }

        $resolveArguments = @('rev-parse', '--verify', '--end-of-options', "${base}^{commit}")
        try {
            $resolvedBase = (@(Invoke-PayablesAgentArchitectureGit -RepoRoot $RepoRoot -Arguments $resolveArguments) -join '').Trim()
        }
        catch {
            if (-not $FetchMissingBase -or $base -notmatch $shaPattern) {
                throw
            }
            # Two commit trees suffice; do not fetch the entire repository history.
            $null = Invoke-PayablesAgentArchitectureGit -RepoRoot $RepoRoot -Arguments @('fetch', '--no-tags', '--depth=1', 'origin', $base)
            $resolvedBase = (@(Invoke-PayablesAgentArchitectureGit -RepoRoot $RepoRoot -Arguments $resolveArguments) -join '').Trim()
        }
        if ($resolvedBase -notmatch $shaPattern) {
            throw 'Cannot resolve the comparison base.'
        }

        $paths = @(
            'src/Apps/W1/PayablesAgent/',
            'build/scripts/Test-PayablesAgentArchitecture*.ps1',
            'build/scripts/*Architecture*.psm1',
            'build/scripts/tests/ALArchitecture*.Test.ps1',
            '.github/workflows/PullRequestHandler.yaml',
            '.github/workflows/_BuildALGoProject.yaml'
        )
        # Git pathspecs perform filtering. -z avoids quoting/newline ambiguities;
        # --no-renames includes both old and new paths for moves across the boundary.
        $diffArguments = @('diff', '--name-only', '--no-renames', '-z', $resolvedBase, $head, '--') + $paths
        $changed = @(Invoke-PayablesAgentArchitectureGit -RepoRoot $RepoRoot -Arguments $diffArguments)
        $required = -not [string]::IsNullOrEmpty(($changed -join "`n"))
        $reason = 'No PA sources or architecture gate inputs changed.'
        if ($required) {
            $reason = 'PA sources or architecture gate inputs changed.'
        }
        return [PSCustomObject]@{
            Required = $required
            Base = $resolvedBase
            Head = $head
            Reason = $reason
        }
    }
    catch {
        return [PSCustomObject]@{
            Required = $true
            Base = $base
            Head = $head
            Reason = "Run conservatively: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function Get-PayablesAgentArchitectureChange
