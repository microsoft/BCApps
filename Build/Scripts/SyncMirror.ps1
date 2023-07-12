param(
    [string] $SourceRepository,
    [string] $Branch
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

$Branch = $Branch -replace "refs/heads/", ""


# Fetch repos and checkout branch
RunAndCheck git reset HEAD --hard
RunAndCheck git remote add upstream $SourceRepository
#RunAndCheck git fetch --all
Write-Host "RunAndCheck git fetch origin"
RunAndCheck git fetch origin

Write-Host "RunAndCheck git fetch upstream"
RunAndCheck git fetch upstream

RunAndCheck git checkout origin/$branch --track

# Merge changes from origin and upstream
RunAndCheck git pull origin $branch
RunAndCheck git pull upstream $branch

# Push to origin
RunAndCheck git push origin $Branch
RunAndCheck git push origin --tags