using module .\GitHubAPI.class.psm1

class GitHubIssue {
    $IssueId
    $Repository
    $Issue

    #Constructor
    hidden GitHubIssue([int] $IssueId, [string] $Repository) {
        $this.IssueId = $IssueId
        $this.Repository = $Repository

        $gitHubIssue = gh api "/repos/$Repository/issues/$IssueId" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader)| ConvertFrom-Json
        if (-not $gitHubIssue) {
            throw "::Error:: Issue $IssueId not found in repository $Repository"
        }
        $this.Issue = $gitHubIssue
    }

    static [GitHubIssue] Get([int] $IssueId, [string] $Repository) {
        $gitHubIssue = [GitHubIssue]::new($IssueId, $Repository)
        
        return $gitHubIssue
    }

    [bool] IsApproved() {
        return $this.Issue.labels.name -contains "approved"
    }       

    [bool] LinkMilestone([string] $MilestoneName) {
        $allMilestones = gh api "/repos/$($this.Repository)/milestones" --method GET -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json
        $milestone = $allMilestones | Where-Object { $_.title -eq $MilestoneName }
        if (-not $milestone) {
            return false
        }
        $milestoneNumber = $milestone.number
        $result = gh api "/repos/$($this.Repository)/issues/$($this.IssueId)" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) -F milestone=$milestoneNumber | ConvertFrom-Json
        
        # check result?

        return true
    }
}

