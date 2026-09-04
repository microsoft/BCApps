[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [long] $IssueNumber,

    [Parameter(Mandatory = $true)]
    [string] $IssueUrl,

    [Parameter(Mandatory = $true)]
    [string] $Repository,

    [string] $Model = 'gpt-5.6-sol',
    [bool] $TelemetryEnabled = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$runId = "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT"
$branch = "bc-extrequest-implement/ext_issue-$IssueNumber"
$telemetryContext = @{
    Enabled = $TelemetryEnabled
    IssueUrl = $IssueUrl
}

function Send-ImplementationTelemetry {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Tag,
        [long] $PullRequestNumber = 0,
        [string] $PullRequestUrl = '',
        [string] $PullRequestState = '',
        [string] $HeadBranch = '',
        [bool] $IsDraft = $false,
        [long] $CommitCount = 0,
        [string] $FailureMessage = ''
    )

    if (-not $telemetryContext.Enabled) {
        return
    }

    & "$PSScriptRoot/send-telemetry.ps1" `
        -ClusterUri $env:EXT_REQ_KUSTO_CLUSTER_URI `
        -Database $env:EXT_REQ_KUSTO_DATABASE `
        -Table $env:EXT_REQ_KUSTO_IMPLEMENT_TABLE `
        -Tag $Tag `
        -RunId $runId `
        -Repository $Repository `
        -IssueNumber $IssueNumber `
        -IssueUrl $telemetryContext.IssueUrl `
        -Model $Model `
        -PullRequestNumber $PullRequestNumber `
        -PullRequestUrl $PullRequestUrl `
        -PullRequestState $PullRequestState `
        -HeadBranch $HeadBranch `
        -IsDraft $IsDraft `
        -CommitCount $CommitCount `
        -FailureMessage $FailureMessage
}

try {
    git config user.name 'github-actions[bot]'
    git config user.email '41898282+github-actions[bot]@users.noreply.github.com'

    Send-ImplementationTelemetry -Tag IMPLEMENTATION_STARTED

    $prompt = @(
        "Use the /bc-extrequest-implement skill to implement GitHub issue #$IssueNumber end to end.",
        "Run fully unattended in self-driven mode. Create or reuse branch '$branch', commit and push the smallest guideline-aligned .al-only change, and create or update one draft pull request in '$Repository'.",
        "Proceed only while the issue is open and carries the 'ext-ready-to-implement' label. The pull request body must contain 'Fixes #$IssueNumber'. Do not modify the issue directly."
    ) -join ' '

    $copilotArgs = @(
        '--allow-all-tools',
        '--no-custom-instructions',
        '--no-color',
        '--log-level', 'info',
        "--model=$Model",
        '-p', $prompt
    )

    & copilot @copilotArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Copilot CLI exited with code $LASTEXITCODE."
    }

    $prJson = gh pr list `
        --repo $Repository `
        --head $branch `
        --state open `
        --limit 1 `
        --json number,url
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to query the pull request for branch '$branch'."
    }

    $pullRequest = @($prJson | ConvertFrom-Json)[0]
    if (-not $pullRequest) {
        throw "Copilot completed without creating or updating a pull request for branch '$branch'."
    }

    $prDetailsJson = gh api "repos/$Repository/pulls/$($pullRequest.number)"
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read details for pull request #$($pullRequest.number)."
    }
    $prDetails = ConvertFrom-Json $prDetailsJson

    Send-ImplementationTelemetry `
        -Tag PR_CREATED `
        -PullRequestNumber ([long]$pullRequest.number) `
        -PullRequestUrl $pullRequest.url `
        -PullRequestState $prDetails.state `
        -HeadBranch $prDetails.head.ref `
        -IsDraft ([bool]$prDetails.draft) `
        -CommitCount ([long]$prDetails.commits)

    Write-Host "Draft pull request ready: $($pullRequest.url)"
} catch {
    Send-ImplementationTelemetry -Tag ERROR -FailureMessage $_.Exception.Message
    throw
}
