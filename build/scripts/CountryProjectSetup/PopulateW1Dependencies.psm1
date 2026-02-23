<#
.SYNOPSIS
    Functions to populate W1 dependencies for country-specific builds based on projects.json.
.DESCRIPTION
    This module provides functions to determine which W1 apps are supported in a given country
    and create symbolic links to those apps in a country's W1Dependencies folder.
#>

# Logging helper
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $prefix = switch ($Level) {
        'Info'    { "[INFO]   " }
        'Warning' { "[WARN]   " }
        'Error'   { "[ERROR]  " }
        'Success' { "[OK]     " }
    }
    
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "$prefix$Message" -ForegroundColor $color
}

<#
.SYNOPSIS
    Determines if an app is supported in a given country based on projects.json configuration.
.PARAMETER AppConfig
    The configuration object for the app from projects.json.
.PARAMETER CountryCode
    The country code to check support for (e.g., "GB", "US").
.RETURNS
    $true if the app is supported in the country, $false otherwise.
#>
function Test-AppSupportedInCountry {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AppConfig,
        
        [Parameter(Mandatory = $true)]
        [string]$CountryCode
    )
    
    # If isMultiCountry is true, it's supported everywhere
    if ($AppConfig.isMultiCountry -eq $true) {
        return $true
    }
    
    # If supportedCountries is specified, check if country is in the list
    if ($null -ne $AppConfig.supportedCountries) {
        $countries = @($AppConfig.supportedCountries)
        
        # Handle "All" as a special value meaning all countries
        if ($countries -contains "All") {
            return $true
        }
        
        return ($countries -contains $CountryCode)
    }
    
    # If unsupportedCountries is specified, check if country is NOT in the list
    if ($null -ne $AppConfig.unsupportedCountries) {
        $unsupported = @($AppConfig.unsupportedCountries)
        return ($unsupported -notcontains $CountryCode)
    }
    
    # Default: if no country restrictions, assume supported everywhere
    return $true
}

<#
.SYNOPSIS
    Gets the list of W1 app folder names that are supported in a given country.
.PARAMETER ProjectsJsonPath
    Path to the projects.json file.
.PARAMETER CountryCode
    The country code to get supported apps for.
.PARAMETER W1AppsPath
    Path to the W1 apps folder to verify app folders exist.
.RETURNS
    Array of W1 app folder names that are supported in the country.
#>
function Get-SupportedW1Apps {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectsJsonPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CountryCode,
        
        [Parameter(Mandatory = $true)]
        [string]$W1AppsPath
    )
    
    $projects = (Get-Content -Path $ProjectsJsonPath -Raw | ConvertFrom-Json).projects
    
    # Build a lookup of W1 app folders to their projects.json configs
    # Key: folder name (lowercase for case-insensitive matching)
    # Value: array of configs that affect this folder
    $w1AppConfigs = @{}
    
    foreach ($prop in $projects.PSObject.Properties) {
        $config = $prop.Value
        $path = $config.projectPath
        
        # Skip if not a W1 app (check for Apps\W1 or Apps/W1 in path)
        if ($path -notmatch 'Apps[\\\/]W1[\\\/]') {
            continue
        }
        
        # Extract the app folder name from the path
        # Path format: $env:INETROOT\App\Apps\W1\<AppName>\app (or similar)
        if ($path -match 'Apps[\\\/]W1[\\\/]([^\\\/]+)') {
            $appFolderName = $Matches[1].ToLower()
            
            if (-not $w1AppConfigs.ContainsKey($appFolderName)) {
                $w1AppConfigs[$appFolderName] = @()
            }
            $w1AppConfigs[$appFolderName] += $config
        }
    }
    
    # Get all W1 app folders that exist in the repo
    $w1Folders = Get-ChildItem -Path $W1AppsPath -Directory | Select-Object -ExpandProperty Name
    $supportedApps = @()
    
    foreach ($folderName in $w1Folders) {
        $folderNameLower = $folderName.ToLower()
        $isSupported = $true
        
        # Check if there are any configs for this folder
        if ($w1AppConfigs.ContainsKey($folderNameLower)) {
            # Check each config - if ANY config excludes this country, exclude the app
            foreach ($config in $w1AppConfigs[$folderNameLower]) {
                if (-not (Test-AppSupportedInCountry -AppConfig $config -CountryCode $CountryCode)) {
                    $isSupported = $false
                    break
                }
            }
        }
        # If no configs found, assume it's a universal app (supported everywhere)
        
        if ($isSupported) {
            $supportedApps += $folderName
        }
    }
    
    return $supportedApps | Sort-Object
}

<#
.SYNOPSIS
    Creates symbolic links for W1 dependencies in a country's dependencies folder.
.PARAMETER CountryCode
    The country code (e.g., "GB").
.PARAMETER RepoRoot
    The root path of the repository.
.PARAMETER DependenciesFolderName
    Name of the dependencies folder (default: "W1Dependencies").
.PARAMETER Force
    If specified, recreates symlinks even if they exist.
#>
function New-W1DependencyLinks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CountryCode,
        
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        
        [string]$DependenciesFolderName = "W1Dependencies",
        
        [switch]$Force
    )
    
    Write-LogMessage "Starting W1 dependency population for country: $CountryCode" -Level Info
    
    $projectsJsonPath = Join-Path $RepoRoot "build\projects.json"
    $w1AppsPath = Join-Path $RepoRoot "src\Apps\W1"
    $countryAppsPath = Join-Path $RepoRoot "src\Apps\$CountryCode"
    $dependenciesPath = Join-Path $countryAppsPath $DependenciesFolderName
    
    Write-LogMessage "Repository root: $RepoRoot" -Level Info
    Write-LogMessage "Projects.json: $projectsJsonPath" -Level Info
    Write-LogMessage "W1 apps path: $w1AppsPath" -Level Info
    Write-LogMessage "Dependencies path: $dependenciesPath" -Level Info
    
    # Validate paths exist
    if (-not (Test-Path $projectsJsonPath)) {
        Write-LogMessage "projects.json not found at: $projectsJsonPath" -Level Error
        throw "projects.json not found at: $projectsJsonPath"
    }
    if (-not (Test-Path $w1AppsPath)) {
        Write-LogMessage "W1 apps folder not found at: $w1AppsPath" -Level Error
        throw "W1 apps folder not found at: $w1AppsPath"
    }
    if (-not (Test-Path $countryAppsPath)) {
        Write-LogMessage "Country apps folder not found at: $countryAppsPath" -Level Error
        throw "Country apps folder not found at: $countryAppsPath"
    }
    
    # Create dependencies folder if it doesn't exist
    if (-not (Test-Path $dependenciesPath)) {
        New-Item -Path $dependenciesPath -ItemType Directory -Force | Out-Null
        Write-LogMessage "Created dependencies folder: $dependenciesPath" -Level Success
    }
    
    # Clean existing symlinks if Force is specified
    if ($Force) {
        $existingLinks = Get-ChildItem -Path $dependenciesPath -Directory -ErrorAction SilentlyContinue | Where-Object { 
            $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint 
        }
        if ($existingLinks) {
            Write-LogMessage "Cleaning $($existingLinks.Count) existing symlinks (Force mode)" -Level Info
            $existingLinks | ForEach-Object {
                Remove-Item $_.FullName -Force
            }
        }
    }
    
    # Get all W1 folders for comparison
    $allW1Folders = Get-ChildItem -Path $w1AppsPath -Directory | Select-Object -ExpandProperty Name
    Write-LogMessage "Total W1 app folders in repo: $($allW1Folders.Count)" -Level Info
    
    # Get supported W1 apps for this country
    $supportedApps = Get-SupportedW1Apps -ProjectsJsonPath $projectsJsonPath -CountryCode $CountryCode -W1AppsPath $w1AppsPath
    
    # Calculate excluded apps
    $excludedApps = $allW1Folders | Where-Object { $supportedApps -notcontains $_ }
    
    Write-LogMessage "W1 apps supported in $CountryCode : $($supportedApps.Count)" -Level Success
    Write-LogMessage "W1 apps excluded from $CountryCode : $($excludedApps.Count)" -Level Warning
    
    if ($excludedApps.Count -gt 0) {
        Write-LogMessage "Excluded apps:" -Level Warning
        foreach ($app in $excludedApps) {
            Write-LogMessage "  - $app" -Level Warning
        }
    }
    
    # Create symbolic links
    $createdCount = 0
    $failedCount = 0
    
    Write-LogMessage "Creating symbolic links..." -Level Info
    foreach ($appName in $supportedApps) {
        $targetPath = Join-Path $w1AppsPath $appName
        $linkPath = Join-Path $dependenciesPath $appName
        
        if (-not (Test-Path $linkPath)) {
            # Create symbolic link (requires admin on Windows or Developer Mode enabled)
            try {
                New-Item -Path $linkPath -ItemType SymbolicLink -Value $targetPath -Force | Out-Null
                $createdCount++
            }
            catch {
                Write-LogMessage "Failed to create symlink for $appName, trying junction..." -Level Warning
                # Try junction as fallback (doesn't require admin)
                try {
                    cmd /c mklink /J "$linkPath" "$targetPath" 2>&1 | Out-Null
                    $createdCount++
                }
                catch {
                    Write-LogMessage "Failed to create junction for $appName : $_" -Level Error
                    $failedCount++
                }
            }
        }
    }
    
    Write-LogMessage "Created $createdCount symbolic links" -Level Success
    if ($failedCount -gt 0) {
        Write-LogMessage "Failed to create $failedCount links" -Level Error
    }
    
    # Verify the results
    $appFolders = Get-ChildItem -Path "$dependenciesPath\*\app" -Directory -ErrorAction SilentlyContinue
    $testFolders = Get-ChildItem -Path "$dependenciesPath\*\test" -Directory -ErrorAction SilentlyContinue
    $demoDataFolders = Get-ChildItem -Path "$dependenciesPath\*\Demo Data" -Directory -ErrorAction SilentlyContinue
    $nestedAppFolders = Get-ChildItem -Path "$dependenciesPath\*\*\app" -Directory -ErrorAction SilentlyContinue
    
    Write-LogMessage "=== Verification ===" -Level Info
    Write-LogMessage "App folders (*/app): $($appFolders.Count)" -Level Info
    Write-LogMessage "Test folders (*/test): $($testFolders.Count)" -Level Info
    Write-LogMessage "Demo Data folders (*/Demo Data): $($demoDataFolders.Count)" -Level Info
    Write-LogMessage "Nested app folders (*/*/app): $($nestedAppFolders.Count)" -Level Info
    
    Write-LogMessage "W1 dependencies population complete for $CountryCode" -Level Success
    return $supportedApps
}

Export-ModuleMember -Function Test-AppSupportedInCountry, Get-SupportedW1Apps, New-W1DependencyLinks, Write-LogMessage
