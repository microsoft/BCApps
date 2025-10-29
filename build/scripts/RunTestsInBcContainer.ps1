Param(
    [Hashtable] $parameters,
    [switch] $DisableTestIsolation
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
            if ($attempt -gt $maxReruns) {
                Write-Host "Tests failed after $maxReruns attempts."
                return $false
            } else {
                Write-Host "Some tests failed. Retrying... (Attempt $($attempt + 1) of $($maxReruns + 1))"
            }
        }
    }
}

if ($DisableTestIsolation)
{
    $parameters["requiredTestIsolation"] = "Disabled" # filtering on tests that require Disabled Test Isolation
    $parameters["testRunnerCodeunitId"] = "130451" # Test Runner with disabled test isolation
}

$parameters["disabledTests"] = @(Get-DisabledTests) # Add disabled tests to parameters
$parameters["renewClientContextBetweenTests"] = $true

return Invoke-TestsWithReruns -parameters $parameters
