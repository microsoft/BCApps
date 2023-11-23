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

    $Comment = "Could not find a linked ADO workitem. Please link one by using the pattern 'Fixes AB#' followed by the workitem number being fixed."
    if (-not $ADOWorkItems) {
        
        # If the pull request is not from a fork, add a comment to the pull request
        if (-not $PullRequest.IsFromFork()) {
            $PullRequest.AddComment($Comment)
        }
        
        # Throw an error if there is no linked ADO workitem
        throw $Comment
    }

    $PullRequest.RemoveComment($Comment)
}

Write-Host "Validating PR $PullRequestNumber"

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
$adoWorkitems = $pullRequest.GetLinkedADOWorkitems()

# Validate that all pull requests links to an ADO workitem
Test-ADOWorkitemIsLinked -ADOWorkItems $adoWorkitems -PullRequest $PullRequest

Write-Host "PR $PullRequestNumber validated successfully" -ForegroundColor Green