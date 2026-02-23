Param(
    [Hashtable]$parameters
)

Import-Module (Join-Path $PSScriptRoot "../../../scripts/EnlistmentHelperFunctions.psm1" -Resolve)

# Load country-specific app names from generated list - skip running tests in these
$countryAppsFile = Join-Path $PSScriptRoot "CountrySpecificApps.txt"
$countrySpecificApps = @()
if (Test-Path $countryAppsFile) {
    $countrySpecificApps = Get-Content $countryAppsFile | Where-Object { $_.Trim() -ne "" }
}

# Skip country-specific test apps - they depend on localized BaseApp and can't run in W1 context
if ($parameters.appName -in $countrySpecificApps) {
    Write-Host "Skipping tests in app $($parameters.appName) - it is a country-specific app"
    return $true
}

$testType = Get-ALGoSetting -Key "testType"
$testConfiguration = (Get-Content (Join-Path $PSScriptRoot "TestConfiguration.json" -Resolve) | ConvertFrom-Json)

# Gather all legacy test apps
$allLegacyTestApps = @()
foreach ($bucket in $testConfiguration.PSObject.Properties.Name) {
    if ($bucket -like "LegacyTests-*") {
        $allLegacyTestApps += $testConfiguration.$bucket
    }
}

$isTestAppLegacy = $parameters.appName -in $allLegacyTestApps
if ($testType -ne "Legacy") {
    if ($isTestAppLegacy) {
        Write-Host "Skipping app $($parameters.appName) - it is a legacy test app but testType is set to $testType"
        return $true
    } 
    Write-Host "Running tests in app $($parameters.appName)"
} else {
    if (-not $isTestAppLegacy) {
        Write-Host "Skipping tests in app $($parameters.appName) as it is not a legacy test app"
        return $true
    }
    
    $bucketNumber = Get-ALGoSetting -Key "bucketNumber"
    $testAppsInBucket = $testConfiguration."LegacyTests-Bucket$($bucketNumber)"
    if ($parameters.appName -notin $testAppsInBucket) {
        Write-Host "Skipping tests in app $($parameters.appName) as it is not in $($testAppsInBucket -join ', ')"
        return $true
    }

    Write-Host "Running legacy tests in app $($parameters.appName)"
}

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