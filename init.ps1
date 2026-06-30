<#
.SYNOPSIS
    BCApps enlistment initialization script.

.DESCRIPTION
    Loads all PowerShell modules (.psm1) found under build\scripts\DevEnv into
    the current session. New modules added to that folder are picked up automatically.

.EXAMPLE
    . .\init.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$devEnvRoot = Join-Path $repoRoot "build\scripts\DevEnv"

Write-Host "Initializing BCApps enlistment..." -ForegroundColor Cyan

# Auto-discover and load all .psm1 modules under build\scripts\DevEnv
$modules = Get-ChildItem -Path $devEnvRoot -Filter "*.psm1" -Recurse
foreach ($module in $modules) {
    Import-Module $module.FullName -DisableNameChecking -Global
}

Write-Host "BCApps enlistment initialized. Loaded $($modules.Count) module(s) from build\scripts\DevEnv." -ForegroundColor Green
Write-Host "Run 'Get-Command -Module <module>' or 'Get-Help <command>' for usage information." -ForegroundColor Gray
