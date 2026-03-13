# Build Optimization V2: Compile + Test Filtering

## Problem

W1 app builds take ~150 minutes because all ~55 W1 apps compile and all ~22 test apps run across 22 build modes, even when only one app changed. The existing AL-Go project-level filtering determines *which projects* to build, but cannot reduce work *within* a project.

## Constraints

- **YAML files are off-limits**: `.github/workflows/*.yaml` are managed by AL-Go infrastructure and cannot be modified.
- **Custom scripts are the integration point**: AL-Go calls `CompileAppInBcContainer.ps1` per app (compile) and `RunTestsInBcContainer.ps1` per test app (test). These can be customized.

## Solution

Two complementary mechanisms:

### 1. Compile Filtering — AL-Go Native `incrementalBuilds`

AL-Go's built-in `incrementalBuilds` setting with `mode: "modifiedApps"`:
- Finds the latest successful CI/CD build (within `retentionDays`)
- Downloads prebuilt `.app` files for unmodified apps from that build
- Only compiles modified apps and apps that depend on them
- Still publishes ALL apps to the container (prebuilt + newly compiled)
- **Does NOT skip test execution** — all test apps still run

Configuration in `.github/AL-Go-Settings.json`:
```json
"incrementalBuilds": {
  "mode": "modifiedApps"
}
```

Defaults: `onPull_Request: true`, `onPush: false`, `onSchedule: false`, `retentionDays: 30`.

### 2. Test Filtering — Custom `RunTestsInBcContainer.ps1`

A PowerShell module (`BuildOptimization.psm1`) that builds a dependency graph from all 329 `app.json` files and computes the affected set. The skip logic in `RunTestsInBcContainer.ps1` checks if the current test app is in the affected set and returns `$true` (skip) if not.

## Architecture

### Dependency Graph

The graph is built by scanning all `app.json` files under the repository root. Each node represents an app:

```
Node {
    Id           : string    # Lowercase GUID from app.json
    Name         : string    # App display name
    AppJsonPath  : string    # Full path to app.json
    AppFolder    : string    # Directory containing app.json
    Dependencies : string[]  # Forward edges (app IDs this app depends on)
    Dependents   : string[]  # Reverse edges (app IDs that depend on this app)
}
```

The graph has ~329 nodes. Forward edges come from the `dependencies` array in each `app.json`. Reverse edges are computed by inverting the forward edges.

### Affected App Computation

Given a list of changed files, the affected set is computed in three phases:

**Phase 1 — File-to-App Mapping**
Each changed file is mapped to an app by walking up the directory tree to the nearest `app.json`. Files under `src/` that cannot be mapped trigger a full build (safety). Files outside `src/` (workflows, build scripts, docs) are ignored — they are covered by `fullBuildPatterns`.

**Phase 2 — Downstream BFS (Dependents)**
Starting from each directly changed app, BFS walks the reverse edges (Dependents) to find all apps that consume the changed app. If App A changed and App B depends on App A, then App B must be retested.

**Phase 3 — Upstream BFS (Dependencies)**
Starting from each directly changed app, BFS walks the forward edges (Dependencies) to find all apps that the changed app depends on. This ensures the full dependency chain is tested.

**System Application Rule**: The System Application umbrella (`63ca2fa4-4f03-4f2b-a480-172fef340d3f`) is implicitly available to all apps. If any System Application module is in the affected set, the umbrella is automatically included.

### Test Skip Logic

AL-Go calls `RunTestsInBcContainer.ps1` once per test app with `$parameters["appName"]` set to the test app's display name. The skip logic:

1. Checks if running in CI (`$env:GITHUB_ACTIONS`)
2. Checks event type (skip filtering for `workflow_dispatch`)
3. Reads or computes the affected app name set (with file-based caching)
4. If the current test app name is NOT in the affected set → `return $true` (skip)
5. Otherwise → proceed with normal test execution

### Caching

Since the script is called once per test app (potentially 50+ times per build job), the affected app set is computed once and cached to `$RUNNER_TEMP/build-optimization-cache.json`. Subsequent calls read the cache (~1ms) instead of re-scanning 329 app.json files.

### Changed File Detection

Changed files are detected from the GitHub Actions environment:

| Event | Method |
|-------|--------|
| `pull_request` / `merge_group` | `git diff --name-only origin/$GITHUB_BASE_REF...HEAD` |
| `push` | `git diff --name-only HEAD~1 HEAD` |
| `workflow_dispatch` | No detection (all tests run) |
| Local / non-CI | No detection (all tests run) |

## Exported Functions

### `Get-AppDependencyGraph -BaseFolder <string>`
Returns `hashtable[appId -> node]` with forward and reverse edges.

### `Get-AppForFile -FilePath <string> -BaseFolder <string>`
Returns the app ID for a file, or `$null` if outside any app.

### `Get-AffectedApps -ChangedFiles <string[]> -BaseFolder <string> [-FirewallAppIds <string[]>]`
Returns `string[]` of affected app IDs (changed + downstream + upstream).

### `Get-ChangedFilesForCI`
Returns `string[]` of changed file paths from GitHub Actions environment, or `$null` if not determinable.

### `Test-ShouldSkipTestApp -AppName <string> -BaseFolder <string>`
Returns `$true` if the test app should be skipped, `$false` otherwise. Handles caching internally.

### `Get-FilteredProjectSettings -ChangedFiles <string[]> -BaseFolder <string>`
Returns filtered `appFolders`/`testFolders` per project. Kept for potential future use.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| `fullBuildPatterns` match | Test skipping disabled, all tests run |
| `workflow_dispatch` | Test skipping disabled, all tests run |
| File under `src/` outside any app | `Get-AffectedApps` returns all apps → all tests run |
| File outside `src/` (workflows, scripts) | Ignored (handled by `fullBuildPatterns`) |
| Not in CI environment | Test skipping disabled, all tests run |
| Git diff fails | `Get-ChangedFilesForCI` returns `$null` → skipping disabled |
| Cache file exists | Read from cache (fast path) |
| `$parameters["appName"]` is null | Skipping disabled (safety) |
| No previous successful build | `incrementalBuilds` falls back to full compilation |

## Expected Impact

| Change | Compile savings (incrementalBuilds) | Test savings (RunTestsInBcContainer) |
|--------|-------------------------------------|--------------------------------------|
| E-Document Core | ~51 apps skip compilation | ~17 test apps skip (of ~22) |
| Shopify Connector | ~54 apps skip compilation | ~21 test apps skip (of ~22) |
| Email module | ~280 apps skip compilation | ~46 test apps skip (of ~50) |

## PowerShell 5.1 Compatibility

The module must run on GitHub Actions `windows-latest` runners which use PowerShell 5.1:

- `[System.IO.Path]::GetRelativePath` does not exist — uses `[uri]::MakeRelativeUri` instead
- `Join-Path` only accepts 2 positional arguments — nested calls required
- Parentheses in paths (e.g., `Apps (W1)`) break `Resolve-Path` with wildcards — uses `Set-Location` to project directory first
- Pester 3.4 is in system modules — tests require Pester 5.x with explicit `-RequiredVersion`
