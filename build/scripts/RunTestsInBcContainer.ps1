Param(
    [Hashtable]$parameters
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

$disabledTests = Get-DisabledTests

if ($disabledTests)
{
    $parameters["disabledTests"] = $disabledTests
}

$testIsolationModules = @('489a0bcb-0619-4bd1-b626-9f30dbe8af4d','0d60b215-6ee1-4789-8e53-866cfa50c23c') # Retention Policy Tests, System Application Tests
if ($testIsolationModules -contains $parameters["extensionId"] ) {
    $parameters["testRunnerCodeunitId"] = "138705"
}

Run-TestsInBcContainer @parameters
