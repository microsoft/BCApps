<#
.Synopsis
    Entry point for the Update Unstable Tests (Combined) action.
.Description
    Invokes the combined updater script, which maintains the per-branch unstable-tests artifact from both
    detection signals in a single run: the CI/CD sliding-window recompute (Path A) and the additive
    cross-PR PR-build detector (Path B). It then exposes the artifact name so the action's upload step can
    publish it, only when the artifact was actually produced.

    Parameters are passed explicitly by the action.yaml run block, which sources the numeric tuning
    values (RunLimit / WindowHours / MinDistinctPrs) from its own input defaults so they live in a
    single place rather than being duplicated as PowerShell parameter defaults.

.Parameter Branch
    Supported branch (main or releases/*) whose unstable-tests artifact should be updated.
.Parameter RunLimit
    Path A: number of recent completed CI/CD runs to recompute the base list from.
.Parameter FilterPush
    Path A: include CI/CD runs triggered by 'push' when discovering the window.
.Parameter FilterWorkflowDispatch
    Path A: include CI/CD runs triggered by 'workflow_dispatch' when discovering the window.
.Parameter WindowHours
    Path B: how many hours of recent PR builds (by completion time) to examine.
.Parameter MinDistinctPrs
    Path B: minimum number of distinct PRs a test must fail on to be marked unstable.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Branch,

    [Parameter(Mandatory = $true)]
    [int] $RunLimit,

    [switch] $FilterPush,

    [switch] $FilterWorkflowDispatch,

    [Parameter(Mandatory = $true)]
    [int] $WindowHours,

    [Parameter(Mandatory = $true)]
    [int] $MinDistinctPrs
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

$scriptsRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', '..', 'build', 'scripts', 'TestTolerance'
Import-Module (Join-Path -Path $scriptsRoot -ChildPath 'TestTolerance.psm1') -Force

$outputPath = Join-Path -Path '.unstable-tests' -ChildPath 'unstable-tests.json'

try {
    & (Join-Path -Path $scriptsRoot -ChildPath 'UpdateUnstableTestsCombined.ps1') `
        -Branch $Branch `
        -RunLimit $RunLimit `
        -FilterPush:$FilterPush `
        -FilterWorkflowDispatch:$FilterWorkflowDispatch `
        -WindowHours $WindowHours `
        -MinDistinctPrs $MinDistinctPrs `
        -OutputPath $outputPath

    # Expose the artifact name so the action's upload step can publish it. Only emit it when the artifact
    # was actually produced, so the upload step can be skipped otherwise.
    if ($env:GITHUB_OUTPUT -and (Test-Path $outputPath)) {
        $artifactName = Get-UnstableTestsArtifactName -Branch $Branch
        Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "artifactName=$artifactName"
    }
}
catch {
    Write-Host "::error::Failed to update unstable tests for '$Branch': $($_.Exception.Message)"
    exit 1
}

# The driver runs best-effort 'gh' commands (e.g. downloading results from still-running PR builds that may
# not have uploaded any artifacts yet), which can leave $LASTEXITCODE non-zero even though the update itself
# succeeded. GitHub's pwsh wrapper ends with 'exit $LASTEXITCODE', so normalize the exit code on success to
# avoid failing the step on a benign, already-tolerated 'gh' error.
exit 0
