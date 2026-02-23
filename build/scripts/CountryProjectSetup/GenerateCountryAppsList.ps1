<#
.SYNOPSIS
    Generates a list of country-specific app names for use by the Test Apps project.

.DESCRIPTION
    This script scans all country-specific app folders (src/Apps/<XX> where XX is a 2-letter 
    country code like AT, MX, US, etc.) and extracts the app names from each app.json file.
    
    The generated list is used by the Test Apps project's PublishBcContainerApp.ps1 to exclude
    country-specific apps from being published to the W1 unit test container. This is necessary
    because country-specific apps depend on localized BaseApp namespaces that don't exist in W1.

    The script also validates that there are no naming conflicts between country-specific apps
    and W1 apps (which would indicate a potential problem).

.PARAMETER RepoRoot
    The root path of the BCAppsPrivate repository. Defaults to 3 levels up from the script location.

.PARAMETER OutputFile
    The output file path for the generated list. Defaults to:
    build/projects/Test Apps/.AL-Go/CountrySpecificApps.txt

.PARAMETER Validate
    Validates that CountrySpecificApps.txt is up to date without making changes.
    Returns $true if the file is correct, $false if updates are needed.
    Use this in CI/PR validation workflows.

.EXAMPLE
    # Run from anywhere with default paths
    .\GenerateCountryAppsList.ps1

.EXAMPLE
    # Run with explicit repo root
    .\GenerateCountryAppsList.ps1 -RepoRoot "C:\depot\BCAppsPrivate"

.EXAMPLE
    # Validate that the file is up to date (for CI)
    .\GenerateCountryAppsList.ps1 -Validate

.NOTES
    WHEN TO RUN THIS SCRIPT:
    - After adding a new country-specific app
    - After removing a country-specific app  
    - After renaming a country-specific app
    - When setting up a new branch that modifies country apps

    The generated CountrySpecificApps.txt file should be committed to source control.
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [string]$OutputFile = (Join-Path $PSScriptRoot "..\..\..\build\projects\Test Apps\.AL-Go\CountrySpecificApps.txt"),
    [switch]$Validate
)

$appsFolder = Join-Path $RepoRoot "src" "Apps"

# Get all country code folders (2-letter uppercase, excluding W1)
$countryFolders = Get-ChildItem -Path $appsFolder -Directory | Where-Object { $_.Name -match "^[A-Z]{2}$" -and $_.Name -ne "W1" }

Write-Host "Scanning country folders: $($countryFolders.Name -join ', ')"

# Collect country-specific app names
$countryApps = @()
foreach ($countryFolder in $countryFolders) {
    $appJsonFiles = Get-ChildItem -Path $countryFolder.FullName -Recurse -Filter "app.json"
    foreach ($appJson in $appJsonFiles) {
        $json = Get-Content $appJson.FullName -Raw | ConvertFrom-Json
        $countryApps += $json.name
        Write-Host "  $($countryFolder.Name): $($json.name)"
    }
}

# Get unique app names
$countryApps = $countryApps | Sort-Object -Unique

Write-Host "`nFound $($countryApps.Count) unique country-specific app names"

# Collect W1 app names for comparison
$w1Folder = Join-Path $appsFolder "W1"
$w1Apps = @()
if (Test-Path $w1Folder) {
    $w1AppJsonFiles = Get-ChildItem -Path $w1Folder -Recurse -Filter "app.json"
    foreach ($appJson in $w1AppJsonFiles) {
        $json = Get-Content $appJson.FullName -Raw | ConvertFrom-Json
        $w1Apps += $json.name
    }
    $w1Apps = $w1Apps | Sort-Object -Unique
    Write-Host "Found $($w1Apps.Count) unique W1 app names"
}

# Check for naming conflicts
$conflicts = $countryApps | Where-Object { $w1Apps -contains $_ }
if ($conflicts.Count -gt 0) {
    Write-Warning "Found naming conflicts between country and W1 apps:"
    foreach ($conflict in $conflicts) {
        Write-Warning "  - $conflict"
    }
    Write-Warning "These apps exist in both W1 and country folders - review needed!"
}

# Resolve output file path
$OutputFile = [System.IO.Path]::GetFullPath($OutputFile)

# Validation mode - compare with existing file
if ($Validate) {
    Write-Host ""
    if (-not (Test-Path $OutputFile)) {
        Write-Host "Validation FAILED: CountrySpecificApps.txt does not exist." -ForegroundColor Red
        Write-Host "Run 'GenerateCountryAppsList.ps1' to create it." -ForegroundColor Yellow
        return $false
    }
    
    $existingApps = Get-Content -Path $OutputFile | Where-Object { $_.Trim() -ne "" } | Sort-Object
    $newApps = $countryApps | Sort-Object
    
    $diff = Compare-Object -ReferenceObject $existingApps -DifferenceObject $newApps -PassThru
    
    if ($null -eq $diff -or $diff.Count -eq 0) {
        Write-Host "Validation PASSED: CountrySpecificApps.txt is up to date." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Validation FAILED: CountrySpecificApps.txt is out of date." -ForegroundColor Red
        
        $missing = $diff | Where-Object { $_.SideIndicator -eq "=>" }
        $extra = $diff | Where-Object { $_.SideIndicator -eq "<=" }
        
        if ($missing) {
            Write-Host "  Apps missing from file:" -ForegroundColor Yellow
            $missing | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
        }
        if ($extra) {
            Write-Host "  Apps in file but no longer exist:" -ForegroundColor Yellow
            $extra | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
        }
        
        Write-Host ""
        Write-Host "Run 'GenerateCountryAppsList.ps1' to fix." -ForegroundColor Yellow
        return $false
    }
}

# Write the output file
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$countryApps | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host "`nCountry-specific app names written to: $OutputFile"
Write-Host "Total apps: $($countryApps.Count)"
