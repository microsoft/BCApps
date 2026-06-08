# Current path is .github/actions/VerifyMiappSync

# Miapp check is temporarily disabled
Write-Host "Miapp sync verification is currently disabled."
return

Import-Module "$PSScriptRoot\..\..\..\build\scripts\Miapp\MicroSnapApp.psm1" -Force
$env:RepoBranchName = $env:GITHUB_BASE_REF
Invoke-MiSnapApp
