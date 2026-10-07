# Per-worker remount warmup diagnostic — AB#646383 — DO NOT MERGE

**Prepared only: do not dispatch until the parent verifies safe scheduling.**
The original300 and pending tenant-count20 retain their original commits and runs.
This branch uses the same repository concurrency group, max six cells, and
`cancel-in-progress: false`. GitHub can replace a pending group member when another
is queued: the scheduling input is an acknowledgement, NOT an automatic lease.

## Current three-arm protocol

Thirty exploratory originals: five W1 and five DE cells each for `control`,
`workerwarmup` and `navreadiness`. The original twenty control/warmup identities
are preserved. Alternating country/arm order keeps cells nearby; actual runner
placement is not guaranteed. All arms use the original four mounted tenants,
three secondary clean workers, reserved pristine default, exact source/runtime/
package pins documented below, and the full21-CU/253-case/19-existing-skip cohort.
There are no added disabled tests, SQL retries, or separate default first-app warmup,
AL/auth changes, rebuilt packages, or changes to the original discovery lifecycle.
The immutable14-day package snapshots from run37634358042 are reused and verified
at plan and cell execution; expiry fails closed without substitution.

### Superseding operation: existing first-app dispatch on every worker

Per explicit user redirection, this replaces the previously prepared URI-method
selection. After **every** pristine worker remount, candidate cells invoke the
**same `Invoke-WarmupDispatch` mechanism** previously run on default:

* Select the **original ordered first app**, `System Application Test Library`,
  resolving its installed AppId. Unexpected ordering or a missing app fails closed.
* Use the original `Start-TestAppDispatch` → `Start-TestJob` →
  `RunTestsInBcContainer.ps1` IntegrationTest path with unchanged runner parameters,
  credential, company and `SkipAutomaticDisabledPass` handling.
* Target the remounted worker rather than default. Only tenant and evidence paths
  change. A private app-queue copy prevents the consumed warmup app from removing
  any real pending app or clean codeunit.
* Await the original dispatcher once; failure, transient/rerun state or unfinished
  work fails the trial without retries. Original job wait/cleanup and workflow
  timeout apply; no new 180-second child-job wrapper is used.
* **Empty `<testsuites/>` is allowed intentionally.** Success means the existing
  app dispatch completed, not that any test methods ran. No new exact-method/XML
  selection or business-data mutation checks are added.

This studies session/company-path warmup and may execute **zero test methods**.
It gives **no readiness guarantee**, and is not proof of exercising the failing
OData/help-metadata call chain or fixing SQL pooling.

### NAV-inspired readiness adaptation (third arm only)

After each pristine remount reaches Operational, `navreadiness` waits30seconds
**inside the serial reset call, before another worker may be remounted**.
After all batch resets and their waits, each worker executes the same app warmup
above, performs one authenticated GET to its own `/api/v2.0/companies?tenant=...`
(60-second timeout, zero retries, exactly one expected company), then waits30seconds.
All worker preflights must finish before any real codeunit in that batch starts.
The discovery restore follows the same phases. Thus a completed readiness trial
has22 app dispatches,22 probes, and44 fixed30-second waits (at least22minutes of
intentional overhead). Every phase records success/failure, UTC and monotonic time.
Failure aborts the trial; no real CU dispatch, retry or success-shaped fallback is
allowed after failed preflight.

This is **not identical to NAV's Toolkit preflight**. NAV's source waits30seconds
inside its shared creation lock, initializes a retry-capable tenant client session,
opens/closes runner page149042, fetches Toolkit `logentries` and `testmethodlines`,
then waits30seconds. Here serial reset pacing substitutes for that lock; existing
app dispatch is **not proven to open/close page149042**, and companies GET substitutes
for both Toolkit endpoints. No Toolkit, AL, auth or explicit session-retry changes
are introduced. Existing runner/client behavior and5-second app-dispatch spacing
are inherited unchanged by both warmup arms.

This **compound treatment cannot separate waits, session warmup and GET effects**.
Earlier companies200 responses were followed by a correlated SQL-pool failure,
so these checks do not guarantee SQL readiness. Control has no warmup, probe or
added wait; `workerwarmup` has only the existing app dispatch.

The discovery worker is restored and warmed once before template freeze. Each
clean batch then finishes **all restores**, **all warmups**, and only then
dispatches full cohort codeunits. Thus a complete candidate has22 independently
completed app dispatches (one post-discovery restore plus21 pre-CU restores), outside
cohort XML. The paired control records the same receipts but performs no warmup.
Dispatch consumes an exact tenant/generation/next-CU receipt once; stale/missing
receipts cannot authorize execution. Original stop-after-failed-batch behavior
and all first-attempt SQL evidence remain intact.

### Evidence and timing

`worker-warmup/<tenant>-g<generation>-cu<nextCU>/` contains raw isolated worker
logs, any emitted warmup XML and UTC/monotonic overhead receipts. Each receipt
records selected app/AppId, tenant/reset/next-CU identity, attempt and outcome.
CU0 denotes discovery.
Reset timing, original reset identities, dispatch receipts, full cohort attempt
logs/XML/events, final counts and always-run cleanup remain separate.
`worker-performance.json` separates pre-checkout total, setup before discovery,
execution, each reset, each warmup (including original dispatch/startup/wait overhead),
and cohort dispatch/case timing. Missing measurements are explicit gaps; incomplete
cohort/22-remount coverage cannot pass. Total excludes queue/upload. XML duration
is not isolated API latency. Timing/instrumentation is identical in all arms.
Serial postmount pacing is included in reset wall time and is also reported
separately: do not add it twice. `readinessPhaseTotalsByWorker` separates app,
probe and both wait phases; `readinessFailures` identifies failed phases.
Five trials per country/arm are exploratory, not a reliability proof; runtime
operation results remain unverified until the authorized CI execution.

## Historical original300 protocol (reference only; not this branch's schedule)

Explicit user authorization: 2026-10-07. One manual `CICD.yaml` dispatch on
`features/646383-sql-api-300-trial-comparison` with `mode=originals` schedules
**3 arms × W1/DE × 50 indices = 300 original disposable-container trials**.
The separate historical DE replacement `37630750803` is not part of these 300.
No exclusion arm, automatic job rerun, production fix, shared NST, or AL changes.

## Arms

| Identity | Pre-clean first-app warmup | One companies probe after each worker restore | Evidence-qualified whole-CU retry |
| --- | --- | --- | --- |
| control | No | No | No |
| warmup | Yes | Yes | No |
| retry | Yes | Yes | At most once per CU |

All arms use the same discovery, pristine-template freeze, owned worker reset,
21-CU order, four tenants (default plus three workers), ordinary baseline skip
configuration, artifacts and diagnostic instrumentation. The common source is
`fbd7ec46c636ee5f9d940cb81e5abbc1df90f055`, with obsolete method exclusion removed.
`Lifecycle.psm1` and its probe tests are restored exactly from original warmup
`fcc1776c6b165199dd66e4227675b1cc31da7a8f`: **one request, TimeoutSec 60,
MaximumRetryCount 0**, no probe retry. Both warmup arms use that identical code.
The template is frozen before first-app warmup on default. Each three-worker
batch completes all restores (then all probes, when enabled) before test dispatch.
As in the original pilot, terminal failures drain the current batch and stop
later CUs; incomplete trials are never passes. This rule is identical across arms.

## Scheduling and resource bound

`PlanComparison.ps1` validates pins and writes the canonical manifest before
any containers start. Ten sequential reusable-workflow batches each contain
30 cells (five indices × two countries × three arms), below the 256 matrix limit.
Each batch has `fail-fast: false`, maximum parallelism **six**, and depends on
completion of the preceding entire batch. Failed trials do not skip subsequent
batches. Queue order rotates arms and countries across balanced six-cell index
blocks; runner placement/execution order is not guaranteed and remains a possible
confound to report. Workflow-level concurrency serializes this comparison and
its explicit replacements; it does not cancel unrelated work.

Each cell has a 120-minute timeout. Worst-case allocation is 36,000 runner-minutes,
with approximately 100 hours of test execution at the six-container ceiling;
actual queues, setup and trial durations determine elapsed time. The requested
300 are not reduced to fit an EOD target. No guarantee of finishing by tomorrow.

Exact repository, branch, manual event and `run_attempt == 1` gates protect
planning, execution and provisioning. Automatic PR Initialization excludes this
exact branch. No PR is necessary for dispatch; existing draft PRs remain untouched.

## Immutable packages and platform

AL/package source **c4953dceffe02a017adad34973e1955017bf5d20**, source run
**37372848860**. `Prepare.ps1` checks ancestry, no source diff, artifact metadata,
archive SHA256 and per-package hashes. Plan checks and downloads all four original
artifacts while unexpired, then uploads their **unchanged ZIP bytes** and original
metadata into immutable, 14-day W1/DE snapshot artifacts on this run. This avoids
the original artifacts' 2026-10-08 expiry cutting off later bounded batches.
Every cell validates its snapshot's exact run/revision/name, transport digest,
original artifact IDs/source/digests, inner ZIP hashes, and extracted package hashes.
There is no rebuild or package substitution. Explicit replacements reuse the
original comparison's country snapshot, not a newer build. Snapshot expiry/drift
fails closed. Package archive IDs remain those of the original source in provenance;
the separate snapshot artifact/run IDs are additionally recorded.

| Country | App artifact | Test artifact |
| --- | --- | --- |
| W1 | 11374170356 | 11374145359 |
| DE | 11376415128 | 11375174896 |

Exact SHA256 pins are recorded in `Comparison.psm1`, `Prepare.ps1`, and uploaded
`artifact-proof.json`. NST **30.0.55665.0**, application **30.0.55683.0**, BCH
**6.1.19-preview2811389**, AL-Go `91b96c2b294be6f823277dafe6f03350abfb9d23`,
generic image `sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492`,
PowerShell 7, existing password-file authentication, and `My Company` are unchanged.

## Retry evidence and accounting

Every failed JUnit case must contain the observed GET 500/InternalServerError,
null-reference response, and CorrelationId. Each must match an NST Application
event 701 in that dispatch's UTC window, with the same ClientSessionId,
RootException NullReferenceException, and all three observed stack frames:
`NavSqlConnectionScope.AcquireSqlConnectionFromPool`,
`MetadataProvider.GetRelativeHelpUrl`, `PageDataProvider.GetNavRecordDataAsync`.
Generic HTTP500/NRE, mixed assertions, stale/unmatched events, stopped jobs,
missing/partial XML, or evidence persistence failure never authorize retry.

All arms retain matching first-attempt evidence, but only `retry` schedules
one whole-CU replay on its freshly restored worker with another single probe.
BCH `ReRun` is removed so all methods run. Recovery requires the exact original
names, count and skip states with no failures/errors. Original and retry result
snapshots remain separate. Only validated recovery replaces that CU in final XML.
Failed retries remain failures and cannot retry again.

Full completed coverage requires **21 suites, 253 cases, 19 baseline skips**;
the 234 non-skipped cases must pass for an unrecovered first-attempt pass.
`148318.CapabilitiesProjectsEnabledViaAPI` must appear exactly once and remain
enabled in every arm. Never count baseline skips, missing results, cancellations
or communication-invalid trials as passing. Report original SQL failures,
retry recoveries, final failures and infrastructure invalids separately.

Ordered cohort:
139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,
139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343.

Artifacts are unique by arm/country/index/run and retained 14 days. Always-run
Finalize and upload preserve ownership/cleanup evidence, raw worker logs, EVTX,
nested `.buildartifacts` results, ordered prefix, reset timeline, probe records,
warmup outcomes, per-attempt XML/outcomes and correlated NST events. Per-CU
snapshots can contain earlier suites on that worker: aggregate only their named CU.
Runner loss may prevent final export/cleanup; parent monitoring must audit that,
not interpret absent evidence as success.

## Explicit communication replacements — not automatically dispatched

After summarizing original communication failures, invoke the same workflow with
`mode=replacement`, `replacementArm`, `replacementCountry`, `replacementTrial`,
`originalRun`, and `originalJob`. This schedules exactly one cell in Batch01;
Batch02–10 skip. The planner verifies the source run is this comparison's
**originals** run at the exact same SHA, the failed job matches the canonical
identity, and its authoritative failure annotation says the self-hosted runner
lost communication with the server. Genuine test/SQL failures cannot pass this gate.
`replacementOf` retains source run/job/event/attempt/workflow SHA and annotation.
The original stays invalid in original-300 accounting; replacements are separate.
Do not use GitHub's normal rerun button (attempt-two gates intentionally reject it).
Dispatch replacements one at a time: GitHub concurrency permits one pending run
and can supersede an older pending run if multiple are submitted.

Local validation: focused Pester suites under `SqlResetPilot`,
`tests/SqlApiTestRetry.Test.ps1`, `tests/ParallelTestExecution.Test.ps1`;
PSScriptAnalyzer, parsed YAML dependency/matrix checks and `git diff --check`.
All local container operations are mocked.
