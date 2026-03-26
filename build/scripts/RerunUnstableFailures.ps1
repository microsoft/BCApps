param(
    [Parameter(Mandatory = $true)]
    [string] $Owner,
    [Parameter(Mandatory = $true)]
    [string] $Repo,
    [Parameter(Mandatory = $false)]
    [int] $MaxFailedJobs = 3,
    [Parameter(Mandatory = $false)]
    [int] $MinTotalJobs = 10,
    [Parameter(Mandatory = $false)]
    [int] $MaxAttempts = 1,
    [Parameter(Mandatory = $false)]
    [int] $LookbackHours = 2,
    [Parameter(Mandatory = $false)]
    [switch] $WhatIf
)

$cutoff = (Get-Date).ToUniversalTime().AddHours(-$LookbackHours).ToString("yyyy-MM-ddTHH:mm:ssZ")
$workflowFiles = @("CICD.yaml", "PullRequestHandler.yaml")

foreach ($workflowFile in $workflowFiles) {
    Write-Host "===== Processing workflow: $workflowFile ====="

    # Get recent completed runs
    $runsJson = gh api "/repos/$Owner/$Repo/actions/workflows/$workflowFile/runs?status=completed&created=%3E$cutoff&per_page=100" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "::warning::Failed to fetch runs for $workflowFile"
        continue
    }
    $runs = ($runsJson | ConvertFrom-Json).workflow_runs

    # Filter to failures on first attempt only
    $failedRuns = $runs | Where-Object { $_.conclusion -eq 'failure' -and $_.run_attempt -le $MaxAttempts }
    if (-not $failedRuns) {
        Write-Host "No eligible failed runs found."
        continue
    }

    # For PR builds: deduplicate by PR number, keep latest per PR, skip if latest run for that PR is not a failure
    if ($workflowFile -eq "PullRequestHandler.yaml") {
        $candidates = @()
        $prGroups = $runs | Where-Object { $_.pull_requests.Count -gt 0 } | Group-Object { ($_.pull_requests | Select-Object -First 1).number }
        foreach ($group in $prGroups) {
            $latest = $group.Group | Sort-Object created_at -Descending | Select-Object -First 1
            if ($latest.conclusion -eq 'failure' -and $latest.run_attempt -le $MaxAttempts) {
                $candidates += $latest
            }
        }
        $failedRuns = $candidates
    }

    if (-not $failedRuns) {
        Write-Host "No eligible failed runs after deduplication."
        continue
    }

    foreach ($run in $failedRuns) {
        Write-Host "--- Checking run $($run.id): $($run.display_title) ---"

        # Count failed jobs
        $jobsJson = gh api "/repos/$Owner/$Repo/actions/runs/$($run.id)/jobs?filter=latest&per_page=100" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "::warning::Failed to fetch jobs for run $($run.id)"
            continue
        }
        $jobs = ($jobsJson | ConvertFrom-Json).jobs
        # Exclude utility jobs that are not actual build jobs
        $excludedJobs = @("Pull Request Status Check", "Initialization")
        $buildJobs = $jobs | Where-Object { $_.name -notin $excludedJobs -and $_.conclusion -ne 'skipped' }
        $buildJobCount = ($buildJobs | Measure-Object).Count
        $failedJobs = $buildJobs | Where-Object { $_.conclusion -eq 'failure' }
        $failedCount = ($failedJobs | Measure-Object).Count

        if ($failedCount -eq 0) {
            Write-Host "No failed build jobs found. Skipping."
            continue
        }

        if ($buildJobCount -lt $MinTotalJobs) {
            Write-Host "Too few build jobs ($buildJobCount < $MinTotalJobs). Run likely didn't reach the large matrix. Skipping."
            continue
        }

        if ($failedCount -gt $MaxFailedJobs) {
            Write-Host "Too many failed jobs ($failedCount > $MaxFailedJobs). Skipping."
            continue
        }

        Write-Host "Rerunning $failedCount failed job(s):"
        $failedJobs | ForEach-Object { Write-Host "  - $($_.name)" }

        $runUrl = "https://github.com/$Owner/$Repo/actions/runs/$($run.id)"
        if ($WhatIf) {
            Write-Host "::notice::WhatIf: Would rerun '$($run.display_title)': $runUrl"
        } else {
            gh run rerun $run.id --failed --repo "$Owner/$Repo" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "::warning::Failed to rerun run $($run.id)"
            } else {
                Write-Host "::notice::Rerun triggered for '$($run.display_title)': $runUrl"
            }
        }
    }
}

Write-Host "===== Done ====="
