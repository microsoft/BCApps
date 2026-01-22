param (
    [Parameter(Mandatory = $false, HelpMessage="Threshold in hours for considering a check stale")]
    [int] $thresholdHours = 72,
    [Parameter(Mandatory = $false, HelpMessage="Maximum number of retry attempts")]
    [int] $maxRetries = 3
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version 2.0

Write-Host "Fetching open pull requests..."

# Get all open pull requests
$prs = gh pr list --state open --json number,title,url --limit 1000 | ConvertFrom-Json

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

    # Get checks for this PR
    try {
        $checks = gh pr checks $pr.number --json name,state,bucket,completedAt,link | ConvertFrom-Json
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

    Write-Host "  Status check is older than $thresholdHours hours, requesting rerun..."

    # Try to rerequest the check with retries
    $success = $false
    for ($retry = 0; $retry -lt $maxRetries; $retry++) {
        try {
            if ($retry -gt 0) {
                # Exponential backoff: 2s, 4s, 8s
                $delaySeconds = 2 * [Math]::Pow(2, $retry - 1)
                Write-Host "  Retry attempt $($retry + 1)/$maxRetries (waiting $delaySeconds seconds)..."
                Start-Sleep -Seconds $delaySeconds
            }

            # Rerequest the check by re-running the workflow
            # First, get the workflow run ID from the check link
            if ($statusCheck.link -match '/runs/(\d+)') {
                $runId = $matches[1]
                # Validate run ID is a positive integer
                if ([int]$runId -gt 0) {
                    gh run rerun $runId -R $env:GITHUB_REPOSITORY | Out-Null
                    Write-Host "  ✓ Successfully triggered re-run of workflow (run ID: $runId)"
                    $restarted++
                    $success = $true
                    break
                }
                else {
                    Write-Host "  ✗ Invalid run ID extracted: $runId"
                    $failed++
                    break
                }
            }
            else {
                Write-Host "  ✗ Could not extract run ID from link: $($statusCheck.link)"
                $failed++
                break
            }
        }
        catch {
            $errorMsg = $_.Exception.Message
            if ($retry -eq $maxRetries - 1) {
                Write-Host "  ✗ Failed to restart workflow after $maxRetries attempts: $errorMsg"
                $failed++
            }
            else {
                Write-Host "  ⚠ Attempt $($retry + 1) failed: $errorMsg"
            }
        }
    }
}

Write-Host ""
Write-Host "Summary:"
Write-Host "  ✓ Successfully restarted: $restarted workflow run(s)"
Write-Host "  ✗ Failed attempts: $failed"

# Add GitHub Actions job summary
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "## PR Status Check Restart Summary"
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ""
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- ✓ Successfully restarted: **$restarted** workflow run(s)"
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- ✗ Failed attempts: **$failed**"
