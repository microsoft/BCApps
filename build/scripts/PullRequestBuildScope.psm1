<#
.SYNOPSIS
    Narrows the Pull Request Build matrix to the countries and test modes a pull request affects.
.DESCRIPTION
    Every country project (Apps XX) also contains the W1 apps, so with AL-Go incremental builds any
    W1 change rebuilds and retests all countries. Pull request builds instead run W1 plus the
    countries whose own code the pull request changes. Full country coverage is provided by the
    merge queue (all-country compilation) and scheduled full-matrix runs on official branches.
    Runs in the Initialization job before AL-Go reads settings, and only rewrites files in that
    job's workspace.
#>

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "BuildOptimization.psm1" -Resolve)

$script:FullMatrixLabel = 'full-country-matrix'
$script:SentinelCountries = @('DE', 'US')
$script:RegionCountries = @{ APAC = @('AU', 'NZ'); DACH = @('AT', 'CH', 'DE'); NA = @('CA', 'MX', 'US') }
$script:InfrastructurePatterns = @(
    'build/*',
    'src/rulesets/*',
    '.github/*.json',
    '.github/actions/*',
    '.github/workflows/PullRequestHandler.yaml',
    '.github/workflows/_BuildALGoProject.yaml'
)

<#
.SYNOPSIS
    Determines which country projects a pull request needs, based on its changed files.
.PARAMETER ChangedFiles
    Files changed by the pull request, relative to the repo root.
.PARAMETER Countries
    All country codes that have country projects (excluding W1).
.OUTPUTS
    PSCustomObject with Countries (string[]) and Reasons (string[]).
#>
function Get-PullRequestCountries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $ChangedFiles,
        [Parameter(Mandatory)]
        [string[]] $Countries
    )

    $selected = [System.Collections.Generic.SortedSet[string]]::new()
    $reasons = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $ChangedFiles) {
        $path = $file.Replace('\', '/')
        $codes = @()
        if ($path -match '^src/(Apps|Layers)/([^/]+)/') {
            $folder = $Matches[2].ToUpperInvariant()
            if ($script:RegionCountries.ContainsKey($folder)) { $codes = $script:RegionCountries[$folder] }
            elseif ($Countries -contains $folder) { $codes = @($folder) }
        }
        elseif ($path -match '^build/projects/(Test )?Apps ([A-Za-z]{2})/') {
            $folder = $Matches[2].ToUpperInvariant()
            if ($Countries -contains $folder) { $codes = @($folder) }
        }
        elseif ($script:InfrastructurePatterns | Where-Object { $path -like $_ }) {
            $codes = $script:SentinelCountries
        }

        foreach ($code in ($codes | Where-Object { $Countries -contains $_ })) {
            if ($selected.Add($code)) { $reasons.Add("$code <- $path") }
        }
    }

    return [PSCustomObject]@{ Countries = [string[]]@($selected); Reasons = [string[]]@($reasons) }
}

<#
.SYNOPSIS
    Removes legacy test buckets when the pull request cannot affect any legacy test app.
.PARAMETER BuildModes
    Build modes configured for a test project.
.PARAMETER Affected
    Result of Get-AffectedAppNames (RunAll, AppNames).
.PARAMETER LegacyTestAppNames
    App names listed in the LegacyTests-* buckets of TestConfiguration.json.
#>
function Get-PullRequestTestBuildModes {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $BuildModes,
        [Parameter(Mandatory)]
        $Affected,
        [Parameter(Mandatory)]
        [string[]] $LegacyTestAppNames
    )

    if ($Affected.RunAll) { return $BuildModes }
    if (@($Affected.AppNames | Where-Object { $LegacyTestAppNames -contains $_ }).Count -gt 0) { return $BuildModes }
    return [string[]]@($BuildModes | Where-Object { $_ -notlike 'LegacyTestsBucket*' })
}

<#
.SYNOPSIS
    Rewrites the Pull Request Build settings in the current workspace to scope a pull request build.
.DESCRIPTION
    No-op for other events, when the pull request has the full-country-matrix label, or when the
    pull request's changes cannot be determined (AL-Go then builds as before).
.PARAMETER BaseFolder
    Root of the repository checkout.
#>
function Set-PullRequestBuildScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    if ($env:GITHUB_EVENT_NAME -ne 'pull_request') { return }

    $prEvent = Get-Content $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json
    if (@($prEvent.pull_request.labels | Where-Object { $_.name -eq $script:FullMatrixLabel }).Count -gt 0) {
        Write-Host "PR BUILD SCOPE: '$($script:FullMatrixLabel)' label present - building every country"
        return
    }

    $changedFiles = Get-PullRequestMergeChangedFiles
    if (-not $changedFiles) {
        Write-Host "PR BUILD SCOPE: Could not determine pull request changes - building every country"
        return
    }

    $projectsFolder = Join-Path $BaseFolder 'build/projects'
    $projectNames = @(Get-ChildItem -Path $projectsFolder -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.AL-Go/settings.json') } | Select-Object -ExpandProperty Name)
    $countries = @($projectNames | Where-Object { $_ -match '^Apps ([A-Z]{2})$' -and $Matches[1] -ne 'W1' } | ForEach-Object { $_.Substring(5) })

    $scope = Get-PullRequestCountries -ChangedFiles $changedFiles -Countries $countries
    $projects = @($projectNames | Where-Object {
        -not ($_ -match '^(Test )?Apps ([A-Z]{2})$' -and $Matches[2] -ne 'W1' -and $scope.Countries -notcontains $Matches[2])
    } | ForEach-Object { Join-Path 'build' (Join-Path 'projects' $_) })

    $settingsFile = Join-Path $BaseFolder '.github/Pull Request Build.settings.json'
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    $conditional = @($settings.conditionalSettings | Where-Object { $_.triggers -notcontains 'pull_request' })
    $conditional += [PSCustomObject]@{ triggers = @('pull_request'); settings = [PSCustomObject]@{ projects = $projects } }
    $settings.conditionalSettings = $conditional
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsFile -Encoding UTF8

    $affected = Get-AffectedAppNames -BaseFolder $BaseFolder
    $testConfig = Get-Content (Join-Path $BaseFolder 'build/scripts/TestConfiguration.json') -Raw | ConvertFrom-Json
    $legacyApps = @($testConfig.PSObject.Properties | Where-Object { $_.Name -like 'LegacyTests-*' } | ForEach-Object { $_.Value })
    $droppedModes = @()
    foreach ($project in @($projectNames | Where-Object { $_ -like 'Test Apps *' })) {
        $projectSettingsFile = Join-Path $projectsFolder "$project/.AL-Go/settings.json"
        $projectSettings = Get-Content $projectSettingsFile -Raw | ConvertFrom-Json
        if (-not $projectSettings.buildModes) { continue }
        $modes = Get-PullRequestTestBuildModes -BuildModes $projectSettings.buildModes -Affected $affected -LegacyTestAppNames $legacyApps
        if ($modes.Count -ne @($projectSettings.buildModes).Count) {
            $droppedModes += @($projectSettings.buildModes | Where-Object { $modes -notcontains $_ })
            $projectSettings.buildModes = $modes
            $projectSettings | ConvertTo-Json -Depth 20 | Set-Content -Path $projectSettingsFile -Encoding UTF8
        }
    }

    $countryText = if ($scope.Countries.Count) { $scope.Countries -join ', ' } else { 'none' }
    $modeText = if ($droppedModes.Count) { ($droppedModes | Select-Object -Unique) -join ', ' } else { 'none' }
    $summary = @(
        "### Pull request build scope",
        "",
        "- Countries built besides W1: $countryText",
        "- Test modes skipped (no affected legacy test app): $modeText",
        "- Add the ``$($script:FullMatrixLabel)`` label and re-run to build every country.",
        ""
    ) + @($scope.Reasons | ForEach-Object { "  - $_" })
    $summary | ForEach-Object { Write-Host "PR BUILD SCOPE: $_" }
    if ($env:GITHUB_STEP_SUMMARY) { $summary | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8 }
}

Export-ModuleMember -Function Get-PullRequestCountries, Get-PullRequestTestBuildModes, Set-PullRequestBuildScope
