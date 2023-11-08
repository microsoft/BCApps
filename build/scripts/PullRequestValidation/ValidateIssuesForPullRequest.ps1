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
$issueRegex = "Fixes #(\d+)"

if(-not $prDescription) {
    throw "Could not find pull request description. Please make sure the pull request description contains a line that contains 'Fixes #' followed by the issue number being fixed."
}

# Get all issue matches
$issueMatches = Select-String $issueRegex -InputObject $prDescription -AllMatches

if(-not $matches) {
    throw "Could not find issues section in the pull request description. Please make sure the pull request description contains a line that contains 'Fixes #' followed by the issue number being fixed."
}

# Get all issue IDs
$issueIds = @()
foreach($match in $issueMatches.Matches) {
    $issueIds += $match.Groups[1].Value
}

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
