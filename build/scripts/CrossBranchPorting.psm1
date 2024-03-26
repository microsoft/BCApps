<#
    .SYNOPSIS
    This script is used to backport a pull request to multiple branches.
    .DESCRIPTION
    This script is used to backport a pull request to multiple branches. It will create a new branch for each backport and create a pull request for each branch.
    .PARAMETER PullRequestNumber
    The number of the pull request to backport.
    .PARAMETER TargetBranches
    The list of branches to backport the pull request to.
    .PARAMETER SkipConfirmation
    Skip the confirmation prompt.
#>
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

    # Change to the base folder of the repository
    Push-Location (Get-BaseFolderForPath -Path $PSScriptRoot)

    try {
        PrecheckBackport -TargetBranches $TargetBranches -PullRequestNumber $PullRequestNumber

        # Get the pull request details
        $pullRequestDetails = (gh pr view $PullRequestNumber --json title,number,body,headRefName,baseRefName,mergeCommit,potentialMergeCommit | ConvertFrom-Json)
        Write-Host "Backport to: $($TargetBranches -join ",")" -ForegroundColor Cyan
        Write-Host "Pull Request Source Branch: $($pullRequestDetails.headRefName)" -ForegroundColor Cyan
        Write-Host "Pull Request Target Branch: $($pullRequestDetails.baseRefName)" -ForegroundColor Cyan
        Write-Host "Pull Request Title: $($pullRequestDetails.title)" -ForegroundColor Cyan
        Write-Host "Pull Request Description: `n$($pullRequestDetails.body)" -ForegroundColor Cyan

        if (-not $SkipConfirmation) {
            GetConfirmation -Message "Please review the above information and press (y)es to continue or any other key to stop"
        }

        # Get the list of existing pull requests
        $existingOpenPullRequests = gh pr list --state open --json title,state,baseRefName,url | ConvertFrom-Json

        # Get the current branch before starting to backport
        $startingBranch = RunAndCheck git rev-parse --abbrev-ref HEAD

        $pullRequests = @{}
        $branchNameSuffix = "$PullRequestNumber/$(Get-Date -Format "yyyyMMddHHmmss")"

        try {
            foreach($TargetBranch in $TargetBranches) {
                $title = "[$TargetBranch] $($pullRequestDetails.title)"
                $title = $title.Substring(0, [Math]::Min(255, $title.Length))
                $body = "This pull request backports #$($pullRequestDetails.number) to $TargetBranch"
                $body += "`r`n`r`nFixes AB#[**Insert Work Item Number Here**]"

                # Check if there is already a pull request for this branch
                $existingPr = $existingOpenPullRequests | Where-Object { ($_.title -eq $title) -and ($_.baseRefName -eq $TargetBranch) }
                if ($existingPr) {
                    Write-Host "Pull request for $TargetBranch already exists: $($existingPr.url)" -ForegroundColor Yellow
                    continue
                }

                # Create a new branch for the cherry-pick
                $cherryPickBranch = "backport/$TargetBranch/$branchNameSuffix"

                # Port the pull request to the target branch
                PortPullRequest -PullRequestDetails $pullRequestDetails -TargetBranch $TargetBranch -CherryPickBranch $cherryPickBranch

                # Create a pull request for the cherry-pick
                gh pr create --title $title --body $body --base $TargetBranch --head $cherryPickBranch

                $backportPr = gh pr view $cherryPickBranch --json url | ConvertFrom-Json
                if ($backportPr.url) {
                    $pullRequests.Add($TargetBranch, $backportPr.url)
                }
            }
        } catch {
            Write-Host "Failed to backport to $TargetBranch. Please inspect the error and try again." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            throw $_.Exception.Message
        } finally {
            # Go back to the original branch
            RunAndCheck git checkout $startingBranch
        }

        if ($pullRequests.Count -eq 0) {
            Write-Host "No pull requests created" -ForegroundColor Yellow
            return
        }

        Write-Host "Backport pull requests created:" -ForegroundColor Green
        foreach($pullRequest in $pullRequests.GetEnumerator()) {
            Write-Host " - $($pullRequest.Key): $($pullRequest.Value)" -ForegroundColor Green
        }
    } catch {
        Write-Host $_ -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function PrecheckBackport($TargetBranches, $PullRequestNumber) {
    # Check gh cli is installed
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "Please install the GitHub CLI by running 'winget install --id GitHub.cli' from your terminal. Once installed open a new terminal and run 'gh auth login' to authenticate with GitHub." -ForegroundColor Red
        throw "Please install GitHub CLI."
    }

    # Check gh cli is authenticated and prompt to authenticate if not
    gh auth status
    if ($LASTEXITCODE -ne 0) {
        Write-Host "GitHub CLI is not authenticated. Please authenticate before continuing to backport." -ForegroundColor Yellow
        gh auth login
    }

    # Check that there are no uncommitted changes
    if (RunAndCheck git diff --name-only) {
        Write-Warning "You have uncommitted changes. Please commit, revert or stash your changes before running this command."
        GetConfirmation -Message "Do you want to stash your changes and continue?"
        RunAndCheck git stash
    }

    # Validate Target Branches exist
    foreach($TargetBranch in $TargetBranches) {
        try {
            RunAndCheck git show-ref --verify --quiet "refs/remotes/origin/$TargetBranch"
        } catch {
            throw "Branch '$TargetBranch' does not exist. Please ensure the branch exists in the remote repository or fetch the latest changes."
        }
    }
}

function PortPullRequest($PullRequestDetails, $TargetBranch, $CherryPickBranch) {
    if ((-not $PullRequestDetails.mergeCommit) -and (-not $PullRequestDetails.potentialMergeCommit)) {
        throw "Cannot find commit to cherry-pick."
    }

    # Create a new branch for the cherry-pick
    RunAndCheck git checkout -b $CherryPickBranch origin/$TargetBranch

    # Cherry pick the merge commit
    try {
        if ($pullRequestDetails.mergeCommit) {
            RunAndCheck git fetch origin $PullRequestDetails.mergeCommit.oid
            RunAndCheck git cherry-pick $PullRequestDetails.mergeCommit.oid
        } else {
            RunAndCheck git fetch origin $PullRequestDetails.potentialMergeCommit.oid
            RunAndCheck git cherry-pick $PullRequestDetails.potentialMergeCommit.oid -m 1
        }
    } catch {
        Write-Host -ForegroundColor Red "Cherry picking commitid $cherrypickId failed. $_"
        Write-Host "To abort, press 'n' and run git cherry-pick --abort"
        Write-Host "To continue, resolve all conflicts in a new window, commit your changes and then press 'y'"
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
