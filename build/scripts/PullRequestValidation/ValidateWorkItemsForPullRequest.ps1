param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository
)

# Set error action
$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\PullRequestValidation.psm1

$linkedGitHubIssues = @(Get-WorkItemForPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber)

# Validate that there is at least one linked workitem
Test-WorkitemsAreLinked -Repository $Repository -PullRequestNumber $PullRequestNumber -GitHubIssues $linkedGitHubIssues

# Validate that all linked GitHub issues are approved
Test-IssuesForPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -GitHubIssues $linkedGitHubIssues

# Ensure that the issue is linked to a milestone
Set-MilestoneForPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber