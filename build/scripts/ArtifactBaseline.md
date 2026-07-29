# Artifact baseline (prototype)

Cut the ~300-app publish/install phase out of the test builds by reusing what the BC artifact
database already has.

## The waste

Every `Test Apps *` build restores the BC sandbox artifact database - in which **all Microsoft
apps are already published, installed and synchronized**, on top of CRONUS demo data - and then
throws it away:

```powershell
# build/scripts/NewBcContainer.ps1 (before)
# Clean the container for all apps. Apps will be installed by AL-Go
foreach($app in $installedApps) { UnInstall-BcContainerApp ...; Unpublish-BcContainerApp ... }
```

after which AL-Go republishes everything, one app at a time:

```
Publishing ...\Microsoft_Tests-Local_29.0.2147483647.78225.app
  Synchronizing Tests-Local on tenant default
  App Microsoft_Tests-Local_29.0.2147483647.78225.app successfully published
Publishing ...\Microsoft_Tests-Marketing_29.0.2147483647.78225.app
  ...
```

The apps in the artifact are built by the NAV build from a specific BCApps commit. If the
artifact says which commit that was, the build can work out exactly which apps differ - and
leave the rest alone.

## How it works

```
NAV build            ->  artifact manifest.json   { "bcAppsCommit": "<sha>" }
BCApps PR build      ->  git diff <sha>..HEAD     -> changed files
                     ->  app dependency graph      -> changed apps + their dependents
                     ->  unpublish/publish only those; reuse everything else
```

1. `NewBcContainer.ps1` reads the artifact manifest, diffs the commit, and unpublishes **only**
   the affected apps (plus any app in the artifact that BCApps does not produce, which today's
   loop also removes).
2. `PublishBcContainerApp.ps1` skips the `.app` files whose app is unchanged and still in the
   container. New apps and test apps the artifact database does not have are published as usual.
3. Everything else in the pipeline is untouched.

No extra storage, no upload/download, no cache to invalidate: the artifact is downloaded and
restored by the build anyway, and the artifact url itself is the cache key.

## NAV side (implemented)

The NAV enlistment already knows the commit: **BCApps is a git submodule of NAV**
(`.gitmodules` -> `App/BCApps` -> `github.com/microsoft/BCApps`). The build stamps it into the
artifact manifest:

| File (NAV) | Change |
| --- | --- |
| `Eng/Core/Lib/BCAppsVersion.psm1` | new - resolves the BCApps submodule commit/branch, best effort |
| `Eng/Core/Lib/BCAppsVersion.test.psm1` / `.test.ps1` | new - 9 tests against real throwaway git enlistments |
| `Eng/Core/Helpers/CreateFullApplicationNugetPackage.ps1` | `GetDatabaseManifestContent` adds the properties (this is the manifest of the sandbox/country artifact) |
| `Eng/Operations/Scripts/Docker/Publish-OnPremArtifactsForDocker.psm1` | same for the two on-prem artifact manifests |

The resulting manifest:

```json
{
  "country": "W1",
  "database": "Demo Database BC (29-0).bak",
  "isBcSandbox": true,
  "licenseFile": "Cronus.bclicense",
  "version": "29.0.53000.0",
  "platform": "29.0.52760.0",
  "bcAppsCommit": "2b72269851f45788533bb15d1dc6e791047e6eaa",
  "bcAppsBranch": "main"
}
```

`Get-BCAppsCommitSha` prefers the commit checked out in `App/BCApps` (what the build actually
compiled) and falls back to the submodule pointer recorded in the NAV commit (which works even
when the submodule was never checked out). It never throws: no git, no submodule or a detached
enlistment simply means no property, and the BCApps side falls back to a full publish.

The consumer also accepts `bcAppsCommitSha`, `applicationCommit` and `sourceCommit` as property
names, and `BCAPPS_ARTIFACT_BASELINE_COMMIT=<sha>` overrides everything for local testing.

Requirements that still hold:

- the SHA must be a **full 40-character** commit (a branch name or short SHA is ignored), and
- the commit must be **reachable from the BCApps repository** (i.e. pushed/mirrored) - otherwise
  the build cannot diff against it.

## Files

| File (BCApps) | Role |
| --- | --- |
| `build/scripts/ArtifactBaseline.psm1` | manifest reading, commit resolution, git diff, changed-app computation, container reconciliation |
| `build/scripts/tests/ArtifactBaseline.Test.ps1` | 35 Pester tests |
| `build/scripts/NewBcContainer.ps1` | unpublishes only the changed apps instead of everything |
| `build/scripts/PublishBcContainerApp.ps1` | skips publishing apps the artifact already has, unchanged |

Change detection reuses the dependency graph in `build/scripts/BuildOptimization.psm1`, so an
app change automatically pulls in every app that depends on it.

## Enabling it

Add to `.github/AL-Go-Settings.json`:

```json
"useArtifactBaseline": true
```

Off by default. `BCAPPS_ARTIFACT_BASELINE=disabled` forces the old behavior for a single run.

## Safety - when it falls back to a full clean

Any of these gives up on reuse and behaves exactly like today:

| Condition | Why |
| --- | --- |
| No commit in the manifest | Nothing to compare against |
| Commit not reachable from the clone (after a shallow fetch attempt) | Cannot diff |
| `git diff` fails | Cannot diff |
| Build mode is not `Default` (e.g. `Clean`) | Different preprocessor symbols - the artifact binaries are not equivalent |
| A changed file matches `fullBuildPatterns` | AL-Go recompiles everything, so the container must be rebuilt too |
| A changed `src/` file cannot be mapped to an app | Unknown blast radius |
| More than 75% of apps affected | Reuse buys nothing |
| Feature setting absent / `BCAPPS_ARTIFACT_BASELINE=disabled` | Explicitly off |

## What to watch when validating this

- **Versions.** Reused apps keep the artifact version (e.g. `29.0.53000.0`) instead of the
  build's `29.0.2147483647.x`. BCApps app.json dependencies are pinned at `<major>.<minor>.0.0`,
  so they are satisfied - but anything that asserts on exact app versions will notice.
- **Binary provenance.** Reused apps are the NAV-built binaries, not the ones this build
  compiled. Same source commit, different compiler invocation.
- **Test apps.** They ship in the artifact too (`Microsoft_Tests-*.app`), but the demo database
  does not necessarily have them published; those are published as before.
- **Country projects.** Each country artifact carries its own apps; the diff is country-agnostic
  (it works on the whole repo graph), so a country project simply reuses whatever its artifact
  had.
- **Freshness.** The win shrinks as the artifact ages - a stale artifact means a large diff. The
  `UpdateBCArtifactVersion` automation already keeps it current; this makes that valuable.

## Possible follow-up

The same reasoning applies to the demo data: the artifact database already contains a fully
populated CRONUS company, but `ImportTestDataInBcContainer.ps1` deletes all companies and
regenerates them with the DemoTool. If the demo data of the artifact is acceptable for a test
type, that step could be skipped for unchanged builds as well. Deliberately out of scope here.
