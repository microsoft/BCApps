<#
.SYNOPSIS
    Updates the BCArtifact version in the AL-Go settings file (artifact property)
.DESCRIPTION
    This script will update the BCArtifact version in the AL-Go settings file (artifact property) to the latest version available on the BC artifacts feed (bcinsider/bcartifacts storage account).
    If the version is updated, a new branch will be created and a pull request will be created to merge the changes into the target branch.
.PARAMETER TargetBranch
    The branch to create the pull request to
.PARAMETER Actor
    The name of the user that will be used as commit author
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,
    [Parameter(Mandatory = $true)]
    [string]$TargetBranch,
    [Parameter(Mandatory = $true)]
    [string]$Actor
)

# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
Import-Module $PSScriptRoot\AutomatedSubmission.psm1

function UpdateBCArtifactVersion() {
    $currentArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    Write-Host "Current BCArtifact URL: $currentArtifactUrl"

    $currentVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
    $latestArtifactUrl = Get-LatestBCArtifactUrl -minimumVersion $currentVersion

    Write-Host "Latest BCArtifact URL: $latestArtifactUrl"

    if($latestArtifactUrl -ne $currentArtifactUrl) {
        Write-Host "Updating BCArtifact version from $currentArtifactUrl to $latestArtifactUrl"
        Set-ConfigValue -Key "artifact" -Value $latestArtifactUrl -ConfigType AL-Go

        return $true
    }

    return $false
}

$pullRequestTitle = "[$TargetBranch] Update BC Artifact version"
$BranchName = New-TopicBranchIfNeeded -Repository $Repository -Category "UpdateBCArtifactVersion/$TargetBranch" -PullRequestTitle $pullRequestTitle

$updatesAvailable = UpdateBCArtifactVersion

if ($updatesAvailable) {
    # Create branch and push changes
    Set-GitConfig -Actor $Actor
    Push-GitBranch -BranchName $BranchName -Files @(".github/AL-Go-Settings.json") -CommitMessage $pullRequestTitle
    New-GitHubPullRequest -Repository $Repository -BranchName $BranchName -TargetBranch $TargetBranch -label "Automation" -PullRequestDescription "Fixes AB#420000"
} else {
    Write-Host "No updates available"
}
