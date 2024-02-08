function New-BCAppsBackport() {
    param(
        [Parameter(Mandatory=$true)]
        [string] $PullRequestNumber,
        [Parameter(Mandatory=$true)]
        [string[]] $TargetBranches,
        [Parameter(Mandatory=$false)]
        [switch] $SkipConfirmation
    )
    Import-Module $PSScriptRoot/EnlistmentHelperFunctions.psm1

    PrecheckBackport -TargetBranches $TargetBranches -PullRequestNumber $PullRequestNumber

    # Get the pull request details
    $pullRequestDetails = (gh pr view $PullRequestNumber --json title,number,body,headRefName,baseRefName,mergeCommit,potentialMergeCommit | ConvertFrom-Json)
    Write-Host "Backport to: $($TargetBranches -join ",")" -ForegroundColor Cyan
    Write-Host "Pull Request Source Branch: $($pullRequestDetails.headRefName)" -ForegroundColor Cyan
    Write-Host "Pull Request Target Branch: $($pullRequestDetails.baseRefName)" -ForegroundColor Cyan
    Write-Host "Pull Request Title: $($pullRequestDetails.title)" -ForegroundColor Cyan
    Write-Host "Pull Request Description: `n$($pullRequestDetails.body)" -ForegroundColor Cyan

    if (-not $SkipConfirmation) {
        GetConfirmation -Message "Please review the about information and press (y)es to continue or any other key to stop" 
    }

    # Get the list of existing pull requests
    $existingOpenPullRequests = gh pr list --state open --json title,state,baseRefName,url | ConvertFrom-Json

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
            $existingPr = $existingOpenPullRequests | Where-Object { ($_.title -eq $title) -and ($_.baseRefName -eq $TargetBranch) }
            if ($existingPr) {
                Write-Host "Pull request for $TargetBranch already exists: $($existingPr.url)" -ForegroundColor Yellow
                continue
            }

            # Create a new branch for the cherry-pick
            $cherryPickBranch = "hotfix/$TargetBranch/$branchNameSuffix"

            # Port the pull request to the target branch
            PortPullRequest -PullRequestDetails $pullRequestDetails -TargetBranch $TargetBranch -CherryPickBranch $cherryPickBranch

            # Create a pull request for the cherry-pick
            gh pr create --title $title --body $body --base $TargetBranch --head $cherryPickBranch

            $backportPr = gh pr view $cherryPickBranch --json url | ConvertFrom-Json
            if ($backportPr.url) {
                $pullRequests.Add($TargetBranch, $backportPr.url)
            }
        } catch {
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

function PrecheckBackport($TargetBranches, $PullRequestNumber) {
    # Check gh cli is installed
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "Please install the gh cli from"
    }

    # Check that there are no uncommitted changes
    if (RunAndCheck git diff --name-only) {
        throw "You have uncommitted changes. Please commit, revert or stash your changes before running this command."
    }

    # Validate Target Branches exist
    foreach($TargetBranch in $TargetBranches) {
        git show-ref --verify --quiet "refs/heads/$TargetBranch"
        if ($LASTEXITCODE -ne 0) {
            throw "Branch $TargetBranch does not exist"
        }
    }
}

function PortPullRequest($PullRequestDetails, $TargetBranch, $CherryPickBranch) {
    RunAndCheck git checkout -b $CherryPickBranch origin/$TargetBranch

    try {
        if ($pullRequestDetails.mergeCommit) {
            RunAndCheck git cherry-pick $pullRequestDetails.mergeCommit.oid 
        } else {
            RunAndCheck git fetch origin refs/pull/$($pullRequestDetails.number)/merge
            RunAndCheck git cherry-pick $pullRequestDetails.potentialMergeCommit.oid -m 1
        }
    } catch {
        Write-Host -ForegroundColor Red "Cherry picking commitid $cherrypickId failed. $_"
        Write-Host "To abort, press 'n' and run git cherry-pick --abort"
        Write-Host "To continue, resolve all conflicts in a new window, run git cherry-pick --continue and then press 'y'"
        GetConfirmation -Message "Do you want to continue?"
    }

    RunAndCheck git push origin $CherryPickBranch
}

function GetConfirmation($Message) {
    $confirmation = Read-Host -Prompt "$Message (y/n)"
    if ($confirmation -ne "y") {
        throw "Operation cancelled"
    }
}

Export-ModuleMember -Function New-BCAppsBackport