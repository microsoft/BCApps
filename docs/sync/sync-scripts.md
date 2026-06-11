# Sync Scripts Design

## Goal

After running Script 1 (NAV -> BCApps) + Script 3 (BCAppsPrivate -> BCApps),
the BCApps repo becomes identical to BCAppsPrivate.

Script 2 handles the reverse direction (BCApps -> BCAppsPrivate) for shared source code.

## Script Locations

All scripts live in `BCAppsPrivate\docs\sync\`.

## Branch and Commit Behavior

All scripts create a branch in the target repo and commit changes to it.

- **Default branch name:** `sync-<source-commit-short-sha>` (e.g., `sync-92899464a7`)
- **Optional parameter:** `-BranchName` overrides the default.
- If `-BranchName` is supplied: the branch must already exist (checked out).
- If using the default name: the branch is created from `main` (error if it already exists).
- At the end of execution, commit all changes with a descriptive message
  (e.g., "Sync from NAV <sha>" or "Sync from BCAppsPrivate").
- **Important:** Some synced files (e.g., `.xlf` translation files) may be listed
  in `.gitignore`. After copying, use `git add --force` to stage all synced paths,
  ensuring gitignored files are included in the commit.

---

## Script 1: SyncNAVToTarget.ps1

**Purpose:** Sync NAV content into a target repo (BCApps or BCAppsPrivate).

**Parameters:**
- `NAVRepoPath` — path to NAV repo (e.g., `C:\depot\NAV`)
- `TargetRepoPath` — path to target repo (BCApps or BCAppsPrivate)
- `NAVCommitId` — expected NAV HEAD SHA (verified before proceeding)

**Preconditions:**
- NAV repo at expected commit, clean working tree
- Target repo clean working tree

**Steps:**

1. **Verify NAV repo** — confirm HEAD matches `NAVCommitId`, no pending changes.

2. **Read version** — get `repoVersion` from target's `.github\AL-Go-Settings.json`,
   construct version string as `$repoVersion.0.0`.

3. **Mirror src/Layers** — robocopy `/MIR` from `NAV\App\Layers` to `target\src\Layers`.

4. **Mirror src/GDL** — robocopy `/MIR` from `NAV\GDL` to `target\src\GDL`.

5. **Mirror src/DemoTool** — robocopy `/MIR` from `NAV\App\Demotool` to `target\src\DemoTool`.

6. **Sync src/Apps** — overlay NAV country apps:
   - Robocopy `/E` from `NAV\App\Apps` to `target\src\Apps` (adds countries).
   - For W1: only copy files from `NAV\App\Apps\W1` that do NOT already exist in
     `target\src\Apps\W1` (BCApps W1 content is preserved as source of truth).

7. **Copy build metadata** — copy `NAV\Eng\Core\Build\projects.json` and `groups.json`
   to `target\build\`.

8. **Merge DisabledTests** — for each `*.DisabledTest.json` in `NAV\App\DisabledTests`:
   - If file does not exist in target `src\DisabledTests\`: copy it.
   - If file exists: additive merge (add new entries, preserve existing).

9. **Replace version tokens** — in all `app.json` files under `target\src\`:
    - `$(app_currentVersion)` -> version
    - `$(app_minimumVersion)` -> version
    - `$(app_platformVersion)` -> version

10. **Generate country project configs** — if `Update-CountryProjectSettings.ps1`
    exists in the target repo's `build\scripts\`, run it to regenerate
    `build\projects\*` from groups.json + projects.json. Skip if not present.

---

## Script 2: SyncBCAppsToBCAppsPrivate.ps1

**Purpose:** Mirror BCApps shared source into BCAppsPrivate.

**Parameters:**
- `BCAppsRepoPath` — path to BCApps repo (e.g., `C:\depot\BCApps`)
- `BCAppsPrivateRepoPath` — path to BCAppsPrivate repo (e.g., `C:\depot\BCAppsPrivate`)

**Preconditions:**
- Both repos clean working tree

**Steps:**

1. **Mirror src/System Application** — robocopy `/MIR` from BCApps to BCAppsPrivate.

2. **Mirror src/Business Foundation** — robocopy `/MIR`.

3. **Mirror src/Tools** — robocopy `/MIR`.

4. **Mirror src/Apps/W1** — robocopy `/MIR` from `BCApps\src\Apps\W1` to
   `BCAppsPrivate\src\Apps\W1`.
   Note: this sets the base; Script 1 (NAV overlay) should run after to apply NAV W1 overrides.

5. **Copy workspace files** — copy `*.code-workspace` from `BCApps\src\` to
   `BCAppsPrivate\src\`.

---

## Script 3: SyncBCAppsPrivateToBCApps.ps1

**Purpose:** Copy BCAppsPrivate "original" files (build/CI infra) into BCApps and
merge rulesets/DisabledTests. Run after Script 1 (NAV -> BCApps).

**Parameters:**
- `BCAppsPrivateRepoPath` — path to BCAppsPrivate repo
- `BCAppsRepoPath` — path to BCApps repo

**Preconditions:**
- Script 1 has already run on BCApps (NAV content synced)
- Both repos clean working tree (or BCApps allowed to be dirty from Script 1)

**Steps:**

1. **Copy build/CI files** — copy the following from BCAppsPrivate to BCApps:
   - `.gitignore`
   - `.github\CICD.settings.json`
   - `.github\AL-Go-Settings.json`
   - `.github\RELEASENOTES.copy.md`
   - `.github\actions\*` (all actions, including Private-only ones)
   - `.github\workflows\*` (all workflows, including Private-only ones)
   - `build\scripts\*` (all build scripts, including Private-only ones)
   - `build\Packages.json`

2. **Merge rulesets** — for each `*.ruleset.json` in `BCAppsPrivate\src\rulesets`:
   - If file does not exist in BCApps `src\rulesets\`: copy it.
   - If file exists: 3-way git merge (base from BCApps `main` branch).
   - Report conflicts for manual resolution.

3. **Merge DisabledTests** — for each `*.DisabledTest.json` in
   `BCAppsPrivate\src\DisabledTests`:
   - If file does not exist in BCApps `src\DisabledTests\`: copy it.
   - If file exists: additive merge (add new entries, preserve existing).

4. **Copy docs** — copy `docs\features\*` from BCAppsPrivate to BCApps.

5. **Generate AL-Go project configs** — run `Update-CountryProjectSettings.ps1`
   (now present in BCApps from step 1) to regenerate `build\projects\*`.

---

## Intended Execution Order

### To make BCApps identical to BCAppsPrivate:

```
Script 1: SyncNAVToTarget.ps1 -NAVRepoPath C:\depot\NAV -TargetRepoPath C:\depot\BCApps -NAVCommitId <sha>
Script 3: SyncBCAppsPrivateToBCApps.ps1 -BCAppsPrivateRepoPath C:\depot\BCAppsPrivate -BCAppsRepoPath C:\depot\BCApps
```

### To update BCAppsPrivate from BCApps + NAV:

```
Script 2: SyncBCAppsToBCAppsPrivate.ps1 -BCAppsRepoPath C:\depot\BCApps -BCAppsPrivateRepoPath C:\depot\BCAppsPrivate
Script 1: SyncNAVToTarget.ps1 -NAVRepoPath C:\depot\NAV -TargetRepoPath C:\depot\BCAppsPrivate -NAVCommitId <sha>
```

---

## Open Questions

1. ~~Should Script 3 delete files in BCApps that don't exist in BCAppsPrivate?~~
   **Answer:** Keep `VerifyAppChanges.yaml`. AL-Go project configs in BCApps get
   overwritten by generation (step 5). No explicit deletion needed.

2. ~~Should the scripts support `-WhatIf` / dry-run mode?~~
   **Answer:** No.

3. ~~Should Script 1 verify the BCApps submodule commit inside NAV matches the
   BCApps repo state?~~
   **Answer:** Yes.
