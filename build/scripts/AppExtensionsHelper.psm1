function GetSourceCodeFromArtifact() {
    param(
        [string] $App,
        [string] $TempFolder
    )
    $sourceArchive = Get-ChildItem -Path $TempFolder -Recurse -Filter "$App.Source.zip" -ErrorAction SilentlyContinue
    $sourceCodeFolder = "$TempFolder/$($App -replace " ", "_")Source"
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
        $sourceArchive = Get-ChildItem -Path $TempFolder -Recurse -Filter "$App.Source.zip"
    }

    $sourceArchive | Expand-Archive -Destination $sourceCodeFolder

    if (-not (Test-Path $sourceCodeFolder)) {
        Write-Error "Could not find the source code for $App"
        throw
    }

    return $sourceCodeFolder
}

function Get-AssemblyProbingPaths() {
    param(
        [string] $TargetDotnetVersion = "8"
    )
    # Check if the target .NET version is installed
    $DotNetSharedPath = "$env:ProgramFiles\dotnet\shared\Microsoft.AspNetCore.App\$TargetDotnetVersion.*"
    if(!(Test-Path $DotNetSharedPath)) {
        throw "Please install dotnet $TargetDotnetVersion SDK, path not found $DotNetSharedPath"
    }

    # Get the .NET latest minor version
    $versions = (Get-ChildItem "$DotNetSharedPath" -Name)
    $latestVersion = [version]"0.0.0"
    foreach ($currentVersion in $versions) {
        if ([version]$currentVersion -gt $latestVersion) {
            $latestVersion = [version]$currentVersion
        }
    }

    $assemblyProbingPaths = @()
    $assemblyProbingPaths += "$env:ProgramFiles\dotnet\shared\Microsoft.AspNetCore.App\$latestVersion"
    $assemblyProbingPaths += "$env:ProgramFiles\dotnet\shared\Microsoft.NETCore.App\$latestVersion"
    $assemblyProbingPaths += "$env:ProgramFiles\dotnet\shared\Microsoft.WindowsDesktop.App\$latestVersion"

    if (($null -ne $bcContainerHelperConfig)) {
        # Set the minimum .NET runtime version for the bccontainerhelper to avoid containerhelper injecting a newer version of the .NET runtime
        $bcContainerHelperConfig.MinimumDotNetRuntimeVersionStr = "99.0.0"
    }
    return $assemblyProbingPaths -join ","
}

<#
    .Synopsis
        Build a dependency app from source code and place it in the symbols folder for the app.
    .Description
        This function will build a dependency app from source code and place it in the symbols folder for the app.
        The source code is downloaded from the artifact and the app is built with the same parameters as the main app.
    .Parameter App
        The name of the app to build.
    .Parameter CompilationParameters
        The parameters to use for the compilation of the app. This should be the same as the parameters used for the main app.
#>
function Build-Dependency() {
    param(
        [string] $App,
        [hashtable] $CompilationParameters
    )
    # Set up temp folder if not already set
    if ($null -eq $script:tempFolder) {
        $script:tempFolder = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
    }

    # Create a new folder for the symbols if it does not exist
    $newSymbolsFolder = (Join-Path $script:tempFolder "Symbols")
    if (-not (Test-Path $newSymbolsFolder)) {
        New-Item -ItemType Directory -Path $newSymbolsFolder -Force | Out-Null
    }

    # Copy apps to packagecachepath
    $addOnsSymbolsFolder = $CompilationParameters["appSymbolsFolder"]

    # Log what is in the symbols folder
    Write-Host "Symbols folder: $addOnsSymbolsFolder"
    Get-ChildItem -Path $addOnsSymbolsFolder | ForEach-Object {
        Write-Host $_.Name
    }

    # If app is already there then skip it
    $appSymbolsExist = Get-ChildItem -Path $addOnsSymbolsFolder | Where-Object { $_.Name -like "Microsoft_$($App)*.app" }
    if ($appSymbolsExist) {
        Write-Host "$App is already in the symbols folder. Skipping recompilation"
        return
    }

    
    Write-Host "Get source code for $App"
    $sourceCodeFolder = GetSourceCodeFromArtifact -App $App -TempFolder $script:tempFolder

    $CompilationParameters["assemblyProbingPaths"] = Get-AssemblyProbingPaths

    # Update the CompilationParameters
    $CompilationParameters["appProjectFolder"] = $sourceCodeFolder # Use the downloaded source code as the project folder
    $CompilationParameters["appOutputFolder"] = $addOnsSymbolsFolder # Place the app directly in the symbols folder for Add-Ons
    $CompilationParameters["appSymbolsFolder"] = $newSymbolsFolder # New symbols folder only used for recompliation. Not used for compilation of Add-Ons

    # Disable all cops for dependencies
    $CompilationParameters["EnableAppSourceCop"] = $false
    $CompilationParameters["EnableCodeCop"] = $false
    $CompilationParameters["EnableUICop"] = $false
    $CompilationParameters["EnablePerTenantExtensionCop"] = $false
    $CompilationParameters.Remove("ruleset")

    Write-Host "Recompile $App with parameters"
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
        $allApps = (Invoke-ScriptInBCContainer -containerName $ContainerName -scriptblock { Get-ChildItem -Path "C:\Applications\" -Filter "*.app" -Recurse })
        $AppFilePath = $allApps | Where-Object { $($_.BaseName) -like "*$($AppName)" } | ForEach-Object { $_.FullName }
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
        [string[]] $DependenciesToInstall
    )
    $allAppsInEnvironment = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst
    $missingDependencies = @()
    foreach($dependency in $DependenciesToInstall) {
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
    $appExtensionsSettings = Join-Path (Get-BaseFolder) "build/projects/Add-Ons (W1)/.AL-Go/customSettings.json" -Resolve
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