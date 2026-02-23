# Country Project Setup Scripts

This folder contains PowerShell scripts for setting up and maintaining country-specific build projects in BCAppsPrivate. These scripts help manage the relationship between W1 (World-Wide) apps and country-specific localizations.

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `Update-CountryProjectSettings.ps1` | Updates country project settings.json files with W1 dependencies |
| `GenerateCountryAppsList.ps1` | Generates list of country-specific app names for Test Apps filtering |
| `Get-W1AppsForCountry.ps1` | Shows which W1 apps are supported in a specific country |
| `PopulateW1Dependencies.psm1` | Module for creating symlinks to W1 apps (local dev) |

---

## Update-CountryProjectSettings.ps1

Updates each country's `.AL-Go/settings.json` with the correct `appFolders` and `testFolders` based on `projects.json` configuration.

### When to Use
- After adding new W1 apps that should be included in country builds
- After modifying `supportedCountries` or `unsupportedCountries` in `projects.json`
- When setting up a new country project
- To synchronize all country projects with the latest `projects.json`

### Parameters
| Parameter | Description |
|-----------|-------------|
| `-CountryCode` | Optional. Country code (e.g., "GB", "DE"). If omitted, updates all countries. |
| `-Validate` | Validates settings are up to date without modifying files. Returns `$true`/`$false`. |
| `-WhatIf` | Shows what changes would be made without modifying files. |

### Examples

```powershell
# Preview changes for all countries
.\Update-CountryProjectSettings.ps1 -WhatIf

# Preview changes for a specific country
.\Update-CountryProjectSettings.ps1 -CountryCode "GB" -WhatIf

# Update all country projects
.\Update-CountryProjectSettings.ps1

# Update only Great Britain
.\Update-CountryProjectSettings.ps1 -CountryCode "GB"

# Validate all countries are up to date (for CI/PR checks)
.\Update-CountryProjectSettings.ps1 -Validate
```

### Output
The script shows:
- AppFolders to add/remove
- TestFolders to add/remove
- Which settings.json files were updated

---

## GenerateCountryAppsList.ps1

Scans all country-specific app folders (`src/Apps/<XX>` where XX is a 2-letter country code) and generates a list of app names for use by the Test Apps project.

### When to Use
- After adding a new country-specific app
- After removing a country-specific app
- After renaming a country-specific app
- When setting up a new branch that modifies country apps

### Parameters
| Parameter | Description |
|-----------|-------------|
| `-RepoRoot` | Repository root path. Defaults to 3 levels up from script location. |
| `-OutputFile` | Output file path. Defaults to `build/projects/Test Apps/.AL-Go/CountrySpecificApps.txt` |
| `-Validate` | Validates the file is up to date without modifying it. Returns `$true`/`$false`. |

### Examples

```powershell
# Generate with default paths
.\GenerateCountryAppsList.ps1

# Generate with explicit repo root
.\GenerateCountryAppsList.ps1 -RepoRoot "C:\depot\BCAppsPrivate"

# Generate to a custom output file
.\GenerateCountryAppsList.ps1 -OutputFile "C:\temp\CountryApps.txt"

# Validate the file is up to date (for CI/PR checks)
.\GenerateCountryAppsList.ps1 -Validate
```

### Output
Creates `CountrySpecificApps.txt` containing one app name per line. This file is used by:
- `PipelineInitialize.ps1` to filter country-specific apps from `$installTestApps` and `$installApps`
- `PublishBcContainerApp.ps1` to prevent publishing country apps to W1 containers

**Note:** The generated file should be committed to source control.

---

## Get-W1AppsForCountry.ps1

Queries `projects.json` to determine which W1 apps are supported for a specific country, based on `isMultiCountry`, `supportedCountries`, and `unsupportedCountries` properties.

### When to Use
- To understand which W1 apps will be built for a country
- To debug country-specific build configurations
- To generate app lists for manual configuration

### Parameters
| Parameter | Description |
|-----------|-------------|
| `-CountryCode` | **Required.** Country code (e.g., "GB", "DE"). |
| `-OutputFormat` | "List" (default) or "Settings" for AL-Go settings.json format. |
| `-IncludeTests` | Include test apps in the output. |

### Examples

```powershell
# List W1 apps supported in Great Britain
.\Get-W1AppsForCountry.ps1 -CountryCode "GB"

# Get apps in AL-Go settings.json format
.\Get-W1AppsForCountry.ps1 -CountryCode "GB" -OutputFormat "Settings"

# Include test apps
.\Get-W1AppsForCountry.ps1 -CountryCode "DE" -IncludeTests
```

---

## PopulateW1Dependencies.psm1

PowerShell module providing functions to create symbolic links from a country's `W1Dependencies` folder to the actual W1 app sources. This is primarily useful for local development scenarios.

### Functions
| Function | Description |
|----------|-------------|
| `Test-AppSupportedInCountry` | Checks if an app is supported in a country |
| `Get-W1AppsForCountry` | Gets list of supported W1 apps for a country |
| `New-W1DependencyLinks` | Creates symlinks to W1 apps |

### When to Use
- Setting up a local development environment for country apps
- When you need to work on country-specific code that depends on W1 apps

### Examples

```powershell
# Import the module
Import-Module .\PopulateW1Dependencies.psm1

# Create symlinks for GB
New-W1DependencyLinks -CountryCode "GB" -RepoRoot "C:\depot\BCAppsPrivate"
```

---

## How It All Fits Together

1. **projects.json** is the source of truth for which apps exist and their country support
2. **GenerateCountryAppsList.ps1** creates `CountrySpecificApps.txt` for Test Apps filtering
3. **Update-CountryProjectSettings.ps1** updates country `settings.json` files with W1 dependencies
4. **Get-W1AppsForCountry.ps1** helps you inspect/debug the configuration
5. **PopulateW1Dependencies.psm1** helps with local dev setup

### Typical Workflow

```powershell
# 1. After modifying projects.json or adding country apps, regenerate the apps list
.\GenerateCountryAppsList.ps1

# 2. Update all country project settings
.\Update-CountryProjectSettings.ps1

# 3. Commit the changes
git add .
git commit -m "Update country project configurations"
```

---

## Related Files

| File | Location | Description |
|------|----------|-------------|
| `projects.json` | `build/projects.json` | Master configuration defining all projects and country support |
| `CountrySpecificApps.txt` | `build/projects/Test Apps/.AL-Go/CountrySpecificApps.txt` | Generated list of country-specific app names |
| `settings.json` | `build/projects/Apps <XX>/.AL-Go/settings.json` | Per-country AL-Go settings |
| `PipelineInitialize.ps1` | `build/projects/Test Apps/.AL-Go/PipelineInitialize.ps1` | Uses CountrySpecificApps.txt for filtering |
