Param(
    [Hashtable]$parameters
)

$parameters["testType"] = "UnitTest"

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters