Param(
    [Hashtable] $parameters,
    [switch] $DisableTestIsolation,
    [validateSet("UnitTest","IntegrationTest", "Uncategorized", "Legacy")]
    [string] $TestType
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-DisabledTests
{
    param(
        [string] $AppName
    )

    $baseFolder = Get-BaseFolder

    # Convert app name to folder name format (replace spaces with underscores)
    $appFolderName = $AppName -replace ' ', '_'

    $disabledTests = @()

    # Look for DisabledTests folders and find the app-specific subfolder
    $disabledTestsFolders = Get-ChildItem -Path $baseFolder -Filter "DisabledTests" -Recurse -Directory
    foreach ($disabledTestsFolder in $disabledTestsFolders) {
        $appFolder = Join-Path $disabledTestsFolder.FullName $appFolderName
        if (Test-Path $appFolder) {
            $jsonFiles = Get-ChildItem -Path $appFolder -Filter "*.json"
            foreach ($jsonFile in $jsonFiles) {
                $disabledTests += (Get-Content -Raw -Path $jsonFile.FullName | ConvertFrom-Json)
            }
        }
    }

    return @($disabledTests)
}

function Invoke-TestsWithReruns {
    param(
        [Hashtable]$parameters,
        [int]$maxReruns = 2
    )
    $attempt = 0
    while ($attempt -lt $maxReruns) {
        $testsSucceeded = $false
        # Run tests and catch any exceptions to prevent the script from terminating
        try {
            $testsSucceeded = Run-TestsInBcContainer @parameters
        } catch {
            $testsSucceeded = $false
            Write-Host "Exception occurred while running tests: $($_.Exception.Message) / $($_.Exception.StackTrace)"
        }

        # Check if tests succeeded
        if ($testsSucceeded) {
            Write-Host "All tests passed on attempt $($attempt + 1)."
            return $true
        } else {
            $attempt++
            $parameters["ReRun"] = $true
            if ($attempt -ge $maxReruns) {
                Write-Host "Tests failed after $maxReruns attempts."
                return $false
            } else {
                Write-Host "Some tests failed. Retrying... (Attempt $($attempt + 1) of $($maxReruns + 1))"
            }
        }
    }
}

if (($null -ne $TestType) -and ($TestType -ne "Legacy")) {
    Write-Host "Using test type $TestType"
    $parameters["testType"] = $TestType
}

$parameters["disabledTests"] = @(Get-DisabledTests -AppName $parameters["appName"]) # Add disabled tests to parameters
$parameters["renewClientContextBetweenTests"] = $true

if ($DisableTestIsolation)
{
    Write-Host "Using RequiredTestIsolation: Disabled"
    $parameters["requiredTestIsolation"] = "Disabled" # filtering on tests that require Disabled Test Isolation
    $parameters["testRunnerCodeunitId"] = "130451" # Test Runner with disabled test isolation

    return Invoke-TestsWithReruns -parameters $parameters -maxReruns 1 # do not retry for Isolation Disabled tests, as they leave traces in the DB
}

return Invoke-TestsWithReruns -parameters $parameters
