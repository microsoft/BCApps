param(
    [string] $SourceRepository,
    [string] $TargetRepository,
    [string] $Branch,
    [switch] $ManagedIdentityAuth
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-AccessToken {
    param(
        [switch] $ManagedIdentityAuth
    )

    if ($ManagedIdentityAuth) {
        az login --identity --allow-no-subscriptions | Out-Null
    } else {
        az login
    }
    return (az account get-access-token | ConvertFrom-Json)
}

$MIAccessToken = Get-AccessToken -ManagedIdentityAuth:$ManagedIdentityAuth

git clone "https://$($MIAccessToken.accessToken)@$TargetRepository" BCApps
Push-Location BCApps

# Fetch repos and checkout branch
RunAndCheck git reset HEAD --hard
RunAndCheck git remote add upstream $SourceRepository
RunAndCheck git fetch --all

if ($Branch -match "refs/heads/") {
    $Branch = $Branch -replace "refs/heads/", ""
    if (RunAndCheck git ls-remote origin $branch) {
        RunAndCheck git checkout origin/$branch --track
        RunAndCheck git pull origin $branch
    }
    else {
        RunAndCheck git checkout upstream/$branch --track
    }
    
    # Merge changes from upstream
    RunAndCheck git pull upstream $branch
    
    # Push to origin
    RunAndCheck git push origin $Branch
}

RunAndCheck git push origin --tags

Pop-Location