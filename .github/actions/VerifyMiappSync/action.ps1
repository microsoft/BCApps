# Current path is .github/actions/VerifyMiappSync

Import-Module "$PSScriptRoot\..\..\..\build\scripts\DevEnv\Miapp\MicroSnapApp.psm1" -Force
$env:RepoBranchName = $env:GITHUB_BASE_REF
Invoke-MiSnapApp
