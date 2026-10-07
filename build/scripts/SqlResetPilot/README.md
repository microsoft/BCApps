# SQL API tenant-count exploratory diagnostic — AB#646383 — DO NOT MERGE

## Current branch: 20 additional originals, not part of the 300

Explicit authorization: 2026-10-07T21:53:58Z. Dispatch `CICD.yaml` with no inputs on
`features/646383-sql-api-tenant-count-comparison`: **2 mounted-tenant counts ×
W1/DE × 5 indices = 20** additional original trials. Canonical identities are
`t1/W1/1` through `t2/DE/5`. This exploratory sample is not reliability proof.
No additional four-tenant arm, warmup, companies probe, SQL retry, AL/auth edits,
or new disabled tests. Complete successful coverage remains **253 cases, 19
existing skips, 21 codeunits**, including `CapabilitiesProjectsEnabledViaAPI`.
Failures stop later codeunit batches exactly as before; incomplete trials cannot pass.

Both counts use **all mounted tenants as workers**: one/default, or two/default
and tenant2. The NST remains multitenant even with one mounted tenant, with its
separate application database. A detached `default-test-template` is copied and
made SQL READ_ONLY **before discovery executes any OnRun triggers on default**.
Discovery always restores default in `finally`. Each codeunit receives a fresh
worker database restored from that same template, including default. No database
is copied onto itself. The template is never mounted, overwritten or removed;
only deletion of the entire owned disposable container removes it.
Every reset checks local mounted mapping, exact tenant count, template GUID and
READ_ONLY state. Restore inherits READ_ONLY, so only the whitelisted worker
destination is made READ_WRITE before Mount-NAVTenant. There is no retry/fallback.
The existing command sequence and runtime command-capability proof are retained;
one-tenant/default restore additionally requires the exact diagnostic gate.

Reference control: run **37634358042**, SHA
`0227094059f2f26f3fcb1b7f85a3285c17e78b8e`, control arm only. That branch/run is
untouched. It has four mounts but **three workers**, reserves default, and
discovers on a secondary before freezing the template. Differences in template
preparation, resource instrumentation, worker layout and **later execution
temporal bias** mean this is not a perfectly controlled 1/2/4-worker comparison.

### Serialization and package provenance

One workflow, one 20-cell matrix, fail-fast false, max-parallel six. Literal
repository-wide workflow concurrency group `sql-api-646383-300-trial-comparison`
is shared with the original 300 and its replacements; cancel-in-progress false.
The entire new run waits until that group is released, never adding containers
while the original uses six. **Only one pending run is supported by the existing
group policy: do not submit another comparison/replacement while this run is
pending, because GitHub can replace the pending run.** Runner-loss orphans still
require ownership-aware audit; scheduler limits alone cannot prove their removal.
The historical DE replay 37630750803 completed successfully and is separate.

Unchanged pins below apply. Package bytes come from the original 300's preserved
14-day W1 snapshot **11487493885** and DE snapshot **11486874993**, not rebuilt
artifacts. Planning verifies exact IDs/names/run/SHA/digests/expiry; each trial
verifies transport hash, inner ZIP hashes and original source metadata. Expiry
fails closed. Per-trial settings change only the requested tenant count; memory
remains **16G**, and actual Docker limits plus mounted worker counts are recorded.

### Stability and performance accounting

Keep raw first-attempt failure evidence, worker logs, event logs, nested results,
`final-counts.json` and `final-junit.xml`. No failure is tolerated or retried.
Report test failures, setup/reset failures, confirmed communication-invalid runs,
cancellations and incomplete coverage separately. No replacements are dispatched
by this workflow.

`performance.json` separates setup, execution including discovery/template/reset,
summed completed reset durations, per-case XML durations and monotonic cell total.
The cell total starts before checkout and ends after cleanup, excludes queue and
artifact-upload time; use GitHub job timestamps for complete job duration.
Codeunit elapsed time includes worker startup and result collection. The API
target's XML time measures the AL test case, **not isolated HTTP latency**.

The same read-only sampler in both arms records host CPU/free RAM/virtual memory/
paging, NST and SQL process cumulative CPU/working sets, and local SQL wait/I/O
counters about every 30 seconds during execution. No shared server modifications
or counter resets. Use deltas, account for recreated database IDs/counter resets,
and do not attribute all host activity to this container. Unsupported/failed
measurements are explicit in `resource-status.json` and `performance.json`;
measurement failure never becomes a success-shaped zero. Sampler cleanup runs
in finally and artifact/owned-container cleanup steps use always().

## Historical parent protocol (applies to the original branch only)

The sections below describe the untouched 300-trial parent, its pins and retry
classifier. Its dispatch commands **do not apply to this tenant-count branch**.

# SQL API 300-trial diagnostic — AB#646383 — DO NOT MERGE

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
