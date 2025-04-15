function GetSourceCode() {
    param(
        [string] $App,
        [string] $TempFolder
    )
    $sourceArchive = Get-ChildItem -Path $TempFolder -Recurse -Filter "$App.Source.zip" -ErrorAction SilentlyContinue
    $sourceCodeFolder = "$TempFolder/$($App -replace " ", "_")Source"

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

    Write-Host "Get source code for $App"
    $sourceCodeFolder = GetSourceCode -App $App -TempFolder $script:tempFolder

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

function Install-UninstalledAppsInEnvironment() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ContainerName
    )
    # Get all apps in the environment
    $allAppsInEnvironment = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst
    foreach ($app in $allAppsInEnvironment) {
        # Check if the app is already installed 
        $isAppAlreadyInstalled = $allAppsInEnvironment | Where-Object { ($($_.Name) -eq $app.Name) -and ($_.IsInstalled -eq $true) }
        if (($app.IsInstalled -eq $true) -or ($isAppAlreadyInstalled)) {
            Write-Host "$($app.Name) is already installed"
        } else {
            Write-Host "Re-Installing $($app.Name)"
            Sync-BcContainerApp -containerName $ContainerName -appName $app.Name -appPublisher $app.Publisher -Mode ForceSync -Force
            Install-BcContainerApp -containerName $ContainerName -appName $app.Name -appPublisher $app.Publisher -appVersion $app.Version -Force
        }
    }

    foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
        Write-Verbose "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - $($app.IsInstalled) / $($app.IsPublished)"
    }
}

function Publish-AppFromFile() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ContainerName,
        [Parameter(Mandatory = $true, ParameterSetName = "ByAppFilePath")]
        [string] $AppFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = "ByAppName")]
        [string] $AppName
    )
    if ($PSCmdlet.ParameterSetName -eq "ByAppName") {
        Write-Host "Searching for app file with name: $AppName"
        $allApps = (Invoke-ScriptInBCContainer -containerName $ContainerName -scriptblock { Get-ChildItem -Path "C:\Applications\" -Filter "*.app" -Recurse })
        $AppFilePath = $allApps | Where-Object { $($_.BaseName) -like "*$($AppName)" } | ForEach-Object { $_.FullName }
    }
    
    if (-not $AppFilePath) {
        throw "App file not found"
    }

    Write-Host "Installing app from file: $AppFilePath"
    Publish-BcContainerApp -containerName $ContainerName -appFile ":$($AppFilePath)" -skipVerification -scope Global -install -sync
}

function Install-MissingDependencies() {
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
            Write-Host "[Install Missing Dependencies] - $($dependency) is not published to the container"
            $missingDependencies += $dependency
            continue
        }

        $isAppInstalled = $appInContainer | Where-Object IsInstalled -eq $true
        if ($isAppInstalled) {
            Write-Host "[Install Missing Dependencies] - $($dependency) ($($isAppInstalled.Version)) is already installed"
            continue
        }
        
        $uninstalledApps = @($appInContainer | Where-Object IsInstalled -eq $false)
        if ($uninstalledApps.Count -gt 1) {
            throw "[Install Missing Dependencies] - $($dependency) has multiple versions published. Cannot determine which one to install"
        }

        $appToInstall = $uninstalledApps[0]
        Write-Host "[Install Missing Dependencies] - Installing $($dependency)"
        try {
            Sync-BcContainerApp -containerName $ContainerName -appName $appToInstall.Name -appPublisher $appToInstall.Publisher -Mode ForceSync -Force
            Install-BcContainerApp -containerName $ContainerName -appName $appToInstall.Name -appPublisher $appToInstall.Publisher -appVersion $appToInstall.Version -Force
        } catch {
            Write-Host "[Install Missing Dependencies] - Failed to install $($dependency) ($($appToInstall.Version))"
            Write-Host $_.Exception.Message
            $missingDependencies += $dependency
            continue
        }
    }

    if ($missingDependencies.Count -gt 0) {
        Write-Host "[Install Missing Dependencies] - The following dependencies are missing: $($missingDependencies -join ', ')"
    }
    return $missingDependencies
}

function Install-AppsInContainer() {
    param(
        [string] $ContainerName,
        [string[]] $Apps
    )
    $allAppsInEnvironment = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst
    foreach ($app in $Apps) {
        # Check if app can be found in the container
        $appInContainer = $allAppsInEnvironment | Where-Object { ($($_.Name) -eq $app) }

        if (-not $appInContainer) {
            Write-Host "App $($app) not found in the container. Cannot install it until it is published."
            return $false
        } elseif ($appInContainer.IsInstalled -eq $true) {
            Write-Host "$($app) is already installed"
            return $true
        } else {
            Write-Host "Installing $appInContainer from container $ContainerName"
            Sync-BcContainerApp -containerName $ContainerName -appName $appInContainer.Name -appPublisher $appInContainer.Publisher -Mode ForceSync -Force
            Install-BcContainerApp -containerName $ContainerName -appName $appInContainer.Name -appPublisher $appInContainer.Publisher -appVersion $appInContainer.Version -Force
            return $true
        }
    }
}

Export-ModuleMember -Function Build-Dependency, Install-UninstalledAppsInEnvironment, Publish-AppFromFile, Install-MissingDependencies, Install-AppsInContainer