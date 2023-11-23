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

<#
    .SYNOPSIS
    Validates that the pull request description contains a line that links the pull request to an issue.
    .Parameter IssueIds
    The IDs of the issues linked to the pull request.
    .Parameter PullRequest
    The pull request to validate.
#>
function Test-IssueIsLinked() {
    param(
        [Parameter(Mandatory = $false)]
        [string[]] $IssueIds,
        [Parameter(Mandatory = $false)]
        [object] $PullRequest
    )

    $Comment = "Could not find linked issues in the pull request description. Please make sure the pull request description contains a line that contains 'Fixes #' followed by the issue number being fixed. Use that pattern for every issue you want to link."

    if (-not $IssueIds) {
        # If the pull request is from a fork, add a comment to the pull request and throw an error
        $PullRequest.AddComment($Comment)
        throw $Comment
    }

    $PullRequest.RemoveComment($Comment)
}

<#
    .SYNOPSIS
    Validates all issues linked to a pull request.
    .Description
    Validates all issues linked to a pull request.
    If the pull request is from a fork, it will validate that the issue is open and approved.
    If the pull request is not from a fork, it will validate that the issue is open.
    .Parameter Repository
    The repository that contains the pull request.
    .Parameter IssueIds
    The IDs of the issues linked to the pull request.
    .Parameter PullRequest
    The pull request to validate.
#>
function Test-GitHubIssue() {
    param(
        [Parameter(Mandatory = $false)]
        [string] $Repository,
        [Parameter(Mandatory = $false)]
        [string[]] $IssueIds,
        [Parameter(Mandatory = $false)]
        [object] $PullRequest
    )
    $invalidIssues = @()

    foreach ($issueId in $IssueIds) {
        Write-Host "Validating issue $issueId"
        $issue = [GitHubIssue]::Get($issueId, $Repository)

        # If the issue is not approved, add a comment to the pull request and throw an error
        $isValid = $issue -and ((-not $PullRequest.IsFromFork()) -or $issue.IsApproved()) -and $issue.IsOpen() -and (-not $issue.IsPullRequest())
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

<#
    .Synopsis
    Validates that the pull request description contains a line that links the pull request to an ADO workitem.
    .Parameter ADOWorkItems
    The IDs of the ADO workitems linked to the pull request.
    .Parameter PullRequest
    The pull request to validate.
#>
function Test-ADOWorkitemIsLinked() {
    param(
        [Parameter(Mandatory = $false)]
        [string[]] $ADOWorkItems,
        [Parameter(Mandatory = $false)]
        [object] $PullRequest
    )

    if ($PullRequest.IsFromFork()) {
        $Comment = "Thank you for your contribution! This comment is a reminder to the Microsoft team that this pull request needs to be assigned an internal workitem before it can be merged. A member of the Microsoft team will be in touch once the pull request is ready to be merged. No further action is needed from the contributor."
    } else {
        $Comment += "Could not find a linked ADO workitem. Please link one by using the pattern 'Fixes AB#' followed by the workitem number being fixed."

    }

    if (-not $ADOWorkItems) {
        # If the pull request is not from a fork, add a comment to the pull request and throw an error
        $PullRequest.AddComment($Comment)
        throw $Comment
    }

    $PullRequest.RemoveComment($Comment)
}

Write-Host "Validating PR $PullRequestNumber"

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
$issueIds = $pullRequest.GetLinkedIssueIDs()
$adoWorkitems = $pullRequest.GetLinkedADOWorkitems()

# If the pull request is from a fork, validate that it links to an issue
if ($pullRequest.IsFromFork()) {
    Test-IssueIsLinked -IssueIds $issueIds -PullRequest $PullRequest
}

# Validate that all issues linked to the pull request are open and approved
Test-GitHubIssue -Repository $Repository -IssueIds $issueIds -PullRequest $PullRequest

# Validate that all pull requests links to an ADO workitem
Test-ADOWorkitemIsLinked -ADOWorkItems $adoWorkitems -PullRequest $PullRequest

Write-Host "PR $PullRequestNumber validated successfully" -ForegroundColor Green