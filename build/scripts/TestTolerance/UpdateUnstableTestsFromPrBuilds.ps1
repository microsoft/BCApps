<#
.Synopsis
    Adds cross-PR unstable tests detected from recent PR Build runs to the per-branch artifact.

.Description
    The driver behind the DetectUnstableTestsFromPrBuilds workflow. It looks at PR Build runs completed
    in the last WindowHours, finds tests that failed across at least MinDistinctPrs distinct PRs
    targeting Branch, and merges those tests into the existing per-branch unstable-tests artifact.

    This is an *additive* fast path that complements the scheduled sliding-window updater
    (UpdateUnstableTests): it reacts within minutes to instabilities that show up across unrelated PRs,
    rather than waiting for the twice-daily CI/CD-based recompute. Like the other additive path, entries
    it adds may later be dropped by the scheduled recompute if they stop failing in CI/CD — the intended
    self-healing behavior — and re-added by the next detector run if they recur across PRs.

    Steps:
    1. Detect cross-PR unstable tests via Find-CrossPrUnstableTests.
    2. When any are found, download the existing per-branch artifact and merge the new tests in
       (every existing entry is preserved).
    3. Write unstable-tests.json to OutputPath. When nothing is detected it returns early without
       writing the file, so the caller can skip the upload step entirely.

.Parameter Branch
    Branch whose unstable tests list should be updated (e.g. 'main', 'releases/26.0').

.Parameter WindowHours
    How far back to look at completed PR Build runs. Defaults to 3.

.Parameter MinDistinctPrs
    Minimum number of distinct PRs a test must fail on to be considered unstable. Defaults to 2.

.Parameter OutputPath
    Path where the unstable-tests.json should be written. Defaults to '.unstable-tests/unstable-tests.json'.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

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

$downloadDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-existing-$([System.Guid]::NewGuid().ToString('N'))"
$runWorkDir = Join-Path ([System.IO.Path]::GetTempPath()) "prbuild-runs-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $runWorkDir -Force | Out-Null

try {
    # --- 1. Detect cross-PR unstable tests from recent PR builds ---
    $failedTests = Find-CrossPrUnstableTests `
        -Branch $Branch `
        -Repository $repo `
        -WindowHours $WindowHours `
        -MinDistinctPrs $MinDistinctPrs `
        -WorkDirectory $runWorkDir

    if ($failedTests.Count -eq 0) {
        Write-Host "::notice::No cross-PR unstable tests detected for branch '$Branch'. Existing list left unchanged."
        return
    }

    Write-Host "::notice::Detected $($failedTests.Count) cross-PR unstable test(s) for branch '$Branch'."

    # --- 2. Merge into the existing per-branch artifact (preserving every existing entry) ---
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

    $tests = @(Add-FailedTestsToUnstableTests -ExistingTests ([System.Collections.IList]$existingTests) -FailedTests $failedTests -Repository $repo)

    # --- 3. Write artifact ---
    $runIds = @($failedTests.Values | ForEach-Object { [string]$_.SourceRunId } | Where-Object { $_ } | Select-Object -Unique)
    Save-UnstableTestsArtifact -Branch $Branch -RunIds $runIds -Tests ([System.Collections.IList]$tests) -OutputPath $OutputPath
}
finally {
    foreach ($dir in @($downloadDir, $runWorkDir)) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Unstable tests list ready at '$OutputPath'."
