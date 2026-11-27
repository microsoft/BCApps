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
# API tests call the container's own web services through AL HttpClient, which anti-SSRF blocks for local addresses (same as NAV RunALTests.ps1).
Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName "NavHttpClientAntiSSRFEnabled" -keyValue "false"
$isUS = (Get-ALGoSetting -Key "country") -eq "US"
if ($isUS) {
    # Read the running server's values, including defaults, rather than just the configuration file.
    $readCompilationSettings = {
        $ErrorActionPreference = "Stop"
        $serverInstance = Get-NAVServerInstance
        $settings = [ordered]@{}
        foreach ($key in @("ClrRetrieverKind", "EnableMultithreadedCompilation")) {
            $setting = @($serverInstance | Get-NAVServerConfiguration -KeyName $key -InMemory)
            if ($setting.Count -ne 1 -or [string]::IsNullOrWhiteSpace($setting[0].Value)) {
                throw "Could not read the effective US compilation setting '$key'."
            }
            $settings[$key] = [string]$setting[0].Value
        }
        [PSCustomObject]$settings
    }
    & {
        $ErrorActionPreference = "Stop"
        $before = Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock $readCompilationSettings
        if ($null -eq $before) {
            throw "Could not read the effective US compilation settings before change."
        }
        Write-Host "US compilation settings before change: ClrRetrieverKind=$($before.ClrRetrieverKind); EnableMultithreadedCompilation=$($before.EnableMultithreadedCompilation)"
        Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName ClrRetrieverKind -keyValue OneApplicationMultipleAssemblies
        Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName EnableMultithreadedCompilation -keyValue true
    }
}
Restart-BcContainer -containerName $parameters.ContainerName

if ($isUS) {
    $after = Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock $readCompilationSettings
    if ($null -eq $after) {
        throw "Could not read the effective US compilation settings after restart."
    }
    Write-Host "US compilation settings after restart: ClrRetrieverKind=$($after.ClrRetrieverKind); EnableMultithreadedCompilation=$($after.EnableMultithreadedCompilation)"
    if ($after.ClrRetrieverKind -ne "OneApplicationMultipleAssemblies" -or $after.EnableMultithreadedCompilation -ne "true") {
        throw "US compilation settings mismatch after restart: expected ClrRetrieverKind=OneApplicationMultipleAssemblies; EnableMultithreadedCompilation=true."
    }
}

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