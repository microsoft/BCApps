Param(
    [Hashtable] $parameters,
    [switch] $DisableTestIsolation,
    [switch] $ReinstallUninstalledApps
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

if ($ReinstallUninstalledApps) {
    Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

    # Get all uninstalled apps and install them in the container
    $allUninstalledApps = Get-BcContainerAppInfo -containerName $parameters["containerName"] -tenantSpecificProperties -sort DependenciesFirst | Where-Object { $_.IsInstalled -eq $false }
    Install-AppFromContainer -ContainerName $parameters["containerName"] -DependenciesToInstall $allUninstalledApps.Name

    # Log all the installed apps
    foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
        Write-Verbose "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - $($app.IsInstalled) / $($app.IsPublished)"
    }
}

Run-TestsInBcContainer @parameters
