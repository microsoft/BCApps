# Diagnostic only — do not merge

One manually dispatched paired W1 Integration pilot on top of PR #11860,
`c4953dceffe02a017adad34973e1955017bf5d20`. Related context: AB#646383;
this experiment does **not** resolve that work item and is outside the native
merge group. No auto-merge, queue entry, automatic rerun or main-branch change.

The branch-only `CICD.yaml` replaces the normal CI matrix with two fresh
`GitHub-BCAppsPL` containers, capped at **120 minutes per arm** (240 runner-minutes).
PR project discovery is disabled for this experiment branch to avoid a full-country
build. Dispatch the existing registered `CICD.yaml` with this branch as its ref.
Do not dispatch a second pair without new authorization.

## Authorized preparation correction

The initial pair, run `37493608127`, never created a container or ran AL tests.
It incorrectly selected Windows PowerShell 5.1 while original W1 job
`112207627851` used `pwsh` 7. `Get-PlatformVersions` therefore failed parsing an
HTTP response because the Internet Explorer engine was unavailable. This is an
experiment preparation/configuration bug, **not a network failure or SQL result**.
The failed pair remains inconclusive and its logs/artifacts are retained.

One replacement pair is explicitly authorized after correcting the job shell
**and all AL-Go composite action shell inputs** to `pwsh`. `Invoke-AlGoAction`
invokes its supplied scriptblock in that shell; it does not select the shell.
A preflight records and requires PowerShell 7 before package preparation.
Checkout includes the unchanged PR2 ancestor through the two diagnostic commits.
No PlatformHelper, vendor action, parsing workaround or shell policy is changed.

The failed preparation consumed 13m16s (control) plus 14m23s (fresh), totaling
27m39s of runner time. The replacement remains capped at 120 minutes per arm
(240 additional runner-minutes; 267m39s cumulative worst-case including the failed
preparation). Record actual old/new preparation time separately. No further
dispatch or failed-job rerun is authorized after the replacement.

Both arms use the exact same PR2 app/test archive IDs and SHA256 digests,
BCH `6.1.19-preview2811389`, NST `30.0.55665.0`, W1 application artifact
`30.0.55683.0`, image digest, original license provisioning, auth files,
test assertions and three-worker scheduling. No AL source is changed or compiled
against a moving head. The image digest resolves the original generic
`1.0.2.128` LTSC2025-dev image; the historic log did not record its digest.
The pilot records the runner OS; compare both manifests before interpretation.

The original discovery runs unchanged. Its ordered clean-test prefix must match
the 21 codeunits captured in W1 job 112207627851, run 37372848860. Seven batches
end with Expense Users, Capabilities and Activity Log. No ordinary-test phase,
HTTP warmup, auth mutation, extra sleep, force-refresh or pool clearing is added.
The existing mount-state polling remains. Copy failures and test failures are
terminal; baseline copy/transient retries are deliberately disabled in both arms.
A failed batch drains its three workers and prevents later batches.

Control restores worker databases under `tenant2/3/4`. Treatment preserves those
logical IDs/URLs, but uses `tenantN_rRUN_gGENERATION` database names. Both arms
read the same SQL identity fields before and after reset. This administrative
probe has a possible timing effect and does not reveal the NST internal pool
generation. A fresh SQL name does not guarantee a fresh database ID or GUID.

Deletion is allowed only for a tracked worker's previously mounted local database,
after dismount. A stale/foreign mapping or pre-existing fresh target fails closed.
The caller's tenant objects are updated after each successful mount, including
the discovery restore. Default/application/template databases are not deleted by
the pilot. The immutable template is retained until whole-container teardown.
The ordinary disposable pipeline teardown plus the final ownership-checked
fallback clean up the complete container, including partial failed copies.
Runner loss/hard cancellation may prevent exports/finally; that is inconclusive.

Artifacts contain package hashes, effective identities, ordered worklist,
reset UTC/SQL identity timeline, worker output, JUnit and raw EVTX.
No credentials, access keys or authorization headers are added to diagnostics.
Missing artifacts, setup drift, timeout or no reproduction mean **inconclusive**.
Control-only reproduction is a name-reuse signal, not proof of a production fix.

Local validation (Pester 5, no NST required):
`Invoke-Pester .\build\scripts\SqlResetPilot`
