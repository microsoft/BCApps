Param(
    [Hashtable]$parameters,
    [string[]]$AppsToUnpublish = @("All")
)

$parameters.multitenant = $true
$parameters.RunSandboxAsOnPrem = $true
$parameters.memoryLimit = "16G"
if ("$env:GITHUB_RUN_ID" -eq "") {
    $parameters.includeAL = $true
    $parameters.doNotExportObjectsToText = $true
    $parameters.shortcuts = "none"
}

Import-Module (Join-Path $PSScriptRoot 'PlatformHelper.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'EnlistmentHelperFunctions.psm1') -Force

$platformVersion = (Get-ConfigValue -Key "BCPlatform" -ConfigType Packages).Version
if ($platformVersion) {
    $platformVersion = Resolve-PlatformVersion -Version $platformVersion
    $platformUrl = Get-PlatformVersionUrl -Version $platformVersion
    $parameters.platformArtifactUrl = "$platformUrl/platform"
}

New-BcContainer @parameters

Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName "EnforceUserPathForAlFileOperations" -keyValue "false"
Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName "UsePermissionSetsFromExtensions" -keyValue "true"
Restart-BcContainer -containerName $parameters.ContainerName

# Clean-BcContainerDatabase -useNewDatabase requires a developer license file to be present in
# the container's 'my' folder (it throws "Container must be started with a developer license"
# otherwise) and imports it into the freshly created database. BCApps CI does not pass a license
# to New-BcContainer, so seed the 'my' folder with the license shipped inside the downloaded BC
# artifact (a '.bclicense' file now present in the BcContainerHelper artifacts cache).
$licenseFile = Get-ChildItem -Path $bcContainerHelperConfig.bcartifactsCacheFolder -Recurse -Filter '*.bclicense' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $licenseFile) {
    throw "Could not find a '.bclicense' file under '$($bcContainerHelperConfig.bcartifactsCacheFolder)' to license the new database."
}
$myFolder = Join-Path $bcContainerHelperConfig.hostHelperFolder "Extensions\$($parameters.ContainerName)\my"
Write-Host "Seeding developer license '$($licenseFile.FullName)' into '$myFolder' for the database reset"
Copy-Item -Path $licenseFile.FullName -Destination (Join-Path $myFolder 'license.bclicense') -Force

# Reset the container database in a single atomic operation before removing the apps.
# '-useNewDatabase' drops and recreates an empty application database (re-importing the license
# seeded above), leaving only the platform System symbols and the System Application published.
# This means the loop below only has to remove those few remaining apps, and each removal is cheap
# because the fresh database has no data/schema to tear down - avoiding the ~19 min per-app
# 'Sync-NAVApp -mode Clean' loop over ~150 pre-installed apps.
# A credential is passed because the container uses NavUserPassword authentication.
Clean-BcContainerDatabase -containerName $parameters.ContainerName -useNewDatabase -credential $parameters.Credential

$installedApps = Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast

# Clean the container for all apps. Apps will be installed by AL-Go
foreach($app in $installedApps) {
    Write-Host "Removing $($app.Name)"
    UnInstall-BcContainerApp -containerName $parameters.ContainerName -name $app.Name -doNotSaveData -doNotSaveSchema -force

    if (($AppsToUnpublish -contains "All") -or ($AppsToUnpublish -contains $app.Name)) {
        Write-Host "Unpublishing $($app.Name)"
        Unpublish-BcContainerApp -containerName $parameters.ContainerName -name $app.Name -unInstall -doNotSaveData -doNotSaveSchema -force
    }
}

Write-Host "Current installed apps in container $($parameters.ContainerName)"
foreach ($app in (Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - IsInstalled: $($app.IsInstalled) - IsPublished: $($app.IsPublished)"
}

Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock { $progressPreference = 'SilentlyContinue' }