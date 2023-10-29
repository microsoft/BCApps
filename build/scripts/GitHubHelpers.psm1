$GitHubAPIHeader = "X-GitHub-Api-Version: 2022-11-28"
$AcceptJsonHeader = "Accept: application/vnd.github+json"

function Remove-CommentOnPullRequest($Repository, $PullRequestNumber, $Message) {
    $existingComments = gh api "/repos/$Repository/issues/$PullRequestNumber/comments" -H $AcceptJsonHeader -H $GitHubAPIHeader  | ConvertFrom-Json
    $comment = $existingComments | Where-Object { $_.body -eq $Message }
    if ($comment) {
        $CommentId = $comment.id
        gh api "/repos/$Repository/issues/comments/$CommentId" -H $AcceptJsonHeader -H $GitHubAPIHeader -X DELETE
    }
}

function Add-CommentOnPullRequestIfNeeded($Repository, $PullRequestNumber, $Message) {
    $existingComments = gh api "/repos/$Repository/issues/$PullRequestNumber/comments" -H $AcceptJsonHeader -H $GitHubAPIHeader  | ConvertFrom-Json
    $commentExists = $existingComments | Where-Object { $_.body -eq $Message }
    if ($commentExists) {
        Write-Host "Comment already exists on pull request $($commentExists.html_url)"
        return
    }

    return (AddCommentOnPullRequest -Repository $Repository -PullRequestNumber $PullRequestNumber -Message $Message)
}

function Set-Milestone($Repository, $IssueNumber, $MilestoneName) {
    $allMilestones = gh api "/repos/$Repository/milestones" --method GET -H $AcceptJsonHeader -H $GitHubAPIHeader | ConvertFrom-Json
    $milestone = $allMilestones | Where-Object { $_.title -eq $MilestoneName }
    if (-not $milestone) {
        throw "::Error:: Milestone $MilestoneName not found"
    }
    $milestoneNumber = $milestone.number
    gh api "/repos/$Repository/issues/$IssueNumber" -H $AcceptJsonHeader -H $GitHubAPIHeader -F milestone=$milestoneNumber | ConvertFrom-Json
}

function Get-PullRequest($Repository, $PullRequestNumber) {
    $pullRequest = gh api "/repos/$Repository/pulls/$PullRequestNumber" -H $AcceptJsonHeader -H $GitHubAPIHeader | ConvertFrom-Json
    if (-not $pullRequest) {
        throw "::Error:: Pull request $PullRequestNumber not found"
    }
    return $pullRequest
}

function Get-Issue($Repository, $IssueNumber) {
    $issue = gh api "/repos/$Repository/issues/$IssueNumber" -H $AcceptJsonHeader -H $GitHubAPIHeader | ConvertFrom-Json
    if (-not $issue) {
        throw "::Error:: Issue $IssueNumber not found"
    }
    return $issue
}

function AddCommentOnPullRequest($Repository, $PullRequestNumber, $Message) {
    $comment = gh api "/repos/$Repository/issues/$PullRequestNumber/comments" -H $AcceptJsonHeader -H $GitHubAPIHeader -f body="$Message" | ConvertFrom-Json
    if (-not $comment) {
        throw "::Error:: Comment not created on pull request $PullRequestNumber"
    }
    return $comment
}

Export-ModuleMember *-*