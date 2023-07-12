param(
    [string] $SourceRepository,
    [string] $TargetRepository,
    [string] $Branch
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-AccessTokenFromManagedIdentity() {
    az login --identity --allow-no-subscriptions | Out-Null
    return (az account get-access-token | ConvertFrom-Json)
}

$Branch = $Branch -replace "refs/heads/", ""

$MIAccessToken = Get-AccessTokenFromManagedIdentity

git clone "https://$($MIAccessToken.accessToken)@$TargetRepository" BCApps
Push-Location BCApps

#git config --global user.email "BCApps-Sync@microsoft.com"
#git config --global user.name "BCApps-Sync"

# Fetch repos and checkout branch
RunAndCheck git reset HEAD --hard
RunAndCheck git remote add upstream $SourceRepository
RunAndCheck git fetch --all
RunAndCheck git checkout origin/$branch --track

# Merge changes from origin and upstream
RunAndCheck git pull origin $branch
RunAndCheck git pull upstream $branch

# Push to origin
RunAndCheck git push origin $Branch
RunAndCheck git push origin --tags