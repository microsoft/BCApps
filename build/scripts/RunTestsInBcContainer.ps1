Param(
    [Hashtable] $parameters,
    [switch] $DisableTestIsolation
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-DisabledTestsFolder
{
    $baseFolder = Get-BaseFolder
    return "$baseFolder\src\System Application\Test\DisabledTests"
}

function Get-DisabledTests
(
    [string] $DisabledTestsFolder = (Get-DisabledTestsFolder)
)
{
    if(-not (Test-Path $DisabledTestsFolder))
    {
        return
    }

    $disabledCodeunits = Get-ChildItem -Filter "*.json" -Path $DisabledTestsFolder

    $disabledTests = @()
    foreach($disabledCodeunit in $disabledCodeunits)
    {
        $disabledTests += (Get-Content -Raw -Path $disabledCodeunit.FullName | ConvertFrom-Json)
    }

    return @($disabledTests)
}

function Get-TestsInGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string] $groupName
    )

    $baseFolder = Get-BaseFolder

    $groupFiles = Get-ChildItem -Path $baseFolder -Filter 'TestGroups.json' -Recurse -File

    $testsInGroup = @()
    foreach($groupFile in $groupFiles)
    {
        $testsInGroup += Get-Content -Raw -Path $groupFile.FullName | ConvertFrom-Json | Where-Object { $_.group -eq $groupName }
    }

    return $testsInGroup
}

$disabledTests = @(Get-DisabledTests)
$noIsolationTests = Get-TestsInGroup -groupName "No Test Isolation"

if ($DisableTestIsolation)
{
    $parameters["testRunnerCodeunitId"] = "130451" # Test Runner with disabled test isolation

    # When test isolation is disabled, only tests from the "No Test Isolation" group should be run
    $parameters["testCodeunitRange"] = @($noIsolationTests | ForEach-Object { $_.codeunitId }) -join "|"
}
else { # Test isolation is enabled
    # Manually disable the test codeunits, as they need to be run without test isolation
    $noIsolationTests | ForEach-Object {
        $disabledTests += @{
            "codeunitId" = $_.codeunitId
            "codeunitName" = $_.codeunitName
            "method" = "*"
        }
    }
}

if ($disabledTests)
{
    $parameters["disabledTests"] = $disabledTests
}

Run-TestsInBcContainer @parameters
