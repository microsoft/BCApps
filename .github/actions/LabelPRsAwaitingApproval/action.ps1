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
        try {
            $result = & gh api @Arguments 2>&1
            if ($LASTEXITCODE -eq 0) { return $result }
            throw "gh api failed (exit $LASTEXITCODE): $result"
        }
        catch {
            if ($attempt -eq $MaxRetries) { throw }
            Start-Sleep -Seconds ([Math]::Pow(2, $attempt))
        }
    }
}

function Ensure-Label {
    param ([string] $Name)
    try {
        Invoke-GhApi -Arguments @("repos/$repo/labels/$([Uri]::EscapeDataString($Name))") | Out-Null
        Write-Host "Label '$Name' exists"
    }
    catch {
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
}

function Get-AwaitingApprovalPRs {
    Write-Host ""
    Write-Host "Fetching workflow runs with status=action_required from $repo..."
    $runsJson = Invoke-GhApi -Arguments @("repos/$repo/actions/runs?status=action_required&per_page=100", '--jq', '.workflow_runs')
    $runs = @()
    if ($runsJson) { $runs = @($runsJson | ConvertFrom-Json) }
    Write-Host "Found $($runs.Count) action_required workflow run(s)"

    $awaiting = [System.Collections.Generic.HashSet[int]]::new()
    $shaCache = @{}

    foreach ($run in $runs) {
        $prNumbers = @()
        $hasPRs = ($run.PSObject.Properties.Name -contains 'pull_requests') -and $run.pull_requests
        if ($hasPRs -and $run.pull_requests.Count -gt 0) {
            $prNumbers = @($run.pull_requests | ForEach-Object { [int]$_.number })
        }
        elseif ($run.PSObject.Properties.Name -contains 'head_sha' -and $run.head_sha) {
            $sha = $run.head_sha
            if (-not $shaCache.ContainsKey($sha)) {
                try {
                    $byShaJson = Invoke-GhApi -Arguments @("repos/$repo/commits/$sha/pulls", '--jq', '[.[] | select(.state=="open") | .number]')
                    $shaCache[$sha] = @($byShaJson | ConvertFrom-Json)
                }
                catch {
                    Write-Host "  ! Failed to resolve PRs for run $($run.id) (sha $sha): $_"
                    $shaCache[$sha] = @()
                }
            }
            $prNumbers = $shaCache[$sha]
        }

        foreach ($n in $prNumbers) {
            [void]$awaiting.Add([int]$n)
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
    $json = Invoke-GhApi -Arguments @('--paginate', "repos/$repo/issues?state=open&labels=$encoded&per_page=100", '--jq', '[.[] | select(.pull_request) | .number]')
    $set = [System.Collections.Generic.HashSet[int]]::new()
    if ($json) {
        foreach ($n in @($json | ConvertFrom-Json)) { [void]$set.Add([int]$n) }
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
