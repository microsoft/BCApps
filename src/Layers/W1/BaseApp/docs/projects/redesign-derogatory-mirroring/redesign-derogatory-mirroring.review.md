---
prd: C:\Enlist\navagent2\App\BCApps\src\Layers\W1\BaseApp\docs\projects\redesign-derogatory-mirroring\redesign-derogatory-mirroring.prd.md
scope: EPIC-009 — commits a2a1932c, b24d5295, 45e9e12c, 13fe1591 (branch private/algladkov/FR-Derogatory-Depreciation-redesign)
date_reviewed: 2026-08-14
reviewer: GitHub Copilot (independent code-review agent)
epic: EPIC-009
code_review_verdict: PASS
compliance_status: PARTIALLY_COMPLIANT
completion_note: Code changes complete and PASS; ITEM-022 and the local (W1/ES) portion of ITEM-024 are green; ITEM-023/027/028 and the non-supported-country portion of ITEM-024 are blocked by external CICD infrastructure/permissions.
---

# EPIC-009 Implementation Review Report

## Executive Summary

EPIC-009 ("Complete semantic, build, and runtime release gates") was resumed after a forced Windows/VS Code restart. The reviewed code changes across four commits are **correct and surgically scoped** — the independent code-review verdict is **PASS** with no substantive findings.

- The relationship-resolution semantic gate (**ITEM-022**) is complete: an AL semantic sweep across all 14 layers found zero dual-producer paths and zero unmarked heuristic reversal callers.
- The locally reachable build/runtime gate (**ITEM-024**, W1/ES supported environments) is green via AL MCP on service `Navision_navagent2`: W1 codeunit 134166 (28/28) and 134149 (50/50) pass, and the interrupted `Depreciation Book` fix is proven test-first (RED 1P/2F pre-fix -> GREEN 28/28 post-fix).
- The multi-country CICD gate (**ITEM-023 / ITEM-027 / ITEM-028**, plus the non-supported-country portion of ITEM-024) is a **CONCRETE EXTERNAL BLOCKER**: workflow dispatch is denied (`HTTP 403: Must have admin rights to Repository`) and the `private/*` CI runs lack required organization secrets (`licenseFileUrl`, `gitSubmodulesToken`, `AZURE_CREDENTIALS`, code-signing). The prior gate run 31718032964 failed with `Run-AlPipeline` "There are test failures!" uniformly across every country and every test bucket — the signature of a missing-license container run, not of the derogatory code. Per the available-environment constraint (W1/ES/FR/NL only), non-supported countries were not built locally.

The epic is therefore **code-complete and correct** but **cannot be closed green** from this environment because of the CICD infrastructure/permission limitations, which are outside EPIC-009's code scope.

## Scope of Review

**Changes Reviewed** (branch `private/algladkov/FR-Derogatory-Depreciation-redesign`):

| Commit | Subject | Files |
|---|---|---|
| `13fe1591` | EPIC-009: Guard derogatory-calc validation before code assignment | `DepreciationBook.Table.al`, `UTTABFADerogatoryDepr.Codeunit.al`, PRD |
| `45e9e12c` | EPIC-009: Enable CLEAN29 gate for private branches | `build/projects/Apps FR/.AL-Go/settings.json` |
| `b24d5295` | EPIC-009: Fix localization release gate failures | FI `FALedgerEntry.Table.al`, IT `FAJnlPostBatch.Codeunit.al` |
| `a2a1932c` | EPIC-009: Restore IT derogatory compatibility delegate | IT `FAJnlPostBatch.Codeunit.al`, IT `ERMFixedAssetsGLJournal.Codeunit.al` |

Authoritative source under `src/Layers/**` was reviewed; generated `src/Views/**` was ignored (CON-001).

## Findings — Code Review: PASS (no substantive findings)

### 1. DepreciationBook `"Derogatory Calc."` guard — PASS (FR-001/AC-001)
`DepreciationBook.Table.al:403-408`. Wrapping only the `Text10800` uniqueness block in `if Code <> ''` is safe and complete:
- With `Code = ''` the `SetRange("Derogatory Calc.", '')` matched every book with an empty derogatory calculation — a pure false positive (the fixed bug). The skipped check is provably vacuous for a not-yet-inserted record.
- A new record can never be inserted onto a code that is already a derogatory target (duplicate-PK insert fails), so no real chain/duplicate can hide.
- The reverse direction stays enforced: once the record has a real code and another book points at it, that book's own OnValidate runs `Text10804`. On any later modify, `Code` is non-blank so `Text10800` runs again.
- The three sibling error paths are outside the guarded block and unaffected: `Text10801` (self), `Text10802` (duplicate target), `Text10804` (target-is-derog).

### 2. Regression test — PASS
`UTTABFADerogatoryDepr.Codeunit.al` `OnValidateDerogatoryCalcBeforeCodeAssignmentSucceeds` faithfully reproduces `Init()` -> `Validate("Derogatory Calc.", NormalBook.Code)` with `Code=''` -> assign `Code` -> `Insert()` -> `TestField`. Verified RED before the fix (server run: 1 passed / 2 failed with the spurious accounting-book error) and GREEN after (134166 28/28). Legitimate red-before/green-after regression.

### 3. Surgical scope — PASS
The four commits touch exactly seven files; every changed line traces to EPIC-009. No formatting churn or accidental edits. The PRD NL test-ID line (`134160`->`144149`, EPIC-006 section) re-syncs the doc with the codeunit ID actually shipped in commit `35fab3afc6`, which fixed a real collision with W1 `codeunit 134160 "Payments using Creditor Number"`; it is relevant EPIC-009 NL localization-gate evidence, not scope creep.

### 4. FI `FA Ledger Entry` FR-003 parity — PASS (no collision)
Fields `5866 "Derogatory Source Entry No." (Integer)` and `5867 "Legacy Derogatory Ambiguous" (Boolean)` are byte-identical to the W1 definitions; the key-name difference (FI `Key14`) is irrelevant because `SetCurrentKey` binds by field list, not key name. FI has no `FA Insert Ledger Entry`/`Maintenance Ledger Entry` override, so it inherits the W1 consumer that reads both fields — adding both to FI's override is exactly what parity requires.

### 5. IT `MakeDerogatoryFAJnlLine` delegate + event — PASS (FR-021/PAT-001)
The IT delegate is identical to W1's: `NewFAJnlLine.Copy(...)` then `exit(DerogatoryPostingMgt.MakeDerogatoryJournalLine(NewFAJnlLine, FAJournalLine, Enum::"Derogatory Posting Role"::Source))`. The restored `OnPostLinesOnAfterFAJnlPostLine` call resolves to a declared `[IntegrationEvent(false,false)]` publisher; IT codeunit 5633 fully replaces W1's, so there is no double-firing.

## Requirement / Acceptance-Criteria traceability (EPIC-009)

| Item / AC | Status | Evidence |
|---|---|---|
| ITEM-022 (NFR-002/NFR-008, AC-013/AC-023) | DONE | 14-layer sweep: zero dual-producer paths, zero unmarked heuristic callers; single producer at `FA Jnl.-Post Line`/`Derogatory Posting Mgt.`; FR/RU link-key-first reversal; FR legacy path gated by `#if not CLEAN29` + `AcceleratedDeprFeature.IsEnabled()`. |
| ITEM-024 (NFR-005/NFR-006, AC-025/AC-026) local | DONE (W1/ES) | W1 compile 0 diagnostics; 134166 28/28; 134149 50/50; ES composes W1 change with no derogatory/`DepreciationBook` diagnostics. |
| ITEM-024 non-supported countries | Blocked | External CICD only; not buildable locally per constraint. |
| ITEM-023 / ITEM-027 / ITEM-028 (NFR-005/NFR-008, AC-025) | Blocked (external) | Dispatch `HTTP 403` (no admin); private-branch missing org secrets; run 31718032964 fails on missing license, not code. |

## Verdict

- **Code review: PASS** — the EPIC-009 changes are correct, complete for what they claim, and surgically scoped to EPIC-009. No remediation required.
- **Epic status: PARTIALLY_COMPLIANT** — ITEM-022 and the local (W1/ES) portion of ITEM-024 are green and verified; ITEM-023/027/028 and the non-supported-country portion of ITEM-024 are blocked by external CICD infrastructure (missing `private/*` organization secrets) and permissions (no workflow-dispatch admin right), which are outside EPIC-009's code scope. No derogatory code defect blocks the gate.
