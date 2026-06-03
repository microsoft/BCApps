<#
.SYNOPSIS
    Synchronizes application source code from the NAV repository into this repo.

.DESCRIPTION
    Copies src/ folder contents from the NAV repo (App/BCApps submodule + App/Apps + App/Layers + GDL + App/Demotool)
    into the current repository's src/ folder, merges .github/AL-Go-Settings.json, copies build metadata,
    then replaces version variables in app.json files.

    The mapping is:
      - src/Layers       <- App/Layers (NAV)
      - src/GDL          <- GDL/ (NAV)
      - src/DemoTool     <- App/Demotool (NAV)
      - src/Apps         <- App/BCApps/src/Apps (base) + App/Apps (overlay)
      - src/Business Foundation <- App/BCApps/src/Business Foundation
      - src/System Application  <- App/BCApps/src/System Application
      - src/Tools               <- App/BCApps/src/Tools
      - src/*.code-workspace    <- App/BCApps/src/*.code-workspace

    src/DisabledTests is merged (new entries from NAV are added, existing entries preserved).
    src/rulesets is merged via 3-way git merge (base from main, theirs from NAV).

.PARAMETER NAVRepoPath
    Path to the NAV repository root (e.g., C:\depot\NAV).

.PARAMETER NAVCommitId
    Expected commit ID (SHA) that the NAV repo should be checked out to.
    The script will verify the NAV repo HEAD matches this commit before proceeding.

.EXAMPLE
    .\build\scripts\SyncFromNAV.ps1 -NAVRepoPath "C:\depot\NAV" -NAVCommitId "92899464a7"
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $NAVRepoPath,

    [Parameter(Mandatory = $true)]
    [string] $NAVCommitId
)

$ErrorActionPreference = "Stop"

# Verify NAV repo is on the expected commit
Write-Host "=== Verifying NAV repo commit ==="
$navHead = (git -C $NAVRepoPath rev-parse HEAD 2>&1).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Failed to get HEAD commit from NAV repo at '$NAVRepoPath'. Is it a git repository?"
}
$matchLen = [Math]::Min($NAVCommitId.Length, $navHead.Length)
if ($navHead.Substring(0, $matchLen) -ne $NAVCommitId.Substring(0, $matchLen)) {
    throw "NAV repo HEAD ($navHead) does not match expected commit ($NAVCommitId)"
}
Write-Host "  NAV repo confirmed at commit: $navHead"

# Verify NAV repo has no pending changes
$navStatus = (git -C $NAVRepoPath status --porcelain 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to check NAV repo status"
}
if ($navStatus) {
    throw "NAV repo has pending changes. Please commit or discard them before syncing."
}

# Validate paths
$bcAppsSubmodule = Join-Path $NAVRepoPath "App\BCApps"
$navApps = Join-Path $NAVRepoPath "App\Apps"
$navLayers = Join-Path $NAVRepoPath "App\Layers"
$navDemotool = Join-Path $NAVRepoPath "App\Demotool"
$navGDL = Join-Path $NAVRepoPath "GDL"

foreach ($path in @($bcAppsSubmodule, $navApps, $navLayers, $navDemotool, $navGDL)) {
    if (-not (Test-Path $path)) {
        throw "Required path not found: $path"
    }
}

$repoRoot = $PSScriptRoot | Split-Path | Split-Path
$srcRoot = Join-Path $repoRoot "src"

if (-not (Test-Path $srcRoot)) {
    throw "src/ folder not found at $srcRoot"
}

# Get repo version from AL-Go settings
$alGoSettings = Join-Path $repoRoot ".github\AL-Go-Settings.json"
$repoVersion = (Get-Content $alGoSettings | ConvertFrom-Json).repoVersion
$version = "$repoVersion.0.0"
Write-Host "Repo version: $version"

function Invoke-Robocopy {
    param(
        [string] $Source,
        [string] $Destination,
        [string[]] $Arguments
    )
    $allArgs = @($Source, $Destination) + $Arguments
    & robocopy @allArgs
    # Robocopy exit codes: 0 = no change, 1 = files copied, 2 = extra files in dest, 3 = 1+2
    # Codes 0-7 are success; 8+ are errors
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed with exit code $LASTEXITCODE copying '$Source' to '$Destination'"
    }
}

# --- 1. Merge .github/AL-Go-Settings.json from BCApps ---
Write-Host "`n=== Merging .github/AL-Go-Settings.json ==="
$alGoFile = Join-Path $repoRoot ".github\AL-Go-Settings.json"
$alGoTheirs = Join-Path $bcAppsSubmodule ".github\AL-Go-Settings.json"
$alGoBase = Join-Path $repoRoot ".github\AL-Go-Settings.base.json"

# Get the base version (from main branch) for 3-way merge
git -C $repoRoot show main:.github/AL-Go-Settings.json > $alGoBase 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not get base from main, copying NAV version directly"
    Copy-Item $alGoTheirs $alGoFile -Force
} else {
    git merge-file $alGoFile $alGoBase $alGoTheirs
    $mergeResult = $LASTEXITCODE
    if ($mergeResult -gt 0) {
        Write-Warning "  $mergeResult conflict(s) in AL-Go-Settings.json - please resolve manually"
    } elseif ($mergeResult -eq 0) {
        Write-Host "  Merged cleanly"
    } else {
        throw "git merge-file failed for AL-Go-Settings.json"
    }
}
if (Test-Path $alGoBase) { Remove-Item $alGoBase -Force }

# --- 2. Mirror src/Layers from App/Layers ---
Write-Host "`n=== Syncing src/Layers from App/Layers ==="
Invoke-Robocopy -Source $navLayers -Destination (Join-Path $srcRoot "Layers") -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")

# --- 3. Mirror src/GDL from GDL/ ---
Write-Host "=== Syncing src/GDL from GDL/ ==="
Invoke-Robocopy -Source $navGDL -Destination (Join-Path $srcRoot "GDL") -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")

# --- 4. Mirror src/DemoTool from App/Demotool ---
Write-Host "=== Syncing src/DemoTool from App/Demotool ==="
Invoke-Robocopy -Source $navDemotool -Destination (Join-Path $srcRoot "DemoTool") -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")

# --- 5. Sync src/Apps (BCApps base + App/Apps overlay) ---
Write-Host "=== Syncing src/Apps (BCApps base + App/Apps overlay) ==="
$srcApps = Join-Path $srcRoot "Apps"

# Remove existing Apps folder and start fresh
if (Test-Path $srcApps) {
    Remove-Item $srcApps -Recurse -Force
}

# Copy BCApps/src/Apps as the base (contains W1 apps)
$bcAppsApps = Join-Path $bcAppsSubmodule "src\Apps"
Write-Host "  Copying BCApps/src/Apps (W1 base)..."
Invoke-Robocopy -Source $bcAppsApps -Destination $srcApps -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")

# Overlay App/Apps on top (all countries + additional W1 content)
# First copy all non-W1 folders (countries)
Write-Host "  Overlaying App/Apps (all countries)..."
Invoke-Robocopy -Source $navApps -Destination $srcApps -Arguments @("/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")

# Force-copy App/Apps/W1 to ensure NAV-specific W1 apps overwrite BCApps versions where they exist
$navAppsW1 = Join-Path $navApps "W1"
if (Test-Path $navAppsW1) {
    Write-Host "  Force-overlaying App/Apps/W1..."
    Invoke-Robocopy -Source $navAppsW1 -Destination (Join-Path $srcApps "W1") -Arguments @("/E", "/IS", "/IT", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
}

# --- 6. Mirror remaining BCApps/src folders (Business Foundation, System Application, Tools) ---
Write-Host "=== Syncing remaining folders from BCApps/src ==="
$bcAppsFolders = @("Business Foundation", "System Application", "Tools")
foreach ($folder in $bcAppsFolders) {
    $source = Join-Path $bcAppsSubmodule "src\$folder"
    $destination = Join-Path $srcRoot $folder
    if (Test-Path $source) {
        Write-Host "  Syncing $folder..."
        Invoke-Robocopy -Source $source -Destination $destination -Arguments @("/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NS", "/NC", "/NP")
    } else {
        Write-Warning "Source not found, skipping: $source"
    }
}

# --- 7. Copy workspace files from BCApps/src ---
Write-Host "=== Copying workspace files ==="
$bcAppsSrc = Join-Path $bcAppsSubmodule "src"
Get-ChildItem -Path $bcAppsSrc -File -Filter "*.code-workspace" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $srcRoot $_.Name) -Force
    Write-Host "  Copied $($_.Name)"
}

# --- 8. Copy build/projects.json and build/groups.json from Eng/Core/Build ---
Write-Host "=== Syncing build/projects.json and build/groups.json ==="
$buildRoot = Join-Path $repoRoot "build"
$navBuildRoot = Join-Path $NAVRepoPath "Eng\Core\Build"
foreach ($buildFile in @("projects.json", "groups.json")) {
    $source = Join-Path $navBuildRoot $buildFile
    $destination = Join-Path $buildRoot $buildFile
    if (Test-Path $source) {
        Copy-Item $source $destination -Force
        Write-Host "  Copied $buildFile"
    } else {
        Write-Warning "Source not found, skipping: $source"
    }
}

# Run Update-CountryProjectSettings.ps1 to regenerate country-specific project files
Write-Host "=== Running Update-CountryProjectSettings.ps1 ==="
$updateScript = Join-Path $repoRoot "build\scripts\Update-CountryProjectSettings.ps1"
& $updateScript
if ($LASTEXITCODE -ne 0) {
    throw "Update-CountryProjectSettings.ps1 failed with exit code $LASTEXITCODE"
}

# --- 9. Merge src/rulesets from BCApps/src/rulesets ---
Write-Host "`n=== Merging src/rulesets from BCApps/src/rulesets ==="
$navRulesets = Join-Path $bcAppsSubmodule "src\rulesets"
$privateRulesets = Join-Path $srcRoot "rulesets"
if (Test-Path $navRulesets) {
    $navRulesetFiles = Get-ChildItem $navRulesets -Filter "*.ruleset.json"
    $mergeConflicts = @()
    foreach ($navFile in $navRulesetFiles) {
        $privatePath = Join-Path $privateRulesets $navFile.Name
        if (-not (Test-Path $privatePath)) {
            # New file in NAV, just copy it
            Copy-Item $navFile.FullName $privatePath -Force
            Write-Host "  Added new file: $($navFile.Name)"
            continue
        }
        # 3-way merge: get base from main branch
        $basePath = Join-Path $env:TEMP "ruleset-base-$($navFile.Name)"
        git -C $repoRoot show "main:src/rulesets/$($navFile.Name)" > $basePath 2>$null
        if ($LASTEXITCODE -ne 0) {
            # No base available, copy NAV version
            Copy-Item $navFile.FullName $privatePath -Force
            Write-Host "  Copied (no base): $($navFile.Name)"
        } else {
            git merge-file $privatePath $basePath $navFile.FullName
            $mergeResult = $LASTEXITCODE
            if ($mergeResult -gt 0) {
                Write-Warning "  $mergeResult conflict(s) in $($navFile.Name) - please resolve manually"
                $mergeConflicts += $navFile.Name
            } elseif ($mergeResult -eq 0) {
                Write-Host "  Merged cleanly: $($navFile.Name)"
            } else {
                throw "git merge-file failed for $($navFile.Name)"
            }
        }
        if (Test-Path $basePath) { Remove-Item $basePath -Force }
    }
    if ($mergeConflicts.Count -gt 0) {
        Write-Warning "  Ruleset files with conflicts: $($mergeConflicts -join ', ')"
    }
} else {
    Write-Warning "NAV rulesets path not found: $navRulesets"
}

# --- 10. Merge DisabledTests from NAV into src/DisabledTests ---
Write-Host "`n=== Merging DisabledTests from NAV ==="
$privateDisabledTests = Join-Path $srcRoot "DisabledTests"

# Collect all NAV disabled test JSON files from known locations
$navDisabledTestFiles = @()
$navDisabledTestsDir = Join-Path $NAVRepoPath "App\DisabledTests"
if (Test-Path $navDisabledTestsDir) {
    $navDisabledTestFiles += Get-ChildItem $navDisabledTestsDir -Recurse -Filter "*.DisabledTest.json"
}
# Also check embedded DisabledTests in BCApps source (e.g. in app test folders)
$bcAppsDisabledTests = Get-ChildItem $bcAppsSubmodule -Recurse -Filter "*.DisabledTest.json" -File 2>$null
if ($bcAppsDisabledTests) {
    $navDisabledTestFiles += $bcAppsDisabledTests
}

Write-Host "  Found $($navDisabledTestFiles.Count) NAV disabled test files"

# Build index of Private files: codeunitId -> file path
$privateIndex = @{} # codeunitId -> Private file path
$privateFileContents = @{} # file path -> array of entries
$privateFiles = Get-ChildItem $privateDisabledTests -Recurse -Filter "*.DisabledTest.json"
foreach ($pf in $privateFiles) {
    $entries = Get-Content $pf.FullName -Raw | ConvertFrom-Json
    $privateFileContents[$pf.FullName] = $entries
    foreach ($entry in $entries) {
        if (-not $privateIndex.ContainsKey($entry.codeunitId)) {
            $privateIndex[$entry.codeunitId] = $pf.FullName
        }
    }
}

# Merge NAV entries into Private
$addedCount = 0
$unmappedCodeunits = @()
$modifiedFiles = @{}
foreach ($navFile in $navDisabledTestFiles) {
    $navEntries = Get-Content $navFile.FullName -Raw | ConvertFrom-Json
    foreach ($navEntry in $navEntries) {
        $targetFile = $privateIndex[$navEntry.codeunitId]
        if (-not $targetFile) {
            # New codeunit not in any Private file - track for warning
            $key = "$($navEntry.codeunitId)|$($navEntry.codeunitName)"
            if ($unmappedCodeunits -notcontains $key) {
                $unmappedCodeunits += $key
            }
            continue
        }

        $existingEntries = $privateFileContents[$targetFile]

        # Skip if Private already has a wildcard for this codeunit
        $hasWildcard = $existingEntries | Where-Object { $_.codeunitId -eq $navEntry.codeunitId -and $_.method -eq '*' }
        if ($hasWildcard) { continue }

        # If NAV entry is wildcard, add it and it subsumes all individual methods
        if ($navEntry.method -eq '*') {
            $alreadyExists = $existingEntries | Where-Object { $_.codeunitId -eq $navEntry.codeunitId -and $_.method -eq '*' }
            if (-not $alreadyExists) {
                $privateFileContents[$targetFile] = @($existingEntries) + @($navEntry)
                $modifiedFiles[$targetFile] = $true
                $addedCount++
            }
            continue
        }

        # Check if this specific entry already exists
        $exists = $existingEntries | Where-Object {
            $_.codeunitId -eq $navEntry.codeunitId -and $_.method -eq $navEntry.method
        }
        if (-not $exists) {
            $privateFileContents[$targetFile] = @($existingEntries) + @($navEntry)
            $modifiedFiles[$targetFile] = $true
            $addedCount++
        }
    }
}

# Write back only files that were actually modified
foreach ($filePath in $modifiedFiles.Keys) {
    $entries = $privateFileContents[$filePath]
    $json = $entries | ConvertTo-Json -Depth 10
    if ($entries.Count -eq 1) {
        # ConvertTo-Json doesn't wrap single items in array
        $json = "[$json]"
    }
    Set-Content $filePath $json -NoNewline
}

Write-Host "  Added $addedCount new entries to existing DisabledTest files"
if ($unmappedCodeunits.Count -gt 0) {
    Write-Warning "  $($unmappedCodeunits.Count) codeunit(s) from NAV not found in any Private DisabledTest file:"
    foreach ($uc in $unmappedCodeunits) {
        $parts = $uc -split '\|'
        Write-Warning "    Codeunit $($parts[0]): $($parts[1])"
    }
    Write-Warning "  These may need manual mapping to the appropriate test app file."
}

# --- 11. Replace version variables in app.json files ---
Write-Host "`n=== Replacing version variables in app.json files ==="
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

# --- Verify ---
$remaining = Get-ChildItem -Path $srcRoot -Recurse -Filter "app.json" | Where-Object {
    (Get-Content $_.FullName -Raw) -match '\$\(app_(currentVersion|minimumVersion|platformVersion)\)'
}
if ($remaining.Count -gt 0) {
    Write-Warning "  $($remaining.Count) files still have version variables!"
    $remaining | ForEach-Object { Write-Warning "    $($_.FullName)" }
} else {
    Write-Host "  Verified: no version variables remaining"
}

Write-Host "`n=== Sync complete ==="
Write-Host "Review changes with 'git status' before committing."
