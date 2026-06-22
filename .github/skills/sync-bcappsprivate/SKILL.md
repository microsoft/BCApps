---
name: sync-bcappsprivate
description: 'Synchronize source code between the BCAppsPrivate, NAV, and BCApps repositories. Use when asked to sync BCAppsPrivate with NAV/BCApps, update BCAppsPrivate from upstream NAV, publish BCAppsPrivate changes to the public BCApps repo, run the sync scripts in docs/sync, mirror Apps/Layers/GDL/DemoTool/System Application source, merge rulesets or DisabledTests across repos, or update sync-state.json. Covers SyncNAVToBCAppsPrivate, SyncNAVToTarget, SyncBCAppsToBCAppsPrivate, and SyncBCAppsPrivateToBCApps.'
argument-hint: 'e.g. "update BCAppsPrivate from NAV <sha>" or "publish BCAppsPrivate to BCApps"'
---

# Sync BCAppsPrivate with NAV and BCApps

## What this produces

A target repository (BCAppsPrivate or BCApps) updated on a fresh `sync-<sha>` branch
with a single descriptive commit, ready for review and PR. The three source repos
relate as follows:

- **NAV** — Microsoft-internal monorepo. Source of truth for country apps, layers,
  GDL, DemoTool, and build metadata. Contains **BCApps as a git submodule** at `App\BCApps`.
- **BCApps** — public open-source repo. Source of truth for W1 apps, System Application,
  Business Foundation, and Tools.
- **BCAppsPrivate** — internal staging repo that combines both, plus Private-only
  build/CI infrastructure.

Path mappings (BCAppsPrivate/BCApps ↔ NAV) are documented in
[docs/sync/diff.md](../../../docs/sync/diff.md).

## When to use

- "Sync BCAppsPrivate with NAV" / "update BCAppsPrivate from the latest NAV commit"
- "Publish BCAppsPrivate to BCApps" / "make BCApps identical to BCAppsPrivate"
- Running any script under [docs/sync/](../../../docs/sync/)
- Resolving sync merge conflicts (rulesets, DisabledTests, shared CI files)

## Prerequisites (verify before any sync)

1. **PowerShell 7+** (scripts declare `#Requires -Version 7.0`).
2. All involved repos cloned locally (typically `C:\depot\NAV`, `C:\depot\BCApps`,
   `C:\depot\BCAppsPrivate`).
3. **Clean working trees** in every repo involved.
4. The **NAV repo checked out at the target commit** — scripts verify HEAD matches
   the supplied `NAVCommitId` (prefix match) and abort otherwise.
5. The **BCApps submodule inside NAV** (`App\BCApps`) matches the intended BCApps state.
6. [docs/sync/sync-state.json](../../../docs/sync/sync-state.json) exists — it stores
   `lastSyncedBCAppsCommit` and `lastSyncedNAVCommit`, used as the 3-way merge base.

## The two workflows

### A. Update BCAppsPrivate from upstream (NAV + BCApps → BCAppsPrivate)

Use the orchestrator [SyncNAVToBCAppsPrivate.ps1](../../../docs/sync/SyncNAVToBCAppsPrivate.ps1).
It runs Script 2 (BCApps → BCAppsPrivate) then Script 1 (NAV → BCAppsPrivate):

```powershell
cd C:\depot\BCAppsPrivate\docs\sync
.\SyncNAVToBCAppsPrivate.ps1 `
    -NAVRepoPath "C:\depot\NAV" `
    -BCAppsPrivateRepoPath "C:\depot\BCAppsPrivate" `
    -NAVCommitId "<nav-head-sha>"
```

Order matters: BCApps sets the W1/shared base first, then NAV overlays country apps
and W1 overrides on top.

### B. Publish BCAppsPrivate to the public repo (BCAppsPrivate + NAV → BCApps)

Run Script 1 targeting BCApps, then Script 3:

```powershell
cd C:\depot\BCAppsPrivate\docs\sync
# Script 1: NAV content into BCApps
.\SyncNAVToTarget.ps1 `
    -NAVRepoPath "C:\depot\NAV" `
    -TargetRepoPath "C:\depot\BCApps" `
    -NAVCommitId "<nav-head-sha>"
# Script 3: BCAppsPrivate build/CI infra + ruleset/DisabledTest merges into BCApps
.\SyncBCAppsPrivateToBCApps.ps1 `
    -BCAppsPrivateRepoPath "C:\depot\BCAppsPrivate" `
    -BCAppsRepoPath "C:\depot\BCApps"
```

The result: BCApps becomes identical to BCAppsPrivate.

## Scripts reference

| Script | Role | Key params |
|--------|------|-----------|
| [SyncNAVToBCAppsPrivate.ps1](../../../docs/sync/SyncNAVToBCAppsPrivate.ps1) | Orchestrator for workflow A (Script 2 + Script 1) | `NAVRepoPath`, `BCAppsPrivateRepoPath`, `NAVCommitId`, `[BranchName]` |
| [SyncNAVToTarget.ps1](../../../docs/sync/SyncNAVToTarget.ps1) | Script 1 — NAV → target (BCApps or BCAppsPrivate) | `NAVRepoPath`, `TargetRepoPath`, `NAVCommitId`, `[BranchName]`, `[-NoCommit]` |
| [SyncBCAppsToBCAppsPrivate.ps1](../../../docs/sync/SyncBCAppsToBCAppsPrivate.ps1) | Script 2 — BCApps shared source → BCAppsPrivate (called by orchestrator) | `BCAppsRepoPath`, `BCAppsPrivateRepoPath` |
| [SyncBCAppsPrivateToBCApps.ps1](../../../docs/sync/SyncBCAppsPrivateToBCApps.ps1) | Script 3 — Private build/CI infra + merges → BCApps | `BCAppsPrivateRepoPath`, `BCAppsRepoPath`, `[BranchName]` |
| [CleanNAVFiles.ps1](../../../docs/sync/CleanNAVFiles.ps1) | Deletes NAV files identical to BCApps counterparts; reports diffs | `NAVRepoPath`, `BCAppsRepoPath`, `[BranchName]` |
| [Sync.psm1](../../../docs/sync/Sync.psm1) | Shared helpers (robocopy, 3-way merge, DisabledTest merge, sync-state) | — |

Detailed step-by-step behavior of each script and the diff categorization that
explains why files land where they do are in
[docs/sync/sync-scripts.md](../../../docs/sync/sync-scripts.md),
[docs/sync/SyncFromNAV.md](../../../docs/sync/SyncFromNAV.md), and
[docs/sync/diff.md](../../../docs/sync/diff.md).

## What gets synced (high level)

- **Mirrored from NAV** (`robocopy /MIR`, NAV wins): `src\Layers`, `src\GDL`,
  `src\DemoTool`, country apps under `src\Apps`, build metadata (`projects.json`,
  `groups.json`).
- **Mirrored from BCApps** (shared source): `src\System Application`,
  `src\Business Foundation`, `src\Tools`, base W1 under `src\Apps\W1`,
  `*.code-workspace` files.
- **3-way merged** (conflicts surface for manual resolution): shared CI/build files
  (`.gitignore`, `.github\CICD.settings.json`, `.github\AL-Go-Settings.json`,
  `.github\RELEASENOTES.copy.md`, `build\Packages.json`) and `src\rulesets\*.ruleset.json`.
- **Additively merged** (existing entries preserved): `src\DisabledTests\*.DisabledTest.json`,
  matched by `codeunitId`.
- **Generated**: country project configs under `build\projects\` via
  `Update-CountryProjectSettings.ps1`.
- **Version tokens replaced** in every `src\**\app.json`:
  `$(app_currentVersion)`, `$(app_minimumVersion)`, `$(app_platformVersion)` →
  `<repoVersion>.0.0.0` (repoVersion read from target's `.github\AL-Go-Settings.json`).
- **BCPlatform version updated** in `build\Packages.json`: the `BCPlatform.Version`
  is set from the `microsoft.nav.platform.main.universal` package version in NAV's
  `.corext\corext.config`, converting the corext form (e.g. `29.0.51074-0`) to the
  dotted form used by `Packages.json` (e.g. `29.0.51074.0`).
- **AppBaselines-BCArtifacts version updated** in `build\Packages.json`: the
  `AppBaselines-BCArtifacts.Version` (AppSourceCop breaking-change baseline) is set
  from `Identity.Version` in NAV's
  `.corext\lazyComponents\ReferenceV2Extensions\PackageInfo.json` (e.g. `28.2.50950`),
  padded to the 4-part dotted form (e.g. `28.2.50950.0`).

## Branch & commit behavior

- Scripts create a branch named `sync-<source-commit-short-sha>` from `main`
  (error if it already exists), or use `-BranchName` (must already exist/checked out).
- All changes are committed with a descriptive message. Gitignored synced files
  (e.g., `.xlf`) are force-staged via `git add --force`.
- After a successful sync, update [docs/sync/sync-state.json](../../../docs/sync/sync-state.json)
  with the new `lastSyncedBCAppsCommit` / `lastSyncedNAVCommit` (handled by the
  `Set-SyncState` helper in `Sync.psm1`).

## Handling merge conflicts

When `Invoke-ThreeWayMerge` reports conflicts, the script pauses and prints the file
path. Resolve the conflict markers in that file manually, then answer `y` to continue
(or `q` to abort). Conflicts are expected only in rulesets and shared CI files; source
code mirrors do not merge.

## Completion checks

1. Script exited without error and committed on the `sync-<sha>` branch.
2. No leftover version tokens (`$(app_*Version)`) — Script 1 verifies this.
3. `sync-state.json` updated to the new commit(s).
4. Review the diff on the sync branch before opening a PR.

> Do not commit or push without explicit user confirmation. Never force-push.
