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
# published, synchronized AND installed. That is already the state a test container needs, so the
# goal is to change as little of it as possible rather than tear it down and rebuild it.
#
# Only apps this repository does not produce (plus the never-in-a-container list) are removed.
# Apps whose source changed are deliberately left installed and are replaced in place by
# PublishBcContainerApp.ps1 with -upgrade: uninstalling one would force out every installed app
# that depends on it (516 of them for Base Application), which is the whole cost we are avoiding.
#
# See build/scripts/ArtifactBaseline.md. Any doubt falls back to removing everything.
$appsToRemove = $installedApps
$appsUntouched = @()
$baseline = [PSCustomObject]@{ IsUsable = $false; Reason = 'Not enabled'; BaselineCommit = ''; ChangedApps = @(); KnownApps = @() }

try {
    if ((Get-ALGoSetting -Key 'useArtifactBaseline') -eq $true) {
        if (-not $parameters.ContainsKey('artifactUrl') -or -not $parameters.artifactUrl) {
            throw "No artifactUrl was passed to New-BcContainer"
        }
        $baseline = Resolve-ArtifactBaseline -ArtifactUrl $parameters.artifactUrl -BaseFolder (Get-BaseFolder) -BuildMode "$env:BuildMode"
        Write-Host "Artifact Baseline: usable=$($baseline.IsUsable) commit=$($baseline.BaselineCommit) - $($baseline.Reason)"

        if ($baseline.IsUsable) {
            $split = Split-ContainerApps -InstalledApps @($installedApps) -KnownApps @($baseline.KnownApps)
            $appsToRemove = @($split.ToUnpublish)
            $appsUntouched = @($split.ToLeaveAlone)

            # Two different populations, easy to confuse: the "N of 841" above counts apps in the
            # REPOSITORY, these count the apps the CONTAINER holds.
            Write-Host "Artifact Baseline: the container holds $($installedApps.Count) app(s) - leaving $($appsUntouched.Count) installed and untouched, unpublishing $($appsToRemove.Count) that this repository does not produce"
            Write-Host "Artifact Baseline: changed apps stay installed and are replaced in place by the publish hook (-upgrade), so no dependent has to be uninstalled"
        }
    }
}
catch {
    Write-Host "Artifact Baseline: disabled for this build - $($_.Exception.Message)"
    $baseline.IsUsable = $false
    $appsToRemove = $installedApps
    $appsUntouched = @()
}

Set-ArtifactBaselineState -ContainerName $parameters.ContainerName -State @{
    IsUsable     = $baseline.IsUsable
    Reason       = $baseline.Reason
    ChangedApps  = @($baseline.ChangedApps)
    # Apps still published and unchanged, so AL-Go does not need to publish them again.
    RetainedApps = @($appsUntouched | ForEach-Object { Get-AppKey -Publisher $_.Publisher -Name $_.Name })
} | Out-Null

# When the baseline is not usable this is every installed app, which is today's behaviour.
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
$containerApps = @(Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast)
foreach ($app in $containerApps) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - IsInstalled: $($app.IsInstalled) - IsPublished: $($app.IsPublished) - SyncState: $($app.SyncState)"
}

# Publishing an app runs a sync, and BC resolves each dependency against a SYNCHRONIZED
# extension - being published is not enough. The artifact ships a handful of apps published but
# never installed (test libraries such as "Permissions Mock"), and those are not synchronized, so
# publishing anything that depends on them fails with "no synchronized extension could be found
# to satisfy the dependency definition".
#
# The predicate is "retained but not installed" rather than a SyncState comparison: an installed
# app is necessarily synchronized, so IsInstalled is a sound invariant, while SyncState is an
# undocumented enum. Measured in the container: all 96 installed apps report SyncState 4 and all
# 14 published-but-not-installed ones report 3.
if ($baseline.IsUsable -and $appsUntouched.Count -gt 0) {
    $retainedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($app in $appsUntouched) { [void]$retainedNames.Add($app.Name) }

    $needSync = @($containerApps | Where-Object { $retainedNames.Contains($_.Name) -and -not $_.IsInstalled })
    if ($needSync.Count -gt 0) {
        Write-Host "Artifact Baseline: synchronizing $($needSync.Count) retained app(s) the artifact left published but not installed"
        foreach ($app in $needSync) {
            try {
                Sync-BcContainerApp -containerName $parameters.ContainerName -appName $app.Name -appVersion $app.Version -Mode ForceSync -Force
            }
            catch {
                Write-Host "Artifact Baseline: could not synchronize $($app.Name) - $($_.Exception.Message)"
            }
        }
    }
}
Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock { $progressPreference = 'SilentlyContinue' }
