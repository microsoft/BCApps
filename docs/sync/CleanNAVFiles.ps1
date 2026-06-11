<#
.SYNOPSIS
    Removes NAV files that are identical to their BCApps counterparts.

.DESCRIPTION
    Compares all files that SyncNAVToTarget copies from NAV into BCApps.
    If a NAV file is identical to the corresponding BCApps file, deletes
    the NAV version. Reports files that differ at the end.

    Mappings checked:
      - App/Layers      -> src/Layers
      - GDL             -> src/GDL
      - App/Demotool    -> src/DemoTool
      - App/Apps        -> src/Apps
      - App/DisabledTests -> src/DisabledTests
      - Eng/Core/Build/projects.json -> build/projects.json
      - Eng/Core/Build/groups.json   -> build/groups.json

.PARAMETER NAVRepoPath
    Path to the NAV repository root.

.PARAMETER BCAppsRepoPath
    Path to the BCApps repository root.

.PARAMETER BranchName
    Optional branch name for NAV repo. Defaults to clean-nav-<BCApps-HEAD-short>.

.EXAMPLE
    .\CleanNAVFiles.ps1 -NAVRepoPath "C:\depot\NAV" -BCAppsRepoPath "C:\depot\BCApps"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $NAVRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $BCAppsRepoPath,

    [Parameter(Mandatory = $false)]
    [string] $BranchName
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Sync.psm1") -Force

#region Verification and Branch Setup

Write-Host "=== Verifying repos ==="
$bcAppsHead = (git -C $BCAppsRepoPath rev-parse HEAD 2>&1).Trim()
if ($LASTEXITCODE -ne 0) { throw "Failed to get HEAD from BCApps repo" }
Write-Host "  BCApps HEAD: $bcAppsHead"

$navStatus = (git -C $NAVRepoPath status --porcelain 2>&1)
if ($LASTEXITCODE -ne 0) { throw "Failed to check NAV repo status" }
if ($navStatus) { throw "NAV repo has pending changes." }

$userSuppliedBranch = [bool]$BranchName
if (-not $BranchName) {
    $shortSha = $bcAppsHead.Substring(0, [Math]::Min(10, $bcAppsHead.Length))
    $BranchName = "clean-nav-$shortSha"
}

Write-Host "`n=== Setting up branch '$BranchName' in NAV ==="
Enter-SyncBranch -RepoPath $NAVRepoPath -BranchName $BranchName -New:(-not $userSuppliedBranch)

#endregion

# Mapping: NAV source path -> BCApps relative destination
$folderMappings = @(
    @{ NAV = "App\Layers";       BCApps = "src\Layers" }
    @{ NAV = "GDL";              BCApps = "src\GDL" }
    @{ NAV = "App\Demotool";     BCApps = "src\DemoTool" }
    @{ NAV = "App\Apps";         BCApps = "src\Apps" }
)

$fileMappings = @(
    @{ NAV = "Eng\Core\Build\projects.json"; BCApps = "build\projects.json" }
    @{ NAV = "Eng\Core\Build\groups.json";   BCApps = "build\groups.json" }
)

$deletedCount = 0
$keptFiles = @()

function Test-FilesIdentical([string]$FileA, [string]$FileB) {
    # For app.json, compare ignoring version-related fields
    if ((Split-Path $FileA -Leaf) -eq "app.json") {
        $jsonA = Get-Content $FileA -Raw | ConvertFrom-Json
        $jsonB = Get-Content $FileB -Raw | ConvertFrom-Json
        foreach ($obj in @($jsonA, $jsonB)) {
            $obj.version = ""
            if ($obj.PSObject.Properties["platform"]) { $obj.platform = "" }
            if ($obj.PSObject.Properties["application"]) { $obj.application = "" }
            if ($obj.PSObject.Properties["dependencies"]) {
                foreach ($dep in $obj.dependencies) { $dep.version = "" }
            }
        }
        return (($jsonA | ConvertTo-Json -Depth 100) -eq ($jsonB | ConvertTo-Json -Depth 100))
    }
    $hashA = (Get-FileHash $FileA -Algorithm MD5).Hash
    $hashB = (Get-FileHash $FileB -Algorithm MD5).Hash
    return $hashA -eq $hashB
}

# Process folder mappings
foreach ($mapping in $folderMappings) {
    $navFolder = Join-Path $NAVRepoPath $mapping.NAV
    $bcAppsFolder = Join-Path $BCAppsRepoPath $mapping.BCApps

    if (-not (Test-Path $navFolder)) {
        Write-Host "  Skipping (not found): $($mapping.NAV)"
        continue
    }

    Write-Host "Comparing $($mapping.NAV) ..."
    $navFiles = Get-ChildItem $navFolder -Recurse -File
    foreach ($nf in $navFiles) {
        $relativePath = $nf.FullName.Substring($navFolder.Length + 1)
        $bcAppsFile = Join-Path $bcAppsFolder $relativePath

        if (-not (Test-Path $bcAppsFile)) {
            $keptFiles += "$($mapping.NAV)\$relativePath (not in BCApps)"
            continue
        }

        if (Test-FilesIdentical $nf.FullName $bcAppsFile) {
            Remove-Item $nf.FullName -Force
            $deletedCount++
        } else {
            $keptFiles += "$($mapping.NAV)\$relativePath (differs)"
        }
    }
}

# Process individual file mappings
foreach ($mapping in $fileMappings) {
    $navFile = Join-Path $NAVRepoPath $mapping.NAV
    $bcAppsFile = Join-Path $BCAppsRepoPath $mapping.BCApps

    if (-not (Test-Path $navFile)) { continue }
    if (-not (Test-Path $bcAppsFile)) {
        $keptFiles += "$($mapping.NAV) (not in BCApps)"
        continue
    }

    if (Test-FilesIdentical $navFile $bcAppsFile) {
        Remove-Item $navFile -Force
        $deletedCount++
    } else {
        $keptFiles += "$($mapping.NAV) (differs)"
    }
}

# Clean up empty directories left behind
foreach ($mapping in $folderMappings) {
    $navFolder = Join-Path $NAVRepoPath $mapping.NAV
    if (Test-Path $navFolder) {
        Get-ChildItem $navFolder -Recurse -Directory |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { (Get-ChildItem $_.FullName -File -Recurse).Count -eq 0 } |
            ForEach-Object { Remove-Item $_.FullName -Force }
    }
}

# Report
Write-Host "`n=== Summary ==="
Write-Host "  Deleted: $deletedCount identical files from NAV"
if ($keptFiles.Count -gt 0) {
    Write-Host "  Kept: $($keptFiles.Count) files that differ or are not in BCApps:"
    foreach ($f in $keptFiles) {
        Write-Host "    $f"
    }
} else {
    Write-Host "  All NAV files were identical to BCApps"
}

#region Commit

Write-Host "`n=== Committing changes ==="
$shortSha = $bcAppsHead.Substring(0, 10)
Complete-SyncCommit -RepoPath $NAVRepoPath -Message "Clean NAV files identical to BCApps $shortSha"

#endregion
