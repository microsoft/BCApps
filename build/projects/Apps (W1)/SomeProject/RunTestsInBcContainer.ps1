Param(
    [Hashtable]$parameters
)
Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)
$testType = Get-ALGoSetting -Key "testType"

$parameters["returnTrueIfAllPassed"] = $true

# Run test codeunits with specified TestType, RequiredTestIsolation set to None or Codeunit
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
$AllTestsPassed = (. $script -parameters $parameters -TestType $testType)

# TODO: For now only run disabled test isolation for unit tests
if ($testType -ne "UnitTest") {
    return $AllTestsPassed
}

# Run test codeunits with RequiredTestIsolation set to Disabled
$AllTestsPassedIsolation = (. $script -parameters $parameters -DisableTestIsolation -TestType $testType)

return $AllTestsPassed -and $AllTestsPassedIsolation
