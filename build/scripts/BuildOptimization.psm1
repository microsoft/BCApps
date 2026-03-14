<#
.SYNOPSIS
    Test-skip logic for CI/CD build optimization.
.DESCRIPTION
    Determines whether a test app should be skipped based on which files changed
    and the app dependency graph. Called from RunTestsInBcContainer.ps1.
#>

$ErrorActionPreference = "Stop"

function Get-AppDependencyGraph {
    [CmdletBinding()]
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

function Get-AppForFile {
    [CmdletBinding()]
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

function Get-AffectedApps {
    [CmdletBinding()]
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

function Get-ChangedFilesForCI {
    [CmdletBinding()]
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

function Test-ShouldSkipTestApp {
    [CmdletBinding()]
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
