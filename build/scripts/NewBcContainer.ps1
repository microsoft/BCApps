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

$maxCleanupAttempts = 2
$cleanupAttempt = 0
$cleanupDone = $false

while (-not $cleanupDone) {
    $cleanupAttempt++
    $cleanupDone = $true
    $installedApps = Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast

    # Clean the container for all apps. Apps will be installed by AL-Go
    foreach($app in $installedApps) {
        Write-Host "Removing $($app.Name)"
        try {
            UnInstall-BcContainerApp -containerName $parameters.ContainerName -name $app.Name -doNotSaveData -doNotSaveSchema -force
        } catch {
            $errText = ($_ | Out-String) + $_.Exception.Message
            if (($errText -match 'Internal CLR error|Fatal error|0x80131506') -and ($cleanupAttempt -lt $maxCleanupAttempts)) {
                Write-Warning "Container CLR crash detected while removing $($app.Name). Restarting container (attempt $cleanupAttempt of $maxCleanupAttempts)..."
                Restart-BcContainer -containerName $parameters.ContainerName
                $cleanupDone = $false
                break
            }
            throw
        }

        if (($AppsToUnpublish -contains "All") -or ($AppsToUnpublish -contains $app.Name)) {
            Write-Host "Unpublishing $($app.Name)"
            Unpublish-BcContainerApp -containerName $parameters.ContainerName -name $app.Name -unInstall -doNotSaveData -doNotSaveSchema -force
        }
    }
}

Write-Host "Current installed apps in container $($parameters.ContainerName)"
foreach ($app in (Get-BcContainerAppInfo -containerName $parameters.ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - IsInstalled: $($app.IsInstalled) - IsPublished: $($app.IsPublished)"
}

Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock { $progressPreference = 'SilentlyContinue' }