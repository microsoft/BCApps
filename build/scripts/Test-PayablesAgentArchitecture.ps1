# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

<#
.SYNOPSIS
    Evaluates the dependency rules owned by the Payables Agent app, without compiling AL.
.DESCRIPTION
    Always scans the entire app, including all preprocessor branches. The editable policy
    is dependency-rules.json at the top of the app, not hard-coded in this script.
    Errors (including invalid configuration and stale exceptions) fail the build.
    Warnings report unfinished architectural cleanup; use -WarningsAsErrors to gate those too.

    Rules deny from/to selector matches, minus documented exceptions. Selector fields are
    ANDed, values within a field are ORed. Paths/names/namespaces use case-insensitive
    * and ? globs (* spans /); kinds/catalog IDs are explicit values. Paths are relative
    to the app or the target catalog. The JSON schema documents all supported fields.
    Exception entries that no longer match a denied dependency fail configuration validation.

    The checker recognizes typed references, object constants/numeric indexed IDs, literal
    static Run/RunModal calls, enum types, SourceTable, conditional TableRelation, CalcFormula,
    page parts, dataitems, inheritance, interfaces, navigation, permissions and event targets.
    It does not resolve dynamic RecordRef/variable object IDs, string-based integrations,
    aliases/indirect calls, cycles, persistence effects, or subscriber control-flow guards.
    Unindexed external symbols can be matched by kind/name; unqualified namespaces cannot
    be inferred. Each file must have one object identity (conditional repeats are allowed).
    Temporary table/page properties inside #if branches are conservatively not exemptions.

    CI runs this in PR Verify App Changes and immediately after Apps W1 build checkout,
    before cache/skip decisions. Direct editor/compiler builds must invoke it separately.
.EXAMPLE
    ./build/scripts/Test-PayablesAgentArchitecture.ps1
.EXAMPLE
    ./build/scripts/Test-PayablesAgentArchitecture.ps1 -WarningsAsErrors
.EXAMPLE
    Invoke-Pester ./build/scripts/tests/ALDependencyRules.Test.ps1
#>
[CmdletBinding()]
param(
    [string] $AppRoot,
    [string] $RulesPath,
    [switch] $WarningsAsErrors,
    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
Import-Module (Join-Path $PSScriptRoot 'ALDependencyRules.psm1') -Force
if ([string]::IsNullOrWhiteSpace($AppRoot)) { $AppRoot = Join-Path $PSScriptRoot '../../src/Apps/W1/PayablesAgent/app' }
if ([string]::IsNullOrWhiteSpace($RulesPath)) { $RulesPath = Join-Path $AppRoot 'dependency-rules.json' }

$result = Invoke-ALDependencyRules -AppRoot $AppRoot -RulesPath $RulesPath
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')).TrimEnd('/', '\') + [IO.Path]::DirectorySeparatorChar
foreach ($diagnostic in $result.Diagnostics) {
    $severity = $diagnostic.Severity
    if ($WarningsAsErrors) { $severity = 'error' }
    $path = $diagnostic.Path
    if ($path.StartsWith($repositoryRoot, [StringComparison]::OrdinalIgnoreCase)) { $path = $path.Substring($repositoryRoot.Length) }
    $path = $path.Replace('\', '/')
    $message = "$($diagnostic.RuleId): $($diagnostic.Message)"
    if ($env:GITHUB_ACTIONS -eq 'true') {
        $escapedPath = $path.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A').Replace(':', '%3A').Replace(',', '%2C')
        $escapedMessage = $message.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
        Write-Host "::${severity} file=$escapedPath,line=$($diagnostic.Line)::$escapedMessage"
    }
    else {
        Write-Host "$($severity.ToUpperInvariant()) ${path}:$($diagnostic.Line): $message"
    }
}
$errors = @($result.Diagnostics | Where-Object { $_.Severity -eq 'error' }).Count
$warnings = @($result.Diagnostics | Where-Object { $_.Severity -eq 'warning' }).Count
Write-Host "Payables Agent architecture: $($result.ObjectCount) app objects, $($result.CatalogObjectCount) catalog objects, $($result.DependencyCount) dependencies; $errors errors, $warnings warnings."
if ($errors -gt 0 -or ($WarningsAsErrors -and $warnings -gt 0)) { throw 'Payables Agent dependency rules failed. See the diagnostics above.' }
if ($PassThru) { return $result }
