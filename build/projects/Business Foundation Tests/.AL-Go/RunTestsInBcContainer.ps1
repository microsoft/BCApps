Param(
    [Hashtable]$parameters
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)
Import-Module (Join-Path $PSScriptRoot "../../../scripts/BuildOptimization.psm1" -Resolve)

$baseFolder = Get-BaseFolder
if (Test-ShouldSkipTestApp -AppName $parameters["appName"] -BaseFolder $baseFolder) {
    return $true
}

$testType = Get-ALGoSetting -Key "testType"

$parameters["returnTrueIfAllPassed"] = $true

# run test codeunits with specified TestType
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
$AllTestsPassed = (. $script -parameters $parameters -TestType $testType)

# Run test codeunits with RequiredTestIsolation set to Disabled
$AllTestsPassedIsolation = (. $script -parameters $parameters -DisableTestIsolation -TestType $testType)

return $AllTestsPassed -and $AllTestsPassedIsolation