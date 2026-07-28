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
Import-Module (Join-Path $PSScriptRoot 'ResetBcContainerDatabase.psm1') -Force

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

# Reset the container's application database in one bulk operation instead of uninstalling every
# pre-installed app one by one (~19 min). Dropping and recreating the application database removes
# all apps at once (~4 min). Resolve the developer license from the artifact this container was
# built from (via the manifest, so a machine with several cached versions cannot pick the wrong
# one); recreating the database drops the license that was imported at container creation.
$appArtifactPath = Download-Artifacts -artifactUrl $parameters.artifactUrl
$artifactManifest = Get-Content (Join-Path $appArtifactPath 'manifest.json') -Raw | ConvertFrom-Json
$licenseFile = Join-Path $appArtifactPath $artifactManifest.licenseFile
if (-not (Test-Path $licenseFile)) {
    throw "Artifact license '$licenseFile' not found; cannot license the reset database."
}
Reset-BcContainerApplicationDatabase -ContainerName $parameters.ContainerName -Credential $parameters.Credential -LicenseFile $licenseFile

$installedApps = Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast

# The reset leaves only the System Application published. Remove it too so AL-Go publishes the
# repository-built version. This loop now runs over a single app instead of ~150.
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