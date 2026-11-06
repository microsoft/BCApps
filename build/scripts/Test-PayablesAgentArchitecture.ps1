# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

#Requires -Version 7.0
<#
.SYNOPSIS
    Runs the app-owned Payables Agent architectural static checks without compiling AL.
.DESCRIPTION
    Policy and editor schema: app/architecture-rules.json and architecture-rules.schema.json.
    Dependencies use type + name in explicit reference contexts and path-selected local
    targets (or explicit typed symbols). External boundaries use namespace imports and
    qualified uses as a deliberately conservative proxy, without reading dependency apps.
    The other checks cover object properties, code ownership, development guards, manifest
    policy, placement and temporary projections. See app/architecture.md for limitations.

    All source and preprocessor branches are scanned. This is not an AL parser/analyzer:
    no numeric/dynamic reference resolution, using-based symbol binding, expression parsing,
    temporary-record inference, transitive calls or effective UI visibility analysis.
    Only * and ? globs are supported, case-insensitively; * spans directories.
    Exceptions need reasons and fail when stale.

    CI invokes this through the TestAdHocALAppValidations action in PR validation (including
    merge queues) for relevant PA/checker/workflow changes, or an uncertain diff. The shared
    change selector also guards the PR Pester tests; direct local invocations here always scan.
    Requires PowerShell 7 (JSON Schema validation); local compiler builds invoke it separately.
.EXAMPLE
    ./build/scripts/Test-PayablesAgentArchitecture.ps1
.EXAMPLE
    $tests = Get-ChildItem ./build/scripts/tests/ALArchitecture*.Test.ps1
    Invoke-Pester -Script $tests.FullName
#>
[CmdletBinding()]
param(
    [string] $AppRoot = (Join-Path $PSScriptRoot '../../src/Apps/W1/PayablesAgent/app'),
    [string] $RulesPath,
    # Diagnostics and annotations are reported relative to this repository root.
    [string] $RepoRoot = (Join-Path $PSScriptRoot '../..'),
    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'ALArchitectureRules.psm1') -Force
if ([string]::IsNullOrWhiteSpace($RulesPath)) { $RulesPath = Join-Path $AppRoot 'architecture-rules.json' }
$result = Invoke-ALArchitectureRules -AppRoot $AppRoot -RulesPath $RulesPath
$repositoryRoot = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('/', '\') + [IO.Path]::DirectorySeparatorChar
foreach ($diagnostic in $result.Diagnostics) {
    $path = $diagnostic.Path
    if ($path.StartsWith($repositoryRoot, [StringComparison]::OrdinalIgnoreCase)) { $path = $path.Substring($repositoryRoot.Length) }
    $path = $path.Replace('\', '/')
    $message = "$($diagnostic.RuleId): $($diagnostic.Message)"
    if ($env:GITHUB_ACTIONS -eq 'true') {
        $escapedPath = $path.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A').Replace(':', '%3A').Replace(',', '%2C')
        $escapedMessage = $message.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
        Write-Host "::error file=$escapedPath,line=$($diagnostic.Line)::$escapedMessage"
    } else { Write-Host "ERROR ${path}:$($diagnostic.Line): $message" }
}
Write-Host "Payables Agent architecture: $($result.ObjectCount) objects, $($result.ReferenceCount) textual references, $($result.RuleCount) rules; $($result.Diagnostics.Count) findings."
if ($result.Diagnostics.Count -gt 0) { throw 'Payables Agent architecture checks failed. See the diagnostics above.' }
if ($PassThru) { return $result }
