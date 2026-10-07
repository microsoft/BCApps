# SQL API two-arm diagnostic — AB#646383 — DO NOT MERGE

One manual `CICD.yaml` dispatch on `features/646383-sql-api-two-arm-experiment`
runs **A/B × W1/DE × five trials = 20 independent disposable containers**.
Maximum parallelism is **five globally**, timeout 120 minutes per cell (2,400
runner-minutes maximum). Exact branch and run-attempt-one guards reject reruns.
The exact experiment PR head is excluded from automatic PR Initialization;
there is no full-country pipeline, job retry, replacement run, or local NST work.

## Shared immutable baseline

Both arms start at warmup head `8a7ebc7d665c0a812c2b3b4902c63df570959954`.
AL/package source remains **c4953dceffe02a017adad34973e1955017bf5d20**.
`Prepare.ps1` verifies ancestry, no source diff, exact source run **37372848860**,
artifact metadata/digests, ZIP SHA256 and package hashes. Missing/expired
artifacts fail closed; there is no rebuild or moving-package fallback.

| Country | App artifact | Test artifact |
| --- | --- | --- |
| W1 | 11374170356 | 11374145359 |
| DE | 11376415128 | 11375174896 |

NST **30.0.55665.0**, application **30.0.55683.0**, BCH
**6.1.19-preview2811389**, AL-Go `91b96c2b294be6f823277dafe6f03350abfb9d23`,
generic image `sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492`,
PowerShell 7, four tenants, existing password-file authentication and `My Company`
are unchanged. No auth/provider changes or AL assertion changes.

Both arms freeze the pristine template before ordinary first-app warmup, then
restore each clean batch under the original tenant database names, probe every
restored worker, and only then dispatch. Companies probes use **one attempt**,
20-second connect/read timeouts, no hidden HTTP retries or redirects. This
disables the optional three-attempt readiness behavior added after the original
warmup run `37608087700` at `fcc1776c6b165199dd66e4227675b1cc31da7a8f`.
The newer baseline's nested `.buildartifacts` collection is retained.

## Treatments

**A — exclude one method:** the existing `Get-DisabledTestsForApp` runner config
adds only `{codeunitId:148318, method:CapabilitiesProjectsEnabledViaAPI}`.
No source or package is edited; the whole Capabilities codeunit stays selected.
All existing baseline disabled tests remain unchanged. No test retries.

**B — all baseline-enabled tests remain enabled:** no additional disabled entry.
At most **one whole-codeunit retry**, and only after every failed JUnit case has:

* The observed GET HTTP500/null-reference response and a valid CorrelationId.
* An NST Application event 701 from `MicrosoftDynamicsNavServer$...`, obtained
  from this container during this dispatch's UTC time window.
* Matching `ClientSessionId`, `RootException: NullReferenceException`, and frames
  `NavSqlConnectionScope.AcquireSqlConnectionFromPool`,
  `MetadataProvider.GetRelativeHelpUrl`, and `PageDataProvider.GetNavRecordDataAsync`.

Generic HTTP500, generic NRE, real/mixed assertions, stale/unmatched events,
partial XML, stopped jobs, missing evidence or persistence errors never qualify.
No automatic polling/wait for evidence. This conservative additional observed
metadata-stack requirement can reject other SQL-pool shapes.

The entire current batch drains before a retry. The retry uses the same worker
after another pristine-template restore and fresh single-attempt companies probe.
`ReRun` is explicitly removed: BCH must run **every method**, not just failures.
Retry files use a unique suffix. Recovery requires the exact original test names,
count and skip states with no failures/errors. Only verified recovery replaces
that CU in the final merged result; original and retry files remain separately
preserved. A failed/incomplete retry stays failed and cannot retry again.
Any unrelated terminal batch failure stops later batches (including queued retries).

## Cohort and interpretation

The exact ordered 21-CU prefix remains:
139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,
139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343.
Order drift fails closed. This is not the full API suite.
Previous complete W1 coverage was 253 cases (234 passing, 19 skipped).
A should turn only the target method into an additional skip; B retains baseline
coverage. Actual counts and any missing/incomplete coverage must be reported per
trial; do not count recovered first failures as first-attempt passes.

Containers derive from `Test Apps <country> Trial<trial><A|B>` at unchanged
descriptor depth. Preflight refuses existing containers; cleanup verifies
country/trial/experiment/run/exact name before deleting only the owned container.

Artifacts preserve provenance, pins, ordered worklist, SQL reset timeline,
single-attempt probe records, worker logs, EVTX, separately labeled warmup,
project-root and nested final XML, plus:
* `test-attempts/<tenant>-<CU>-1/`: original result snapshot and outcome.
* `test-attempts/<tenant>-<CU>-2/`: retry result snapshot and outcome.
* `SqlApiRetryEvidence/`: original CU XML and correlated NST events.

Per-CU snapshots may include previously completed suites on that worker; count
only the outcome's CU when aggregating first attempts. Final merged XML contains
one result per CU, with recovery replacing rather than duplicating cases.
Runner loss/cancellation can prevent final export and is **inconclusive**.
Passes are non-reproductions, not proof of a production fix or SQL-name reuse safety.

Local validation uses Pester 5+ and PSScriptAnalyzer, with all live container
operations mocked. Tests: `build\scripts\SqlResetPilot`,
`build\scripts\tests\SqlApiTestRetry.Test.ps1`, and
`build\scripts\tests\ParallelTestExecution.Test.ps1`.
