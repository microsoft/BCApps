param(
    [Parameter(Mandatory = $true)]
    [string] $Owner,
    [Parameter(Mandatory = $true)]
    [string] $Repo,
    [Parameter(Mandatory = $true)]
    [long] $RunId,
    [Parameter(Mandatory = $false)]
    [int] $MaxFailedJobs = 3,
    [Parameter(Mandatory = $false)]
    [int] $MinTotalJobs = 10,
    [Parameter(Mandatory = $false)]
    [int] $MaxAttempts = 1
)

# Fetch the run to verify it's a failure on first attempt
$runJson = gh api "/repos/$Owner/$Repo/actions/runs/$RunId" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "::warning::Failed to fetch run $RunId"
    exit 1
}
$run = $runJson | ConvertFrom-Json

if ($run.conclusion -ne 'failure') {
    Write-Host "Run $RunId concluded with '$($run.conclusion)', not 'failure'. Skipping."
    exit 0
}

if ($run.run_attempt -gt $MaxAttempts) {
    Write-Host "Run $RunId is on attempt $($run.run_attempt) (max $MaxAttempts). Skipping."
    exit 0
}

Write-Host "--- Checking run $($run.id): $($run.display_title) ---"

# Fetch all jobs (paginated)
$jobsJson = gh api "/repos/$Owner/$Repo/actions/runs/$RunId/jobs?filter=latest&per_page=100" --paginate --jq '.jobs[]' 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "::warning::Failed to fetch jobs for run $RunId"
    exit 1
}
$jobs = $jobsJson | ConvertFrom-Json

# Exclude utility jobs that are not actual build jobs
$excludedJobs = @("Pull Request Status Check", "Initialization")
$buildJobs = $jobs | Where-Object { $_.name -notin $excludedJobs -and $_.conclusion -ne 'skipped' }
$buildJobCount = ($buildJobs | Measure-Object).Count
$failedJobs = $buildJobs | Where-Object { $_.conclusion -eq 'failure' }
$failedCount = ($failedJobs | Measure-Object).Count

if ($failedCount -eq 0) {
    Write-Host "No failed build jobs found. Skipping."
    exit 0
}

if ($buildJobCount -lt $MinTotalJobs) {
    Write-Host "Too few build jobs ($buildJobCount < $MinTotalJobs). Run likely didn't reach the large matrix. Skipping."
    exit 0
}

if ($failedCount -gt $MaxFailedJobs) {
    Write-Host "Too many failed jobs ($failedCount > $MaxFailedJobs). Skipping."
    exit 0
}

Write-Host "Rerunning $failedCount failed job(s):"
$failedJobs | ForEach-Object { Write-Host "  - $($_.name)" }

$runUrl = "https://github.com/$Owner/$Repo/actions/runs/$RunId"
gh run rerun $RunId --failed --repo "$Owner/$Repo" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "::warning::Failed to rerun run $RunId"
    exit 1
} else {
    Write-Host "::notice::Rerun triggered for '$($run.display_title)': $runUrl"
}
