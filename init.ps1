<#
.SYNOPSIS
    BCApps enlistment initialization script.

.DESCRIPTION
    Loads shared utilities and developer tool modules into the current session.
    Modules under eng/Shared and eng/DevTools are auto-discovered.
    Sets $repoRoot to the repository root for use by downstream scripts.

    Output is suppressed when the CI environment variable is set (e.g. in
    GitHub Actions).

.EXAMPLE
    . .\init.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot

if ($env:CI -ne 'true') {
    Write-Host "Initializing BCApps enlistment..." -ForegroundColor Cyan
}

# Load shared utilities first (dependencies for DevTools)
$sharedRoot = Join-Path $repoRoot "eng/Shared"
$sharedModules = Get-ChildItem -Path $sharedRoot -Filter "*.psm1" -Recurse
foreach ($module in $sharedModules) {
    Import-Module $module.FullName -DisableNameChecking -Global
}

# Load developer tools
$devToolsRoot = Join-Path $repoRoot "eng/DevTools"
$devToolsModules = Get-ChildItem -Path $devToolsRoot -Filter "*.psm1" -Recurse
foreach ($module in $devToolsModules) {
    Import-Module $module.FullName -DisableNameChecking -Global
}

if ($env:CI -ne 'true') {
    $totalModules = $sharedModules.Count + $devToolsModules.Count
    Write-Host "BCApps enlistment initialized. Loaded $totalModules module(s)." -ForegroundColor Green
    Write-Host "Run 'Get-Command -Module <module>' or 'Get-Help <command>' for usage information." -ForegroundColor Gray
}
