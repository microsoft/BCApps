Param(
    [Hashtable]$parameters
)

$parameters["testType"] = "UnitTest"

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters

# run test codeunits with RequiredTestIsolation set to Disabled
. $script -parameters $parameters -DisableTestIsolation
