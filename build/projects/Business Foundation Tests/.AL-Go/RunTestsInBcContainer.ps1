Param(
    [Hashtable]$parameters
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)
$testType = Get-ALGoSetting -Key "testType"

$parameters["returnTrueIfAllPassed"] = $true

# run test codeunits with specified TestType
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
$AllTestsPassed = (. $script -parameters $parameters -TestType $testType)

# Run test codeunits with RequiredTestIsolation set to Disabled
$AllTestsPassedIsolation = (. $script -parameters $parameters -DisableTestIsolation -TestType $testType)

return $AllTestsPassed -and $AllTestsPassedIsolation