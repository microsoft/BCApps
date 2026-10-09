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

if ($env:BC_SQL_PILOT_ARM) {
    & (Join-Path $PSScriptRoot 'SqlResetPilot\ContainerPreflight.ps1') -Parameters $parameters
}
New-BcContainer @parameters
if ($env:BC_SQL_PILOT_ARM) {
    $runtime = Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock {
        $commands = @('Get-NAVTenant', 'Dismount-NAVTenant', 'Mount-NAVTenant', 'Test-NAVDatabase', 'Copy-NAVDatabase', 'Remove-NAVDatabase')
        @{
            commands = @($commands | ForEach-Object {
                $command = Get-Command $_ -ErrorAction Stop
                @{ name = $command.Name; version = [string]$command.Version; parameters = @($command.Parameters.Keys) }
            })
            nst = @(Get-Process 'Microsoft.Dynamics.Nav.Server' | ForEach-Object {
                @{ pid = $_.Id; version = $_.FileVersion }
            })
        }
    }
    $runtime | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $env:BC_SQL_PILOT_OUTPUT 'runtime-preflight.json')
    if (@($runtime.nst).Count -ne 1 -or $runtime.nst[0].version -notmatch '^30\.0\.56092\.0(?:\s|$)') {
        throw 'Installed NST is not the predeclared 30.0.56092.0 runtime.'
    }
}

if ($parameters.auth -in @('UserPassword', 'NavUserPassword')) {
    if (-not $parameters.credential) {
        throw "The BCApps UserPassword test container requires a credential."
    }

    Import-Module (Join-Path $PSScriptRoot 'ApiTestCredential.psm1') -Force
    Write-ApiTestPassword -ContainerName $parameters.ContainerName -Credential $parameters.credential
}

Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName "EnforceUserPathForAlFileOperations" -keyValue "false"
Set-BcContainerServerConfiguration -containerName $parameters.ContainerName -keyName "UsePermissionSetsFromExtensions" -keyValue "true"
Restart-BcContainer -containerName $parameters.ContainerName

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