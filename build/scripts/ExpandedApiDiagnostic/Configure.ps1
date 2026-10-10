param([ValidateSet('Build', 'Lane')][string]$Kind)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Context.psm1') -Force
Assert-ExpandedApiDispatch
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -ne 7) { throw 'Diagnostic requires the baseline PowerShell7 host.' }
$pins = Get-ExpandedApiPinSet
if ($env:BC_EXPANDED_COUNTRY -cnotin @('W1', 'DE', 'CA', 'US', 'IT')) { throw 'Unexpected compilation country.' }
$output = Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output'
if (Test-Path $output) { throw 'Diagnostic output already exists; refusing stale evidence reuse.' }
$null = New-Item -ItemType Directory -Path $output -Force
Import-Module (Join-Path $PSScriptRoot 'TenantResources.psm1')
Get-SqlTenantResourceSample -Phase setup-start | ConvertTo-Json -Depth 12 |
    Set-Content (Join-Path $output 'setup-resource.json')
@{ utc = $env:BC_EXPANDED_STARTED_UTC; ticks = [long]$env:BC_EXPANDED_STARTED_TICKS
    frequency = [Diagnostics.Stopwatch]::Frequency; runner = $env:RUNNER_NAME
    host = $env:COMPUTERNAME; shell = $PSVersionTable.PSVersion.ToString()
    kind = $Kind; run = $env:GITHUB_RUN_ID; sourceHead = $env:GITHUB_SHA } |
    ConvertTo-Json | Set-Content (Join-Path $output 'clock.json')
& (Join-Path $PSScriptRoot 'StageSource.ps1') |
    Set-Content (Join-Path $output 'source-receipt.json')

$repoPath = Join-Path $env:GITHUB_WORKSPACE '.github\AL-Go-Settings.json'
$repo = Get-Content $repoPath -Raw | ConvertFrom-Json -AsHashtable
$repo.bcContainerHelperVersion = $pins.helper
$repo.artifact = "https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/sandbox/$($pins.application)/$($env:BC_EXPANDED_COUNTRY.ToLowerInvariant())"
$repo.maxTestAppReruns = 0
$repo.workspaceCompilation = @{ enabled = ($Kind -eq 'Build'); parallelism = 2 }
$repo.incrementalBuilds = @{ onPush = $false; onPull_Request = $false; onSchedule = $false; retentionDays = 14; mode = 'modifiedApps' }
$repo.skipUpgrade = $true
$repo | ConvertTo-Json -Depth 30 | Set-Content $repoPath
$packagesPath = Join-Path $env:GITHUB_WORKSPACE 'build\Packages.json'
$packages = Get-Content $packagesPath -Raw | ConvertFrom-Json -AsHashtable
$packages.BCPlatform.Version = $pins.platform
$packages | ConvertTo-Json -Depth 20 | Set-Content $packagesPath

if ($Kind -eq 'Build') {
    $sourceProject = "build\projects\Apps $($env:BC_EXPANDED_COUNTRY)"
    $project = "build\projects\Expanded Build $($env:BC_EXPANDED_COUNTRY)"
} else {
    $context = Get-ExpandedContext
    $sourceProject = "build\projects\Test Apps $($env:BC_EXPANDED_COUNTRY)"
    $project = $context.project
}
if (Test-Path $project) { throw 'Generated project already exists.' }
Copy-Item -LiteralPath $sourceProject -Destination $project -Recurse
$settingsPath = Join-Path $project '.AL-Go\settings.json'
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
$settings.projectName = "Expanded $Kind $($env:BC_EXPANDED_COUNTRY)"
$settings.country = $env:BC_EXPANDED_COUNTRY.ToLowerInvariant()
$settings.bcContainerHelperVersion = $pins.helper
$settings.artifact = $repo.artifact
$settings.skipUpgrade = $true
$settings.incrementalBuilds = @{ onPush = $false; onPull_Request = $false; onSchedule = $false; retentionDays = 14; mode = 'modifiedApps' }
$settings.maxTestAppReruns = 0
if ($Kind -eq 'Build') {
    $settings.doNotRunTests = $true
    $settings.doNotPublishApps = $true
    $settings.useCompilerFolder = $true
    $settings.workspaceCompilation = @{ enabled = $true; parallelism = 2 }
    $hook = @'
param([hashtable]$parameters)
& (Join-Path $PSScriptRoot '../../../scripts/ExpandedApiDiagnostic/Compiler.ps1') -Phase Before -Parameters $parameters
'@
    Set-Content (Join-Path $project '.AL-Go\PreNewBcCompilerFolder.ps1') $hook
} else {
    $settings.conditionalSettings = @()
    $settings.appFolders = @()
    $settings.testFolders = @()
    # AL-Go91b96 treats empty folders without this marker as an empty repository
    # and exits before reading installTestAppsJson. No dependency downloader is
    # called: the actual packages still come exclusively from the sealed registry.
    $settings.projectsToTest = @("build/projects/Apps $($env:BC_EXPANDED_COUNTRY)")
    $settings.doNotRunTests = $false
    $settings.doNotPublishApps = $false
    $settings.runTestsInAllInstalledTestApps = $true
    $settings.workspaceCompilation = @{ enabled = $false; parallelism = 2 }
    $settings.enableCleanTestCodeunitExecution = $true
    $settings.useCompilerFolder = $false
    $settings.numberOfTenantsForTesting = $context.cell.configuration.mounts.Count
    $settings.testType = $context.lane.settings.testType
    $settings.companyName = $context.lane.settings.company
    $settings.enableTaskScheduler = $context.lane.settings.taskScheduler
    $settings.additionalDemoDataTypes = @()
    if ($context.lane.id -eq 'LegacyTestsBucket1') { $settings.additionalDemoDataTypes = @('Standard', 'Evaluation') }
    foreach ($pair in @(
        @('NewBcContainer', 'NewContainer'), @('RunTestsInBcContainer', 'RunLane')
    )) {
        $hook = @"
param([hashtable]`$parameters)
& (Join-Path `$PSScriptRoot '../../../scripts/ExpandedApiDiagnostic/$($pair[1]).ps1') -Parameters `$parameters
"@
        Set-Content (Join-Path $project ".AL-Go\$($pair[0]).ps1") $hook
    }
    # Retain the established country/demo-data setup, removing its two retry budgets
    # only in this disposable checkout. Same directory preserves shared helper paths.
    $setup = Get-Content 'build\scripts\ImportTestDataInBcContainer.ps1' -Raw
    foreach ($old in @('$maxAttempts = 3', '$maxAttempts = 2')) {
        if ([regex]::Matches($setup, [regex]::Escape($old)).Count -ne 1) { throw 'Setup retry contract changed.' }
        $setup = $setup.Replace($old, '$maxAttempts = 1')
    }
    $setup = $setup.Replace('Join-Path $env:TEMP "DemoToolTranscript.txt"', 'Join-Path $env:BC_EXPANDED_OUTPUT "DemoToolTranscript.txt"')
    $setup = $setup.Replace('Write-Host "  WARNING: Sync failed for', 'throw "Sync failed for')
    Set-Content 'build\scripts\ExpandedApiImportTestData.ps1' $setup
    Set-Content (Join-Path $project '.AL-Go\ImportTestDataInBcContainer.ps1') @'
param([hashtable]$parameters)
. (Join-Path $PSScriptRoot '../../../scripts/ExpandedApiImportTestData.ps1') -parameters $parameters
'@
}
$settings | ConvertTo-Json -Depth 30 | Set-Content $settingsPath
Set-Content (Join-Path $project '.AL-Go\BuildInitialize.ps1') @'
param([hashtable]$parameters)
DownloadAndImportBcContainerHelper
& (Join-Path $PSScriptRoot '../../../scripts/ExpandedApiDiagnostic/HelperPreflight.ps1') -Boundary Warm
'@
Copy-Item $settingsPath (Join-Path $output 'project-settings.json')
"project=$($project.Replace('\', '/'))" | Add-Content $env:GITHUB_OUTPUT
"artifact=$($repo.artifact)" | Add-Content $env:GITHUB_OUTPUT
"BC_EXPANDED_PROJECT=$project" | Add-Content $env:GITHUB_ENV
"BC_EXPANDED_OUTPUT=$output" | Add-Content $env:GITHUB_ENV
