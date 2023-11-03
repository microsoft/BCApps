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

Write-Host "Validating PR $PullRequestNumber"
    
$pullRequest = [GitHubPullRequest]::new($PullRequestNumber, $Repository)

$prDescription = $pullRequest.GetBody()

Write-Host "PR desc: $prDescription"
$issuesStartingPoint = "Fixes #"

$issueStartingIndex = -1
if($prDescription) {
    $issueStartingIndex = $prDescription.IndexOf($issuesStartingPoint)
}

if ($issueStartingIndex -eq -1) {
    throw "::Error:: Could not find issues section in the pull request description. Please make sure the pull request description contains a line that contains 'Fixes #' followed by the issue number being fixed"
} 

$issuesDescription = $prDescription.Substring($issueStartingIndex + $($issuesStartingPoint.Length) - 1)

$issueIds = $issuesDescription.Split(' ,') | Where-Object { $_ -match "#\d+" } | ForEach-Object { [int] $_.Trim("# ") }

foreach ($issueId in $issueIds) {

    Write-Host "Validating issue $issueId"

    $issue = [GitHubIssue]::Get($issueId, $this.Repository)

    if ($issue) {

        Write-Host "Issue $issueId found: $(ConvertTo-Json $issue))"

        $Comment = "Issue $($issue.html_url) is not approved. Please make sure the issue is approved before continuing with the pull request"
        if (-not $issue.IsApproved()) {
            $this.PullRequest.AddComment($Comment)

            Write-Warning "::Warning:: $Comment"

            # Should the workflow fail if the issue is not approved?
        }
        else {
            $this.PullRequest.RemoveComment($Comment)
        }
    }
    else {
        Write-Warning "::Warning:: Issue $issueId not found"
        # Should the workflow fail if the issue is not found?
    }
}

Write-Host "PR $PullRequestNumber validated successfully"
