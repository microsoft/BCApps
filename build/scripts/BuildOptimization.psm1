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
            return [string[]]@($Graph.Keys)
        }
    }

    if ($directlyChanged.Count -eq 0) { return [string[]]@() }

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

    return [string[]]@($affected)
}

<#
.SYNOPSIS
    Resolves the merge base between two commits.
.DESCRIPTION
    Tries 'git merge-base' directly, and - should the merge base not be reachable
    because one side's commit has not been fetched yet - fetches both endpoints
    and tries once more. The workflows that rely on change detection check out the
    full history (fetch-depth: 0), so no history deepening is required here.
.PARAMETER BaseSha
    The base commit SHA.
.PARAMETER HeadSha
    The head commit SHA.
.OUTPUTS
    The merge-base commit SHA, or an empty string when it cannot be determined.
#>
function Resolve-MergeBaseForCI {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)] [string] $BaseSha,
        [Parameter(Mandatory = $true)] [string] $HeadSha
    )

    $mergeBase = (& git merge-base $BaseSha $HeadSha 2>$null)
    if (-not [string]::IsNullOrWhiteSpace($mergeBase)) {
        return $mergeBase
    }

    # Fetch both endpoints in case one side's commit is missing, then retry.
    & git fetch --no-tags origin $BaseSha $HeadSha 2>$null
    return (& git merge-base $BaseSha $HeadSha 2>$null)
}

<#
.SYNOPSIS
    Returns the verified tested PR merge and its base, or null when verification fails.
.PARAMETER ExpectedHeadSha
    PR head commit from the event payload, expected as the merge's second parent.
#>
function Get-VerifiedPullRequestMerge {
    param([string] $ExpectedHeadSha)

    $testedSha = & git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $env:GITHUB_SHA -or $testedSha -ne $env:GITHUB_SHA) {
        return $null
    }

    # Read raw headers: revision traversal hides parents at a shallow boundary.
    $commit = @(& git cat-file -p $testedSha 2>$null)
    if ($LASTEXITCODE -ne 0) { return $null }

    $parents = @()
    foreach ($line in $commit) {
        if ($line -eq '') { break }
        if ($line -match '^parent ([0-9a-f]{40,64})$') { $parents += $Matches[1] }
    }
    if ($parents.Count -ne 2 -or $parents[1] -ne $ExpectedHeadSha) { return $null }

    return [PSCustomObject]@{ BaseSha = $parents[0]; MergeSha = $testedSha }
}

<#
.SYNOPSIS
    Makes a commit available locally, fetching it from origin if missing.
.PARAMETER CommitSha
    Commit required for change detection.
.PARAMETER FetchHistory
    Fetch without a depth limit when merge-base comparison requires history.
.PARAMETER RequireChangeDetection
    Throw on fetch failure instead of logging and returning false.
#>
function Initialize-GitCommit {
    [OutputType([bool])]
    param(
        [string] $CommitSha,
        [switch] $FetchHistory,
        [switch] $RequireChangeDetection
    )

    $null = & git cat-file -e "$CommitSha^{commit}" 2>$null
    if ($LASTEXITCODE -eq 0) { return $true }

    Write-Host "BUILD OPTIMIZATION: Fetching missing commit $CommitSha"
    $fetchArguments = @('fetch', 'origin', $CommitSha)
    if (-not $FetchHistory) { $fetchArguments += '--depth=1' }
    $null = & git @fetchArguments 2>$null
    if ($LASTEXITCODE -eq 0) { return $true }

    $message = "Could not fetch commit '$CommitSha' from origin (exitCode=$LASTEXITCODE, directory='$PWD')."
    if ($RequireChangeDetection) { throw $message }
    Write-Host "BUILD OPTIMIZATION: $message"
    return $false
}

<#
.SYNOPSIS
    Detects changed files from the GitHub Actions CI environment.
.DESCRIPTION
    Reads the GitHub event payload ($GITHUB_EVENT_PATH) to extract base/head commit
    SHAs, then uses git diff with those SHAs. This approach works reliably with
    shallow clones (unlike three-dot diffs that need the merge base).
    Supports pull_request, merge_group, and push events.
    Returns $null when changed files cannot be determined (local, workflow_dispatch, git failure).
    .PARAMETER DiffFilter
    Optional git diff-filter value, for example 'A' to return only newly added files.
    .PARAMETER CompareFromMergeBase
    Compare the head against the merge base instead of the current base-branch tip.
    .PARAMETER CompareWithPullRequestMerge
    For pull_request events, compare the verified checked-out merge against its first parent.
    .PARAMETER RequireChangeDetection
    Throw instead of returning null when the change set cannot be determined.
.OUTPUTS
    String array of changed file paths relative to repo root, or $null.
#>
function Get-ChangedFilesForCI {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string] $DiffFilter,
        [switch] $CompareFromMergeBase,
        [switch] $CompareWithPullRequestMerge,
        [switch] $RequireChangeDetection
    )

    if ($CompareWithPullRequestMerge -and $CompareFromMergeBase) {
        throw "CompareWithPullRequestMerge and CompareFromMergeBase cannot be combined."
    }

    if (-not $env:GITHUB_ACTIONS) {
        if ($RequireChangeDetection) {
            throw "Change detection requires a GitHub Actions environment."
        }
        Write-Host "BUILD OPTIMIZATION: Change detection skipped - not running in GitHub Actions"
        return $null
    }

    if ($env:GITHUB_EVENT_NAME -eq 'workflow_dispatch') {
        if ($RequireChangeDetection) {
            throw "Change detection is not supported for workflow_dispatch events."
        }
        Write-Host "BUILD OPTIMIZATION: Change detection skipped - workflow_dispatch event"
        return $null
    }

    # Read GitHub event payload for base/head commit SHAs (works with shallow clones)
    if (-not $env:GITHUB_EVENT_PATH -or -not (Test-Path $env:GITHUB_EVENT_PATH)) {
        if ($RequireChangeDetection) {
            throw "GitHub event payload not found at '$($env:GITHUB_EVENT_PATH)'."
        }
        Write-Host "BUILD OPTIMIZATION: GitHub event payload not found at '$($env:GITHUB_EVENT_PATH)'"
        return $null
    }

    $eventPayload = Get-Content $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json

    $baseSha = $null
    $headSha = $null

    if ($env:GITHUB_EVENT_NAME -match 'pull_request') {
        $baseSha = $eventPayload.pull_request.base.sha
        $headSha = $eventPayload.pull_request.head.sha
    }
    elseif ($env:GITHUB_EVENT_NAME -eq 'merge_group') {
        $baseSha = $eventPayload.merge_group.base_sha
        $headSha = $eventPayload.merge_group.head_sha
    }
    elseif ($env:GITHUB_EVENT_NAME -eq 'push') {
        $baseSha = $eventPayload.before
        $headSha = $eventPayload.after
    }

    if (-not $baseSha -or -not $headSha) {
        if ($RequireChangeDetection) {
            throw "Could not extract commit SHAs from the GitHub event payload (event=$($env:GITHUB_EVENT_NAME))."
        }
        Write-Host "BUILD OPTIMIZATION: Could not extract commit SHAs from event payload (event=$($env:GITHUB_EVENT_NAME))"
        return $null
    }

    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($CompareWithPullRequestMerge -and $env:GITHUB_EVENT_NAME -eq 'pull_request') {
            $merge = Get-VerifiedPullRequestMerge -ExpectedHeadSha $headSha
            if ($null -eq $merge) {
                $message = "Could not verify the checked-out PR merge against GITHUB_SHA and event head '$headSha'."
                if ($RequireChangeDetection) { throw $message }
                Write-Host "BUILD OPTIMIZATION: $message"
                return $null
            }
            $baseSha = $merge.BaseSha
            $headSha = $merge.MergeSha
        }

        Write-Host "BUILD OPTIMIZATION: Comparing $($baseSha.Substring(0, 8))...$($headSha.Substring(0, 8))"

        # A depth-one PR merge checkout can be missing both event endpoints.
        foreach ($sha in @($baseSha, $headSha)) {
            if (-not (Initialize-GitCommit -CommitSha $sha -FetchHistory:$CompareFromMergeBase -RequireChangeDetection:$RequireChangeDetection)) {
                return $null
            }
        }

        $diffBase = $baseSha
        if ($CompareFromMergeBase) {
            $diffBase = Resolve-MergeBaseForCI -BaseSha $baseSha -HeadSha $headSha
            if ([string]::IsNullOrWhiteSpace($diffBase)) {
                if ($RequireChangeDetection) {
                    throw "Could not determine the merge base between '$baseSha' and '$headSha'."
                }
                Write-Host "BUILD OPTIMIZATION: Could not determine merge base"
                return $null
            }
        }

        $diffArguments = @('-c', 'core.quotePath=false', 'diff', '--name-only')
        if (-not [string]::IsNullOrWhiteSpace($DiffFilter)) {
            $diffArguments += "--diff-filter=$DiffFilter"
        }
        $diffArguments += @($diffBase, $headSha, '--')

        $stderrFile = [System.IO.Path]::GetTempFileName()
        try {
            $files = @(& git @diffArguments 2> $stderrFile)
            $diffExitCode = $LASTEXITCODE
            $diagnostic = Get-Content -Path $stderrFile -Raw
        } finally {
            Remove-Item -LiteralPath $stderrFile
        }
        if ($diffExitCode -ne 0) {
            $message = "Git diff failed (exitCode=$diffExitCode, directory='$PWD'): $diagnostic"
            if ($RequireChangeDetection) {
                throw $message
            }
            Write-Host "BUILD OPTIMIZATION: $message"
            return $null
        }

        if ($files.Count -eq 0) {
            Write-Host "BUILD OPTIMIZATION: No changed files detected"
            return $null
        }

        return [string[]]$files
    }
    finally {
        $ErrorActionPreference = $prevErrorAction
    }
}

<#
.SYNOPSIS
    Checks whether any changed files match the fullBuildPatterns from AL-Go settings.
.DESCRIPTION
    Reads the fullBuildPatterns array from .github/AL-Go-Settings.json and tests
    each changed file path against each pattern using -like. When AL-Go detects
    matching files it forces a full compile, so the test side must also force a
    full test run (i.e., skip nothing).
.PARAMETER ChangedFiles
    Array of changed file paths (relative to repo root, forward-slash separated).
.PARAMETER BaseFolder
    Root of the repository (used to locate .github/AL-Go-Settings.json).
.OUTPUTS
    $true if any changed file matches a fullBuildPattern, $false otherwise.
#>
function Test-FullBuildPatternsMatch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string[]] $ChangedFiles,
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    $settingsPath = Join-Path $BaseFolder '.github/AL-Go-Settings.json'
    if (-not (Test-Path $settingsPath)) { return $false }

    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
    $patterns = $settings.fullBuildPatterns
    if (-not $patterns -or $patterns.Count -eq 0) { return $false }

    foreach ($file in $ChangedFiles) {
        $normalized = $file.Replace('\', '/')
        foreach ($pattern in $patterns) {
            if ($normalized -like $pattern) {
                Write-Host "BUILD OPTIMIZATION: File '$normalized' matches fullBuildPattern '$pattern' - forcing full test run"
                return $true
            }
        }
    }

    return $false
}

<#
.SYNOPSIS
    Computes the set of app names affected by changed files.
.DESCRIPTION
    Pure computation — no caching or side effects. Returns a PSCustomObject with
    two properties: RunAll (bool) and AppNames (string[]). The caller is responsible
    for persisting/reading the result to avoid recomputing across process invocations.
    Selective results also retain Tests-NewObjects-Internal regardless of dependency changes.
.PARAMETER BaseFolder
    Root of the repository.
.OUTPUTS
    PSCustomObject with RunAll (bool) and AppNames (string[]).
#>
function Get-AffectedAppNames {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string] $BaseFolder
    )

    $runAll = @{ RunAll = $true; AppNames = @() }

    if ($env:BUILD_OPTIMIZATION_DISABLED -eq 'true') {
        Write-Host "BUILD OPTIMIZATION: Disabled via BUILD_OPTIMIZATION_DISABLED=true"
        return [PSCustomObject]$runAll
    }
    if (-not $env:GITHUB_ACTIONS) {
        return [PSCustomObject]$runAll
    }
    if ($env:GITHUB_EVENT_NAME -eq 'workflow_dispatch') {
        return [PSCustomObject]$runAll
    }

    $changedFiles = Get-ChangedFilesForCI -CompareWithPullRequestMerge
    if (-not $changedFiles) {
        Write-Host "BUILD OPTIMIZATION: Running all tests - could not determine changed files"
        return [PSCustomObject]$runAll
    }

    Write-Host "BUILD OPTIMIZATION: Changed files ($($changedFiles.Count)):"
    foreach ($f in $changedFiles) { Write-Host "  - $f" }

    # If any changed file matches fullBuildPatterns, AL-Go compiles everything.
    # We must run all tests to match — skip nothing.
    if (Test-FullBuildPatternsMatch -ChangedFiles $changedFiles -BaseFolder $BaseFolder) {
        Write-Host "BUILD OPTIMIZATION: fullBuildPatterns matched, full test run required"
        return [PSCustomObject]$runAll
    }

    $graph = Get-AppDependencyGraph -BaseFolder $BaseFolder
    $affectedIds = Get-AffectedApps -ChangedFiles $changedFiles -BaseFolder $BaseFolder -Graph $graph

    # Full build triggered (unmapped src file or all apps affected)
    if ($affectedIds.Count -ge $graph.Count) {
        Write-Host "BUILD OPTIMIZATION: Full build triggered ($($affectedIds.Count) apps affected)"
        return [PSCustomObject]$runAll
    }

    $affectedNames = @()
    foreach ($id in $affectedIds) {
        if ($graph.ContainsKey($id)) { $affectedNames += $graph[$id].Name }
    }

    $sortedNames = $affectedNames | Sort-Object
    Write-Host "BUILD OPTIMIZATION: Affected apps ($($affectedNames.Count)):"
    foreach ($name in $sortedNames) { Write-Host "  - $name" }

    # These tests validate objects and permissions across installed apps, regardless of changed dependencies.
    if ($affectedNames -notcontains 'Tests-NewObjects-Internal') {
        $affectedNames += 'Tests-NewObjects-Internal'
    }

    return [PSCustomObject]@{ RunAll = $false; AppNames = $affectedNames }
}

<#
.SYNOPSIS
    Determines whether tests for a given app should be skipped.
.DESCRIPTION
    Reads the cached affected-apps JSON file written by a prior call in the same
    CI job. If the file doesn't exist, computes the result and writes the cache.
    Returns $true to skip, $false to run.
.PARAMETER AppName
    The display name of the test app (from $parameters["appName"]).
.PARAMETER BaseFolder
    Root of the repository.
.PARAMETER CacheFile
    Path to the JSON cache file. Defaults to $TEMP/BuildOptimization_AffectedApps.json.
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
        [string] $BaseFolder,
        [string] $CacheFile = (Join-Path ([System.IO.Path]::GetTempPath()) 'BuildOptimization_AffectedApps.json')
    )

    # Read or compute affected apps
    if (Test-Path $CacheFile) {
        Write-Host "BUILD OPTIMIZATION: Reading cached result from $CacheFile"
        $result = Get-Content $CacheFile -Raw | ConvertFrom-Json
    } else {
        $result = Get-AffectedAppNames -BaseFolder $BaseFolder
        $result | ConvertTo-Json -Compress | Set-Content -Path $CacheFile -Force
        Write-Host "BUILD OPTIMIZATION: Cache written to $CacheFile"
    }

    if ($result.RunAll) {
        Write-Host "BUILD OPTIMIZATION: RUNNING tests for '$AppName'"
        return $false
    }

    if ($result.AppNames -notcontains $AppName) {
        Write-Host "BUILD OPTIMIZATION: SKIPPING tests for '$AppName' - not in affected set"
        return $true
    }
    Write-Host "BUILD OPTIMIZATION: RUNNING tests for '$AppName'"
    return $false
}

<#
.SYNOPSIS
    Logs the churn-based test proposal and returns all candidate apps unchanged.
.PARAMETER AppNamesToTest
    Candidate test app names in dispatch order; returned unchanged in logging-only mode.
.PARAMETER BaseFolder
    Repository root used to determine affected apps.
.PARAMETER ChurnEnabled
    Enables impact analysis for the logged proposal; false bypasses analysis without skipping tests.
.PARAMETER Country
    Project country shown in the selection log.
.PARAMETER TestType
    Project test type shown in the selection log.
.PARAMETER BucketNumber
    Legacy test bucket shown in the log; ignored for other test types.
#>
function Get-SelectedTestApps {
    [OutputType([string[]])]
    param(
        [string[]] $AppNamesToTest,
        [string] $BaseFolder,
        [bool] $ChurnEnabled,
        [string] $Country,
        [string] $TestType,
        [int] $BucketNumber
    )

    $candidateCount = $AppNamesToTest.Count
    $proposedAppNames = @($AppNamesToTest)
    $selectionMode = if ($ChurnEnabled) { 'Enabled; no candidate test apps' } else { 'Disabled; full bucket' }
    if ($AppNamesToTest.Count -gt 0 -and $ChurnEnabled) {
        $affected = Get-AffectedAppNames -BaseFolder $BaseFolder
        $selectionMode = 'Enabled; full bucket (RunAll)'
        if (-not $affected.RunAll) {
            $selectionMode = 'Enabled; affected-app proposal'
            $proposedAppNames = @($AppNamesToTest | Where-Object { $_ -in $affected.AppNames })
        }
    }

    $bucketLabel = if ($TestType -eq 'Legacy') { $BucketNumber } else { 'n/a' }
    Write-Host "Test app selection"
    Write-Host "Country: $Country | Test type: $TestType | Bucket: $bucketLabel"
    Write-Host "Churn-based testing: $selectionMode"
    Write-Host "Logging only: full bucket will run ($candidateCount test apps)."
    Write-Host "Candidates: $candidateCount | Would run: $($proposedAppNames.Count) | Would skip: $($candidateCount - $proposedAppNames.Count)"
    Write-Host "Proposed test apps (candidate order):"
    foreach ($appName in $proposedAppNames) {
        Write-Host "  - $appName"
    }
    if ($proposedAppNames.Count -eq 0) {
        Write-Host "  No test apps proposed."
    }

    return $AppNamesToTest
}

Export-ModuleMember -Function Get-AppDependencyGraph, Get-AppForFile, Get-AffectedApps, Get-ChangedFilesForCI, Test-FullBuildPatternsMatch, Get-AffectedAppNames, Test-ShouldSkipTestApp, Get-SelectedTestApps
