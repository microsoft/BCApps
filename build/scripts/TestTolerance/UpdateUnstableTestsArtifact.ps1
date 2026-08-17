<#
.Synopsis
    Builds and writes the per-branch unstable tests artifact from a given set of workflow runs.

.Description
    The single updater shared by both update paths. The caller (the UpdateUnstableTests action, driven
    by its workflow) supplies the only differences:
    - Recompute (scheduled UpdateUnstableTests workflow): the workflow discovers the recent window of
      runs and passes them here for a full recompute of the list.
    - Additive (AddUnstableTestsFromRun workflow): passes an explicit run and sets -Additive so its
      failures are merged into the existing artifact (every existing entry is preserved).

    Regardless of mode, it:
    1. Downloads the test result artifacts from the supplied runs and identifies the failing tests.
    2. Builds the unstable tests list (full recompute, or additive merge with the existing artifact).
    3. Writes unstable-tests.json to OutputPath. When no runs are supplied it returns early without
       writing the file. Exposing the artifact name for upload is the caller's responsibility.

.Parameter Branch
    Branch whose unstable tests list should be updated (e.g. 'main', 'releases/26.0').

.Parameter RunIds
    The workflow run ids to pull failing tests from.

.Parameter OutputPath
    Path where the unstable-tests.json should be written. Defaults to '.unstable-tests/unstable-tests.json'.

.Parameter Additive
    When set, the failing tests are merged into the existing per-branch artifact (every existing entry
    is preserved). When not set, the list is fully recomputed from the supplied runs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [string[]] $RunIds = @(),

    [string] $OutputPath = (Join-Path '.unstable-tests' 'unstable-tests.json'),

    [switch] $Additive
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TestTolerance.psm1') -Force

if (-not (Test-IsToleranceSupportedBranch -Branch $Branch)) {
    throw "Branch '$Branch' is not supported by the test tolerance feature."
}

$repo = $env:GITHUB_REPOSITORY

if ($RunIds.Count -eq 0) {
    # Nothing to process: leave the existing artifact untouched and don't write the file, so the caller
    # can skip the upload step entirely.
    Write-Host "::warning::No runs provided for branch '$Branch'. Keeping existing unstable tests list unchanged."
    return
}

Write-Host "::notice::Using $($RunIds.Count) run(s) for branch '$Branch': $($RunIds -join ', ')"

$downloadDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-existing-$([System.Guid]::NewGuid().ToString('N'))"
$runWorkDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-run-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $runWorkDir -Force | Out-Null

try {
    # --- 1. Download and parse the failing tests from the supplied runs ---
    $failedTests = Get-FailedTestsFromRuns -RunIds $RunIds -Repository $repo -WorkDirectory $runWorkDir
    Write-Host "::notice::Observed $($failedTests.Count) distinct failed test(s) across $($RunIds.Count) run(s)."

    # --- 2. Build the unstable tests list (additive merge or full recompute) ---
    if ($Additive) {
        $existingPath = Receive-UnstableTestsArtifact -Branch $Branch -OutputDirectory $downloadDir

        $existingTests = @()
        if ($existingPath -and (Test-Path $existingPath)) {
            $existing = Get-Content -Raw -Path $existingPath | ConvertFrom-Json
            if (($existing.PSObject.Properties['tests']) -and $existing.tests) {
                $existingTests = @($existing.tests)
            }
            Write-Host "Existing unstable tests list for branch '$Branch' has $($existingTests.Count) test(s)."
        }
        else {
            Write-Host "No existing unstable tests artifact found for branch '$Branch'. Starting from an empty list."
        }

        if ($failedTests.Count -eq 0) {
            Write-Host "::warning::No failed tests found in the supplied run(s). The unstable tests list will be rewritten unchanged."
        }

        $tests = @(Add-FailedTestsToUnstableTests -ExistingTests ([System.Collections.IList]$existingTests) -FailedTests $failedTests -Repository $repo)
    }
    else {
        $updatedTests = Update-UnstableTestsList -FailedTests $failedTests -RunCount $RunIds.Count
        $tests = @($updatedTests.Values | ForEach-Object { ConvertTo-UnstableTestEntry -Test $_ -Repository $repo })
    }

    # --- 3. Write artifact ---
    Save-UnstableTestsArtifact -Branch $Branch -RunIds $RunIds -Tests ([System.Collections.IList]$tests) -OutputPath $OutputPath
}
finally {
    foreach ($dir in @($downloadDir, $runWorkDir)) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Unstable tests list ready at '$OutputPath'."
