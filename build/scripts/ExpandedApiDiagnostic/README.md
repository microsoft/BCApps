# DRAFT expanded API preparation — DO NOT MERGE

AB#653393 · AB#646383

**Blocked preparation, not an executable comparison. Do not dispatch this draft.**
The opt-in workflow writes its complete scope and then deliberately fails. It has
no build, provisioning or test jobs. A green contract suite is not runtime proof.
The shared build stage and all-lane runtime producer remain unimplemented. Parent
review and capacity/new-binary coordination are required before further work.

## Evidence and source ancestry

Both candidates passed the empirical pilot gate in original run `37758493320`,
SHA `94989d1c434f264f688748143eadc915a7b2a706`: each has 5 W1 + 5 DE fully
audited originals, zero relevant original failures; all 20 cleanups were verified.
This is an exploratory qualification, **not statistical stability proof**.

The supplied main snapshot `ad9b529a78c818ba25c24aecd093442a6c7a3852` precedes
the externally owned revert. Git ancestry proves it is an ancestor of
`97c2f034e7a32eb3bbb7efb1a1e893ea06ac121b` (with `f18567dc08` between them).
The new isolated branch starts at the latter. PR12514 is not changed, blocked or
merged by this draft; its merge remains an ancestor.

`source-overlay.patch` independently reapplies the reviewed source fixes only
inside a future dedicated manual build checkout. It changes **no ordinary source
files, settings, disabled-test manifests or existing workflows on push**.
`source-overlay.json` seals its hash, 178 paths, source subtree and 11 exact
reviewed commits. The full stack ref remains unchanged at
`f6c91f21b7fac7942c9d2dcd589a33c1b1b604c7`.

The overlay includes Expense enablement/consolidated regressions, general API
authentication enablement (including layer/IRS tests), VAT fixtures, cancellation
reason fixtures, localized payment discounts/document comparisons, quote dates,
vendor-payment number series, posted return-shipment report selection and APIV1
fixture/verification fixes. It does **not** bring back Expense-first sequencing
disables. Only disabled-test keys removed by the reviewed enablement commits are
removed; unrelated existing entries are retained:

| Manifest | Before | Reviewed removals | Retained |
| --- | ---: | ---: | ---: |
| Expense Agent | 60 | 51 | 9 |
| E-Document Core | 151 | 1 | 150 |
| APIV1 | 291 | 291 | 0 |
| APIV2 | 717 | 716 | 1 |

These are manifest entries, not executed skip counts. No new disabled tests,
retry, warmup, companies probe or failure tolerance is added.
`StageSource.ps1` is manual-identity-gated, verifies ancestry/base-source/hash,
requires a clean checkout, applies the patch with an index check, and verifies the
resulting `src` subtree. It fails on drift rather than resolving conflicts.
Local composition used an isolated index; the overlay has **not been compiled**.
One scoped integration adjustment preserves main's `29212ba86b` Company Info
description-restoration fix while removing the duplicate `RequiredTestIsolation`
property introduced by applying general API enablement on top of it. All 167
inventory routes retain their test-type/isolation properties and test-procedure
sequences; the other 166 route files are byte-identical to the reviewed stack.
This is a targeted integration check, not a replacement runtime inventory.

## Bounded initial coverage

Use the original reviewed static inventory unchanged: 167 source-CU variants,
15 apps, five lanes, zero unrouted entries. `Get-ExpandedApiPlan` uses the exact
country source-overlay selection and package membership, not `supportedCountries`
alone (which may be `All`). Never interpret declarations as runtime case counts.

| Scope | Cells | Coverage in each cell |
| --- | ---: | --- |
| W1 + DE | 6 | 159 selected CU variants, all five lanes |
| CA + US supplement | 6 | IRS Forms Tests CU148018, Uncategorized only |

Each country compares `m1w1` (default), `m2w2` (default + tenant2), and `m4w3`
(four mounts; only tenant2/3/4 are workers). The latter must use the **same new
protected-default-template design**, not the historical four-mount producer.
There is one original per configuration/country, no repetition or replacement.

Primary lane counts per country: Default 51, Integration 33, Uncategorized 66,
Legacy bucket1 5, Legacy bucket2 4. APIV1/APIV2 span all three typed modes.
The seven unselected variants are APAC General Journal + Prepayment, CH/CZ/ES/IT
General Journal, and NA Prepayment. AU/NZ/CH/CZ/ES/IT/MX are not tested by this
plan; CA/US coverage is IRS-only, not complete CA/US or NA-layer coverage.
The plan exports exact uncovered paths. No all-country or full-167-runtime claim.

## Precise producer blockers requiring parent review

The qualified source is **not safe to broaden by replacing its 21-ID list**:

1. `ParallelTestExecution.psm1:Get-RequiredDisabledWorkItems` filters
   `requiredTestIsolation=Disabled`; Legacy returns an empty array. Of the 167
   source variants, 44 have unspecified required isolation. The successor needs
   explicit inventory-CU discovery for every lane and must preserve compiled
   normal/disabled runner semantics. Selecting only Disabled silently drops
   coverage; forcing all 44 through runner130451 changes semantics without proof.
2. `Get-CachedTestRunResult` keys only on container; the pilot finalizer expects
   21 suites/253 cases/19 skips and a single Integration template. Reusing that
   cache or template across lanes can silently skip tests or use the wrong data.
   A material lifecycle choice remains: distinct owned containers per lane
   (recommended, sequential within each cell), versus a demonstrated full lane
   reinitialization protocol. This draft does not invent one.
3. The matched four-mount baseline must protect its detached template before
   discovery just like both candidates, restore the discovery tenant in finally,
   and allow only its declared worker set for subsequent resets. Existing
   tenant-count reset guards whitelist only default/tenant2, while the historical
   four-mount path freezes its template after secondary discovery. Neither
   existing path is a matched baseline without new code and focused tests.
4. The new source must actually compile before any expanded runtime claims.
   Shared compilation and new artifact sealing are not wired in this draft.
   Old PR2 packages and the 253-case snapshots are explicitly rejected by the
   consumer contract. This cannot be fixed by relabeling those artifacts.

## Required next implementation contract

One separate workflow group `sql-api-653393-expanded-api-diagnostic`, cancellation
disabled, at most **two concurrent allocations**, independent of all three
existing experiment paths. The parent reserves capacity. Builds finish before
trials, with compile/build and runtime allocations included in the ceiling.

Shared build: W1/DE/CA/US compile once from the exact overlay, including BaseApp,
test libraries, all application/test dependencies and country materializations.
Pin AL-Go `91b96c2b294be6f823277dafe6f03350abfb9d23`, BCH
`6.1.19-preview2811389`, application `30.0.55683.0`, platform **30.0.55665.0**,
and image `sha256:c899d12093ad7bbdbfd08ccc0e6294e0f98c682c7e35db4ecfbca345fb068492`.
Do not inherit main's newer/floating defaults. Platform47167 uptake belongs to a
separate monitor; the fixed30.x build is unpublished and is not adopted here.

After upload, seal actual Apps/TestApps artifact IDs, service archive SHA256,
run/attempt/head/source-tree/overlay hash, compiler/settings provenance, and
per-`.app` path/size/SHA256/app-id/version/dependencies. Verify download transport
and package hashes before install. All three country configurations consume
the **same exact sealed artifact IDs and package bytes**. No name-only lookup,
baseline fallback, incremental old packages or per-configuration recompilation.
Record actual installed runner/test-framework packages and the running NST binary
version (not just the requested artifact URL), shell, Docker limits and image.

Each lane retains its existing settings: Unit/Empty Company;
Integration/My Company; Uncategorized/CRONUS with scheduler enabled;
Legacy/CRONUS, with bucket1 Standard/Evaluation demo data. Freeze a detached
read-only template only after the lane's complete setup and before discovery.
Never use an Integration template as evidence for another lane.

Mandatory runtime inventory: country, lane, app id/name/version, CU id/name,
method, compiled selector/isolation, normal/disabled runner, intentional skip
state/reason and the exact installed package hash. Compare exact discovered
identities/skip states against results and across all three configurations,
including the static expected app/CU routing. Record unsupported cases explicitly.
Missing, duplicate, truncated or newly skipped cases must fail closed.

Persist first-attempt raw failures **before** classification or aggregation.
Preserve worker logs, original XML, NST event logs, reset mappings/template GUID,
resource samples and ownership receipts. No retries or failure tolerance.
Use finally/always for ownership-scoped cleanup and artifact export; runner loss
without cleanup proof is invalid, never success. The consumer functions validate
contract shapes and exact identities; they do not replace raw-evidence auditing.

Timing starts on the assigned runner before checkout and ends after owned cleanup.
Queue/upload are excluded, with GitHub job timestamps reported separately.
Record setup, template creation, discovery, discovery-reset, per-CU resets,
dispatch/collection/test execution, cleanup and whole-cell intervals using
monotonic ticks. Define discovery/reset as nested within lane execution, and
per-CU concurrent times as **summed work**, not additive wall time. Report reset
union/wall and sum separately. XML case time is AL duration, not HTTP latency.
Use identical host/NST/SQL CPU, memory, waits and I/O sampling in all arms;
missing resource evidence fails qualification rather than becoming zero.

## Local validation and limitations

Pester6.1 contract tests use project-local fixtures with TestDrive/TestRegistry
disabled. Parser, PSScriptAnalyzer and isolated-index patch checks are appropriate.
No local AL compile, publish, NST test, dispatch, push, PR or CI start is performed.
The only new workflow is fail-closed preparation; it deliberately cannot produce a
green expanded diagnostic run. **Do not mark the investigation complete.**
