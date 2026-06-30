# Current path is .github/actions/VerifyMiappSync

# Initialize enlistment (sets $repoRoot and loads shared modules, including Miapp)
. "$env:GITHUB_WORKSPACE/init.ps1"
$env:RepoBranchName = $env:GITHUB_BASE_REF
Invoke-MiSnapApp
