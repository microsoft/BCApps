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

Unstable tests are tracked via a **per-branch artifact** (`unstable-tests-<normalized-branch>`) maintained by the UpdateUnstableTests workflow that runs after each CI/CD completion. Tests are never annotated in source; the list lives entirely in the artifact.

- The artifact is **branch-scoped**: its name encodes the branch it applies to, so each branch can have its own set of unstable tests.
  - Naming pattern: `unstable-tests-<normalized-branch>`, where the branch name is normalized by replacing non-alphanumeric characters (except `.`, `_`, `-`) with `-`. For example, `releases/26.0` becomes `unstable-tests-releases-26.0`.
- Supported branches: **`main`** and all **`releases/*`** branches only. Other branches do not produce or consume the artifact.

**Sliding window heuristic**

After each CI/CD run completes, the UpdateUnstableTests workflow examines the last **3** completed CI/CD runs on the branch (the default window). The unstable-tests list is **fully recomputed** from those runs — no incremental merging.

- **ADD**: Any test that failed in at least one of the last 3 runs is added to the list.
- **REMOVE**: Any test that did not fail in any of the last 3 runs is dropped from the list (i.e., self-healing is automatic over a 3-run window).

The artifact records the `runIds` field listing the exact runs examined, for traceability.

The window size (default 3) is a parameter of `UpdateUnstableTests.ps1` and can be changed without modifying the schema.

**Test identity key**

Each test is identified by a three-part normalized key: `extensionId::codeunit::testMethod` (all lowercase). The `extensionId` is read from the `<properties><property name="extensionid">` element in the test results XML; it is empty-string for suites without that property. Two tests with the same codeunit and testMethod name but different extension IDs are treated as distinct tests.

> **Schema migration note:** Unstable-tests artifacts produced before the `extensionId` field was added use the old two-part key format (`codeunit::testMethod`). When a run downloads such an artifact, no matches will be found and tolerance will silently degrade to zero for that run. The artifact will be overwritten with the new three-part key format after the next UpdateUnstableTests run completes.

**Artifact lifecycle**

Artifacts are retained for 90 days. If the artifact expires before a new CI/CD run produces a replacement, tolerance silently stops applying until the next UpdateUnstableTests run. Each UpdateUnstableTests run publishes a fresh artifact, resetting the 90-day clock. A test that is removed from the codebase entirely stays on the unstable list until the artifact expires.

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

- **If listed as unstable**: the `<failure>` (or `<error>`) node is **removed** from `TestResults.xml` in place, the parent `<testsuite failures="...">` count is decremented, and a `<system-out>TOLERATED: ...</system-out>` marker is inserted. The test appears as a pass to all downstream tooling (AL-Go analysis, GitHub test reports, dashboards). The `TOLERATED:` marker in `<system-out>` is the only signal in the XML that reclassification occurred.
- **If not listed**: the failure is unchanged and fails the build as it does today.

### 6.5 Reporting & telemetry

- **Build log**: each tolerated failure is logged as `TOLERATED: <extensionId> :: <codeunit> :: <testMethod> — <reason>` inside a collapsible `::group::` block. Non-tolerated failures are also listed explicitly so engineers can see what will fail the build.
- **Test report visibility**: tolerated failures appear as passes in the GitHub UI test report because the `<failure>` node is removed. There is no warning-level marker in the report. This is a deliberate trade-off for now; the `TOLERATED:` marker in `<system-out>` is available for tooling that inspects the raw XML.
- **Build summary**: not yet implemented (tracked separately).
- **Dashboard / trend report**: not yet implemented (tracked separately).

## 7. Open questions

| Question | Status |
|---|---|
| Should tolerated failures appear as warnings in the GitHub UI test report rather than silently as passes? | Open — current behavior is silent pass via XML rewrite |
| Should there be a manual override path for adding a test that is consistently unstable but always fails alone? | Deferred — not in initial scope |
| What is the eviction policy when a test is removed from the codebase entirely? | Accepted for now — stays on list until artifact expires (90 days) |
