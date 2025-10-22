Param(
    [Hashtable]$parameters
)


if ($null -ne $env:settings) {
    Write-Host "AL-Go settings found in environment variable"
    $alGoSettings = $env:settings | ConvertFrom-Json
    if ($alGoSettings.PSObject.Properties.Name -contains "doNotImportTestData") {
        if ($alGoSettings.doNotImportTestData -eq $true) {
            Write-Host "Using test type UnitTest as doNotImportTestData is set to true in AL-Go settings"
            $parameters["testType"] = "UnitTest"
        } else {
            Write-Host "doNotImportTestData is set to false in AL-Go settings. Using default test type."
        }
    } else {
        Write-Host "doNotImportTestData not found in AL-Go settings. Using default test type."
    }
} else {
    Write-Host "No AL-Go settings found in environment variable. Using default test type."
}

$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters