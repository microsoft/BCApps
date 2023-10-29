Import-Module $PSScriptRoot\..\GitHubHelpers.psm1
Import-Module $PSScriptRoot\..\EnlistmentHelperFunctions.psm1

function Get-WorkItemForPullRequest() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PullRequestNumber,
        [Parameter(Mandatory = $true)]
        [string] $Repository
    )

    $pullRequest = Get-PullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber

    $description = $pullRequest.body
    $workItemsStartingIndex = $description.IndexOf("# Work Item(s)")
    if ($workItemsStartingIndex -eq -1) {
        throw "::Error:: Could not find work item section in pull request description. Please make sure the pull request description contains a section called '# Work Item(s)'"
    } 

    $workItemDescription = $description.Substring($workItemsStartingIndex)
    return GetIssueFromPullRequestDescription -Description $workItemDescription
}

<#
.Synopsis
    Validates that the GitHub issue has the tag "Approved"
#>
function Test-IssuesForPullRequest($Repository, $PullRequestNumber, $GitHubIssues) {
    foreach ($issueNumber in $GitHubIssues) {
        $issue = Get-Issue -Repository $Repository -IssueNumber $IssueNumber
        if ($issue) {
            $Comment = "Issue $($issue.html_url) is not approved or acknowledged. Please make sure the issue is approved before continuing with the pull request"
            if ((-not ($issue.labels.name -contains "approved"))) {
                # Add comment to pull request if it doesn't already exist
                Add-CommentOnPullRequestIfNeeded -Repository $Repository -PullRequestNumber $PullRequestNumber -Message $Comment
                Write-Warning "::Warning:: $Comment"
            }
            else {
                Remove-CommentOnPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -Message $Comment
            }
        }
        else {
            Write-Warning "Issue $IssueNumber not found"
        }
    }
}

function Set-MilestoneForPullRequest($Repository, $PullRequestNumber) {
    $pullRequest = Get-PullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber
    if ($pullRequest.milestone) {
        Write-Host "Pull request already has a milestone: $($pullRequest.milestone.title)"
        return
    }
    $currentMilestone = Get-ConfigValue -Key "Milestone" -ConfigType BuildConfig
    Set-Milestone -Repository $Repository -IssueNumber $PullRequestNumber -Milestone $currentMilestone
}

function Test-WorkitemsAreLinked($Repository, $PullRequestNumber, $GitHubIssues) {
    $Comment = "No work item found for pull request. Please link a work item to the pull request."
    if (-not $GitHubIssues) {
        # Add comment to pull request if it doesn't already exist
        Add-CommentOnPullRequestIfNeeded -Repository $Repository -PullRequestNumber $PullRequestNumber -Message $Comment
        throw "::Error:: $Comment"
    }
    else {
        Remove-CommentOnPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -Message $Comment
    }
}

function GetIssueFromPullRequestDescription($Description) {
    $matches = [regex]::matches($Description, "(?<!\w)#(?<IssueNumber>\d+)")
    if ($matches -and $matches.Groups) {
        $issueNumbers = $matches.Groups | Where-Object { $_.Name -eq "IssueNumber" } | Select-Object -ExpandProperty Value
        return $issueNumbers
    }
}

Export-ModuleMember *-*