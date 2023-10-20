param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository
)

# Set error action
$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\PullRequestValidation.psm1

$linkedGitHubIssues = @(Get-WorkItemForPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -GitHub)
$linkedAdoWorkItem = @(Get-WorkItemForPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -ADO)

# Validate that there are linked work items
Test-WorkitemsAreLinked -Repository $Repository -PullRequestNumber $PullRequestNumber -GitHubIssues $linkedGitHubIssues -ADOWorkItems $linkedAdoWorkItem

# Validate that all linked GitHub issues are approved or acknowledged
Test-IssuesForPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -GitHubIssues $linkedGitHubIssues