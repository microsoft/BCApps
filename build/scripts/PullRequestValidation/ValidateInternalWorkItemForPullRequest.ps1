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

Import-Module (Join-Path $PSScriptRoot "WorkItemValidation.psm1") -Force

Write-Host "Validating PR $PullRequestNumber"

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
if (-not $pullRequest) {
    throw "Could not get PR $PullRequestNumber from repository $Repository"
}

$adoWorkItems = $pullRequest.GetLinkedADOWorkItemIDs()

# When there is no ADO work item, resolve the linked GitHub issues so the GitHub Task exemption can be evaluated.
# A pull request linked to a GitHub issue of type 'Task' is sufficiently tracked and does not require an ADO work item.
$linkedIssues = @()
if (-not $adoWorkItems) {
    foreach ($issueId in $pullRequest.GetLinkedIssueIDs()) {
        $issue = [GitHubIssue]::Get($issueId, $Repository)
        if ($issue) {
            $linkedIssues += $issue
        }
    }
}

# Validate that the pull request is tracked by an ADO work item or an exempt GitHub Task issue.
Test-PullRequestHasWorkItem -ADOWorkItems $adoWorkItems -PullRequest $pullRequest -LinkedIssues $linkedIssues

Write-Host "PR $PullRequestNumber validated successfully" -ForegroundColor Green