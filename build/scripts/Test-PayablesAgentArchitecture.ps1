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
    Exceptions need reasons and fail when stale. Errors and invalid configuration fail CI;
    -WarningsAsErrors also gates architectural cleanup warnings.

    CI invokes this for relevant PA/checker/workflow changes (or an uncertain diff) in PR
    validation and Apps W1 builds, before AL-Go cache/skip decisions. The shared change
    selector also guards the PR Pester tests; direct local invocations here always scan.
    Requires PowerShell 7 (JSON Schema validation); local compiler builds invoke it separately.
.EXAMPLE
    ./build/scripts/Test-PayablesAgentArchitecture.ps1 -WarningsAsErrors
.EXAMPLE
    $tests = Get-ChildItem ./build/scripts/tests/ALArchitecture*.Test.ps1
    Invoke-Pester -Script $tests.FullName
#>
[CmdletBinding()]
param(
    [string] $AppRoot = (Join-Path $PSScriptRoot '../../src/Apps/W1/PayablesAgent/app'),
    [string] $RulesPath,
    [switch] $WarningsAsErrors,
    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'ALArchitectureRules.psm1') -Force
if ([string]::IsNullOrWhiteSpace($RulesPath)) { $RulesPath = Join-Path $AppRoot 'architecture-rules.json' }
$result = Invoke-ALArchitectureRules -AppRoot $AppRoot -RulesPath $RulesPath
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')).TrimEnd('/', '\') + [IO.Path]::DirectorySeparatorChar
foreach ($diagnostic in $result.Diagnostics) {
    $severity = if ($WarningsAsErrors) { 'error' } else { $diagnostic.Severity }
    $path = $diagnostic.Path
    if ($path.StartsWith($repositoryRoot, [StringComparison]::OrdinalIgnoreCase)) { $path = $path.Substring($repositoryRoot.Length) }
    $path = $path.Replace('\', '/')
    $message = "$($diagnostic.RuleId): $($diagnostic.Message)"
    if ($env:GITHUB_ACTIONS -eq 'true') {
        $escapedPath = $path.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A').Replace(':', '%3A').Replace(',', '%2C')
        $escapedMessage = $message.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
        Write-Host "::${severity} file=$escapedPath,line=$($diagnostic.Line)::$escapedMessage"
    } else { Write-Host "$($severity.ToUpperInvariant()) ${path}:$($diagnostic.Line): $message" }
}
$errors = @($result.Diagnostics | Where-Object Severity -eq 'error').Count
$warnings = @($result.Diagnostics | Where-Object Severity -eq 'warning').Count
Write-Host "Payables Agent architecture: $($result.ObjectCount) objects, $($result.ReferenceCount) textual references, $($result.RuleCount) rules; $errors errors, $warnings warnings."
if ($errors -gt 0 -or ($WarningsAsErrors -and $warnings -gt 0)) { throw 'Payables Agent architecture checks failed. See the diagnostics above.' }
if ($PassThru) { return $result }
