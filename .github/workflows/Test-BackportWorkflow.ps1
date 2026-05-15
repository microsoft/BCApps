<#
.SYNOPSIS
    Simulates the backport-on-label.yml workflow locally using PowerShell + gh CLI.

.DESCRIPTION
    Runs through the same steps as the GitHub Actions workflow:
      1. Resolve PR details (title, body, labels, merge commit)
      2. Extract linked issue from PR body
      3. Identify version labels → validate release branches exist
      4. Cherry-pick merge commit onto each release branch
      5. Create backport PRs with structured description + "Linked" label

    Supports -DryRun to preview all steps without pushing or creating PRs.

.PARAMETER PrNumber
    The PR number (merged to main) to backport.

.PARAMETER Repo
    The GitHub repository in owner/repo format. Default: microsoft/BCApps

.PARAMETER DryRun
    Preview all steps without pushing branches or creating PRs.

.EXAMPLE
    # Dry run — see what would happen without making changes
    .\Test-BackportWorkflow.ps1 -PrNumber 7700 -DryRun

.EXAMPLE
    # Actually create backport branches and PRs
    .\Test-BackportWorkflow.ps1 -PrNumber 7700
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [int]$PrNumber,

    [string]$Repo = "microsoft/BCApps",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step { param([string]$Step, [string]$Message) Write-Host "`n== Step $Step ==" -ForegroundColor Cyan; Write-Host $Message }
function Write-Ok { param([string]$Message) Write-Host "  OK: $Message" -ForegroundColor Green }
function Write-Skip { param([string]$Message) Write-Host "  SKIP: $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "  FAIL: $Message" -ForegroundColor Red }
function Write-Dry { param([string]$Message) Write-Host "  [DRY RUN] $Message" -ForegroundColor Magenta }

# ─────────────────────────────────────────────────────────────────────────────
# Pre-checks
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nBackport Workflow Simulator" -ForegroundColor White
Write-Host "PR: #$PrNumber | Repo: $Repo | DryRun: $DryRun`n" -ForegroundColor Gray

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required. Install from https://cli.github.com/"
}

# Verify gh is authenticated
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "gh CLI is not authenticated. Run 'gh auth login' first."
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Resolve PR details
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1" "Resolving PR #$PrNumber details..."

$prJson = gh api "/repos/$Repo/pulls/$PrNumber" | ConvertFrom-Json

if (-not $prJson.merged) {
    throw "PR #$PrNumber is not merged. The backport workflow only works on merged PRs."
}

$prTitle = $prJson.title
$prBody = $prJson.body
$mergeCommit = $prJson.merge_commit_sha
$labels = $prJson.labels | ForEach-Object { $_.name }

Write-Ok "Title: $prTitle"
Write-Ok "Merge commit: $mergeCommit"
Write-Ok "Labels: $($labels -join ', ')"

# Verify Backported label
if ('Backported' -notin $labels) {
    throw "PR #$PrNumber does not have the 'Backported' label."
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Extract linked issue from PR body
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "2" "Extracting linked issue from PR body..."

$issueNum = $null
if ($prBody -match '(?i)(?:fix|fixes|fixed|close|closes|closed|resolve|resolves|resolved)\s+#(\d+)') {
    $issueNum = $Matches[1]
    Write-Ok "Linked issue: #$issueNum"
}
else {
    Write-Skip "No linked issue found in PR description."
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Identify version labels and validate branches
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "3" "Identifying version labels and validating release branches..."

$versionLabels = $labels | Where-Object { $_ -match '^\d+\.[a-zA-Z0-9]+$' }

if (-not $versionLabels) {
    Write-Skip "No version labels found (e.g., 28.x, 28.1). Nothing to backport."
    exit 0
}

$validTargets = @()
$invalidTargets = @()

foreach ($label in $versionLabels) {
    $branch = "releases/$label"
    $lsRemote = git ls-remote --exit-code --heads origin $branch 2>&1
    if ($LASTEXITCODE -eq 0) {
        $validTargets += $label
        Write-Ok "Branch $branch exists"
    }
    else {
        $invalidTargets += $label
        Write-Fail "Branch $branch does not exist for label '$label'"
    }
}

if ($invalidTargets.Count -gt 0) {
    Write-Host "`n  Warning: These version labels have no matching release branch:" -ForegroundColor Yellow
    $invalidTargets | ForEach-Object { Write-Host "    - releases/$_" -ForegroundColor Yellow }
}

if ($validTargets.Count -eq 0) {
    Write-Skip "No valid target branches found. Nothing to backport."
    exit 0
}

Write-Host "`n  Targets to process: $($validTargets -join ', ')" -ForegroundColor White

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Cherry-pick and create PRs
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "4" "Cherry-picking and creating backport PRs..."

# Save current branch to restore later
$originalBranch = git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0) { $originalBranch = git rev-parse HEAD }

git config user.name "github-actions[bot]" 2>$null
git config user.email "github-actions[bot]@users.noreply.github.com" 2>$null

$summarySuccess = @()
$summarySkipped = @()
$summaryFailed = @()

foreach ($version in $validTargets) {
    $targetBranch = "releases/$version"
    $backportBranch = "backport/$targetBranch/$PrNumber"

    Write-Host "`n  --- Processing $targetBranch ---" -ForegroundColor Cyan

    # 4.1 Idempotency check
    $existingPr = gh api "/repos/$Repo/pulls?head=$($Repo.Split('/')[1]):$backportBranch&base=$targetBranch&state=open" --jq '.[0].number // empty' 2>$null
    if ($existingPr) {
        Write-Skip "Backport PR #$existingPr already exists for $targetBranch"
        $summarySkipped += [PSCustomObject]@{ Branch = $targetBranch; Detail = "PR #$existingPr already exists" }
        continue
    }

    # 4.2 Create cherry-pick branch
    Write-Host "  Fetching $targetBranch..." -ForegroundColor Gray
    git fetch origin $targetBranch --quiet 2>$null

    # Clean up any leftover local branch from previous runs
    git branch -D $backportBranch 2>$null | Out-Null
    git checkout -b $backportBranch "origin/$targetBranch" 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Could not checkout origin/$targetBranch"
        $summaryFailed += [PSCustomObject]@{ Branch = $targetBranch; Detail = "checkout failed" }
        git checkout $originalBranch --quiet 2>$null
        continue
    }

    # 4.3 Cherry-pick
    $parentCount = (git cat-file -p $mergeCommit | Select-String '^parent ').Count

    Write-Host "  Cherry-picking $($mergeCommit.Substring(0,10))... (parents: $parentCount)" -ForegroundColor Gray

    if ($parentCount -gt 1) {
        git cherry-pick $mergeCommit -m 1 --no-edit 2>&1 | Out-Null
    }
    else {
        git cherry-pick $mergeCommit --no-edit 2>&1 | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Cherry-pick failed for $targetBranch (conflicts)"
        git cherry-pick --abort 2>$null
        git checkout $originalBranch --quiet 2>$null
        git branch -D $backportBranch 2>$null | Out-Null
        $summaryFailed += [PSCustomObject]@{ Branch = $targetBranch; Detail = "cherry-pick conflict" }
        continue
    }

    Write-Ok "Cherry-pick succeeded"

    # 4.4 Push + create PR
    if ($DryRun) {
        Write-Dry "Would push branch: $backportBranch"

        $bpTitle = "[$targetBranch] $prTitle"
        $bpBody = "This is a backport of #$PrNumber"
        if ($issueNum) { $bpBody += "`n`nFixes #$issueNum" }

        Write-Dry "Would create PR:"
        Write-Host "    Title: $bpTitle" -ForegroundColor Magenta
        Write-Host "    Base:  $targetBranch" -ForegroundColor Magenta
        Write-Host "    Head:  $backportBranch" -ForegroundColor Magenta
        Write-Host "    Body:  $bpBody" -ForegroundColor Magenta
        Write-Dry "Would add label: Linked"

        $summarySuccess += [PSCustomObject]@{ Branch = $targetBranch; Detail = "[dry run] would create PR" }
    }
    else {
        Write-Host "  Pushing $backportBranch..." -ForegroundColor Gray
        git push origin $backportBranch 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Push failed for $backportBranch"
            $summaryFailed += [PSCustomObject]@{ Branch = $targetBranch; Detail = "push failed" }
            git checkout $originalBranch --quiet 2>$null
            git branch -D $backportBranch 2>$null | Out-Null
            continue
        }

        $bpTitle = "[$targetBranch] $prTitle"
        if ($bpTitle.Length -gt 255) { $bpTitle = $bpTitle.Substring(0, 255) }

        $bpBody = "This is a backport of #$PrNumber"
        if ($issueNum) { $bpBody += "`n`nFixes #$issueNum" }

        $newPrUrl = gh pr create --repo $Repo --base $targetBranch --head $backportBranch --title $bpTitle --body $bpBody
        $newPrNum = ($newPrUrl -split '/')[-1]

        gh pr edit $newPrNum --repo $Repo --add-label "Linked"

        Write-Ok "Created backport PR: $newPrUrl"
        $summarySuccess += [PSCustomObject]@{ Branch = $targetBranch; Detail = $newPrUrl }
    }

    # Return to clean state
    git checkout $originalBranch --quiet 2>$null
    git branch -D $backportBranch 2>$null | Out-Null
}

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor White
Write-Host " Backport Summary for PR #$PrNumber" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White

if ($summarySuccess.Count -gt 0) {
    Write-Host "`n  Created:" -ForegroundColor Green
    $summarySuccess | ForEach-Object { Write-Host "    - $($_.Branch): $($_.Detail)" -ForegroundColor Green }
}
if ($summarySkipped.Count -gt 0) {
    Write-Host "`n  Skipped:" -ForegroundColor Yellow
    $summarySkipped | ForEach-Object { Write-Host "    - $($_.Branch): $($_.Detail)" -ForegroundColor Yellow }
}
if ($summaryFailed.Count -gt 0) {
    Write-Host "`n  Failed:" -ForegroundColor Red
    $summaryFailed | ForEach-Object { Write-Host "    - $($_.Branch): $($_.Detail)" -ForegroundColor Red }
}

if ($summarySuccess.Count -eq 0 -and $summarySkipped.Count -eq 0 -and $summaryFailed.Count -eq 0) {
    Write-Host "`n  No backport actions were taken." -ForegroundColor Gray
}

# Restore original branch
Write-Host "`n  Restoring branch: $originalBranch" -ForegroundColor Gray
git checkout $originalBranch --quiet 2>$null

Write-Host "`nDone.`n" -ForegroundColor White
