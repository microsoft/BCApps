using module ..\GitHub\GitHubPullRequest.class.psm1

param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository,
    [Parameter(Mandatory = $true)]
    [string] $RepoVersion
)

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)

if (-not $pullRequest) {
    throw "Could not get PR $PullRequestNumber from repository $Repository"
}

if ($pullRequest.PullRequest.labels -and ($pullRequest.PullRequest.labels.name -contains "Automation")) {
    return # Don't set milestone on automation PRs
}

$milestone = "Version $RepoVersion"

Write-Host "Setting milestone '$milestone' on PR $PullRequestNumber"
$pullRequest.SetMilestone($milestone)