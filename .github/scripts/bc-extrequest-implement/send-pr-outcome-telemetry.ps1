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

$branchMatch = [regex]::Match($HeadBranch, '^bc-extrequest-implement/ext_issue-(\d+)$')
if (-not $branchMatch.Success) {
    Write-Warning "Cannot extract an issue number from branch '$HeadBranch'."
    return
}
$issueNumber = [long]$branchMatch.Groups[1].Value

$prJson = gh api "repos/$Repository/pulls/$PullRequestNumber"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Unable to read pull request #$PullRequestNumber. No telemetry was sent."
    return
}
$pr = ConvertFrom-Json $prJson

$isMerged = [bool]$pr.merged
$tag = if ($isMerged) { 'PR_MERGED' } else { 'PR_CLOSED_UNMERGED' }
$mergeCommitSha = if ($isMerged) { $pr.merge_commit_sha } else { '' }

& "$PSScriptRoot/send-telemetry.ps1" `
    -ClusterUri $env:EXT_REQ_KUSTO_CLUSTER_URI `
    -Database $env:EXT_REQ_KUSTO_DATABASE `
    -Table $env:EXT_REQ_KUSTO_IMPLEMENT_TABLE `
    -Tag $tag `
    -RunId "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT" `
    -Repository $Repository `
    -IssueNumber $issueNumber `
    -IssueUrl "https://github.com/$Repository/issues/$issueNumber" `
    -PullRequestNumber ([long]$pr.number) `
    -PullRequestUrl $pr.html_url `
    -PullRequestState $pr.state `
    -HeadBranch $pr.head.ref `
    -IsDraft ([bool]$pr.draft) `
    -MergeCommitSha $mergeCommitSha `
    -CommitCount ([long]$pr.commits)
