using module ..\GitHub\GitHubPullRequest.class.psm1
using module ..\GitHub\GitHubIssue.class.psm1

param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository
)

function Update-GitHubPullRequest() {
    param(
        [Parameter(Mandatory = $false)]
        [string] $Repository,
        [Parameter(Mandatory = $false)]
        [object] $PullRequest,
        [Parameter(Mandatory = $false)]
        [string[]] $IssueIds
    )

    $pullRequestBody = $PullRequest.PullRequest.body

    # Find all ADO work items linked to the provided issues and link them to the PR
    foreach ($issueId in $IssueIds) {
        Write-Host "Trying to link work items from $issueId to pull request $($PullRequest.PRNumber)"

        $issue = [GitHubIssue]::Get($issueId, $Repository)
        $adoWorkItems = $issue.GetLinkedADOWorkitems()
        if (-not $adoWorkItems) {
            Write-Host "No ADO workitems found in issue $issueId"
            continue
        }

        foreach ($adoWorkItem in $adoWorkItems) {
            if ($pullRequestBody -notmatch "AB#$($adoWorkItem)") {
                Write-Host "Linking ADO workitem AB#$($adoWorkItem) to pull request $PullRequestNumber"
                $pullRequestBody += "`r`nFixes AB#$($adoWorkItem)"
            } else {
                Write-Host "Pull request already linked to ADO workitem AB#$($adoWorkItem)"

            }
        }
    }

    # Update the pull request description
    $PullRequest.PullRequest.body = $pullRequestBody
    $pullRequest.Update()
}

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)
$issueIds = $pullRequest.GetLinkedIssueIDs()

Write-Host "Updating pull request $PullRequestNumber with linked issues $issueIds"
Update-GitHubPullRequest -Repository $Repository -PullRequest $PullRequest -IssueIds $issueIds