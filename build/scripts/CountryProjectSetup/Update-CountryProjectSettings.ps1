<#
.SYNOPSIS
    Updates country project settings.json files with the correct W1 app dependencies.
.DESCRIPTION
    This script reads projects.json to determine which W1 apps are supported in each country,
    then updates each country's .AL-Go/settings.json with the correct appFolders and testFolders.
    
    This ensures country projects include the W1 apps they depend on without manual maintenance.
.PARAMETER CountryCode
    Optional. If specified, only updates the settings for this country. 
    If not specified, updates all country projects.
.PARAMETER Validate
    Validates that all country settings are up to date without making changes.
    Returns $true if all settings are correct, $false if updates are needed.
    Use this in CI/PR validation workflows.
.PARAMETER WhatIf
    Shows what changes would be made without actually modifying files.
.PARAMETER Verbose
    Shows detailed output including which apps are added/removed.
.EXAMPLE
    .\Update-CountryProjectSettings.ps1
    Updates all country project settings.json files.
.EXAMPLE
    .\Update-CountryProjectSettings.ps1 -CountryCode "GB"
    Updates only the GB (Great Britain) project settings.
.EXAMPLE
    .\Update-CountryProjectSettings.ps1 -WhatIf
    Shows what changes would be made without modifying files.
.EXAMPLE
    .\Update-CountryProjectSettings.ps1 -Validate
    Validates all country settings are up to date. Returns $true/$false for CI.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CountryCode,
    
    [switch]$Validate,
    
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

# Track validation state
$script:validationPassed = $true
$script:countriesNeedingUpdate = @()

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$projectsJsonPath = Join-Path $RepoRoot "build\projects.json"
$countryProjectsPath = Join-Path $RepoRoot "build\projects"
$w1AppsPath = Join-Path $RepoRoot "src\Apps\W1"

# W1 paths that are always included for all countries (core dependencies)
$coreW1AppFolders = @(
    "../../../src/System Application/App",
    "../../../src/Business Foundation/App",
    "../../../src/Tools/AI Test Toolkit",
    "../../../src/Tools/Performance Toolkit/App",
    "../../../src/Tools/Test Framework/Test Libraries/*",
    "../../../src/Tools/Test Framework/Test Runner",
    "../../../src/Tools/Test Framework/Test Stability Tools/Prevent Metadata Updates",
    "../../../src/Layers/W1/Application",
    "../../../src/Layers/W1/BaseApp"
)

$coreW1TestFolders = @(
    "../../../src/System Application/Test Library",
    "../../../src/Business Foundation/Test Library",
    "../../../src/System Application/Test",
    "../../../src/Business Foundation/Test",
    "../../../src/Tools/Performance Toolkit/Test",
    "../../../src/Layers/W1/Tests/*"
)

# ============================================================================
# Functions
# ============================================================================

function Get-CountryCodes {
    # Get all country project folders (Apps XX pattern)
    $countryFolders = Get-ChildItem -Path $countryProjectsPath -Directory | 
        Where-Object { $_.Name -match "^Apps ([A-Z]{2})$" } |
        ForEach-Object { 
            if ($_.Name -match "^Apps ([A-Z]{2})$") { $Matches[1] }
        }
    return $countryFolders | Sort-Object
}

function Test-AppSupportedInCountry {
    param(
        [PSCustomObject]$AppConfig,
        [string]$Country
    )
    
    # If isMultiCountry is true, it's supported everywhere
    if ($AppConfig.isMultiCountry -eq $true) {
        return $true
    }
    
    # If supportedCountries is specified, check if country is in the list
    if ($null -ne $AppConfig.supportedCountries) {
        $countries = @($AppConfig.supportedCountries)
        if ($countries -contains "All") { return $true }
        return ($countries -contains $Country)
    }
    
    # If unsupportedCountries is specified, check if country is NOT in the list
    if ($null -ne $AppConfig.unsupportedCountries) {
        $unsupported = @($AppConfig.unsupportedCountries)
        return ($unsupported -notcontains $Country)
    }
    
    # Default: assume supported everywhere
    return $true
}

function Get-W1AppFoldersForCountry {
    param(
        [string]$Country,
        [PSCustomObject]$Projects
    )
    
    $appFolders = @()
    $testFolders = @()
    
    foreach ($prop in $Projects.PSObject.Properties) {
        $config = $prop.Value
        $path = $config.projectPath
        
        # Skip if not a W1 app
        if ($path -notmatch 'Apps[\\\/]W1[\\\/]') {
            continue
        }
        
        # Check if supported in this country
        if (-not (Test-AppSupportedInCountry -AppConfig $config -Country $Country)) {
            continue
        }
        
        # Extract app folder structure and build the relative path
        # Path format: $env:INETROOT\App\BCApps\src\Apps\W1\<AppName>\app
        if ($path -match 'Apps[\\\/]W1[\\\/](.+)$') {
            $appSubPath = $Matches[1] -replace '\$env:INETROOT\\App\\BCApps\\src\\', ''
            $appSubPath = $appSubPath -replace '\\', '/'
            
            # Handle common patterns
            $relativePath = "../../../src/Apps/W1/$appSubPath"
            
            if ($config.isTest -eq $true) {
                $testFolders += $relativePath
            } else {
                $appFolders += $relativePath
            }
        }
    }
    
    return @{
        AppFolders = $appFolders | Sort-Object -Unique
        TestFolders = $testFolders | Sort-Object -Unique
    }
}

function Update-CountrySettings {
    param(
        [string]$Country,
        [PSCustomObject]$Projects
    )
    
    $settingsPath = Join-Path $countryProjectsPath "Apps $Country\.AL-Go\settings.json"
    
    if (-not (Test-Path $settingsPath)) {
        Write-Warning "Settings file not found for $Country : $settingsPath"
        return
    }
    
    Write-Host "Processing $Country..." -ForegroundColor Cyan
    
    # Read current settings
    $settingsContent = Get-Content -Path $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json
    
    # Get W1 apps for this country
    $w1Apps = Get-W1AppFoldersForCountry -Country $Country -Projects $Projects
    
    # Build the complete appFolders list
    # Start with core W1 folders, add country-specific W1 apps, then country's own apps
    $currentAppFolders = @($settings.appFolders)
    $currentTestFolders = @($settings.testFolders)
    
    # Find country-specific folders (not W1)
    $countryAppFolders = $currentAppFolders | Where-Object { $_ -notmatch '/W1/' -and $_ -notmatch '/Layers/W1/' }
    $countryTestFolders = $currentTestFolders | Where-Object { $_ -notmatch '/W1/' -and $_ -notmatch '/Layers/W1/' }
    
    # Build new lists
    $newAppFolders = @()
    $newAppFolders += $coreW1AppFolders
    $newAppFolders += $w1Apps.AppFolders
    $newAppFolders += $countryAppFolders
    
    $newTestFolders = @()
    $newTestFolders += $coreW1TestFolders
    $newTestFolders += $w1Apps.TestFolders
    $newTestFolders += $countryTestFolders
    
    # Remove duplicates while preserving order
    $newAppFolders = $newAppFolders | Select-Object -Unique
    $newTestFolders = $newTestFolders | Select-Object -Unique
    
    # Check if changes are needed
    $appFoldersChanged = (Compare-Object $currentAppFolders $newAppFolders -SyncWindow 0) -ne $null
    $testFoldersChanged = (Compare-Object $currentTestFolders $newTestFolders -SyncWindow 0) -ne $null
    
    if (-not $appFoldersChanged -and -not $testFoldersChanged) {
        Write-Host "  No changes needed for $Country" -ForegroundColor Green
        return
    }
    
    # Track that this country needs updates
    $script:validationPassed = $false
    $script:countriesNeedingUpdate += $Country
    
    # Show changes
    $showDetails = $Validate -or ($WhatIfPreference -eq $true) -or ($VerbosePreference -eq 'Continue')
    
    if ($appFoldersChanged) {
        $added = $newAppFolders | Where-Object { $currentAppFolders -notcontains $_ }
        $removed = $currentAppFolders | Where-Object { $newAppFolders -notcontains $_ }
        if ($added) {
            Write-Host "  AppFolders to add: $($added.Count)" -ForegroundColor Yellow
            if ($showDetails) {
                $added | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
            }
        }
        if ($removed) {
            Write-Host "  AppFolders to remove: $($removed.Count)" -ForegroundColor Red
            if ($showDetails) {
                $removed | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
            }
        }
    }
    
    if ($testFoldersChanged) {
        $added = $newTestFolders | Where-Object { $currentTestFolders -notcontains $_ }
        $removed = $currentTestFolders | Where-Object { $newTestFolders -notcontains $_ }
        if ($added) {
            Write-Host "  TestFolders to add: $($added.Count)" -ForegroundColor Yellow
            if ($showDetails) {
                $added | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
            }
        }
        if ($removed) {
            Write-Host "  TestFolders to remove: $($removed.Count)" -ForegroundColor Red
            if ($showDetails) {
                $removed | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
            }
        }
    }
    
    # Apply changes (skip if validating)
    if (-not $Validate -and $PSCmdlet.ShouldProcess($settingsPath, "Update appFolders and testFolders")) {
        $settings.appFolders = $newAppFolders
        $settings.testFolders = $newTestFolders
        
        # Convert back to JSON with proper formatting
        $newContent = $settings | ConvertTo-Json -Depth 10
        
        # Preserve JSONC formatting (comments) if possible - just write the new content
        Set-Content -Path $settingsPath -Value $newContent -Encoding UTF8
        
        Write-Host "  Updated $Country settings.json" -ForegroundColor Green
    }
}

# ============================================================================
# Main
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Country Project Settings Updater" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Validate paths
if (-not (Test-Path $projectsJsonPath)) {
    throw "projects.json not found at: $projectsJsonPath"
}

# Load projects.json
Write-Host "Loading projects.json..." -ForegroundColor Gray
$projectsData = Get-Content -Path $projectsJsonPath -Raw | ConvertFrom-Json
$projects = $projectsData.projects

# Get countries to process
if ($CountryCode) {
    $countries = @($CountryCode)
    Write-Host "Processing single country: $CountryCode" -ForegroundColor Gray
} else {
    $countries = Get-CountryCodes
    Write-Host "Found $($countries.Count) country projects to update" -ForegroundColor Gray
}

Write-Host ""

# Process each country
foreach ($country in $countries) {
    Update-CountrySettings -Country $country -Projects $projects
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

# Handle validation result
if ($Validate) {
    if ($script:validationPassed) {
        Write-Host "Validation PASSED: All country settings are up to date." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Validation FAILED: The following countries need updates:" -ForegroundColor Red
        $script:countriesNeedingUpdate | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host ""
        Write-Host "Run 'Update-CountryProjectSettings.ps1' to fix." -ForegroundColor Yellow
        return $false
    }
} else {
    Write-Host "Done!" -ForegroundColor Green
}
