# Build Optimization: App-Level Dependency Graph Filtering

## Problem

W1 app builds take ~150 minutes because all ~55 W1 apps compile and test across 22 build modes, even when only one app changed. The existing AL-Go project-level filtering determines *which projects* to build, but cannot reduce work *within* a project. We need app-level filtering to dynamically reduce `appFolders` and `testFolders` to only the affected apps.

## Solution

A PowerShell module (`BuildOptimization.psm1`) that builds a dependency graph from all 329 `app.json` files in the repository and computes the minimal set of apps to compile and test for a given set of changed files. The filtered settings are injected into the AL-Go build pipeline before the `ReadSettings` action runs.

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
Starting from each directly changed app, BFS walks the reverse edges (Dependents) to find all apps that consume the changed app. If App A changed and App B depends on App A, then App B must be recompiled and retested.

**Phase 3 — Upstream BFS (Dependencies)**
Starting from each directly changed app, BFS walks the forward edges (Dependencies) to find all apps that the changed app depends on. This ensures the full dependency chain is tested, since a change in an app could interact with its dependencies in unexpected ways.

**System Application Rule**: The System Application umbrella (`63ca2fa4-4f03-4f2b-a480-172fef340d3f`) is implicitly available to all apps. If any System Application module is in the affected set, the umbrella is automatically included.

### Compilation Closure

After determining the affected set, a per-project compilation closure is computed. For each affected app in a project, all its in-project dependencies are added to the build set. This ensures the AL compiler has all required symbol files. The closure uses fixed-point iteration until no new dependencies are added.

### Project Settings Filtering

For each of the 7 AL-Go projects, the module:

1. Resolves the `appFolders` and `testFolders` glob patterns from `.AL-Go/settings.json`
2. Maps each resolved folder to its app ID
3. Intersects with the affected set (plus compilation closure)
4. Produces filtered folder lists using relative paths matching the settings.json convention

Projects with no affected apps are excluded. Projects where all apps are affected keep their original wildcard patterns (no filtering needed).

## Key App IDs

| App | ID | Role |
|-----|----|------|
| System Application | `63ca2fa4-4f03-4f2b-a480-172fef340d3f` | Umbrella, 0 dependencies, implicitly available to all |
| E-Document Core | `e1d97edc-c239-46b4-8d84-6368bdf67c8b` | W1 app, 0 in-repo dependencies |
| Email | `9c4a2cf2-be3a-4aa3-833b-99a5ffd11f25` | System Application module, 17 dependencies |

## Repository Structure

| Path | Purpose |
|------|---------|
| `build/projects/` | 7 AL-Go projects, each with `.AL-Go/settings.json` |
| `src/System Application/App/` | System Application umbrella + individual modules |
| `src/Apps/W1/` | ~55 W1 apps (EDocument, Shopify, Subscription Billing, etc.) |
| `src/Business Foundation/` | Business Foundation app and tests |
| `src/Tools/` | Performance Toolkit, Test Framework, AI Test Toolkit |

## Dependency Architecture

- **System Application umbrella** has an empty `dependencies` array — it does not reference individual modules
- **Individual modules** (Email, BLOB Storage, etc.) depend on each other within `src/System Application/App/`
- **W1 apps** list System Application as an `ExternalAppDependency` in `customSettings.json` — they compile against a pre-built artifact, not the source
- Module changes propagate within System Application projects but do NOT naturally cascade to W1 through the dependency graph

## Exported Functions

### `Get-AppDependencyGraph -BaseFolder <string>`
Returns `hashtable[appId -> node]` with forward and reverse edges.

### `Get-AppForFile -FilePath <string> -BaseFolder <string>`
Returns the app ID for a file, or `$null` if outside any app.

### `Get-AffectedApps -ChangedFiles <string[]> -BaseFolder <string> [-FirewallAppIds <string[]>]`
Returns `string[]` of affected app IDs (changed + downstream + upstream + compilation closure).

### `Get-FilteredProjectSettings -ChangedFiles <string[]> -BaseFolder <string>`
Returns `hashtable[projectPath -> @{appFolders=string[]; testFolders=string[]}]`. Only includes projects that need filtering.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| `fullBuildPatterns` match | Skip filtering, output `{}` (all projects build fully) |
| `workflow_dispatch` | Full build (CICD.yaml skips filter step) |
| File under `src/` outside any app | Full build (safety fallback) |
| File outside `src/` (workflows, scripts) | Ignored by filtering (handled by fullBuildPatterns) |
| All apps in a project affected | Keep original wildcard patterns |
| Compilation closure adds apps | Included in appFolders even though they didn't change |
| App in multiple projects | Filtered independently per project |

## Expected Impact

| Change | Before | After | Savings |
|--------|--------|-------|---------|
| E-Document Core | ~55 W1 apps x 22 modes | 4 apps + 5 tests x 22 modes | ~84% |
| Shopify Connector | ~55 W1 apps x 22 modes | 1 app + 1 test x 22 modes | ~95% |
| Email module | All System App modules | 46 app + 4 test folders | ~64% app, ~97% test |
| Subscription Billing | ~55 W1 apps x 22 modes | 2 apps + 2 tests x 22 modes | ~93% |

## PowerShell 5.1 Compatibility

The module must run on GitHub Actions `windows-latest` runners which use PowerShell 5.1:

- `[System.IO.Path]::GetRelativePath` does not exist — uses `[uri]::MakeRelativeUri` instead
- `Join-Path` only accepts 2 positional arguments — nested calls required
- Parentheses in paths (e.g., `Apps (W1)`) break `Resolve-Path` with wildcards — uses `Set-Location` to project directory first
- Pester 3.4 is in system modules — tests require Pester 5.x with explicit `-RequiredVersion`
