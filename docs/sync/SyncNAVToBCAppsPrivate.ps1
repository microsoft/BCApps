<#
.SYNOPSIS
    Syncs NAV content into BCAppsPrivate by running Script 2 (BCApps -> BCAppsPrivate)
    followed by Script 1 (NAV -> BCAppsPrivate).

.DESCRIPTION
    Uses the BCApps submodule inside NAV (App\BCApps) as the source for Script 2,
    then overlays NAV content via Script 1.

    This is the standard workflow to update BCAppsPrivate from NAV.

.PARAMETER NAVRepoPath
    Path to the NAV repository root (e.g., C:\depot\NAV).

.PARAMETER BCAppsPrivateRepoPath
    Path to the BCAppsPrivate repo (e.g., C:\depot\BCAppsPrivate).

.PARAMETER NAVCommitId
    Expected commit ID (SHA) that the NAV repo should be checked out to.

.PARAMETER BranchName
    Optional branch name. Defaults to sync-<NAVCommitId-short>.

.EXAMPLE
    .\SyncNAVToBCAppsPrivate.ps1 -NAVRepoPath "C:\depot\NAV" -BCAppsPrivateRepoPath "C:\depot\BCAppsPrivate" -NAVCommitId "92899464a7"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $NAVRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $BCAppsPrivateRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $NAVCommitId,

    [Parameter(Mandatory = $false)]
    [string] $BranchName
)

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot

# Derive branch name
$userSuppliedBranch = [bool]$BranchName
if (-not $BranchName) {
    $shortSha = $NAVCommitId.Substring(0, [Math]::Min(10, $NAVCommitId.Length))
    $BranchName = "sync-$shortSha"
}

# BCApps submodule path inside NAV
$bcAppsSubmodule = Join-Path $NAVRepoPath "App\BCApps"
if (-not (Test-Path $bcAppsSubmodule)) {
    throw "BCApps submodule not found at: $bcAppsSubmodule"
}

# Create/checkout branch in BCAppsPrivate before calling child scripts
Write-Host "`n=== Setting up branch '$BranchName' in BCAppsPrivate ==="
Import-Module (Join-Path $scriptDir "Sync.psm1") -Force
Enter-SyncBranch -RepoPath $BCAppsPrivateRepoPath -BranchName $BranchName -New:(-not $userSuppliedBranch)

Write-Host "=== SyncNAVToBCAppsPrivate ==="
Write-Host "  NAV repo: $NAVRepoPath"
Write-Host "  BCApps submodule: $bcAppsSubmodule"
Write-Host "  BCAppsPrivate: $BCAppsPrivateRepoPath"
Write-Host "  Branch: $BranchName"

# Step 1: Sync BCApps (from NAV submodule) -> BCAppsPrivate
Write-Host "`n=== Running SyncBCAppsToBCAppsPrivate (using NAV submodule) ==="
& (Join-Path $scriptDir "SyncBCAppsToBCAppsPrivate.ps1") `
    -BCAppsRepoPath $bcAppsSubmodule `
    -BCAppsPrivateRepoPath $BCAppsPrivateRepoPath

# Step 2: Sync NAV -> BCAppsPrivate
Write-Host "`n=== Running SyncNAVToTarget ==="
& (Join-Path $scriptDir "SyncNAVToTarget.ps1") `
    -NAVRepoPath $NAVRepoPath `
    -TargetRepoPath $BCAppsPrivateRepoPath `
    -NAVCommitId $NAVCommitId `
    -BranchName $BranchName `
    -NoCommit

# Single commit at the end
Write-Host "`n=== Committing changes ==="
$shortSha = $NAVCommitId.Substring(0, [Math]::Min(10, $NAVCommitId.Length))
$bcAppsHead = (git -C $bcAppsSubmodule rev-parse HEAD 2>&1).Trim()
$navHead = (git -C $NAVRepoPath rev-parse HEAD 2>&1).Trim()
Set-SyncState -BCAppsPrivateRepoPath $BCAppsPrivateRepoPath -BCAppsCommit $bcAppsHead -NAVCommit $navHead
Complete-SyncCommit -RepoPath $BCAppsPrivateRepoPath -Message "Sync from NAV $shortSha"

Write-Host "`n=== SyncNAVToBCAppsPrivate complete ==="
