<#
.SYNOPSIS
    Runs the ad hoc validations of the AL apps registered below.
.DESCRIPTION
    A registered app is scanned when its folder or the checker's files (scripts, tests and
    action) changed. Older checkouts without the app's architecture-rules.json are skipped.

    The checker's own Pester tests are slower and only run in PR validation (including
    merge queues), when the checker's files or any registered app changed.

    Changed files come from the GitHub event (pull_request, merge_group, push). When they
    are unknown (local or manual runs, detection failures), everything runs.
    Pass -ChangedFiles to simulate a change set.
.EXAMPLE
    ./build/scripts/Test-AdHocALAppValidations.ps1
.EXAMPLE
    ./build/scripts/Test-AdHocALAppValidations.ps1 -ChangedFiles 'README.md'
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = (Join-Path $PSScriptRoot '../..'),
    [string] $EventName = $env:GITHUB_EVENT_NAME,
    [string[]] $ChangedFiles
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$repoRoot = (Get-Item -LiteralPath $RepoRoot -ErrorAction Stop).FullName

# Apps opting into ad hoc validations.
# Path: app folder that holds architecture-rules.json.
$registeredApps = @(
    @{ Name = 'Payables Agent'; Path = 'src/Apps/W1/PayablesAgent/app' }
)

# Changes to the checker's files rerun everything: the scan of every registered app and, the self-tests.
$checkerInputs = @(
    'build/scripts/ALArchitecture*',
    'build/scripts/Test-AdHocALAppValidations.ps1',
    'build/scripts/tests/ALArchitecture*.Test.ps1',
    '.github/actions/TestAdHocALAppValidations/*'
)

if (-not $PSBoundParameters.ContainsKey('ChangedFiles')) {
    Import-Module (Join-Path $PSScriptRoot 'BuildOptimization.psm1') -Force
    Push-Location -LiteralPath $repoRoot
    try { $ChangedFiles = Get-ChangedFilesForCI } finally { Pop-Location }
}

# Returns why a check must run for the given path patterns, or $null to skip it.
function Get-RunReason([string[]] $Patterns) {
    if ($null -eq $ChangedFiles) { return 'changed files are unknown' }
    foreach ($file in $ChangedFiles) {
        foreach ($pattern in $Patterns) {
            if ($file -like $pattern) { return "$file changed" }
        }
    }
    return $null
}

if ($EventName -in @('pull_request', 'merge_group')) {
    # The tests use the registered apps as fixtures, so app changes rerun them too.
    $reason = Get-RunReason ($checkerInputs + @($registeredApps | ForEach-Object { "$($_.Path)/*" }))
    if ($reason) {
        Write-Host "AL app architecture self-tests: RUN; $reason."
        $testFiles = @(Get-ChildItem (Join-Path $repoRoot 'build/scripts/tests/ALArchitecture*.Test.ps1') -File -ErrorAction SilentlyContinue)
        if ($testFiles.Count -eq 0) { throw 'No AL app architecture tests found.' }
        $result = Invoke-Pester -Script $testFiles.FullName -PassThru
        if ($result.TotalCount -eq 0 -or $result.FailedCount -gt 0) {
            throw "$($result.FailedCount) AL app architecture tests failed; $($result.TotalCount) tests discovered."
        }
    }
    else {
        Write-Host 'AL app architecture self-tests: SKIP; no checker files or registered apps changed.'
    }
}

# Imported after the self-tests, which import their own copy of the module with -Force.
Import-Module (Join-Path $PSScriptRoot 'ALArchitectureRules.psm1') -Force
foreach ($app in $registeredApps) {
    $reason = Get-RunReason ($checkerInputs + "$($app.Path)/*")
    if (-not $reason) {
        Write-Host "$($app.Name) architecture: SKIP; neither the app nor the checker files changed."
        continue
    }
    $appRoot = Join-Path $repoRoot $app.Path
    $rulesPath = Join-Path $appRoot 'architecture-rules.json'
    if (-not (Test-Path -LiteralPath $rulesPath -PathType Leaf)) {
        Write-Host "$($app.Name) architecture: SKIP; this checkout registers no policy at $rulesPath."
        continue
    }
    Write-Host "$($app.Name) architecture: RUN; $reason."
    Invoke-ALAppArchitectureCheck -AppRoot $appRoot -RulesPath $rulesPath -RepoRoot $repoRoot -Name $app.Name
}
