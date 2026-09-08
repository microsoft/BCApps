[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $StatePath,

    [bool] $TelemetryEnabled = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

if (-not (Test-Path $StatePath)) {
    throw "Team implementation state '$StatePath' was not found."
}

$state = Get-Content -Raw $StatePath | ConvertFrom-Json
if ($state.version -ne 1 -or @($state.successful_issues).Count -eq 0) {
    throw 'Team implementation state is invalid or contains no successful issues.'
}

function Invoke-NativeText {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    $output = & $Command @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $text"
    }
    if ($AllowFailure) {
        $global:LASTEXITCODE = 0
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = $text
    }
}

function Send-IssueTelemetry {
    param(
        [Parameter(Mandatory = $true)]
        [long] $IssueNumber,
        [Parameter(Mandatory = $true)]
        [string] $IssueUrl,
        [Parameter(Mandatory = $true)]
        [object] $PullRequest
    )

    if (-not $TelemetryEnabled) {
        return
    }

    & "$PSScriptRoot/send-telemetry.ps1" `
        -ClusterUri $env:EXT_REQ_KUSTO_CLUSTER_URI `
        -Database $env:EXT_REQ_KUSTO_DATABASE `
        -Table $env:EXT_REQ_KUSTO_IMPLEMENT_TABLE `
        -Tag PR_CREATED `
        -RunId "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT" `
        -Repository $state.repository `
        -IssueNumber $IssueNumber `
        -IssueUrl $IssueUrl `
        -BatchId $state.batch_id `
        -Model $state.model `
        -PullRequestNumber ([long]$PullRequest.number) `
        -PullRequestUrl $PullRequest.html_url `
        -PullRequestState $PullRequest.state `
        -HeadBranch $PullRequest.head.ref `
        -IsDraft ([bool]$PullRequest.draft) `
        -CommitCount ([long]$PullRequest.commits)
    $global:LASTEXITCODE = 0
}

function Add-JobSummary {
    param([Parameter(Mandatory = $true)][string] $Text)

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

git config --local --unset-all http.https://github.com/.extraheader 2>$null
gh auth setup-git
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to configure git authentication with the fresh GitHub App token.'
}

Invoke-NativeText -Command 'git' -Arguments @(
    'push', '--set-upstream', 'origin', $state.branch
) | Out-Null

$existingPrResponse = Invoke-NativeText -Command 'gh' -Arguments @(
    'pr', 'list',
    '--repo', $state.repository,
    '--head', $state.branch,
    '--state', 'open',
    '--limit', '1',
    '--json', 'number,body'
)
$existingPr = @($existingPrResponse.Text | ConvertFrom-Json)[0]

$sections = [System.Text.StringBuilder]::new()
foreach ($result in @($state.successful_issues)) {
    [void]$sections.AppendLine("## Issue #$($result.issue_number) - $($result.issue_title)")
    [void]$sections.AppendLine()
    [void]$sections.AppendLine([string]$result.summary)
    [void]$sections.AppendLine()
    [void]$sections.AppendLine('### Changes Made')
    foreach ($change in @($result.changes_made)) {
        [void]$sections.AppendLine("- $change")
    }
    [void]$sections.AppendLine()
    [void]$sections.AppendLine("Fixes #$($result.issue_number)")
    [void]$sections.AppendLine()
}

$githubDirectory = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$skillDirectory = Join-Path (Join-Path $githubDirectory 'skills') 'bc-extrequest-implement'
$templatePath = Join-Path $skillDirectory 'batch-pr-template.md'
if (-not (Test-Path $templatePath)) {
    throw "Batch pull request template '$templatePath' was not found."
}

$template = Get-Content -Raw $templatePath
$sectionMarker = '<!-- EXT_REQ_BATCH_END -->'
if (-not $template.Contains('{{TEAM}}') -or
    -not $template.Contains('{{ISSUE_SECTIONS}}') -or
    -not $template.Contains($sectionMarker)) {
    throw "Batch pull request template '$templatePath' is missing a required placeholder or marker."
}

$newSections = $sections.ToString().Trim()
if ($existingPr) {
    $existingBody = [string]$existingPr.body
    if (-not $existingBody.Contains($sectionMarker)) {
        throw "Existing pull request #$($existingPr.number) does not contain the batch section marker."
    }
    $prBody = $existingBody.Replace($sectionMarker, "$newSections`n`n$sectionMarker")
} else {
    $prBody = $template.
        Replace('{{TEAM}}', [string]$state.team).
        Replace('{{ISSUE_SECTIONS}}', $newSections)
}

$prBodyPath = Join-Path ([IO.Path]::GetDirectoryName($StatePath)) 'pull-request-body.md'
Set-Content -Path $prBodyPath -Value $prBody -Encoding UTF8
$prTitle = "[Extensibility Requests][Team: $($state.team)] $($state.batch_date) batch"

if ($existingPr) {
    Invoke-NativeText -Command 'gh' -Arguments @(
        'pr', 'edit', "$($existingPr.number)",
        '--repo', $state.repository,
        '--title', $prTitle,
        '--body-file', $prBodyPath
    ) | Out-Null
    $pullRequestNumber = [long]$existingPr.number
} else {
    $createdPr = Invoke-NativeText -Command 'gh' -Arguments @(
        'pr', 'create',
        '--repo', $state.repository,
        '--title', $prTitle,
        '--body-file', $prBodyPath,
        '--base', $state.default_branch,
        '--head', $state.branch,
        '--draft'
    )
    $pullRequestNumber = [long]([regex]::Match($createdPr.Text, '/pull/(\d+)').Groups[1].Value)
    if ($pullRequestNumber -eq 0) {
        throw "Unable to determine the created pull request number from '$($createdPr.Text)'."
    }
}

$labels = @(
    $state.successful_issues |
        ForEach-Object { @($_.labels) } |
        Where-Object { $_ -ne 'ext-ready-to-implement' } |
        Sort-Object -Unique
)
foreach ($label in $labels) {
    $addLabel = Invoke-NativeText -Command 'gh' -Arguments @(
        'pr', 'edit', "$pullRequestNumber", '--repo', $state.repository, '--add-label', "$label"
    ) -AllowFailure
    if ($addLabel.ExitCode -ne 0) {
        Write-Warning "Unable to add label '$label' to pull request #$pullRequestNumber."
    }
}

$prDetailsResponse = Invoke-NativeText -Command 'gh' -Arguments @(
    'api', "repos/$($state.repository)/pulls/$pullRequestNumber"
)
$prDetails = ConvertFrom-Json $prDetailsResponse.Text
foreach ($result in @($state.successful_issues)) {
    Send-IssueTelemetry `
        -IssueNumber ([long]$result.issue_number) `
        -IssueUrl ([string]$result.issue_url) `
        -PullRequest $prDetails
}

$summary = @(
    "## $($state.team)",
    '',
    "Draft pull request: $($prDetails.html_url)",
    '',
    "Implemented issues: $(@($state.successful_issues | ForEach-Object { "#$($_.issue_number)" }) -join ', ')"
)
if (@($state.failed_issues).Count -gt 0) {
    $summary += ''
    $summary += "Failed issues: $(@($state.failed_issues | ForEach-Object { "#$($_.issue_number)" }) -join ', ')"
}
Add-JobSummary ($summary -join "`n")

Remove-Item -Path $prBodyPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $StatePath -Force -ErrorAction SilentlyContinue

Write-Host "Draft pull request ready: $($prDetails.html_url)"
if (@($state.failed_issues).Count -gt 0) {
    throw "$(@($state.failed_issues).Count) issue implementation(s) failed after the partial batch pull request was created."
}
$global:LASTEXITCODE = 0
