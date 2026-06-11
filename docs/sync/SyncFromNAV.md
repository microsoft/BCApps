# SyncFromNAV.ps1 - Analysis

Script location: `BCAppsPrivate\build\scripts\SyncFromNAV.ps1`

## Purpose

Synchronizes application source code from the NAV repository into BCAppsPrivate.
Takes two parameters:
- `NAVRepoPath` - path to NAV repo (e.g., `C:\depot\NAV`)
- `NAVCommitId` - expected NAV HEAD SHA (verified before proceeding)

## Prerequisites

- NAV repo must be at the specified commit (prefix match)
- NAV repo must have no pending changes
- BCApps is a **git submodule** inside NAV at `App\BCApps`

## Version Resolution

Reads `repoVersion` from `.github\AL-Go-Settings.json` and constructs the version
string as `$repoVersion.0.0` (currently `29.0.0`).

## Sync Steps

### Step 1: Merge .github/AL-Go-Settings.json

- Source: `App\BCApps\.github\AL-Go-Settings.json`
- Method: 3-way git merge (base from `main` branch)
- Conflicts require manual resolution

### Step 2: Mirror src/Layers

- Source: `NAV\App\Layers`
- Destination: `src\Layers`
- Method: Robocopy `/MIR` (exact mirror, deletes extras in destination)

### Step 3: Mirror src/GDL

- Source: `NAV\GDL`
- Destination: `src\GDL`
- Method: Robocopy `/MIR`

### Step 4: Mirror src/DemoTool

- Source: `NAV\App\Demotool`
- Destination: `src\DemoTool`
- Method: Robocopy `/MIR`

### Step 5: Sync src/Apps (layered merge)

- Deletes existing `src\Apps` entirely
- Copies `App\BCApps\src\Apps` as the **base** (W1 apps from the public repo)
- Overlays `NAV\App\Apps` on top with `/E` (adds all country folders)
- Force-overlays `NAV\App\Apps\W1` with `/IS /IT` flags (NAV W1 wins over BCApps W1)

This means: BCApps provides the foundation W1 apps, NAV adds country-specific apps
and can override W1 files where needed.

### Step 6: Mirror BCApps/src folders

Copies from the BCApps submodule (`App\BCApps\src\`):
- `Business Foundation`
- `System Application`
- `Tools`

Method: Robocopy `/MIR` for each folder.

### Step 7: Copy workspace files

Copies all `*.code-workspace` files from `App\BCApps\src\` into `src\`.

### Step 8: Copy build metadata from Eng/Core/Build

- `NAV\Eng\Core\Build\projects.json` -> `build\projects.json`
- `NAV\Eng\Core\Build\groups.json` -> `build\groups.json`

Then runs `Update-CountryProjectSettings.ps1` to regenerate country-specific
AL-Go project configs (`build\projects\*`).

### Step 9: Merge src/rulesets

- Source: `App\BCApps\src\rulesets\*.ruleset.json`
- Method: 3-way git merge (base from `main` branch)
- New files from BCApps are copied directly
- Existing files are merged, conflicts flagged for manual resolution

### Step 10: Merge DisabledTests

- Sources: `NAV\App\DisabledTests\` + any `*.DisabledTest.json` in BCApps submodule
- Method: Additive merge into `src\DisabledTests\`
  - Builds an index of existing entries by `codeunitId`
  - NAV entries with new methods are added to existing files
  - Wildcard entries (`method: '*'`) are preserved/added
  - Codeunits not found in any Private file are reported as warnings
- Private-only entries are preserved (never deleted)

### Step 11: Replace version variables

Replaces build-time tokens in all `app.json` files under `src\`:
- `$(app_currentVersion)` -> `29.0.0.0`
- `$(app_minimumVersion)` -> `29.0.0.0`
- `$(app_platformVersion)` -> `29.0.0.0`

Verifies no tokens remain after replacement.

## How This Explains the Diff Results

| Diff Category | Script Explanation |
|---|---|
| Cat 1: 36,333 files identical/mechanical to NAV | Steps 2-5, 8, 11 (mirror + version replacement) |
| Cat 2: 1 file truly modified vs NAV | Step 9 (3-way merge of `base.ruleset.json`) |
| Cat 3: 8,216 files identical to BCApps | Steps 5-7 (copied from BCApps submodule) |
| Cat 4: 30 files modified vs BCApps | Build/CI infrastructure unique to BCAppsPrivate |
| Cat 5: 494 files only in BCAppsPrivate | Step 8 generates 335 project configs; Step 10 preserves 130 Private-only DisabledTest entries |
| Cat 6: 42 files only in BCApps | AL-Go configs that BCAppsPrivate replaces with its own generated versions |
