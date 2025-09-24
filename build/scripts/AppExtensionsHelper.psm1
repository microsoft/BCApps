function Update-VersionInAppJson {
    param (
        [string]$Path,
        [string]$CurrentVersion,
        [string]$MinimumVersion,
        [string]$PlatformVersion
    )
    $appJsonFiles = Get-ChildItem -Path $Path -Filter app.json -Recurse
    foreach ($appJsonFile in $appJsonFiles) {
        $appJson = Get-Content $appJsonFile.FullName | ConvertFrom-Json
        $appJson.version = $CurrentVersion
        foreach ($dependency in $appJson.dependencies) {
            $dependency.version = $MinimumVersion
        }
        if ($null -ne $appJson.application) {
            $appJson.application = $MinimumVersion
        }
        if ($null -ne $appJson.platform) {
            $appJson.platform = $PlatformVersion
        }
        $appJson | ConvertTo-Json -Depth 10 | Set-Content $appJsonFile.FullName
    }
    Write-Host "Updated app.json files in $Path with version $CurrentVersion, minimum version $MinimumVersion, and platform version $PlatformVersion"
}

function GetSourceCodeFromArtifact() {
    param(
        [string] $AppName,
        [string] $TempFolder
    )
    $sourceArchive = Get-ChildItem -Path $TempFolder -Recurse -Filter "$AppName.Source.zip" -ErrorAction SilentlyContinue
    $sourceCodeFolder = "$TempFolder/$($AppName -replace " ", "_")Source"
    # Return source code folder if it exists
    if (Test-Path $sourceCodeFolder) {
        Write-Host "Source code folder already exists: $sourceCodeFolder"
        return $sourceCodeFolder
    }

    if (-not $sourceArchive) {
        # Find out which version of the apps we need
        if ($env:artifact) {
            Write-Host "Found artifact: $($env:artifact)"
            $artifact = $env:artifact
        } else {
            Write-Host "No artifact found. Using default artifact version."
            Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
            $artifact = Get-ConfigValue -ConfigType "AL-GO" -Key "artifact"
        }
        # Test that artifact is a url
        if ($artifact -notmatch "^https?://") {
            Write-Error "Artifact is not a valid URL: $artifact"
            throw
        }

        $artifactVersion = $artifact -replace "/[^/]+$", "/w1"

        # Download the artifact that contains the source code for those apps
        Download-Artifacts -artifactUrl $artifactVersion -basePath $TempFolder -includePlatform | Out-Null

        # Unzip it
        $sourceArchive = Get-ChildItem -Path $TempFolder -Recurse -Filter "$AppName.Source.zip"
    }

    $sourceArchive | Expand-Archive -Destination $sourceCodeFolder

    if (-not (Test-Path $sourceCodeFolder)) {
        Write-Error "Could not find the source code for $AppName"
        throw
    }

    # Find Directory.App.Props.json in the source code folder and copy to the parent folder
    $directoryAppPropsPath = Get-ChildItem -Path $sourceCodeFolder -Filter "Directory.App.Props.json" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $directoryAppPropsPath) {
        throw "Could not find Directory.App.Props.json in the source code for $AppName"
    }
    $directoryAppProps = Get-Content -Path $directoryAppPropsPath.FullName | ConvertFrom-Json
    Update-VersionInAppJson -Path $sourceCodeFolder `
                             -CurrentVersion $directoryAppProps.variables.app_currentVersion `
                             -MinimumVersion $directoryAppProps.variables.app_minimumVersion `
                             -PlatformVersion $directoryAppProps.variables.app_platformVersion

    return $sourceCodeFolder
}

<#
    .Synopsis
        Build an app from source code and place it in the symbols folder for the app.
    .Description
        This function will build an app from source code and place it in the symbols folder for the app.
        The source code is downloaded from the artifact and the app is built with the same parameters as the main app.
    .Parameter App
        The name of the app to build.
    .Parameter CompilationParameters
        The parameters to use for the compilation of the app. This should be the same as the parameters used for the main app.
#>
function Build-App() {
    param(
        [string] $AppName,
        [hashtable] $CompilationParameters
    )
    # Set up temp folder if not already set
    if ($null -eq $script:tempFolder) {
        $script:tempFolder = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
    }

    # Log what is in the symbols folder
    Write-Host "Symbols folder: $($CompilationParameters['appSymbolsFolder'])"
    Get-ChildItem -Path $CompilationParameters["appSymbolsFolder"] | ForEach-Object {
        Write-Host "- $($_.Name)"
    }

    # If app is already there then skip it
    if (Test-Path $CompilationParameters["appOutputFolder"]) {
        $appSymbolsExist = Get-ChildItem -Path $CompilationParameters["appOutputFolder"] | Where-Object { $_.Name -like "Microsoft_$($AppName)*.app" }
        if ($appSymbolsExist) {
            Write-Host "$AppName is already in the symbols folder. Skipping recompilation"
            return
        }
    }


    $alGoSettings = $env:settings | ConvertFrom-Json
    $sourceCodeFolder = $null
    # If we are using project dependencies we will try to find the source code within the repository
    if ($alGoSettings.useProjectDependencies) {
        Write-Host "Get source code for $AppName"
        Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
        $sourceCodeFolder = Get-ChildItem -Path (Get-BaseFolder) -Filter "app.json" -Recurse | ForEach-Object {
            $appJsonName = (Get-Content -Path $_.FullName | ConvertFrom-Json).Name
            if ($appJsonName -eq $AppName) {
                $sourceCodeFolder = Split-Path $_.FullName -Parent
                Write-Host "Found code for $AppName in $sourceCodeFolder"
                return $sourceCodeFolder
            }
        }
    }

    # If we didn't find the source code in the repository, we will try to get it from the artifact
    if (-not $sourceCodeFolder) {
        $sourceCodeFolder = GetSourceCodeFromArtifact -AppName $AppName -TempFolder $script:tempFolder
    }

    # Update the CompilationParameters
    $CompilationParameters["appProjectFolder"] = $sourceCodeFolder # Use the downloaded source code as the project folder

    # Disable all cops for dependencies
    $CompilationParameters["EnableAppSourceCop"] = $false
    $CompilationParameters["EnableCodeCop"] = $false
    $CompilationParameters["EnableUICop"] = $false
    $CompilationParameters["EnablePerTenantExtensionCop"] = $false
    $CompilationParameters["GenerateReportLayout"] = "No"
    $CompilationParameters.Remove("ruleset")

    Write-Host "Recompile $AppName with parameters"
    foreach ($key in $CompilationParameters.Keys) {
        Write-Host "$key : $($CompilationParameters[$key])"
    }

    Compile-AppWithBcCompilerFolder @CompilationParameters
}

<#
    .Synopsis
        Publish and install an app from a file.
    .Description
        This function will publish and install an app from a file.
    .Parameter ContainerName
        The name of the container to publish the app in.
    .Parameter AppFilePath
        The path to the app file to publish.
    .Parameter AppName
        The name of the app to publish. If this is specified, the function will search for the app file with this name.
#>
function Install-AppFromFile() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ContainerName,
        [Parameter(Mandatory = $true, ParameterSetName = "ByAppFilePath")]
        [string] $AppFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = "ByAppName")]
        [string] $AppName
    )
    if ($PSCmdlet.ParameterSetName -eq "ByAppName") {
        Write-Host "[Install App from file] - Searching for app file with name: $AppName"
        # Looking for app files under the Applications folder on the container
        $allApps = (Invoke-ScriptInBCContainer -containerName $ContainerName -scriptblock { Get-ChildItem -Path "C:\Applications\" -Filter "*.app" -Recurse })

        # Find the app file by looking for an app file with the base name "Microsoft_AppName"
        $AppFilePath = $allApps | Where-Object { $($_.BaseName) -eq "Microsoft_$($AppName)" } | ForEach-Object { $_.FullName }
    }

    if (-not $AppFilePath) {
        throw "[Install App from file] - App file not found"
    }

    Write-Host "[Install App from file] - $AppFilePath"
    Publish-BcContainerApp -containerName $ContainerName -appFile ":$($AppFilePath)" -skipVerification -scope Global -install -sync
}

<#
    .Synopsis
        Install Container App
    .Description
        This function will Install Container App
    .Parameter ContainerName
        The name of the container to install the dependencies in.
    .Parameter DependenciesToInstall
        The list of dependencies to install.
#>
function Install-AppFromContainer() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ContainerName,
        [Parameter(Mandatory = $true)]
        [string[]] $AppsToInstall
    )
    $allAppsInEnvironment = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst
    $missingDependencies = @()
    foreach($dependency in $AppsToInstall) {
        $appInContainer = $allAppsInEnvironment | Where-Object Name -eq $dependency
        if (-not $appInContainer) {
            Write-Host "[Install Container App] - $($dependency) is not published to the container"
            $missingDependencies += $dependency
            continue
        }

        $isAppInstalled = $appInContainer | Where-Object IsInstalled -eq $true
        if ($isAppInstalled) {
            Write-Host "[Install Container App] - $($dependency) ($($isAppInstalled.Version)) is already installed"
            continue
        }

        $uninstalledApps = @($appInContainer | Where-Object IsInstalled -eq $false)
        if ($uninstalledApps.Count -gt 1) {
            throw "[Install Container App] - $($dependency) has multiple versions published. Cannot determine which one to install"
        }

        $appToInstall = $uninstalledApps[0]
        Write-Host "[Install Container App] - Installing $($dependency)"
        try {
            Sync-BcContainerApp -containerName $ContainerName -appName $appToInstall.Name -appPublisher $appToInstall.Publisher -Mode ForceSync -Force
            Install-BcContainerApp -containerName $ContainerName -appName $appToInstall.Name -appPublisher $appToInstall.Publisher -appVersion $appToInstall.Version -Force
        } catch {
            Write-Host "[Install Container App] - Failed to install $($dependency) ($($appToInstall.Version))"
            Write-Host $_.Exception.Message
            $missingDependencies += $dependency
            continue
        }
    }

    if ($missingDependencies.Count -gt 0) {
        Write-Host "[Install Container App] - The following dependencies are missing: $($missingDependencies -join ', ')"
    }
    return $missingDependencies
}

<#
    .Synopsis
        Get the external dependencies from the settings.json file.
    .Description
        This function will get the external dependencies from the settings.json file.
    .Parameter AppDependencies
        If this switch is set, only the app dependencies will be returned.
    .Parameter TestAppDependencies
        If this switch is set, only the test app dependencies will be returned.
#>
function Get-ExternalDependencies() {
    param(
        [switch] $AppDependencies,
        [switch] $TestAppDependencies
    )
    Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
    $appExtensionsSettings = Join-Path (Get-BaseFolder) "build/projects/Apps (W1)/.AL-Go/customSettings.json" -Resolve
    $customSettings = Get-Content -Path $appExtensionsSettings | ConvertFrom-Json

    if ($AppDependencies) {
        return $customSettings.ExternalAppDependencies
    } elseif ($TestAppDependencies) {
        return $customSettings.ExternalTestAppDependencies
    } else {
        return $customSettings.ExternalAppDependencies + $customSettings.ExternalTestAppDependencies
    }
}

Export-ModuleMember -Function *-*
