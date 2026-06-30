<#
.SYNOPSIS
    BCApps enlistment initialization script.

.DESCRIPTION
    Loads all PowerShell modules (.psm1) found under build\scripts into the
    current session. New modules added to that tree are picked up automatically.

.EXAMPLE
    . .\init.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$scriptsRoot = Join-Path $repoRoot "build\scripts"

Write-Host "Initializing BCApps enlistment..." -ForegroundColor Cyan

# Auto-discover and load all .psm1 modules under build\scripts
$modules = Get-ChildItem -Path $scriptsRoot -Filter "*.psm1" -Recurse
foreach ($module in $modules) {
    Import-Module $module.FullName -DisableNameChecking -Global
}

Write-Host "BCApps enlistment initialized. Loaded $($modules.Count) module(s) from build\scripts." -ForegroundColor Green
Write-Host "Run 'Get-Command -Module <module>' or 'Get-Help <command>' for usage information." -ForegroundColor Gray
