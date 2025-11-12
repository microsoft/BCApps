Param(
    [Hashtable]$parameters
)
Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)
$testType = Get-ALGoSetting -Key "testType"

$parameters["returnTrueIfAllPassed"] = $true

# Run test codeunits with specified TestType, RequiredTestIsolation set to None or Codeunit
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve

# Unit Tests
$parameters["companyName"] = "CRONUS UnitTest"
$AllUnitTestsPassed = (. $script -parameters $parameters -TestType "UnitTest")

# Integration Tests
$parameters["companyName"] = "CRONUS IntegrationTest"
$AllIntegrationTestsPassed = (. $script -parameters $parameters -TestType "IntegrationTest")
# Run test codeunits with RequiredTestIsolation set to Disabled
$AllIntegrationTestsPassedWithIsolationDisabled = (. $script -parameters $parameters -DisableTestIsolation -TestType $testType)

return $AllUnitTestsPassed -and $AllIntegrationTestsPassed -and $AllIntegrationTestsPassedWithIsolationDisabled
