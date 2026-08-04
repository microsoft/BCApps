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
# published, installed and synchronized. Keep the ones whose source has not changed since that
# commit - they only get uninstalled, which leaves them in exactly the state AL-Go's publish step
# produces today, so install order and test discovery downstream are unaffected.
# See build/scripts/ArtifactBaseline.md. Any doubt falls back to removing everything.
$appsToRemove = $installedApps
$appsToKeep = @()
$baseline = [PSCustomObject]@{ IsUsable = $false; Reason = 'Not enabled'; BaselineCommit = ''; ChangedApps = @(); KnownApps = @() }

try {
    if ((Get-ALGoSetting -Key 'useArtifactBaseline') -eq $true) {
        if (-not $parameters.ContainsKey('artifactUrl') -or -not $parameters.artifactUrl) {
            throw "No artifactUrl was passed to New-BcContainer"
        }
        $baseline = Resolve-ArtifactBaseline -ArtifactUrl $parameters.artifactUrl -BaseFolder (Get-BaseFolder) -BuildMode "$env:BuildMode"
        Write-Host "ARTIFACT BASELINE: usable=$($baseline.IsUsable) commit=$($baseline.BaselineCommit) - $($baseline.Reason)"

        if ($baseline.IsUsable) {
            $split = Split-ContainerApps -InstalledApps @($installedApps) -KnownApps @($baseline.KnownApps)
            $appsToRemove = @($split.ToUnpublish)
            $appsToKeep = @($split.ToKeep)
            Write-Host "ARTIFACT BASELINE: reusing $($appsToKeep.Count) app(s) from the artifact, refreshing $($appsToRemove.Count)"
        }
    }
}
catch {
    Write-Host "ARTIFACT BASELINE: disabled for this build - $($_.Exception.Message)"
    $baseline.IsUsable = $false
    $appsToRemove = $installedApps
    $appsToKeep = @()
}

Set-ArtifactBaselineState -ContainerName $parameters.ContainerName -State @{
    IsUsable     = $baseline.IsUsable
    Reason       = $baseline.Reason
    ChangedApps  = @($baseline.ChangedApps)
    # Apps left published in the container; anything else must still be published by AL-Go.
    RetainedApps = @($appsToKeep | ForEach-Object { Get-AppKey -Publisher $_.Publisher -Name $_.Name })
} | Out-Null

# Uninstall every app: the retained ones must end up published-but-not-installed, which is the
# state AL-Go's publish step leaves apps in and which ImportTestDataInBcContainer.ps1 expects.
#
# -doNotSaveSchema drops the extension's schema, which leaves it published but NOT synchronized.
# That is harmless for apps about to be unpublished, but a retained app has to stay synchronized:
# publishing any app runs a sync, and BC resolves each dependency against a SYNCHRONIZED
# extension. Dropping the schema on System Application makes publishing Base Application fail
# with "no synchronized extension could be found to satisfy the dependency definition".
$retainedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($app in $appsToKeep) { [void]$retainedNames.Add($app.Name) }

foreach($app in $installedApps) {
    Write-Host "Removing $($app.Name)"
    if ($retainedNames.Contains($app.Name)) {
        UnInstall-BcContainerApp -containerName $parameters.ContainerName -name $app.Name -doNotSaveData -force
    }
    else {
        UnInstall-BcContainerApp -containerName $parameters.ContainerName -name $app.Name -doNotSaveData -doNotSaveSchema -force
    }
}

# Unpublish the apps AL-Go is going to (re)publish
foreach($app in $appsToRemove) {
    # $AppsToUnpublish is the script parameter (note the different casing): it lets a project
    # keep specific apps published. Do not rename it into $appsToRemove - PowerShell variable
    # names are case-insensitive, so the two would silently become one.
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