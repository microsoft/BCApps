<#
.SYNOPSIS
    Pipeline initialization override for Test Apps project.
    
.DESCRIPTION
    This override filters out country-specific test apps from the pipeline.
    
    CRITICAL TIMING:
    This script runs at the VERY START of Run-AlPipeline, BEFORE parameters
    are processed (converted from strings to arrays). Since it runs via 
    Invoke-Command -ScriptBlock within Run-AlPipeline, it has access to the
    function's scope variables.
    
    We modify the $script:installTestApps variable directly to filter out
    country-specific apps BEFORE the pipeline processes them.
    
    For the Test Apps project, we only want to run tests from:
    - System Application Partner Tests (local test folder)
    - Any W1 (non-country-specific) test apps from dependencies
    
    Country-specific test apps should NOT be installed or tested because:
    1. They are designed for specific country containers
    2. They may have dependencies that don't exist in the W1 container
    3. The Test Apps project only tests W1 functionality
#>

# Load country-specific app names from generated list
$countryAppsFile = Join-Path $PSScriptRoot "CountrySpecificApps.txt"
$countrySpecificApps = @()
if (Test-Path $countryAppsFile) {
    $countrySpecificApps = Get-Content $countryAppsFile | Where-Object { $_.Trim() -ne "" }
    Write-Host "PipelineInitialize: Loaded $($countrySpecificApps.Count) country-specific app names from exclusion list"
} else {
    Write-Warning "PipelineInitialize: Country-specific apps list not found at: $countryAppsFile"
    Write-Warning "PipelineInitialize: Run build/scripts/GenerateCountryAppsList.ps1 to generate the list"
}

function Test-IsCountrySpecificApp {
    param([string]$appPath)
    
    if ([string]::IsNullOrWhiteSpace($appPath)) {
        return $false
    }
    
    $appName = [System.IO.Path]::GetFileNameWithoutExtension($appPath)
    
    foreach ($countryApp in $countrySpecificApps) {
        # App file names are like: Microsoft_<AppName>_<Version>.app
        if ($appName -like "Microsoft_${countryApp}_*") {
            return $true
        }
    }
    
    return $false
}

function Test-IsFromCountryProject {
    param([string]$appPath)
    
    if ([string]::IsNullOrWhiteSpace($appPath)) {
        return $false
    }
    
    # Check if the path contains a country project folder
    # W1 pattern:      build_projects_Apps-<branch>-
    # Country pattern: build_projects_Apps XX-<branch>-  (where XX is country code like AT, SE, etc.)
    # 
    # We detect country projects by looking for "build_projects_Apps <CountryCode>-" pattern
    # Country codes are 2 uppercase letters
    
    if ($appPath -match 'build_projects_Apps ([A-Z]{2})-') {
        return $true
    }
    
    return $false
}

function Get-AppNameFromPath {
    param([string]$appPath)
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($appPath)
    # App file names are like: Microsoft_<AppName>_<Version>.app
    # Extract just the app name (without publisher and version)
    if ($fileName -match '^Microsoft_(.+)_\d+\.\d+\.\d+\.\d+$') {
        return $matches[1]
    }
    return $fileName
}

function Remove-CountrySpecificAppsFromList {
    param(
        [string]$parameterName,
        $apps
    )
    
    if (-not $apps) {
        Write-Host "PipelineInitialize: $parameterName is null/empty, nothing to filter"
        return $apps
    }
    
    # Handle string vs array
    if ($apps -is [string]) {
        $appList = @($apps.Split(',').Trim() | Where-Object { $_ })
    } else {
        $appList = @($apps)
    }
    
    if ($appList.Count -eq 0) {
        Write-Host "PipelineInitialize: $parameterName is empty after parsing, nothing to filter"
        return $apps
    }
    
    $originalCount = $appList.Count
    
    # PHASE 1: Build a lookup of which apps have W1 versions
    # This helps us filter out country-built copies of W1 apps
    $appsWithW1Version = @{}
    foreach ($app in $appList) {
        $appPath = $app
        if ($app -is [string]) {
            $appPath = $app.TrimStart("(").TrimEnd(")")
        }
        
        if (-not (Test-IsFromCountryProject -appPath $appPath)) {
            # This is from W1 (Apps project, not Apps XX project)
            $appName = Get-AppNameFromPath -appPath $appPath
            $appsWithW1Version[$appName] = $true
        }
    }
    
    Write-Host "PipelineInitialize: Found $($appsWithW1Version.Count) apps with W1 versions"
    
    # PHASE 2: Filter the list
    $filteredApps = @()
    $removedCountrySpecific = 0
    $removedCountryBuiltDuplicates = 0
    
    foreach ($app in $appList) {
        # Handle apps wrapped in parentheses (meaning "install but don't run tests")
        $appPath = $app
        if ($app -is [string]) {
            $appPath = $app.TrimStart("(").TrimEnd(")")
        }
        
        # Check 1: Is this a country-specific app (from CountrySpecificApps.txt)?
        if (Test-IsCountrySpecificApp -appPath $appPath) {
            Write-Host "  - Filtering country-specific app: $([System.IO.Path]::GetFileName($appPath))"
            $removedCountrySpecific++
            continue
        }
        
        # Check 2: Is this a W1 app built by a country project, when we have the W1-built version?
        if (Test-IsFromCountryProject -appPath $appPath) {
            $appName = Get-AppNameFromPath -appPath $appPath
            if ($appsWithW1Version.ContainsKey($appName)) {
                Write-Host "  - Filtering country-built duplicate: $([System.IO.Path]::GetFileName($appPath)) (W1 version exists)"
                $removedCountryBuiltDuplicates++
                continue
            }
        }
        
        # Keep this app
        $filteredApps += $app
    }
    
    if ($removedCountrySpecific -gt 0) {
        Write-Host "PipelineInitialize: Filtered $removedCountrySpecific country-specific apps from $parameterName"
    }
    if ($removedCountryBuiltDuplicates -gt 0) {
        Write-Host "PipelineInitialize: Filtered $removedCountryBuiltDuplicates country-built duplicates from $parameterName"
    }
    
    Write-Host "PipelineInitialize: $parameterName reduced from $originalCount to $($filteredApps.Count) apps"
    
    # Return in same format (string if input was string, array otherwise)
    if ($apps -is [string]) {
        return ($filteredApps -join ',')
    }
    return $filteredApps
}

# ============================================================================
# MAIN FILTERING LOGIC
# ============================================================================
# 
# This script runs via Invoke-Command -ScriptBlock within Run-AlPipeline.
# We use Set-Variable -Scope 1 to modify the parent scope's $installTestApps.
#
# Key variable we want to filter: $installTestApps
#
# At this point in Run-AlPipeline, $installTestApps is still the raw parameter
# value (could be string or array). The conversion to array happens AFTER
# PipelineInitialize runs.
# ============================================================================

Write-Host "============================================================================"
Write-Host "PipelineInitialize: Starting country-specific test apps filtering..."
Write-Host "============================================================================"

$found = $false
foreach ($scopeNum in 1..5) {
    try {
        $currentValue = Get-Variable -Name 'installTestApps' -ValueOnly -Scope $scopeNum -ErrorAction Stop
        if ($currentValue) {
            Write-Host "PipelineInitialize: Found installTestApps at Scope $scopeNum"
            Write-Host "  Type: $($currentValue.GetType().Name)"
            Write-Host "  Count: $(@($currentValue).Count)"
            
            $filteredValue = Remove-CountrySpecificAppsFromList -parameterName 'installTestApps' -apps $currentValue
            Set-Variable -Name 'installTestApps' -Value $filteredValue -Scope $scopeNum
            
            Write-Host "PipelineInitialize: Successfully updated installTestApps at Scope $scopeNum"
            $found = $true
            break
        }
    } catch {
        Write-Host "PipelineInitialize: Scope $scopeNum - $($_.Exception.Message)"
    }
}

if (-not $found) {
    Write-Host "PipelineInitialize: WARNING - Could not find installTestApps in any scope"
}

Write-Host "============================================================================"
