# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string] $RepoRoot = (Join-Path $PSScriptRoot '../..'),
    [string] $BaselineRef,
    [string] $EventName = $env:GITHUB_EVENT_NAME,
    [string] $EventPath = $env:GITHUB_EVENT_PATH,
    [string] $ExpectedHead = $env:GITHUB_SHA
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$repoRoot = (Get-Item -LiteralPath $RepoRoot -ErrorAction Stop).FullName

# The single app policy registration stays here, not in workflow conditions or a
# plugin/discovery framework.
$appRoot = Join-Path $repoRoot 'src/Apps/W1/PayablesAgent/app'
$rulesPath = Join-Path $appRoot 'architecture-rules.json'
if (-not (Test-Path -LiteralPath $rulesPath -PathType Leaf)) {
    Write-Host "AL app architecture: SKIP; this checkout registers no policy at $rulesPath."
    return
}

Import-Module (Join-Path $PSScriptRoot 'PayablesAgentArchitectureChanges.psm1') -Force
$change = Get-PayablesAgentArchitectureChange -RepoRoot $repoRoot -EventName $EventName -EventPath $EventPath `
    -ExpectedHead $ExpectedHead -BaselineRef $BaselineRef
if (-not $change.Required) {
    Write-Host "AL app architecture: SKIP; $($change.Reason)"
    return
}
Write-Host "AL app architecture: RUN; $($change.Reason)"

if ($EventName -in @('pull_request', 'merge_group')) {
    Write-Host 'AL app architecture: testing the checked-out checker and change selector.'
    $testFiles = @(Get-ChildItem (Join-Path $repoRoot 'build/scripts/tests/ALArchitecture*.Test.ps1') -File)
    if ($testFiles.Count -eq 0) { throw 'No AL app architecture tests found.' }
    # The tests import the checkout's modules; unload the runner's copy so module-scoped
    # mocks bind to exactly one module even when the runner comes from a separate copy.
    Remove-Module PayablesAgentArchitectureChanges -ErrorAction SilentlyContinue
    $result = Invoke-Pester -Script $testFiles.FullName -PassThru
    if ($result.TotalCount -eq 0 -or $result.FailedCount -gt 0) {
        throw "$($result.FailedCount) AL app architecture tests failed; $($result.TotalCount) tests discovered."
    }
}

& (Join-Path $PSScriptRoot 'Test-PayablesAgentArchitecture.ps1') -AppRoot $appRoot -RulesPath $rulesPath -RepoRoot $repoRoot
