# Derogatory Depreciation Mirroring Redesign - Agent Handoff

## Repository and branch

- Repository: `C:\Enlist\navagent2\App\BCApps`
- Branch: `private/algladkov/FR-Derogatory-Depreciation-redesign`
- Backup branch: `private/algladkov/FR-Accelerated-Depreciation-W1-squashed`
- OpenSpec change: `redesign-derogatory-mirroring`
- OpenSpec root: `C:\Enlist\navagent2\App\BCApps\openspec`
- Current OpenSpec progress: **41/48 tasks complete**

Run from the repository root:

```powershell
openspec instructions apply --change redesign-derogatory-mirroring --json
openspec validate redesign-derogatory-mirroring --strict --no-color
```

## Goal

Replace derogatory depreciation mirroring based on mutable journal state and heuristic reversal matching with:

- one authoritative policy/service for book resolution and eligibility;
- centralized mirroring at `FA Jnl.-Post Line`;
- explicit links from generated FA/maintenance ledger counterparts to their normal-book source;
- deterministic linked reversal and reversal-of-reversal;
- a French historical linkage upgrade;
- removal of the unshipped W1 `Is Derogatory` journal fields;
- guarded retention of pre-CLEAN30 French legacy behavior for companies where the feature is still disabled.

## Implemented W1 changes

### Schema and setup

- Added to `FA Ledger Entry`:
  - field 5866 `Derogatory Source Entry No.`;
  - field 5867 `Legacy Derogatory Ambiguous`;
  - keyed lookup by source entry and depreciation book.
- Added equivalent fields and key to `Maintenance Ledger Entry` using field numbers 5865 and 5866.
- Fixed `Depreciation Book."Derogatory Calc."` validation:
  - first assignment works;
  - duplicate relationships are rejected;
  - changing an existing relationship to an already-used normal book is rejected;
  - self-reference remains rejected;
  - runtime resolution rejects imported ambiguous setup.

### Authoritative policy

Added:

- `FixedAssets\FixedAsset\DerogatoryPostingMgt.Codeunit.al`
- `FixedAssets\FixedAsset\DerogatoryPostingRole.Enum.al`

The management codeunit owns:

- unique normal-to-derogatory book resolution;
- FA book eligibility;
- source/generated-mirror/reversal/internal roles;
- FA journal line construction for FA and general journal inputs;
- acquisition-cost adjustment eligibility, calculation, and line construction;
- FA and maintenance source-link validation.

### Centralized posting

`FA Jnl.-Post Line` now:

- captures the actual inserted source entry;
- posts an eligible tax-book counterpart after the source insert;
- stores the source entry number on the counterpart;
- uses a generated-mirror role to prevent recursion;
- works for FA and maintenance entries from both FA and general journals;
- preserves record links on the normal-book source.

Compatible `FA Insert Ledger Entry` overloads return inserted FA and maintenance entries while preserving existing callers.

### Acquisition-cost design decision

Eligibility, amount calculation, and adjustment-line construction are centralized in `Derogatory Posting Mgt.`.

Two thin execution adapters remain because a G/L-integrated adjustment must re-enter `Gen. Jnl.-Post Line` with its transaction-local posting buffers and numbering. Calling general-journal posting back from `FA Jnl.-Post Line` would create circular ownership.

Review markers:

```text
REVIEW(redesign-derogatory-mirroring)
```

exist in W1 and FR `GenJnlPostLine.Codeunit.al` and `FAJnlPostBatch.Codeunit.al`.

The OpenSpec design documents the pros and cons.

### Removed distributed W1 coordination

- Removed `Gen. Journal Line."Is Derogatory"`.
- Removed `Posted Gen. Journal Line."Is Derogatory"`.
- Removed `GetDerogatorySetup` and validation-time calls.
- Removed the purchase invoice producer call.
- Removed outer mirror construction from W1 general-journal and FA-journal batch posting.

### Deterministic reversal

- FA and maintenance counterparts are looked up by `Derogatory Source Entry No.` and expected book.
- Generated tax-book reversal entries link to the new normal-book reversal entry.
- Reversal-of-reversal preserves the link chain.
- Missing, duplicate, invalid, or already-reversed counterparts fail explicitly.
- The old amount/document heuristic is only available when `Legacy Derogatory Ambiguous` is set.

### W1 tests added/extended

- Setup tests for first assignment, relationship changes, imported ambiguity, and generated-mirror ineligibility.
- Existing derogatory posting tests now assert one explicit linked counterpart.
- W1 BaseApp and W1 Fixed Asset tests compile together.

## Implemented FR changes

### W1 behavior ported to FR overrides

FR localized copies were updated for:

- ledger link schema;
- setup validation;
- inserted-entry overloads;
- centralized forward posting;
- deterministic reversal;
- removal of the unshipped `Is Derogatory` W1 field;
- feature-enabled/CLEAN30 use of the W1 workflow.

### Feature-disabled and CLEAN30 policy

Decision: do **not** remove all French legacy paths immediately.

- Before CLEAN30, feature-disabled companies retain legacy fields/producers under `#if not CLEAN30`.
- Feature-enabled companies use the centralized W1 workflow.
- CLEAN30 builds exclude the guarded legacy implementation.
- The historical upgrade shim remains until its separate cleanup version because ambiguous upgraded entries can still need the legacy reversal fallback.

This is documented in the OpenSpec design and task 7.7.

### Historical linkage upgrade

Added:

- `src\Layers\FR\BaseApp\FixedAssets\Depreciation\UpgradeDerogatoryLinkage.Codeunit.al`
- a new per-company tag in `UpgTagAcceleratedDepr.Codeunit.al`

The upgrade:

- is idempotent through `Upgrade Tag`;
- processes non-automatic normal-book FA and maintenance entries;
- matches candidates using book relationship, asset, posting type, amount, document type/no., external document, FA/posting/document dates, transaction shape, reversal state/link shape, and entry ordering;
- links a unique candidate;
- marks only tied/ambiguous sources with `Legacy Derogatory Ambiguous`;
- records missing candidates without fabricating links;
- emits linked/ambiguous/missing telemetry counts.

### FR upgrade tests

Added:

- `src\Layers\FR\Tests\Fixed Asset\UTDerogatoryLinkageUpgrade.Codeunit.al`

Covers:

- unique FA pair;
- reversed pair;
- reversal-of-reversal shape;
- ambiguous equidistant candidates;
- missing counterpart;
- maintenance pair;
- repeated processing of an existing link.

FR BaseApp and FR Fixed Asset tests compile together in the generated FR GDL view.

## Important correctness fixes discovered during review

Two independent review passes found and led to fixes for:

1. Missing G/L balance insertion for acquisition-cost derogatory adjustments.
2. Disposal source identity not being captured for mirroring.
3. Record links being copied to the mirror instead of the source.
4. `FindLast()` selecting the newly inserted tax-book mirror instead of the normal-book primary entry for G/L balancing.
5. Reversal lookups not being restricted to the expected derogatory book.
6. Historical migration matching being too broad before transaction/date/reversal-shape filters were added.

A final code-review agent reported no remaining high-confidence correctness issues.

## Validation completed

- W1 BaseApp compile: passed.
- W1 Fixed Asset test app compile: passed.
- FR BaseApp compile: passed.
- FR Fixed Asset test app compile: passed.
- Strict OpenSpec validation: passed.
- `git diff --check`: passed.
- Generated `.docx`/`.rdlc` hardlink changes caused by GDL generation were repeatedly cleaned; verify again before committing.

## Publishing/runtime blocker

W1 BaseApp publishing through AL MCP was attempted several times:

- prebuilt package + `Synchronize`;
- explicit development-service port 7049;
- build-and-publish from the project;
- prebuilt package + `ForceSync`.

Results:

- build-and-publish timed out;
- other attempts returned generic `PublishFailed` without the server error;
- the dependent test app could not be published.

The user requested that the next agent publish W1 BaseApp first, then the user will download/set up an FR database.

Current intended AL MCP W1 configuration in `.mcp.json`:

- country `W1`;
- W1 BaseApp project;
- W1 Fixed Asset test project;
- W1 package cache and base ruleset.

The W1 packages built during this session are in:

```text
C:\Users\algladkov\.copilot\session-state\c05cdd52-50ee-44b4-9342-288f9c69cf0d\files\w1-base-build
C:\Users\algladkov\.copilot\session-state\c05cdd52-50ee-44b4-9342-288f9c69cf0d\files\w1-fixedasset-tests-build
```

The FR BaseApp package is in:

```text
C:\Users\algladkov\.copilot\session-state\c05cdd52-50ee-44b4-9342-288f9c69cf0d\files\fr-base-build
```

## Remaining OpenSpec tasks

Seven tasks remain:

1. **3.4** Tests for returned entry identity, valid link insertion, duplicate-link rejection, and invalid source/book combinations.
2. **4.6** Posting tests for purchase invoices, general journals, FA journals, maintenance, G/L integration variants, and missing asset-book eligibility.
3. **5.7** Localization regression coverage for subscribers and copied purchase buffers.
4. **6.7** Reversal tests for FA/maintenance, two-step reversal, reversal-of-reversal, duplicates, missing counterpart, and already-reversed counterpart.
5. **8.2** Validate normal, final, negative, and acquisition-cost depreciation without duplicate tax-book entries.
6. **8.4** Run focused W1/FR test suites.
7. **8.5** Inspect representative FA/maintenance ledgers, links, reversal links, book values, G/L counts, and duplicate absence.

## Recommended next steps

1. Diagnose/publish W1 BaseApp using AL MCP.
2. Publish W1 Fixed Asset test app.
3. Run focused W1 codeunits:
   - `134166` - `UT TAB FA Derogatory Depr.`
   - `134149` - `ERM Derogatory Depr. Posting`
4. Add the remaining insertion, posting-path, localization, maintenance, and reversal edge-case tests.
5. Inspect posted entries directly for one source/one mirror and linked reversal chains.
6. After the user prepares FR:
   - configure AL MCP for FR BaseApp + FR Fixed Asset tests;
   - publish;
   - run `134167` - `UT Derogatory Linkage Upg.`;
   - inspect upgrade telemetry and linked/ambiguous/missing data.
7. Re-run all four project compiles and strict OpenSpec validation.
8. Mark remaining tasks complete only after runtime verification.

## Worktree cautions

Do not revert unrelated user changes:

- `src\Layers\ES\BaseApp\Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al`
- `src\Layers\W1\.view\layered_view_files.json`
- repository `.github\lsp.json`

The W1 BaseApp `.github` skills/prompts were restored from a nested backup. There are 25 skills. The AL template was intentionally renamed so the compiler ignores it:

```text
src\Layers\W1\BaseApp\.github\skills\ventselartur-bc-delocalize\references\baseapp-feature-key-template.al_
```

Do not rename it back to `.al`.

Before committing, check for regenerated report layouts:

```powershell
git --no-pager diff --name-only | Where-Object { $_ -match '\.(docx|rdlc)$' }
```

Those are GDL hardlink side effects and should not be included.
