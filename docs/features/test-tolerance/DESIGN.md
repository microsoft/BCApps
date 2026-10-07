# Test Tolerance — Design

> Status: Draft — core decisions made, implementation complete
> Owner: Engineering Systems
> Last updated: 2026-04-28

## 1. Summary

Allow specific tests that are known to be unstable to be tolerated during build runs, so that random failures of those tests do not, by themselves, cause the build to fail.

## 2. Problem statement

- Some tests fail intermittently due to non-deterministic factors (timing, environment, external dependencies, ordering, etc.).
- Today, any test failure fails the build, which forces re-runs and erodes trust in build signal.
- We need a controlled, auditable way to mark tests as "unstable" so the build can tolerate their failures without hiding real regressions.

## 3. Goals / Non-goals

### Goals
- Stable builds: a build that runs successfully should not be failed by tests that are known to be unstable.

### Non-goals
- Disabling tests. Unstable tests still run; their failures are reclassified, not skipped.
- Hiding real regressions. A build with even one non-tolerated failure still fails as it does today.
- Providing a manual override path. Tests enter the unstable list only via the automated heuristic (see §6.1).

## 4. Terminology

- **Unstable test**: A test that fails intermittently due to non-deterministic factors (timing, environment, external dependencies, ordering, etc.) and is tracked in the per-branch unstable tests artifact.
- **Tolerated failure**: A test failure that is matched against the unstable tests artifact and reclassified so it does not fail the build.

## 5. User scenarios

1. **Unstable test fails during CI/CD**: A developer pushes a change. The CI/CD build runs all tests. A known-unstable test fails. Because the test is listed in the unstable tests artifact for the current branch, the failure is tolerated — the build succeeds and the tolerated failure is logged.
2. **Real regression fails the build**: A developer pushes a change that introduces a real bug. A test that is *not* in the unstable tests artifact fails. The build fails as it does today.
3. **Unstable test on a different branch**: An unstable test is listed for `main` but not for `releases/26.0`. If the same test fails on `releases/26.0`, it is treated as a real failure because the artifact is branch-scoped.

## 6. Proposed design

### 6.1 How a test is marked as unstable

Unstable tests are tracked via a **per-branch artifact** (`unstable-tests-<normalized-branch>`) maintained by the UpdateUnstableTests workflow, which runs on an hourly schedule. Tests are never annotated in source; the list lives entirely in the artifact.

- The artifact is **branch-scoped**: its name encodes the branch it applies to, so each branch can have its own set of unstable tests.
  - Naming pattern: `unstable-tests-<normalized-branch>`, where the branch name is normalized by replacing non-alphanumeric characters (except `.`, `_`, `-`) with `-`. For example, `releases/26.0` becomes `unstable-tests-releases-26.0`.
- Supported branches: **`main`** and all **`releases/*`** branches only. Other branches do not produce or consume the artifact.

**Sliding window heuristic (Path A)**

On each scheduled run, the UpdateUnstableTests workflow examines the last **3** completed CI/CD runs on the branch (the default window). The unstable-tests list is **fully recomputed** from those runs — no incremental merging.

- **ADD**: Any test that failed in at least one of the last 3 runs is added to the list.
- **REMOVE**: Any test that did not fail in any of the last 3 runs is dropped from the list (i.e., self-healing is automatic over a 3-run window).

The artifact records the `runIds` field listing the exact runs examined, for traceability.

The window size (default 3) is the `RunLimit` parameter of the combined updater (passed through to `Find-UnstableTestRunIds`) and can be changed without modifying the schema.

**Manual additive path (AddUnstableTestsFromRun)**

In addition to the automatic sliding-window heuristic, the **AddUnstableTestsFromRun** workflow provides a manual, additive way to mark tests as unstable from a single run. It is intended for tests that are consistently unstable but do not get picked up by the window (for example, a test that fails in isolation on a specific PR Build or CI/CD run). The workflow:

1. Downloads the existing `unstable-tests-<normalized-branch>` artifact for the target branch (starting from an empty list when none exists).
2. Downloads the test result artifacts from the run ID you specify and identifies its failing tests.
3. Merges those failing tests into the existing list — every existing entry is preserved verbatim and only tests that are not already present are appended (matched by the three-part key).
4. Re-publishes the artifact, resetting the 30-day retention clock.

Unlike the sliding window, this path **never removes** entries; it is purely additive. Entries added this way carry the reason `Manually added from CI/CD run <runId>` and a `sourceRunUrl` for traceability. The next scheduled UpdateUnstableTests run will recompute the list from the window and may drop manually-added entries if they have stopped failing — this is the intended self-healing behavior.

The `AddUnstableTestsFromRun` path runs the composite action (`UpdateUnstableTests`), which takes a comma-separated `run-id` list and an `additive` flag and invokes the shared updater script `UpdateUnstableTestsArtifact.ps1` in `build/scripts/TestTolerance` (it collects failing tests from those runs via `Get-FailedTestsFromRuns`, merges them additively via `Add-FailedTestsToUnstableTests`, and writes the artifact). The scheduled `UpdateUnstableTests.yaml` workflow does **not** use this action — it uses its own composite action (`UpdateUnstableTestsCombined`), which runs the combined driver described below (recompute Path A and layer Path B on top in a single artifact write) and uploads the resulting per-branch artifact. Both actions ultimately reuse the same building blocks in `TestTolerance.psm1`, so the artifact schema stays identical.

The additive path is wired through the `AddUnstableTestsFromRun.yaml` workflow (manual `workflow_dispatch` with `branch` and `runId` inputs), which calls the shared `UpdateUnstableTests` action with `additive: true`. The `branch` input is a comma-separated filter (default `main, releases/*`) that is converted to a JSON array and expanded against the official branches via the `GetGitBranches` action; the workflow then fans out over the matching branches with a matrix, applying the run's failing tests to each selected branch's list. The run is always read from the current repository.

**Cross-PR automatic additive path (Path B)**

The `AddUnstableTestsFromRun` path above is manual. The scheduled `UpdateUnstableTests` workflow also runs an *automatic* additive path in the **same** run, right after the Path A recompute, that reacts quickly by correlating failures **across PR builds**.

The signal it exploits: a test failing on a *single* PR is ambiguous (it could be that PR's own change), but the same test failing across **multiple unrelated PRs** in a short window is almost never caused by any one PR — it is an instability. On each hourly run, for each official branch it:

1. Lists `Pull Request Build` runs that **completed within the last `windowHours`** (default **6**) hours, or are **still running**. Recency is measured by the run's **completion time** (`updated_at`), not when it started — a BC PR build routinely runs **5–10 hours**, so by the time a failing build finishes and has uploaded test results it was *created* many hours ago; filtering on start time would discard almost every completed failure. To find those runs the server-side listing looks back `windowHours + maxBuildHours` (default **12**) hours by `created_at` (wide enough to include a long build that just completed), and the completion window is then applied client-side. Including in-progress builds lets an instability be caught as soon as a build's test job has uploaded results, before the whole build completes.
2. Resolves each run's PR number and base branch (same-repo PRs come from the run's `pull_requests`; fork PRs fall back to the commit→PRs API), keeping only runs that target the branch and either failed (completed within the window) or are still running.
3. Downloads those runs' test result artifacts and identifies the failing tests, **including every attempt of each run**. A workflow can be re-run, and the run-level artifacts endpoint returns the artifacts from all attempts (a re-run uploads a fresh artifact id even when the name is unchanged), so each `*TestResult*` artifact is fetched by id rather than via `gh run download` (which only returns the latest attempt). Failures are unioned per run, and a running build that has not uploaded results yet is simply skipped.
4. Marks any test that failed on at least `minDistinctPrs` (default **3**) **distinct PRs** as unstable, and merges it into the Path A base list via the same `Add-FailedTestsToUnstableTests` additive merge (existing entries preserved).

For visibility, each run logs a **PR → failing tests** map (built by `Get-PrFailingTestsMap`), aggregating each PR build's failures across its attempts under a collapsible `::group::` in the workflow log.

Distinctness is counted by **PR number**, so retrying the same PR — whether as a new run or as additional attempts of the same run — does not inflate the count. Entries carry the reason `Auto-detected: failed on <N> distinct PRs targeting '<branch>' within the last <windowHours> h` and a `sourceRunUrl`. This path **never removes** entries; because Path A recomputes from CI/CD in the same run, a cross-PR-added entry is dropped once it stops failing in CI/CD, and Path B re-adds it on the next run if it keeps recurring across PRs — the intended self-healing behavior.

The correlation logic lives in `TestTolerance.psm1`, split into a computational, unit-tested core with no `gh`/network or file I/O (`Select-CrossPrUnstableTests`, which counts distinct PRs and applies the threshold; and `Get-PrFailingTestsMap`, which builds the per-PR failing-tests map) and a thin `gh`-facing wrapper (`Find-CrossPrUnstableTests`, which lists runs, resolves PRs, and downloads each attempt's artifacts via `Get-RunFailedTestsAllAttempts`). The `UpdateUnstableTestsCombined.ps1` script drives the whole run: Path A recompute (or, when no CI/CD runs are available, preserving the existing list so it is never wiped) → Path B cross-PR detection → a single additive merge → one artifact write. It is wrapped by the `UpdateUnstableTestsCombined` composite action (which invokes the script and uploads the artifact), and the scheduled workflow simply calls that action per branch. Because both signals are merged before writing, PR builds always consume one coherent artifact and there is no interleaving race between separate publishers.

> **Confidence trade-off:** the default threshold (`minDistinctPrs = 3`, no base-branch guard) is deliberately tuned for speed. It can, in the worst case, tolerate a *real* regression that has just landed on the base branch and is therefore failing across many PRs. This is accepted because the scheduled recompute self-heals the list and the exposure is time-bounded; raising `minDistinctPrs` or adding a base-branch check would trade speed for a lower masking risk.


**Test identity key**

Each test is identified by a three-part normalized key: `extensionId::codeunit::testMethod` (all lowercase). The `extensionId` is read from the `<properties><property name="extensionid">` element in the test results XML; it is empty-string for suites without that property. Two tests with the same codeunit and testMethod name but different extension IDs are treated as distinct tests.

> **Schema migration note:** Unstable-tests artifacts produced before the `extensionId` field was added use the old two-part key format (`codeunit::testMethod`). When a run downloads such an artifact, no matches will be found and tolerance will silently degrade to zero for that run. The artifact will be overwritten with the new three-part key format after the next UpdateUnstableTests run completes.

**Artifact lifecycle**

The scheduled `UpdateUnstableTests` workflow publishes a fresh per-branch artifact on every hourly run, retained for **7 days**. Because a replacement is produced hourly and PR builds only ever read the latest copy, the short retention still buffers a multi-day scheduler outage while keeping storage bounded (the manual `AddUnstableTestsFromRun` path, which runs the shared composite action, retains for 30 days). If the artifact expires before a new run produces a replacement, tolerance silently stops applying until the next run. A test that is removed from the codebase entirely stays on the unstable list until the next recompute drops it (or the artifact expires).

Per-branch runs are serialized with a `concurrency` group (`unstable-tests-<branch>`, `cancel-in-progress: false`): if an hourly run for a branch runs long and the next one starts, the newer run queues behind it so the newest recompute is always the last to upload, avoiding a stale copy overwriting a fresher one. Different branches use different groups (artifacts are branch-scoped) and never block each other.

### 6.2 Branch resolution

The tolerance branch is resolved at runtime by `Get-ToleranceBranch` (in `TestTolerance.psm1`):

1. If `GITHUB_BASE_REF` is set and is a supported branch → use it (PR targeting `main` or `releases/*`).
2. Else if `GITHUB_REF_NAME` is a supported branch → use it (push on `main` or `releases/*`).
3. Otherwise → default to `main`.

This means tolerance always applies — even on feature branches — using the unstable tests list from the nearest supported branch.

### 6.3 Tolerance entry point

The feature uses a single entry point:

**Container-level (`Test-ShouldTolerateFailures` in `TestTolerance.psm1`)**

Used in `RunTestsInBcContainer.ps1`, after retries are exhausted. Behavior: *all-or-nothing*. If **every** failure in the test run is tolerated, the entire run is treated as successful and the XML is rewritten. If even one failure is not tolerated, no tolerance is applied and the run fails normally.

The artifact download (`Receive-UnstableTestsArtifact`) is deferred until tests have actually failed, avoiding unnecessary API calls on green builds.

### 6.4 How the build interprets unstable tests

Tests run normally; the build does not skip anything based on the artifact.

When a test **fails**, it is cross-referenced against the unstable tests artifact for the current branch:

- **If listed as unstable**: the `<failure>` (or `<error>`) node is **reclassified as `<skipped>`** in `TestResults.xml` in place. The `<skipped message="Failed (tolerated by Test Tolerance) (&lt;reason&gt;)">` node preserves the original failure message as its inner text, the test method `name` is suffixed with ` (tolerated)`, the parent `<testsuite>` `failures`/`errors` count is decremented and its `skipped` count incremented, and a `<system-out>FAILED (TOLERATED): ...</system-out>` marker is inserted. The test therefore does **not** fail the build, but stays clearly visible in the test summary as a tolerated failure (a skipped test named `<testMethod> (tolerated)`) rather than being silently reported as a pass.
- **If not listed**: the failure is unchanged and fails the build as it does today.

### 6.5 Reporting & telemetry

- **Build log**: each tolerated failure is logged as `TOLERATED: <extensionId> :: <codeunit> :: <testMethod> — <reason>` inside a collapsible `::group::` block. Non-tolerated failures are also listed explicitly so engineers can see what will fail the build.
- **Test report visibility**: tolerated failures appear as **skipped** tests named `<testMethod> (tolerated)` in the GitHub UI test report (not as passes), so they are easy to spot in the summary without failing the build. The skip message and `<system-out>FAILED (TOLERATED): ...</system-out>` marker carry the original failure reason for tooling that inspects the raw XML.
- **Telemetry**: not yet implemented (tracked separately).
- **Build summary**: not yet implemented (tracked separately).
- **Dashboard / trend report**: not yet implemented (tracked separately).

## 7. Open questions

| Question | Status |
|---|---|
| Should tolerated failures appear as warnings in the GitHub UI test report rather than silently as passes? | Implemented — tolerated failures are reclassified as skipped tests named `<testMethod> (tolerated)` so they surface in the summary without failing the build |
| Should there be a manual override path for adding a test that is consistently unstable but always fails alone? | Implemented — see the AddUnstableTestsFromRun workflow in §6.1 |
| What is the eviction policy when a test is removed from the codebase entirely? | Accepted for now — stays on list until artifact expires (7 days) |
