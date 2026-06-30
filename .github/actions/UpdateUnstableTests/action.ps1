<#
.Synopsis
    Entry point for the Update Unstable Tests action.
.Description
    Reads the failing tests from the supplied CI/CD (or PR Build) runs and invokes the shared updater
    script, which builds the per-branch unstable-tests list and exposes the artifact name for upload.

    By default the list is recomputed from the supplied runs. When -additive is set, the failing tests
    are merged into the existing artifact instead (every existing entry is preserved).

    The set of runs to read is computed by the calling workflow and passed in as a comma-separated list.

    Parameters are passed explicitly by the action.yaml run block.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $branch,

    [string] $runId = '',

    [switch] $additive
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

. "$env:GITHUB_WORKSPACE/init.ps1"

$scriptsRoot = Join-Path $repoRoot 'eng' 'AL-Go' 'scripts' 'TestTolerance'
Import-Module (Join-Path $scriptsRoot 'TestTolerance.psm1') -Force

# Parse the comma-separated run ids.
$runIds = @($runId.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($runIds.Count -eq 0) {
    throw "No valid run IDs were provided in 'run-id' (value: '$runId'). Provide at least one CI/CD (or PR Build) run ID."
}

$outputPath = Join-Path '.unstable-tests' 'unstable-tests.json'

& (Join-Path $scriptsRoot 'UpdateUnstableTestsArtifact.ps1') `
    -Branch $branch `
    -RunIds $runIds `
    -OutputPath $outputPath `
    -Additive:$additive

# Expose the artifact name so the action's upload step can publish it. Only emit it when the artifact
# was actually produced, so the upload step can be skipped otherwise.
if ($env:GITHUB_OUTPUT -and (Test-Path $outputPath)) {
    $artifactName = Get-UnstableTestsArtifactName -Branch $branch
    Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "artifactName=$artifactName"
}
