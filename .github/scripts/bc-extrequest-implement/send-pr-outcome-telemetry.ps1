[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [long] $PullRequestNumber,

    [Parameter(Mandatory = $true)]
    [string] $HeadBranch,

    [Parameter(Mandatory = $true)]
    [string] $Repository
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$issueNumbers = @()
$batchId = ''
$issueBranchMatch = [regex]::Match($HeadBranch, '^bc-extrequest-implement/ext_issue-(\d+)$')
$teamBranchMatch = [regex]::Match($HeadBranch, '^bc-extrequest-implement/team-(finance|scm|integrations)-(\d{4}-\d{2}-\d{2})$')

if ($issueBranchMatch.Success) {
    $issueNumbers = @([long]$issueBranchMatch.Groups[1].Value)
} elseif ($teamBranchMatch.Success) {
    $batchId = "$($teamBranchMatch.Groups[1].Value)-$($teamBranchMatch.Groups[2].Value)"
} else {
    Write-Warning "Cannot extract an issue number from branch '$HeadBranch'."
    return
}

$prJson = gh api "repos/$Repository/pulls/$PullRequestNumber"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Unable to read pull request #$PullRequestNumber. No telemetry was sent."
    return
}
$pr = ConvertFrom-Json $prJson

$isMerged = [bool]$pr.merged
$tag = if ($isMerged) { 'PR_MERGED' } else { 'PR_CLOSED_UNMERGED' }
$mergeCommitSha = if ($isMerged) { $pr.merge_commit_sha } else { '' }

if ($teamBranchMatch.Success) {
    $linkedIssuesJson = gh pr view $PullRequestNumber `
        --repo $Repository `
        --json closingIssuesReferences
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Unable to read linked issues for pull request #$PullRequestNumber. No telemetry was sent."
        return
    }

    $issueNumbers = @(
        (ConvertFrom-Json $linkedIssuesJson).closingIssuesReferences |
            Where-Object { "$($_.repository.owner.login)/$($_.repository.name)" -eq $Repository } |
            ForEach-Object { [long]$_.number } |
            Sort-Object -Unique
    )
}

if ($issueNumbers.Count -eq 0) {
    Write-Warning "Pull request #$PullRequestNumber does not close any issues in '$Repository'. No telemetry was sent."
    return
}

foreach ($issueNumber in $issueNumbers) {
    & "$PSScriptRoot/send-telemetry.ps1" `
        -ClusterUri $env:EXT_REQ_KUSTO_CLUSTER_URI `
        -Database $env:EXT_REQ_KUSTO_DATABASE `
        -Table $env:EXT_REQ_KUSTO_IMPLEMENT_TABLE `
        -Tag $tag `
        -RunId "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT" `
        -Repository $Repository `
        -IssueNumber $issueNumber `
        -IssueUrl "https://github.com/$Repository/issues/$issueNumber" `
        -BatchId $batchId `
        -PullRequestNumber ([long]$pr.number) `
        -PullRequestUrl $pr.html_url `
        -PullRequestState $pr.state `
        -HeadBranch $pr.head.ref `
        -IsDraft ([bool]$pr.draft) `
        -MergeCommitSha $mergeCommitSha `
        -CommitCount ([long]$pr.commits)
}
