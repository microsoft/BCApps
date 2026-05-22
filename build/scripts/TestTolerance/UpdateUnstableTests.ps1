<#
.Synopsis
    Updates the per-branch unstable tests artifact by examining recent CI/CD runs.

.Description
    Called by the UpdateUnstableTests workflow on PRs (and optionally manually). It:
    1. Finds the last <RunLimit> completed CI/CD runs on the target branch
       (filtered by event type, e.g. 'push' or 'schedule').
    2. Downloads all test result artifacts from each run via 'gh run download'.
    3. Identifies every test that failed in at least one of those runs.
    4. Writes a new unstable-tests.json listing those tests.

    The list is fully recomputed each time — no incremental merging.

.Parameter Branch
    Branch name (e.g. 'main', 'releases/26.0').

.Parameter OutputPath
    Path where the updated unstable-tests.json should be written.

.Parameter RunLimit
    Number of recent completed CI/CD runs to examine. Default: 3.

.Parameter WorkflowFile
    Filename of the CI/CD workflow. Default: 'CICD.yaml'.

.Parameter FilterPush
    Include CI/CD runs triggered by push events.

.Parameter FilterWorkflowDispatch
    Include CI/CD runs triggered by workflow_dispatch events.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath,

    [int] $RunLimit = 3,

    [string] $WorkflowFile = 'CICD.yaml',

    [switch] $FilterPush,
    [switch] $FilterWorkflowDispatch
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TestTolerance.psm1') -Force

$repo = $env:GITHUB_REPOSITORY

# --- 1. Find the last N completed CI/CD runs on the target branch that have test result artifacts ---

$eventTypes = @()
if ($FilterPush) { $eventTypes += 'push' }
if ($FilterWorkflowDispatch) { $eventTypes += 'workflow_dispatch' }
if ($eventTypes.Count -eq 0) { $eventTypes = @('workflow_dispatch') }  # Default to workflow_dispatch if nothing selected
Write-Host "Finding last $RunLimit completed '$WorkflowFile' runs on '$Branch' (events=$($eventTypes -join ', ')) with test result artifacts ..."

# Fetch candidate runs across all requested event types.
$candidateLimit = $RunLimit * 5
$candidates = @()
foreach ($eventType in $eventTypes) {
    $candidates += @(gh run list --repo $repo --workflow $WorkflowFile --branch $Branch --event $eventType --status completed --limit $candidateLimit --json databaseId,conclusion,createdAt | ConvertFrom-Json)
}
# Sort by creation date descending and deduplicate (in case of overlap).
$candidates = @($candidates | Sort-Object -Property createdAt -Descending | Sort-Object -Property databaseId -Unique | Sort-Object -Property createdAt -Descending)

$runIds = [System.Collections.Generic.List[string]]::new()
foreach ($run in $candidates) {
    if ($runIds.Count -ge $RunLimit) { break }
    # The API 'name' param requires exact match (no wildcards), so we paginate and filter client-side.
    $testResultNames = @(gh api "/repos/$repo/actions/runs/$($run.databaseId)/artifacts" --paginate --jq '.artifacts[].name | select(contains("TestResults"))' 2>$null)
    if ($testResultNames.Count -eq 0) { continue }
    $runIds.Add([string]$run.databaseId)
}

if ($runIds.Count -eq 0) {
    if ($candidates.Count -eq 0) {
        Write-Host "::warning::No completed '$WorkflowFile' runs found for branch '$Branch' (events=$($eventTypes -join ', ')). Keeping existing unstable tests list unchanged."
    } else {
        Write-Host "::warning::Found $($candidates.Count) completed '$WorkflowFile' run(s) for branch '$Branch' (events=$($eventTypes -join ', ')), but none contained test result artifacts. Keeping existing unstable tests list unchanged."
    }
    return
}

Write-Host "Found $($runIds.Count) run(s) with test results: $($runIds -join ', ')"
Write-Host "::notice::Using $($runIds.Count) CI/CD run(s) for branch '$Branch': $($runIds -join ', ')"

# --- 2. Download and parse test results from each run ---

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-updater-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {

$allFailed = @{}
$totalArtifacts = 0
$downloadPattern = '*TestResult*'

foreach ($runId in $runIds) {
    $runDir = Join-Path $tempDir "run-$runId"

    Write-Host "Downloading test result artifacts from run $runId ..."
    gh run download $runId --repo $repo --dir $runDir --pattern $downloadPattern 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "::warning::gh run download failed for run $runId (exit code $LASTEXITCODE). Skipping."
        continue
    }

    if (-not (Test-Path $runDir)) { continue }

    foreach ($artifactDir in @(Get-ChildItem -Path $runDir -Directory)) {
        if ($artifactDir.Name -match 'BcptTestResults|PageScriptingTestResult') { continue } # Skip known non-test artifacts that may contain 'TestResult' in their name but don't have test result XML files.

        $totalArtifacts++
        foreach ($xml in @(Get-ChildItem -Path $artifactDir.FullName -Filter '*.xml' -Recurse)) {
            foreach ($ft in @(Get-FailedTestsFromResults -Path $xml.FullName)) {
                if (-not $allFailed.ContainsKey($ft.Key)) {
                    $allFailed[$ft.Key] = [pscustomobject]@{
                        ExtensionId    = $ft.ExtensionId
                        CodeunitId     = $ft.CodeunitId
                        CodeunitName   = $ft.CodeunitName
                        TestMethod     = $ft.TestMethod
                        FailureMessage = $ft.FailureMessage
                        FailureDetail  = $ft.FailureDetail
                        SourceRunId    = [string]$runId
                    }
                }
            }
        }
    }
}

Write-Host "Observed $($allFailed.Count) distinct failed test(s) across $totalArtifacts artifact(s) from $($runIds.Count) run(s)."
Write-Host "::notice::Observed $($allFailed.Count) distinct unstable test(s) across $totalArtifacts artifact(s) from $($runIds.Count) run(s)."

# --- 3. Build updated unstable list ---

$updatedTests = Update-UnstableTestsList -FailedTests $allFailed -RunCount $runIds.Count

# --- 4. Write artifact ---

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$payload = [ordered]@{
    branch        = $Branch
    updatedAt     = (Get-Date).ToUniversalTime().ToString('o')
    artifactCount = $totalArtifacts
    runIds        = @($runIds)
    tests     = @($updatedTests.Values | ForEach-Object {
        [ordered]@{
            extensionId    = $_.ExtensionId
            codeunitId     = $_.CodeunitId
            codeunitName   = $_.CodeunitName
            testMethod     = $_.TestMethod
            failureMessage = $_.FailureMessage
            failureDetail  = $_.FailureDetail
            reason         = $_.Reason
            linkedIssue    = $_.LinkedIssue
            sourceRunUrl   = if ($_.PSObject.Properties['SourceRunId'] -and $_.SourceRunId) { "https://github.com/$repo/actions/runs/$($_.SourceRunId)" } else { '' }
        }
    })
}

$payload | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Updated unstable tests list written to '$OutputPath' with $($updatedTests.Count) test(s)."
Write-Host "::notice::Unstable tests list updated with $($updatedTests.Count) test(s) for branch '$Branch'."

} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
