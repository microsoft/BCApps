Param(
    [Hashtable]$parameters
)

$parameters["testType"] = "UnitTest"

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters

# Integration Tests should run with TestData = Contoso Demo Data (Setup Data)
$parameters["testType"] = "IntegrationTest"
$parameters["SetupData"] = $true

$script = Join-Path $PSScriptRoot "../../../scripts/ImportTestDataInBcContainer.ps1" -Resolve
. $script -parameters $parameters

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters