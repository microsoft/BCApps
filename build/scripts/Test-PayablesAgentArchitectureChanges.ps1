# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 5.1
<#
.SYNOPSIS
    Selects whether CI runs the Payables Agent architecture checks and their Pester tests.
.DESCRIPTION
    Compares the checked-out HEAD with the PR base, merge-group base, or push's before SHA.
    Manual/scheduled builds can supply the AL-Go baseline SHA; otherwise validation runs.
    Missing/invalid event data, mismatched checkouts or Git failures mean RUN, not SKIP.
    Writes required=true/false to GITHUB_OUTPUT. Local architecture runs remain unfiltered.
.EXAMPLE
    ./build/scripts/Test-PayablesAgentArchitectureChanges.ps1 -FetchMissingBase
.EXAMPLE
    ./build/scripts/Test-PayablesAgentArchitectureChanges.ps1 -EventName workflow_dispatch -BaselineRef HEAD~1 -PassThru
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = (Join-Path $PSScriptRoot '../..'),
    [string] $EventName = $env:GITHUB_EVENT_NAME,
    [string] $EventPath = $env:GITHUB_EVENT_PATH,
    [string] $ExpectedHead = $env:GITHUB_SHA,
    [string] $BaselineRef,
    [switch] $FetchMissingBase,
    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'PayablesAgentArchitectureChanges.psm1') -Force

$result = Get-PayablesAgentArchitectureChange -RepoRoot $RepoRoot -EventName $EventName -EventPath $EventPath `
    -ExpectedHead $ExpectedHead -BaselineRef $BaselineRef -FetchMissingBase:$FetchMissingBase
$required = $result.Required.ToString().ToLowerInvariant()
Write-Host "Payables Agent architecture: required=$required. $($result.Reason)"
if ($env:GITHUB_OUTPUT) {
    Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "required=$required" -Encoding UTF8
}
if ($PassThru) {
    return $result
}
