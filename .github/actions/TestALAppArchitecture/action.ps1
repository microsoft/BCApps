# The checker comes from this action; the validated sources come from the checked-out repository (current directory).
& "$PSScriptRoot\..\..\..\build\scripts\Test-ALAppArchitecture.ps1" -RepoRoot (Get-Location).Path -FetchMissingBase
