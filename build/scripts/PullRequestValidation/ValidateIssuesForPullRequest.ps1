using module ..\GitHub\GitHubPullRequest.class.psm1
using module ..\GitHub\GitHubIssue.class.psm1

param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository
    )

# Set error action
$ErrorActionPreference = "Stop"

Write-Host "Validating PR $PullRequestNumber"

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
$prDescription = $pullRequest.GetBody()
$issuesStartingPoint = "Fixes #"

if(-not $prDescription) {
    throw "Could not find pull request description. Please make sure the pull request description contains a line that contains '$issuesStartingPoint' followed by the issue number being fixed."
}

$issueStartingIndex = $prDescription.IndexOf($issuesStartingPoint)

if ($issueStartingIndex -eq -1) {
    throw "Could not find issues section in the pull request description. Please make sure the pull request description contains a line that contains '$issuesStartingPoint' followed by the issue number being fixed"
}

$issuesDescription = $prDescription.Substring($issueStartingIndex + $($issuesStartingPoint.Length) - 1)
$issueIds = $issuesDescription.Split(' ,') | Where-Object { $_ -match "#\d+" } | ForEach-Object { [int] $_.Trim("# ") }

foreach ($issueId in $issueIds) {
    Write-Host "Validating issue $issueId"
    $issue = [GitHubIssue]::Get($issueId, $Repository)

    $Comment = "Issue $($issue.html_url) is not approved. Please make sure the issue is approved before continuing with the pull request."
    if (-not $issue.IsApproved()) {
        $pullRequest.AddComment($Comment)

        throw "$Comment"
    }
    else {
        $pullRequest.RemoveComment($Comment)
    }
}

Write-Host "PR $PullRequestNumber validated successfully"
