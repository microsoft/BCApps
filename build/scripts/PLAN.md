# Build Optimization V2: Implementation Plan

## Change Log

- **V1**: Filtered `appFolders`/`testFolders` in settings.json via YAML workflow steps. **Rejected** — YAML files are managed by AL-Go infrastructure and cannot be modified.
- **V2**: Two-pronged approach. Compile filtering via AL-Go native `incrementalBuilds` setting. Test filtering via skip logic in `RunTestsInBcContainer.ps1`. Zero YAML changes.

## Overview

Reduce CI/CD build times by skipping both compilation and test execution for unaffected apps:

1. **Compile filtering** — AL-Go's native `incrementalBuilds` setting with `mode: "modifiedApps"`. AL-Go finds the latest successful CI/CD build and reuses prebuilt `.app` files for unmodified apps. No custom code needed.
2. **Test filtering** — Custom skip logic in `build/scripts/RunTestsInBcContainer.ps1`. AL-Go calls this script once per test app; our code checks if the app is in the affected set and returns `$true` (pass) to skip unaffected tests.

These are complementary: `incrementalBuilds` handles compilation but still runs all tests. Our custom code fills that gap.

## Files

### New Files

| File | Purpose |
|------|---------|
| `build/scripts/BuildOptimization.psm1` | Core module: graph construction, affected app computation, test skip logic |
| `build/scripts/tests/BuildOptimization.Test.ps1` | Pester 5 tests covering all functions and scenarios |
| `build/scripts/SPEC.md` | Technical specification |
| `build/scripts/PLAN.md` | This file |

### Modified Files

| File | Change |
|------|--------|
| `.github/AL-Go-Settings.json` | Add `incrementalBuilds` setting with `mode: "modifiedApps"` |
| `build/scripts/RunTestsInBcContainer.ps1` | Import BuildOptimization module, add skip check before test execution |

### Reverted Files (V1 → V2)

| File | Change |
|------|--------|
| `.github/workflows/_BuildALGoProject.yaml` | Revert to main (remove `filteredProjectSettingsJson` input and "Apply Filtered App Settings" step) |
| `.github/workflows/PullRequestHandler.yaml` | Revert to main (remove filter steps and output wiring) |
| `.github/workflows/CICD.yaml` | Revert to main (remove filter steps and output wiring) |

## Implementation Steps

### Step 1: Revert YAML Changes

Restore all three YAML files to their `main` branch versions:
- `.github/workflows/_BuildALGoProject.yaml`
- `.github/workflows/PullRequestHandler.yaml`
- `.github/workflows/CICD.yaml`

### Step 2: Add `incrementalBuilds` to AL-Go Settings

Add to `.github/AL-Go-Settings.json`:

```json
"incrementalBuilds": {
  "mode": "modifiedApps"
}
```

This uses AL-Go defaults:
- `onPull_Request: true` — incremental builds on PRs (most common case)
- `onPush: false` — full build on merge to main
- `onSchedule: false` — full build on schedule
- `retentionDays: 30` — reuse builds up to 30 days old

How it works: AL-Go finds the latest successful CI/CD build, downloads prebuilt `.app` files for unmodified apps, and only compiles modified apps + apps that depend on them. Unmodified apps are still published to the container (for test dependencies) but skip compilation.

**Note**: `incrementalBuilds` does NOT skip test execution — all test apps still run their tests. That's why we need Step 3.

### Step 3: Update BuildOptimization.psm1

Keep existing functions (with fixes from PR review):
1. **`Get-AppDependencyGraph`** — Add `[OutputType([hashtable])]`
2. **`Get-AppForFile`** — No changes needed (already has doc comment for output)
3. **`Get-AffectedApps`** — Add `[OutputType([string[]])]`
4. **`Get-FilteredProjectSettings`** — Add `[OutputType([hashtable])]`, keep for potential future use

Add new exported functions:
5. **`Get-ChangedFilesForCI`** — Detects changed files from GitHub Actions environment
6. **`Test-ShouldSkipTestApp`** — Main entry point: checks cache, computes affected set, decides skip

Add `[OutputType()]` to internal functions:
- `Resolve-ProjectGlobs` → `[OutputType([string[]])]`

### Step 4: Modify RunTestsInBcContainer.ps1

Add at the top of the main execution section (after function definitions, before test execution):

```powershell
Import-Module $PSScriptRoot\BuildOptimization.psm1 -Force

$baseFolder = Get-BaseFolder
if ($parameters["appName"] -and (Test-ShouldSkipTestApp -AppName $parameters["appName"] -BaseFolder $baseFolder)) {
    Write-Host "BUILD OPTIMIZATION: Skipping tests for '$($parameters["appName"])' - not in affected set"
    return $true
}
```

This runs before both the normal and disabled-isolation test passes. When the project-level script calls the base script twice (normal + disabled isolation), both calls hit the cache and skip instantly.

### Step 5: Update Tests

- Fix unused `$graph` warning (add PSScriptAnalyzer suppression or restructure BeforeAll)
- Add tests for `Get-ChangedFilesForCI` (mock `$env:GITHUB_*` variables)
- Add tests for `Test-ShouldSkipTestApp` (mock environment, verify cache behavior)
- Keep existing tests for core graph functions

## How It Works

### Compile Filtering (AL-Go native)

```
AL-Go RunPipeline
  ├─ Find latest successful CI/CD build (within retentionDays)
  ├─ Determine modified files (git diff)
  ├─ For unmodified apps: download prebuilt .app from previous build
  ├─ For modified apps + dependents: compile normally
  └─ Publish ALL apps to container (prebuilt + newly compiled)
```

### Test Filtering (our code)

```
AL-Go RunPipeline
  └─ for each test app in testFolders:
       └─ [Project]/.AL-Go/RunTestsInBcContainer.ps1 ($parameters["appName"] = "E-Document Core Tests")
            └─ build/scripts/RunTestsInBcContainer.ps1
                 └─ Test-ShouldSkipTestApp checks affected set
                 └─ If NOT affected → return $true (skip)
                 └─ If affected → Run-TestsInBcContainer (normal execution)
```

### Changed File Detection

The script detects changed files based on GitHub Actions environment variables:

| Event | Method |
|-------|--------|
| `pull_request` / `merge_group` | `git fetch origin $GITHUB_BASE_REF --depth=1` then `git diff --name-only origin/$base...HEAD` |
| `push` | `git fetch --deepen=1` then `git diff --name-only HEAD~1 HEAD` |
| `workflow_dispatch` | Skip filtering (always run all tests) |
| Local / non-CI | Skip filtering (always run all tests) |

### Caching

Graph construction scans ~329 `app.json` files. Since the script is called once per test app (potentially 50+ times), the affected app set is cached to a temp file (`$RUNNER_TEMP/build-optimization-cache.json`) on first computation and read from cache on subsequent calls within the same build job.

## New Function Designs

### `Get-ChangedFilesForCI`

```
Inputs:  (none — reads from $env:GITHUB_EVENT_NAME, $env:GITHUB_BASE_REF)
Outputs: string[] of changed file paths, or $null if can't determine
```

Returns `$null` when:
- Not in GitHub Actions (`$env:GITHUB_ACTIONS` not set)
- `workflow_dispatch` event
- Git commands fail

### `Test-ShouldSkipTestApp`

```
Inputs:  -AppName <string> -BaseFolder <string>
Outputs: $true if tests should be skipped, $false otherwise
```

Logic:
1. If not in CI → `$false`
2. If `workflow_dispatch` → `$false`
3. Check cache file → if exists, read and check
4. If no cache: compute changed files → if `$null`, cache `skipEnabled=$false` → `$false`
5. Check `fullBuildPatterns` from `.github/AL-Go-Settings.json` → if match, `skipEnabled=$false`
6. Compute `Get-AffectedApps` → build name set from graph → cache
7. Return `$true` if app name NOT in affected set

Cache format (`$RUNNER_TEMP/build-optimization-cache.json`):
```json
{
  "skipEnabled": true,
  "affectedAppNames": ["E-Document Core", "E-Document Core Tests", "E-Document Connector - Avalara", ...]
}
```

## Data Flow

```
RunTestsInBcContainer.ps1 (called per test app)
  │
  ├─ Test-ShouldSkipTestApp("E-Document Core Tests", $baseFolder)
  │   ├─ Check $env:GITHUB_ACTIONS → if not CI, return $false
  │   ├─ Check $env:GITHUB_EVENT_NAME → if workflow_dispatch, return $false
  │   ├─ Check cache file → if exists, read it
  │   ├─ (first call only) Compute:
  │   │   ├─ Get-ChangedFilesForCI → ["src/Apps/W1/EDocument/App/src/X.al"]
  │   │   ├─ Check fullBuildPatterns → no match
  │   │   ├─ Get-AppDependencyGraph → 329 nodes
  │   │   ├─ Get-AffectedApps → 9 app IDs
  │   │   ├─ Map IDs to names → 9 app names
  │   │   └─ Write cache file
  │   └─ Check: "E-Document Core Tests" in affected names? → YES → return $false
  │
  └─ (tests run normally)

RunTestsInBcContainer.ps1 (next test app)
  │
  ├─ Test-ShouldSkipTestApp("Shopify", $baseFolder)
  │   ├─ Check cache file → exists, read it
  │   └─ Check: "Shopify" in affected names? → NO → return $true
  │
  └─ Write-Host "SKIPPING..." → return $true
```

## Safety Mechanisms

1. **CI-only**: Skip logic only activates when `$env:GITHUB_ACTIONS` is set. Local runs always execute all tests.
2. **workflow_dispatch**: Always runs all tests (manual builds = full build).
3. **fullBuildPatterns**: Changes to `build/*`, `src/rulesets/*`, workflow files disable skipping. Already configured in `.github/AL-Go-Settings.json`.
4. **Unmapped src/ files**: Any file under `src/` that can't be mapped to an app disables skipping (via `Get-AffectedApps` returning all apps).
5. **Git failure fallback**: If changed file detection fails, `$null` is returned → skipping disabled.
6. **Cache miss safety**: First test app call computes everything; subsequent calls read cache.
7. **Return $true on skip**: AL-Go interprets this as "tests passed", so the build continues.
8. **incrementalBuilds defaults**: `onPush: false` ensures full builds on merge to main.

## Rollback

- **Compile filtering**: Remove `incrementalBuilds` from `.github/AL-Go-Settings.json` → AL-Go reverts to full compilation.
- **Test filtering**: Set environment variable `BUILD_OPTIMIZATION_DISABLED=true` → `Test-ShouldSkipTestApp` returns `$false` for all apps.

## Expected Impact

| Change | Compile savings (incrementalBuilds) | Test savings (RunTestsInBcContainer) |
|--------|-------------------------------------|--------------------------------------|
| E-Document Core | ~51 apps skip compilation | ~17 test apps skip (of ~22) |
| Shopify Connector | ~54 apps skip compilation | ~21 test apps skip (of ~22) |
| Email module | ~280 apps skip compilation | ~46 test apps skip (of ~50) |

## Testing Strategy

### Local Testing

```powershell
Import-Module ./build/scripts/BuildOptimization.psm1 -Force
$base = (Get-Location).Path

# Verify affected apps for E-Doc change
$affected = Get-AffectedApps -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $base
$graph = Get-AppDependencyGraph -BaseFolder $base
$affected | ForEach-Object { $graph[$_].Name }

# Test skip logic (outside CI, should always return $false)
Test-ShouldSkipTestApp -AppName "Shopify" -BaseFolder $base
```

### Pester Tests

```powershell
Import-Module Pester -RequiredVersion 5.7.1 -Force
Invoke-Pester -Path build/scripts/tests/BuildOptimization.Test.ps1
```

### CI Verification

1. Create a PR that only changes an E-Document Core file
2. Check AL-Go build logs for "Using prebuilt app" messages (compile skip from incrementalBuilds)
3. Check `RunTestsInBcContainer` logs for "BUILD OPTIMIZATION: Skipping tests for..." messages
4. Verify affected test apps (E-Document Core Tests, etc.) still execute
5. Verify unrelated test apps (Shopify, etc.) are skipped
6. Verify build succeeds
