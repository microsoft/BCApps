# DE trial 3 communication replacement — diagnostic only, do not merge

One authorized manual `CICD.yaml` dispatch on
`features/646383-sql-api-de3-communication-replay` runs **only DE trial 3**,
with maximum parallelism one and a 120-minute cap. This replaces only job
`112748402288` from run `37608087700`: the self-hosted runner lost communication
before tests started. The original event was `workflow_dispatch`, attempt one,
workflow `.github/workflows/CICD.yaml`, at
`fcc1776c6b165199dd66e4227675b1cc31da7a8f`.
The new run is separately identified in `provenance.json`; it is not an original
success. The genuine W1 SQL failure is not rerun.

Treatment is byte-for-byte the original `fcc1776` runner/lifecycle: full cohort,
no extra disabled method, no SQL retry, one companies probe with its original
60-second timeout. Changes only narrow workflow/branch/preflight guards, record
replacement provenance and update diagnostic tests/docs. Cleanup and artifact
collection remain the original implementation. Only attempt one is allowed.
No further dispatch, PR, merge queue, local/shared NST operation, or
fresh-database-name treatment is authorized.

## Fixed baseline

The branch starts from SQL reset pilot `d7dd4dddcd49da397ee42de1677d1b7d44622149`.
AL source remains exactly PR2 `c4953dceffe02a017adad34973e1955017bf5d20`.
Both countries consume their own unchanged compiled packages from run
`37372848860`; this does not claim country package binaries are identical.
`Prepare.ps1` verifies the source ancestry/diff, artifact run/head/digests,
downloaded archive SHA256 and per-package hashes. Missing or expired artifacts
fail closed; there is no moving-build fallback.

| Country | App artifact | Test artifact |
| --- | --- | --- |
| W1 | 11374170356 | 11374145359 |
| DE | 11376415128 | 11375174896 |

The pinned runtime is NST **30.0.55665.0**, application **30.0.55683.0**,
BCH **6.1.19-preview2811389**, AL-Go
`91b96c2b294be6f823277dafe6f03350abfb9d23`, and generic image
`sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492`.
The image matches the pilot; historic source logs did not record its digest.
PowerShell 7, four tenants, original password-file authentication and company
`My Company` are retained.

## Experiment order and failure policy

1. Original discovery runs on a worker, which is then restored from default.
2. The immutable pristine template is frozen **before** app warmup fixtures.
3. The original `Invoke-WarmupDispatch` runs the ordinary first test app alone
   on default, with the original `SkipAutomaticDisabledPass` behavior.
   Results live under `sql-reset-pilot-output/warmup`, outside prefix coverage.
   Failure, a transient queue, a skipped warmup or an incomplete job stops the trial.
4. For each of seven clean batches, restore all three workers under their
   original `tenant2/3/4` database names, then probe all three, then dispatch.
5. Each probe makes **one external host HTTP GET** to
   `/BC/api/v2.0/companies?tenant=tenantN`, using the actual server instance,
   port/IP and existing container credential. Basic auth is sent preemptively.
   No redirects or HTTP retries; timeout is 60 seconds. A non-200 response,
   invalid JSON or missing expected company stops the trial before dispatch.
6. Test failures drain the current three-worker batch and stop later batches.
   No test, transient, warmup or restore retries are enabled. Existing bounded
   mount-state polling and ordinary scheduler waits are unchanged.

The cohort remains the same ordered **21-codeunit prefix**, ending with Expense
Users (148315), Capabilities (148318), and Activity Log (148343). The previous W1
control yielded **253 cases: 234 passed, 19 skipped**, across 20 codeunits with
cases. This is a quick cohort, **not all API paths or the full suite**. Warmup
counts must be reported separately. Discovery-order drift fails closed.

## Isolation, evidence and interpretation

At runtime only, the selected project descriptor is copied to
`build/projects/Test Apps <country> Trial<trial>` at the same directory depth.
AL-Go derives a unique container name:
`bcbuildprojectsTestApps<country>Trial<trial><run>`.
Country settings and wrapper targets stay unchanged. Preflight refuses an
existing container; final cleanup checks country, trial, run, arm and exact
registered name before removing only that owned disposable container.

Artifacts preserve provenance, shell/runtime identity, worklist, SQL reset
timeline, warmup outcome/results, worker output, prefix JUnit and EVTX.
`companies-probes.jsonl` records sanitized URI, tenant, generation, HTTP status,
UTC start/end, duration and safe client/server correlation IDs. No password,
authorization header, response body or raw HTTP exception is added to logs.
Runner loss or cancellation can prevent final export/cleanup and is inconclusive.

This experiment combines two warmup interventions; it cannot distinguish their
individual effects. A pass/non-reproduction is not proof of a production fix or
SQL-name reuse safety. Report every trial, including preflight/probe failures,
timeouts and missing evidence. Do not launch another matrix without authorization.

Local validation requires Pester 5+ (validated with 6.1.0), not an NST:
`Invoke-Pester .\build\scripts\SqlResetPilot`
