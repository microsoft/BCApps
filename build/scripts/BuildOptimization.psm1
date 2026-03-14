<#
.SYNOPSIS
    Test-skip logic for CI/CD build optimization.
.DESCRIPTION
    Determines whether a test app should be skipped based on which files changed
    and the app dependency graph. Called from RunTestsInBcContainer.ps1.
#>

$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
    Builds a dependency graph from all app.json files under the given base folder.
.PARAMETER BaseFolder
    Root of the repository.
.OUTPUTS
    Hashtable keyed by lowercase app ID. Each value is a PSCustomObject with
    Id, Name, AppFolder, Dependencies (string[]), Dependents (List[string]).
#>
function Get-AppDependencyGraph {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    $graph = @{}
    $appJsonFiles = Get-ChildItem -Path $BaseFolder -Recurse -Filter 'app.json' -File |
        Where-Object { $_.FullName -notmatch '[\\/]\.buildartifacts[\\/]' }

    foreach ($file in $appJsonFiles) {
        $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        if (-not $json.id) { continue }

        $appId = $json.id.ToLowerInvariant()
        $depIds = @()
        if ($json.dependencies) {
            $depIds = @($json.dependencies | ForEach-Object { $_.id.ToLowerInvariant() })
        }

        $graph[$appId] = [PSCustomObject]@{
            Id           = $appId
            Name         = $json.name
            AppFolder    = $file.DirectoryName
            Dependencies = $depIds
            Dependents   = [System.Collections.Generic.List[string]]::new()
        }
    }

    foreach ($node in $graph.Values) {
        foreach ($depId in $node.Dependencies) {
            if ($graph.ContainsKey($depId)) {
                $graph[$depId].Dependents.Add($node.Id)
            }
        }
    }

    return $graph
}

<#
.SYNOPSIS
    Determines which app (if any) a file belongs to by walking up to the nearest app.json.
.PARAMETER FilePath
    Path to the changed file (absolute or relative to BaseFolder).
.PARAMETER BaseFolder
    Root of the repository.
.OUTPUTS
    The app ID (lowercase GUID) or $null if the file is not inside any app folder.
#>
function Get-AppForFile {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $FilePath,
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
        $FilePath = Join-Path $BaseFolder $FilePath
    }
    $FilePath = [System.IO.Path]::GetFullPath($FilePath)

    $dir = [System.IO.Path]::GetDirectoryName($FilePath)
    $baseFolderNorm = [System.IO.Path]::GetFullPath($BaseFolder).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    while ($dir -and $dir.Length -ge $baseFolderNorm.Length) {
        $candidate = Join-Path $dir 'app.json'
        if (Test-Path $candidate) {
            $json = Get-Content -Path $candidate -Raw | ConvertFrom-Json
            if ($json.id) { return $json.id.ToLowerInvariant() }
        }
        $parent = [System.IO.Path]::GetDirectoryName($dir)
        if ($parent -eq $dir) { break }
        $dir = $parent
    }

    return $null
}

<#
.SYNOPSIS
    Given changed files, computes the set of affected app IDs via downstream BFS.
.DESCRIPTION
    Maps each changed file to its app, then walks dependents (BFS) to find all
    apps that transitively depend on a changed app. Files under src/ that can't
    be mapped to an app trigger a full build (returns all app IDs).
.PARAMETER ChangedFiles
    Array of changed file paths (relative to BaseFolder or absolute).
.PARAMETER BaseFolder
    Root of the repository.
.PARAMETER Graph
    Pre-built dependency graph. If not provided, one is built from BaseFolder.
.OUTPUTS
    String array of affected app IDs (lowercase GUIDs).
#>
function Get-AffectedApps {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string[]] $ChangedFiles,
        [Parameter(Mandatory)]
        [string] $BaseFolder,
        [Parameter()]
        [hashtable] $Graph
    )

    if (-not $Graph) {
        $Graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
    }

    # Map changed files to apps
    $directlyChanged = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($file in $ChangedFiles) {
        $appId = Get-AppForFile -FilePath $file -BaseFolder $BaseFolder
        if ($appId) {
            [void]$directlyChanged.Add($appId)
        } elseif ($file.Replace('\', '/') -match '(^|/)src/') {
            # Unmapped file under src/ — safety fallback to full build
            return @($Graph.Keys)
        }
    }

    if ($directlyChanged.Count -eq 0) { return @() }

    # BFS downstream: changed apps + everything that depends on them
    $affected = [System.Collections.Generic.HashSet[string]]::new()
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($appId in $directlyChanged) {
        if ($Graph.ContainsKey($appId)) { $queue.Enqueue($appId) }
    }

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($affected.Contains($current)) { continue }
        [void]$affected.Add($current)
        if ($Graph.ContainsKey($current)) {
            foreach ($dep in $Graph[$current].Dependents) {
                if (-not $affected.Contains($dep)) { $queue.Enqueue($dep) }
            }
        }
    }

    return @($affected)
}

<#
.SYNOPSIS
    Detects changed files from the GitHub Actions CI environment.
.DESCRIPTION
    Uses git diff against the base branch (for PRs) or previous commit (for push).
    Returns $null when changed files cannot be determined (local, workflow_dispatch, git failure).
.OUTPUTS
    String array of changed file paths relative to repo root, or $null.
#>
function Get-ChangedFilesForCI {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    if (-not $env:GITHUB_ACTIONS -or $env:GITHUB_EVENT_NAME -eq 'workflow_dispatch') {
        return $null
    }

    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($env:GITHUB_EVENT_NAME -match 'pull_request|merge_group') {
            $base = if ($env:GITHUB_BASE_REF) { $env:GITHUB_BASE_REF } else { 'main' }
            git fetch origin $base --depth=1 2>$null
            $files = @(git diff --name-only "origin/$base...HEAD" 2>$null)
        }
        elseif ($env:GITHUB_EVENT_NAME -eq 'push') {
            git fetch --deepen=1 2>$null
            $files = @(git diff --name-only HEAD~1 HEAD 2>$null)
        }

        if ($LASTEXITCODE -eq 0 -and $files.Count -gt 0) { return $files }
    }
    finally {
        $ErrorActionPreference = $prevErrorAction
    }
    return $null
}

<#
.SYNOPSIS
    Determines whether tests for a given app should be skipped.
.DESCRIPTION
    Called from RunTestsInBcContainer.ps1 for each test app. Computes the affected
    app set from changed files and the dependency graph, then checks whether the
    given app name is in that set. Returns $true to skip, $false to run.
.PARAMETER AppName
    The display name of the test app (from $parameters["appName"]).
.PARAMETER BaseFolder
    Root of the repository.
.OUTPUTS
    $true if the test app should be skipped, $false if it should run.
#>
function Test-ShouldSkipTestApp {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $AppName,
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    if ($env:BUILD_OPTIMIZATION_DISABLED -eq 'true') { return $false }
    if (-not $env:GITHUB_ACTIONS) { return $false }
    if ($env:GITHUB_EVENT_NAME -eq 'workflow_dispatch') { return $false }

    $changedFiles = Get-ChangedFilesForCI
    if (-not $changedFiles) { return $false }

    $graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
    $affectedIds = Get-AffectedApps -ChangedFiles $changedFiles -BaseFolder $BaseFolder -Graph $graph

    # Full build triggered (unmapped src file or all apps affected)
    if ($affectedIds.Count -ge $graph.Count) { return $false }

    $affectedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $affectedIds) {
        if ($graph.ContainsKey($id)) { [void]$affectedNames.Add($graph[$id].Name) }
    }

    if (-not $affectedNames.Contains($AppName)) {
        Write-Host "BUILD OPTIMIZATION: Skipping tests for '$AppName' - not in affected set ($($affectedNames.Count) affected apps)"
        return $true
    }
    return $false
}

Export-ModuleMember -Function Get-AppDependencyGraph, Get-AppForFile, Get-AffectedApps, Get-ChangedFilesForCI, Test-ShouldSkipTestApp
