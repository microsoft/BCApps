Param(
    [Hashtable]$parameters
)
Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)

#TODO: Revert this when 616057 is fixed
if (((Get-BuildMode) -eq "CZ") -and ($parameters["appName"] -eq "Quality Management-Tests")) {
    Write-Host "Skipping tests for Quality Management in CZ build mode due to 616057"
    return $true
}

$testType = Get-ALGoSetting -Key "testType"

$parameters["returnTrueIfAllPassed"] = $true

# Run test codeunits with specified TestType, RequiredTestIsolation set to None or Codeunit
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
$AllTestsPassed = (. $script -parameters $parameters -TestType $testType)

# Uncategorized tests do not have RequiredTestIsolation set on the codeunits
if ($testType -eq "Uncategorized") {
    return $AllTestsPassed
}

# Run test codeunits with RequiredTestIsolation set to Disabled
$AllTestsPassedIsolation = (. $script -parameters $parameters -DisableTestIsolation -TestType $testType)

return $AllTestsPassed -and $AllTestsPassedIsolation
