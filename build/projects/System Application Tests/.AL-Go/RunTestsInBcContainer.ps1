Param(
    [Hashtable]$parameters
)

$parameters["testType"] = "UnitTest"
$parameters["returnTrueIfAllPassed"] = $true

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
$AllTestsPassed = (. $script -parameters $parameters)

# run test codeunits with RequiredTestIsolation set to Disabled
$AllTestsPassedIsolation = (. $script -parameters $parameters -DisableTestIsolation)

return $AllTestsPassed -and $AllTestsPassedIsolation