function Port-PullRequestToBranches() {
    param(
        [Parameter(Mandatory=$true)]
        [string] $PullRequestNumber,
        [Parameter(Mandatory=$true)]
        [string[]] $TargetBranches
    )

    # Get the pull request details
    $pullRequestDetails = (gh pr view $PullRequestNumber --json title,body | ConvertFrom-Json)
    $body = $pullRequestDetails.body
    $body = $body -replace '\[AB#\d+\]\(.*?\)', '**INSERT BUG ID HERE**'
    $body = $body -replace 'AB#\d+', '**INSERT BUG ID HERE**'


    foreach($TargetBranch in $TargetBranches) {
        # Get datetime to use in branch name
        $datetime = Get-Date -Format "yyyyMMddHHmmss"
        $cherryPickBranch = "hotfix/$TargetBranch/$PRNumber/$datetime"
        $title = "[$TargetBranch] $($pullRequestDetails.title)"

        git checkout -b $cherryPickBranch $TargetBranch
        git pull origin $TargetBranch
        gh pr diff --patch $PRNumber | git am
        git push origin $cherryPickBranch
        gh pr create --title $title --body $body --base $TargetBranch --head $cherryPickBranch
    }
}

Export-ModuleMember -Function Port-PullRequestToBranches