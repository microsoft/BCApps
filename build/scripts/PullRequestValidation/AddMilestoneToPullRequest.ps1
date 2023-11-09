using module ..\GitHub\GitHubPullRequest.class.psm1

param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository
)
Import-Module $PSScriptRoot\..\EnlistmentHelperFunctions.psm1

$pullRequest = [GitHubPullRequest]::Get($PullRequestNumber, $Repository)

# Get milestone
$repoVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-GO
$milestone = "Version $repoVersion"

Write-Host "Setting milestone '$milestone' on PR $PullRequestNumber"
$pullRequest.SetMilestone($milestone)