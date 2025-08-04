Param(
    [Hashtable]$parameters
)

$parameters["returnTrueIfAllPassed"] = $true
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve

$parameters["testType"] = "UnitTest"
[bool] $AllUnitTestsPassed = (. $script -parameters $parameters)

$parameters["testType"] = "IntegrationTest"
[bool] $AllIntegrationTestsPassed = (. $script -parameters $parameters)

$parameters["testType"] = "Uncategorized"
[bool] $AllUncategorizedTestsPassed = (. $script -parameters $parameters)

return $AllUnitTestsPassed -and $AllIntegrationTestsPassed -and $AllUncategorizedTestsPassed