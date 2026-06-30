<#
.SYNOPSIS
    BCApps enlistment initialization script.

.DESCRIPTION
    Loads developer tooling modules into the current PowerShell session.
    Dot-source this script from the repository root to get access to:
      - Invoke-Miapp / Invoke-MiSnapApp (country layer integration)
      - New-GDLView / Sync-GDLView / Remove-GDLView (GDL view management)
      - EnlistmentHelperFunctions (repo utility functions)

.EXAMPLE
    . .\init.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$scriptsRoot = Join-Path $repoRoot "build\scripts"

Write-Host "Initializing BCApps enlistment..." -ForegroundColor Cyan

# Load enlistment helper functions
Import-Module (Join-Path $scriptsRoot "EnlistmentHelperFunctions.psm1") -DisableNameChecking -Global

# Load Miapp (country layer integration)
Import-Module (Join-Path $scriptsRoot "Miapp\MicroApp.psm1") -DisableNameChecking -Global
Import-Module (Join-Path $scriptsRoot "Miapp\MicroSnapApp.psm1") -DisableNameChecking -Global

# Load GDL Development (view management)
Import-Module (Join-Path $scriptsRoot "GDLDevelopment\GDLDevelopment.psm1") -DisableNameChecking -Global

Write-Host "BCApps enlistment initialized. Available commands:" -ForegroundColor Green
Write-Host "  Invoke-Miapp          - Propagate W1 changes to country layers" -ForegroundColor Gray
Write-Host "  Invoke-MiSnapApp      - Validate propagation for committed files" -ForegroundColor Gray
Write-Host "  New-GDLView           - Create a GDL view for a country code" -ForegroundColor Gray
Write-Host "  Sync-GDLView          - Synchronize an existing GDL view" -ForegroundColor Gray
Write-Host "  Remove-GDLView        - Remove a GDL view" -ForegroundColor Gray
Write-Host "  Remove-AllGDLViews    - Remove all GDL views" -ForegroundColor Gray
Write-Host ""
Write-Host "Run 'Get-Help <command>' for detailed usage information." -ForegroundColor Gray
