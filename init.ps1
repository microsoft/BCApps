<#
.SYNOPSIS
    BCApps enlistment initialization script.

.DESCRIPTION
    Loads shared utilities and developer tool modules into the current session.
    Modules under eng/Shared are always loaded. Modules under eng/DevTools are
    loaded when the -Dev switch is specified (default in interactive sessions,
    off in CI).

    Sets $repoRoot to the repository root for use by downstream scripts.

    Output is suppressed when the CI environment variable is set (e.g. in
    GitHub Actions).

.PARAMETER Dev
    Load developer tool modules (eng/DevTools). These require additional
    dependencies such as BCContainerHelper. Enabled by default in interactive
    sessions, disabled in CI.

.EXAMPLE
    . .\init.ps1
    # Interactive: loads Shared + DevTools

.EXAMPLE
    . .\init.ps1 -Dev
    # Explicitly load DevTools (e.g. in CI if needed)
#>

param(
    [switch]$Dev = ($env:CI -ne 'true')
)

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

# Load developer tools (requires BCContainerHelper and other local dependencies)
$devToolsModules = @()
if ($Dev) {
    $devToolsRoot = Join-Path $repoRoot "eng/DevTools"
    $devToolsModules = Get-ChildItem -Path $devToolsRoot -Filter "*.psm1" -Recurse
    foreach ($module in $devToolsModules) {
        Import-Module $module.FullName -DisableNameChecking -Global
    }
}

if ($env:CI -ne 'true') {
    $totalModules = $sharedModules.Count + $devToolsModules.Count
    Write-Host "BCApps enlistment initialized. Loaded $totalModules module(s)." -ForegroundColor Green
    if (-not $Dev) {
        Write-Host "Tip: Use '. .\init.ps1 -Dev' to also load developer tools." -ForegroundColor Gray
    } else {
        Write-Host "Run 'Get-Command -Module <module>' or 'Get-Help <command>' for usage information." -ForegroundColor Gray
    }
}
