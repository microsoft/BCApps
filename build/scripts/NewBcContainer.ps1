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

if ($parameters.auth -in @('UserPassword', 'NavUserPassword')) {
    if (-not $parameters.credential) {
        throw "The BCApps UserPassword test container requires a credential."
    }

    $apiTestPasswordFile = 'C:\Run\my\ApiTestPassword'
    $apiTestPassword = $parameters.credential.GetNetworkCredential().Password
    $hostPasswordFile = Join-Path ([System.IO.Path]::GetTempPath()) "BCAppsApiTestPassword-$([Guid]::NewGuid().ToString('N'))"
    try {
        [System.IO.File]::WriteAllText($hostPasswordFile, $apiTestPassword)

        try {
            Copy-FileToBcContainer -containerName $parameters.ContainerName -localPath $hostPasswordFile -containerPath $apiTestPasswordFile
            Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -argumentList $apiTestPasswordFile -scriptblock {
                param(
                    [string]$FilePath
                )

                $fileSecurity = [System.Security.AccessControl.FileSecurity]::new()
                $fileSecurity.SetAccessRuleProtection($true, $false)
                foreach ($accessEntry in @(
                    @{ Sid = 'S-1-5-18'; Rights = [System.Security.AccessControl.FileSystemRights]::FullControl },
                    @{ Sid = 'S-1-5-20'; Rights = [System.Security.AccessControl.FileSystemRights]::Read },
                    @{ Sid = 'S-1-5-32-544'; Rights = [System.Security.AccessControl.FileSystemRights]::FullControl }
                )) {
                    $identity = [System.Security.Principal.SecurityIdentifier]::new($accessEntry.Sid)
                    $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new(
                        $identity,
                        $accessEntry.Rights,
                        [System.Security.AccessControl.AccessControlType]::Allow)
                    $fileSecurity.AddAccessRule($accessRule)
                }
                Set-Acl -LiteralPath $FilePath -AclObject $fileSecurity
            }
        }
        catch {
            $originalError = $_
            try {
                Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -argumentList $apiTestPasswordFile -scriptblock {
                    param(
                        [string]$FilePath
                    )

                    Remove-Item -LiteralPath $FilePath -Force -ErrorAction SilentlyContinue
                }
            }
            catch {
                Write-Warning "Could not remove the API test credential file after setup failed."
            }
            throw $originalError
        }
    }
    finally {
        Remove-Item -LiteralPath $hostPasswordFile -Force -ErrorAction SilentlyContinue
        Clear-Variable apiTestPassword -ErrorAction SilentlyContinue
    }
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