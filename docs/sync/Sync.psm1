#Requires -Version 7.0
<#
.SYNOPSIS
    Shared helper functions for sync scripts.
#>

function ConvertTo-NormalizedJson {
    <#
    .SYNOPSIS
        Serializes objects to JSON with consistent formatting matching SyncFromNAV.ps1.
    #>
    param([Parameter(Mandatory)] $InputObject)
    $json = $InputObject | ConvertTo-Json -Depth 10
    if ($InputObject.Count -eq 1) { $json = "[$json]" }
    return $json
}

function Get-SyncState {
    <#
    .SYNOPSIS
        Reads sync-state.json from BCAppsPrivate repo.
    #>
    param([Parameter(Mandatory)][string] $BCAppsPrivateRepoPath)
    $stateFile = Join-Path $BCAppsPrivateRepoPath "docs\sync\sync-state.json"
    if (-not (Test-Path $stateFile)) {
        throw "sync-state.json not found at $stateFile. Create it manually before first sync."
    }
    return Get-Content $stateFile -Raw | ConvertFrom-Json
}

function Set-SyncState {
    <#
    .SYNOPSIS
        Updates sync-state.json in BCAppsPrivate repo.
    #>
    param(
        [Parameter(Mandatory)][string] $BCAppsPrivateRepoPath,
        [string] $BCAppsCommit,
        [string] $NAVCommit
    )
    $stateFile = Join-Path $BCAppsPrivateRepoPath "docs\sync\sync-state.json"
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    if ($BCAppsCommit) { $state.lastSyncedBCAppsCommit = $BCAppsCommit }
    if ($NAVCommit) { $state.lastSyncedNAVCommit = $NAVCommit }
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -NoNewline -Encoding utf8NoBOM
}

function Invoke-Robocopy {
    param(
        [string] $Source,
        [string] $Destination,
        [string[]] $Arguments
    )
    $allArgs = @($Source, $Destination) + $Arguments
    & robocopy @allArgs | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed with exit code $LASTEXITCODE copying '$Source' to '$Destination'"
    }
}

function Invoke-ThreeWayMerge {
    <#
    .SYNOPSIS
        3-way merges a file using a base from the source repo at a specific commit.
    .PARAMETER TargetFile
        The "ours" file (in the destination repo).
    .PARAMETER SourceFile
        The "theirs" file (current version in the source repo).
    .PARAMETER SourceRepoPath
        Path to the source git repo.
    .PARAMETER BaseCommit
        Commit SHA in the source repo to use as merge base.
    .PARAMETER BaseRelativePath
        Path relative to source repo root for the base file.
    #>
    param(
        [string] $TargetFile,
        [string] $SourceFile,
        [string] $SourceRepoPath,
        [string] $BaseCommit,
        [string] $BaseRelativePath
    )
    $fileName = Split-Path $TargetFile -Leaf
    $basePath = Join-Path $env:TEMP "merge-base-$fileName"
    $oldEAP = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    $baseLines = git -C $SourceRepoPath show "${BaseCommit}:$BaseRelativePath" 2>$null
    $ErrorActionPreference = $oldEAP
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot get base for $fileName from $SourceRepoPath at commit $BaseCommit (path: $BaseRelativePath)"
    }
    # Write with same line endings as target file to avoid spurious conflicts
    $targetContent = [System.IO.File]::ReadAllBytes($TargetFile)
    $useCRLF = [System.Array]::IndexOf($targetContent, [byte]13) -ge 0
    $sep = if ($useCRLF) { "`r`n" } else { "`n" }
    ($baseLines -join $sep) + $sep | Set-Content $basePath -NoNewline
    git merge-file $TargetFile $basePath $SourceFile 2>&1 | Out-Null
    $mergeResult = $LASTEXITCODE
    if ($mergeResult -ge 128) {
        throw "git merge-file error ($mergeResult) for $fileName"
    } elseif ($mergeResult -gt 0) {
        Write-Warning "  $mergeResult conflict(s) in $fileName"
        Write-Host "  Resolve in: $TargetFile"
        do {
            $answer = Read-Host "  Press 'y' when resolved to continue, 'q' to abort"
            if ($answer -eq 'q') { throw "Aborted by user due to merge conflict in $fileName." }
        } while ($answer -ne 'y')
    } else {
        Write-Host "  Merged cleanly: $fileName"
    }
    if (Test-Path $basePath) { Remove-Item $basePath -Force }
    return $mergeResult
}

function Merge-SharedFiles {
    <#
    .SYNOPSIS
        3-way merges shared individual files between repos.
        Files that only exist in source are copied. Files in both are merged.
        Base is always read from BCApps repo at the given commit.
    #>
    param(
        [string] $SourceRepoPath,
        [string] $TargetRepoPath,
        [string] $BaseRepoPath,
        [string] $BaseCommit
    )

    $files = @(
        ".gitignore",
        ".github\CICD.settings.json",
        ".github\AL-Go-Settings.json",
        ".github\RELEASENOTES.copy.md",
        "build\Packages.json"
    )

    foreach ($f in $files) {
        $source = Join-Path $SourceRepoPath $f
        $target = Join-Path $TargetRepoPath $f
        $baseRelPath = $f -replace '\\', '/'
        if (-not (Test-Path $source)) { continue }
        $destDir = Split-Path $target -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        if (-not (Test-Path $target)) {
            Copy-Item $source $target -Force
            Write-Host "  Copied new: $f"
        } else {
            Invoke-ThreeWayMerge -TargetFile $target -SourceFile $source `
                -SourceRepoPath $BaseRepoPath -BaseCommit $BaseCommit `
                -BaseRelativePath $baseRelPath
        }
    }
}

function Merge-DisabledTests {
    <#
    .SYNOPSIS
        Merges DisabledTest entries into a target folder.
        If target folder has existing .DisabledTest.json files, performs semantic merge
        (entries matched by codeunitId into existing files). Otherwise, copies source files flat.
    .PARAMETER SourceFiles
        Array of FileInfo objects (the source DisabledTest JSON files).
    .PARAMETER TargetDir
        Path to the target DisabledTests folder.
    #>
    param(
        [System.IO.FileInfo[]] $SourceFiles,
        [string] $TargetDir
    )
    if (-not $SourceFiles -or $SourceFiles.Count -eq 0) {
        Write-Host "  No source DisabledTest files to merge"
        return
    }
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # Detect mode: if target already has .DisabledTest.json files, do semantic merge
    $targetFiles = Get-ChildItem $TargetDir -Recurse -Filter "*.DisabledTest.json" -File
    if ($targetFiles.Count -eq 0) {
        # No existing files - copy flat
        foreach ($sf in $SourceFiles) {
            Copy-Item $sf.FullName (Join-Path $TargetDir $sf.Name) -Force
        }
        Write-Host "  Copied $($SourceFiles.Count) DisabledTest files"
        return
    }

    # Semantic merge: index target files by codeunitId
    $targetIndex = @{}
    $targetFileContents = @{}
    foreach ($tf in $targetFiles) {
        $entries = Get-Content $tf.FullName -Raw | ConvertFrom-Json
        $targetFileContents[$tf.FullName] = @($entries)
        foreach ($entry in $entries) {
            if (-not $targetIndex.ContainsKey($entry.codeunitId)) {
                $targetIndex[$entry.codeunitId] = $tf.FullName
            }
        }
    }

    # Read source entries and merge into target
    $addedCount = 0
    $unmappedCodeunits = @()
    $modifiedFiles = @{}

    foreach ($sf in $SourceFiles) {
        $raw = Get-Content $sf.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $raw) { continue }
        $entries = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-not $entries) { continue }

        foreach ($entry in $entries) {
            if (-not $entry.codeunitId) { continue }
            $targetFile = $targetIndex[$entry.codeunitId]
            if (-not $targetFile) {
                $key = "$($entry.codeunitId)|$($entry.codeunitName)"
                if ($unmappedCodeunits -notcontains $key) {
                    $unmappedCodeunits += $key
                }
                continue
            }

            $existingEntries = $targetFileContents[$targetFile]

            # Skip if target already has a wildcard for this codeunit
            $hasWildcard = $existingEntries | Where-Object { $_.codeunitId -eq $entry.codeunitId -and $_.method -eq '*' }
            if ($hasWildcard) { continue }

            if ($entry.method -eq '*') {
                $alreadyExists = $existingEntries | Where-Object { $_.codeunitId -eq $entry.codeunitId -and $_.method -eq '*' }
                if (-not $alreadyExists) {
                    $targetFileContents[$targetFile] = @($existingEntries) + @($entry)
                    $modifiedFiles[$targetFile] = $true
                    $addedCount++
                }
                continue
            }

            $exists = $existingEntries | Where-Object {
                $_.codeunitId -eq $entry.codeunitId -and $_.method -eq $entry.method
            }
            if (-not $exists) {
                $targetFileContents[$targetFile] = @($existingEntries) + @($entry)
                $modifiedFiles[$targetFile] = $true
                $addedCount++
            }
        }
    }

    # Write back modified files
    foreach ($filePath in $modifiedFiles.Keys) {
        $entries = $targetFileContents[$filePath]
        $json = ConvertTo-NormalizedJson $entries
        Set-Content $filePath $json -NoNewline -Encoding utf8NoBOM
    }

    Write-Host "  Added $addedCount new entries to existing DisabledTest files"
    if ($unmappedCodeunits.Count -gt 0) {
        Write-Warning "  $($unmappedCodeunits.Count) codeunit(s) not found in any target DisabledTest file:"
        foreach ($uc in $unmappedCodeunits) {
            $parts = $uc -split '\|'
            Write-Warning "    Codeunit $($parts[0]): $($parts[1])"
        }
    }
}

function Enter-SyncBranch {
    param(
        [string] $RepoPath,
        [string] $BranchName,
        [switch] $New
    )
    $existingBranch = git -C $RepoPath branch --list $BranchName 2>&1
    if ($New) {
        if ($existingBranch) {
            throw "Branch '$BranchName' already exists in $(Split-Path $RepoPath -Leaf)."
        }
        git -C $RepoPath checkout -b $BranchName main
        Write-Host "  Created new branch '$BranchName' from main"
    } else {
        if (-not $existingBranch) {
            throw "Branch '$BranchName' does not exist in $(Split-Path $RepoPath -Leaf)."
        }
        git -C $RepoPath checkout $BranchName
        Write-Host "  Checked out existing branch '$BranchName'"
    }
}

function Complete-SyncCommit {
    param(
        [string] $RepoPath,
        [string] $Message
    )
    git -C $RepoPath add --force -A
    $status = git -C $RepoPath status --porcelain
    if ($status) {
        git -C $RepoPath commit --quiet -m $Message
        Write-Host "  Committed: $Message"
    } else {
        Write-Host "  No changes to commit"
    }
}

Export-ModuleMember -Function Invoke-Robocopy, Invoke-ThreeWayMerge, Merge-SharedFiles, Merge-DisabledTests, Enter-SyncBranch, Complete-SyncCommit, Get-SyncState, Set-SyncState, ConvertTo-NormalizedJson
