<#
.SYNOPSIS
    PROTOTYPE: reuse the apps that are already published in the BC artifact database.

.DESCRIPTION
    A BC (sandbox) artifact ships a demo database in which every Microsoft app is already
    published, installed and synchronized, plus CRONUS demo data. Every BCApps test build
    already downloads and restores that database - and then throws all of it away:

        # NewBcContainer.ps1
        # Clean the container for all apps. Apps will be installed by AL-Go
        foreach($app in $installedApps) { UnInstall-BcContainerApp ...; Unpublish-BcContainerApp ... }

    ...after which AL-Go re-publishes ~300 apps one by one:

        Publishing ...\Microsoft_Tests-Local_29.0.2147483647.78225.app
          Synchronizing Tests-Local on tenant default

    The apps in the artifact are built from a known BCApps commit. If the artifact carries that
    commit SHA, the build can compute exactly which apps changed between it and the commit being
    built, and only unpublish/publish those. Everything else stays exactly as the artifact
    restored it.

    Producer contract (NAV build): write the BCApps commit into the artifact manifest, e.g.

        {
          "country": "W1",
          "version": "29.0.53000.0",
          "platform": "29.0.52760.0",
          "database": "Demo Database BC (29-0).bak",
          "bcAppsCommit": "2b72269851ab0c2e2f9d4d8e0e0a1b2c3d4e5f60",
          "bcAppsBranch": "main"
        }

    Consumer (this module): read the SHA, `git diff` it against the commit being built, map the
    changed files to apps, expand to dependents, and hand that list to the container hooks.

.NOTES
    Anything that cannot be proven safe falls back to today's behavior (clean the container and
    publish everything): unknown/unreachable SHA, non-Default build mode, changes matching
    fullBuildPatterns, or a change set so large that reuse buys nothing.
#>

$ErrorActionPreference = "Stop"

# Manifest property names accepted for the BCApps commit, in priority order.
$script:CommitPropertyNames = @('bcAppsCommit', 'bcAppsCommitSha', 'applicationCommit', 'sourceCommit')

#region Artifact manifest

<#
.SYNOPSIS
    Locates the local folder of a downloaded BC artifact.
.DESCRIPTION
    Resolves the path inside the artifacts cache from the artifact url. By the time this is
    called the container has already been created from the artifact, so it is always cached -
    downloading is only attempted when -AllowDownload is given.
.OUTPUTS
    The artifact folder path, or $null when it cannot be determined.
#>
function Get-ArtifactFolder {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $ArtifactUrl,
        [string] $ArtifactsCacheFolder = '',
        [switch] $AllowDownload
    )

    if (-not $ArtifactsCacheFolder) {
        $configVariable = Get-Variable -Name 'bcContainerHelperConfig' -Scope Global -ErrorAction SilentlyContinue
        if ($null -ne $configVariable) {
            $ArtifactsCacheFolder = $configVariable.Value.bcartifactsCacheFolder
        }
    }

    if ($ArtifactsCacheFolder) {
        # https://<host>/sandbox/29.0.53000.0/w1?sas -> <cache>\sandbox\29.0.53000.0\w1
        $path = ([uri]$ArtifactUrl).AbsolutePath.Trim('/')
        $folder = Join-Path $ArtifactsCacheFolder ($path -replace '/', '\')
        if (Test-Path $folder) {
            return $folder
        }
        Write-Host "ARTIFACT BASELINE: '$folder' is not in the artifacts cache"
    }

    if ($AllowDownload -and (Get-Command -Name 'Download-Artifacts' -ErrorAction SilentlyContinue)) {
        try {
            $folders = @(Download-Artifacts -artifactUrl $ArtifactUrl)
            if ($folders.Count -gt 0 -and $folders[0]) {
                return $folders[0]
            }
        }
        catch {
            Write-Host "ARTIFACT BASELINE: Download-Artifacts failed - $($_.Exception.Message)"
        }
    }

    return $null
}

<#
.SYNOPSIS
    Reads the manifest.json of a downloaded BC artifact.
.OUTPUTS
    PSCustomObject, or $null when there is no manifest.
#>
function Get-ArtifactManifest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $ArtifactFolder
    )

    $manifestPath = Join-Path $ArtifactFolder 'manifest.json'
    if (-not (Test-Path $manifestPath)) {
        return $null
    }
    return Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
}

<#
.SYNOPSIS
    Extracts the BCApps commit SHA the artifact was built from.
.DESCRIPTION
    Accepts a few property spellings so the NAV side can pick one without breaking this side,
    and honors the BCAPPS_ARTIFACT_BASELINE_COMMIT environment variable, which allows the
    feature to be exercised before the NAV build stamps the manifest.
.OUTPUTS
    A 40-character lowercase SHA, or $null.
#>
function Get-ArtifactBaselineCommit {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [PSCustomObject] $Manifest
    )

    if ($env:BCAPPS_ARTIFACT_BASELINE_COMMIT) {
        Write-Host "ARTIFACT BASELINE: using commit from BCAPPS_ARTIFACT_BASELINE_COMMIT"
        return $env:BCAPPS_ARTIFACT_BASELINE_COMMIT.Trim().ToLowerInvariant()
    }

    if ($null -eq $Manifest) {
        return $null
    }

    foreach ($propertyName in $script:CommitPropertyNames) {
        if ($Manifest.PSObject.Properties.Name -contains $propertyName) {
            $value = "$($Manifest.$propertyName)".Trim()
            if ($value -match '^[0-9a-fA-F]{40}$') {
                return $value.ToLowerInvariant()
            }
            if ($value) {
                Write-Host "ARTIFACT BASELINE: manifest property '$propertyName' is not a full SHA ('$value')"
            }
        }
    }

    return $null
}

#endregion

#region Git

<#
.SYNOPSIS
    Makes sure a commit is present locally, fetching it when the clone is shallow.
.OUTPUTS
    $true when the commit can be diffed against.
#>
function Test-CommitAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Sha,
        [string] $BaseFolder = '.'
    )

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        Push-Location $BaseFolder
        try {
            git cat-file -e "$Sha^{commit}" 2>$null
            if ($LASTEXITCODE -eq 0) { return $true }

            Write-Host "ARTIFACT BASELINE: commit $Sha not in the local clone, fetching it"
            git fetch origin $Sha --depth=1 2>$null | Out-Null

            git cat-file -e "$Sha^{commit}" 2>$null
            return ($LASTEXITCODE -eq 0)
        }
        finally {
            Pop-Location
        }
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

<#
.SYNOPSIS
    Returns the files that changed between the baseline commit and the commit being built.
.OUTPUTS
    String[] of repo-relative paths, or $null when the diff could not be produced.
#>
function Get-ChangedFilesSinceCommit {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $BaselineCommit,
        [string] $HeadSha = '',
        [string] $BaseFolder = '.'
    )

    if (-not $HeadSha) {
        $HeadSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA } else { 'HEAD' }
    }

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        Push-Location $BaseFolder
        try {
            $files = @(git diff --name-only $BaselineCommit $HeadSha 2>$null)
            if ($LASTEXITCODE -ne 0) {
                Write-Host "ARTIFACT BASELINE: git diff $BaselineCommit..$HeadSha failed (exit $LASTEXITCODE)"
                return $null
            }
            # The comma keeps an empty diff an (empty) array instead of collapsing it to $null,
            # which is how "nothing changed" is told apart from "the diff failed".
            return ,[string[]]$files
        }
        finally {
            Pop-Location
        }
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

#endregion

#region Baseline resolution

<#
.SYNOPSIS
    Maps changed files to the set of app names that must be refreshed in the container.
.DESCRIPTION
    Reuses the dependency graph from BuildOptimization.psm1: each changed file is mapped to the
    app that owns it, and the set is expanded downstream so that everything depending on a
    changed app is refreshed too.
.OUTPUTS
    PSCustomObject with IsUsable, Reason and ChangedAppNames.
#>
function Get-ChangedAppNames {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $ChangedFiles,
        [Parameter(Mandatory)]
        [string] $BaseFolder,
        [double] $MaxChangedRatio = 0.75,
        [hashtable] $Graph
    )

    Import-Module (Join-Path $PSScriptRoot 'BuildOptimization.psm1') -Force -DisableNameChecking

    $notUsable = { param($reason) [PSCustomObject]@{ IsUsable = $false; Reason = $reason; ChangedAppNames = @(); KnownAppNames = @() } }

    if ($ChangedFiles.Count -eq 0) {
        if (-not $Graph) {
            $Graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
        }
        return [PSCustomObject]@{
            IsUsable        = $true
            Reason          = 'Nothing changed since the artifact was built'
            ChangedAppNames = @()
            KnownAppNames   = @($Graph.Values | ForEach-Object { $_.Name } | Sort-Object -Unique)
        }
    }

    if (Test-FullBuildPatternsMatch -ChangedFiles $ChangedFiles -BaseFolder $BaseFolder) {
        return & $notUsable 'A changed file matches fullBuildPatterns - everything is rebuilt'
    }

    if (-not $Graph) {
        $Graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
    }

    $affectedIds = @(Get-AffectedApps -ChangedFiles $ChangedFiles -BaseFolder $BaseFolder -Graph $Graph)

    if ($affectedIds.Count -ge $Graph.Count) {
        return & $notUsable "All $($Graph.Count) apps are affected"
    }

    $ratio = if ($Graph.Count -gt 0) { [double]$affectedIds.Count / [double]$Graph.Count } else { 0 }
    if ($ratio -gt $MaxChangedRatio) {
        return & $notUsable "$($affectedIds.Count) of $($Graph.Count) apps affected ($([math]::Round($ratio * 100, 1))%) - more than the $([math]::Round($MaxChangedRatio * 100, 1))% limit"
    }

    $names = @()
    foreach ($id in $affectedIds) {
        if ($Graph.ContainsKey($id)) { $names += $Graph[$id].Name }
    }

    return [PSCustomObject]@{
        IsUsable        = $true
        Reason          = "$($affectedIds.Count) of $($Graph.Count) apps changed since the artifact"
        ChangedAppNames = @($names | Sort-Object -Unique)
        KnownAppNames   = @($Graph.Values | ForEach-Object { $_.Name } | Sort-Object -Unique)
    }
}
<#
.SYNOPSIS
    Decides whether the apps already published in the artifact database can be reused.
.OUTPUTS
    PSCustomObject with IsUsable, Reason, BaselineCommit and ChangedAppNames.
#>
function Resolve-ArtifactBaseline {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $ArtifactUrl,
        [Parameter(Mandatory)]
        [string] $BaseFolder,
        [string] $BuildMode = 'Default',
        [double] $MaxChangedRatio = 0.75
    )

    $result = [PSCustomObject]@{
        IsUsable        = $false
        Reason          = ''
        BaselineCommit  = ''
        ChangedAppNames = @()
        KnownAppNames   = @()
    }

    if ($env:BCAPPS_ARTIFACT_BASELINE -eq 'disabled') {
        $result.Reason = 'Disabled via BCAPPS_ARTIFACT_BASELINE=disabled'
        return $result
    }

    # Other build modes compile the apps with different preprocessor symbols, so the binaries in
    # the artifact are not equivalent to what this build would produce.
    if ($BuildMode -and $BuildMode -ne 'Default') {
        $result.Reason = "Build mode '$BuildMode' does not match the artifact build"
        return $result
    }

    $artifactFolder = Get-ArtifactFolder -ArtifactUrl $ArtifactUrl
    if (-not $artifactFolder) {
        $result.Reason = "Could not locate the local artifact folder for '$ArtifactUrl'"
        return $result
    }

    $manifest = Get-ArtifactManifest -ArtifactFolder $artifactFolder
    $baselineCommit = Get-ArtifactBaselineCommit -Manifest $manifest
    if (-not $baselineCommit) {
        $result.Reason = "The artifact manifest does not carry a BCApps commit (expected one of: $($script:CommitPropertyNames -join ', '))"
        return $result
    }
    $result.BaselineCommit = $baselineCommit

    if (-not (Test-CommitAvailable -Sha $baselineCommit -BaseFolder $BaseFolder)) {
        $result.Reason = "Artifact commit $baselineCommit is not reachable from this clone"
        return $result
    }

    $changedFiles = Get-ChangedFilesSinceCommit -BaselineCommit $baselineCommit -BaseFolder $BaseFolder
    if ($null -eq $changedFiles) {
        $result.Reason = "Could not diff against artifact commit $baselineCommit"
        return $result
    }

    Write-Host "ARTIFACT BASELINE: $($changedFiles.Count) file(s) changed since artifact commit $baselineCommit"

    $changed = Get-ChangedAppNames -ChangedFiles $changedFiles -BaseFolder $BaseFolder -MaxChangedRatio $MaxChangedRatio
    $result.IsUsable = $changed.IsUsable
    $result.Reason = $changed.Reason
    $result.ChangedAppNames = $changed.ChangedAppNames
    $result.KnownAppNames = $changed.KnownAppNames

    return $result
}

#endregion

#region Container reconciliation

<#
.SYNOPSIS
    Returns the app name encoded in an .app file name.
.DESCRIPTION
    AL-Go/BcContainerHelper name app files "<Publisher>_<Name>_<Version>.app", e.g.
    "Microsoft_Tests-Local_29.0.2147483647.78225.app" -> "Tests-Local".
.OUTPUTS
    The app name, or $null when the file name does not follow the convention.
#>
function Get-AppNameFromAppFile {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    if ($baseName -match '^(?<publisher>[^_]+)_(?<name>.+)_(?<version>\d+(\.\d+){1,3})$') {
        return $Matches['name']
    }
    return $null
}

<#
.SYNOPSIS
    Selects the apps currently in the container that have to be unpublished.
.DESCRIPTION
    Two groups are removed:
      - apps whose source changed since the artifact commit, and
      - apps the BCApps repository does not produce at all (when KnownAppNames is given).
    The second group keeps parity with the current behavior, where the container is emptied and
    only the apps built/downloaded by this build end up in it. Everything else stays published,
    installed and synchronized exactly as the artifact database had it.
.PARAMETER InstalledApps
    Output of Get-BcContainerAppInfo (needs at least a Name property), sorted DependenciesLast.
.PARAMETER KnownAppNames
    All app names the repository produces. Omit to keep apps that BCApps does not own.
.OUTPUTS
    The subset of InstalledApps to unpublish, in the order they were given.
#>
function Get-AppsToUnpublish {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $InstalledApps,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $ChangedAppNames,
        [string[]] $KnownAppNames
    )

    $changed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $ChangedAppNames) { [void]$changed.Add($name) }

    $known = $null
    if ($PSBoundParameters.ContainsKey('KnownAppNames') -and $null -ne $KnownAppNames) {
        $known = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($name in $KnownAppNames) { [void]$known.Add($name) }
    }

    return @($InstalledApps | Where-Object {
        $changed.Contains($_.Name) -or (($null -ne $known) -and (-not $known.Contains($_.Name)))
    })
}

<#
.SYNOPSIS
    Decides whether an .app file still has to be published into the container.
.DESCRIPTION
    Publish when the app changed since the artifact commit, or when the container does not have
    it at all (a new app, or a test app that the artifact database does not have published).
    Skip when the container already holds an equivalent, unchanged app.
.OUTPUTS
    $true to publish, $false to skip.
#>
function Test-ShouldPublishAppFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $AppFile,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $ChangedAppNames,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $ContainerAppNames
    )

    $appName = Get-AppNameFromAppFile -Path $AppFile
    if (-not $appName) {
        # Unknown naming convention - never skip.
        return $true
    }

    if ($ChangedAppNames -contains $appName) {
        return $true
    }

    if ($ContainerAppNames -notcontains $appName) {
        return $true
    }

    return $false
}

#endregion

#region Build state (shared between AL-Go hook invocations)

function Get-ArtifactBaselineStatePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $folder = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
    return (Join-Path $folder 'ArtifactBaseline.state.json')
}

function Set-ArtifactBaselineState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $State
    )

    $path = Get-ArtifactBaselineStatePath
    [PSCustomObject]$State | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8 -Force
    return $path
}

function Get-ArtifactBaselineState {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $path = Get-ArtifactBaselineStatePath
    if (-not (Test-Path $path)) {
        return $null
    }
    return Get-Content -Path $path -Raw | ConvertFrom-Json
}

function Clear-ArtifactBaselineState {
    [CmdletBinding()]
    param()

    $path = Get-ArtifactBaselineStatePath
    if (Test-Path $path) {
        Remove-Item -Path $path -Force
    }
}

#endregion

Export-ModuleMember -Function @(
    'Get-ArtifactFolder'
    'Get-ArtifactManifest'
    'Get-ArtifactBaselineCommit'
    'Test-CommitAvailable'
    'Get-ChangedFilesSinceCommit'
    'Get-ChangedAppNames'
    'Resolve-ArtifactBaseline'
    'Get-AppNameFromAppFile'
    'Get-AppsToUnpublish'
    'Test-ShouldPublishAppFile'
    'Get-ArtifactBaselineStatePath'
    'Set-ArtifactBaselineState'
    'Get-ArtifactBaselineState'
    'Clear-ArtifactBaselineState'
)
