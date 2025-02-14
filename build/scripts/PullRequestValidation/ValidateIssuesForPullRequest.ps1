using module ..\GitHub\GitHubPullRequest.class.psm1
using module ..\GitHub\GitHubIssue.class.psm1

param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository,
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
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
        [object] $PullRequest,
        [Parameter(Mandatory = $false)]
        [switch] $ValidateOnly
    )

    $Comment = "Could not find linked issues in the pull request description. Please make sure the pull request description contains a line that contains 'Fixes #' followed by the issue number being fixed. Use that pattern for every issue you want to link."

    if (-not $IssueIds) {
        # If the pull request is from a fork, add a comment to the pull request and throw an error
        if (-not $ValidateOnly) {
            $PullRequest.AddComment($Comment)
        }
        throw $Comment
    }

    if (-not $ValidateOnly) {
        $PullRequest.RemoveComment($Comment)
    }
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
        [object] $PullRequest,
        [Parameter(Mandatory = $false)]
        [switch] $ValidateOnly
    )
    $invalidIssues = @()

    foreach ($issueId in $IssueIds) {
        Write-Host "Validating issue $issueId"
        $issue = [GitHubIssue]::Get($issueId, $Repository)

        # If the issue is not approved, add a comment to the pull request and throw an error
        $isValid = $issue -and ((-not $PullRequest.IsFromFork()) -or $issue.IsApproved()) -and $issue.IsOpen() -and (-not $issue.IsPullRequest())
        $Comment = "Issue #$($issueId) is not valid. Please make sure you link an **issue** that exists, is **open** and is **approved**."
        if (-not $isValid) {
            if (-not $ValidateOnly) {
                $PullRequest.AddComment($Comment)
            }
            $invalidIssues += $issueId
        }
        elseif (-not $ValidateOnly) {
            $PullRequest.RemoveComment($Comment)
        }
    }

    if($invalidIssues) {
        throw "The following issues are not open or approved: $($invalidIssues -join ', ')"
    }
}

Write-Host "Validating PR $PullRequestNumber"

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
if (-not $pullRequest) {
    throw "Could not get PR $PullRequestNumber from repository $Repository"
}

$issueIds = $pullRequest.GetLinkedIssueIDs()

# If the pull request is from a fork, validate that it links to an issue
if ($pullRequest.IsFromFork()) {
    Test-IssueIsLinked -IssueIds $issueIds -PullRequest $PullRequest -ValidateOnly:$ValidateOnly
}

# Validate that all issues linked to the pull request are open and approved
Test-GitHubIssue -Repository $Repository -IssueIds $issueIds -PullRequest $PullRequest -ValidateOnly:$ValidateOnly

Write-Host "PR $PullRequestNumber validated successfully" -ForegroundColor Green