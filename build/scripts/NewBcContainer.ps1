Param(
    [Hashtable]$parameters,
    [switch]$KeepAppsPublished
)

$parameters.multitenant = $false
$parameters.RunSandboxAsOnPrem = $true
if ("$env:GITHUB_RUN_ID" -eq "") {
    $parameters.includeAL = $true
    $parameters.doNotExportObjectsToText = $true
    $parameters.shortcuts = "none"
}

New-BcContainer @parameters

function PrepareEnvironment() {
    param(
        [string] $ContainerName,
        [boolean] $KeepAppsPublished = $false
    )
    $installedApps = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast

    # Clean the container for all apps. Apps will be installed by AL-Go
    foreach($app in $installedApps) {
        UnInstall-BcContainerApp -containerName $ContainerName -name $app.Name -doNotSaveData -doNotSaveSchema -force

        if ((-not $KeepAppsPublished)) {
            Write-Host "Unpublishing $($app.Name)"
            Unpublish-BcContainerApp -containerName $ContainerName -name $app.Name -unInstall -doNotSaveData -doNotSaveSchema -force
        }
    }

    foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
        Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - IsInstalled: $($app.IsInstalled) - IsPublished: $($app.IsPublished)"
    }
}

PrepareEnvironment -ContainerName $parameters.ContainerName -KeepAppsPublished:$KeepAppsPublished

Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock { $progressPreference = 'SilentlyContinue' }