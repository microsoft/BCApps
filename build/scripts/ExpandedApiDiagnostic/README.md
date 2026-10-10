# DRAFT expanded API matched comparison — DO NOT MERGE

AB#653393 · AB#646383

**Executable opt-in orchestration, locally validated, not dispatched.**
The parent must review the complete successor and reserve **two** allocations
before any push, draft PR, or dispatch. No local AL compilation, publication or NST
test is claimed. The investigation remains open.

## Entry point and allocation bound

The registered `CICD.yaml` dispatch entry bridges to
`SqlApiExpandedDiagnostic.yaml` **only** on
`features/653393-expanded-api-helper-scope`, manual event, attempt1, with
`authorization=reviewed-originals`. Default authorization is **HOLD**.
The bridge avoids depending on a newly introduced workflow already being registered
on the default branch. Ordinary CI job bodies/push triggers remain unchanged;
they are excluded only on this exact diagnostic branch. Existing experiment
branches, protocols, dispatch definitions and concurrency groups are untouched.

`PullRequestHandler.yaml` uses `pull_request`, not `pull_request_target`.
[GitHub documents](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request_target)
that `pull_request` executes in the PR merge context; the branch-local workflow
gate is therefore honored. Every job in that handler excludes only an event with
`pull_request.head.repo.full_name == microsoft/BCApps` and
`pull_request.head.ref == features/653393-expanded-api-helper-scope`. Opened,
synchronize and reopened events are covered regardless of draft/ready status.
Other heads, forks and merge-group behavior are unchanged. Other PR workflows
(for example hosted PowerShell validation, labels and reviews) may still run;
this is **not** a promise of zero GitHub jobs. Do not enqueue/merge this diagnostic.
The inspected handler at fresh main `fcd2704c64729f42612c1959118588424e6ecb2b`
uses the same `pull_request` trigger. Future trigger/gate changes need re-review.
The immutable diagnostic source remains based on `97c2f034…`, not latest main.

A PR is **not required** to run the manual diagnostic after parent authorization:
`gh workflow run CICD.yaml --repo microsoft/BCApps --ref features/653393-expanded-api-helper-scope -f authorization=reviewed-originals`.
The input name is `authorization`; the exact value is `reviewed-originals`.

## Isolated helper-scope successor

This branch starts at immutable `1d4e69dd94ac4faee5ec0a05b0338abb301530b2`.
The predecessor branch/PR12587 and run37873706046 are not edited or replayed.
Parent terminal evidence records all five country compilations successful but
the separate sealing and cleanup processes failed command resolution; registry/
trials never ran. This was our **CI setup bug**, not evidence of a SQL platform bug.

`Import-ExpandedHelper` previously imported into the Context module's private
scope. The exact pinned helper really exports the reader and cleanup APIs.
It now publishes that exact instance to global session scope and checks version,
provider path, exports and required parameters. Warm instances are re-exported
without Force, preserving AL-Go configuration. Both build and lane workflows run
a pinned AL-Go BuildInitialize hook to load/verify the warm helper, followed by
a separate cold PowerShell API/signature check **before** compilation/provisioning.
The finalizer, producer and new-container callbacks also check their required
surface. Worker and sampler children already import directly in their own session.

Compiler cleanup now persists ownership/removal/absence/failure evidence even
when loading or removal fails, and rethrows the original error. Only the exact
run-scoped destination under the helper compiler root is eligible; matching names
elsewhere and reparse-point destinations are rejected. Null/unknown absence is
not success. Registry requires verified ownership and absence with no failure.
The five **remote compiler folders** from the predecessor remain cleanup-UNKNOWN;
these are not NST containers and this patch does not delete or assert absence of
them. Parent cleanup/capacity/provenance and independent review gates still apply.

`ExactHelperProbe.ps1` is an explicitly invoked integration probe, not an automatic
mock test. Run it in a fresh `pwsh -NoProfile` with the exact helper module, a new
workspace-local fixture, an already verified compiled app ZIP/digest and an
existing cached AL extension directory. It validates real exports/signatures,
cold caller visibility, warm instance/config preservation, parses the real Test
Runner package using the real helper and cached metadata reader (no compiler),
and creates/removes only its own disposable compiler-folder fixture. It performs
no NST/Docker/remote cleanup. The helper ZIP is obtained from the exact version URL
used by AL-Go91b96's `GetBcContainerHelperPath`, not a floating release. Mock suites
no longer globally preload fake BCH before calling the production loader.

The independent literal concurrency group is
`sql-api-653393-expanded-api-diagnostic`, cancellation disabled.

1. Plan declares all cells and exact source routes.
2. **Five shared country builds**, max-parallel2, compile all application and test
   dependencies once from the diagnostic source overlay.
3. Registry verifies actual country artifact IDs/digests and compiler cleanup.
4. **Fifteen configuration/country cells**, max-parallel2, each run their lanes
   sequentially through `_ExpandedApiCell.yaml` / `_ExpandedApiLane.yaml`.
   Every lane has a separate owned container, project, cache, company and template.
5. Always-run audit validates every original lane and compares exact packages,
   compiled selectors, methods and skip states across all three topologies.

Builds finish before trials start. Each active cell has at most one provisioning/
test job, so at most **two BC allocations** exist in either phase. Plan, registry
and audit use hosted control-plane runners, not BC container allocations.
Builds have180-minute and lanes360-minute bounds. There are39 lane executions,
one original per cell/lane; no automatic repetitions, replacements or reruns.
Runner loss without cleanup proof is invalid and still requires parent orphan
auditing; scheduler limits alone cannot prove physical cleanup.

## Bounded coverage

| Scope | Configuration cells | Lanes and CUs in each cell |
| --- | ---: | --- |
| W1 + DE | 6 | All five lanes,159 selected source variants per country |
| CA + US | 6 | IRS Forms Tests CU148018, Uncategorized only |
| IT | 3 | Eleven localized-fix CUs, Uncategorized only |

Topologies: `m1w1` = default; `m2w2` = default + tenant2; `m4w3` = four
mounted tenants with **only tenant2/3/4 as workers**. Default is reserved in the
baseline after its discovery reset. All three use the same protected template
and reset implementation, not the historical four-mount producer.

Primary lane counts: Default51, Integration33, Uncategorized66, Legacy bucket1
5, Legacy bucket2 4. APIV1/APIV2 include all three typed modes.
The existing reviewed inventory remains167 source variants /15 apps /five lanes.
Source declarations are not runtime case totals.

Italy was added after a focused metadata review: table12170 **Payment Lines**
and the **Operation Occurred Date** fields exist only in IT. W1/DE cannot exercise
the localized branches of `a91e0d9308` and `4902a412d0`. The11 representatives are
139709,139711,139723,139728,139729,139809,139811,139823,139828,139851,139865.
The other localization-only deltas are equivalent authentication initialization
or whitespace, not newly omitted unique logic.

Seven source variants remain explicitly unselected: APAC General Journal and
Prepayment, CH/CZ/ES/IT General Journal, NA Prepayment. CA/US are IRS-only, and IT
is the11-CU supplement, **not full country coverage**.160 distinct source variants
are selected overall. The plan and final audit enumerate exact uncovered paths.

## Immutable source, compiler and package provenance

The supplied main snapshot `ad9b529a78c818ba25c24aecd093442a6c7a3852` precedes
the externally owned revert. The isolated branch starts after its descendant
`97c2f034e7a32eb3bbb7efb1a1e893ea06ac121b`; PR12514 is untouched.

`source-overlay.patch` contains178 source paths from11 pinned reviewed commits.
It restores Expense enablement/consolidated fixes and the deferred full API stack
**only in a dedicated manually dispatched checkout**. No ordinary source,
disabled-test configuration or production default is enabled on push.
`StageSource.ps1` requires clean source, exact ancestor/base/hash and exact
resulting `src` subtree. Drift fails rather than overwriting or resolving conflicts.

The overlay preserves main's `29212ba86b` Company Info description restoration
and removes the duplicate RequiredTestIsolation property introduced by composition.
All167 route property/test-procedure sequences were checked;166 route files are
byte-identical to the reviewed stack at `f6c91f21b7fac7942c9d2dcd589a33c1b1b604c7`.
No stack refs changed and no wasteful reinventory was performed.

Only disabled entries removed by reviewed enablement commits are removed:

| Manifest | Before | Reviewed removals | Retained |
| --- | ---: | ---: | ---: |
| Expense Agent |60|51|9|
| E-Document Core |151|1|150|
| APIV1 |291|291|0|
| APIV2 |717|716|1|

These are manifest entries, not runtime skips. Existing intentional skips remain.
The former Expense-first sequencing exclusions are not restored.

Exact pins:

- AL-Go `91b96c2b294be6f823277dafe6f03350abfb9d23`
- BCH `6.1.19-preview2811389`
- Application artifact `30.0.55683.0`; platform **30.0.55665.0**
- Generic image `mcr.microsoft.com/businesscentral@sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492`
- PowerShell7,16G, existing disposable-container password-file authentication

The fixed30.x Platform47167 build is unpublished and **not adopted**. No floating
runtime or VSIX override is accepted. Compiler creation checks its exact artifact,
owns a unique run-scoped folder, and is cleaned even after compilation failure.
All incremental event flags are disabled and baselineWorkflowRunId is0.

The compile action builds all folders/dependencies; artifact upload precedes
sealing actual Apps/TestApps IDs, service archive digests, source head/subtree,
overlay hash, per-package SHA256/size/id/name/version/dependencies and compiler
settings. Compiler cleanup is mandatory before registry publication.
Every topology receives the same sealed registry and country manifest.
Downloads verify service provenance, transport SHA, path safety, exact package
bytes and file inventory. Old PR2/253-prefix snapshots cannot be substituted.

The original test-project marker (`projectsToTest`) is retained: pinned AL-Go
otherwise exits as an empty repository before reading installTestAppsJson.
There is **no** upstream dependency download or recompilation in a lane; only
the sealed new packages are supplied to RunPipeline.

## Runtime producer and original evidence

The new producer replaces the per-project test callback, not ordinary CI defaults.
The complete sealed build inventory remains distinct from the expected installed
inventory. **Library - No Transactions** and **Prevent Metadata Updates Library**
are compiled, uploaded and hash-verified but deliberately not published/installed
by the repository's standard publication policy. `AppPublicationPolicy.psm1`
supplies the same exclusion names and filename matching to the inherited publish
hook and the diagnostic validator. No diagnostic-specific exclusion or caller's
`AdditionalAppsNotToPublish` may relax required installation. The runtime records
both required and intentionally excluded packages; installing either excluded
library is also an error. All other sealed packages must match installed IDs and
versions. The final audit independently recomputes that partition. Compilation,
registry, download transport and per-file verification continue to include **all**
packages, including the two intentionally absent libraries.

It verifies actual required installed package IDs/versions (including Test Runner), actual
NST executable version, multitenancy with a separate application DB, mounted
mappings,16G and the pinned generic image's actual layer prefix. The actual derived
container image ID, runner/host and Docker CPU settings are retained.

Correct company/data setup is reused from the existing producer:

- Unit: Empty Company, no demo generation.
- Integration: My Company, setup demo data.
- Uncategorized: CRONUS International Ltd., evaluation/full demo data and scheduler.
- Legacy: CRONUS, existing Extended setup; bucket1 additionally checks Standard/
  Evaluation as before.

A diagnostic-only copy of the setup script preserves these paths, reduces both
setup retry budgets to **one**, makes schema-sync errors fatal and uses the owned
output directory for its transcript. Shared scripts are not edited.

After setup, all configurations copy default to a detached READ_ONLY template
**before** discovery. Template GUID/read-only state, local mapping and mounted
count guard each destructive reset. Discovery restores default in finally.
Default can subsequently be reset as a worker only in m1w1/m2w2; m4w3 reserves it.
All batch restores finish before dispatch, retaining the qualified reset sequence.

Discovery is not restricted to RequiredTestIsolation=Disabled:

- Actual compiled `None|Codeunit` and `Disabled` selectors establish the normal
 130450 versus Disabled130451 runner.
- A second effective discovery with preserved disabled manifests records actual
  enabled/skipped method sets.
- Legacy also gets explicit untyped app/CU discovery, which must exactly match
  the compiled runner classification; it cannot disappear through the typed path.
- Execution loads **only the verified numeric CU range**, without reloading the
  whole extension/type and rerunning other CUs' OnRun triggers on a clean worker.
- All cases are checked against exact country/lane/app/CU/method/skip identities.
  Unknown, missing, duplicate or changed skip states fail closed. Canonical
  cross-topology signatures do not depend on JSON property ordering.

Per-attempt transcripts, original XML and receipt are persisted before
classification. ERROR DIALOG/cancellation cannot become success. Each CU runs
once; independent later CUs may continue on newly restored workers, but a failed
original can never qualify. No first-app warmup, companies probe, SQL retry,
generic test retry, failure tolerance or added skip exists.

Always-run export/cleanup preserve original/nested pipeline logs, event logs,
runtime inventories, reset mappings, resource samples and performance files.
Only the owned run/cell/lane container is removed. Incomplete resource, cohort,
provenance, phase or cleanup evidence fails qualification even when tests passed.

## Timing and resources

Each lane starts its monotonic clock on its assigned runner before checkout and
ends after owned cleanup. Queue and artifact upload are excluded; summed sequential
lane totals are **not** whole-workflow elapsed time.

Setup, execution, template, discovery including its finally reset, per-reset host
intervals, in-container reset operation durations, CU dispatch/collection, worker
execution, XML case times, pipeline finalization/export and cleanup are separate.
Execution includes inventory/sampler/template/discovery/resets/tests/event export.
Reset host intervals are serialized within a lane; their union differs from the
in-container operation sum. CU dispatch durations include startup and batch-drain
waiting and overlap; worker execution excludes startup. Neither sum is wall time.
XML duration is AL case time, not isolated HTTP latency.

Identical read-only host/NST/SQL CPU/memory/paging/wait/I/O sampling runs in all
topologies, with setup samples and actual Docker limits. Missing/empty/error
measurements do not become zero-valued success. Cumulative counters need deltas;
database recreation resets I/O identities and host activity may include other work.

## Local validation boundary

Pester6.1 runs project-local fixtures with TestDrive/TestRegistry disabled.
Tests exercise real orchestration, transcripts and worker processes with **fake
external services**, including all topologies, original failure, discovery failure
and cleanup/resource rejection. Artifact tests exercise transport hashing/path
safety and the real manifest producer with synthetic compiler output.
Parser/PSScriptAnalyzer, workflow dependency/capacity/ordinary-CI equivalence and
isolated-index source-overlay checks complement those tests.

No actual compiler/NST/SQL/Docker/GitHub dispatch is run by these local tests.
Real package IDs, runtime case totals and empirical expanded results will exist
only after the parent's reviewed, authorized CI execution.

Prior empirical gate: run37758493320/SHA94989d1c43, each candidate10/10 fully
audited originals (5W1+5DE), zero relevant original failures and20 verified cleanups.
That remains qualification to begin expansion, **not expanded-cohort or statistical
stability proof**. Do not mark the investigation complete.
