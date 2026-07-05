<#
.SYNOPSIS
    Updates country project settings.json files with the correct app dependencies.
.DESCRIPTION
    This script uses ALAppBuild.psm1's BuildMetadataProvider to determine which apps
    (W1 and country-specific) are supported in each country, then updates each country's
    .AL-Go/settings.json with the correct appFolders and testFolders.

    App inclusion is determined by groups.json (via BuildMetadataProvider::GetApplicationsInGroup)
    and country support is checked via projects.json metadata (supportedCountries/unsupportedCountries),
    reusing the same data structures that the build system relies on.
.PARAMETER CountryCode
    Optional. If specified, only updates the settings for this country.
    If not specified, updates all country projects (including the W1 base
    project at eng/projects/Apps W1).

    For the W1 base project, both "W1" and "WW" are accepted (case-insensitive)
    and normalized to "W1" internally, which is the identifier used in
    groups.json and projects.json.
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
    .\Update-CountryProjectSettings.ps1 -CountryCode "W1"
    Updates only the W1 base project (eng/projects/Apps W1). "WW" is accepted
    as an alias.
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

    [switch]$Validate
)

# Track validation state
$script:validationPassed = $true
$script:countriesNeedingUpdate = @()

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "../Shared/EnlistmentHelperFunctions.psm1") -Force
$RepoRoot = Get-BaseFolder

$ErrorActionPreference = "Stop"

# Write-Log stub — ALAppBuild.psm1 uses Write-Log internally; provide a lightweight
# implementation so the module can be imported outside the full build environment.
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function global:Write-Log {
        param([Parameter(Position = 0)][string]$Message, [string]$ForegroundColor)
        Write-Host $Message
    }
}

$env:INETROOT = $RepoRoot
Import-Module (Join-Path (Join-Path $RepoRoot "eng") "CI" | Join-Path -ChildPath "ALAppBuild.psm1") -Force

# Apps that should be included in all country projects but aren't tracked in groups.json.
$AdditionalAppFolders = @(
    "../../../src/Layers/W1/DemoTool"
)

# Country code used for the W1 base project. Matches the identifier used in
# groups.json / projects.json (supportedCountries / unsupportedCountries).
$W1CountryCode = "W1"

$countryProjectsPath = Join-Path $RepoRoot "eng/projects"

function ConvertTo-NormalizedCountryCode {
    <#
    .SYNOPSIS
        Normalizes a user-supplied country code.
    .DESCRIPTION
        Accepts "W1", "w1", "WW", "ww" as aliases for the W1 base project and
        returns "W1" (the identifier used in groups.json / projects.json).
        All other inputs are upper-cased and returned as-is.
    #>
    param([string]$CountryCode)

    if ([string]::IsNullOrWhiteSpace($CountryCode)) { return $CountryCode }

    $upper = $CountryCode.ToUpperInvariant()
    if ($upper -eq "W1" -or $upper -eq "WW") { return $W1CountryCode }
    return $upper
}

function ConvertTo-SettingsRelativePath {
    <#
    .SYNOPSIS
        Converts an expanded build-system path to a settings.json relative path.
    .DESCRIPTION
        Maps absolute paths (e.g. C:\repo\src\System Application\App) to the
        relative paths used in AL-Go settings.json (e.g. ../../../src/System Application/App).
    #>
    param([string]$AbsolutePath)
    # Normalize both paths to forward slashes before comparison so that
    # Split-Path back-slash normalization doesn't break the replacement.
    $normalizedRoot = $RepoRoot -replace '\\', '/'
    $normalizedPath = $AbsolutePath -replace '\\', '/'
    $path = $normalizedPath -replace [regex]::Escape("$normalizedRoot/"), ''
    return "../../../$path"
}

function Get-CountryCodes {
    $countryFolders = Get-ChildItem -Path $countryProjectsPath -Directory |
        Where-Object { $_.Name -match "^Apps (W1|[A-Z]{2})$" } |
        ForEach-Object {
            if ($_.Name -match "^Apps (W1|[A-Z]{2})$") { $Matches[1] }
        }

    return $countryFolders | Sort-Object -Unique
}

function Get-AppFoldersForCountry {
    param([string]$Country)

    # Use ALAppBuild's Get-ApplicationGroup to get all apps for this country.
    # This handles group membership filtering, country support checks, and
    # language pack exclusion using the same logic as the build system.
    $allApps = Get-ApplicationGroup -GroupName "All" -CountryCode $Country -SkipLanguagePacks

    # Apps that PublishBcContainerApp.ps1 refuses to publish to the container.
    # If these end up in testFolders, the test runner's post-test verification
    # fails because they were never installed. Exclude them from testFolders
    # and treat them as regular appFolders instead.
    $appsNotPublished = @(
        "Library-NoTransactions",
        "Prevent Metadata Updates"
    )

    $appFolders = @()
    $testFolders = @()

    foreach ($metadata in $allApps) {
        if ($metadata.IsInternal) { continue }

        # For GDL projects use AppJsonPath's parent (ProjectFolder points to the generated dir)
        if ($metadata.IsGDLProject) {
            $sourcePath = Split-Path $metadata.AppJsonPath -Parent
        } else {
            $sourcePath = $metadata.ProjectFolder
        }

        # Skip apps whose source folder doesn't exist on disk
        if (-not (Test-Path $sourcePath)) { continue }

        $relativePath = ConvertTo-SettingsRelativePath $sourcePath

        if ($metadata.IsTest -and $metadata.ApplicationName -notin $appsNotPublished) {
            $testFolders += $relativePath
        } else {
            $appFolders += $relativePath
        }
    }

    # Merge in additional app folders not tracked in groups.json
    $appFolders += $script:AdditionalAppFolders

    return @{
        AppFolders  = $appFolders | Sort-Object -Unique
        TestFolders = $testFolders | Sort-Object -Unique
    }
}

function Update-CountrySettings {
    param([string]$Country)

    $settingsPath = Join-Path (Join-Path (Join-Path $countryProjectsPath "Apps $Country") ".AL-Go") "settings.json"

    if (-not (Test-Path $settingsPath)) {
        Write-Warning "Settings file not found for $Country : $settingsPath"
        return
    }

    Write-Host "Processing $Country..." -ForegroundColor Cyan

    # Read current settings
    $settingsContent = Get-Content -Path $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json

    # Get all apps for this country from ALAppBuild metadata
    $apps = Get-AppFoldersForCountry -Country $Country

    $currentAppFolders = @($settings.appFolders)
    $currentTestFolders = @($settings.testFolders)

    $newAppFolders = $apps.AppFolders
    $newTestFolders = $apps.TestFolders

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

        $newContent = $settings | ConvertTo-Json -Depth 10

        try {
            $null = $newContent | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Error "Generated invalid JSON for $Country : $_"
            return
        }

        Set-Content -Path $settingsPath -Value $newContent -Encoding UTF8

        Write-Host "  Updated $Country settings.json" -ForegroundColor Green
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Country Project Settings Updater" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get countries to process
if ($CountryCode) {
    $CountryCode = ConvertTo-NormalizedCountryCode $CountryCode
    $countries = @($CountryCode)
    Write-Host "Processing single country: $CountryCode" -ForegroundColor Gray
} else {
    $countries = Get-CountryCodes
    Write-Host "Found $($countries.Count) country projects to update" -ForegroundColor Gray
}

Write-Host ""

# Process each country
foreach ($country in $countries) {
    Update-CountrySettings -Country $country
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
