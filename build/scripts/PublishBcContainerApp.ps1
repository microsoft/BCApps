Param(
    [Hashtable]$parameters,
    [string[]]$AdditionalAppsNotToPublish = @()
)

Import-Module (Join-Path $PSScriptRoot 'ArtifactBaseline.psm1') -Force

# Apps that must never end up in a test container. The list is owned by ArtifactBaseline.psm1 so
# that the container hook removes exactly the same apps from the artifact database that this hook
# refuses to publish.
$listOfAppsNotToPublish = @(Get-AppsNeverInContainer) + $AdditionalAppsNotToPublish

function Test-ShouldPublishApp() {
    param(
        [string]$appFile,
        [string[]]$exclusionList
    )

    $appName = (Get-Item $appFile).BaseName

    $matchedApp = $exclusionList | Where-Object {
        $pattern = "Microsoft_$($_)_*"
        $appName -like $pattern
    }

    if ($null -ne $matchedApp) {
        Write-Host "Skipping publishing of app $appName as it is in the exclusion list."
        return $false
    }

    return $true
}

$appFiles = $parameters["appFile"]
if ($appFiles -is [string]) {
    if (Test-ShouldPublishApp -appFile $appFiles -exclusionList $listOfAppsNotToPublish) {
        $filteredAppFiles = $appFiles
    } else {
        $filteredAppFiles = @()
    }
} elseif ($appFiles -is [array]) {
    $filteredAppFiles = @()
    foreach ($appFile in $appFiles) {
        if (Test-ShouldPublishApp -appFile $appFile -exclusionList $listOfAppsNotToPublish) {
            $filteredAppFiles += $appFile
        }
    }
}

$parameters["appFile"] = $filteredAppFiles

# PROTOTYPE: skip publishing apps the artifact database already holds, unchanged. The state is
# only trusted when it was written for this container by this run.
# See build/scripts/ArtifactBaseline.md.
$baselineState = Get-ArtifactBaselineState -ContainerName $parameters["containerName"]
$appsToUpgrade = @()

if ($baselineState -and $baselineState.IsUsable) {
    $appsToPublish = @($parameters["appFile"] | Where-Object {
        Test-ShouldPublishAppFile -AppFile $_ -ChangedApps @($baselineState.ChangedApps) -RetainedApps @($baselineState.RetainedApps)
    })
    $skipped = @($parameters["appFile"]).Count - $appsToPublish.Count
    if ($skipped -gt 0) {
        Write-Host "Artifact Baseline: skipping $skipped of $(@($parameters["appFile"]).Count) app package(s) in this batch - the artifact already has them published and unchanged"
    }
    if ($appsToPublish.Count -eq 0) {
        Write-Host "Artifact Baseline: nothing left to publish in this batch"
        return
    }

    # An app still installed at the artifact's version cannot just be published and installed
    # again, and uninstalling it first would drag out everything that depends on it. -upgrade
    # publishes the new version and runs Start-NavAppDataUpgrade, replacing it in place.
    $installedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($app in @(Get-BcContainerAppInfo -containerName $parameters["containerName"] -tenantSpecificProperties | Where-Object { $_.IsInstalled })) {
        [void]$installedKeys.Add((Get-AppKey -Publisher $app.Publisher -Name $app.Name))
    }

    $plain = @()
    foreach ($appFile in $appsToPublish) {
        $identity = Get-AppFileIdentity -Path $appFile
        if ($identity -and $installedKeys.Contains($identity.Key)) { $appsToUpgrade += $appFile } else { $plain += $appFile }
    }

    if ($appsToUpgrade.Count -gt 0) {
        Write-Host "Artifact Baseline: upgrading $($appsToUpgrade.Count) app(s) in place - they are still installed at the artifact's version"
    }
    $parameters["appFile"] = $plain
}

$parameters["scope"] = "Global"
# Publish only - do not install. Installation is handled by ImportTestDataInBcContainer.ps1
# which controls the install order based on test type (e.g. Legacy needs DemoTool to run
# before certain apps are installed).
$parameters["install"] = $false
$parameters["upgrade"] = $false
$parameters["sync"] = $true

if (@($parameters["appFile"]).Count -gt 0) {
    Publish-BcContainerApp @parameters
}

if ($appsToUpgrade.Count -gt 0) {
    $upgradeParameters = @{}
    foreach ($key in $parameters.Keys) { $upgradeParameters[$key] = $parameters[$key] }
    $upgradeParameters["appFile"] = $appsToUpgrade
    $upgradeParameters["install"] = $false
    $upgradeParameters["upgrade"] = $true
    $upgradeParameters["sync"] = $true
    Publish-BcContainerApp @upgradeParameters
}
