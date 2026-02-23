<#
.SYNOPSIS
    Gets the list of W1 apps that should be included for a specific country based on projects.json.
.DESCRIPTION
    This script reads the projects.json file and determines which W1 apps are supported for a given country
    based on the isMultiCountry, supportedCountries, and unsupportedCountries properties.
.PARAMETER CountryCode
    The country code to get supported apps for (e.g., "GB", "DE").
.PARAMETER ProjectsJsonPath
    Path to the projects.json file. Defaults to the build folder location.
.PARAMETER OutputFormat
    The output format: "List" for simple list, "Settings" for AL-Go settings.json format.
.PARAMETER IncludeTests
    Whether to include test apps in the output.
.EXAMPLE
    .\Get-W1AppsForCountry.ps1 -CountryCode "GB" -OutputFormat "Settings"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CountryCode,
    
    [string]$ProjectsJsonPath = (Join-Path $PSScriptRoot "..\projects.json"),
    
    [ValidateSet("List", "Settings")]
    [string]$OutputFormat = "List",
    
    [switch]$IncludeTests
)

function Test-AppSupportedInCountry {
    param(
        [PSCustomObject]$AppConfig,
        [string]$CountryCode
    )
    
    # If isMultiCountry is explicitly true, it's supported everywhere
    if ($AppConfig.isMultiCountry -eq $true) {
        return $true
    }
    
    # Check unsupportedCountries first (exclusion list)
    if ($AppConfig.unsupportedCountries) {
        $unsupported = @($AppConfig.unsupportedCountries) -split '\s+'
        if ($unsupported -contains $CountryCode) {
            return $false
        }
    }
    
    # Check supportedCountries (inclusion list)
    if ($AppConfig.supportedCountries) {
        $supported = @($AppConfig.supportedCountries) -split '\s+'
        
        # "All" means all countries
        if ($supported -contains "All") {
            return $true
        }
        
        return ($supported -contains $CountryCode)
    }
    
    # If no supportedCountries specified (null or empty), the app is supported in all countries
    # This matches the logic in ALAppBuild.psm1 GetApplicationGroup
    return $true
}

# Load projects.json
if (-not (Test-Path $ProjectsJsonPath)) {
    throw "projects.json not found at: $ProjectsJsonPath"
}

$projects = (Get-Content -Path $ProjectsJsonPath -Raw | ConvertFrom-Json).projects

# Find W1 apps
$w1Apps = @{
    'appFolders' = @()
    'testFolders' = @()
}

$projects.PSObject.Properties | ForEach-Object {
    $appName = $_.Name
    $config = $_.Value
    $path = $config.projectPath
    
    # Skip if not a W1 app - check both BCApps and internal repo paths
    # BCApps: src\Apps\W1 or src/Apps/W1
    # Internal: App\Apps\W1 or App/Apps/W1
    if ($path -notmatch 'Apps[\\\/]W1[\\\/]') {
        return
    }
    
    # Check if supported in country
    if (-not (Test-AppSupportedInCountry -AppConfig $config -CountryCode $CountryCode)) {
        Write-Verbose "Excluding $appName - not supported in $CountryCode"
        return
    }
    
    # Extract the app folder name and subfolder from the path
    # Handles both: 
    #   $env:INETROOT\App\BCApps\src\Apps\W1\<AppName>\<subfolder>
    #   $env:INETROOT\App\Apps\W1\<AppName>\<subfolder>
    if ($path -match 'Apps[\\\/]W1[\\\/]([^\\\/]+)[\\\/]?(.*)$') {
        $appFolderName = $Matches[1]
        $subFolder = $Matches[2] -replace '\\', '/'
        
        # Build the relative path for settings.json
        $settingsPath = "../../../src/Apps/W1/$appFolderName"
        if ($subFolder) {
            $settingsPath = "$settingsPath/$subFolder"
        }
        
        # Verify the folder exists in BCAppsPrivate
        $fullPath = Join-Path $PSScriptRoot "..\..\src\Apps\W1\$appFolderName" -Resolve -ErrorAction SilentlyContinue
        if (-not $fullPath) {
            Write-Verbose "Skipping $appName - folder not found in BCAppsPrivate: $appFolderName"
            return
        }
        
        if ($config.isTest) {
            if ($IncludeTests) {
                $w1Apps['testFolders'] += $settingsPath
            }
        } else {
            $w1Apps['appFolders'] += $settingsPath
        }
    }
}

# Output based on format
switch ($OutputFormat) {
    "List" {
        Write-Host "=== W1 Apps supported in $CountryCode ===" -ForegroundColor Cyan
        Write-Host "`nApp Folders ($($w1Apps['appFolders'].Count)):" -ForegroundColor Green
        $w1Apps['appFolders'] | Sort-Object | ForEach-Object { Write-Host "  $_" }
        
        if ($IncludeTests) {
            Write-Host "`nTest Folders ($($w1Apps['testFolders'].Count)):" -ForegroundColor Yellow
            $w1Apps['testFolders'] | Sort-Object | ForEach-Object { Write-Host "  $_" }
        }
    }
    "Settings" {
        Write-Host "// W1 app folders for $CountryCode (paste into settings.json appFolders)" -ForegroundColor Cyan
        $w1Apps['appFolders'] | Sort-Object | ForEach-Object { 
            Write-Host "    `"$_`","
        }
        
        if ($IncludeTests) {
            Write-Host "`n// W1 test folders for $CountryCode (paste into settings.json testFolders)" -ForegroundColor Yellow
            $w1Apps['testFolders'] | Sort-Object | ForEach-Object { 
                Write-Host "    `"$_`","
            }
        }
    }
}

# Return the data for programmatic use
return $w1Apps
