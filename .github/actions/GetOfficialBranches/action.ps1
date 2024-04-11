git fetch
$branches = @(git for-each-ref --format="'%(refname:short)'" refs/remotes/origin/releases/ | % { $_ -replace 'origin/', '' })
$branches += "'main'"
$branchMatrix = "[$($branches -join ',')]"

Write-Host "Official branches: $branchMatrix"
Add-Content -Path $env:GITHUB_OUTPUT -Value "OfficialBranches=$branchMatrix"