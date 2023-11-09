using module .\GitHubAPI.class.psm1
using module .\GitHubIssue.class.psm1


<#
    Class that represents a GitHub pull request.
#>
class GitHubPullRequest {
    [int] $PRNumber
    [string] $Repository
    $PullRequest

    hidden GitHubPullRequest([int] $PRNumber, [string] $Repository) {
        $this.PRNumber = $PRNumber
        $this.Repository = $Repository

        $pr = gh api "/repos/$Repository/pulls/$PRNumber" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json
        if ($pr.message) {
            # message property is populated when the PR is not found
            throw "::Error:: Could not get PR $PRNumber from repository $Repository. Error: $($pr.message)"
        }

        $this.PullRequest = $pr
    }

    <#
        Gets the pull request from GitHub.
    #>
    static [GitHubPullRequest] Get([int] $PRNumber, [string] $Repository) {
        $pr = [GitHubPullRequest]::new($PRNumber, $Repository)

        return $pr
    }

    <#
        Gets the linked issues IDs from the pull request description.
        .param $issueSection
            The section of the pull request description that contains the issue ID.
        .returns
            An array of linked issue IDs.
    #>
    [int[]] GetLinkedIssueIDs($issueSection) {
        if(-not $this.PullRequest.body) {
            return @()
        }

        $issueRegex = "$issueSection(\d+)" # e.g. "Fixes #1234"
        $issueMatches = Select-String $issueRegex -InputObject $this.PullRequest.body -AllMatches

        if(-not $issueMatches) {
            return @()
        }

        $issueIds = @()
        foreach($match in $issueMatches.Matches) {
            $issueIds += $match.Groups[1].Value
        }

        return $issueIds
    }

    <#
        Removes a comment from the pull request if it exists.
    #>
    RemoveComment($Message) {
        $existingComments = gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)/comments" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json
        $comment = $existingComments | Where-Object { $_.body -eq $Message }

        if ($comment) {
            $CommentId = $comment.id
            gh api "/repos/$($this.Repository)/issues/comments/$CommentId" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) -X DELETE
        }
    }

    <#
        Adds a comment to the pull request if it does not exist.
        Returns the comment object if it was added, otherwise returns null.
    #>
    [object] AddComment($Message) {
        $existingComments = gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)/comments" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json

        $commentExists = $existingComments | Where-Object { $_.body -eq $Message }
        if ($commentExists) {
            Write-Host "Comment already exists on pull request $($commentExists.html_url)"
            return $null
        }

        $comment = gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)/comments" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) -f body="$Message" | ConvertFrom-Json
        return $comment
    }

    <#
        Adds a milestone to the pull request.
    #>
    SetMilestone($Milestone) {
        $allMilestones = gh api "/repos/$($this.Repository)/milestones" --method GET -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json
        $githubMilestone = $allMilestones | Where-Object { $_.title -eq $Milestone }
        if (-not $githubMilestone) {
            Write-Host "::Warning:: Milestone '$Milestone' not found"
            return 
        }
        $milestoneNumber = $githubMilestone.number
        gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) -F milestone=$milestoneNumber | ConvertFrom-Json
    }
}
