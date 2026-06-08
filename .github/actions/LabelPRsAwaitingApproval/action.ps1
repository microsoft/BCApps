param (
    [Parameter(Mandatory = $false, HelpMessage = "Label to manage on PRs awaiting workflow approval")]
    [string] $Label = 'needs-approval',
    [Parameter(Mandatory = $false, HelpMessage = "Dry-run mode - log changes without applying them")]
    [switch] $WhatIf
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version 2.0

$repo = $env:GITHUB_REPOSITORY
if (-not $repo) {
    throw "GITHUB_REPOSITORY environment variable is not set"
}

if ($WhatIf) {
    Write-Host "::notice::Running in WhatIf mode - no label changes will be applied"
}

function Invoke-GhApi {
    param (
        [Parameter(Mandatory = $true)] [string[]] $Arguments,
        [int] $MaxRetries = 3
    )
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        $stderrFile = [System.IO.Path]::GetTempFileName()
        try {
            # Redirect stderr to a temp file so deprecation notices / warnings
            # don't get prepended to stdout and break ConvertFrom-Json.
            $stdout = & gh api @Arguments 2>$stderrFile
            if ($LASTEXITCODE -eq 0) {
                $stderrText = Get-Content -Path $stderrFile -Raw -ErrorAction SilentlyContinue
                if ($stderrText -and $stderrText.Trim()) {
                    Write-Host "  gh api stderr: $($stderrText.Trim())"
                }
                return $stdout
            }
            $stderrText = Get-Content -Path $stderrFile -Raw -ErrorAction SilentlyContinue
            throw "gh api failed (exit $LASTEXITCODE): $stderrText"
        }
        catch {
            if ($attempt -eq $MaxRetries) { throw }
            Start-Sleep -Seconds ([Math]::Pow(2, $attempt))
        }
        finally {
            Remove-Item -Path $stderrFile -ErrorAction SilentlyContinue
        }
    }
}

function Ensure-Label {
    param ([string] $Name)
    $stderrFile = [System.IO.Path]::GetTempFileName()
    try {
        & gh api "repos/$repo/labels/$([Uri]::EscapeDataString($Name))" 2>$stderrFile | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Label '$Name' exists"
            return
        }
        $errText = Get-Content -Path $stderrFile -Raw -ErrorAction SilentlyContinue
        # Only treat genuine "not found" responses as a signal to create the
        # label. Other failures (rate limiting, 5xx, network) should bubble
        # up so they're not masked as a missing-label condition.
        if ($errText -notmatch 'HTTP 404|Not Found') {
            throw "Unexpected error checking label '$Name' (exit $LASTEXITCODE): $errText"
        }
        Write-Host "Label '$Name' not found - creating it"
        if ($WhatIf) {
            Write-Host "  [WhatIf] Would create label '$Name'"
            return
        }
        & gh label create $Name --repo $repo --color 'FBCA04' --description 'Workflow runs require maintainer approval to start' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create label '$Name'"
        }
    }
    finally {
        Remove-Item -Path $stderrFile -ErrorAction SilentlyContinue
    }
}

function Get-AwaitingApprovalPRs {
    Write-Host ""
    Write-Host "Fetching open PRs in $repo (for head-SHA mapping)..."
    # With --paginate, gh runs the --jq filter against each page and emits the
    # results concatenated. We use a filter that emits one JSON object per
    # line, and parse them individually below (NDJSON style) - this avoids
    # the "multiple JSON arrays concatenated" problem that breaks
    # ConvertFrom-Json.
    $prsJson = Invoke-GhApi -Arguments @('--paginate', "repos/$repo/pulls?state=open&per_page=100", '--jq', '.[] | {number: .number, sha: .head.sha}')
    $openPRs = @($prsJson | Where-Object { $_ -and $_.ToString().Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    Write-Host "Found $($openPRs.Count) open PR(s)"

    # Map of current PR head SHA -> list of PR numbers. We match action_required
    # runs against the *current* head only, so PRs with stale action_required
    # runs from older commits (whose newer commits have been approved) are not
    # falsely flagged. A list (rather than a single PR) handles the edge case
    # where multiple open PRs share the same head SHA (e.g. one PR per base
    # branch from a single commit).
    $headShaToPRs = @{}
    foreach ($pr in $openPRs) {
        if ($pr.sha) {
            if (-not $headShaToPRs.ContainsKey($pr.sha)) {
                $headShaToPRs[$pr.sha] = [System.Collections.Generic.List[int]]::new()
            }
            $headShaToPRs[$pr.sha].Add([int]$pr.number)
        }
    }

    Write-Host ""
    Write-Host "Fetching workflow runs with status=action_required..."
    $runsJson = Invoke-GhApi -Arguments @('--paginate', "repos/$repo/actions/runs?status=action_required&per_page=100", '--jq', '.workflow_runs[]')
    $runs = @($runsJson | Where-Object { $_ -and $_.ToString().Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    Write-Host "Found $($runs.Count) action_required workflow run(s)"

    $awaiting = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($run in $runs) {
        if (($run.PSObject.Properties.Name -contains 'head_sha') -and $run.head_sha -and $headShaToPRs.ContainsKey($run.head_sha)) {
            foreach ($prNum in $headShaToPRs[$run.head_sha]) {
                [void]$awaiting.Add($prNum)
            }
        }
    }

    # Comma prevents PowerShell from unrolling the HashSet (which would
    # turn an empty set into $null at the call site).
    return ,$awaiting
}

function Get-LabeledPRs {
    param ([string] $LabelName)
    Write-Host ""
    Write-Host "Fetching open PRs currently labelled '$LabelName'..."
    $encoded = [Uri]::EscapeDataString($LabelName)
    $json = Invoke-GhApi -Arguments @('--paginate', "repos/$repo/issues?state=open&labels=$encoded&per_page=100", '--jq', '.[] | select(.pull_request) | .number')
    $set = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($n in @($json | Where-Object { $_ -and $_.ToString().Trim() -match '^\d+$' })) {
        [void]$set.Add([int]$n)
    }
    Write-Host "Found $($set.Count) PR(s) with label '$LabelName'"
    return ,$set
}

# --- Main ---

Ensure-Label -Name $Label
$awaitingPRs = Get-AwaitingApprovalPRs
$labeledPRs  = Get-LabeledPRs -LabelName $Label

if ($awaitingPRs.Count -gt 0) {
    Write-Host ""
    Write-Host "PRs awaiting approval:"
    $awaitingPRs | Sort-Object | ForEach-Object { Write-Host "  - #$_" }
}

$toAdd    = @($awaitingPRs | Where-Object { -not $labeledPRs.Contains($_) } | Sort-Object)
$toRemove = @($labeledPRs  | Where-Object { -not $awaitingPRs.Contains($_) } | Sort-Object)

Write-Host ""
Write-Host "Plan: add '$Label' to $($toAdd.Count) PR(s), remove from $($toRemove.Count) PR(s)"

$added = 0; $removed = 0; $failed = 0

foreach ($pr in $toAdd) {
    Write-Host "  + Add '$Label' to PR #$pr"
    if ($WhatIf) { $added++; continue }
    try {
        & gh pr edit $pr --repo $repo --add-label $Label 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "gh pr edit exited with $LASTEXITCODE" }
        $added++
    }
    catch {
        Write-Host "    ::warning::Failed to add label to PR #${pr}: $_"
        $failed++
    }
}

foreach ($pr in $toRemove) {
    Write-Host "  - Remove '$Label' from PR #$pr"
    if ($WhatIf) { $removed++; continue }
    try {
        & gh pr edit $pr --repo $repo --remove-label $Label 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "gh pr edit exited with $LASTEXITCODE" }
        $removed++
    }
    catch {
        Write-Host "    ::warning::Failed to remove label from PR #${pr}: $_"
        $failed++
    }
}

Write-Host ""
Write-Host "Summary:"
Write-Host "  PRs awaiting approval: $($awaitingPRs.Count)"
Write-Host "  Labels added:          $added"
Write-Host "  Labels removed:        $removed"
Write-Host "  Failures:              $failed"

if ($env:GITHUB_STEP_SUMMARY) {
    $title = if ($WhatIf) { "## PRs Awaiting Approval - Label Sync (WhatIf)" } else { "## PRs Awaiting Approval - Label Sync" }
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $title
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ""
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- Label: ``$Label``"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- PRs awaiting approval: **$($awaitingPRs.Count)**"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- Labels added: **$added**"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- Labels removed: **$removed**"
    if ($failed -gt 0) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- Failures: **$failed**"
    }
}

if ($failed -gt 0 -and -not $WhatIf) {
    Write-Host "::error::Encountered $failed label operation failure(s)"
    exit 1
}
