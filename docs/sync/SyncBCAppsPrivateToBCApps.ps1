<#
.SYNOPSIS
    Syncs BCAppsPrivate "original" files (build/CI infra) into BCApps and merges
    rulesets/DisabledTests. Run after SyncNAVToTarget.ps1 has synced NAV into BCApps.

.DESCRIPTION
    Copies BCAppsPrivate build/CI files into BCApps, merges rulesets and DisabledTests
    (since NAV may have synced different versions into BCApps), and generates AL-Go
    project configs.

    Creates a branch and commits changes.

.PARAMETER BCAppsPrivateRepoPath
    Path to the BCAppsPrivate repo (e.g., C:\depot\BCAppsPrivate).

.PARAMETER BCAppsRepoPath
    Path to the BCApps repo (e.g., C:\depot\BCApps).

.PARAMETER BranchName
    Optional branch name. Defaults to sync-<BCAppsPrivate-HEAD-short>.

.EXAMPLE
    .\SyncBCAppsPrivateToBCApps.ps1 -BCAppsPrivateRepoPath "C:\depot\BCAppsPrivate" -BCAppsRepoPath "C:\depot\BCApps"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $BCAppsPrivateRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $BCAppsRepoPath,

    [Parameter(Mandatory = $false)]
    [string] $BranchName
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Sync.psm1") -Force

#region Verification

Write-Host "=== Verifying repos ==="
$privateHead = (git -C $BCAppsPrivateRepoPath rev-parse HEAD 2>&1).Trim()
if ($LASTEXITCODE -ne 0) { throw "Failed to get HEAD from BCAppsPrivate repo" }
Write-Host "  BCAppsPrivate HEAD: $privateHead"

#endregion

#region Branch Setup

$userSuppliedBranch = [bool]$BranchName
if (-not $BranchName) {
    $shortSha = $privateHead.Substring(0, [Math]::Min(10, $privateHead.Length))
    $BranchName = "sync-$shortSha"
}

Write-Host "`n=== Setting up branch '$BranchName' in BCApps ==="
Enter-SyncBranch -RepoPath $BCAppsRepoPath -BranchName $BranchName -New:(-not $userSuppliedBranch)

#endregion

#region Step 1: Merge and copy build/CI files

Write-Host "`n=== Step 1: Merging/copying build/CI files ==="
$syncState = Get-SyncState -BCAppsPrivateRepoPath $BCAppsPrivateRepoPath
$baseCommit = $syncState.lastSyncedBCAppsCommit

Merge-SharedFiles -SourceRepoPath $BCAppsPrivateRepoPath -TargetRepoPath $BCAppsRepoPath -BaseRepoPath $BCAppsRepoPath -BaseCommit $baseCommit

# Directory copies (one-way Private -> BCApps only)
$dirCopies = @(
    @{ Source = ".github\actions"; Dest = ".github\actions" },
    @{ Source = ".github\workflows"; Dest = ".github\workflows" },
    @{ Source = "build\scripts"; Dest = "build\scripts" }
)

foreach ($dc in $dirCopies) {
    $source = Join-Path $BCAppsPrivateRepoPath $dc.Source
    $dest = Join-Path $BCAppsRepoPath $dc.Dest
    if (Test-Path $source) {
        Invoke-Robocopy -Source $source -Destination $dest -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
        Write-Host "  Mirrored $($dc.Source)"
    }
}

#endregion

#region Step 2: Merge rulesets

Write-Host "`n=== Step 2: Merging rulesets ==="
$sourceRulesets = Join-Path $BCAppsPrivateRepoPath "src\rulesets"
$destRulesets = Join-Path $BCAppsRepoPath "src\rulesets"
if (-not (Test-Path $destRulesets)) {
    New-Item -ItemType Directory -Path $destRulesets -Force | Out-Null
}

if (Test-Path $sourceRulesets) {
    $rulesetFiles = Get-ChildItem $sourceRulesets -Filter "*.json"
    foreach ($rf in $rulesetFiles) {
        $targetFile = Join-Path $destRulesets $rf.Name
        if (-not (Test-Path $targetFile)) {
            Copy-Item $rf.FullName $targetFile -Force
            Write-Host "  Copied new: $($rf.Name)"
        } else {
            Invoke-ThreeWayMerge -TargetFile $targetFile -SourceFile $rf.FullName `
                -SourceRepoPath $BCAppsRepoPath -BaseCommit $baseCommit `
                -BaseRelativePath "src/rulesets/$($rf.Name)"
        }
    }
} else {
    Write-Warning "  Source rulesets not found: $sourceRulesets"
}

#endregion

#region Step 3: Merge DisabledTests

Write-Host "`n=== Step 3: Merging DisabledTests ==="
$privateDisabledTests = Join-Path $BCAppsPrivateRepoPath "src\DisabledTests"
$bcappsDisabledTests = Join-Path $BCAppsRepoPath "src\DisabledTests"

# Collect all DisabledTest files in BCApps (scattered in-app + flat NAV ones)
$bcappsSourceFiles = Get-ChildItem $BCAppsRepoPath -Recurse -Filter "*.DisabledTest.json" -File
# Also check for .json files in DisabledTests folders without the .DisabledTest.json suffix
$dtFolderFiles = Get-ChildItem $BCAppsRepoPath -Recurse -Directory -Filter "DisabledTests" |
    ForEach-Object { Get-ChildItem $_.FullName -Filter "*.json" -File } |
    Where-Object { $_.Name -notlike "*.DisabledTest.json" }
$allBCAppsFiles = @($bcappsSourceFiles) + @($dtFolderFiles) | Sort-Object FullName -Unique
Write-Host "  Found $($allBCAppsFiles.Count) DisabledTest files in BCApps"

# Merge into a temp copy of BCAppsPrivate's per-app structure
$tempDir = Join-Path $env:TEMP "sync-disabled-tests-merge"
# Merge into a temp copy of BCAppsPrivate's per-app structure
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
Copy-Item $privateDisabledTests $tempDir -Recurse -Force

Merge-DisabledTests -SourceFiles $allBCAppsFiles -TargetDir $tempDir

# Delete all original DisabledTest files from BCApps and their DisabledTests folders
$foldersToCheck = @()
foreach ($sf in $allBCAppsFiles) {
    $parent = Split-Path $sf.FullName -Parent
    Remove-Item $sf.FullName -Force -ErrorAction SilentlyContinue
    if ((Split-Path $parent -Leaf) -eq "DisabledTests" -and $foldersToCheck -notcontains $parent) {
        $foldersToCheck += $parent
    }
}
foreach ($folder in $foldersToCheck) {
    if ((Test-Path $folder) -and (Get-ChildItem $folder -File).Count -eq 0) {
        Remove-Item $folder -Recurse -Force
    }
}
if (Test-Path $bcappsDisabledTests) { Remove-Item $bcappsDisabledTests -Recurse -Force }

# Copy merged result to BCApps
Copy-Item $tempDir $bcappsDisabledTests -Recurse -Force
Remove-Item $tempDir -Recurse -Force

Write-Host "  Replaced BCApps DisabledTests with merged per-app structure"

#endregion

#region Step 4: Copy tools folder

Write-Host "`n=== Step 4: Copying tools folder ==="
$sourceTools = Join-Path $BCAppsPrivateRepoPath "tools"
$destTools = Join-Path $BCAppsRepoPath "tools"
if (Test-Path $sourceTools) {
    Invoke-Robocopy -Source $sourceTools -Destination $destTools -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    Write-Host "  Done"
}

#endregion

#region Step 5: Copy root-level files

Write-Host "`n=== Step 5: Copying root-level files ==="
$rootFiles = Get-ChildItem $BCAppsPrivateRepoPath -File
foreach ($rf in $rootFiles) {
    Copy-Item $rf.FullName (Join-Path $BCAppsRepoPath $rf.Name) -Force
}
Write-Host "  Copied $($rootFiles.Count) root files"

#endregion

#region Step 6: Copy docs

Write-Host "`n=== Step 6: Copying docs ==="
$sourceDocs = Join-Path $BCAppsPrivateRepoPath "docs\features"
$destDocs = Join-Path $BCAppsRepoPath "docs\features"
if (Test-Path $sourceDocs) {
    if (-not (Test-Path $destDocs)) { New-Item -ItemType Directory -Path $destDocs -Force | Out-Null }
    Invoke-Robocopy -Source $sourceDocs -Destination $destDocs -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    Write-Host "  Done"
} else {
    Write-Host "  No docs\features found in BCAppsPrivate, skipping"
}

#endregion

#region Step 7: Generate AL-Go project configs

Write-Host "`n=== Step 7: Generating AL-Go project configs ==="
$updateScript = Join-Path $BCAppsRepoPath "build\scripts\Update-CountryProjectSettings.ps1"
if (Test-Path $updateScript) {
    # Seed project folder structure from BCAppsPrivate (script only updates existing folders)
    $sourceProjects = Join-Path $BCAppsPrivateRepoPath "build\projects"
    $destProjects = Join-Path $BCAppsRepoPath "build\projects"
    if (Test-Path $destProjects) { Remove-Item $destProjects -Recurse -Force }
    Copy-Item $sourceProjects $destProjects -Recurse -Force
    Write-Host "  Copied project folder structure from BCAppsPrivate"

    Push-Location $BCAppsRepoPath
    & $updateScript
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        throw "Update-CountryProjectSettings.ps1 failed with exit code $LASTEXITCODE"
    }
    Pop-Location
    Write-Host "  Done"
} else {
    Write-Host "  Skipped (Update-CountryProjectSettings.ps1 not found)"
}

#endregion

#region Commit

Write-Host "`n=== Committing changes ==="
$shortSha = $privateHead.Substring(0, 10)
Complete-SyncCommit -RepoPath $BCAppsRepoPath -Message "Sync from BCAppsPrivate $shortSha"

#endregion

Write-Host "`n=== SyncBCAppsPrivateToBCApps complete ==="
