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
                     ->  attribute each file to the app that OWNS it
                     ->  keep the rest published; republish in place only those
```

1. `NewBcContainer.ps1` reads the artifact manifest, diffs the commit, and decides which apps to
   keep.
2. **Every app is uninstalled**, and only apps this repo does not produce, plus apps that must
   never be in a test container, are unpublished. Everything else is left **published and
   synchronized but not installed** - exactly the state AL-Go's publish step leaves an app in
   today.
3. `PublishBcContainerApp.ps1` skips the `.app` files whose app is retained and unchanged. New
   apps and anything the container does not hold are published as usual.
4. `ImportTestDataInBcContainer.ps1` and the test runner are untouched.

Step 2 is what makes this safe. Because retained apps end up *published but not installed*:

- **Install order stays under the pipeline's control.** The `Legacy` test type deliberately
  installs only the base apps + DemoTool, generates demo data, and only then installs the rest.
  If retained apps stayed installed, `Install-BaseAppsForDemoTool` would silently become a no-op
  and the DemoTool would run against a fully installed container.
- **Test discovery is unchanged.** Every test project sets `"runTestsInAllInstalledTestApps": true`,
  so the set of tests that run is derived from the *installed* apps. Retaining installed apps
  would change which tests execute.

Only the publish/sync work is skipped - the container still ends up in today's shape.

### Only the owning app, never its dependents

The set of apps to refresh is **not** expanded down the dependency graph.
`BuildOptimization`'s `Get-AffectedApps` does expand, because it answers a different question -
*which tests must run* - where a change in a dependency can change a dependent's behaviour.

*Which published binaries are still valid* is not that question. An app whose own source did not
change has identical source at both commits, is already published, installed and synchronized in
the restored database, and still resolves its dependencies because BCApps pins them at
`<major>.<minor>.0.0`, so a refreshed Base Application at `29.0.2147483647.x` still satisfies it.

This is not a marginal difference. Measured on a real 16-commit, 3-day window
(`1e77e9c2..28ff6645`, 432 changed files, 841 apps): expanding to dependents marks **841 of 841
apps**, because `src/Layers/W1/BaseApp` changed and everything depends on Base Application.
Attributing to the owning app marks **10**. Base Application changes in nearly every multi-day
window, so expansion would make this optimization fire approximately never.

### Layers are resolved through the country's view chain

A country layer folder carries no `app.json`. `PreCompileApp.ps1` calls `New-GDLView`, which
composes `src/Views/<CC>` from a chain of layers declared in `src/Layers/.config/views_config.json`
and compiles the localized app from that view:

```
W1   -> [W1]           DK -> [W1, DK]
NA   -> [W1, NA]       US -> [W1, NA, US]
DACH -> [W1, DACH]     AT -> [W1, DACH, AT]
```

So a change to `src/Layers/<L>/<AppFolder>/**` marks `<AppFolder>` for republish in a build of
country `CC` **only when `L` is part of `chain(CC)`**, and the app identity is resolved by walking
that chain from the most specific layer back to the base. For a `Test Apps W1` build the RU, IT,
ES … layer changes are genuinely irrelevant; for `Test Apps DK` a `src/Layers/DK/BaseApp` change
*does* invalidate that container's Base Application. Ignoring country layers altogether would
publish a stale localized Base Application - a correctness bug, not a missed optimization.

The country is taken from the artifact url (`.../sandbox/29.0.53247.0/w1` -> `w1`), which is the
country the container is built for.

### In-place publishing, not unpublish-then-publish

Changed apps are **not** unpublished. Business Central refuses to unpublish an extension while
another *published* extension depends on it, and retaining dependents published is the entire
point of this change - so the unpublish set can never be dependency closed. A first CI run proved
it, failing with:

```
The Extension cannot be unpublished because it is required by the following apps:
Subscription Billing Demo Data by Microsoft 29.0.53221.0
    at UnPublish-BcContainerApp <- NewBcContainer.ps1
```

Note this is also what the original dependency-expansion approach was quietly buying: not just
binary validity, but a dependency-closed unpublish set. Restoring expansion would fix the error
and destroy the benefit, because Base Application is in the changed set in nearly every window
and everything depends on it.

Instead the newly built version is published **over** the artifact's copy. The build produces
`29.0.2147483647.x` against the artifact's `29.0.<build>.0`, and BC allows several versions of an
extension to be published at once. The precondition - that dependent apps are uninstalled before
a new version is published - is already met, because the hook uninstalls every app first.

**Open risk:** installation must resolve to the newly published version. Testing the artifact's
stale copy would be worse than not optimizing at all, so this needs to be confirmed on a real run
before the feature is enabled anywhere.

## NAV side (implemented)

The NAV enlistment already knows the commit: **BCApps is a git submodule of NAV**
(`.gitmodules` -> `App/BCApps` -> `github.com/microsoft/BCApps`). The build stamps it into the
artifact manifest:

| File (NAV) | Change |
| --- | --- |
| `Eng/Normal/Lib/SubmodulesHelper.psm1` | `Get-BCAppsCommitSha` - resolves the BCApps submodule commit, returning empty when the submodule is dirty |
| `Eng/Normal/Lib/SubmodulesHelper.test.psm1` / `.test.ps1` | tests against real throwaway git enlistments |
| `Eng/Core/Helpers/CreateFullApplicationNugetPackage.ps1` | `GetDatabaseManifestContent` adds `bcAppsCommit` (this is the manifest of the sandbox/country artifact) |

Shipped in NAV PR 251642 on 2026-07-31. Verified in a published artifact:
`sandbox/29.0.53247.0/w1` and `.../dk` both carry
`"bcAppsCommit": "1e77e9c2e8d4c58e45e32be2876550dbb68b773c"`, which is a real commit on BCApps
`main`. The repository-level `base` artifact is *not* stamped, but no `Test Apps` project uses it -
`Test Apps W1` sets `country: w1` and each localization project sets its own.

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
| `build/scripts/NewBcContainer.ps1` | unpublishes only apps this repo does not produce; changed apps are republished in place |
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
| Commit not reachable from the clone | Cannot diff. A shallow (CI) clone is fetched once; a complete clone is never made shallow |
| `git diff` fails | Cannot diff |
| Build mode changes compilation | Different preprocessor symbols mean the artifact binaries are not equivalent. Derived from the settings (any build mode whose `conditionalSettings` set `preprocessorSymbols` - today that is `Clean`), **not** an allow-list of `Default`: no container-building project uses `Default`, they build in `IntegrationTests` / `UncategorizedTests` / `LegacyTestsBucket1` / `LegacyTestsBucket2` |
| A changed `src/` file cannot be mapped to an app | Unknown blast radius |
| A changed layer file belongs to a country with no resolvable view chain | Cannot tell which app it compiles into |
| A changed path is not recognized at all | Unknown blast radius |
| More than 75% of apps changed | Reuse buys nothing |
| Feature setting absent / `BCAPPS_ARTIFACT_BASELINE=disabled` | Explicitly off |

### What is deliberately *not* a trigger

A retained app is never compiled by this build - its binary is fixed inside the artifact - so no
repository-side setting can retroactively change it. These therefore do **not** force a full
clean:

| Path | Why not |
| --- | --- |
| `src/rulesets/*` | Analyzer rules are a diagnostic input. They can fail a build; they cannot make a published `.app` wrong |
| `src/DisabledTests/*` | Controls which tests run, not what a binary contains |
| `build/*` | Build tooling, package pins and per-project AL-Go settings. If a project's `appFolders` changes, a removed app is unpublished anyway (it is no longer in `KnownApps`) and an added app arrives with new files that are attributed normally |
| `.github/*` | Workflows and the repository-wide AL-Go settings. Preprocessor-symbol changes are caught by the build-mode guard above |
| `*.md`, `.gitignore`, `.vscode/*` | Not compiled |

The artifact and platform pins deserve their own note. `UpdateBCArtifactVersion` bumps them
roughly weekly:

```
.github/AL-Go-Settings.json   artifact   29.0.53094.0 -> 29.0.53221.0
build/Packages.json           BCPlatform 29.0.53093.0 -> 29.0.53216.0
```

Bumping a pin downloads a **newer** artifact, carrying a **newer** `bcAppsCommit`, which makes the
diff *smaller*. Treating those files as a full-refresh trigger would mean the commit that improves
this optimization is the one that switches it off.

Note also that `fullBuildPatterns` is **not** consulted. It is tuned for AL-Go's compile skipping
and test selection; on the measured window it vetoes reuse on `build/Packages.json` and
`src/DisabledTests/*`, neither of which can invalidate a published binary.

Additional guarantees:

- **Apps are identified by publisher + name**, not name alone. This repository contains several
  apps that share a name (`Tests-Local` in the BE/MX/W1 layers, `Data Archive` in both
  `src/Apps` and `src/System Application`), and matching on name alone could skip publishing an
  app the container never had.
- **Apps that must never be in a test container** (`Library - No Transactions`,
  `Prevent Metadata Updates Library`) are always unpublished. Both are built from this
  repository, so they would otherwise look like ordinary reusable apps - and
  `Prevent Metadata Updates Library` changes runtime behavior.
- **Apps this repository does not produce are unpublished**, keeping the container's contents
  equal to what this build publishes, as today.
- **The decision is stamped with the container name and the workflow run/attempt.** The publish
  hook runs in a separate process and the temp folder is shared on a developer machine and on
  reused runners; state that does not belong to the current container is ignored rather than
  trusted.
- **`BCAPPS_ARTIFACT_BASELINE_COMMIT` is ignored in CI**, so the manifest is the only source of
  truth there.

## What to watch when validating this

- **This has never run in a real CI build.** The first version of this change guarded on
  `BuildMode -eq 'Default'`, which no container-building project uses, so the feature could not
  activate at all. That is fixed and covered by a regression test, but the payoff and the
  behavior still have to be measured on a real `Test Apps` run before it is enabled.
- **Versions.** Reused apps keep the artifact version (e.g. `29.0.53000.0`) instead of the
  build's `29.0.2147483647.x`. BCApps app.json dependencies are pinned at `<major>.<minor>.0.0`,
  so they are satisfied - but anything that asserts on exact app versions will notice.
- **Binary provenance.** Reused apps are the NAV-built binaries, not the ones this build
  compiled. Same source commit, different compiler invocation.
- **Country projects.** Each country artifact carries its own apps; the diff is country-agnostic
  (it works on the whole repo graph), so a country project reuses whatever its artifact had.
- **Freshness.** The win shrinks as the artifact ages - a stale artifact means a large diff. The
  `UpdateBCArtifactVersion` automation already keeps it current; this makes that valuable.

## Possible follow-up

The same reasoning applies to the demo data: the artifact database already contains a fully
populated CRONUS company, but `ImportTestDataInBcContainer.ps1` deletes all companies and
regenerates them with the DemoTool. If the demo data of the artifact is acceptable for a test
type, that step could be skipped for unchanged builds as well. Deliberately out of scope here.
