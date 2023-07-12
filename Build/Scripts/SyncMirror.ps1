param(
    [string] $SourceRepository,
    [string] $Branch
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

$Branch = $Branch -replace "refs/heads/", ""

git config --global user.email "d365bc-agentpool-nonprod-bcapps-sync@microsoft.com"
git config --global user.name "BCApps-Sync"

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