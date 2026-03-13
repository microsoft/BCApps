<#
.SYNOPSIS
    App-level dependency graph filtering for CI/CD build optimization.
.DESCRIPTION
    Builds a dependency graph from all app.json files in the repository and uses it
    to determine the minimal set of apps to compile and test when only a subset of
    files have changed. This dramatically reduces build times for large projects.
#>

$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
    Builds a dependency graph from all app.json files under the given base folder.
.PARAMETER BaseFolder
    Root of the repository (defaults to Get-BaseFolder if available).
.OUTPUTS
    Hashtable[string -> PSCustomObject] keyed by lowercase app ID. Each node has:
      Id, Name, AppJsonPath, AppFolder, Dependencies (string[]), Dependents (string[]).
#>
function Get-AppDependencyGraph {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $BaseFolder
    )

    $graph = @{}

    # Find all app.json files
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
            AppJsonPath  = $file.FullName
            AppFolder    = $file.DirectoryName
            Dependencies = $depIds
            Dependents   = [System.Collections.Generic.List[string]]::new()
        }
    }

    # Build reverse edges (Dependents)
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
    Determines which app (if any) a file belongs to.
.PARAMETER FilePath
    Path to the changed file (absolute or relative to BaseFolder).
.PARAMETER BaseFolder
    Root of the repository.
.OUTPUTS
    The app ID (lowercase GUID) or $null if the file is not inside any app folder.
#>
function Get-AppForFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,
        [Parameter(Mandatory = $true)]
        [string] $BaseFolder
    )

    # Make absolute
    if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
        $FilePath = Join-Path $BaseFolder $FilePath
    }
    $FilePath = [System.IO.Path]::GetFullPath($FilePath)

    # Walk up looking for app.json
    $dir = [System.IO.Path]::GetDirectoryName($FilePath)
    $baseFolderNorm = [System.IO.Path]::GetFullPath($BaseFolder).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    while ($dir -and $dir.Length -ge $baseFolderNorm.Length) {
        $candidate = Join-Path $dir 'app.json'
        if (Test-Path $candidate) {
            $json = Get-Content -Path $candidate -Raw | ConvertFrom-Json
            if ($json.id) {
                return $json.id.ToLowerInvariant()
            }
        }
        $parent = [System.IO.Path]::GetDirectoryName($dir)
        if ($parent -eq $dir) { break }
        $dir = $parent
    }

    return $null
}

<#
.SYNOPSIS
    Given changed files, computes the full set of affected app IDs including
    downstream dependents (with firewall) and compilation closure.
.PARAMETER ChangedFiles
    Array of changed file paths (relative to BaseFolder or absolute).
.PARAMETER BaseFolder
    Root of the repository.
.PARAMETER FirewallAppIds
    App IDs that should NOT propagate downstream. Defaults to System Application.
.OUTPUTS
    String array of affected app IDs (lowercase GUIDs).
#>
function Get-AffectedApps {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $ChangedFiles,
        [Parameter(Mandatory = $true)]
        [string] $BaseFolder,
        [Parameter(Mandatory = $false)]
        [string[]] $FirewallAppIds = @()
    )

    $graph = Get-AppDependencyGraph -BaseFolder $BaseFolder

    # Normalize firewall IDs
    $firewallSet = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fid in $FirewallAppIds) {
        [void]$firewallSet.Add($fid.ToLowerInvariant())
    }

    # Map changed files to apps
    $directlyChanged = [System.Collections.Generic.HashSet[string]]::new()
    $hasUnmappedSrcFile = $false
    foreach ($file in $ChangedFiles) {
        $appId = Get-AppForFile -FilePath $file -BaseFolder $BaseFolder
        if ($appId) {
            [void]$directlyChanged.Add($appId)
        } else {
            # Only trigger full build for unmapped files inside src/ — these could
            # affect app compilation (e.g., shared rulesets, dotnet packages).
            # Files outside src/ (workflows, build scripts, docs) are infrastructure
            # and are already handled by fullBuildPatterns in the workflow.
            $normalizedFile = $file.Replace('\', '/')
            if ($normalizedFile -like 'src/*' -or $normalizedFile -like '*/src/*') {
                $hasUnmappedSrcFile = $true
            }
        }
    }

    # If any source file couldn't be mapped to an app, return all apps (safety)
    if ($hasUnmappedSrcFile) {
        return @($graph.Keys)
    }

    # If no changed files mapped to any app, nothing to filter
    if ($directlyChanged.Count -eq 0) {
        return @()
    }

    # BFS downstream (dependents) — apps that consume the changed app
    $visited = [System.Collections.Generic.HashSet[string]]::new()
    $queue = [System.Collections.Generic.Queue[string]]::new()

    foreach ($appId in $directlyChanged) {
        if ($graph.ContainsKey($appId)) {
            $queue.Enqueue($appId)
        }
    }

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($visited.Contains($current)) { continue }
        [void]$visited.Add($current)

        # Don't propagate through firewall nodes
        if ($firewallSet.Contains($current)) { continue }

        if ($graph.ContainsKey($current)) {
            foreach ($dependent in $graph[$current].Dependents) {
                if (-not $visited.Contains($dependent)) {
                    $queue.Enqueue($dependent)
                }
            }
        }
    }

    # BFS upstream (dependencies) — walk from each directly changed app
    # up through its dependencies to the root, so the full chain is tested.
    # Uses a separate visited set since the downstream BFS already marked
    # the changed apps as visited.
    $upstreamVisited = [System.Collections.Generic.HashSet[string]]::new()
    $upstreamQueue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($appId in $directlyChanged) {
        if ($graph.ContainsKey($appId)) {
            $upstreamQueue.Enqueue($appId)
        }
    }

    while ($upstreamQueue.Count -gt 0) {
        $current = $upstreamQueue.Dequeue()
        if ($upstreamVisited.Contains($current)) { continue }
        [void]$upstreamVisited.Add($current)
        [void]$visited.Add($current)

        if ($graph.ContainsKey($current)) {
            foreach ($depId in $graph[$current].Dependencies) {
                if (-not $upstreamVisited.Contains($depId)) {
                    $upstreamQueue.Enqueue($depId)
                }
            }
        }
    }

    # System Application is implicitly available to all apps (even without a declared
    # dependency). If any System Application module is affected, include the umbrella
    # so it gets compiled and tested too.
    $sysAppUmbrellaId = '63ca2fa4-4f03-4f2b-a480-172fef340d3f'
    if ($graph.ContainsKey($sysAppUmbrellaId) -and -not $visited.Contains($sysAppUmbrellaId)) {
        $sysAppFolder = $graph[$sysAppUmbrellaId].AppFolder
        foreach ($appId in @($visited)) {
            if ($graph.ContainsKey($appId) -and $graph[$appId].AppFolder.StartsWith($sysAppFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
                [void]$visited.Add($sysAppUmbrellaId)
                break
            }
        }
    }

    return @($visited)
}

<#
.SYNOPSIS
    Resolves glob patterns from a project's settings relative to the .AL-Go directory.
.DESCRIPTION
    Takes the appFolders/testFolders patterns (which are relative to the .AL-Go directory)
    and resolves them to actual filesystem paths.
#>
function Resolve-ProjectGlobs {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ProjectDir,
        [Parameter(Mandatory = $false)]
        [string[]] $Patterns = @()
    )

    $resolved = @()
    if ($Patterns.Count -eq 0) { return $resolved }

    # AL-Go resolves appFolders/testFolders relative to the project directory
    $savedLocation = Get-Location
    try {
        Set-Location -LiteralPath $ProjectDir
        foreach ($pattern in $Patterns) {
            $items = @(Resolve-Path $pattern -ErrorAction SilentlyContinue)
            foreach ($item in $items) {
                if (Test-Path -LiteralPath $item.Path -PathType Container) {
                    $resolved += $item.Path
                }
            }
        }
    } finally {
        Set-Location $savedLocation
    }
    return $resolved
}

<#
.SYNOPSIS
    Finds which app ID (if any) lives in a given folder by looking for app.json.
#>
function Get-AppIdForFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FolderPath
    )

    $appJsonPath = Join-Path $FolderPath 'app.json'
    if (Test-Path $appJsonPath) {
        $json = Get-Content -Path $appJsonPath -Raw | ConvertFrom-Json
        if ($json.id) {
            return $json.id.ToLowerInvariant()
        }
    }
    return $null
}

<#
.SYNOPSIS
    Computes a relative path from one directory to another (PS 5.1 compatible).
#>
function Get-RelativePathCompat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $From,
        [Parameter(Mandatory = $true)]
        [string] $To
    )

    $fromUri = [uri]::new($From.TrimEnd('\', '/') + '\')
    $toUri = [uri]::new($To.TrimEnd('\', '/') + '\')
    $relativeUri = $fromUri.MakeRelativeUri($toUri).ToString()
    # MakeRelativeUri returns URI-encoded forward-slash paths; decode and trim trailing slash
    $decoded = [uri]::UnescapeDataString($relativeUri).TrimEnd('/')
    return $decoded
}

<#
.SYNOPSIS
    Converts an absolute folder path back to the relative pattern used in settings.json.
.DESCRIPTION
    Given a resolved folder path and the .AL-Go directory, produces the relative path
    with forward slashes that matches the convention in settings.json (e.g., "../../../src/Apps/W1/EDocument/App").
#>
function Get-RelativeFolderPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FolderPath,
        [Parameter(Mandatory = $true)]
        [string] $ALGoDir
    )

    return Get-RelativePathCompat -From $ALGoDir -To $FolderPath
}

<#
.SYNOPSIS
    For a given project, computes the compilation closure — adds in-project dependencies
    of affected apps so the compiler has all required symbols.
.PARAMETER AffectedAppIds
    Set of affected app IDs (will be modified in place).
.PARAMETER ProjectAppIds
    Set of all app IDs in this project.
.PARAMETER Graph
    The full dependency graph.
#>
function Add-CompilationClosure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]] $AffectedAppIds,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]] $ProjectAppIds,
        [Parameter(Mandatory = $true)]
        [hashtable] $Graph
    )

    # Fixed-point iteration: keep adding in-project dependencies until stable
    $changed = $true
    while ($changed) {
        $changed = $false
        $toAdd = @()
        foreach ($appId in $AffectedAppIds) {
            if (-not $Graph.ContainsKey($appId)) { continue }
            foreach ($depId in $Graph[$appId].Dependencies) {
                if ($ProjectAppIds.Contains($depId) -and -not $AffectedAppIds.Contains($depId)) {
                    $toAdd += $depId
                }
            }
        }
        foreach ($id in $toAdd) {
            [void]$AffectedAppIds.Add($id)
            $changed = $true
        }
    }
}

<#
.SYNOPSIS
    Given changed files, computes filtered appFolders and testFolders for each project.
.DESCRIPTION
    Returns a hashtable keyed by project path (as used in AL-Go matrix, e.g.
    "build_projects_Apps (W1)") mapping to @{appFolders=...; testFolders=...}.

    Only projects that need filtering are included. Projects with no affected apps
    are excluded entirely. Projects where ALL apps are affected keep original settings
    (i.e., are not included in the output).
.PARAMETER ChangedFiles
    Array of changed file paths (relative to BaseFolder or absolute).
.PARAMETER BaseFolder
    Root of the repository.
.OUTPUTS
    Hashtable[string -> @{appFolders=string[]; testFolders=string[]}]
#>
function Get-FilteredProjectSettings {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $ChangedFiles,
        [Parameter(Mandatory = $true)]
        [string] $BaseFolder
    )

    $graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
    $affectedAppIds = Get-AffectedApps -ChangedFiles $ChangedFiles -BaseFolder $BaseFolder

    $affectedSet = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($id in $affectedAppIds) {
        [void]$affectedSet.Add($id)
    }

    # Find all project settings files
    $projectSettingsFiles = Get-ChildItem -Path (Join-Path $BaseFolder 'build/projects') -Recurse -Filter 'settings.json' |
        Where-Object { $_.DirectoryName -match '[\\/]\.AL-Go$' }

    $result = @{}

    foreach ($settingsFile in $projectSettingsFiles) {
        $alGoDir = $settingsFile.DirectoryName
        $projectDir = Split-Path $alGoDir -Parent
        $settings = Get-Content -Path $settingsFile.FullName -Raw | ConvertFrom-Json

        # Build project key (same format AL-Go uses)
        $projectKey = Get-RelativePathCompat -From $BaseFolder -To $projectDir

        # Resolve actual app folders and test folders
        $appPatterns = @()
        if ($settings.appFolders) { $appPatterns = @($settings.appFolders) }
        $testPatterns = @()
        if ($settings.testFolders) { $testPatterns = @($settings.testFolders) }

        $resolvedAppFolders = @(Resolve-ProjectGlobs -ProjectDir $projectDir -Patterns $appPatterns)
        $resolvedTestFolders = @(Resolve-ProjectGlobs -ProjectDir $projectDir -Patterns $testPatterns)

        # Map each folder to its app ID
        $allProjectAppIds = [System.Collections.Generic.HashSet[string]]::new()
        $folderToAppId = @{}

        foreach ($folder in ($resolvedAppFolders + $resolvedTestFolders)) {
            $appId = Get-AppIdForFolder -FolderPath $folder
            if ($appId) {
                [void]$allProjectAppIds.Add($appId)
                $folderToAppId[$folder] = $appId
            }
        }

        # Skip projects with no apps
        if ($allProjectAppIds.Count -eq 0) { continue }

        # Find which project apps are affected
        $projectAffected = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($appId in $allProjectAppIds) {
            if ($affectedSet.Contains($appId)) {
                [void]$projectAffected.Add($appId)
            }
        }

        # Skip projects with no affected apps
        if ($projectAffected.Count -eq 0) { continue }

        # Add compilation closure (in-project dependencies of affected apps)
        Add-CompilationClosure -AffectedAppIds $projectAffected -ProjectAppIds $allProjectAppIds -Graph $graph

        # If all apps are affected, skip filtering (keep original wildcard patterns)
        if ($projectAffected.Count -ge $allProjectAppIds.Count) { continue }

        # Build filtered folder lists
        $filteredAppFolders = @()
        foreach ($folder in $resolvedAppFolders) {
            if ($folderToAppId.ContainsKey($folder) -and $projectAffected.Contains($folderToAppId[$folder])) {
                $filteredAppFolders += Get-RelativeFolderPath -FolderPath $folder -ALGoDir $projectDir
            }
        }

        $filteredTestFolders = @()
        foreach ($folder in $resolvedTestFolders) {
            if ($folderToAppId.ContainsKey($folder) -and $projectAffected.Contains($folderToAppId[$folder])) {
                $filteredTestFolders += Get-RelativeFolderPath -FolderPath $folder -ALGoDir $projectDir
            }
        }

        $result[$projectKey] = @{
            appFolders  = $filteredAppFolders
            testFolders = $filteredTestFolders
        }
    }

    return $result
}

<#
.SYNOPSIS
    Detects changed files from the GitHub Actions CI environment.
.DESCRIPTION
    Uses git diff against the base branch (for PRs) or previous commit (for push)
    to determine which files changed. Returns $null when changed files cannot be
    determined (local runs, workflow_dispatch, git failures).
.OUTPUTS
    String array of changed file paths (relative to repo root), or $null.
#>
function Get-ChangedFilesForCI {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    # Only run in GitHub Actions
    if (-not $env:GITHUB_ACTIONS) {
        Write-Host "BUILD OPTIMIZATION: Not in CI environment, skipping changed file detection"
        return $null
    }

    # Never filter for manual runs
    if ($env:GITHUB_EVENT_NAME -eq 'workflow_dispatch') {
        Write-Host "BUILD OPTIMIZATION: workflow_dispatch event, running all tests"
        return $null
    }

    # For PRs and merge_group, diff against the base branch
    if ($env:GITHUB_EVENT_NAME -eq 'pull_request' -or $env:GITHUB_EVENT_NAME -eq 'pull_request_target' -or $env:GITHUB_EVENT_NAME -eq 'merge_group') {
        $baseBranch = $env:GITHUB_BASE_REF
        if (-not $baseBranch) { $baseBranch = 'main' }

        $prevErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        git fetch origin $baseBranch --depth=1 2>$null
        $files = @(git diff --name-only "origin/$baseBranch...HEAD" 2>$null)
        $fetchExitCode = $LASTEXITCODE
        $ErrorActionPreference = $prevErrorAction

        if ($fetchExitCode -eq 0 -and $files.Count -gt 0) {
            Write-Host "BUILD OPTIMIZATION: Detected $($files.Count) changed files (PR diff vs $baseBranch)"
            return $files
        }
    }

    # For push events, diff against previous commit
    if ($env:GITHUB_EVENT_NAME -eq 'push') {
        $prevErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        git fetch --deepen=1 2>$null
        $files = @(git diff --name-only HEAD~1 HEAD 2>$null)
        $fetchExitCode = $LASTEXITCODE
        $ErrorActionPreference = $prevErrorAction

        if ($fetchExitCode -eq 0 -and $files.Count -gt 0) {
            Write-Host "BUILD OPTIMIZATION: Detected $($files.Count) changed files (push diff)"
            return $files
        }
    }

    Write-Host "BUILD OPTIMIZATION: Could not determine changed files, running all tests"
    return $null
}

<#
.SYNOPSIS
    Determines whether tests for a given app should be skipped based on
    the dependency graph and changed files.
.DESCRIPTION
    Called from RunTestsInBcContainer.ps1 for each test app. On first call,
    computes the affected app set and caches it to a temp file. Subsequent
    calls read from cache for fast lookup.
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
        [Parameter(Mandatory = $true)]
        [string] $AppName,
        [Parameter(Mandatory = $true)]
        [string] $BaseFolder
    )

    # Allow disabling via environment variable
    if ($env:BUILD_OPTIMIZATION_DISABLED -eq 'true') {
        return $false
    }

    # Only skip in CI environment
    if (-not $env:GITHUB_ACTIONS) {
        return $false
    }

    # Never skip for manual runs
    if ($env:GITHUB_EVENT_NAME -eq 'workflow_dispatch') {
        return $false
    }

    # Check for cached result
    $tempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $cacheFile = Join-Path $tempDir 'build-optimization-cache.json'

    if (Test-Path $cacheFile) {
        $cached = Get-Content $cacheFile -Raw | ConvertFrom-Json
    } else {
        # First call — compute the affected set
        $changedFiles = Get-ChangedFilesForCI
        if ($null -eq $changedFiles -or $changedFiles.Count -eq 0) {
            $cached = [PSCustomObject]@{ skipEnabled = $false; affectedAppNames = @() }
        } else {
            # Check fullBuildPatterns
            $alGoSettingsPath = Join-Path $BaseFolder '.github/AL-Go-Settings.json'
            $fullBuildPatterns = @()
            if (Test-Path $alGoSettingsPath) {
                $alGoSettings = Get-Content $alGoSettingsPath -Raw | ConvertFrom-Json
                if ($alGoSettings.fullBuildPatterns) { $fullBuildPatterns = @($alGoSettings.fullBuildPatterns) }
            }

            $fullBuild = $false
            foreach ($file in $changedFiles) {
                foreach ($pattern in $fullBuildPatterns) {
                    if ($file -like $pattern) {
                        Write-Host "BUILD OPTIMIZATION: Full build triggered by '$file' matching pattern '$pattern'"
                        $fullBuild = $true
                        break
                    }
                }
                if ($fullBuild) { break }
            }

            if ($fullBuild) {
                $cached = [PSCustomObject]@{ skipEnabled = $false; affectedAppNames = @() }
            } else {
                $graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
                $affectedIds = Get-AffectedApps -ChangedFiles $changedFiles -BaseFolder $BaseFolder

                # If Get-AffectedApps returned all apps, that means full build
                if ($affectedIds.Count -ge $graph.Count) {
                    $cached = [PSCustomObject]@{ skipEnabled = $false; affectedAppNames = @() }
                } else {
                    $names = @()
                    foreach ($id in $affectedIds) {
                        if ($graph.ContainsKey($id)) {
                            $names += $graph[$id].Name
                        }
                    }
                    Write-Host "BUILD OPTIMIZATION: $($names.Count) affected apps out of $($graph.Count) total"
                    $cached = [PSCustomObject]@{ skipEnabled = $true; affectedAppNames = $names }
                }
            }
        }

        # Write cache for subsequent calls
        $cached | ConvertTo-Json -Depth 5 | Set-Content $cacheFile -Encoding UTF8
    }

    if (-not $cached.skipEnabled) {
        return $false
    }

    # Check if the app is in the affected set (case-insensitive)
    $affectedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $cached.affectedAppNames) {
        [void]$affectedSet.Add($name)
    }

    $shouldSkip = -not $affectedSet.Contains($AppName)
    if ($shouldSkip) {
        Write-Host "BUILD OPTIMIZATION: Skipping tests for '$AppName' - not in affected set"
    }
    return $shouldSkip
}

Export-ModuleMember -Function Get-AppDependencyGraph, Get-AppForFile, Get-AffectedApps, Get-FilteredProjectSettings, Get-ChangedFilesForCI, Test-ShouldSkipTestApp
