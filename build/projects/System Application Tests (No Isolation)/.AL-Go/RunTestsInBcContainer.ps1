Param(
    [Hashtable]$parameters
)

$parameters["testRunnerCodeunitId"] = "138705" # Disables the test isolation for this project

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters