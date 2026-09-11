[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [long] $IssueNumber,

    [Parameter(Mandatory = $true)]
    [string] $IssueUrl,

    [Parameter(Mandatory = $true)]
    [string] $Repository,

    [string] $ExpectedTeamLabel = '',
    [string] $ExpectedRequestType = '',
    [switch] $RejectOpenPullRequest,
    [string] $Model = 'gpt-5.6-sol',
    [bool] $TelemetryEnabled = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$expectedTeamLabelForRun = $ExpectedTeamLabel
$expectedRequestTypeForRun = $ExpectedRequestType
$rejectOpenPullRequestForRun = [bool]$RejectOpenPullRequest

$runId = "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT"
$branch = "bc-extrequest-implement/ext_issue-$IssueNumber"
$knownTeamLabels = @('Team: Finance', 'Team: SCM', 'Team: Integrations', 'Team: Other')
$knownRequestTypes = @('event-request', 'request-for-external', 'enum-request', 'extensibility-enhancement')
$telemetryContext = @{
    Enabled = $TelemetryEnabled
    IssueUrl = $IssueUrl
}

function Test-IssueEligibility {
    $issueJson = gh issue view $IssueNumber `
        --repo $Repository `
        --json state,labels,closedByPullRequestsReferences
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to revalidate issue #$IssueNumber."
    }

    $issue = ConvertFrom-Json $issueJson
    $labels = @($issue.labels | ForEach-Object { $_.name })
    if ($issue.state -ne 'OPEN' -or $labels -notcontains 'ext-ready-to-implement') {
        throw "Issue #$IssueNumber is no longer open and ready to implement."
    }
    if (-not [string]::IsNullOrWhiteSpace($expectedTeamLabelForRun)) {
        $assignedTeamLabels = @($labels | Where-Object { $_ -in $knownTeamLabels })
        if ($assignedTeamLabels.Count -ne 1 -or $assignedTeamLabels[0] -ne $expectedTeamLabelForRun) {
            throw "Issue #$IssueNumber no longer has only expected team label '$expectedTeamLabelForRun'."
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($expectedRequestTypeForRun)) {
        $assignedRequestTypes = @($labels | Where-Object { $_ -in $knownRequestTypes })
        if ($assignedRequestTypes.Count -ne 1 -or $assignedRequestTypes[0] -ne $expectedRequestTypeForRun) {
            throw "Issue #$IssueNumber no longer has only expected request type '$expectedRequestTypeForRun'."
        }

        $repositoryParts = $Repository.Split('/', 2)
        $query = 'query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){issueType{name}}}}'
        $issueTypeJson = gh api graphql `
            -f "query=$query" `
            -f "owner=$($repositoryParts[0])" `
            -f "repo=$($repositoryParts[1])" `
            -F "number=$IssueNumber"
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to verify the type of issue #$IssueNumber."
        }
        $issueType = (ConvertFrom-Json $issueTypeJson).data.repository.issue.issueType
        if ($null -eq $issueType -or $issueType.name -ne 'Task') {
            throw "Issue #$IssueNumber is no longer a Task."
        }
    }

    if ($rejectOpenPullRequestForRun) {
        foreach ($reference in @($issue.closedByPullRequestsReferences)) {
            $referenceRepository = "$($reference.repository.owner.login)/$($reference.repository.name)"
            $prState = gh pr view $reference.number `
                --repo $referenceRepository `
                --json state `
                --jq .state
            if ($LASTEXITCODE -ne 0) {
                throw "Unable to verify pull request #$($reference.number) while revalidating issue #$IssueNumber."
            }
            if ($prState -eq 'OPEN') {
                throw "Issue #$IssueNumber already has open pull request #$($reference.number)."
            }
        }
    }
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
        -BatchId '' `
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

    Test-IssueEligibility

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
