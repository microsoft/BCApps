# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 7.0
<#
.SYNOPSIS
    Validates checked-out AL app architecture policies before build skip/cache decisions.
.DESCRIPTION
    Owns project and change relevance, checker self-tests for relevant PR/merge-group
    checks, and policy execution. Unknown or unavailable comparison evidence means RUN.
    No project selects all registered policies; no baseline on a local run means RUN.
    Direct app-specific scanner invocations remain unconditional.
.PARAMETER Project
    Repository-relative AL-Go project path. Empty selects all registered policies.
.PARAMETER BaselineRef
    Explicit comparison base for local, manual or scheduled checks. Event comparisons
    still use the PR base, whole merge group or push before/after endpoints.
.PARAMETER FetchMissingBase
    Allows the selector to fetch a missing comparison SHA in shallow CI checkouts.
.EXAMPLE
    ./build/scripts/Test-ALAppArchitecture.ps1
.EXAMPLE
    ./build/scripts/Test-ALAppArchitecture.ps1 -Project 'build/projects/Apps W1' -BaselineRef HEAD
#>
[CmdletBinding()]
param(
    [string] $Project,
    [string] $BaselineRef,
    [string] $EventName = $env:GITHUB_EVENT_NAME,
    [string] $EventPath = $env:GITHUB_EVENT_PATH,
    [string] $ExpectedHead = $env:GITHUB_SHA,
    [switch] $FetchMissingBase
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

# The single app policy registration and its AL-Go app-group mapping stay here,
# not in workflow conditions or a plugin/discovery framework.
$policyProject = 'build/projects/Apps W1'
$appRoot = Join-Path $repoRoot 'src/Apps/W1/PayablesAgent/app'
$normalizedProject = $Project.Replace('\', '/').TrimEnd('/') -replace '^\./', ''
if ($normalizedProject -and $normalizedProject -ne $policyProject) {
    Write-Host "AL app architecture: SKIP project '$Project'; no registered policy for this project."
    return
}

Import-Module (Join-Path $PSScriptRoot 'PayablesAgentArchitectureChanges.psm1') -Force
$change = Get-PayablesAgentArchitectureChange -RepoRoot $repoRoot -EventName $EventName -EventPath $EventPath `
    -ExpectedHead $ExpectedHead -BaselineRef $BaselineRef -FetchMissingBase:$FetchMissingBase
if (-not $change.Required) {
    Write-Host "AL app architecture: SKIP $policyProject; $($change.Reason)"
    return
}
Write-Host "AL app architecture: RUN $policyProject; $($change.Reason)"

if ($EventName -in @('pull_request', 'merge_group')) {
    Write-Host 'AL app architecture: testing the checked-out checker and change selector.'
    $testFiles = @(Get-ChildItem (Join-Path $PSScriptRoot 'tests/ALArchitecture*.Test.ps1') -File)
    if ($testFiles.Count -eq 0) { throw 'No AL app architecture tests found.' }
    $result = Invoke-Pester -Script $testFiles.FullName -PassThru
    if ($result.TotalCount -eq 0 -or $result.FailedCount -gt 0) {
        throw "$($result.FailedCount) AL app architecture tests failed; $($result.TotalCount) tests discovered."
    }
}

& (Join-Path $PSScriptRoot 'Test-PayablesAgentArchitecture.ps1') -AppRoot $appRoot -RulesPath (Join-Path $appRoot 'architecture-rules.json')
