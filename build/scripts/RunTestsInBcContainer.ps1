Param(
    [Hashtable] $parameters,
    [switch] $DisableTestIsolation,
    [validateSet("UnitTest","IntegrationTest", "Uncategorized")]
    [string] $TestType
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-DisabledTests
{
    $baseFolder = Get-BaseFolder

    $disabledCodeunits = Get-ChildItem -Path $baseFolder -Filter "DisabledTests" -Recurse -Directory | ForEach-Object { Get-ChildItem -Path $_.FullName -Filter "*.json" }
    $disabledTests = @()
    foreach($disabledCodeunit in $disabledCodeunits)
    {
        $disabledTests += (Get-Content -Raw -Path $disabledCodeunit.FullName | ConvertFrom-Json)
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
                CleanUpAfterFailedTests -ContainerName $parameters.ContainerName
            }
        }
    }
}

function CleanUpAfterFailedTests {
    param(
        [string]$ContainerName
    )
    Write-Host "Cleaning up after failed tests in container $ContainerName..."
    CleanUpPublishedApps -ContainerName $ContainerName
}

function CleanUpPublishedApps {
    param(
        [string]$ContainerName
    )
    # Get installed apps in the container published by "Designer" with name "CRM Sync Designer"
    $appsToUninstall = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties | Where-Object { $_.Publisher -eq "Designer" -and $_.Name -eq "CRM Sync Designer" }
    
    foreach($app in $appsToUninstall) {
        if ($app.IsInstalled) {
            Write-Host "Uninstalling $($app.Name) (version $($app.Version))"
            UnInstall-BcContainerApp -containerName $ContainerName -name $app.Name -version $app.Version -publisher $app.Publisher -doNotSaveData -doNotSaveSchema -force
        }

        if ($app.IsPublished) {
            Write-Host "Unpublishing $($app.Name) (version $($app.Version))"
            Unpublish-BcContainerApp -containerName $ContainerName -name $app.Name -version $app.Version  -publisher $app.Publisher -doNotSaveData -doNotSaveSchema -force
        }
    }
}

if ($null -ne $TestType) {
    Write-Host "Using test type $TestType"
    $parameters["testType"] = $TestType
}

$parameters["disabledTests"] = @(Get-DisabledTests) # Add disabled tests to parameters
$parameters["renewClientContextBetweenTests"] = $true

if ($DisableTestIsolation)
{
    Write-Host "Using RequiredTestIsolation: Disabled"
    $parameters["requiredTestIsolation"] = "Disabled" # filtering on tests that require Disabled Test Isolation
    $parameters["testRunnerCodeunitId"] = "130451" # Test Runner with disabled test isolation

    return Invoke-TestsWithReruns -parameters $parameters -maxReruns 1 # do not retry for Isolation Disabled tests, as they leave traces in the DB
}

return Invoke-TestsWithReruns -parameters $parameters
