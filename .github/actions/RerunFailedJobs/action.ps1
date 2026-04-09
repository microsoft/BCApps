param (
    [Parameter(Mandatory = $true, HelpMessage = "The workflow run ID of the failed run")]
    [string] $RunId,
    [Parameter(Mandatory = $false, HelpMessage = "Maximum number of rerun attempts before giving up")]
    [int] $MaxRerunAttempts = 2,
    [Parameter(Mandatory = $false, HelpMessage = "Maximum number of failed jobs to analyze")]
    [int] $MaxFailedJobs = 3
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version 2.0

<#
    .SYNOPSIS
    Gets the workflow run details.
    .PARAMETER RunId
    The workflow run ID.
    .RETURNS
    The workflow run object.
#>
function Get-WorkflowRun {
    param (
        [Parameter(Mandatory = $true)]
        [string] $RunId
    )

    $run = gh api "/repos/$env:GITHUB_REPOSITORY/actions/runs/$RunId" `
        -H "Accept: application/vnd.github+json" `
        -H "X-GitHub-Api-Version: 2022-11-28" | ConvertFrom-Json

    return $run
}

<#
    .SYNOPSIS
    Gets the failed jobs from a workflow run.
    .PARAMETER RunId
    The workflow run ID.
    .RETURNS
    An array of failed job objects.
#>
function Get-FailedJobs {
    param (
        [Parameter(Mandatory = $true)]
        [string] $RunId
    )

    $allJobs = @()
    $page = 1

    # Paginate through all jobs
    while ($true) {
        $response = gh api "/repos/$env:GITHUB_REPOSITORY/actions/runs/$RunId/jobs?per_page=100&page=$page&filter=latest" `
            -H "Accept: application/vnd.github+json" `
            -H "X-GitHub-Api-Version: 2022-11-28" | ConvertFrom-Json

        if ($response.jobs.Count -eq 0) {
            break
        }

        $allJobs += $response.jobs
        if ($allJobs.Count -ge $response.total_count) {
            break
        }

        $page++
    }

    $failedJobs = $allJobs | Where-Object { $_.conclusion -eq "failure" }

    return @($failedJobs)
}

<#
    .SYNOPSIS
    Gets the logs for a specific job.
    .PARAMETER JobId
    The job ID.
    .RETURNS
    The job logs as a string (last 200 lines).
#>
function Get-JobLogs {
    param (
        [Parameter(Mandatory = $true)]
        [string] $JobId
    )

    $logs = gh api "/repos/$env:GITHUB_REPOSITORY/actions/jobs/$JobId/logs" 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Warning: Could not fetch logs for job $JobId"
        return ""
    }

    # Return last 200 lines to keep within reasonable size for analysis
    $lines = $logs -split "`n"
    if ($lines.Count -gt 200) {
        $lines = $lines[-200..-1]
    }

    return ($lines -join "`n")
}

<#
    .SYNOPSIS
    Analyzes a job failure log to determine if it is an instability (flaky/transient failure).
    .DESCRIPTION
    Uses the GitHub Copilot models API to analyze the error log and determine
    if the failure is a known instability pattern (e.g., timeout, network issue,
    resource contention, flaky test, infrastructure issue).
    .PARAMETER JobName
    The name of the failed job.
    .PARAMETER Logs
    The job's error logs.
    .RETURNS
    A hashtable with 'IsInstability' (bool) and 'Reason' (string) fields.
#>
function Get-InstabilityAnalysis {
    param (
        [Parameter(Mandatory = $true)]
        [string] $JobName,
        [Parameter(Mandatory = $true)]
        [string] $Logs
    )

    $prompt = @"
You are analyzing a CI/CD job failure log to determine if it represents a transient/flaky instability or a genuine code issue.

Job name: $JobName

Analyze the following error log and determine if this is an INSTABILITY (transient/flaky failure) or a GENUINE failure.

Common instability patterns include:
- Network timeouts or connection failures
- Docker/container startup failures
- Resource exhaustion (disk space, memory) on CI runners
- Transient Azure/cloud service errors
- HTTP 429 (rate limiting) or 503 (service unavailable) errors
- File locking or access issues that are intermittent
- Flaky test failures that pass on retry
- "The process cannot access the file because it is being used by another process"
- Container health check failures
- DNS resolution failures
- Artifact download failures
- BcContainer or Docker-related transient errors

Genuine failure patterns include:
- Compilation errors in AL code
- Test assertion failures that indicate logic bugs
- Missing dependencies or references that are part of the code change
- Configuration errors introduced by code changes
- Consistent, reproducible error patterns

Respond with ONLY a JSON object (no markdown, no code blocks) in this exact format:
{"isInstability": true/false, "reason": "brief explanation"}

Error log:
$Logs
"@

    $body = @{
        messages = @(
            @{
                role    = "user"
                content = $prompt
            }
        )
        model = "gpt-4o"
    } | ConvertTo-Json -Depth 5

    try {
        $response = $body | gh api "/models/chat/completions" `
            -H "Accept: application/vnd.github+json" `
            -H "X-GitHub-Api-Version: 2022-11-28" `
            --method POST --input - | ConvertFrom-Json

        $content = $response.choices[0].message.content.Trim()

        # Strip markdown code block fences if present
        $content = $content -replace '(?s)^```(?:json)?\s*', '' -replace '(?s)\s*```$', ''

        $analysis = $content | ConvertFrom-Json

        return @{
            IsInstability = [bool]$analysis.isInstability
            Reason        = [string]$analysis.reason
        }
    }
    catch {
        Write-Host "  Warning: AI analysis failed for job '$JobName': $_"
        # If AI analysis fails, we err on the side of caution and don't rerun
        return @{
            IsInstability = $false
            Reason        = "AI analysis failed: $_"
        }
    }
}

<#
    .SYNOPSIS
    Posts a comment on the PR associated with the workflow run.
    .PARAMETER Run
    The workflow run object.
    .PARAMETER Comment
    The comment body to post.
#>
function Add-PRComment {
    param (
        [Parameter(Mandatory = $true)]
        $Run,
        [Parameter(Mandatory = $true)]
        [string] $Comment
    )

    # Get the PR number from the pull_requests array in the run
    $prNumber = $null
    if ($Run.pull_requests -and $Run.pull_requests.Count -gt 0) {
        $prNumber = $Run.pull_requests[0].number
    }

    if (-not $prNumber) {
        Write-Host "Could not determine PR number from workflow run, skipping comment"
        return
    }

    gh api "/repos/$env:GITHUB_REPOSITORY/issues/$prNumber/comments" `
        -H "Accept: application/vnd.github+json" `
        -H "X-GitHub-Api-Version: 2022-11-28" `
        -f body="$Comment" | Out-Null

    Write-Host "Posted comment to PR #$prNumber"
}

<#
    .SYNOPSIS
    Reruns only the failed jobs in a workflow run.
    .PARAMETER RunId
    The workflow run ID.
#>
function Invoke-RerunFailedJobs {
    param (
        [Parameter(Mandatory = $true)]
        [string] $RunId
    )

    gh run rerun $RunId --failed -R $env:GITHUB_REPOSITORY
}

# --- Main logic ---

Write-Host "Analyzing workflow run $RunId for instabilities..."

# Step 1: Get the workflow run details
$run = Get-WorkflowRun -RunId $RunId
$currentAttempt = $run.run_attempt
Write-Host "Current run attempt: $currentAttempt (max rerun attempts: $MaxRerunAttempts)"

# Step 2: Check if we've already exceeded the maximum number of reruns
if ($currentAttempt -gt $MaxRerunAttempts) {
    Write-Host "::notice::Run has already been attempted $currentAttempt times (max: $MaxRerunAttempts). Skipping rerun."
    exit 0
}

# Step 3: Get the failed jobs
$failedJobs = Get-FailedJobs -RunId $RunId
$failedJobCount = $failedJobs.Count

Write-Host "Found $failedJobCount failed job(s)"

if ($failedJobCount -eq 0) {
    Write-Host "::notice::No failed jobs found. Nothing to do."
    exit 0
}

if ($failedJobCount -gt $MaxFailedJobs) {
    Write-Host "::notice::Too many failed jobs ($failedJobCount > $MaxFailedJobs). Skipping instability analysis."
    exit 0
}

# Step 4: Analyze each failed job
$analysisResults = @()
$allInstabilities = $true

foreach ($job in $failedJobs) {
    Write-Host ""
    Write-Host "Analyzing job: $($job.name) (ID: $($job.id))"

    $logs = Get-JobLogs -JobId $job.id

    if ([string]::IsNullOrWhiteSpace($logs)) {
        Write-Host "  No logs available for job $($job.name). Treating as non-instability."
        $analysisResults += @{
            JobName       = $job.name
            IsInstability = $false
            Reason        = "No logs available for analysis"
        }
        $allInstabilities = $false
        continue
    }

    $analysis = Get-InstabilityAnalysis -JobName $job.name -Logs $logs

    Write-Host "  Is instability: $($analysis.IsInstability)"
    Write-Host "  Reason: $($analysis.Reason)"

    $analysisResults += @{
        JobName       = $job.name
        IsInstability = $analysis.IsInstability
        Reason        = $analysis.Reason
    }

    if (-not $analysis.IsInstability) {
        $allInstabilities = $false
    }
}

# Step 5: If all failures are instabilities, rerun failed jobs and post a comment
Write-Host ""
if ($allInstabilities) {
    Write-Host "All $failedJobCount failed job(s) identified as instabilities. Rerunning failed jobs..."

    Invoke-RerunFailedJobs -RunId $RunId

    # Build comment
    $jobDetails = ($analysisResults | ForEach-Object {
        "| $($_.JobName) | $($_.Reason) |"
    }) -join "`n"

    $comment = @"
## 🔄 Automatic Rerun - Instability Detected

The **Pull Request Build** workflow run [#$RunId](https://github.com/$env:GITHUB_REPOSITORY/actions/runs/$RunId) (attempt $currentAttempt) failed with **$failedJobCount job(s)** identified as transient instabilities.

The failed jobs have been automatically rerun.

### Analysis Summary

| Job | Reason |
|-----|--------|
$jobDetails

> _This is an automated action. If the issue persists after rerun, it may require manual investigation._
"@

    Add-PRComment -Run $run -Comment $comment
    Write-Host "::notice::Successfully rerun failed jobs and posted PR comment."
}
else {
    Write-Host "::notice::Not all failures are instabilities. Manual investigation required."

    # Build informational summary for the step summary
    $summary = "## Instability Analysis Results`n`n"
    $summary += "| Job | Instability? | Reason |`n"
    $summary += "|-----|-------------|--------|`n"
    foreach ($result in $analysisResults) {
        $marker = if ($result.IsInstability) { "✅ Yes" } else { "❌ No" }
        $summary += "| $($result.JobName) | $marker | $($result.Reason) |`n"
    }

    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summary
    }

    Write-Host $summary
}
