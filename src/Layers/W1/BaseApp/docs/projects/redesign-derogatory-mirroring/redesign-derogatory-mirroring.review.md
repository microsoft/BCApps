---
prd: C:\Enlist\navagent2\App\BCApps\src\Layers\W1\BaseApp\docs\projects\redesign-derogatory-mirroring\redesign-derogatory-mirroring.prd.md
scope: workspace — 18 staged and 75 unstaged entries; no untracked files before this report
date_reviewed: 2026-08-08
reviewer: GitHub Copilot
compliance_status: REMEDIATED
completion_percentage: 100%
remediated: 2026-08-10
remediated_by: SddCoder
remediation_status: All actionable EPIC-003 findings resolved and re-verified; see Remediation Record.
---

# PRD Implementation Review Report

## Executive Summary

EPIC-003 is **NON_COMPLIANT** and is not ready to merge. Static inspection confirms that the main disabled/enabled/CLEAN29 routing branches and the requested public signatures exist, but five release-blocking defects remain:

1. The W1 Fixed Asset test project does not compile because FR-only objects were introduced into W1 tests.
2. The FR posting override does not contain generated mirrors before invoking duplicate-book/insurance dispatchers.
3. A changed book-value assertion accepts an accounting result that the PRD explicitly requires to remain unchanged.
4. The restored FR compatibility builder bypasses the authoritative policy service and silently selects the first ambiguous relationship.
5. A dangling `else` prevents the feature-disabled FR reversal path from populating its temporary consistency record.

Containment also fails: 84 of the 93 pre-report workspace entries are wholly untraced tooling or report-layout changes. Four additional FR AL files are defensible failing-test/runtime-routing fixes but are omitted from the PRD Files section. The relocated FR test is traceable in intent but placed in the wrong layer and breaks W1 compilation.

The 32% completion score is weighted across 14 applicable requirement rows: 3 PASS, 3 PARTIAL, and 8 FAIL, with PARTIAL counting as one-half.

## Scope of Review

**PRD Document**: `C:\Enlist\navagent2\App\BCApps\src\Layers\W1\BaseApp\docs\projects\redesign-derogatory-mirroring\redesign-derogatory-mirroring.prd.md`  
**Changes Reviewed**: `workspace`, captured before creating this report  
**Review Target**: EPIC-003 and its explicit dependencies only  
**Total Files Modified**: 93 current-path entries (18 staged, 75 unstaged, 0 untracked); the rename also has one historical source path  
**Text Changes**: staged +12,503/-108; unstaged +977/-81  
**Binary Changes**: 65 DOCX files  
**Review Date**: 2026-08-08  
**Baseline**: branch `private/algladkov/FR-Derogatory-Depreciation-redesign`, HEAD `78759d0ee63b68a2907e24a40ac9b86a1bd77e96`

Unimplemented EPIC-004 through EPIC-009 work was not scored unless EPIC-003 directly relies on it for routing, containment, compatibility, or validation.

**Reference path key**: abbreviated evidence paths below expand to:

- `W1/.../DerogatoryPostingMgt.Codeunit.al` and W1 `FAJnlPost*.Codeunit.al`: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/`
- FR `FA*.Codeunit.al`: `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/`
- FR `DepreciationBook.Table.al` and `FADepreciationBook.Table.al`: `src/Layers/FR/BaseApp/FixedAssets/Depreciation/`
- `W1/.../UTDerogatoryLinkageUpg.Codeunit.al`: `src/Layers/W1/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al`

## Requirements Compliance

### Functional Requirements

| Requirement | Status | Implementation | Notes |
|------------|--------|---------------|-------|
| FR-002 | ❌ FAIL | `W1/.../DerogatoryPostingMgt.Codeunit.al:15-28`; `FR/.../FAJnlPostBatch.Codeunit.al:327-341` | The manager rejects a second relationship, but the restored FR public builder uses `FindFirst()` and bypasses the ambiguity check. |
| FR-004 | ❌ FAIL | `W1/.../DerogatoryPostingMgt.Codeunit.al:15-44`; `FR/.../FAJnlPostBatch.Codeunit.al:327-341` | `Derogatory Posting Mgt.` is not the sole policy authority because the FR compatibility API reimplements resolution and eligibility. |
| FR-005 | ❌ FAIL | `FR/.../FAJnlPostLine.Codeunit.al:90-103,145-157`; W1 reference behavior at `W1/.../FAJnlPostLine.Codeunit.al:96-106,159-160` | FR generated mirrors still execute both duplicate-book dispatchers, leaving duplicate-book and insurance side effects possible. |
| FR-020 | ⚠️ PARTIAL | `FR/.../FAJnlPostBatch.Codeunit.al:267-325,405-429`; `FR/.../FAJnlPostLine.Codeunit.al:290-329` | Disabled routing is legacy-only and enabled/CLEAN29 routing is central-only statically. Compliance is blocked by generated-mirror containment, missing runtime evidence, failed test compilation, and contradictory shim documentation at `UpgradeDerogatoryLinkage.Codeunit.al:13-20`. |
| FR-021 | ⚠️ PARTIAL | W1 delegate at `W1/.../FAJnlPostBatch.Codeunit.al:265-273`; FR overloads at `FR/.../FAInsertLedgerEntry.Codeunit.al:859-872,946-959` | Signatures exist, but the FR builder is not a policy delegate, the reversal path contains a logic defect, dependent tests do not compile, and FILE-024 is ignored/untracked. |

### Security Requirements

The PRD defines no `SEC-*` identifiers. Its four security considerations were still checked.

| Consideration | Status | Evidence | Notes |
|---------------|--------|----------|-------|
| Data handling | ✅ PASS | No telemetry or sensitive-data change in EPIC-003 | The workspace introduces no business identifiers into telemetry. |
| Input validation | ❌ FAIL | `FR/.../FAJnlPostBatch.Codeunit.al:327-341` | Imported ambiguous relationships can be silently reduced to the first record through the public compatibility API. |
| Access control | ✅ PASS | No permission/public-entry-point expansion found | Existing procedure restoration does not add permission sets. |
| Secrets | ✅ PASS | Full text diff and tooling files inspected | No credential, token, or connection string was found. The local LSP config is unportable but not secret. |

### Constraints & Guidelines

| Requirement | Status | Implementation | Notes |
|------------|--------|---------------|-------|
| NFR-001 | ❌ FAIL | `FR/.../FAJnlPostLine.Codeunit.al:90-103,145-157` | Uncontained dispatchers can make counterpart count depend on duplicate-book/insurance setup. |
| NFR-004 | ❌ FAIL | `ERMDerogatoryDeprPosting.Codeunit.al:98-112,1556-1580`; moved test `:18-159` | Test intent is weakened, required containment cases are absent, and the target suite cannot compile. |
| NFR-005 | ❌ FAIL | W1 targeted compiler output: 11 `AL0185` errors | W1 Fixed Asset tests reference FR-only codeunits. No current CLEAN29 or full four-project evidence exists. |
| NFR-006 | ❌ FAIL | PRD implementation note at `redesign-derogatory-mirroring.prd.md:322`; `gh run list` returned no branch runs | Zero current runtime suites or ledger/G/L inspections were evidenced. |
| NFR-007 | ⚠️ PARTIAL | Compatibility signatures exist; final link validation remains immediately before insert | No event/subscriber-order regression exists, and dependent-consumer compilation fails. |
| CON-001 | ✅ PASS | All product/test changes are under `src/Layers/**` | No generated `src/Views/**` file is modified. `src/Layers/W1/.view/...` is generated tooling data and is scope creep, but not a direct edit to `src/Views/**`. |
| CON-002 | ❌ FAIL | `ERMDerogatoryDeprPosting.Codeunit.al:112`; `FR/.../FADepreciationBook.Table.al:344-356`; `FR/.../FAInsertLedgerEntry.Codeunit.al:129-137` | The test now accepts a reduced normal-book value. Non-CLEAN29 `Book Value` filters the legacy exclusion field while enabled insertion writes only the new field. |
| GUD-001 | ✅ PASS | Object/procedure/field identifiers were used with line references throughout this review | Line drift did not prevent semantic tracing. |
| PAT-001 | ✅ PASS | W1 delegate `:265-273`; FR result-returning overload delegates `:859-872,946-959` | The required overload/delegate shape exists, notwithstanding behavioral defects in the delegated path. |

### Applicable Acceptance Criteria

| Criterion | Status | Finding |
|-----------|--------|---------|
| AC-002 / AC-004 dependency | ❌ FAIL | The FR public builder bypasses ambiguity rejection. |
| AC-005 generated-mirror containment dependency | ❌ FAIL | FR override invokes duplicate dispatchers for generated mirrors. |
| AC-020 | ❌ FAIL | Routing shape exists, but runtime proof, containment, and post-CLEAN29 shim documentation are incomplete. |
| AC-021 | ⚠️ PARTIAL | Signatures are restored; source-compatible behavior and consumer compilation are not established. |
| AC-025 | ❌ FAIL | W1 test compilation fails; FR/CLEAN29 evidence is unavailable. |
| AC-027 | ❌ FAIL | No subscriber/event-order regression was found. |

## EPIC Implementation Status

### EPIC-003: Correct French runtime routing and compatibility

| Task | Status | Completion | Findings |
|------|--------|------------|----------|
| ITEM-010 | ⚠️ PARTIAL | Static disabled/enabled/CLEAN29 branches are present. | FR generated-mirror containment is missing; the W1/FR routing tests are not compilable; runtime proof is absent; shim lifetime documentation is contradictory. |
| ITEM-011 | ⚠️ PARTIAL | W1 and FR public signatures are present. | FR builder bypasses the manager; disabled reversal contains a dangling-`else` defect; FILE-024 is not deliverable; consumer/test compilation fails. |

**EPIC Completion**: 0/2 tasks strictly complete — 0% strict, 50% weighted partial completion.

### Architecture and FILE Traceability

| Reference | Status | Evidence |
|-----------|--------|----------|
| RD-001 | ❌ FAIL | FR `MakeDerogatoryFAJnlLine` reimplements policy at `FAJnlPostBatch.Codeunit.al:327-341`. |
| RD-002 | ❌ FAIL | FR generated mirrors invoke duplicate dispatchers at `FAJnlPostLine.Codeunit.al:90-103,145-157`. |
| RD-006 | ⚠️ PARTIAL | APIs are restored, but source-compatible behavior/compilation is not proven. |
| RD-009 | ⚠️ PARTIAL | Shim code survives CLEAN29, but `UpgradeDerogatoryLinkage.Codeunit.al:13-20` says it lasts only until the FR CLEAN29 cleanup version. |
| RD-010 | ⚠️ PARTIAL | `.github/AL-Go-Settings.json:20-34` defines cumulative CLEAN25-CLEAN29 symbols, but no successful current Clean build exists. |
| FILE-005 | ✅ PASS | W1 compatibility delegate exists at `FAJnlPostBatch.Codeunit.al:265-273`. |
| FILE-013 | ❌ FAIL | Routing gate exists, but generated-mirror containment is absent in the FR override. |
| FILE-014 | ✅ PASS (static) | Disabled/central FA-journal routing is mutually exclusive at `FR/.../FAJnlPostBatch.Codeunit.al:405-429`. |
| FILE-015 | ❌ FAIL | Overloads exist, but `FAInsertLedgerEntry.Codeunit.al:566-577` has incorrect `else` binding. |
| FILE-020 | ❌ FAIL | Contains an accounting-expectation regression and an FR-only dependency in a W1 test. |
| FILE-021 | ❌ FAIL | Contains an FR-only dependency in a W1 test; Code[10] test-data corrections are otherwise justified. |
| FILE-022 | ❌ FAIL | Renamed/moved from the specified FR path to W1, renumbered 134167→134194, and changed five tests to `AutoCommit`. |
| FILE-024 | ⚠️ PARTIAL | Local ignored proposal text correctly names `Is Derogatory` as the only break, but the file is not tracked or part of the workspace diff. |

## Scope Compliance

Only 9/93 pre-report workspace entries map to an EPIC-003 item or a defensible supporting fix. One of those nine—the moved test—is traced but noncompliant. Eight entries are both traced and reasonably justified; 84 are wholly untraced.

### Untraced Changes

| File | Change Description | Mapped To | Verdict |
|------|-------------------|-----------|---------|
| `.github/lsp.json` | Machine-specific AL LSP path and project path | NONE | ⚠️ UNTRACED; unportable local setup |
| `src/Layers/W1/.view/layered_view_files.json` | 11,246-entry generated absolute-path manifest | NONE | ⚠️ UNTRACED generated artifact |
| `src/Layers/W1/BaseApp/.config/**`, `.github/**` (6 files) | Octane agent/scenario installation metadata and docs | NONE | ⚠️ UNTRACED workflow scaffolding |
| `.../redesign-derogatory-mirroring.req.md` | 402-line planning artifact | NONE / pre-PRD input | ⚠️ UNTRACED to EPIC-003 implementation |
| 65 DOCX files in Appendix | Package/XML/relationship regeneration | NONE | ⚠️ UNTRACED drive-by changes |
| 10 RDLC files in Appendix | Dataset/parameter/serialization changes | NONE | ⚠️ UNTRACED drive-by changes |

### Supporting Changes Outside the PRD Files Section

| File | Change | Trace/Justification | Verdict |
|------|--------|---------------------|---------|
| `FR/.../DepreciationBook.Table.al:656-671` | Selects legacy/new integration fields by feature state | FR-020, CON-002 failing-test support | ✅ JUSTIFIED, but FILE omission |
| `FR/.../FAGetJournal.Codeunit.al:17-22,137-151` | Selects legacy/new G/L integration field | FR-020 supporting fix | ✅ JUSTIFIED, but FILE omission |
| `FR/.../FAInsertGLAccount.Codeunit.al:70-78,465-494` | Selects legacy/new account and allocation fields | FR-020/CON-002 supporting fix | ✅ JUSTIFIED, but FILE omission |
| `FR/.../FAJnlCheckLine.Codeunit.al:69-76,352-362` | Selects legacy/new integration field during validation | FR-020 supporting fix | ✅ JUSTIFIED, but FILE omission |

### Failing-Test Fix Assessment

| Change | Assessment | Verdict |
|--------|------------|---------|
| `ERMDerogatoryDeprPosting.Codeunit.al:112` changes expected normal book value | Accepts a likely product regression instead of preserving accounting intent. | ❌ INVALID FIX |
| `ERMDerogatoryDeprPosting.Codeunit.al:1565-1580` adds FR feature codeunit to W1 test | Intended to force central routing, but violates layer boundaries and prevents compilation. | ❌ INVALID FIX |
| `ERMDerogatoryDeprPosting.Codeunit.al:1755-1764` creates distinct G/L accounts | Makes setup less dependent on existing account properties and preserves test intent. | ✅ JUSTIFIED |
| `UTTABFADerogatoryDepr.Codeunit.al:128-140` uses `GetNewCode10()` for Code[10] fields | Corrects generated data length without weakening assertions. | ✅ JUSTIFIED |
| `UTTABFADerogatoryDepr.Codeunit.al:351-434` adds FR feature dependency | Intended to select central behavior, but W1 cannot resolve the FR codeunit. | ❌ INVALID FIX |
| FR test move/renumber to `W1/.../UTDerogatoryLinkageUpg.Codeunit.al` | Renumbering may avoid object-ID collision, but moving FR-only tests into W1 is structurally invalid. Keep it in FR with a non-conflicting ID. | ❌ INVALID FIX |
| Five `AutoRollback`→`AutoCommit` changes at moved test `:20,53,86,113,151` | May avoid rollback-related posting failures, but persists setup/ledger/feature state without teardown and weakens repeatability. | ⚠️ HIGH REGRESSION RISK |
| Dynamic depreciation books and explicit ledger cleanup at moved test `:337-362` | Reduces collisions for upgrade cases, but does not make the five routing/API `AutoCommit` tests isolated. | ⚠️ PARTIAL |

### Files Outside PRD Scope

There are **89 current paths outside the PRD Files section**:

- 4 justified FR supporting AL files listed above.
- 1 traced but misplaced W1 test destination.
- 9 untraced tooling/planning additions.
- 65 untraced DOCX files.
- 10 untraced RDLC files.

The four current paths inside the listed PRD scope are FILE-013, FILE-015, FILE-020, and FILE-021. The rename source matches FILE-022, but its destination does not.

### Drive-By Changes

- All 75 report-layout changes are unrelated to EPIC-003.
- All 9 tooling/planning additions are unrelated to product implementation.
- Six staged FR AL diffs also remove a final blank line; these formatting-only deletions do not trace to a requirement.
- No unnecessary AL interface, factory, table, enum, or persistent configuration abstraction was added. The problem is broad workspace/tooling scope, not product abstraction complexity.

## Gap Analysis

### Critical Gaps

1. **W1 Fixed Asset tests do not compile**
   - PRD Reference: NFR-005, AC-025, ITEM-010, ITEM-011
   - Evidence: `ERMDerogatoryDeprPosting.Codeunit.al:1568`, `UTTABFADerogatoryDepr.Codeunit.al:422`, and moved test `:194,216,236,256,279,300,321,369,384`
   - Impact: HIGH
   - Recommendation: Keep FR-only setup/routing tests in the FR Fixed Asset test layer; remove FR codeunit dependencies from W1 tests; then compile W1 and FR independently.

2. **Generated mirrors can invoke duplicate-book and insurance behavior**
   - PRD Reference: FR-005, RD-002, RISK-002
   - Evidence: `FR/.../FAJnlPostLine.Codeunit.al:90-103,145-157`
   - Impact: HIGH — duplicate or unlinked ledger rows and insurance side effects
   - Recommendation: Port the W1 role guard/neutralization into the FR override and add a configured duplicate-book/insurance regression.

3. **Accounting regression is masked by the test**
   - PRD Reference: CON-002, Non-Goal 2
   - Evidence: test `ERMDerogatoryDeprPosting.Codeunit.al:112`; insertion `FR/.../FAInsertLedgerEntry.Codeunit.al:129-137`; FlowField `FR/.../FADepreciationBook.Table.al:344-356`
   - Impact: HIGH — normal-book report/book value changes
   - Recommendation: Restore the invariant assertion, then align non-CLEAN29 FlowField filtering and enabled insertion so the derogatory entry remains excluded as designed.

4. **FR public compatibility API bypasses central policy**
   - PRD Reference: FR-002, FR-004, ITEM-011, RD-001, PAT-001
   - Evidence: `FR/.../FAJnlPostBatch.Codeunit.al:327-341`
   - Impact: HIGH — ambiguous imported setup silently selects a book
   - Recommendation: Implement the restored procedure as the same thin `Derogatory Posting Mgt.` delegate used by W1.

5. **Feature-disabled reversal has a dangling-`else` defect**
   - PRD Reference: ITEM-011, FR-020, FR-021
   - Evidence: `FR/.../FAInsertLedgerEntry.Codeunit.al:566-577`; later consumer `:755-761`
   - Impact: HIGH — disabled legacy reversal omits expected temporary consistency state
   - Recommendation: Use explicit `begin/end` blocks for feature-enabled and disabled branches and cover the disabled path.

6. **Workspace containment is unacceptable**
   - PRD Reference: CON-001 containment intent and the Octane surgical-change requirement
   - Evidence: 84 wholly untraced entries
   - Impact: HIGH review/merge risk
   - Recommendation: Split or revert all report-layout and tooling additions before resubmission.

### Minor Deviations

1. **Shim lifetime comment contradicts RD-009**
   - Expected: retained beyond CLEAN29 until a separately approved cleanup
   - Actual: `UpgradeDerogatoryLinkage.Codeunit.al:13-20` says retained until the “FR CLEAN29 cleanup version”
   - Recommendation: state explicitly that the shim survives CLEAN29.

2. **Proposal reconciliation is not deliverable**
   - Expected: FILE-024 tracked with compatibility statement
   - Actual: `openspec/changes/.../proposal.md:14-15` has the right text but is excluded by repository-local `info/exclude`
   - Recommendation: make the intended documentation artifact reviewable/trackable or formally amend FILE-024.

3. **Persistent test transactions**
   - Expected: isolated, repeatable routing/API tests
   - Actual: five tests use `AutoCommit` without complete teardown
   - Recommendation: restore rollback isolation or add deterministic cleanup justified by the test framework.

## Quality Assessment

### Test Coverage

- **Required EPIC-003 test procedures found**: 7
  - 3 disabled/enabled/CLEAN29 routing tests
  - 2 FR reversal compatibility tests
  - 2 W1 builder compatibility tests
- **Implemented Tests**: 7 source procedures, but 0 compile successfully in their current W1 placement
- **Executed Tests**: 0
- **Validated Test Coverage**: 0%
- **Coverage Gaps**:
  - FR generated-mirror duplicate-book/insurance containment
  - ambiguous relationship through the restored FR public builder
  - feature-disabled reversal temporary-record path
  - normal-book value preservation
  - subscriber/event ordering
  - repeatable cleanup for `AutoCommit` tests

### Validation Performed

1. `altool compile` on `src/Views/W1/Tests/Fixed Asset` with its existing package cache and report-layout generation disabled:
   - **FAIL**
   - 11 relevant `AL0185` errors for missing `Accelerated Depr. Feature` and `Upgrade Derogatory Linkage`
   - No artifact produced
2. `altool compile` on `src/Views/FR/BaseApp`:
   - **BLOCKED**
   - The project has no local `.alpackages`; using the W1 package cache reaches compilation but fails on unavailable .NET assembly probing (`JObject`, `JArray`, `PageNotifier`, `NavUserAccountHelper`, and others)
   - No artifact produced; this is an environment blocker, not evidence of FR success
3. `git diff --check` on staged and unstaged text:
   - **PASS**
4. Branch CI query:
   - `gh run list` returned no runs for the current branch
5. Runtime/publish validation:
   - Not run because compilation is failing and no Business Central test service evidence was available

### Documentation

- **Required Updates**: FILE-024 proposal reconciliation and RD-009 shim-lifetime documentation
- **Completed Updates**: Correct compatibility statement exists only in ignored local proposal text
- **Missing Documentation**: Trackable FILE-024 update; corrected shim lifetime
- **Documentation Completeness**: 0% deliverable

### Performance & Constraints

- No new algorithmic abstraction or persistent configuration was introduced.
- The required indexed link validation remains directly before insert.
- No representative timing or runtime evidence exists.
- Direct `FindFirst()` in the FR compatibility builder is primarily a correctness failure; it also bypasses the intended unique-resolution contract.

## Risk Assessment

| Risk | Status | Mitigation | Notes |
|------|--------|------------|-------|
| RISK-002 | ❌ UNADDRESSED | Guard both duplicate dispatchers for generated mirrors and add configured coverage | FR override diverges from W1 containment. |
| RISK-004 | ⚠️ PARTIAL | Central path is link-first; repair disabled reversal branching and execute compatibility cases | The staged FR insertion logic contains a disabled-path defect. |
| RISK-008 | ❌ UNADDRESSED | Restore APIs through true delegates/overloads and compile consumers | Signatures exist, but behavior and compilation fail. |

RISK-001 and RISK-007 concern later localization epics and were not scored as EPIC-003 gaps. RISK-003/005/006 concern other completed or later epics except where cited as direct dependencies above.

## Recommendations

### Priority 1 - Critical (Must Fix)

1. Move the FR-only test back under `src/Layers/FR/Tests/Fixed Asset`, retain a non-conflicting object ID, and remove FR codeunit references from W1 tests.
2. Restore the normal-book value invariant and correct the underlying legacy/new exclusion-field mismatch.
3. Add generated-mirror duplicate-book/insurance containment to the FR posting override.
4. Replace the FR compatibility builder’s direct lookup with the authoritative manager delegate.
5. Correct the dangling `else` in FR reversal insertion and test the disabled-feature path.
6. Remove/split the 84 wholly untraced workspace entries.

### Priority 2 - Important (Should Fix)

1. Restore rollback isolation or deterministic teardown for the five `AutoCommit` tests.
2. Correct the shim lifetime comment and make FILE-024 deliverable.
3. Run W1, FR, and cumulative CLEAN25-CLEAN29 compiles after the layer fix.
4. Publish and execute the seven focused tests plus the missing containment/value/event cases.

### Priority 3 - Minor (Nice to Have)

1. Remove formatting-only final-blank-line changes from the six FR AL diffs.
2. Keep machine-specific LSP configuration and generated layer manifests out of the product change.

## Metrics Summary

- **Total Applicable Requirements**: 14
- **Requirements Met**: 3 (21%)
- **Requirements Partial**: 3 (21%)
- **Requirements Failed**: 8 (57%)
- **Weighted Completion**: 32%
- **Total EPIC Tasks**: 2
- **Tasks Completed**: 0 (0% strict; 50% weighted partial)
- **Applicable FILE Entries Expected**: 8
- **Files Actually Modified Before Report**: 93
- **Wholly Untraced Files**: 84
- **Files Outside PRD Scope**: 89
- **Test Coverage**: 0% validated execution
- **Documentation Completeness**: 0% deliverable

## Conclusion

EPIC-003 contains recognizable routing and compatibility work, but it does not meet the PRD’s correctness, containment, compilation, testing, or documentation gates. The current workspace must not be approved. The W1 layer violation, accounting assertion regression, FR generated-mirror side effects, policy bypass, and disabled reversal defect are must-fix issues before another review.

## Appendix

### Files Reviewed

#### Staged workspace entries (18)

1. `.github/lsp.json`
2. `src/Layers/FR/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al`
3. `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAGetJournal.Codeunit.al`
4. `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertGLAccount.Codeunit.al`
5. `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`
6. `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlCheckLine.Codeunit.al`
7. `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`
8. `src/Layers/W1/.view/layered_view_files.json`
9. `src/Layers/W1/BaseApp/.config/octane.yaml`
10. `src/Layers/W1/BaseApp/.github/.octane-metadata.json`
11. `src/Layers/W1/BaseApp/.github/agents/Octane.SddCoder.agent.md`
12. `src/Layers/W1/BaseApp/.github/agents/Octane.SddPlanner.agent.md`
13. `src/Layers/W1/BaseApp/.github/docs/scenarios/spec-driven-development.md`
14. `src/Layers/W1/BaseApp/.github/octane/installed-scenarios.json`
15. `src/Layers/W1/BaseApp/docs/projects/redesign-derogatory-mirroring/redesign-derogatory-mirroring.req.md`
16. `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al`
17. `src/Layers/FR/Tests/Fixed Asset/UTDerogatoryLinkageUpgrade.Codeunit.al` → `src/Layers/W1/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al`
18. `src/Layers/W1/Tests/Fixed Asset/UTTABFADerogatoryDepr.Codeunit.al`

#### Unstaged RDLC entries (10)

1. `src/Layers/FR/BaseApp/Sales/Document/StandardSalesDraftInvoice.rdlc`
2. `src/Layers/FR/BaseApp/Sales/History/StandardSalesCreditMemo.rdlc`
3. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryAvailability.rdlc`
4. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryPurchaseOrders.rdlc`
5. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryTransactionDetail.rdlc`
6. `src/Layers/W1/BaseApp/Inventory/Reports/ItemAgeCompositionValue.rdlc`
7. `src/Layers/W1/BaseApp/Inventory/Reports/ItemExpirationQuantity.rdlc`
8. `src/Layers/W1/BaseApp/Manufacturing/Reports/InventoryValuationWIP.rdlc`
9. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesOrderConf.rdlc`
10. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesQuote.rdlc`

The RDLC changes remove unused GLN fields, add/reorder generated parameters and dataset fields, rename generated dataset fields, or alter serialization. No change traces to EPIC-003.

#### Unstaged DOCX entries (65)

1. `src/Layers/FR/BaseApp/Sales/Document/StandardSalesDraftInvoice.docx`
2. `src/Layers/FR/BaseApp/Sales/History/StandardSalesCreditMemo.docx`
3. `src/Layers/FR/BaseApp/Sales/History/StandardSalesInvoice.docx`
4. `src/Layers/W1/BaseApp/CRM/DefaultEmailMergeDoc.docx`
5. `src/Layers/W1/BaseApp/CRM/Reports/ContactCoverSheet.docx`
6. `src/Layers/W1/BaseApp/Finance/Deferral/DeferralSummaryGL.docx`
7. `src/Layers/W1/BaseApp/Finance/Deferral/DeferralSummaryPurchasing.docx`
8. `src/Layers/W1/BaseApp/Finance/Deferral/DeferralSummarySales.docx`
9. `src/Layers/W1/BaseApp/Finance/FinancialReports/FinRepPackageExportEmail.docx`
10. `src/Layers/W1/BaseApp/Finance/FinancialReports/FinancialReportExportEmail.docx`
11. `src/Layers/W1/BaseApp/Inventory/Item/ItemGTINLabel.docx`
12. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryCustomerSales.docx`
13. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryOrderDetails.docx`
14. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryPurchaseOrders.docx`
15. `src/Layers/W1/BaseApp/Inventory/Reports/InventorySalesBackOrders.docx`
16. `src/Layers/W1/BaseApp/Inventory/Reports/InventoryVendorPurchases.docx`
17. `src/Layers/W1/BaseApp/Inventory/Reports/ReferenceNoLabel.docx`
18. `src/Layers/W1/BaseApp/Inventory/Tracking/LotNoLabel.docx`
19. `src/Layers/W1/BaseApp/Inventory/Tracking/SNLabel.docx`
20. `src/Layers/W1/BaseApp/Manufacturing/Document/OutputItemLabel.docx`
21. `src/Layers/W1/BaseApp/Manufacturing/Reports/CapacityTaskList.docx`
22. `src/Layers/W1/BaseApp/Manufacturing/Reports/InventoryValuationWIP.docx`
23. `src/Layers/W1/BaseApp/Manufacturing/Reports/ProdOrderShortageList.docx`
24. `src/Layers/W1/BaseApp/Manufacturing/Reports/ProdOrderStatisticsWord.docx`
25. `src/Layers/W1/BaseApp/Manufacturing/Reports/QuantityExplosionofBOM.docx`
26. `src/Layers/W1/BaseApp/Manufacturing/Reports/SubcontractorDispatchList.docx`
27. `src/Layers/W1/BaseApp/Manufacturing/Reports/WorkMachineCenterLoad.docx`
28. `src/Layers/W1/BaseApp/Projects/Project/JobQuote.docx`
29. `src/Layers/W1/BaseApp/Projects/Project/JobTaskQuote.docx`
30. `src/Layers/W1/BaseApp/Purchases/Document/StandardPurchaseOrder.docx`
31. `src/Layers/W1/BaseApp/Purchases/Document/StandardPurchaseOrderEmail.docx`
32. `src/Layers/W1/BaseApp/Purchases/Document/StandardPurchaseOrderThemable.docx`
33. `src/Layers/W1/BaseApp/Sales/Customer/StandardCustomerStatementEmail.docx`
34. `src/Layers/W1/BaseApp/Sales/Customer/StandardStatement.docx`
35. `src/Layers/W1/BaseApp/Sales/Document/StandardDraftSalesInvoiceBlue.docx`
36. `src/Layers/W1/BaseApp/Sales/Document/StandardDraftSalesInvoiceBlueThemable.docx`
37. `src/Layers/W1/BaseApp/Sales/Document/StandardDraftSalesInvoiceEmail.docx`
38. `src/Layers/W1/BaseApp/Sales/Document/StandardOrderConfirmationEmail.docx`
39. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesOrderConf.docx`
40. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesOrderConfThemable.docx`
41. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesProFormaInv.docx`
42. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesQuote.docx`
43. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesQuoteBlue.docx`
44. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesQuoteBlueThemable.docx`
45. `src/Layers/W1/BaseApp/Sales/Document/StandardSalesQuoteEmail.docx`
46. `src/Layers/W1/BaseApp/Sales/History/SimpleSalesReturnReceipt.docx`
47. `src/Layers/W1/BaseApp/Sales/History/StandardSalesCreditMemoEmail.docx`
48. `src/Layers/W1/BaseApp/Sales/History/StandardSalesCreditMemoThemable.docx`
49. `src/Layers/W1/BaseApp/Sales/History/StandardSalesInvoiceBlueSimple.docx`
50. `src/Layers/W1/BaseApp/Sales/History/StandardSalesInvoiceBlueSimpleThemable.docx`
51. `src/Layers/W1/BaseApp/Sales/History/StandardSalesInvoiceDefEmail.docx`
52. `src/Layers/W1/BaseApp/Sales/History/StandardSalesInvoiceVatSpec.docx`
53. `src/Layers/W1/BaseApp/Sales/History/StandardSalesReturnRcpt.docx`
54. `src/Layers/W1/BaseApp/Sales/History/StandardSalesReturnRcptBlue.docx`
55. `src/Layers/W1/BaseApp/Sales/History/StandardSalesReturnRcptBlueThemable.docx`
56. `src/Layers/W1/BaseApp/Sales/History/StandardSalesShipment.docx`
57. `src/Layers/W1/BaseApp/Sales/History/StandardSalesShipmentBlue.docx`
58. `src/Layers/W1/BaseApp/Sales/History/StandardSalesShipmentBlueThemable.docx`
59. `src/Layers/W1/BaseApp/Sales/Reminder/DefaultReminderEmail.docx`
60. `src/Layers/W1/BaseApp/Sales/Reports/CustomerItemSales.docx`
61. `src/Layers/W1/BaseApp/Sales/Reports/CustomerOrderDetail.docx`
62. `src/Layers/W1/BaseApp/Sales/Reports/CustomerOrderSummary.docx`
63. `src/Layers/W1/BaseApp/Sales/Reports/SalespersonCommission.docx`
64. `src/Layers/W1/BaseApp/Sales/Reports/SalespersonSalesStatistics.docx`
65. `src/Layers/W1/BaseApp/System/Notifications/NotificationEmail.docx`

DOCX ZIP/XML comparison found no changed embedded media payload. Fifty-one packages retained equivalent visible `word/document.xml`; fourteen also changed normalized document/header/footer/endnote XML. None maps to EPIC-003.

#### Relevant unchanged current-tree files inspected

- `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al`
- `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al`
- `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`
- `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al`
- `src/Layers/FR/BaseApp/FixedAssets/Depreciation/FADepreciationBook.Table.al`
- `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`
- `src/Layers/W1/Tests/Fixed Asset/app.json`
- `.github/AL-Go-Settings.json`
- `build/projects/Apps W1/.AL-Go/settings.json`
- `build/projects/Apps FR/.AL-Go/settings.json`
- ignored local `openspec/changes/redesign-derogatory-mirroring/proposal.md`

### Tools Used

- Code search patterns: `MakeDerogatoryFAJnlLine`, `MakeDerogFAJnlLine`, `InsertFARevEntryForDerog`, `InsertMaintRevEntryForDerog`, `Accelerated Depr. Feature`, `Upgrade Derogatory Linkage`, `DuplicateFAJnlLine`, `DuplicateGenJnlLine`, codeunits 134167/134194
- Git methods: full staged/unstaged status, name/status/numstat, rename detection, full text diffs, ignored-file check, `diff --check`
- AL validation: `altool compile` against W1 Fixed Asset tests and FR BaseApp; package/dependency inspection
- Binary validation: DOCX ZIP member/XML comparison and RDLC XML/text diff inspection
- CI validation: `gh run list` for the current branch
- Independent reviews: mandated deep implementation and requirements/quality SddCoder subreviews, followed by targeted compiler verification

## Remediation Record (2026-08-10)

All actionable EPIC-003 findings were fixed test-first and re-verified with the AL MCP tools against the local W1 (`Navision_navagent2`) and French (`navagent2_FR`) services. Commits are prefixed `EPIC-003:`.

| Finding | Resolution | Evidence |
|---------|-----------|----------|
| Critical 1 - W1 Fixed Asset tests do not compile | Codeunit 134194 moved back to `src/Layers/FR/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al`; French feature dependency removed from W1 codeunits 134149 and 134166 | `al_getdiagnostics` on W1 Tests-Fixed Asset: 11 `AL0185` before, 0 after; `al_build` of W1 Tests-Fixed Asset succeeds |
| Critical 2 - Generated mirrors invoke duplicate-book/insurance behavior | French `FA Jnl.-Post Line` clears the copied duplication/insurance fields and guards both `DuplicateDeprBook` dispatchers for `Generated Mirror` | `GeneratedMirrorDoesNotRunDuplicateBookDispatcher`: "Expected:<1> Actual:<2>" before, pass after |
| Critical 3 - Accounting regression masked by the test | Restored `AcqCostAmount` in codeunit 134149 and aligned the legacy/new exclusion fields in French insertion before CLEAN29 | `NormalBookValueExcludesDerogatoryEntry`: "Expected:<1,000> Actual:<700>" before, pass after; codeunit 134149 42/42 on W1 |
| Critical 4 - FR public compatibility API bypasses central policy | `MakeDerogatoryFAJnlLine` is now the same thin `Derogatory Posting Mgt.` delegate as W1 | `PublicDerogatoryBuilderRejectsAmbiguousRelationship`: "An error was expected inside an ASSERTERROR statement" before, pass after |
| Critical 5 - Feature-disabled reversal dangling `else` | Explicit begin/end branches; the disabled branch evaluates the legacy `Derogatory Calculation` relationship | `DisabledFeatureReversalTracksTemporaryConsistencyEntry`: "Reversal found a FA Ledger Entry without a matching G/L Entry." before, pass after |
| Critical 6 - Workspace containment | Only traced EPIC-003 product/test/doc files were committed. The report layouts, `.github/lsp.json`, `src/Layers/W1/.view/**`, the Octane scaffolding and the requirements artifact were left untouched in the workspace and are not part of any commit | `git show --stat` for each `EPIC-003:` commit |
| Minor 1 - Shim lifetime comment | `Upgrade Derogatory Linkage` documents retention beyond CLEAN29 | Codeunit summary |
| Minor 2 - FILE-024 not deliverable | Formal resolution recorded in the PRD Files section: `openspec/` is excluded by `.git/modules/BCApps/info/exclude`, so the tracked PRD carries the authoritative compatibility statement | PRD FILE-024 |
| Minor 3 - Persistent test transactions | Rollback isolation is impossible for the posting tests: the framework rejects Commit under `AutoRollback`. They keep `AutoCommit` and now capture and restore the French feature state deterministically | Pre-fix run failed all posting tests with "Tests cannot call the Commit function if TransactionModel property is set to AutoRollback." |
| Priority 3 - Formatting-only diffs | The final-blank-line deletions in the six French AL files were reverted | `git show` of the dedicated commit |

Additional defects found and fixed while re-validating: `AA0005` in `FAInsertGLAccount.Codeunit.al` and `AA0215` for the relocated test file blocked every French build; and the cumulative `CLEAN25`-`CLEAN29` compile reported three `AL0792` and four `AA0137` errors for declarations that only the excluded legacy implementation uses.

Validation summary:

- `al_compile` over the four projects: zero diagnostics without CLEAN symbols and with `CLEAN25`-`CLEAN29`.
- `al_build`: W1 BaseApp, W1 Tests-Fixed Asset, FR BaseApp, FR Tests-Fixed Asset succeed; FR Tests-Fixed Asset also succeeds under CLEAN25-CLEAN29.
- Runtime: codeunit 134194 16/16 on the French service; codeunits 134149 (42/42) and 134166 (24/24) on the W1 service.
- Open limitation: `al_build` of the FR base application under CLEAN25-CLEAN29 fails during package generation and exposes no diagnostic through the AL MCP tools; no direct `altool`/dispatch build was substituted. The packaged Clean build stays an ITEM-023 AL-Go gate.
- Open gap outside EPIC-003: W1 codeunit 134149 still fails inside the composed French test app while the French feature is disabled, because the W1 suite configures the central `Integration G/L - Derogatory` field. Tracked under EPIC-008 (ITEM-019/ITEM-021); the equivalent French invariant is covered by codeunit 134194.
