---
prd: C:\Enlist\navagent2\App\BCApps\src\Layers\W1\BaseApp\docs\projects\redesign-derogatory-mirroring\redesign-derogatory-mirroring.prd.md
scope: 0b1f8578b7^..0b1f8578b7 (9192474e01643a6efdf858d2c82d91b7eb5dbc01..0b1f8578b7398dc2925c3124b4506b08879f49db)
date_reviewed: 2026-08-18
reviewer: GitHub Copilot
compliance_status: PARTIALLY_COMPLIANT
completion_percentage: 73%
---

# PRD Implementation Review Report

## Workflow Todos

| Todo | Status | Completion evidence |
|---|---|---|
| Parse the complete PRD | ✅ COMPLETE | Read all 491 lines and inventoried 177 unique prefixed references: 22 FR, 8 NFR, 13 FM, 28 AC references, 11 RD, 2 CON, 1 GUD, 1 PAT, 9 EPIC, 28 ITEM, 29 FILE, 8 RISK, 3 ASSUMPTION, 7 DEP, and 7 TEST; no REQ/SEC IDs exist. |
| Analyze the exact committed scope | ✅ COMPLETE | Reviewed only `0b1f8578b7^..0b1f8578b7`; confirmed two modified files and 26 insertions/7 deletions. Unrelated workspace changes were excluded. |
| Deep implementation review | ✅ COMPLETE | Independent SddCoder sub-agent used code intelligence/code search to trace every changed region and impacted reversal behavior, architecture, and scope containment. |
| Requirements and quality validation | ✅ COMPLETE | Independent SddCoder sub-agent used code intelligence/code search to assess all requirement, task, quality, security, deployment, and success-criteria entries. |
| Preserve existing report work | ✅ COMPLETE | Inspected the pre-existing uncommitted report and its git diff first; retained its useful all-PRD matrices and updated them for the new exact range. |
| Generate the validation report | ✅ COMPLETE | Merged the new scope, live CI evidence, agent findings, and independently verified pre-existing gaps into this mandatory-template report. |
| Final verification | ✅ COMPLETE | Rechecked counts, weighted percentages, verdict, scope hashes, date, paths, changed-line traceability, report diff, and worktree preservation. |

## Executive Summary

**Verdict: PARTIALLY_COMPLIANT (73% weighted completion); not ready to merge as a completed PRD.**

The scoped commit itself is narrow, fully traced, and statically sound:

- `ReverseDerogEntryInitAcqCostBody` at `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al:876-887` restores reversal of the independent normal-book `Derogatory` source that parent commit `9192474e01` had removed, and now asserts that its persisted-link counterpart is automatically reversed and linked to the new normal reversal.
- The PRD changes at lines 5 and 436-477 record local W1 evidence and explicitly qualify localization CI as pending rather than green.
- `git diff --check 0b1f8578b7^ 0b1f8578b7` passes. No production AL, schema, API, generated `src/Views/**`, build, or deployment file changed. Both changed files are justified and every changed line is traced.

Overall PRD compliance remains incomplete for substantive reasons that predate and are not fixed by this test/documentation commit:

1. **FR-004/ITEM-002/RD-001:** at least 20 active calculation/report relationship filters remain outside `Derogatory Posting Mgt.`, including `W1/.../CalculateDepreciation.Report.al:413` and `CalculateNormalDepreciation.Codeunit.al:597`.
2. **FR-017/ITEM-016/AC-017:** French historical matching checks only zero/nonzero reversal shape, not counterpart-consistent reversal chains (`UpgradeDerogatoryLinkage.Codeunit.al:323-334,458-469`).
3. **NFR-003/ITEM-025:** the corrective tag is set after the atomic `Codeunit.Run` transaction, not within it (`UpgradeDerogatoryLinkage.Codeunit.al:92-109`; `DerogLinkageCorrectiveRun.Codeunit.al:18-24`).
4. **NFR-005/NFR-006/ITEM-023/024/027/028:** current-SHA run `32131321496` targets `0b1f8578b7` but was still in progress at final capture and already contained failed ES IntegrationTests and NZ LegacyTestsBucket2 jobs; it is not a green release gate. The PRD-cited parent-SHA run `32129755257` completed cancelled.
5. An equivalent legacy relationship-validation defect remains in the IS full-copy table at `src/Layers/IS/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al:380-409`.

Scoped-commit containment is **PASS**: the AL test is FILE-020, the PRD is a justified update to the authoritative planning artifact, and there are no untraced, deleted, production, or drive-by changes. The broader implementation and release-readiness verdict remains partial.

## Scope of Review

**PRD Document**: `C:\Enlist\navagent2\App\BCApps\src\Layers\W1\BaseApp\docs\projects\redesign-derogatory-mirroring\redesign-derogatory-mirroring.prd.md`

**Changes Reviewed**: exact committed range `0b1f8578b7^..0b1f8578b7`; unrelated uncommitted files were excluded

**Parent**: `9192474e01643a6efdf858d2c82d91b7eb5dbc01`

**Commit**: `0b1f8578b7398dc2925c3124b4506b08879f49db`

**Total Files Modified**: 2

**Diff Size**: 26 insertions, 7 deletions

**Review Date**: 2026-08-18

### Exact Modified Files and Changed Regions

| File | Change | Exact changed regions | Trace |
|---|---:|---|---|
| `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al` | +12/-0 | `876-887`: reverse the independent normal-book `Derogatory` source; resolve both counterpart and counterpart reversal by persisted links; assert reversal-chain identity | FR-009/014/015, AC-009/014, TEST-002/003, EPIC-002/008/009, ITEM-008/020/024, FILE-020 |
| `src/Layers/W1/BaseApp/docs/projects/redesign-derogatory-mirroring/redesign-derogatory-mirroring.prd.md` | +14/-7 | `5`, `436`, `440-448`, `456`, `469-477`: update date/statuses, record local W1 gate, qualify pending localization CI, and add change-log evidence | Goal 5, NFR-005/006/008, AC-025/026, EPIC-009, ITEM-022/023/024/027/028, TEST-006/007, deployment gates |

### Corrective Logic Assessment

| Correction | Result | Evidence |
|---|---|---|
| Independent-source reversal regression | ✅ CORRECT STATICALLY | The added block mirrors the immediately preceding depreciation reversal, uses `FindLinkedFAEntry` to require exactly one linked counterpart, and proves the counterpart reversal links to the new normal reversal. |
| Change lineage | ✅ VERIFIED | Parent `9192474e01` removed the independent `Derogatory` reversal while changing the depreciation assertion. This commit restores that step and strengthens it; product link-first reversal behavior, keys, helpers, and variables all predate the scoped commit. |
| Local W1 execution | ✅ RECORDED, NOT RE-RUN BY REVIEW | PRD lines 469-472 record first-run 48/50, targeted 3/3, then codeunits 134149/134150/134166 at 50/50, 9/9, and 29/29. The arithmetic is consistent; this review does not fabricate an independent runtime result. |
| Current-SHA CI | ⚠️ NON-GREEN/IN PROGRESS | Run `32131321496` targets exact SHA `0b1f8578b7`; at final evidence capture it had 26 successful jobs, failed ES IntegrationTests and NZ LegacyTestsBucket2 jobs, and 111 jobs in progress. |
| Equivalent localization coverage | ❌ INCOMPLETE (PRE-EXISTING) | IS retains the pre-fix validation at `IS/.../DepreciationBook.Table.al:380-409`; its composed W1 test project can exercise the same inherited regression. |

## Requirements Compliance

The PRD contains FR/NFR identifiers rather than `REQ-*`; no `REQ-*` or `SEC-*` identifiers are present. Security prose is assessed separately.

### Functional Requirements

| Requirement | Status | Implementation | Notes |
|---|---|---|---|
| FR-001 | ✅ PASS | W1 `DepreciationBook.Table.al:370-415`; RU `:378-422`; tests `UTTABFADerogatoryDepr.Codeunit.al:21-70` | Corrective RU fix is sound. IS full copy remains inconsistent. |
| FR-002 | ✅ PASS | `DerogatoryPostingMgt.Codeunit.al:17-29`; ambiguity test `UTTAB...:74-96` | Runtime manager rejects a second match. |
| FR-003 | ✅ PASS | FA fields/key `FALedgerEntry.Table.al:506-520,573`; maintenance `MaintenanceLedgerEntry.Table.al:383-395,430` | W1/FR/FI/RU schema evidence exists. |
| FR-004 | ❌ FAIL | Manager policy exists at `DerogatoryPostingMgt.Codeunit.al:17-238` | Strict sole-authority rule is violated by at least 20 active calculation/report direct filters, including W1 `CalculateDepreciation.Report.al:413` and `CalculateNormalDepreciation.Codeunit.al:597`. |
| FR-005 | ✅ PASS | `FAJnlPostLine.Codeunit.al:82-107,147-160`; containment test at `ERMDerogatory...:1087` | Generated mirrors clear controls and skip both duplicate dispatchers. |
| FR-006 | ✅ PASS | Shared boundary `FAJnlPostLine.Codeunit.al:76-128,133-192` | Raw insertion does not initiate forward mirroring. |
| FR-007 | ✅ PASS | Link posting `FAJnlPostLine.Codeunit.al:239-246,280-306`; validation `DerogatoryPostingMgt.Codeunit.al:198-238` | Exact total/link assertions exist. |
| FR-008 | ✅ PASS | Delegating overloads `FAInsertLedgerEntry.Codeunit.al:79-86,179-186` | Returning identities are tested. |
| FR-009 | ✅ PASS | Automatic/salvage capture `FAJnlPostLine.Codeunit.al:450-580`; reversal `FAInsertLedgerEntry.Codeunit.al:741-786` | Source/test evidence is strong. |
| FR-010 | ✅ PASS | Automatic-only continuation `FAJnlPostLine.Codeunit.al:298-328` | Covered by W1 posting tests. |
| FR-011 | ✅ PASS | Manager calculations `DerogatoryPostingMgt.Codeunit.al:112-196`; thin adapters in W1 posting code | Acquisition amount/line ownership is centralized. |
| FR-012 | ⚠️ PARTIAL | Calculation and amount tests in `ERMDerogatory...:390-681` | Direct relationship filtering bypasses FR-004 and complete localization runtime parity is absent. |
| FR-013 | ⚠️ PARTIAL | Static sweep found 0/9 active localization posting codeunits still using `"Is Derogatory"` | Current multi-country runtime evidence is absent. |
| FR-014 | ✅ PASS | Link-first reversal `FAInsertLedgerEntry.Codeunit.al:789-876`; setup-change tests `ERMDerogatory...:1295,1331`; scoped assertion `:876-887` | The commit restores the second independent reversal and verifies its persisted-link counterpart chain. |
| FR-015 | ✅ PASS | Missing/multiple/reversal-of-reversal tests `ERMDerogatory...:1365-1555,1795-1840` | Explicit consistency paths exist. |
| FR-016 | ✅ PASS | Transfer sequencing `AcceleratedDeprFeature.Codeunit.al:120-139`; `UpgradeAcceleratedDepr.Codeunit.al:35-52` | Original linkage tag follows telemetry/writes. |
| FR-017 | ❌ FAIL | Candidate graph exists in `UpgradeDerogatoryLinkage.Codeunit.al` | `SetFAReversalShapeFilters:323-334` and maintenance equivalent `:458-469` compare only zero/nonzero shape, not actual counterpart chains. |
| FR-018 | ✅ PASS | Existing-link skip `UpgradeDerogatoryLinkage.Codeunit.al:267-273,416-422`; retry tests exist | Partial/repeated pass behavior is covered in source. |
| FR-019 | ✅ PASS | Marker-gated fallback `FAInsertLedgerEntry.Codeunit.al:789-900` | New W1 entries do not use heuristic fallback. |
| FR-020 | ⚠️ PARTIAL | FR guards/routing in `FR/.../FAJnlPostBatch.Codeunit.al:273-345,405-424` and `FAJnlPostLine.Codeunit.al:299-343` | No current-SHA CLEAN30 package/run evidence. |
| FR-021 | ⚠️ PARTIAL | W1 builder and FR reversal overloads restored | Full current dependent-app compilation is unverified. |
| FR-022 | ✅ PASS | Six telemetry dimensions at `UpgradeDerogatoryLinkage.Codeunit.al:178-191`; direct test `UTDerogatoryLinkageUpg.Codeunit.al:1633-1642` | Aggregate-only telemetry; no counter table. |

**FR score**: 16 pass, 4 partial, 2 fail; weighted completion **81.8%**.

### Non-Functional Requirements

| Requirement | Status | Evidence / gap |
|---|---|---|
| NFR-001 | ⚠️ PARTIAL | W1 posting-path matrix exists, but zero variance across every localization was not run at current SHA. |
| NFR-002 | ⚠️ PARTIAL | Reversal selects the dedicated key at `FAInsertLedgerEntry.Codeunit.al:799,843`; no representative timing evidence and insertion validation does not explicitly select it. |
| NFR-003 | ⚠️ PARTIAL | Amount/idempotency tests exist, but corrective tag assignment occurs after the atomic wrapper transaction. |
| NFR-004 | ⚠️ PARTIAL | Strong total-row verifier at `ERMDerogatoryDeprPosting.Codeunit.al:2867-2890`; localization/event matrix execution remains incomplete. |
| NFR-005 | ⚠️ PARTIAL | The PRD records current W1 compile/build and earlier successful W1/FR/CLEAN30/localization builds; exact-SHA CI run `32131321496` is not complete/green and therefore does not establish every required build. |
| NFR-006 | ⚠️ PARTIAL | Current-SHA local W1 88/88 is recorded, but no complete current-SHA localization run plus durable representative ledger/G/L inspection exists. |
| NFR-007 | ⚠️ PARTIAL | Manager exposes no mutable event and validation is immediately before insert; only one of five named event surfaces has focused subscriber regression coverage. |
| NFR-008 | ⚠️ PARTIAL | Static localization sweep is positive; required current runtime evidence is incomplete. |

**NFR score**: 8 partial; weighted completion **50.0%**.

### Security Requirements

No numbered `SEC-*` requirements exist.

| Security consideration | Status | Evidence / gap |
|---|---|---|
| Aggregate-only telemetry | ✅ PASS | `UpgradeDerogatoryLinkage.Codeunit.al:178-191` emits counts only. |
| Input/link validation | ⚠️ PARTIAL | New links validate existence/identity/duplicates; historical reversal-chain matching is shape-only. |
| Existing access boundaries | ✅ PASS STATICALLY | No new public entry point or permission set was introduced by the reviewed commit. |
| Secrets | ✅ PASS | No credentials, tokens, or connection strings were added. |

### Constraints & Guidelines

| Identifier | Status | Evidence / notes |
|---|---|---|
| CON-001 | ✅ PASS | The scoped commit changes authoritative `src/Layers/**`, not generated `src/Views/**`. |
| CON-002 | ⚠️ PARTIAL | The scoped commit changes no product amounts/formulas/accounts; complete current accounting runtime proof remains open. |
| GUD-001 | ✅ PASS | Stable objects/procedures/fields are used; some narrative line references have drifted. |
| PAT-001 | ✅ PASS | Public insertion/reversal procedures delegate to context-aware/returning overloads. |

## Acceptance Criteria

| Criterion | Status | Verification result |
|---|---|---|
| AC-001 | ✅ PASS | W1/RU setup validation and tests exist; IS parity gap remains outside the listed layers. |
| AC-002 | ✅ PASS | Ambiguous runtime setup errors through the manager. |
| AC-003 | ✅ PASS | W1/FR fields and link keys are present. |
| AC-004 | ✅ PASS | Eligibility and link-integrity errors are implemented/tested. |
| AC-005 | ✅ PASS | Generated-mirror recursion/duplication/insurance containment is explicit. |
| AC-006 | ✅ PASS | Purchase/general/FA paths converge; raw insertion does not mirror. |
| AC-007 | ✅ PASS | Exact total and linked tax-row assertions exist. |
| AC-008 | ✅ PASS | Compatibility and returning insertion APIs exist. |
| AC-009 | ✅ PASS | Automatic/salvage companions are linked and reversible. |
| AC-010 | ✅ PASS | Automatic-only continuation is implemented/tested. |
| AC-011 | ✅ PASS | Acquisition with G/L on/off and thin adapters covered in source/tests. |
| AC-012 | ✅ PASS | Normal/final/negative/acquisition amount/cardinality tests exist. |
| AC-013 | ⚠️ PARTIAL | Outer producers are statically neutralized; full localization runtime matrix is missing. |
| AC-014 | ✅ PASS | Link-first FA/maintenance reversal and setup-change behavior are covered. |
| AC-015 | ✅ PASS | Missing/multiple/reversal-of-reversal consistency paths exist. |
| AC-016 | ⚠️ PARTIAL | Sequencing code/tests exist; current CLEAN30 transition run is absent. |
| AC-017 | ❌ FAIL | Historical matching does not enforce actual reversal-chain counterpart identity. |
| AC-018 | ✅ PASS | Retry/idempotency behavior is covered. |
| AC-019 | ✅ PASS | Marker-gated legacy fallback is implemented. |
| AC-020 | ⚠️ PARTIAL | FR routing/shim docs are present; current CLEAN30 package gate is absent. |
| AC-021 | ⚠️ PARTIAL | APIs are restored; complete current consumer compilation is absent. |
| AC-022 | ✅ PASS | All six telemetry dimensions are directly asserted. |
| AC-023 | ⚠️ PARTIAL | Keyed reversal is visible; timing and explicit insertion-key evidence are absent. |
| AC-024 | ⚠️ PARTIAL | W1/FR matrices are strong; localization/event execution is incomplete. |
| AC-025 | ⚠️ PARTIAL | Current W1 and prior build evidence exists, but exact-SHA CI run `32131321496` is not complete/green for all required projects and CLEAN30. |
| AC-026 | ⚠️ PARTIAL | Current-SHA local W1 88/88 is recorded; the complete localization suite and durable manual ledger/G/L evidence remain absent. |
| AC-027 | ⚠️ PARTIAL | Static event ordering is safe; only one of five named event surfaces has a focused regression. |

**AC score**: 17 pass, 9 partial, 1 fail; weighted completion **79.6%**.

The referenced requirements document defines AC-001 through AC-037, while the PRD defines a second AC-001 through AC-027 set with different criterion meanings. The overlapping namespaces and workflow reference should be reconciled for unambiguous traceability.

## EPIC Implementation Status

### EPIC Summary

| EPIC | Validated status | Findings |
|---|---|---|
| EPIC-001: W1 posting/linkage invariants | ⚠️ PARTIAL | ITEM-002 sole-policy rule fails; ITEM-001 corrective RU change is sound. |
| EPIC-002: Link-authoritative reversal | ✅ COMPLETE FOR CURRENT W1 EVIDENCE | Scoped reversal assertion is correct and the PRD records a current-SHA local W1 pass; country runtime remains part of EPIC-009. |
| EPIC-003: French routing/API compatibility | ⚠️ PARTIAL | CLEAN30/current consumer compile gate remains open. |
| EPIC-004: Standard localization outer producers | ⚠️ PARTIAL | Source neutralization is convincing; complete runtime is absent. |
| EPIC-005: Divergent/declaration-only localizations | ⚠️ PARTIAL | IT/RU source exists; current runtime absent and IS equivalent setup defect remains. |
| EPIC-006: Declaration-only localization verification | ✅ COMPLETE STATICALLY | NL regression and semantic evidence exist. |
| EPIC-007: French historical migration | ❌ NON_COMPLIANT | Reversal-chain identity and corrective-tag atomicity gaps. |
| EPIC-008: Deterministic automated coverage | ⚠️ PARTIAL | Strong tests; localization/event/current-run gaps remain. |
| EPIC-009: Release gates | ⚠️ PARTIAL/NON-GREEN | Static sweep and local W1 gate are positive; exact-SHA CI `32131321496` is in progress with at least two failed jobs, so all-country/CLEAN30 release gates remain open. |

### All ITEM Statuses

| Task | Status | Completion / finding |
|---|---|---|
| ITEM-001 | ✅ COMPLETE | W1/FR/RU validation/schema evidence; IS full-copy parity remains an important systemic gap. |
| ITEM-002 | ❌ NONCOMPLIANT | At least 20 active direct relationship filters remain outside the manager. |
| ITEM-003 | ✅ COMPLETE | Both duplicate dispatchers are contained for generated mirrors. |
| ITEM-004 | ✅ COMPLETE | Forward mirroring remains at the shared boundary. |
| ITEM-005 | ✅ COMPLETE | Automatic and salvage identities are captured. |
| ITEM-006 | ✅ COMPLETE | Delegates, identities, and link validation exist. |
| ITEM-007 | ✅ COMPLETE | Acquisition policy/preparation is centralized with thin adapters. |
| ITEM-008 | ✅ COMPLETE | Scoped test restores the second independent reversal and verifies automatic linked reversal; current local W1 pass is recorded. |
| ITEM-009 | ✅ COMPLETE | Maintenance/link/reversal/salvage behavior exists. |
| ITEM-010 | ⚠️ PARTIAL | FR routing exists; current CLEAN30 execution absent. |
| ITEM-011 | ⚠️ PARTIAL | APIs restored; full current consumer compile absent. |
| ITEM-012 | ⚠️ PARTIAL | Standard producers removed; complete country runtime absent. |
| ITEM-013 | ⚠️ PARTIAL | IT implementation exists; current country runtime absent. |
| ITEM-014 | ✅ COMPLETE STATICALLY | Semantic evidence and NL regression exist. |
| ITEM-015 | ✅ COMPLETE | Transfer sequencing and original tag behavior implemented. |
| ITEM-016 | ❌ NONCOMPLIANT | Reversal-chain identity is only shape-checked. |
| ITEM-017 | ✅ COMPLETE | Mutual graph, ambiguity marking, and established-link skip exist. |
| ITEM-018 | ✅ COMPLETE | Six aggregate telemetry dimensions implemented. |
| ITEM-019 | ✅ COMPLETE IN SOURCE | Total-row and posting matrices are present. |
| ITEM-020 | ⚠️ PARTIAL | Most edge cases exist; event-order regression coverage is incomplete. |
| ITEM-021 | ⚠️ PARTIAL | Upgrade matrix exists but reversal-chain tests accept unrelated chain numbers. |
| ITEM-022 | ⚠️ PARTIAL | Producer/heuristic sweep exists; strict policy bypasses remain and evidence is narrative rather than durable. |
| ITEM-023 | ⚠️ PARTIAL/NON-GREEN | Current W1 and prior build evidence exists; exact-SHA CI `32131321496` is active with failed jobs and no final green FR CLEAN30 gate. |
| ITEM-024 | ⚠️ PARTIAL | Current-SHA local W1 88/88 is recorded; localization runtime and durable representative ledger/G/L inspection are incomplete. |
| ITEM-025 | ❌ NONCOMPLIANT | Corrective tag is outside the atomic clear/rebuild `Codeunit.Run`. |
| ITEM-026 | ⚠️ PARTIAL | RU correction is sound; current RU runtime absent. |
| ITEM-027 | ⚠️ PARTIAL/NON-GREEN | Prior builds exist and current CI is running; APAC/BE/CH/DACH/ES/FI/GB runtime gate is not green. |
| ITEM-028 | ⚠️ PARTIAL/NON-GREEN | Prior builds exist and current CI is running; IT/NA/NL/NO/RU/SE runtime gate is not green. |

**Task completion**: 13 complete, 12 partial, 3 noncompliant; strict completion **46.4%**, weighted completion **67.9%**.

## Scope Compliance

### Untraced Changes

No scoped code or documentation change is untraced.

| File | Change description | Mapped to | Verdict |
|---|---|---|---|
| `W1/Tests/.../ERMDerogatoryDeprPosting.Codeunit.al:876-887` | Restore the independent normal-book `Derogatory` reversal and assert its linked generated reversal | FR-009/014/015, AC-009/014, ITEM-008/020/024, TEST-002/003, FILE-020 | ✅ TRACED |
| `...redesign-derogatory-mirroring.prd.md:5,436-477` | Update date, EPIC-009/task statuses, local W1 evidence, pending-CI disclosure, and change log | Goal 5, NFR-005/006/008, AC-025/026, EPIC-009, ITEM-022/023/024/027/028, TEST-006/007 | ✅ TRACED |

### Files Outside PRD Scope

| File | PRD Files-section status | Assessment |
|---|---|---|
| `src/Layers/W1/BaseApp/docs/projects/redesign-derogatory-mirroring/redesign-derogatory-mirroring.prd.md` | The authoritative PRD is not assigned a FILE ID in its own Section 12 | ✅ JUSTIFIED self-documentation/status update; not production scope creep. |

The AL test file is explicitly FILE-020. No production or generated-view file changed.

### Drive-By Changes

- No formatting-only, style-only, refactoring, deletion, or unrelated production/test edit was found.
- All seven documentation deletions replace obsolete gate statuses/evidence in the same EPIC-009 section.
- Unrelated modified/untracked workspace files were excluded and left untouched.

### Containment Verdict

**PASS** — 100% of scoped changed lines are traced, the only AL file is FILE-020, the PRD update is justified, and there are no drive-by or production changes.

## FILE Traceability

| FILE ID | Status | Current evidence / gap |
|---|---|---|
| FILE-001 | ⚠️ PARTIAL | Manager exists, but strict sole-authority requirement fails. |
| FILE-002 | ✅ PASS | Posting-role enum retained. |
| FILE-003 | ✅ PASS | Central source/mirror lifecycle and automatic capture implemented. |
| FILE-004 | ✅ PASS | Returning insertion, validation, link-first reversal implemented. |
| FILE-005 | ✅ PASS | Thin FA acquisition adapter and delegate exist. |
| FILE-006 | ✅ PASS | Thin G/L acquisition adapter exists. |
| FILE-007 | ⚠️ PARTIAL | W1 validation exists; RU parity exists but the RU full-copy table remains omitted from this FILE entry. |
| FILE-008 | ✅ PASS | FA fields and link key exist. |
| FILE-009 | ✅ PASS | Maintenance fields and link key exist. |
| FILE-010 | ❌ FAIL | Historical graph exists but full reversal-chain identity and corrective-tag atomicity fail. |
| FILE-011 | ✅ PASS | Feature-enable sequencing exists. |
| FILE-012 | ✅ PASS | CLEAN30 transfer sequencing exists. |
| FILE-013 | ⚠️ PARTIAL | FR feature gating exists; current runtime/CLEAN30 evidence absent. |
| FILE-014 | ⚠️ PARTIAL | FR legacy/central routing exists; current runtime gate absent. |
| FILE-015 | ⚠️ PARTIAL | Compatibility/link-first code exists; consumer compile incomplete. |
| FILE-016 | ✅ PASS | FR schema parity present. |
| FILE-017 | ⚠️ PARTIAL | Listed active producers are neutralized statically; full runtime absent. |
| FILE-018 | ⚠️ PARTIAL | IT/RU files exist; RU depreciation table is not listed; current runtime absent. |
| FILE-019 | ✅ PASS STATICALLY | Compatibility declarations exist/are retained as documented. |
| FILE-020 | ✅ PASS | The scoped `:876-887` assertion is in this file; the PRD records its targeted 3/3 and full W1 50/50 current-SHA execution. |
| FILE-021 | ✅ PASS IN SOURCE | Setup/policy/link tests exist. |
| FILE-022 | ⚠️ PARTIAL | FR suite exists; reversal-chain test expectation is too weak. |
| FILE-023 | ⚠️ PARTIAL | ES/IT/RU local tests exist; complete current execution absent. |
| FILE-024 | ⚠️ PARTIAL/SUBSTITUTED | OpenSpec proposal is ignored/untracked; PRD declares itself authoritative. |
| FILE-025 | ⚠️ PARTIAL | Ignored/untracked design artifact is not a deliverable from this clone. |
| FILE-026 | ⚠️ PARTIAL | Ignored/untracked tasks artifact remains incomplete. |
| FILE-027 | ✅ PASS STATICALLY | Compatibility declarations/removals align with source. |
| FILE-029 | ✅ PASS IN SOURCE | NL inherited-posting regression exists. |
| FILE-030 | ❌ FAIL | Wrapper is atomic for clear/rebuild but excludes the corrective tag. |

`FILE-028` is undefined; the numbering jumps from FILE-027 to FILE-029.

## Goals, Non-Goals, Architecture, and Status Markers

### Goals and Non-Goals

| Statement | Status | Assessment |
|---|---|---|
| Goal 1: exactly one counterpart independent of path/localization | ⚠️ PARTIAL | Strong W1 tests/static sweep; complete country runtime missing. |
| Goal 2: contain/capture/link/reverse companions | ✅ PASS IN SOURCE | Generated mirrors and automatic companions are explicitly handled. |
| Goal 3: persisted-link-first reversal | ✅ PASS | W1/FR/RU implementations follow link first. |
| Goal 4: safe observable French historical linkage | ❌ FAIL | Reversal-chain identity and corrective-tag atomicity gaps remain. |
| Goal 5: W1/FR/localization/CLEAN30 compile and tests | ⚠️ PARTIAL | Current W1 evidence and prior builds exist; current-SHA CI is not complete/green. |
| Non-Goal 1: no one-to-many relationship | ✅ PRESERVED | Setup/runtime model remains one-to-one. |
| Non-Goal 2: no formula/account/report behavior change | ⚠️ PARTIAL | No product source changed in scope; full runtime proof remains absent. |
| Non-Goal 3: no duplication-feature redesign | ✅ PRESERVED | Only generated-mirror suppression is implemented. |
| Non-Goal 4: no persistent counter table | ✅ PRESERVED | Telemetry uses aggregate dimensions. |

### Architecture Decisions

| Decision | Status | Assessment |
|---|---|---|
| RD-001 | ❌ FAIL | Central posting boundary exists, but 20 relationship-policy bypasses contradict sole authority. |
| RD-002 | ✅ PASS | Both duplicate dispatchers are guarded. |
| RD-003 | ✅ PASS | Automatic companions are tracked individually. |
| RD-004 | ✅ PASS | Link-first zero/one/multiple/fallback logic implemented. |
| RD-005 | ⚠️ PARTIAL | Complete mutual graph exists; full reversal-chain identity does not. |
| RD-006 | ✅ PASS | Compatibility delegates/overloads restored. |
| RD-007 | ⚠️ PARTIAL | IT/RU treated independently; current runtime absent. |
| RD-008 | ✅ PASS | Telemetry only, no table. |
| RD-009 | ✅ PASS | Shim survives CLEAN30 in code comments/design. |
| RD-010 | ✅ PASS STATICALLY | Clean settings inject CLEAN30. |
| RD-011 | ✅ PASS | Original/corrective tags and force API exist. |

Architecture steps 1-5 are implemented in current W1 source. Step 6 is partial because the French candidate graph does not validate actual reversal-chain pairing. Step 7 is statically implemented, but runtime proof is incomplete.

### PRD Status Markers

| Marker | PRD status | Review result |
|---|---|---|
| Purpose Review / Deep Research / Draft / Refine | Completed | Accepted as planning-process history; the requirements document's AC-001..037 and the PRD's differently defined AC-001..027 collide. |
| PRD Review | DONE | Historical marker only; current review identifies unresolved gaps. |
| Implementation | DONE | Overstated: ITEM-002/016/025 are noncompliant. |
| Review | DONE | Historical EPIC-003 review completed, but not equivalent to all-PRD compliance. |
| Post-implementation remediation | DONE | Corrective code and current local W1 evidence are present; current-SHA country CI remains non-green. |
| EPIC-001..008 | DONE | Several must be reopened as shown above. |
| EPIC-009 | DONE, qualified as local W1 green/localization pending | Overstated as a roll-up: current-SHA CI is not green, so the validated status remains PARTIAL. |
| ITEM-023 | “DONE for prior builds; fresh rerun pending” | PARTIAL; prior builds do not satisfy the exact-SHA all-gates requirement. |
| ITEM-027/028 | Builds DONE; runtime pending | Accurate as partial, not complete. |
| ITEM-024 | W1 local DONE; localization pending | Accurate as partial. |

## Gap Analysis

### Critical Gaps

1. **Historical reversal chains are matched by shape, not identity**
   - PRD Reference: FR-017, ITEM-016, AC-017, RD-005, RISK-005
   - Evidence: `UpgradeDerogatoryLinkage.Codeunit.al:323-334,458-469`; tests at `UTDerogatoryLinkageUpg.Codeunit.al:545-582` deliberately use unrelated chain numbers and still expect linking.
   - Impact: HIGH — a mutually unique but wrong historical reversal pair can be permanently linked.
   - Recommendation: validate the candidate's reversed/reversing entries against the counterpart candidates of the source chain; add crossed-chain/adversarial FA and maintenance tests.

2. **Corrective upgrade tag is not in the atomic clear/rebuild transaction**
   - PRD Reference: ITEM-025, NFR-003, RISK-006
   - Evidence: `UpgradeDerogatoryLinkage.Codeunit.al:92-109`; wrapper `DerogLinkageCorrectiveRun.Codeunit.al:18-24`.
   - Impact: HIGH — clear/rebuild can commit and tag assignment can fail separately, allowing an unintended rerun.
   - Recommendation: include corrective-tag assignment in the same rollback boundary or revise the explicit one-transaction requirement with a proven recovery design.

3. **Sole relationship-policy authority is not achieved**
   - PRD Reference: FR-004, ITEM-002, RD-001
   - Evidence: repository search returns at least 20 direct filters in calculation/report paths, including W1 `CalculateDepreciation.Report.al:413`, `CalculateNormalDepreciation.Codeunit.al:597`, `FixedAssetBookValue01.Report.al:519`, and `FixedAssetBookValue02.Report.al:1560`.
   - Impact: HIGH — ambiguous imported setup can be silently resolved with `FindFirst`/`Find('-')` outside the manager.
   - Recommendation: route these paths through the manager, or explicitly narrow the requirement and prove why read-only/report calculation paths may differ.

4. **Current-SHA release gates are not closed**
   - PRD Reference: NFR-005/006, ITEM-023/024/027/028, AC-025/026
   - Evidence: exact-SHA run `32131321496` targets `0b1f8578b7` but was still in progress with failed ES IntegrationTests and NZ LegacyTestsBucket2 jobs at final capture. PRD-cited parent-SHA run `32129755257` completed cancelled. Current local W1 88/88 is recorded but does not satisfy all-country/CLEAN30/manual-inspection gates.
   - Impact: HIGH — accounting/localization readiness is not dynamically established.
   - Recommendation: run actual country projects plus W1, FR, and FR Clean/CLEAN30 at current SHA; publish and execute focused suites; retain ledger/G/L evidence.

### Important Gaps

1. **Equivalent IS full-copy defect remains**
   - Evidence: `src/Layers/IS/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al:380-409`.
   - Expected: reassignment must execute uniqueness/chain/reverse-use checks as W1/RU do.
   - Recommendation: determine whether IS is intentionally excluded; otherwise port W1 validation and run inherited codeunit 134166 in the IS composed project.

2. **Localization runtime coverage is incomplete**
   - PRD Reference: FR-013, NFR-001/008, ITEM-012/013/026/027/028
   - Recommendation: execute inherited W1 suite in the actual composed projects and local ES/IT/RU regressions.

3. **AL-Go project names in the PRD are not executable as written**
   - PRD cites `Apps APAC`, `Apps DACH`, and `Apps NA`; repository projects are country-specific (`Apps AT/AU/NZ`, `Apps DE`, `Apps CA/MX/US`).
   - Recommendation: replace aggregate aliases with concrete projects or document an explicit expansion map.

4. **Event-order coverage is incomplete**
   - PRD Reference: NFR-007, AC-027, ITEM-020
   - Recommendation: add focused regressions for all five named event surfaces.

### Minor Deviations

1. Add RU `DepreciationBook.Table.al` to FILE-007/FILE-018 and ITEM-001/026 relevant files.
2. Correct the pre-existing PRD line 467 wording from “current HEAD `81a5ff1e23`” to the historical SHA it describes.
3. Reconcile the requirements document's AC-001..037 namespace with the PRD's different AC-001..027 definitions.
4. Define FILE-028 or renumber FILE-029/030.
5. Keep EPIC-009 partial until exact-SHA localization runtime and CLEAN30 gates finish green.

## Quality Assessment

### Test Coverage

- **Required test groups**: 7 (`TEST-001` through `TEST-007`)
- **Current source inventory**: 223 `[Test]` methods across the seven named W1/FR/ES/IT/RU/NL files; this count includes unrelated methods in shared localization codeunits and is not a code-coverage percentage.
- **Current-SHA execution**: local W1 88/88 is recorded in the PRD; exact-SHA CI `32131321496` is non-green/in progress and was not treated as a pass.

| Test requirement | Status | Evidence / gap |
|---|---|---|
| TEST-001 | ✅ PASS IN SOURCE | 27 methods in `UTTABFADerogatoryDepr.Codeunit.al`; setup/policy/link cases present. |
| TEST-002 | ✅ PASS IN SOURCE/RECORDED LOCAL | 48 methods in `ERMDerogatoryDeprPosting.Codeunit.al`; scoped reversal assertion is sound and current local codeunit 134149 50/50 is recorded. |
| TEST-003 | ✅ PASS IN SOURCE | Extensive FA/maintenance reversal cases exist. |
| TEST-004 | ⚠️ PARTIAL | 33 FR test methods, but reversal-chain identity is not correctly asserted. |
| TEST-005 | ⚠️ PARTIAL | ES/IT/RU/NL regressions exist; inherited country executions are incomplete. |
| TEST-006 | ⚠️ PARTIAL | Current W1 and prior build evidence exists; complete exact-SHA localization/CLEAN30 CI evidence is absent. |
| TEST-007 | ⚠️ PARTIAL | Current local W1 runs are recorded; complete localization execution/manual inspection is absent. |

Positive test-quality findings:

- Exact tax-row/link equality helper: `ERMDerogatoryDeprPosting.Codeunit.al:2867-2890`.
- Scoped test captures the independent derogatory counterpart before reversal and asserts its linked generated reversal.
- Telemetry interception asserts all six dimensions.
- Corrective retry/rollback tests exist.

### Documentation

**Required updates**: PRD, compatibility statement, CLEAN30 shim lifetime, OpenSpec proposal/design/tasks, release evidence.

**Completed**: PRD remediation narrative; compatibility/shim statements; prior report evidence.

**Missing/inconsistent**: tracked OpenSpec artifacts, executable project paths, final exact-SHA release evidence, FILE inventory parity, AC numbering, the stale historical “current HEAD” wording, and the EPIC-009 `DONE` roll-up.

### Performance & Constraints

- Dedicated link keys exist and reversal explicitly chooses them.
- No representative indexed-lookup timing artifact was found.
- No accounting formula, amount, account, schema, API, or production code changed in the scoped commit.
- `git diff --check` passed.
- No additional AL build/runtime was run: the scope is a test-body composition using existing symbols, the PRD records current local W1 execution, and active CI is the required cross-country gate. No result is fabricated.

### Deployment and Rollback

| Deployment requirement | Status |
|---|---|
| Merge only after all gates pass | ❌ NOT SATISFIED |
| Normal W1/localization upgrade sequence | ⚠️ PARTIAL at current SHA |
| Relationship transfer before linkage | ✅ VERIFIED IN SOURCE |
| Monitor six dimensions | ✅ IMPLEMENTED; operations unverified |
| Inspect representative ledgers/G/L | ⚠️ W1 scenarios recorded; no durable complete cross-country artifact |
| Forward-only corrective rebuild | ⚠️ PARTIAL due tag atomicity |
| Retain French shim beyond CLEAN30 | ✅ VERIFIED |

## Risk Assessment

| Risk | Status | Mitigation | Notes |
|---|---|---|---|
| RISK-001 | ⚠️ PARTIAL | Static producer sweep and cardinality tests | Complete country runtime missing. |
| RISK-002 | ✅ MITIGATED | Generated role clears/bypasses duplication and insurance controls | Source/tests align. |
| RISK-003 | ✅ MITIGATED | Automatic identities captured individually | Salvage/automatic-only tests exist. |
| RISK-004 | ✅ MITIGATED | Link queried before setup | Scoped reversal assertion aligns. |
| RISK-005 | ❌ OPEN | Mutual candidate graph | Full reversal-chain identity is missing. |
| RISK-006 | ⚠️ PARTIAL | Original tag ordering correct | Corrective tag outside atomic wrapper. |
| RISK-007 | ⚠️ PARTIAL | IT/RU distinct implementations/tests | Current country runtime absent; IS equivalent issue found. |
| RISK-008 | ⚠️ PARTIAL | Compatibility APIs restored | Full current consumer compilation absent. |

### Assumptions and Dependencies

| ID | Status | Assessment |
|---|---|---|
| ASSUMPTION-001 | ✅ VERIFIED | Field numbers and keys match current W1/FR schema and known overrides. |
| ASSUMPTION-002 | ✅ VERIFIED STATICALLY | Disabled FR vs enabled/CLEAN30 routing guards exist; runtime unverified. |
| ASSUMPTION-003 | ✅ VERIFIED | Clean symbols come from AL-Go settings; the scoped commit did not modify product `app.json`. |
| DEP-001 | ✅ VERIFIED | Manager and role enum exist. |
| DEP-002 | ✅ VERIFIED | FA Key13/Maintenance Key10 and fields exist. |
| DEP-003 | ✅ VERIFIED IN SOURCE | Relationship transfer invokes linkage in sequence. |
| DEP-004 | ✅ VERIFIED IN SOURCE | Six dimensions are passed to feature telemetry. |
| DEP-005 | ⚠️ PARTIAL | Semantic sweep is narrated; no durable machine-readable artifact. |
| DEP-006 | ⚠️ PARTIAL | Current local W1 execution is recorded; complete exact-SHA localization execution is unavailable. |
| DEP-007 | ❌ DOCUMENTATION GAP | APAC/DACH/NA project paths do not exist as written. |

## Recommendations

### Priority 1 - Critical (Must Fix)

1. Implement true reversal-chain counterpart consistency in `FR/.../UpgradeDerogatoryLinkage.Codeunit.al:323-334,458-469` and add adversarial tests.
2. Put the ITEM-025 corrective tag inside the atomic clear/rebuild transaction.
3. Resolve the FR-004/RD-001 policy-authority contradiction for every direct relationship filter (at least 20 active calculation/report occurrences).
4. Complete current-SHA run `32131321496`, resolve/rerun every failed relevant job, and retain green W1, FR, CLEAN30, and actual-country build/runtime evidence.

### Priority 2 - Important (Should Fix)

1. Fix or explicitly exclude the IS full-copy validation at `IS/.../DepreciationBook.Table.al:380-409`.
2. Run inherited and local regressions in all composed localizations.
3. Add focused subscriber-order regressions for all AC-027 events.
4. Correct AL-Go project paths and formal FILE/ITEM traceability.

### Priority 3 - Minor (Nice to Have)

1. Correct the stale historical “current HEAD” wording and EPIC-009 `DONE` roll-up.
2. Reconcile AC numbering and FILE-028.
3. Strengthen the RU relationship test to assert the expected message, not only generic `Dialog`.

## Metrics Summary

- **Unique prefixed identifiers/references in PRD**: 177
- **Functional/non-functional requirements**: 30
- **Requirements strictly met**: 16 (53.3%)
- **Requirements partial**: 12
- **Requirements failed**: 2
- **Requirements unverified**: 0
- **Weighted requirements completion**: 73.3% → **73%**
- **Acceptance criteria**: 27 defined; 17 pass, 9 partial, 1 fail; weighted **79.6%**
- **Total tasks**: 28
- **Tasks complete**: 13 (46.4% strict)
- **Weighted task completion**: 67.9%
- **Files expected by PRD**: 29 FILE IDs representing multiple paths; FILE-028 undefined
- **Files actually modified in scope**: 2
- **Scoped changed lines traced**: 100%
- **Scoped AL files inside formal FILE inventory**: 1/1; the second file is the authoritative PRD itself
- **Scope containment**: PASS; no untraced or drive-by changes
- **Test coverage**: not objectively measurable; current local W1 88/88 is recorded, while exact-SHA cross-country CI is not green
- **Documentation completeness**: partial; not assigned a fabricated percentage

## Conclusion

The scoped test/documentation commit is **correct, minimal, fully traced, and scope-compliant**. It should be retained and is acceptable in isolation. It does not change production behavior or resolve the pre-existing architecture/migration defects.

The current repository is **PARTIALLY_COMPLIANT (73%)** with the full PRD because FR-004/ITEM-002, FR-017/ITEM-016, and NFR-003/ITEM-025 remain noncompliant and exact-SHA release gates are not green.

**Ready to merge as the completed PRD implementation: NO.** Merge/release approval requires the Priority 1 fixes and successful current-SHA localization/CLEAN30/runtime evidence. The scoped commit alone is low risk and mergeable as an incremental correction, but it cannot justify closing the feature.

## Appendix

### Identifier Inventory

| Prefix | Count | Inventory |
|---|---:|---|
| FR | 22 | FR-001..FR-022 |
| NFR | 8 | NFR-001..NFR-008 |
| FM | 13 | FM-001..FM-013 |
| AC | 28 unique references | AC-001..AC-027 plus AC-037 reference |
| RD | 11 | RD-001..RD-011 |
| CON | 2 | CON-001..CON-002 |
| GUD | 1 | GUD-001 |
| PAT | 1 | PAT-001 |
| EPIC | 9 | EPIC-001..EPIC-009 |
| ITEM | 28 | ITEM-001..ITEM-028 |
| FILE | 29 | FILE-001..027, FILE-029, FILE-030 |
| RISK | 8 | RISK-001..RISK-008 |
| ASSUMPTION | 3 | ASSUMPTION-001..003 |
| DEP | 7 | DEP-001..007 |
| TEST | 7 | TEST-001..007 |
| REQ / SEC | 0 | No identifiers present |

### Failure Modes

| Failure mode | Status |
|---|---|
| FM-001 ambiguous setup | ✅ Mitigated through manager |
| FM-002 duplicate counterpart | ✅ Mitigated |
| FM-003 missing counterpart | ✅ Mitigated |
| FM-004 multiple counterparts | ✅ Mitigated |
| FM-005 localization duplicate | ⚠️ Static mitigation; runtime incomplete |
| FM-006 premature original tag | ✅ Mitigated |
| FM-007 false historical link | ❌ Open due reversal-chain identity |
| FM-008 partial retry duplicate | ✅ Mitigated |
| FM-009 automatic companion omitted | ✅ Mitigated |
| FM-010 setup-first reversal | ✅ Mitigated |
| FM-011 invalid source link | ✅ Mitigated |
| FM-012 automatic acquisition omitted | ✅ Mitigated in source/tests |
| FM-013 API breakage | ⚠️ APIs restored; current full compile absent |

### Files Reviewed

- Both files in `0b1f8578b7^..0b1f8578b7`, with parent-versus-scoped lineage for the reversal test.
- Complete PRD and referenced requirements document.
- W1 manager, posting boundary, insertion/reversal, schema, setup validation, and focused test files.
- FR linkage upgrade, corrective wrapper, transfer callers, routing, compatibility, schema, and upgrade tests.
- ES/IT/RU/NL localization tests and relevant current localization implementations.
- DACH/GB/IT/RU/IS full-copy setup validation files.
- AL-Go settings/workflow/project paths and prior review report.

### Tools Used

- Two independent SddCoder sub-agents using code-intelligence/code-search for implementation/traceability and requirements/quality validation.
- `git show`, exact `git diff 0b1f8578b7^..0b1f8578b7`, `git diff --check`, status, ancestry, and tracked-file inspection.
- Static source inspection with exact line ranges and repository-wide relationship-filter searches.
- `gh run view 32129755257` and exact-SHA `gh run view/list` for run `32131321496`, including job-status aggregation.
- Direct verification of reversal-shape matching, corrective transaction boundaries, IS validation parity, and relationship-filter bypasses.
- Non-destructive test-attribute inventory; no production code or test file was edited.
