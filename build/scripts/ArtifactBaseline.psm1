<#
.SYNOPSIS
    PROTOTYPE: reuse the apps that are already published in the BC artifact database.

.DESCRIPTION
    A BC (sandbox) artifact ships a demo database in which every Microsoft app is already
    published, installed and synchronized. Every BCApps test build restores that database - and
    then throws all of it away:

        # NewBcContainer.ps1
        # Clean the container for all apps. Apps will be installed by AL-Go
        foreach($app in $installedApps) { UnInstall-BcContainerApp ...; Unpublish-BcContainerApp ... }

    ...after which AL-Go re-publishes ~300 apps one by one. Publishing is the expensive part: the
    .app file is uploaded, extracted, validated and schema-synced.

    The apps in the artifact are built from a known BCApps commit. When the artifact manifest
    carries that commit (see Eng\Core\Lib\BCAppsVersion.psm1 in the NAV repository), this module
    computes which apps changed between it and the commit being built, so the build can keep the
    unchanged ones instead of republishing them.

    IMPORTANT - what "keeping" means. Retained apps are UNINSTALLED but left published and
    synchronized. That is exactly the state AL-Go's publish step leaves an app in today
    (install = $false), so everything downstream is unchanged:

      - ImportTestDataInBcContainer.ps1 keeps full control of install order, which the Legacy
        test type depends on (base apps + DemoTool first, demo data, then the rest);
      - test discovery, which every test project drives from the INSTALLED apps
        ("runTestsInAllInstalledTestApps": true), sees exactly the apps it sees today.

    Only the publish/sync work is skipped - the container still ends up in today's shape.

.NOTES
    Anything that cannot be proven safe falls back to today's behavior (clean the container and
    publish everything): unknown/unreachable commit, a build mode that changes compilation,
    changes matching the full-build patterns, or a change set so large that reuse buys nothing.
#>

$ErrorActionPreference = "Stop"

# Manifest property names accepted for the BCApps commit, in priority order.
$script:CommitPropertyNames = @('bcAppsCommit', 'bcAppsCommitSha', 'applicationCommit', 'sourceCommit')

# Apps that must never be present in a test container, regardless of the artifact.
# "Prevent Metadata Updates Library" changes runtime behavior and "Library - No Transactions"
# is a test-only shim; both are built from this repository, so they would otherwise look like
# ordinary reusable apps.
$script:AppsNeverInContainer = @(
    'Library - No Transactions',
    'Prevent Metadata Updates Library'
)

# Changed files that force a full rebuild of the container, on top of the repository's
# fullBuildPatterns. fullBuildPatterns is tuned for AL-Go's compile skipping; these are the
# inputs that change how apps are COMPILED or which apps a project builds, and therefore break
# equivalence with the binaries in the artifact.
$script:ExtraFullBuildPatterns = @(
    '.github/*',
    '.github/**/*',
    'build/projects/*/.AL-Go/settings.json',
    '.AL-Go/settings.json'
)

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
        # BcContainerHelper exposes this as a module variable; do not constrain the scope.
        $configVariable = Get-Variable -Name 'bcContainerHelperConfig' -ErrorAction SilentlyContinue
        if ($null -ne $configVariable -and $null -ne $configVariable.Value) {
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
    Accepts a few property spellings so the producer can pick one without breaking this side.
    BCAPPS_ARTIFACT_BASELINE_COMMIT overrides the manifest for local experimentation, but is
    ignored in GitHub Actions: in CI the manifest must be the only source of truth, otherwise a
    stray environment variable could silently pin the build to an arbitrary commit.
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
        if ($env:GITHUB_ACTIONS) {
            Write-Host "ARTIFACT BASELINE: ignoring BCAPPS_ARTIFACT_BASELINE_COMMIT in CI"
        }
        else {
            Write-Host "ARTIFACT BASELINE: using commit from BCAPPS_ARTIFACT_BASELINE_COMMIT"
            return $env:BCAPPS_ARTIFACT_BASELINE_COMMIT.Trim().ToLowerInvariant()
        }
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
        Push-Location $BaseFolder -ErrorAction Stop
        try {
            git cat-file -e "$Sha^{commit}" 2>$null
            if ($LASTEXITCODE -eq 0) { return $true }

            # Only fetch into an already-shallow clone (CI). Fetching a single commit into a
            # developer's complete clone would mark it shallow and break later history commands.
            $isShallow = (git rev-parse --is-shallow-repository 2>$null)
            if ("$isShallow".Trim() -ne 'true') {
                Write-Host "ARTIFACT BASELINE: commit $Sha is not in this clone (not fetching into a complete clone)"
                return $false
            }

            Write-Host "ARTIFACT BASELINE: commit $Sha not in the shallow clone, fetching it"
            git fetch origin $Sha --depth=1 2>$null | Out-Null

            git cat-file -e "$Sha^{commit}" 2>$null
            return ($LASTEXITCODE -eq 0)
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-Host "ARTIFACT BASELINE: could not check commit availability - $($_.Exception.Message)"
        return $false
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

<#
.SYNOPSIS
    Returns the files that changed between the baseline commit and the commit being built.
.OUTPUTS
    String[] of repo-relative paths (empty when nothing changed), or $null when the diff could
    not be produced.
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
        Push-Location $BaseFolder -ErrorAction Stop
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
    catch {
        Write-Host "ARTIFACT BASELINE: could not diff against $BaselineCommit - $($_.Exception.Message)"
        return $null
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

#endregion

#region Baseline resolution

<#
.SYNOPSIS
    Tells whether a build mode compiles the apps differently from the artifact build.
.DESCRIPTION
    Derived from the settings rather than hard-coded: any build mode whose conditional settings
    define preprocessorSymbols produces binaries that are not equivalent to the ones in the
    artifact, so the artifact's apps cannot be reused.

    Note that no container-building project uses the 'Default' build mode - the test projects
    build in IntegrationTests / UncategorizedTests / LegacyTestsBucket1 / LegacyTestsBucket2,
    none of which change compilation.
.OUTPUTS
    $true when the build mode changes compilation.
#>
function Test-BuildModeChangesCompilation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string] $BuildMode,
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    if (-not $BuildMode) { return $false }

    $settingsFiles = @(Join-Path $BaseFolder '.github/AL-Go-Settings.json')
    $settingsFiles += @(Get-ChildItem -Path (Join-Path $BaseFolder 'build/projects') -Filter 'settings.json' -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })

    foreach ($settingsFile in $settingsFiles) {
        if (-not (Test-Path $settingsFile)) { continue }
        try {
            $settings = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
        }
        catch {
            continue
        }
        if (-not $settings.PSObject.Properties.Name -contains 'conditionalSettings') { continue }

        foreach ($conditional in @($settings.conditionalSettings)) {
            if ($null -eq $conditional) { continue }
            if (@($conditional.buildModes) -notcontains $BuildMode) { continue }
            if ($null -ne $conditional.settings -and ($conditional.settings.PSObject.Properties.Name -contains 'preprocessorSymbols')) {
                return $true
            }
        }
    }

    return $false
}

<#
.SYNOPSIS
    Maps changed files to the set of apps that must be refreshed in the container.
.DESCRIPTION
    Reuses the dependency graph from BuildOptimization.psm1: each changed file is mapped to the
    app that owns it, and the set is expanded downstream so that everything depending on a
    changed app is refreshed too.
.OUTPUTS
    PSCustomObject with IsUsable, Reason, ChangedApps and KnownApps (both "Publisher_Name").
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

    Import-Module (Join-Path $PSScriptRoot 'BuildOptimization.psm1') -DisableNameChecking

    $notUsable = { param($reason) [PSCustomObject]@{ IsUsable = $false; Reason = $reason; ChangedApps = @(); KnownApps = @() } }

    if (-not $Graph) {
        $Graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
    }
    $knownApps = @($Graph.Values | ForEach-Object { Get-AppKey -Publisher $_.Publisher -Name $_.Name } | Sort-Object -Unique)

    if ($ChangedFiles.Count -eq 0) {
        return [PSCustomObject]@{
            IsUsable    = $true
            Reason      = 'Nothing changed since the artifact was built'
            ChangedApps = @()
            KnownApps   = $knownApps
        }
    }

    if (Test-FullBuildPatternsMatch -ChangedFiles $ChangedFiles -BaseFolder $BaseFolder) {
        return & $notUsable 'A changed file matches fullBuildPatterns - everything is rebuilt'
    }

    foreach ($file in $ChangedFiles) {
        $normalized = $file.Replace('\', '/')
        foreach ($pattern in $script:ExtraFullBuildPatterns) {
            if ($normalized -like $pattern) {
                return & $notUsable "Changed file '$normalized' can change how apps are compiled (matches '$pattern')"
            }
        }
    }

    $affectedIds = @(Get-AffectedApps -ChangedFiles $ChangedFiles -BaseFolder $BaseFolder -Graph $Graph)

    if ($affectedIds.Count -ge $Graph.Count) {
        return & $notUsable "All $($Graph.Count) apps are affected"
    }

    $ratio = if ($Graph.Count -gt 0) { [double]$affectedIds.Count / [double]$Graph.Count } else { 0 }
    if ($ratio -gt $MaxChangedRatio) {
        return & $notUsable "$($affectedIds.Count) of $($Graph.Count) apps affected ($([math]::Round($ratio * 100, 1))%) - more than the $([math]::Round($MaxChangedRatio * 100, 1))% limit"
    }

    $changedApps = @()
    foreach ($id in $affectedIds) {
        if ($Graph.ContainsKey($id)) {
            $changedApps += Get-AppKey -Publisher $Graph[$id].Publisher -Name $Graph[$id].Name
        }
    }

    return [PSCustomObject]@{
        IsUsable    = $true
        Reason      = "$($affectedIds.Count) of $($Graph.Count) apps changed since the artifact"
        ChangedApps = @($changedApps | Sort-Object -Unique)
        KnownApps   = $knownApps
    }
}

<#
.SYNOPSIS
    Decides whether the apps already published in the artifact database can be reused.
.OUTPUTS
    PSCustomObject with IsUsable, Reason, BaselineCommit, ChangedApps and KnownApps.
#>
function Resolve-ArtifactBaseline {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $ArtifactUrl,
        [Parameter(Mandatory)]
        [string] $BaseFolder,
        [string] $BuildMode = '',
        [double] $MaxChangedRatio = 0.75
    )

    $result = [PSCustomObject]@{
        IsUsable       = $false
        Reason         = ''
        BaselineCommit = ''
        ChangedApps    = @()
        KnownApps      = @()
    }

    if ($env:BCAPPS_ARTIFACT_BASELINE -eq 'disabled') {
        $result.Reason = 'Disabled via BCAPPS_ARTIFACT_BASELINE=disabled'
        return $result
    }

    if (Test-BuildModeChangesCompilation -BuildMode $BuildMode -BaseFolder $BaseFolder) {
        $result.Reason = "Build mode '$BuildMode' compiles apps with different preprocessor symbols than the artifact"
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
    $result.ChangedApps = $changed.ChangedApps
    $result.KnownApps = $changed.KnownApps

    return $result
}

#endregion

#region Container reconciliation

<#
.SYNOPSIS
    Builds the key that identifies an app across the container and the repository.
.DESCRIPTION
    Name alone is ambiguous: this repository contains several apps that share a name
    (for example 'Tests-Local' in the BE, MX and W1 layers, and 'Data Archive' in both
    src/Apps and src/System Application). Publisher + name is what BC and the .app file
    naming convention agree on.
#>
function Get-AppKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] $Publisher,
        [Parameter(Mandatory)]
        [string] $Name
    )

    if (-not $Publisher) { $Publisher = 'Microsoft' }
    return "$($Publisher.Trim())_$($Name.Trim())"
}

<#
.SYNOPSIS
    Returns publisher, name and version encoded in an .app file name.
.DESCRIPTION
    AL-Go/BcContainerHelper name app files "<Publisher>_<Name>_<Version>.app", e.g.
    "Microsoft_Tests-Local_29.0.2147483647.78225.app".
.OUTPUTS
    PSCustomObject with Publisher, Name, Version and Key - or $null when the file name does not
    follow the convention.
#>
function Get-AppFileIdentity {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    if ($baseName -match '^(?<publisher>[^_]+)_(?<name>.+)_(?<version>\d+(\.\d+){1,3})$') {
        return [PSCustomObject]@{
            Publisher = $Matches['publisher']
            Name      = $Matches['name']
            Version   = $Matches['version']
            Key       = Get-AppKey -Publisher $Matches['publisher'] -Name $Matches['name']
        }
    }
    return $null
}

<#
.SYNOPSIS
    Returns the apps that must never be left in a test container.
#>
function Get-AppsNeverInContainer {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return [string[]]$script:AppsNeverInContainer
}

<#
.SYNOPSIS
    Splits the apps currently in the container into the ones to unpublish and the ones to keep.
.DESCRIPTION
    Unpublish an app when its source changed since the artifact commit, when this repository does
    not produce it at all, or when it must never be in a test container. Everything else is kept
    published and synchronized - the caller uninstalls it so that the container reaches the same
    state AL-Go's publish step produces today.
.PARAMETER InstalledApps
    Output of Get-BcContainerAppInfo (needs Name and Publisher), sorted DependenciesLast.
.PARAMETER ChangedApps
    App keys ("Publisher_Name") whose source changed since the artifact commit.
.PARAMETER KnownApps
    App keys this repository produces. Apps outside this set are unpublished, matching today's
    behavior where the container only ever holds apps this build publishes.
.OUTPUTS
    PSCustomObject with ToUnpublish and ToKeep, preserving the input order.
#>
function Split-ContainerApps {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $InstalledApps,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $ChangedApps,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $KnownApps
    )

    $changed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in $ChangedApps) { [void]$changed.Add($key) }

    $known = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in $KnownApps) { [void]$known.Add($key) }

    $never = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $script:AppsNeverInContainer) { [void]$never.Add($name) }

    $toUnpublish = @()
    $toKeep = @()

    foreach ($app in $InstalledApps) {
        $key = Get-AppKey -Publisher $app.Publisher -Name $app.Name
        if ($never.Contains($app.Name) -or $changed.Contains($key) -or (-not $known.Contains($key))) {
            $toUnpublish += $app
        }
        else {
            $toKeep += $app
        }
    }

    return [PSCustomObject]@{
        ToUnpublish = @($toUnpublish)
        ToKeep      = @($toKeep)
    }
}

<#
.SYNOPSIS
    Decides whether an .app file still has to be published into the container.
.DESCRIPTION
    Publish when the app changed since the artifact commit, or when the container does not hold
    it. Skip only when the container already has an equivalent, unchanged app published.
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
        [string[]] $ChangedApps,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $RetainedApps
    )

    $identity = Get-AppFileIdentity -Path $AppFile
    if ($null -eq $identity) {
        # Unknown naming convention - never skip.
        return $true
    }

    if ($ChangedApps -contains $identity.Key) {
        return $true
    }

    return ($RetainedApps -notcontains $identity.Key)
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

<#
.SYNOPSIS
    Persists the decision so the later publish-hook invocations can act on it.
.DESCRIPTION
    The state is stamped with the container and the workflow run, because the publish hook runs
    in a separate process and the temp folder is shared on a local machine and on reused
    runners. State that does not belong to the current container must never be trusted - acting
    on it would silently skip publishing apps.
#>
function Set-ArtifactBaselineState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $State,
        [Parameter(Mandatory)]
        [string] $ContainerName
    )

    $State['ContainerName'] = $ContainerName
    $State['RunId'] = "$env:GITHUB_RUN_ID/$env:GITHUB_RUN_ATTEMPT"

    $path = Get-ArtifactBaselineStatePath
    [PSCustomObject]$State | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8 -Force
    return $path
}

<#
.SYNOPSIS
    Reads the decision written by the container hook, for this container only.
.OUTPUTS
    The state object, or $null when there is none or it belongs to another container/run.
#>
function Get-ArtifactBaselineState {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $ContainerName
    )

    $path = Get-ArtifactBaselineStatePath
    if (-not (Test-Path $path)) {
        return $null
    }

    $state = Get-Content -Path $path -Raw | ConvertFrom-Json

    if ($state.ContainerName -ne $ContainerName) {
        Write-Host "ARTIFACT BASELINE: ignoring state for container '$($state.ContainerName)' (this is '$ContainerName')"
        return $null
    }

    $runId = "$env:GITHUB_RUN_ID/$env:GITHUB_RUN_ATTEMPT"
    if ($state.RunId -ne $runId) {
        Write-Host "ARTIFACT BASELINE: ignoring state from run '$($state.RunId)' (this is '$runId')"
        return $null
    }

    return $state
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
    'Test-BuildModeChangesCompilation'
    'Get-ChangedAppNames'
    'Resolve-ArtifactBaseline'
    'Get-AppKey'
    'Get-AppFileIdentity'
    'Get-AppsNeverInContainer'
    'Split-ContainerApps'
    'Test-ShouldPublishAppFile'
    'Get-ArtifactBaselineStatePath'
    'Set-ArtifactBaselineState'
    'Get-ArtifactBaselineState'
    'Clear-ArtifactBaselineState'
)
