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

$issueSection = "Fixes #"
$issueIds = $pullRequest.GetLinkedIssueIDs($issueSection)

$Comment = "Could not find linked issues in the pull request description. Please make sure the pull request description contains a line that contains '$issueSection' followed by the issue number being fixed. Use that pattern for every issue you want to link."
if(-not $issueIds) {
    $pullRequest.AddComment($Comment)
    throw $Comment
}

$pullRequest.RemoveComment($Comment)

$unapprovedIssues = @()

foreach ($issueId in $issueIds) {
    Write-Host "Validating issue $issueId"
    $issue = [GitHubIssue]::Get($issueId, $Repository)

    $Comment = "Issue $($issue.html_url) is not approved. Please make sure the issue is approved before continuing with the pull request."

    if (-not $issue.IsApproved()) {
        $pullRequest.AddComment($Comment)
        $unapprovedIssues += $issueId
    }
    else {
        $pullRequest.RemoveComment($Comment)
    }
}

if($unapprovedIssues) {
    throw "The following issues are not approved: $($unapprovedIssues -join ', ')"
}

Write-Host "PR $PullRequestNumber validated successfully"
