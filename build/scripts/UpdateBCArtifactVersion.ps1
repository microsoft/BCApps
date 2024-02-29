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

function Update-BCArtifactVersion($BranchName) {
    $artifactValue = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
    $minimumVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
    Write-Host "Current BCArtifact is $artifactValue. Looking for a new artifact with minimum version $minimumVersion"

    if (($BranchName -eq "main") -or ($BranchName -match "^releases/\d+\.x")) {
        # The artifact version for main and releases/*.x should always come from bcinsider
        Write-Host "Getting latest version from bcinsider"
        $newArtifact = Get-BCArtifactVersion -StorageAccount bcinsider -MinimumVersion $minimumVersion -ReturnUrl
    } else {
        # For other branches use bcartifacts if possible. Otherwise, fallback to bcinsider artifacts from the last 7 days
        Write-Host "Getting latest version from bcartifacts"
        $newArtifact = Get-BCArtifactVersion -StorageAccount bcartifacts -MinimumVersion $minimumVersion -ReturnUrl
        if (-not $newArtifact) {
            Write-Host "Latest version not found in bcartifacts. Trying bcinsider"
            $newArtifact = Get-BCArtifactVersion -StorageAccount bcinsider -MinimumVersion $minimumVersion -After ((Get-Date).AddDays(-7)) -ReturnUrl
        }
    }

    if (-not $newArtifact) {
        throw "Could not find BCArtifact version (for min version: $minimumVersion)"
    }

    Write-Host "Updating to latest BCArtifact: $newArtifact"
    Set-ConfigValue -Key "artifact" -Value $newArtifact -ConfigType AL-Go
    return $newArtifact
}

$pullRequestTitle = "[$TargetBranch] Update BC Artifact version"
$BranchName = New-TopicBranchIfNeeded -Repository $Repository -Category "UpdateBCArtifactVersion/$TargetBranch" -PullRequestTitle $pullRequestTitle

$updatesAvailable = Update-BCArtifactVersion -BranchName $TargetBranch

if ($updatesAvailable) {
    # Create branch and push changes
    Set-GitConfig -Actor $Actor
    Push-GitBranch -BranchName $BranchName -Files @(".github/AL-Go-Settings.json") -CommitMessage $pullRequestTitle
    New-GitHubPullRequest -Repository $Repository -BranchName $BranchName -TargetBranch $TargetBranch -label "automation" -PullRequestDescription "Fixes AB#420000"
} else {
    Write-Host "No updates available"
}
