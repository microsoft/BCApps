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
Import-Module (Join-Path $PSScriptRoot 'ArtifactBaseline.psm1') -Force

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

$installedApps = Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast

# PROTOTYPE: the artifact database already has every app of the BCApps commit it was built from
# published, installed and synchronized. Only remove the apps that changed since that commit.
# See build/scripts/ArtifactBaseline.md. Any doubt falls back to removing everything.
$baseline = [PSCustomObject]@{ IsUsable = $false; Reason = 'Not enabled'; BaselineCommit = ''; ChangedAppNames = @(); KnownAppNames = @() }
if ((Get-ALGoSetting -Key 'useArtifactBaseline') -eq $true) {
    try {
        if (-not $parameters.ContainsKey('artifactUrl') -or -not $parameters.artifactUrl) {
            throw "No artifactUrl was passed to New-BcContainer"
        }
        $baseline = Resolve-ArtifactBaseline -ArtifactUrl $parameters.artifactUrl -BaseFolder (Get-BaseFolder) -BuildMode "$env:BuildMode"
    }
    catch {
        $baseline.Reason = "Failed to resolve the artifact baseline - $($_.Exception.Message)"
    }
    Write-Host "ARTIFACT BASELINE: usable=$($baseline.IsUsable) commit=$($baseline.BaselineCommit) - $($baseline.Reason)"
}

if ($baseline.IsUsable) {
    # Remove the apps that changed since the artifact, plus anything in the artifact database
    # that this repository does not produce (which today's clean-everything loop also removes).
    $appsToRemove = @(Get-AppsToUnpublish -InstalledApps $installedApps -ChangedAppNames $baseline.ChangedAppNames -KnownAppNames $baseline.KnownAppNames)
    Write-Host "ARTIFACT BASELINE: reusing $($installedApps.Count - $appsToRemove.Count) app(s) from the artifact, refreshing $($appsToRemove.Count)"
}
else {
    $appsToRemove = $installedApps
}

$removedNames = @($appsToRemove | ForEach-Object { $_.Name })
Set-ArtifactBaselineState -State @{
    IsUsable          = $baseline.IsUsable
    Reason            = $baseline.Reason
    BaselineCommit    = $baseline.BaselineCommit
    ChangedAppNames   = @($baseline.ChangedAppNames)
    # Apps that survive in the container - anything else still has to be published by AL-Go.
    ContainerAppNames = @($installedApps | Where-Object { $removedNames -notcontains $_.Name } | ForEach-Object { $_.Name })
} | Out-Null

# Clean the container for the apps that AL-Go is going to (re)publish
foreach($app in $appsToRemove) {
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