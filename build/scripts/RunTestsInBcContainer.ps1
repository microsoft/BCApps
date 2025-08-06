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

$disabledTests = @(Get-DisabledTests)

if ($DisableTestIsolation)
{
    $parameters["requiredTestIsolation"] = "Disabled" # filtering on tests that require Disabled Test Isolation
    $parameters["testRunnerCodeunitId"] = "130451" # Test Runner with disabled test isolation
}

if ($disabledTests)
{
    $parameters["disabledTests"] = $disabledTests
}

Run-TestsInBcContainer @parameters -renewClientContextBetweenTests
