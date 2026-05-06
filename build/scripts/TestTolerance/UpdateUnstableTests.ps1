<#
.Synopsis
    Updates the per-branch unstable tests artifact by examining recent CI/CD runs.

.Description
    Called by the UpdateUnstableTests workflow after a CI/CD run completes. It:
    1. Locates the last <RunWindow> completed CI/CD runs on the branch.
    2. Downloads all TestResults.xml artifacts from each of those runs.
    3. Identifies every test that failed in at least one of those runs.
    4. Writes a new unstable-tests.json listing those tests.

    The list is fully recomputed each time — no incremental merging.

.Parameter Branch
    Branch name (e.g. 'main', 'releases/26.0').

.Parameter OutputPath
    Path where the updated unstable-tests.json should be written.

.Parameter RunWindow
    Number of recent CI/CD runs to examine. Default: 3.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath,

    [int] $RunWindow = 3
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TestTolerance.psm1') -Force

$repo = $env:GITHUB_REPOSITORY

# --- 1. Determine which runs to examine ---

Write-Host "Finding completed CI/CD runs on '$Branch' (window: $RunWindow) ..."
$recentRuns = @(gh run list --repo $repo --workflow 'CICD.yaml' --branch $Branch --status completed --limit 20 --json databaseId,conclusion | ConvertFrom-Json | Where-Object { $_.conclusion -ne 'cancelled' } | Select-Object -ExpandProperty databaseId)

$runIds = @()
if ($recentRuns.Count -eq 0) {
    Write-Host "No completed CI/CD runs found on branch '$Branch'. Writing empty unstable list."
} else {
    $runIds = @($recentRuns | Select-Object -First $RunWindow)
}

Write-Host "Examining $($runIds.Count) run(s): $($runIds -join ', ')"

# --- 2. Download and parse test results from all runs ---

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-updater-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {

$allFailed = @{}

foreach ($runId in $runIds) {
    $allArtifacts = @(gh api --paginate "/repos/$repo/actions/runs/$runId/artifacts?per_page=100" --jq '.artifacts[]' | ConvertFrom-Json)
    $testResultArtifacts = @($allArtifacts | Where-Object { $_.name -match 'TestResults' -and $_.name -notmatch 'BcptTestResults|PageScriptingTestResult' -and -not $_.expired })
    Write-Host "Run ${runId}: found $($testResultArtifacts.Count) test result artifact(s)."

    foreach ($artifact in $testResultArtifacts) {
        try {
            $zipPath = Join-Path $tempDir "$($artifact.name)-$runId.zip"
            $extractDir = Join-Path $tempDir "$($artifact.name)-$runId"

            # Use Invoke-WebRequest instead of gh api because gh api has no option to save binary responses to a file.
            $token = (gh auth token)
            Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/actions/artifacts/$($artifact.id)/zip" `
                -Headers @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' } `
                -OutFile $zipPath
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
            foreach ($xml in @(Get-ChildItem -Path $extractDir -Filter '*.xml' -Recurse)) {
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
        catch {
            Write-Host "Warning: failed to download artifact '$($artifact.name)' from run ${runId}: $($_.Exception.Message)"
        }
    }
}

Write-Host "Observed $($allFailed.Count) distinct failed test(s) across $($runIds.Count) run(s)."

# --- 3. Build updated unstable list ---

$updatedTests = Update-UnstableTestsList -FailedTests $allFailed -RunWindow $RunWindow

# --- 4. Write artifact ---

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$payload = [ordered]@{
    branch    = $Branch
    updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    runIds    = @($runIds | ForEach-Object { [string]$_ })
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

} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
