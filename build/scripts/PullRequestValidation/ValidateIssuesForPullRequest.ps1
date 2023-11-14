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

function Test-WorkitemIsLinked($IssueIds, $ADOWorkItems, [object] $PullRequest) {
    $Comment = "Could not find linked issues in the pull request description. Please make sure the pull request description contains a line that contains 'Fixes #' followed by the issue number being fixed. Use that pattern for every issue you want to link."
    if ((-not $IssueIds) -and (-not $ADOWorkItems)) {
        $PullRequest.AddComment($Comment)
        throw $Comment
    }

    $PullRequest.RemoveComment($Comment)
}

function Test-GitHubIssue($Repository, $IssueIds, $PullRequest) {
    $invalidIssues = @()

    foreach ($issueId in $IssueIds) {
        Write-Host "Validating issue $issueId"
        $issue = [GitHubIssue]::Get($issueId, $Repository)
    
        # If the issue is not approved, add a comment to the pull request and throw an error
        $isValid = $issue -and $issue.IsApproved() -and $issue.IsOpen() -and (-not $issue.IsPullRequest())
        $Comment = "Issue #$($issueId) is not valid. Please make sure you link an **issue** that exists, is **open** and is **approved**."
        if (-not $isValid) {
            $PullRequest.AddComment($Comment)
            $invalidIssues += $issueId
        }
        else {
            $PullRequest.RemoveComment($Comment)
        }
    }
    
    if($invalidIssues) {
        throw "The following issues are not open or approved: $($invalidIssues -join ', ')"
    }
}

Write-Host "Validating PR $PullRequestNumber"

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
$issueIds = $pullRequest.GetLinkedIssueIDs()
$adoWorkitems = $pullRequest.GetLinkedADOWorkitems()

Test-WorkitemIsLinked -IssueIds $issueIds -ADOWorkItems $adoWorkitems -PullRequest $PullRequest
Test-GitHubIssue -Repository $Repository -IssueIds $issueIds -PullRequest $PullRequest

Write-Host "PR $PullRequestNumber validated successfully" -ForegroundColor Green