# BCApps / BCAppsPrivate / NAV - Directory Comparison

Comparison date: 2026-06-04

## Path Mappings (BCAppsPrivate/BCApps to NAV)

| BCAppsPrivate / BCApps | NAV |
|------------------------|-----|
| `src\Apps\` | `App\Apps\` |
| `src\Layers\` | `App\Layers\` |
| `src\GDL\` | `GDL\` |
| `src\DemoTool\` | `App\Demotool\` |
| `src\DisabledTests\` | `App\DisabledTests\` |
| `src\rulesets\` | `App\Rulesets\` |
| `build\groups.json` | `Eng\Core\Build\groups.json` |
| `build\projects.json` | `Eng\Core\Build\projects.json` |

## File Counts

| Repository | Total Files |
|------------|------:|
| BCApps | 8,289 |
| BCAppsPrivate | 45,074 |

---

## Categorization of All Files

| # | Category | Count | % of Private |
|---|----------|------:|---:|
| 1 | In BCAppsPrivate + NAV, identical or mechanical | 36,333 | 80.6% |
| 2 | In BCAppsPrivate + NAV, truly modified | 1 | 0.0% |
| 3 | In BCAppsPrivate + BCApps, identical | 8,216 | 18.2% |
| 4 | In BCAppsPrivate + BCApps, modified | 30 | 0.1% |
| 5 | Only in BCAppsPrivate | 494 | 1.1% |
| 6 | Only in BCApps (not in Private) | 42 | - |
| | **Total BCAppsPrivate** | **45,074** | |

---

## 1. In BCAppsPrivate + NAV, identical or mechanical (36,331 files)

These files exist in both BCAppsPrivate and NAV (via path mapping). They are either
byte-for-byte identical (35,830) or differ only in version tokens (501 app.json files).

The 501 `app.json` mechanical differences:

| Field | BCAppsPrivate | NAV |
|-------|--------------|-----|
| `version` | `29.0.0.0` | `$(app_currentVersion)` |
| `platform` | `29.0.0.0` | `$(app_platformVersion)` |
| `application` | `29.0.0.0` | `$(app_minimumVersion)` |
| dependency versions | `29.0.0.0` | `$(app_minimumVersion)` |

No structural differences - same dependency IDs/names, same fields. Just hardcoded
versions vs build-time tokens.

By folder:

| Count | Folder |
|------:|--------|
| 21,763 | `src\Layers` (country localizations) |
| 13,606 | `src\Apps` (W1 + country apps/connectors) |
| 667 | `src\GDL` |
| 295 | `src\DemoTool` |

---

## 2. In BCAppsPrivate + NAV, truly modified (1 file)

- `src\rulesets\base.ruleset.json`

BCAppsPrivate (599 lines) adds extra ruleset suppression entries vs NAV (468 lines):
PTE0020, AL0254, AL0269, AL0424, and others, plus an include path to `./ruleset.json`.

---

## 3. In BCAppsPrivate + BCApps, identical (8,216 files)

These files exist in both BCAppsPrivate and BCApps with identical content. This is the
bulk of BCApps - all source code (System Application modules, Business Foundation,
Performance Toolkit, W1 apps like Avalara/Continia EDocument connectors, etc.) is
shared unchanged between the two repos.

---

## 4. In BCAppsPrivate + BCApps, modified (30 files)

All are CI/CD and build infrastructure - no source code differences:

| Area | Count | Files |
|------|------:|-------|
| `.github\workflows\` | 8 | _BuildALGoProject, CICD, DeployReferenceDocumentation, IncrementVersionNumber, PullRequestHandler, SubmitStabilityJobs, Troubleshooting, UpdateGitHubGoSystemFiles |
| `build\scripts\` | 8 | AppExtensionsHelper, AppObjectValidation, EnlistmentHelperFunctions, GuardingV2ExtensionsHelper, ImportTestDataInBcContainer, NewBcContainer, PreCompileApp, RunTestsInBcContainer |
| `build\projects\System Application Modules\.AL-Go\` | 4 | cloudDevEnv, localDevEnv, PreCompileApp, settings.json |
| `.github\actions\` | 2 | RunAutomation/SubmitStabilityJob, TestObjectIdsAndManifests |
| `.github\` | 2 | AL-Go-Settings.json, RELEASENOTES.copy.md |
| `src\rulesets\` | 2 | CodeCop.ruleset.json, ruleset.json |
| `build\` | 1 | Packages.json |
| root | 1 | .gitignore |
| `build\scripts\PullRequestValidation\` | 1 | AddMilestoneToPullRequest.ps1 |
| `build\scripts\tests\` | 1 | runTests.ps1 |

---

## 5. Only in BCAppsPrivate (494 files)

Files present in BCAppsPrivate but not found in either BCApps or NAV:

| Count | Folder | Description |
|------:|--------|-------------|
| 335 | `build\projects` | AL-Go project configs for country builds |
| 130 | `src\DisabledTests` | Test-disable config files (no NAV counterpart) |
| 19 | `build\scripts` | Additional build scripts |
| 6 | `.github\actions` | Additional GitHub Actions |
| 2 | `.github\workflows` | Additional workflows |
| 1 | `.github\CICD.settings.json` | CI/CD settings |
| 1 | `docs\features` | Feature documentation |

Note: `build\groups.json` and `build\projects.json` are identical to
`NAV\Eng\Core\Build\groups.json` and `NAV\Eng\Core\Build\projects.json` respectively,
so they belong in category 1 (total updated to 36,333).

---

## 6. Only in BCApps - not in BCAppsPrivate (42 files)

AL-Go build project configs for 6 projects + 1 workflow that BCAppsPrivate organizes differently:

| Folder | Files |
|--------|------:|
| `build\projects\Apps (W1)\.AL-Go\` | 13 |
| `build\projects\Business Foundation Tests\.AL-Go\` | 7 |
| `build\projects\Performance Toolkit Tests\.AL-Go\` | 7 |
| `build\projects\System Application\.AL-Go\` | 4 |
| `build\projects\System Application Tests\.AL-Go\` | 7 |
| `build\projects\Test Stability Tools\.AL-Go\` | 4 |
| `.github\workflows\VerifyAppChanges.yaml` | 1 |

---

## Key Takeaways

1. **BCAppsPrivate is a superset of BCApps**, sharing 8,216 identical source files and differing only in 30 build/CI files.
2. **BCAppsPrivate sources come from NAV** - 97.3% of its non-BCApps files are identical to NAV (via path mapping), and another 1.1% differ only in mechanical version-token substitution.
3. **Only 1 file has true content differences** between BCAppsPrivate and NAV (`base.ruleset.json`).
4. **496 files are unique to BCAppsPrivate** - mostly build project configs (335) and disabled-test lists (130) that exist in neither BCApps nor NAV.
