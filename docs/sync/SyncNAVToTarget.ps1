<#
.SYNOPSIS
    Syncs NAV content into a target repo (BCApps or BCAppsPrivate).

.DESCRIPTION
    Copies src/ folder contents from the NAV repo (App/Apps, App/Layers, GDL, App/Demotool)
    into the target repository's src/ folder, merges DisabledTests,
    copies build metadata, replaces version variables in app.json files, and
    optionally generates country project configs.

    Creates a branch and commits changes.

.PARAMETER NAVRepoPath
    Path to the NAV repository root (e.g., C:\depot\NAV).

.PARAMETER TargetRepoPath
    Path to the target repository (BCApps or BCAppsPrivate).

.PARAMETER NAVCommitId
    Expected commit ID (SHA) that the NAV repo should be checked out to.

.PARAMETER BranchName
    Optional branch name. Defaults to sync-<NAVCommitId-short>.

.EXAMPLE
    .\SyncNAVToTarget.ps1 -NAVRepoPath "C:\depot\NAV" -TargetRepoPath "C:\depot\BCApps" -NAVCommitId "92899464a7"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $NAVRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $TargetRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $NAVCommitId,

    [Parameter(Mandatory = $false)]
    [string] $BranchName,

    [switch] $NoCommit
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Sync.psm1") -Force

#region Verification

Write-Host "=== Verifying NAV repo ==="
$navHead = (git -C $NAVRepoPath rev-parse HEAD 2>&1).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Failed to get HEAD commit from NAV repo at '$NAVRepoPath'. Is it a git repository?"
}
if (-not $navHead.StartsWith($NAVCommitId, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "NAV repo HEAD ($navHead) does not match expected commit ($NAVCommitId)"
}
Write-Host "  NAV repo confirmed at commit: $navHead"

$navStatus = (git -C $NAVRepoPath status --porcelain 2>&1)
if ($LASTEXITCODE -ne 0) { throw "Failed to check NAV repo status" }
if ($navStatus) { throw "NAV repo has pending changes. Please commit or discard them before syncing." }

if (-not $NoCommit) {
    $targetStatus = (git -C $TargetRepoPath status --porcelain 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Failed to check target repo status" }
    if ($targetStatus) { throw "Target repo has pending changes. Please commit or discard them before syncing." }
}

# Verify BCApps submodule commit
$bcAppsSubmodule = Join-Path $NAVRepoPath "App\BCApps"
if (Test-Path $bcAppsSubmodule) {
    $submoduleHead = (git -C $bcAppsSubmodule rev-parse HEAD 2>&1).Trim()
    $targetHead = (git -C $TargetRepoPath rev-parse HEAD 2>&1).Trim()
    Write-Host "  BCApps submodule in NAV: $submoduleHead"
    Write-Host "  Target repo HEAD: $targetHead"
}

#endregion

#region Branch Setup

$userSuppliedBranch = [bool]$BranchName
if (-not $BranchName) {
    $shortSha = $NAVCommitId.Substring(0, [Math]::Min(10, $NAVCommitId.Length))
    $BranchName = "sync-$shortSha"
}

Write-Host "`n=== Setting up branch '$BranchName' in target repo ==="
Enter-SyncBranch -RepoPath $TargetRepoPath -BranchName $BranchName -New:(-not $userSuppliedBranch)

#endregion

#region Read Version

$alGoSettings = Join-Path $TargetRepoPath ".github\AL-Go-Settings.json"
$repoVersion = (Get-Content $alGoSettings | ConvertFrom-Json).repoVersion
$version = "$repoVersion.0.0"
Write-Host "Repo version: $version"

#endregion

#region Validate Paths

$navApps = Join-Path $NAVRepoPath "App\Apps"
$navLayers = Join-Path $NAVRepoPath "App\Layers"
$navDemotool = Join-Path $NAVRepoPath "App\Demotool"
$navGDL = Join-Path $NAVRepoPath "GDL"
$navDisabledTests = Join-Path $NAVRepoPath "App\DisabledTests"
$navBuild = Join-Path $NAVRepoPath "Eng\Core\Build"

$srcRoot = Join-Path $TargetRepoPath "src"
$buildRoot = Join-Path $TargetRepoPath "build"

#endregion

#region Step 3: Mirror src/Layers

Write-Host "`n=== Step 3: Syncing src/Layers ==="
$destLayers = Join-Path $srcRoot "Layers"
if (Test-Path $navLayers) {
    Invoke-Robocopy -Source $navLayers -Destination $destLayers -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    Write-Host "  Done"
} else {
    Write-Warning "  NAV Layers not found: $navLayers"
}

#endregion

#region Step 4: Mirror src/GDL

Write-Host "=== Step 4: Syncing src/GDL ==="
$destGDL = Join-Path $srcRoot "GDL"
if (Test-Path $navGDL) {
    Invoke-Robocopy -Source $navGDL -Destination $destGDL -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    Write-Host "  Done"
} else {
    Write-Warning "  NAV GDL not found: $navGDL"
}

#endregion

#region Step 5: Mirror src/DemoTool

Write-Host "=== Step 5: Syncing src/DemoTool ==="
$destDemoTool = Join-Path $srcRoot "DemoTool"
if (Test-Path $navDemotool) {
    Invoke-Robocopy -Source $navDemotool -Destination $destDemoTool -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    Write-Host "  Done"
} else {
    Write-Warning "  NAV Demotool not found: $navDemotool"
}

#endregion

#region Step 6: Sync src/Apps

Write-Host "=== Step 6: Syncing src/Apps (NAV overlay) ==="
$destApps = Join-Path $srcRoot "Apps"
if (-not (Test-Path $destApps)) {
    New-Item -ItemType Directory -Path $destApps -Force | Out-Null
}

if (Test-Path $navApps) {
    # Copy root-level files (e.g. ExtensionGroups.json)
    $rootFiles = Get-ChildItem $navApps -File
    foreach ($f in $rootFiles) {
        Copy-Item $f.FullName (Join-Path $destApps $f.Name) -Force
    }

    # Copy all non-W1 country folders
    $countryFolders = Get-ChildItem $navApps -Directory | Where-Object { $_.Name -ne "W1" }
    foreach ($folder in $countryFolders) {
        $dest = Join-Path $destApps $folder.Name
        Invoke-Robocopy -Source $folder.FullName -Destination $dest -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    }
    Write-Host "  Copied $($countryFolders.Count) country folders"

    # For W1: only copy files that do NOT already exist (preserve BCApps W1)
    $navAppsW1 = Join-Path $navApps "W1"
    $destAppsW1 = Join-Path $destApps "W1"
    if (Test-Path $navAppsW1) {
        if (-not (Test-Path $destAppsW1)) {
            New-Item -ItemType Directory -Path $destAppsW1 -Force | Out-Null
        }
        # /E = recursive, /XC /XN /XO = exclude Changed/Newer/Older (only copy new files)
        Invoke-Robocopy -Source $navAppsW1 -Destination $destAppsW1 -Arguments @("/E", "/XC", "/XN", "/XO", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
        Write-Host "  Overlaid NAV W1 (new files only, preserving BCApps)"
    }
} else {
    Write-Warning "  NAV Apps not found: $navApps"
}

#endregion

#region Step 7: Copy build metadata

Write-Host "=== Step 7: Copying build metadata ==="
if (Test-Path $navBuild) {
    foreach ($buildFile in @("projects.json", "groups.json")) {
        $source = Join-Path $navBuild $buildFile
        $destination = Join-Path $buildRoot $buildFile
        if (Test-Path $source) {
            Copy-Item $source $destination -Force
            Write-Host "  Copied $buildFile"
        }
    }
} else {
    Write-Warning "  NAV Eng\Core\Build not found: $navBuild"
}

#endregion

#region Step 8: Merge DisabledTests

Write-Host "`n=== Step 8: Merging DisabledTests ==="
$destDisabledTests = Join-Path $srcRoot "DisabledTests"
$navDTFiles = Get-ChildItem $navDisabledTests -Recurse -Filter "*.DisabledTest.json" -File
Merge-DisabledTests -SourceFiles $navDTFiles -TargetDir $destDisabledTests

#endregion

#region Step 9: Replace version tokens

Write-Host "`n=== Step 9: Replacing version tokens in app.json ==="
$appJsonFiles = Get-ChildItem -Path $srcRoot -Recurse -Filter "app.json" | Where-Object {
    (Get-Content $_.FullName -Raw) -match '\$\(app_(currentVersion|minimumVersion|platformVersion)\)'
}

Write-Host "  Found $($appJsonFiles.Count) files with version variables"
foreach ($file in $appJsonFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace '\$\(app_currentVersion\)', $version
    $content = $content -replace '\$\(app_minimumVersion\)', $version
    $content = $content -replace '\$\(app_platformVersion\)', $version
    Set-Content $file.FullName $content -NoNewline
}
Write-Host "  Replaced version variables with $version in $($appJsonFiles.Count) files"

# Verify
$remaining = Get-ChildItem -Path $srcRoot -Recurse -Filter "app.json" | Where-Object {
    (Get-Content $_.FullName -Raw) -match '\$\(app_(currentVersion|minimumVersion|platformVersion)\)'
}
if ($remaining.Count -gt 0) {
    Write-Warning "  $($remaining.Count) files still have version variables!"
    $remaining | ForEach-Object { Write-Warning "    $($_.FullName)" }
} else {
    Write-Host "  Verified: no version variables remaining"
}

#endregion

#region Step 10: Generate country project configs

Write-Host "`n=== Step 10: Generate country project configs ==="
$updateScript = Join-Path $TargetRepoPath "build\scripts\Update-CountryProjectSettings.ps1"
if (Test-Path $updateScript) {
    Push-Location $TargetRepoPath
    & $updateScript
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        throw "Update-CountryProjectSettings.ps1 failed with exit code $LASTEXITCODE"
    }
    Pop-Location
    Write-Host "  Done"
} else {
    Write-Host "  Skipped (Update-CountryProjectSettings.ps1 not found in target)"
}

#endregion

#region Commit

if (-not $NoCommit) {
    Write-Host "`n=== Committing changes ==="
    $shortSha = $navHead.Substring(0, 10)
    Complete-SyncCommit -RepoPath $TargetRepoPath -Message "Sync from NAV $shortSha"
}

#endregion

Write-Host "`n=== SyncNAVToTarget complete ==="
