using module .\GitHubAPI.class.psm1
using module .\GitHubIssue.class.psm1

class GitHubPullRequest {
    [int] $PRNumber
    [string] $Repository
    $PullRequest

    #Constructor
    GitHubPullRequest([int] $PRNumber, [string] $Repository) {
        $this.PRNumber = $PRNumber
        $this.Repository = $Repository

        Write-Host "PRNumber: $($this.PRNumber)"

        $pr = gh api "/repos/$Repository/pulls/$PRNumber" -H ([GitHubAPI]::AcceptJsonHeader) -H ([GitHubAPI]::GitHubAPIHeader) | ConvertFrom-Json
        if (-not $pr) {
            throw "::Error:: Pull request $PRNumber not found in repository $Repository"
        }

        $this.PullRequest = $pr
    }

    [string] GetBody() {
        return $this.PullRequest.body
    }

    RemoveComment($Message) {
        $existingComments = gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)/comments" -H $this.AcceptJsonHeader -H $this.GitHubAPIHeader  | ConvertFrom-Json
        $comment = $existingComments | Where-Object { $_.body -eq $Message }
        
        if ($comment) {
            $CommentId = $comment.id
            gh api "/repos/$this.Repository/issues/comments/$CommentId" -H $this.AcceptJsonHeader -H $this.GitHubAPIHeader -X DELETE
        }
    }

    [object] AddComment($Message) {
        $existingComments = gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)/comments" -H $this.AcceptJsonHeader -H $this.GitHubAPIHeader  | ConvertFrom-Json
        
        $commentExists = $existingComments | Where-Object { $_.body -eq $Message }
        if ($commentExists) {
            Write-Host "Comment already exists on pull request $($commentExists.html_url)"
            return $null
        }
    
        $comment = gh api "/repos/$($this.Repository)/issues/$($this.PRNumber)/comments" -H $this.AcceptJsonHeader -H $this.GitHubAPIHeader -f body="$Message" | ConvertFrom-Json
        return $comment
    }
}

Export-ModuleMember -Function GitHubPullRequest
