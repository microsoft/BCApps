<#
.Synopsis
    Builds the per-branch unstable-tests artifact from BOTH the recent CI/CD runs and recent PR builds.

.Description
    The single driver behind the unified UpdateUnstableTests workflow. For one branch it combines the two
    detection signals into one artifact write:

      Path A - CI/CD sliding window (authoritative recompute):
        Discovers the last RunLimit completed CI/CD runs that produced test results and marks every test
        that failed in at least one of them as unstable. This is a full recompute, so tests that no longer
        fail across the window drop off the list (self-healing).

      Path B - cross-PR detection (additive):
        Looks at PR builds that completed in the last WindowHours (or are still running) and additively adds
        any test that failed across at least MinDistinctPrs distinct PRs targeting the branch. A test failing
        on a single PR is ambiguous (could be that PR's own change); the same test failing across several
        unrelated PRs in a short window is almost always an instability.

    The two paths are merged into a single per-branch unstable-tests.json (Path A produces the base list,
    Path B is layered on top additively so entries from either signal are preserved). The result is written
    once, so PR builds always consume a single coherent artifact.

    Self-healing note: Path A recomputes from scratch each run and can drop a cross-PR-added entry once it
    stops failing in CI/CD; Path B re-adds it on the next run if it keeps recurring across PRs.

.Parameter Branch
    Branch whose unstable tests list should be updated (e.g. 'main', 'releases/26.0').

.Parameter RunLimit
    Number of recent completed CI/CD runs to examine for Path A. Defaults to 3.

.Parameter FilterPush
    Include CI/CD runs triggered by push when discovering the Path A window.

.Parameter FilterWorkflowDispatch
    Include CI/CD runs triggered by workflow_dispatch when discovering the Path A window. Defaults to on.

.Parameter WindowHours
    How far back to look at PR builds for Path B, measured by build completion time. Defaults to 3.

.Parameter MinDistinctPrs
    Minimum number of distinct PRs a test must fail on to be flagged by Path B. Defaults to 2.

.Parameter OutputPath
    Path where the unstable-tests.json should be written. Defaults to '.unstable-tests/unstable-tests.json'.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [int] $RunLimit = 3,

    [switch] $FilterPush,

    [switch] $FilterWorkflowDispatch,

    [int] $WindowHours = 3,

    [int] $MinDistinctPrs = 2,

    [string] $OutputPath = (Join-Path '.unstable-tests' 'unstable-tests.json')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TestTolerance.psm1') -Force

if (-not (Test-IsToleranceSupportedBranch -Branch $Branch)) {
    throw "Branch '$Branch' is not supported by the test tolerance feature."
}

$repo = $env:GITHUB_REPOSITORY

$existingDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-existing-$([System.Guid]::NewGuid().ToString('N'))"
$cicdWorkDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-cicd-$([System.Guid]::NewGuid().ToString('N'))"
$prWorkDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-prbuild-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $cicdWorkDir -Force | Out-Null
New-Item -ItemType Directory -Path $prWorkDir -Force | Out-Null

try {
    # --- Path A: recompute the base list from the recent CI/CD window ---
    Write-Host "::group::Path A · Recompute from recent CI/CD runs (branch '$Branch')"
    $cicdRunIds = @(Find-UnstableTestRunIds `
        -Branch $Branch `
        -Repository $repo `
        -RunLimit $RunLimit `
        -FilterPush:$FilterPush `
        -FilterWorkflowDispatch:$FilterWorkflowDispatch)

    $baseEntries = @()
    if ($cicdRunIds.Count -gt 0) {
        $cicdFailed = Get-FailedTestsFromRuns -RunIds $cicdRunIds -Repository $repo -WorkDirectory $cicdWorkDir
        $recomputed = Update-UnstableTestsList -FailedTests $cicdFailed -RunCount $cicdRunIds.Count
        $baseEntries = @($recomputed.Values | ForEach-Object { ConvertTo-UnstableTestEntry -Test $_ -Repository $repo })
        Write-Host "::endgroup::"
        Write-Host "::notice::Path A (CI/CD): recomputed $($baseEntries.Count) unstable test(s) from $($cicdRunIds.Count) run(s) on '$Branch'."
    }
    else {
        # No CI/CD runs to recompute from. Do NOT wipe the list: fall back to the existing artifact as the
        # base so Path B stays purely additive on top of it.
        $existingPath = Receive-UnstableTestsArtifact -Branch $Branch -OutputDirectory $existingDir
        if ($existingPath -and (Test-Path $existingPath)) {
            $existing = Get-Content -Raw -Path $existingPath | ConvertFrom-Json
            if (($existing.PSObject.Properties['tests']) -and $existing.tests) {
                $baseEntries = @($existing.tests)
            }
            Write-Host "Existing unstable tests list for '$Branch' has $($baseEntries.Count) test(s)."
        }
        Write-Host "::endgroup::"
        Write-Host "::warning::Path A (CI/CD): no completed runs with test results for '$Branch'. Preserving the existing list ($($baseEntries.Count) test(s)) as the base."
    }

    # --- Path B: cross-PR detection from recent PR builds (completed or running) ---
    $crossPrFailed = Find-CrossPrUnstableTests `
        -Branch $Branch `
        -Repository $repo `
        -WindowHours $WindowHours `
        -MinDistinctPrs $MinDistinctPrs `
        -WorkDirectory $prWorkDir
    Write-Host "::notice::Path B (cross-PR): detected $($crossPrFailed.Count) unstable test(s) for '$Branch'."

    # If there is nothing to recompute (no CI/CD runs) and nothing new detected, leave the existing
    # artifact untouched and skip the write entirely so the caller can skip the upload.
    if ($cicdRunIds.Count -eq 0 -and $crossPrFailed.Count -eq 0) {
        Write-Host "::notice::Nothing to update for '$Branch' (no CI/CD window, no cross-PR detections). Existing list left unchanged."
        return
    }

    # --- Merge Path B additively on top of the Path A base and write once ---
    $tests = @(Add-FailedTestsToUnstableTests -ExistingTests ([System.Collections.IList]$baseEntries) -FailedTests $crossPrFailed -Repository $repo)

    $allRunIds = @()
    $allRunIds += @($cicdRunIds)
    $allRunIds += @($crossPrFailed.Values | ForEach-Object { [string]$_.SourceRunId } | Where-Object { $_ })
    $allRunIds = @($allRunIds | Select-Object -Unique)

    Save-UnstableTestsArtifact -Branch $Branch -RunIds $allRunIds -Tests ([System.Collections.IList]$tests) -OutputPath $OutputPath
}
finally {
    foreach ($dir in @($existingDir, $cicdWorkDir, $prWorkDir)) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Unstable tests list ready at '$OutputPath'."
