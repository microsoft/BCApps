function New-BCAppsBackport() {
    param(
        [Parameter(Mandatory=$true)]
        [string] $PullRequestNumber,
        [Parameter(Mandatory=$true)]
        [string[]] $TargetBranches
    )
    Import-Module $PSScriptRoot/EnlistmentHelperFunctions.psm1

    # Check gh cli is installed
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "Please install the gh cli from"
    }

    # Check that there are no uncommitted changes
    if (RunAndCheck git diff --name-only) {
        throw "You have uncommitted changes. Please commit, revert or stash your changes before running this command."
    }

    # Get the pull request details
    $pullRequestDetails = (gh pr view $PullRequestNumber --json title,number | ConvertFrom-Json)

    # Get the list of existing pull requests
    $existingPullRequests = gh pr list --json title,state,baseRefName,url | ConvertFrom-Json

    # Get the current branch before starting to backport
    $startingBranch = RunAndCheck git rev-parse --abbrev-ref HEAD

    $pullRequests = @{}
    $branchNameSuffix = "$PullRequestNumber/$(Get-Date -Format "yyyyMMddHHmmss")"
    foreach($TargetBranch in $TargetBranches) {
        try {
            $title = "[$TargetBranch] $($pullRequestDetails.title)"
            $body = "This pull request backports #$($pullRequestDetails.number) to $TargetBranch"
            $body += "`r`n`r`nFixes [**Insert Work Item Number Here**]"

            # Check if there is already a pull request for this branch
            $existingPr = $existingPullRequests | Where-Object { $_.title -eq $title -and $_.state -eq "OPEN" -and $_.baseRefName -eq $TargetBranch }
            if ($existingPr) {
                Write-Host "Pull request for $TargetBranch already exists: $($existingPr.url)" -ForegroundColor Yellow
                continue
            }

            # Create a new branch for the cherry-pick
            $cherryPickBranch = "hotfix/$TargetBranch/$branchNameSuffix"
            RunAndCheck git checkout -b $cherryPickBranch $TargetBranch
            RunAndCheck git pull origin $TargetBranch

            # Apply patch on top of the branch
            gh pr diff --patch $PullRequestNumber | RunAndCheck git am

            # Push the branch and create a pull request
            RunAndCheck git push origin $cherryPickBranch
            gh pr create --title $title --body $body --base $TargetBranch --head $cherryPickBranch

            $backportPr = gh pr view --json url | ConvertFrom-Json
            if ($backportPr.url) {
                $pullRequests.Add($TargetBranch, $backportPr.url)
            }
        } catch {
            git am --abort
            RunAndCheck git checkout $startingBranch
            Write-Host "Failed to backport to $TargetBranch. Please inspect the error and try again." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            throw $_.Exception.Message
        }
    }

    # Go back to the original branch
    RunAndCheck git checkout $startingBranch

    if ($pullRequests.Count -eq 0) {
        Write-Host "No pull requests created" -ForegroundColor Yellow
        return
    }

    Write-Host "Backport pull requests created:" -ForegroundColor Green
    foreach($pullRequest in $pullRequests.GetEnumerator()) {
        Write-Host " - $($pullRequest.Key): $($pullRequest.Value)" -ForegroundColor Green
    }
}

Export-ModuleMember -Function *-*
