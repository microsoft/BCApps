<#
.Synopsis
    Entry point for the Update Unstable Tests (Combined) action.
.Description
    Invokes the combined updater script, which maintains the per-branch unstable-tests artifact from both
    detection signals in a single run: the CI/CD sliding-window recompute (Path A) and the additive
    cross-PR PR-build detector (Path B). It then exposes the artifact name so the action's upload step can
    publish it, only when the artifact was actually produced.

    Parameters are passed explicitly by the action.yaml run block.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [int] $RunLimit = 3,

    [switch] $FilterPush,

    [switch] $FilterWorkflowDispatch,

    [int] $WindowHours = 3,

    [int] $MinDistinctPrs = 2
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

$scriptsRoot = Join-Path $PSScriptRoot '..' '..' '..' 'build' 'scripts' 'TestTolerance'
Import-Module (Join-Path $scriptsRoot 'TestTolerance.psm1') -Force

$outputPath = Join-Path '.unstable-tests' 'unstable-tests.json'

& (Join-Path $scriptsRoot 'UpdateUnstableTestsCombined.ps1') `
    -Branch $Branch `
    -RunLimit $RunLimit `
    -FilterPush:$FilterPush `
    -FilterWorkflowDispatch:$FilterWorkflowDispatch `
    -WindowHours $WindowHours `
    -MinDistinctPrs $MinDistinctPrs `
    -OutputPath $outputPath

# Expose the artifact name so the action's upload step can publish it. Only emit it when the artifact was
# actually produced, so the upload step can be skipped otherwise.
if ($env:GITHUB_OUTPUT -and (Test-Path $outputPath)) {
    $artifactName = Get-UnstableTestsArtifactName -Branch $Branch
    Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "artifactName=$artifactName"
}
