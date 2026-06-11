<#
.SYNOPSIS
    Syncs BCApps shared source into BCAppsPrivate.

.DESCRIPTION
    Mirrors BCApps source folders (System Application, Business Foundation, Tools,
    Apps, workspace files) into BCAppsPrivate.

    Intended to be called from SyncNAVToBCAppsPrivate.ps1 (not standalone).
    Branch setup and commit are handled by the wrapper.

.PARAMETER BCAppsRepoPath
    Path to the BCApps repo (or NAV submodule at App\BCApps).

.PARAMETER BCAppsPrivateRepoPath
    Path to the BCAppsPrivate repo.
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $BCAppsRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $BCAppsPrivateRepoPath
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Sync.psm1") -Force

#region Step 0: Merge shared files

Write-Host "`n=== Step 0: Merging shared files ==="
$syncState = Get-SyncState -BCAppsPrivateRepoPath $BCAppsPrivateRepoPath
$baseCommit = $syncState.lastSyncedBCAppsCommit

Merge-SharedFiles -SourceRepoPath $BCAppsRepoPath -TargetRepoPath $BCAppsPrivateRepoPath -BaseRepoPath $BCAppsRepoPath -BaseCommit $baseCommit

#endregion

#region Step 1: Mirror src/System Application, Business Foundation, Tools

Write-Host "`n=== Step 1: Syncing BCApps folders ==="
$mirrorFolders = @("System Application", "Business Foundation", "Tools")
foreach ($folder in $mirrorFolders) {
    $source = Join-Path $BCAppsRepoPath "src\$folder"
    $dest = Join-Path $BCAppsPrivateRepoPath "src\$folder"
    if (Test-Path $source) {
        Invoke-Robocopy -Source $source -Destination $dest -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
        Write-Host "  Synced $folder"
    } else {
        Write-Warning "  Source not found: $source"
    }
}

#endregion

#region Step 2: Rebuild src/Apps from BCApps base

Write-Host "`n=== Step 2: Rebuilding src/Apps from BCApps ==="
$srcApps = Join-Path $BCAppsPrivateRepoPath "src\Apps"
$bcAppsApps = Join-Path $BCAppsRepoPath "src\Apps"

# Remove existing Apps folder and rebuild from BCApps (NAV overlay comes later)
if (Test-Path $srcApps) {
    Remove-Item $srcApps -Recurse -Force
}
Invoke-Robocopy -Source $bcAppsApps -Destination $srcApps -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
Write-Host "  Done"

#endregion

#region Step 3: Copy workspace files

Write-Host "`n=== Step 3: Copying workspace files ==="
$bcAppsSrc = Join-Path $BCAppsRepoPath "src"
$privateSrc = Join-Path $BCAppsPrivateRepoPath "src"
$workspaceFiles = Get-ChildItem -Path $bcAppsSrc -File -Filter "*.code-workspace"
foreach ($wf in $workspaceFiles) {
    Copy-Item $wf.FullName (Join-Path $privateSrc $wf.Name) -Force
    Write-Host "  Copied $($wf.Name)"
}

#endregion

#region Step 4: Merge rulesets

Write-Host "`n=== Step 4: Merging rulesets from BCApps ==="
$sourceRulesets = Join-Path $BCAppsRepoPath "src\rulesets"
$destRulesets = Join-Path $BCAppsPrivateRepoPath "src\rulesets"
if (-not (Test-Path $destRulesets)) {
    New-Item -ItemType Directory -Path $destRulesets -Force | Out-Null
}
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

#endregion

#region Step 5: Merge DisabledTests

Write-Host "`n=== Step 5: Merging DisabledTests from BCApps ==="
$bcAppsDisabledTestFiles = @(Get-ChildItem $BCAppsRepoPath -Recurse -Filter "*.DisabledTest.json" -File)
$privateDisabledTests = Join-Path $BCAppsPrivateRepoPath "src\DisabledTests"
Merge-DisabledTests -SourceFiles $bcAppsDisabledTestFiles -TargetDir $privateDisabledTests

#endregion

Write-Host "`n=== SyncBCAppsToBCAppsPrivate complete ==="
