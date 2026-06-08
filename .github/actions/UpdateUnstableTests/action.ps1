<#
.Synopsis
    Entry point for the Update Unstable Tests action.
.Description
    Computes the artifact name, invokes the updater script (which fetches recent
    test result artifacts matching the branch and repo version and rewrites the
    unstable-tests list from scratch), and uploads the result.

    Parameters are passed explicitly by the action.yaml run block.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $branch,

    [int] $runLimit = 3,

    [switch] $filterPush,
    [switch] $filterWorkflowDispatch,

    [Parameter(Mandatory = $true)]
    [string] $repository,

    [string] $sourceRepository = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

$scriptsRoot = Join-Path $PSScriptRoot '..' '..' '..' 'build' 'scripts' 'TestTolerance'
Import-Module (Join-Path $scriptsRoot 'TestTolerance.psm1') -Force

$sourceRepo = if ([string]::IsNullOrWhiteSpace($sourceRepository)) { $repository } else { $sourceRepository }

# --- Compute artifact name and output path ---
$artifactName = Get-UnstableTestsArtifactName -Branch $branch
Write-Host "Artifact name: $artifactName"

$unstableDir = '.unstable-tests'
$unstablePath = Join-Path $unstableDir 'unstable-tests.json'
New-Item -ItemType Directory -Path $unstableDir -Force | Out-Null

# --- Run updater ---
$env:GITHUB_REPOSITORY = $sourceRepo
$updaterScript = Join-Path $scriptsRoot 'UpdateUnstableTests.ps1'
& $updaterScript `
    -Branch $branch `
    -OutputPath $unstablePath `
    -RunLimit $runLimit `
    -FilterPush:$filterPush `
    -FilterWorkflowDispatch:$filterWorkflowDispatch

# --- Set output for artifact upload ---
Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "artifactName=$artifactName"

if (-not (Test-Path $unstablePath)) {
    Write-Host "::warning::Unstable tests file was not produced (no CI/CD runs with test results found). Skipping artifact upload."
    return
}

Write-Host "Unstable tests list ready at '$unstablePath'."
