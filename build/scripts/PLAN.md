# Build Optimization: Implementation Plan

## Overview

Add app-level dependency graph filtering to the CI/CD pipeline so that only affected apps are compiled and tested when a subset of files change.

## Files

### New Files

| File | Purpose |
|------|---------|
| `build/scripts/BuildOptimization.psm1` | Core module: graph construction, affected app computation, project filtering |
| `build/scripts/tests/BuildOptimization.Test.ps1` | 23 Pester 5 tests covering all functions and scenarios |
| `build/scripts/SPEC.md` | Technical specification |
| `build/scripts/PLAN.md` | This file |

### Modified Files

| File | Change |
|------|--------|
| `.github/workflows/_BuildALGoProject.yaml` | Add `filteredProjectSettingsJson` input, add "Apply Filtered App Settings" step before ReadSettings |
| `.github/workflows/PullRequestHandler.yaml` | Add "Filter Projects by Dependency Analysis" step, add "Determine Apps to Build" step, wire output to Build jobs |
| `.github/workflows/CICD.yaml` | Same filter step as PullRequestHandler (skipped for `workflow_dispatch`), wire output to Build jobs |

## Implementation Steps

### Step 1: BuildOptimization.psm1

The core module with 4 exported functions:

1. **`Get-AppDependencyGraph`** — Scan all `app.json` files, build forward/reverse edge graph
2. **`Get-AppForFile`** — Walk directory tree upward to find nearest `app.json`
3. **`Get-AffectedApps`** — Map files to apps, BFS downstream + upstream, System App rule
4. **`Get-FilteredProjectSettings`** — Per-project glob resolution, affected intersection, compilation closure, relative path generation

Internal helpers:
- `Resolve-ProjectGlobs` — Resolve `appFolders`/`testFolders` patterns from project directory
- `Get-AppIdForFolder` — Read `app.json` in a folder to get app ID
- `Get-RelativePathCompat` — PS 5.1-compatible relative path via `[uri]::MakeRelativeUri`
- `Get-RelativeFolderPath` — Convert absolute path to relative path for settings.json
- `Add-CompilationClosure` — Fixed-point iteration to add in-project dependencies

### Step 2: Pester Tests

Test against the real repository (329 app.json files):

- **Graph tests**: Node count, System Application node, E-Document Core edges, Avalara connector forward edges
- **File mapping tests**: E-Document Core, Email module, non-app files, absolute paths
- **Affected apps tests**: E-Document cascade (9 apps), Email upstream (49 apps), unmapped src/ files trigger full build, non-src files ignored
- **Filtered settings tests**: E-Document correct folders, Subscription Billing compilation closure, Email affects System App projects, forward-slash paths

### Step 3: _BuildALGoProject.yaml

Add input:
```yaml
filteredProjectSettingsJson:
  description: 'JSON mapping project paths to filtered appFolders/testFolders'
  required: false
  default: '{}'
  type: string
```

Add step before "Read settings":
- Parse the JSON input
- Normalize project key (backslash to forward slash for matching)
- If project has a filtered entry, overwrite `appFolders` and `testFolders` in `.AL-Go/settings.json`
- Log which apps are in scope for compile and test

### Step 4: PullRequestHandler.yaml

Add to Initialization job outputs:
```yaml
filteredProjectSettingsJson: ${{ steps.filterProjects.outputs.filteredProjectSettingsJson }}
```

Add "Filter Projects by Dependency Analysis" step after `determineProjectsToBuild`:
- Import `BuildOptimization.psm1`
- Get changed files via `gh pr diff --name-only` (works with shallow checkouts)
- Check `fullBuildPatterns` — if any match, output `{}`
- Run `Get-FilteredProjectSettings`
- Output JSON

Add "Determine Apps to Build" step:
- Read filtered JSON and project list
- For each project, print `[Project] -> App` list showing filtered vs full build

Pass `filteredProjectSettingsJson` to both Build1 and Build jobs.

### Step 5: CICD.yaml

Same pattern as PullRequestHandler with differences:
- Skip filter step for `workflow_dispatch` (always full build)
- Get changed files via `git diff HEAD~1 HEAD` (push context, not PR)
- Pass `filteredProjectSettingsJson` to both Build1 and Build jobs

## Data Flow

```
PullRequestHandler.yaml / CICD.yaml
  Initialization Job:
    1. Checkout
    2. DetermineProjectsToBuild (existing AL-Go step)
    3. Filter Projects by Dependency Analysis (NEW)
       - Input: changed files from git/GitHub API
       - Output: filteredProjectSettingsJson
    4. Determine Apps to Build (NEW)
       - Input: filteredProjectSettingsJson + ProjectsJson
       - Output: log showing [Project] -> [App] list

  Build Job (_BuildALGoProject.yaml):
    1. Checkout
    2. Apply Filtered App Settings (NEW)
       - Input: filteredProjectSettingsJson
       - Action: overwrite .AL-Go/settings.json appFolders/testFolders
    3. Read Settings (existing - now reads filtered settings)
    4. Build (existing - compiles only filtered apps)
```

## Safety Mechanisms

1. **fullBuildPatterns**: Changes to `build/*`, `src/rulesets/*`, workflow files trigger full build
2. **Unmapped src/ files**: Any file under `src/` that can't be mapped to an app triggers full build
3. **Non-src files ignored**: Workflow files, build scripts, docs are not app code and are handled by fullBuildPatterns
4. **All apps affected**: If every app in a project is affected, original wildcard patterns are preserved
5. **workflow_dispatch**: Always triggers full build (CICD.yaml skips filter step)
6. **Empty result**: If filtering returns `{}`, all projects build with original settings

## Testing Strategy

### Local Testing

```powershell
Import-Module ./build/scripts/BuildOptimization.psm1 -Force
$base = (Get-Location).Path

# Test E-Document Core change
Get-FilteredProjectSettings -ChangedFiles @('src/Apps/W1/EDocument/App/src/SomeFile.al') -BaseFolder $base

# Test Email module change
Get-FilteredProjectSettings -ChangedFiles @('src/System Application/App/Email/src/SomeFile.al') -BaseFolder $base
```

### Pester Tests

```powershell
# Requires Pester 5.x
Import-Module Pester -RequiredVersion 5.7.1 -Force
Invoke-Pester -Path build/scripts/tests/BuildOptimization.Test.ps1
```

### CI Verification

1. Create a PR that only changes an E-Document Core file
2. Check "Filter Projects by Dependency Analysis" step output for filtered JSON
3. Check "Determine Apps to Build" step for `[Apps (W1)] FILTERED` with 4+5 folders
4. Check "Apply Filtered App Settings" step in Build job for correct app/test lists
5. Verify build succeeds and only E-Document related tests run

## Rollback

If filtering causes issues, set `filteredProjectSettingsJson` default to `'{}'` in `_BuildALGoProject.yaml` — this disables all filtering without removing the code. The "Apply Filtered App Settings" step has an `if: inputs.filteredProjectSettingsJson != '{}'` guard that skips it entirely when the input is empty.
