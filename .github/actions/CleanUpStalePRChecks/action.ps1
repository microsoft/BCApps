param (
    [Parameter(Mandatory = $false, HelpMessage="Threshold in hours for considering a check stale")]
    [int] $thresholdHours = 72,
    [Parameter(Mandatory = $false, HelpMessage="Maximum number of retry attempts")]
    [int] $maxRetries = 3,
    [Parameter(Mandatory = $false, HelpMessage="If specified, only performs read operations without triggering any reruns")]
    [switch] $WhatIf
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version 2.0

# Import EnlistmentHelperFunctions module
Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking

if ($WhatIf) {
    Write-Host "::notice::Running in WhatIf mode - no workflows will be rerun"
}

Write-Host "Fetching open pull requests..."

# Get all open pull requests with mergeable state
$prs = gh pr list --state open --json number,title,url,mergeable --limit 1000 | ConvertFrom-Json

Write-Host "Found $($prs.Count) open pull requests"

if ($prs.Count -eq 0) {
    Write-Host "::notice::No open pull requests found"
    exit 0
}

$now = [DateTime]::UtcNow
$restarted = 0
$failed = 0

foreach ($pr in $prs) {
    Write-Host ""
    Write-Host "Checking PR #$($pr.number): $($pr.title)"

    # Check if PR is mergeable
    if ($pr.mergeable -ne "MERGEABLE") {
        Write-Host "  PR is not in MERGEABLE state (current: $($pr.mergeable)), skipping"
        continue
    }

    # Get checks for this PR with retry
    $checks = $null
    try {
        $checks = Invoke-CommandWithRetry -ScriptBlock {
            gh pr checks $pr.number --json name,state,bucket,completedAt,link | ConvertFrom-Json
        } -RetryCount $maxRetries -FirstDelay 2 -MaxWaitBetweenRetries 8
    }
    catch {
        Write-Host "  ✗ Failed to get checks for PR: $_"
        $failed++
        continue
    }

    # Find the "Pull Request Status Check"
    $statusCheck = $checks | Where-Object { $_.name -eq "Pull Request Status Check" }

    if (-not $statusCheck) {
        Write-Host "  No 'Pull Request Status Check' found for this PR"
        continue
    }

    Write-Host "  Check state: $($statusCheck.state)"

    # Check if the check is completed and successful
    if ($statusCheck.state -ne "SUCCESS") {
        Write-Host "  Check state is '$($statusCheck.state)', not 'SUCCESS', skipping"
        continue
    }

    $completedAt = [DateTime]::Parse($statusCheck.completedAt, [System.Globalization.CultureInfo]::InvariantCulture)
    $ageInHours = ($now - $completedAt).TotalHours

    Write-Host "  Completed at: $completedAt UTC (Age: $([Math]::Round($ageInHours, 2)) hours)"

    if ($ageInHours -le $thresholdHours) {
        Write-Host "  Status check is recent enough, no action needed"
        continue
    }

    Write-Host "  Status check is older than $thresholdHours hours, deleting stale workflow run..."

    # Try to delete the workflow run and add a comment with retries using Invoke-CommandWithRetry
    $prFailed = $false
    try {
        # Extract run ID from the check link
        if ($statusCheck.link -match '/runs/(\d+)') {
            $runId = $matches[1]
            # Validate run ID is a positive integer
            if ([int64]$runId -gt 0) {
                if ($WhatIf) {
                    Write-Host "  [WhatIf] Would delete workflow run (run ID: $runId) and add comment to PR #$($pr.number)"
                    $restarted++
                }
                else {
                    # Delete the workflow run
                    Invoke-CommandWithRetry -ScriptBlock {
                        gh run delete $runId -R $env:GITHUB_REPOSITORY | Out-Null
                    } -RetryCount $maxRetries -FirstDelay 2 -MaxWaitBetweenRetries 8
                    Write-Host "  ✓ Successfully deleted workflow run (run ID: $runId)"

                    # Add a comment to the PR with instructions
                    $commentBody = @"
The Pull Request Status Check for this PR was stale (older than $thresholdHours hours) and has been deleted.

To unblock this PR and trigger a new status check, you can:
1. Push a new commit to the PR branch, or
2. Close and reopen the PR

This will automatically trigger a new Pull Request Build workflow run.
"@
                    Invoke-CommandWithRetry -ScriptBlock {
                        gh pr comment $pr.number --body $commentBody -R $env:GITHUB_REPOSITORY | Out-Null
                    } -RetryCount $maxRetries -FirstDelay 2 -MaxWaitBetweenRetries 8
                    Write-Host "  ✓ Added comment to PR #$($pr.number) with instructions"
                    $restarted++
                }
            }
            else {
                Write-Host "  ✗ Invalid run ID extracted: $runId"
                $prFailed = $true
            }
        }
        else {
            Write-Host "  ✗ Could not extract run ID from link: $($statusCheck.link)"
            $prFailed = $true
        }
    }
    catch {
        Write-Host "  ✗ Failed to delete workflow run or add comment: $_"
        $prFailed = $true
    }

    # Increment failed counter once per PR if any attempt failed
    if ($prFailed) {
        $failed++
    }
}

Write-Host ""
Write-Host "Summary:"
Write-Host "  ✓ Successfully processed: $restarted PR(s)"
Write-Host "  ✗ Failed to process: $failed PR(s)"

# Add GitHub Actions job summary
if ($env:GITHUB_STEP_SUMMARY) {
    $summaryTitle = if ($WhatIf) { "## Stale PR Status Check Cleanup Summary (WhatIf Mode)" } else { "## Stale PR Status Check Cleanup Summary" }
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summaryTitle
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ""
    if ($WhatIf) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- ℹ️ Running in **WhatIf mode** - no workflow runs were deleted"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ""
    }
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- ✓ Successfully processed: **$restarted** PR(s) (deleted stale workflow runs and added comments)"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- ✗ Failed to process: **$failed** PR(s)"
}

# Exit with error if there were any failures (not in WhatIf mode)
if ($failed -gt 0 -and -not $WhatIf) {
    Write-Host "::error::Failed to process $failed PR(s)"
    exit 1
}
