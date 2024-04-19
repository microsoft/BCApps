param (
    [Parameter(Mandatory = $false, HelpMessage="JSON-formatted array of branch names to include")]
    [string] $include = '[]'
)

# Current path is .github/actions/GetGitBranches
# Import EnlistmentHelperFunctions module from build/scripts
Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$includeBranches = ConvertFrom-Json $include

RunAndCheck git fetch
$allBranches = @(RunAndCheck git for-each-ref --format="%(refname:short)" refs/remotes/origin/) | Where-Object { $_ -ne 'origin' } | ForEach-Object { $_ -replace 'origin/', '' }

if ($includeBranches) {
    Write-Host "Filtering branches by: $($includeBranches -join ', ')"
    $branches = @()
    foreach ($branchFilter in $includeBranches) {
        $branches += $allBranches | Where-Object { $_ -like $branchFilter }
    }
}
else {
    $branches = $allBranches
}

Write-Host "Git branches: $($branches -join ', ')"

$branchesJson = ConvertTo-Json $branches -Compress
Add-Content -Path $env:GITHUB_OUTPUT -Value "branchesJson=$branchesJson"