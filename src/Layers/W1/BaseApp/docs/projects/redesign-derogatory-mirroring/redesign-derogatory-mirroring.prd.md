---
goal: Complete deterministic derogatory depreciation mirroring across W1, localization, reversal, and French upgrade paths
version: 1.0
date_created: 2026-08-05
last_updated: 2026-08-12
owner: Business Central Fixed Assets
tags: [feature, fixed-assets, derogatory-depreciation, posting, reversal, upgrade, localization]
---

# Introduction

This plan completes the partially implemented redesign of derogatory depreciation mirroring. It establishes `Derogatory Posting Mgt.` as the single policy authority, creates exactly one explicitly linked tax-book counterpart for every eligible FA or maintenance source, makes reversal use persisted links, removes localization double producers, and safely links French historical entries. The expected impact is posting-path-independent accounting behavior, deterministic reversal, and a non-destructive, observable French upgrade.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Cross-reference conventions**: This document uses standardized prefixes for traceability — `FR-` (functional requirements), `NFR-` (non-functional requirements), `FM-` (failure modes), `AC-` (acceptance criteria), and `RD-` (resolved decisions). Identifiers from `redesign-derogatory-mirroring.req.md` are referenced directly.

| Workflow Todo | Status | Completion evidence |
|---------------|--------|---------------------|
| Purpose Review | Completed | Requirements FR-001 through FR-022, NFR-001 through NFR-008, FM-001 through FM-013, assumptions, alternatives, and AC-001 through AC-037 were analyzed. |
| Deep Research | Completed | AL semantic definitions, references, call graphs, localization overrides, upgrade paths, tests, and AL-Go build metadata were inspected across W1, FR, and affected localizations. |
| Draft the Plan | Completed | Architecture, decisions, traceability, files, tests, release gates, and atomic implementation items are populated below. |
| Review and Refine | Completed | An independent SddPlanner compliance review identified reversal, corrective-upgrade, localization, CLEAN29, compatibility, event, and file-specificity gaps; all blocking and high-severity findings were resolved in this version. |
| PRD Review | DONE | EPIC-001 through EPIC-003 requirements, traceability, files, tests, dependencies, constraints, and pre-existing worktree changes were reviewed. |
| Implementation | DONE | EPIC-001 posting/linkage invariants, EPIC-002 link-authoritative reversal, and EPIC-003 French routing/API compatibility were completed with focused tests and W1/FR compilation. |
| Review | DONE | The independent EPIC-003 review reopened the epic as NON_COMPLIANT. All actionable findings were fixed test-first on 2026-08-10, the four normal compile/build targets and the cumulative CLEAN25-CLEAN29 compile pass, and the focused French and W1 suites were published and executed (134194: 17/17, 134149: 42/42, 134166: 24/24). |

## 1. Goals and Non-Goals

- **Goal 1**: Every eligible FA or maintenance source MUST create exactly one linked derogatory-book counterpart, independent of posting path or localization.
- **Goal 2**: Generated mirrors and their automatic companions MUST be contained, captured, linked, and reversible without recursive or configurable duplication side effects.
- **Goal 3**: Reversal MUST locate new counterparts through persisted links before consulting mutable setup.
- **Goal 4**: French historical linkage MUST be prerequisite-aware, mutually unique, idempotent, non-destructive, and observable.
- **Goal 5**: The affected W1, FR, and localization implementation MUST compile and pass focused accounting regression tests, including CLEAN29.
- **Non-Goal 1**: The implementation MUST NOT support one normal depreciation book mapping to multiple derogatory books.
- **Non-Goal 2**: The implementation MUST NOT change accelerated-depreciation formulas, posting accounts, report results, or supported FA posting types.
- **Non-Goal 3**: The implementation MUST NOT redesign the configurable `Duplicate Depr. Book` capability beyond suppressing it for generated mirrors.
- **Non-Goal 4**: The implementation MUST NOT introduce a table or setup option for upgrade outcome counters.

### In Scope

- W1 setup validation, policy, posting context, ledger linkage, automatic companions, acquisition adjustments, and reversal.
- Removal or neutralization of active `Is Derogatory` outer producers in APAC, BE, CH, ES, FI, IT, NA, NO, and RU, plus semantic verification of DACH, GB, NL, and SE.
- FR feature-disabled legacy routing, feature-enabled centralized routing, CLEAN29 exclusion, historical linkage, compatibility procedures, and telemetry.
- W1/FR/localization tests, standard builds, CLEAN29 build, runtime suites, and ledger/G/L verification.

### Out of Scope (deferred)

- One-to-many derogatory-book relationships — incompatible with the existing single-code FlowField and FR-001.
- New-entry heuristic reversal — prohibited by FR-019; only marked French legacy sources may use the fallback.
- Physical consolidation of both acquisition execution adapters — AL posting transaction state requires the existing thin general-journal and FA-journal adapters.
- Removal of the French upgrade shim at CLEAN29 — ambiguous historical entries require it beyond that cleanup boundary.

## 2. Terminology

| Term | Definition |
|------|------------|
| Source | An eligible normal-book FA or maintenance posting executed with posting role `Source`. |
| Generated mirror | The single tax-book counterpart produced by the centralized workflow; it cannot produce another mirror. |
| Link | The counterpart-side `"Derogatory Source Entry No."` value identifying its normal-book source ledger entry. |
| Automatic companion | A catch-up, acquisition-cost, custom-depreciation, or salvage entry created as part of a source posting. |
| Mutual uniqueness | A historical source has exactly one candidate and that candidate has exactly one source in the complete candidate graph. |
| Active localization | A localization with an `Is Derogatory` consumer in its `Gen. Jnl.-Post Line` implementation. |
| CLEAN29 | The compilation symbol that excludes the superseded French legacy implementation. |
| Corrective upgrade | A forward-only rerunnable linkage pass that may rebuild links/markers but never changes accounting amounts. |

## 3. Solution Architecture

The implementation uses one policy boundary and one-way persisted links:

1. `FA Jnl.-Post Line` posts the source and captures all inserted primary and automatic ledger identities.
2. `Derogatory Posting Mgt.` resolves the single relationship, determines eligibility, builds counterpart lines, prepares acquisition adjustments, and validates link integrity.
3. The same shared boundary recursively posts a `Generated Mirror` context with duplicate-book and insurance side effects disabled.
4. `FA Insert Ledger Entry` returns inserted identities and rejects invalid or duplicate links.
5. Reversal searches the dedicated link key first, creates the normal reversal, and links the tax-book reversal to that new normal reversal. If no link exists, a marked legacy source uses the fallback; an unmarked source errors only when current centralized eligibility proves that a counterpart is required, otherwise reversal proceeds without a counterpart.
6. FR upgrade code builds complete FA and maintenance candidate graphs in memory, writes only mutually unique links, marks ambiguous sources, emits six outcome counts, and sets the upgrade tag only after prerequisites and writes succeed.
7. Localization outer producers are removed or bypassed so inherited W1 posting remains the only mirror producer.

```mermaid
flowchart LR
    A[Purchase, general journal, or FA journal] --> B[FA Jnl.-Post Line: Source]
    B --> C[Capture primary and automatic source entries]
    C --> D[Derogatory Posting Mgt.]
    D -->|ineligible| E[No mirror]
    D -->|eligible| F[FA Jnl.-Post Line: Generated Mirror]
    F --> G[Validate and insert linked FA or maintenance entries]
    G --> H[Persist source entry number on counterpart]
    H --> I[Link-first reversal]
    J[FR historical ledgers] --> K[Complete candidate graph]
    K -->|mutually unique| L[Persist link]
    K -->|multiple candidates| M[Mark legacy ambiguous]
    K -->|no candidate| N[Count missing]
```

The schema remains one-way: source entries retain a zero link; counterpart entries store the source number. FA Key13 and Maintenance Key10 on (`"Derogatory Source Entry No."`, `"Depreciation Book Code"`) MUST serve new-entry posting and reversal lookups. No new persistent object, interface, factory, feature flag, or configuration field is introduced.

## 4. Requirements

**Summary**: The plan implements all 22 functional and eight non-functional requirements from the requirements document. Existing schema and the policy codeunit are retained; incomplete lifecycle, localization, migration, compatibility, and verification behavior is corrected.

**Items**:

| ID | Implementation constraint | Planned items |
|----|---------------------------|---------------|
| FR-001, FR-002 | Enforce one relationship in table validation and reject ambiguous imported data at runtime. | ITEM-001, ITEM-002 |
| FR-003, FR-004 | Retain link schema/keys and make `Derogatory Posting Mgt.` the sole policy authority. | ITEM-001, ITEM-002, ITEM-006 |
| FR-005, FR-006 | Contain generated mirrors and produce them only at `FA Jnl.-Post Line`. | ITEM-003, ITEM-004 |
| FR-007, FR-008 | Insert exactly one validated counterpart and preserve returning/non-returning insertion APIs. | ITEM-005, ITEM-006 |
| FR-009, FR-010 | Capture/link salvage and all automatic-only source/mirror identities. | ITEM-005 |
| FR-011, FR-012 | Keep calculation ownership unchanged and retain only thin acquisition execution adapters. | ITEM-007 |
| FR-013 | Remove or neutralize every active localization outer producer. | ITEM-012, ITEM-013, ITEM-014, ITEM-026 |
| FR-014, FR-015 | Perform link-first FA/maintenance reversal with explicit missing/multiple errors and reversal-chain linkage. | ITEM-008, ITEM-009 |
| FR-016, FR-018 | Sequence relationship transfer before linkage/tagging and make retries duplicate-safe. | ITEM-015, ITEM-017 |
| FR-017, FR-019 | Use complete mutually unique historical matching and marker-gated fallback. | ITEM-016, ITEM-017 |
| FR-020 | Keep feature-disabled FR legacy routing under `not CLEAN29`; use only central routing otherwise; retain the shim. | ITEM-010, ITEM-015 |
| FR-021 | Preserve removed public APIs with source-compatible overloads/delegates. | ITEM-011 |
| FR-022 | Emit six upgrade outcome dimensions without a new table. | ITEM-018 |
| NFR-001, NFR-004 | Prove zero posting-path variance and total-row equality using complete test matrices. | ITEM-019, ITEM-020, ITEM-021 |
| NFR-002 | Use dedicated link keys for new posting and reversal; prohibit heuristic scans for unmarked sources. | ITEM-006, ITEM-008, ITEM-022 |
| NFR-003 | Modify only links/markers in upgrade, provide a forward corrective rebuild, and prove repeated execution changes nothing. | ITEM-016, ITEM-017, ITEM-021, ITEM-025 |
| NFR-005 | Compile W1 BaseApp/tests, FR BaseApp/tests, affected localizations, and FR with CLEAN29. | ITEM-023, ITEM-027, ITEM-028 |
| NFR-006 | Publish/run focused suites and inspect representative FA, maintenance, and G/L results. | ITEM-024 |
| NFR-007 | Preserve public procedures and validate subscriber/event ordering at the central boundary. | ITEM-011, ITEM-020 |
| NFR-008 | Complete AL-semantic and runtime verification for all listed localizations. | ITEM-012, ITEM-013, ITEM-014, ITEM-022, ITEM-026 |
| CON-001 | Authoritative editable source is `src/Layers/**`; generated `src/Views/**` MUST NOT be edited directly. | All items |
| CON-002 | Accounting amounts, posting formulas, and posting-account selection MUST remain unchanged. | ITEM-003 through ITEM-024 |
| GUD-001 | Stable AL object/procedure/field identifiers MUST be used as anchors when line numbers drift. | All items |
| PAT-001 | Existing single-parameter public insertion/reversal procedures MUST delegate to context-aware or returning overloads. | ITEM-006, ITEM-011 |

## 5. Risk Classification

**Risk**: 🔴 HIGH RISK

**Summary**: The change affects accounting posting, reversal, country-layer overrides, database upgrade behavior, and public AL procedures. Static compilation alone cannot establish correctness; release requires runtime ledger and G/L evidence.

**Items**:

- **RISK-001**: A remaining localization outer producer can create an unlinked duplicate. Mitigation: AL semantic reference sweep plus total-row runtime assertions in every active localization.
- **RISK-002**: Generated-mirror recursion or copied control state can create duplicate-book/insurance side effects. Mitigation: clear/bypass those controls before recursive posting and test configured duplication.
- **RISK-003**: Incomplete automatic identity capture can make salvage or automatic-only entries irreversible. Mitigation: return and map every inserted companion identity.
- **RISK-004**: Setup-first reversal can silently bypass linked history. Mitigation: search the persisted link key before any current-setup check; on zero results, apply RD-004.
- **RISK-005**: Greedy historical matching can persist false links. Mitigation: construct the entire bipartite candidate graph and write only mutual one-to-one pairs.
- **RISK-006**: Premature upgrade tagging can strand feature-disabled companies. Mitigation: execute linkage after relationship transfer and tag only after successful completion.
- **RISK-007**: IT and RU contain divergent posting/insertion implementations. Mitigation: treat each as a distinct implementation surface and run its own compile/runtime regression; do not assume the ES edit applies.
- **RISK-008**: Changed public procedures can break dependent apps. Mitigation: restore compatibility overloads/delegates and compile semantic consumers.
- **ASSUMPTION-001**: Field numbers and keys stated in FR-003 are the final schema.
- **ASSUMPTION-002**: Feature-disabled FR companies use legacy behavior until CLEAN29; enabled and CLEAN29 companies use only W1 central behavior.
- **ASSUMPTION-003**: AL-Go Clean mode injects `CLEAN29` from `.github/AL-Go-Settings.json`; product `app.json` MUST NOT be modified.

## 6. Dependencies

**Summary**: The implementation depends only on existing Business Central AL objects, test infrastructure, upgrade tags, feature telemetry, localization layers, and the repository build/publish environment.

**Items**:

- **DEP-001**: W1 `Derogatory Posting Mgt.` codeunit 5869 and `Derogatory Posting Role` enum 5869.
- **DEP-002**: FA Ledger Entry Key13 and Maintenance Ledger Entry Key10 plus fields specified by FR-003.
- **DEP-003**: `AcceleratedDepreciationUpgradeTag` relationship transfer completes before `DerogatoryLinkageUpgradeTag`.
- **DEP-004**: `Feature Telemetry.LogUsage` accepts the six dimensions defined by FR-022.
- **DEP-005**: AL semantic definition/reference tooling is available for the cross-localization sweep.
- **DEP-006**: A Business Central test environment is available to publish W1/FR/localization apps and run focused codeunits.
- **DEP-007**: `.github/workflows/CICD.yaml` and `.github/workflows/_BuildALGoProject.yaml` compile projects selected from the `build/projects/Apps W1/.AL-Go/settings.json`, `Apps FR`, `Apps APAC`, `Apps BE`, `Apps CH`, `Apps DACH`, `Apps ES`, `Apps FI`, `Apps GB`, `Apps IT`, `Apps NA`, `Apps NL`, `Apps NO`, `Apps RU`, and `Apps SE` equivalents; Clean mode injects `CLEAN29` from `.github/AL-Go-Settings.json`.

## 7. Quality & Testing

**Summary**: Tests are layered as schema/unit validation, posting/reversal/upgrade integration matrices, semantic localization verification, compilation, runtime execution, and final ledger/G/L inspection. Assertions MUST count all tax-book rows as well as linked rows.

**Items**:

- **TEST-001**: Extend codeunit 134166 to cover relationship validation, ambiguous runtime resolution, link-validation errors, generated-mirror containment, and insertion overload identities.
- **TEST-002**: Extend codeunit 134149 and related W1 FA suites with purchase/general/FA journal, maintenance, G/L on/off, no-asset-book, automatic-only, salvage, final, negative, acquisition, and total-row cases.
- **TEST-003**: Add FA and maintenance reversal cases for setup removal/change, missing/multiple/already-reversed counterparts, two-step reversal, reversal-of-reversal, and salvage.
- **TEST-004**: Extend FR codeunit 134167 with prerequisite/tag ordering, mutual uniqueness including unequal distance, missing, maintenance code, canceled asset, reversal chains, automatic acquisition adjustments, partial retry, and true repeated execution.
- **TEST-005**: Add localization regressions for APAC, BE, CH, ES, FI, IT, NA, NO, and RU; verify DACH, GB, NL, and SE semantically and compile them.
- **TEST-006**: Compile all required applications and tests, including a dedicated FR build with `CLEAN29`.
- **TEST-007**: Publish and execute all focused suites with 100% pass and inspect representative FA, maintenance, and G/L entries.

### Acceptance Criteria

| ID | Criterion | Verification | Traces To |
|----|-----------|--------------|-----------|
| AC-001 | First relationship assignment succeeds; duplicate, changed-to-occupied, self, chain, and reverse assignments fail with the specified setup errors. | Automated AL tests | FR-001 |
| AC-002 | Runtime relationship resolution rejects two matching derogatory books and posts no counterpart. | Automated AL test | FR-002, FM-001 |
| AC-003 | W1 and FR tables contain the specified fields and indexed keys; sources store zero and counterparts store the source entry number. | Schema validation and automated test | FR-003 |
| AC-004 | Eligibility is false for non-Source roles, missing relationship, or missing tax-book asset record; invalid, inconsistent, and duplicate links are rejected. | Automated AL tests | FR-004, FM-002, FM-011 |
| AC-005 | A generated mirror creates no recursive mirror, duplicate-book entry, or insurance side effect. | Automated AL test | FR-005 |
| AC-006 | Purchase invoice, general journal, and FA journal inputs converge on the central boundary and each produce exactly one counterpart; raw internal insertion produces none. | Posting-path matrix | FR-006, NFR-001 |
| AC-007 | Each eligible FA and maintenance source has one total tax-book row and one linked row; a second insertion fails. | Automated AL tests | FR-007, FM-005 |
| AC-008 | Existing insertion callers compile unchanged and returning overloads yield the inserted non-zero FA/maintenance identity. | Compilation and unit tests | FR-008 |
| AC-009 | Every source automatic companion, including salvage, has exactly one linked mirror companion and reverses through that link. | Automated AL test | FR-009, FM-009 |
| AC-010 | A depreciation posting with no primary entry still produces linked mirror entries for all automatic source entries. | Automated AL test | FR-010 |
| AC-011 | Acquisition-cost depreciation posts the calculated source and one counterpart with G/L integration on and off; adapters perform no policy or amount calculation. | Automated AL tests and code inspection | FR-011 |
| AC-012 | Normal, final, negative, acquisition, and automatic-only calculations preserve amounts and create at most one counterpart per eligible source line. | Automated AL tests | FR-012 |
| AC-013 | Every active localization produces one total counterpart; no path invokes both central and outer producers; declare-only layers have no semantic consumer. | AL semantic sweep and runtime tests | FR-013, NFR-008, FM-005 |
| AC-014 | FA and maintenance reversal locate linked history despite setup removal/change and create exactly one linked tax-book reversal. With no link, marked legacy uses fallback; an unmarked currently eligible source raises missing; an unmarked currently ineligible source reverses without a counterpart. | Automated AL tests | FR-014, FM-010 |
| AC-015 | A currently eligible unmarked source with no counterpart and a source with multiple counterparts raise their explicit errors; reversal-of-reversal preserves reversal marks and links. | Automated AL tests | FR-015, FM-003, FM-004 |
| AC-016 | Relationship transfer precedes linkage; a disabled-to-enabled or CLEAN29 transition links history; the tag is written only after success. | FR upgrade tests | FR-016, FM-006 |
| AC-017 | Upgrade links only mutually unique full-identity pairs, includes maintenance code/canceled assets/reversal chains/primary automatic Derogatory adjustments, and changes no amount. | FR upgrade tests and before/after comparison | FR-017, NFR-003, FM-007, FM-012 |
| AC-018 | A partial or repeated pass creates no additional link or marker change when the established outcome is already valid. | FR upgrade tests | FR-018, NFR-003, FM-008 |
| AC-019 | Ambiguous sources are marked and unlinked; only marked legacy sources use heuristic reversal; new W1 sources never use it. | Automated AL tests | FR-019 |
| AC-020 | Disabled FR uses only the guarded legacy builder; enabled/CLEAN29 uses only central posting; CLEAN29 excludes legacy code; shim documentation states post-CLEAN29 retention. | Automated tests, compilation, documentation review | FR-020 |
| AC-021 | Removed/signature-changed public procedures have compatible overloads/delegates and all semantic consumers compile. | AL semantic sweep and compilation | FR-021, NFR-007, FM-013 |
| AC-022 | Each completed upgrade emits matching `FALinked`, `FAAmbiguous`, `FAMissing`, `MaintenanceLinked`, `MaintenanceAmbiguous`, and `MaintenanceMissing` counts. | Automated test and telemetry inspection | FR-022 |
| AC-023 | New-entry counterpart/reversal resolution performs one indexed lookup and no document/amount heuristic scan. | AL code inspection and representative timing | NFR-002 |
| AC-024 | All specified posting, reversal, depreciation, localization, and upgrade matrices assert total rows and links. | Test-suite inspection | NFR-004 |
| AC-025 | W1 BaseApp/tests, FR BaseApp/tests, affected localization apps/tests, and FR CLEAN29 compile with zero errors. | Build logs | NFR-005 |
| AC-026 | Focused published suites pass 100%; inspected ledgers/G/L have correct links, reversal chains, values, and counts with no duplicate mirrors. | Runtime execution and ledger evidence | NFR-006 |
| AC-027 | `Derogatory Posting Mgt.` exposes no mutable integration event. Generic events `OnBeforeFAJnlPostLine`, `OnBeforeGenJnlPostLine`, `OnBeforePostDeprUntilDate`, `OnPostFixedAssetOnBeforeInsertEntry`, and `OnPostMaintenanceOnBeforeInsertEntry` retain ordering; none may mutate posting role/link identity after validation, and final link validation runs immediately before insert. | Semantic inspection and subscriber regression | NFR-007 |

## 8. Security Considerations

- **Data handling**: Ledger entry numbers and telemetry counts are business data but contain no credentials. Telemetry MUST contain aggregate counts only, not FA numbers, document numbers, amounts, or customer data.
- **Input validation**: Imported or historical relationship/link inconsistencies MUST fail through ambiguity, source-existence, identity, and duplicate checks before writes.
- **Access control**: Existing posting, reversal, feature-management, and upgrade permission boundaries MUST remain unchanged; no new public entry point or permission set is required.
- **Secrets**: No secrets, credentials, tokens, or connection strings are introduced.

## 9. Deployment & Rollback

1. Merge product and test changes only after all builds and focused suites pass.
2. Deploy W1 and localization application changes using the normal application upgrade sequence.
3. In FR companies, transfer the legacy relationship before invoking historical linkage; commit `DerogatoryLinkageUpgradeTag` only after all link/marker writes and telemetry complete.
4. Monitor upgrade telemetry for the six outcome counts. Non-zero ambiguous/missing counts are supported outcomes and MUST be investigated before reversing affected legacy sources; they MUST NOT be auto-linked.
5. After deployment, inspect representative FA, maintenance, and G/L entries for one-to-one links and correct reversal chains.
6. Before production upgrade, rollback MAY restore the prior app/database backup. After linkage has run, rollback MUST be forward-only: retain accounting entries and apply a corrective upgrade that clears/rebuilds only link fields and ambiguity markers. Product rollback MUST NOT attempt to reverse accounting amounts.
7. The French shim MUST remain deployed beyond CLEAN29 until a separately approved cleanup version removes all need for marked-legacy fallback.

## 10. Resolved Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| RD-001 | `FA Jnl.-Post Line` is the sole forward-mirror execution boundary; `Derogatory Posting Mgt.` is the sole policy boundary. | All posting paths converge there while policy remains testable and free of transaction adapters. |
| RD-002 | `FAJnlPostLineWithContext` MUST guard both `DuplicateDeprBook.DuplicateFAJnlLine` and `DuplicateDeprBook.DuplicateGenJnlLine` so neither dispatcher runs for `Generated Mirror`; the existing `Source` sequence remains unchanged. Unused `Reversal` and `Internal` enum values remain unwired. | Both dispatchers can create insurance and explicit/list duplication, so guarding them before invocation is deterministic and smaller than clearing copied fields. |
| RD-003 | Automatic companion identities are captured individually and mapped by companion role, including salvage. | A single primary identity cannot represent automatic-only or multi-companion posting shapes. |
| RD-004 | Reversal first searches links globally. One result is reversed regardless of current setup; more than one errors. With zero results, a marked legacy source may use fallback; an unmarked source is evaluated by current centralized eligibility and raises `MissingDerogatoryCounterpartErr` only when eligible, otherwise it reverses without a counterpart. | Persisted history survives setup changes, while a zero link alone cannot distinguish a legitimate never-eligible source from corruption. |
| RD-005 | Historical matching uses a complete in-memory bipartite candidate graph and mutual one-to-one uniqueness; entry-number proximity is not identity. | Greedy proximity can persist objectively false accounting relationships. |
| RD-006 | Public procedures removed or changed by the branch are restored through delegates/overloads rather than documented as new breaking changes. | The stated redesign only identifies `Is Derogatory` as intentionally breaking and source compatibility is cheaper and safer here. |
| RD-007 | IT and RU are fully in scope as independent divergent posting surfaces, not deferred. | FR-013/NFR-008 require every active localization to satisfy exactly-one production. |
| RD-008 | FR linkage emits telemetry only and introduces no persistent counter table. | Counts are operational evidence, not application state. |
| RD-009 | The FR linkage shim survives CLEAN29; the legacy posting implementation does not. | Marked ambiguous history may still require fallback after the posting cleanup boundary. |
| RD-010 | CLEAN29 validation uses AL-Go `Clean` mode from `.github/AL-Go-Settings.json`; FR project selection comes from `build/projects/Apps FR/.AL-Go/settings.json`, and compilation executes through `.github/workflows/_BuildALGoProject.yaml`. | This is the repository-defined symbol-injection mechanism and does not modify product `app.json`. |
| RD-011 | `Upgrade Derogatory Linkage` exposes internal procedure `RunAfterRelationshipTransfer(ForceCorrective: Boolean)`. Feature enablement and CLEAN29 transfer call it after the relationship copy. `false` honors the original linkage tag; `true` ignores that tag and is invoked once by new corrective tag `MS-581204-DerogatoryLinkageCorrectiveUpgradeTag-20260805`. | Existing databases may already carry the premature original tag; a separately tagged forward correction is deterministic and preserves upgrade history. |

## 11. Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Mirror in raw ledger insertion | Covers every insert call automatically. | Creates mirrors for balance, cancellation, disposal, reversal, and internal entries; lacks posting context. | Rejected — use the shared posting boundary. |
| Keep journal `Is Derogatory` coordination | Small localized changes. | Depends on copied mutable buffers/subscribers and permits duplicate producers. | Rejected — remove or neutralize outer producers. |
| Store links on both source and counterpart | Direct bidirectional navigation. | Requires synchronized writes, more schema, and additional failure modes. | Rejected — retain one-way indexed links. |
| Match history by nearest entry number | Simple and fast. | Not an accounting identity and fails unequal-distance ambiguity. | Rejected — use mutual uniqueness over full identity. |
| Fail every ambiguous legacy reversal | Removes heuristic code. | Breaks supported reversal of historical French entries that cannot be linked uniquely. | Rejected — marker-gate the existing fallback. |
| Document all API removals as breaking | Less compatibility code. | Contradicts proposal scope and risks dependent apps. | Rejected — restore delegates/overloads. |
| Fix ES only | Small localization patch. | Leaves equivalent active consumers and divergent IT/RU paths unproven. | Rejected — sweep and test every declared layer. |

## 12. Files

- **FILE-001**: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al` — policy, eligibility, construction, and link validation.
- **FILE-002**: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingRole.Enum.al` — retained posting-role contract.
- **FILE-003**: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al` — central source/mirror lifecycle and automatic identity capture.
- **FILE-004**: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al` — returning insertion, validation, and link-first reversal.
- **FILE-005**: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al` — thin FA acquisition adapter and compatibility delegate.
- **FILE-006**: `src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al` — thin G/L acquisition adapter.
- **FILE-007**: `src/Layers/W1/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al` — relationship validation.
- **FILE-008**: `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al` — FA link/marker schema and key.
- **FILE-009**: `src/Layers/W1/BaseApp/FixedAssets/Maintenance/MaintenanceLedgerEntry.Table.al` — maintenance link/marker schema and key.
- **FILE-010**: `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al` — safe historical graph matching, tagging, and telemetry.
- **FILE-011**: `src/Layers/FR/BaseApp/FixedAssets/Depreciation/AcceleratedDeprFeature.Codeunit.al` — feature-enable sequencing.
- **FILE-012**: `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeAcceleratedDepr.Codeunit.al` — CLEAN29 transfer sequencing.
- **FILE-013**: `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al` — feature gating.
- **FILE-014**: `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al` — legacy-only versus central-only routing.
- **FILE-015**: `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al` — compatibility reversal overloads and legacy fallback.
- **FILE-016**: `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al` — FR schema parity.
- **FILE-017**: Active posting files: `src/Layers/APAC/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/BE/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/CH/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/ES/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/FI/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/NA/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, and `src/Layers/NO/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`.
- **FILE-018**: Divergent active posting files: `src/Layers/IT/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/IT/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/IT/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al`, `src/Layers/RU/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/RU/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, and `src/Layers/RU/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`. IT inherits W1 `FA Insert Ledger Entry`; no IT override exists.
- **FILE-019**: `GenJournalLine.Table.al` declarations at `src/Layers/APAC/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/BE/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/CH/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/DACH/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/ES/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/FI/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/GB/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/IT/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/NA/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/NL/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/NO/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/RU/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, and `src/Layers/SE/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`.
- **FILE-027**: `PostedGenJournalLine.Table.al` compatibility declarations at `src/Layers/APAC/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/BE/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/CH/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/ES/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/FI/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/GB/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/IT/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/NA/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/NL/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/NO/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/RU/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, and `src/Layers/SE/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`. DACH has no override. These fields MUST remain for source compatibility unless semantic references prove removal is safe.
- **FILE-020**: `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al` — total-row, posting, automatic, and reversal matrix.
- **FILE-021**: `src/Layers/W1/Tests/Fixed Asset/UTTABFADerogatoryDepr.Codeunit.al` — setup, policy, insertion, and containment unit tests.
- **FILE-022**: `src/Layers/FR/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al` — French routing, compatibility, containment and upgrade matrix. Resolution (2026-08-10): the file name matches object name `UT Derogatory Linkage Upg.` because AA0215 rejects `UTDerogatoryLinkageUpgrade.Codeunit.al`, and the object ID is 134194 because 134167 is already used by W1 test codeunit `Copy Price Data Test`.
- **FILE-023**: `src/Layers/ES/Tests/Fixed Asset/ERMFixedAssetsGLJournal.Codeunit.al`, `src/Layers/IT/Tests/Fixed Asset/ERMFixedAssetsGLJournal.Codeunit.al`, and `src/Layers/RU/Tests/Fixed Asset/ERMFixedAssetsGLJournal.Codeunit.al` — local regressions for divergent paths. APAC, BE, CH, FI, NA, and NO MUST execute inherited W1 codeunit 134149 in their composed test projects; no duplicate local test file is created.
- **FILE-029**: `src/Layers/NL/Tests/Fixed Asset/ERMDerogatoryDeclarationNL.Codeunit.al` — NL regression proving inherited W1 posting ignores the retained general-journal declaration and the zero-reference posted-journal declaration is absent.
- **FILE-030**: `src/Layers/FR/BaseApp/FixedAssets/Depreciation/DerogLinkageCorrectiveRun.Codeunit.al` — atomic non-upgrade codeunit wrapper for the forward French linkage corrective rebuild.
- **FILE-024**: `openspec/changes/redesign-derogatory-mirroring/proposal.md` — public compatibility statement reconciliation. Resolution (2026-08-10): `openspec/` is excluded from this repository clone by `.git/modules/BCApps/info/exclude`, so the OpenSpec proposal cannot be delivered as a tracked artifact from this workspace. The compatibility statement is therefore delivered here instead and is authoritative: `Is Derogatory` is the only intentional source-compatibility break; the FA-journal derogatory line builder (`MakeDerogatoryFAJnlLine`) and the former three-parameter French FA/maintenance reversal procedures remain source-compatible through delegates and overloads. FILE-024 is satisfied by this PRD statement and RD-006; the untracked OpenSpec copy already carries the same wording and needs no further change.
- **FILE-025**: `openspec/changes/redesign-derogatory-mirroring/design.md` — shim lifetime and final architectural decisions.
- **FILE-026**: `openspec/changes/redesign-derogatory-mirroring/tasks.md` — implementation and verification status after evidence is complete.

## 13. Simplicity Rationale

- **Scope justification**: EPIC-001 implements FR-001 through FR-012; EPIC-002 implements FR-014/FR-015; EPIC-003 implements FR-020/FR-021; EPIC-004 through EPIC-006 implement FR-013/NFR-008; EPIC-007 implements FR-016 through FR-019, FR-022, and NFR-003; EPIC-008 implements NFR-001/NFR-004; EPIC-009 implements NFR-005 through NFR-008. EPIC-009 is enabling work that cannot be folded into product epics because release evidence spans every implementation surface.
- **Abstractions check**: No new AL interface, base class, factory, strategy, enum, or table is introduced. The existing policy codeunit and role enum are sufficient. The FR upgrade MAY use temporary records, dictionaries, or lists local to the codeunit to construct its candidate graph; these are implementation data structures, not public abstractions.
- **Configuration check**: No feature flag, setup option, extension point, or persistent configuration is added. CLEAN29 remains a build symbol, and existing French feature state remains the runtime gate.
- **Could this be simpler?**: The simplest patch would fix the confirmed ES duplicate and move reversal lookup ahead of setup checks. That would leave automatic-only/salvage omissions, other active localizations, divergent IT/RU paths, unsafe French matching/tagging, and API breaks unresolved. The proposed plan adds no new persistent architecture; its breadth is required because the exactly-one and reversibility invariants cross all those existing paths.

## 14. Implementation Plan

- EPIC-001: Complete W1 posting and linkage invariants — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-001 | Verify and, only where missing, complete setup-time one-to-one validation, W1/FR schema parity, field editability, and dedicated link keys exactly as required by FR-001 through FR-003; do not renumber existing fields. | DONE | `src/Layers/W1/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al`, `src/Layers/W1/BaseApp/FixedAssets/Maintenance/MaintenanceLedgerEntry.Table.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al` |
| ITEM-002 | Make `Derogatory Posting Mgt.` the exclusive relationship/eligibility/construction/validation policy; runtime resolution MUST reject a second relationship and all direct caller-side relationship filtering MUST be removed. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al` |
| ITEM-003 | In `FAJnlPostLineWithContext`, preserve `Source` behavior but guard both `DuplicateDeprBook.DuplicateFAJnlLine` and `DuplicateDeprBook.DuplicateGenJnlLine` when role is `Generated Mirror`; this prevents their `InsertInsurance` and explicit/list `CreateLine` side effects before execution. Generated mirrors MUST never invoke counterpart production. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingRole.Enum.al`, `src/Layers/W1/BaseApp/FixedAssets/Depreciation/DuplicateDeprBook.Codeunit.al` |
| ITEM-004 | Keep forward production only at `FA Jnl.-Post Line`; continue counterpart processing when either a primary source identity or captured automatic identities exist and prohibit raw insertion from initiating mirrors. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al` |
| ITEM-005 | Extend automatic identity capture so catch-up, acquisition-cost, custom-depreciation, and salvage source entries each map to the correct generated-mirror entry; use returning insertion for salvage and preserve links for automatic-only posting. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al` |
| ITEM-006 | Preserve single-parameter `InsertFA`/`InsertMaintenance` procedures as delegates, return actual identities from overloads, and validate source existence/identity/book/duplicate state with the dedicated link keys before inserting counterparts. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al` |
| ITEM-007 | Keep acquisition amount/line preparation in the manager and retain only execution in the general-journal and FA-journal adapters; keep both `REVIEW(redesign-derogatory-mirroring)` markers and prevent double posting with G/L integration on or off. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al`, `src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al` |

- EPIC-002: Make reversal link-authoritative — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-008 | For FA reversal, query counterparts by persisted source link before current setup. Reverse one result and error on multiple. With zero, use heuristic matching only when the marker is true; otherwise evaluate current `Derogatory Posting Mgt.` eligibility, raising missing only when eligible and performing only the normal reversal when ineligible. Link each tax reversal to the new normal reversal. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al` |
| ITEM-009 | Apply the same link-first algorithm to maintenance, preserve reversal/reversal-of-reversal marks, include automatic salvage companions, and raise explicit missing/multiple errors for non-legacy entries that require a counterpart. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/Maintenance/MaintenanceLedgerEntry.Table.al` |

Implementation notes (2026-08-06): FA and maintenance reversal now perform a dedicated-key lookup by persisted source entry before consulting mutable setup, reject global duplicate links, retain setup-independent marker-gated legacy fallback, and link reversal chains. Direct counterpart reversal preserves its persisted counterpart role even if later setup makes that book a source. Source- and tax-book acquisition reversal resolve the immediately posted automatic salvage companion by its deterministic ledger sequence and validate its complete posting identity before reversal, so shared metadata cannot reverse unrelated companions. W1 BaseApp and Fixed Asset tests compile. After publishing the current W1 packages, all EPIC-002 tests and the complete codeunit 134149 test run passed. The final test updates add transaction boundaries around expected-error rollback checks, allow the intentionally repeated document number in both depreciation books, and preserve the automatic-only depreciation posting date for verification.

- EPIC-003: Correct French runtime routing and compatibility — DONE (reopened by review on 2026-08-08, remediated and re-verified on 2026-08-10)

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-010 | Under `not CLEAN29`, route feature-disabled FR FA-journal posting exclusively through the legacy `"Derogatory Calculation"` builder; route enabled and CLEAN29 builds exclusively through W1 central posting with no nested requirement for both relationship fields. Generated mirrors MUST NOT reach either duplicate-book dispatcher. | DONE | `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAGetJournal.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertGLAccount.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlCheckLine.Codeunit.al` |
| ITEM-011 | Restore source-compatible delegates/overloads for the removed W1 `MakeDerogatoryFAJnlLine` and former three-parameter FR FA/maintenance reversal procedures; reconcile proposal documentation so `Is Derogatory` remains the only intentional break. | DONE | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`, `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al`, `src/Layers/W1/Tests/Fixed Asset/UTTABFADerogatoryDepr.Codeunit.al`, `src/Layers/FR/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al` |

Implementation notes (2026-08-06): Feature-disabled FR FA-journal posting uses only `MakeDerogFAJnlLine`; enabled and CLEAN29 paths remain central-only. Distinct legacy/central relationship tests now prove disabled, enabled, and CLEAN29 routing, with the CLEAN29-only test selected by preprocessor guards. W1 restores `MakeDerogatoryFAJnlLine` as a policy delegate and preserves the former false-result output copy semantics; FR restores the former three-parameter FA/maintenance reversal overloads, and behavior tests require returned reversal entry numbers plus reversal/link effects.

Review remediation notes (2026-08-10): the independent review found EPIC-003 NON_COMPLIANT. Every actionable finding is now resolved and evidenced by a local French and W1 service run.

- Test layering: codeunit 134194 `UT Derogatory Linkage Upg.` is back under `src/Layers/FR/Tests/Fixed Asset` (see FILE-022 resolution) and the French feature dependency is removed from W1 codeunits 134149 and 134166. The eleven `AL0185` diagnostics are gone.
- Generated-mirror containment (RD-002/FR-005): the French `FA Jnl.-Post Line` override now neutralizes the copied duplication and insurance fields and guards both `DuplicateDeprBook` dispatchers for `Generated Mirror`, proven by a configured duplication-book regression.
- Normal-book value (CON-002/Non-Goal 2): the reduced expectation in codeunit 134149 is reverted to `AcqCostAmount`, and French insertion keeps `Exclude Derogatory` and `Derogatory Excluded` aligned before CLEAN29 so the `Book Value` FlowField, the legacy `Derogatory` FlowField and the French projected-value report stay correct in both feature states.
- Compatibility API (FR-002/FR-004/RD-001): the French `MakeDerogatoryFAJnlLine` is a thin `Derogatory Posting Mgt.` delegate and rejects ambiguous relationships.
- Disabled reversal (FR-020/FR-021): the dangling `else` in `FA Insert Ledger Entry` is replaced by explicit begin/end branches that use the legacy relationship field when the feature is disabled; a disabled-path regression covers it.
- Automatic-only and salvage identities (FR-009/FR-010 through the EPIC-001 ITEM-005 dependency): the same range also brings the French posting override to W1 parity for automatic companions, which EPIC-003 needs for FR routing parity. `FA Jnl.-Post Line` captures the automatic salvage source identity through the returning insertion overload and stamps it on the generated-mirror salvage entry (`FR/.../FAJnlPostLine.Codeunit.al:56,565,568-575,580-593`), and both counterpart gates were relaxed to `if (SourceEntryNo = 0) and not HasSourceAutomaticEntries() then exit` so automatic-only postings still produce linked mirrors (`:309,:333`). `FA Insert Ledger Entry` resolves the automatic salvage companion by its deterministic ledger sequence after full identity validation and inserts the linked salvage reversal with the reversal source code (`FR/.../FAInsertLedgerEntry.Codeunit.al:537-545,671-706,707-737,738-752`). W1 already carried the same members from EPIC-001/EPIC-002 (`W1/.../FAJnlPostLine.Codeunit.al:53,298,318,550-578`; `W1/.../FAInsertLedgerEntry.Codeunit.al:527,741-786`), so this is traced FR parity, and `SalvageCounterpartReversalKeepsReversalSourceCode` covers the French path.
- Test isolation: rollback isolation is impossible for the posting tests. The framework fails them with "Tests cannot call the Commit function if TransactionModel property is set to AutoRollback." because `FA Jnl.-Post Batch` commits, so they keep `AutoCommit` and capture/restore the French feature state deterministically instead. The failure path of that restore was completed in the second pass below.
- Shim lifetime (RD-009): `Upgrade Derogatory Linkage` now documents that the shim survives CLEAN29.
- Supporting files: `DepreciationBook.Table.al`, `FAGetJournal.Codeunit.al`, `FAInsertGLAccount.Codeunit.al` and `FAJnlCheckLine.Codeunit.al` select the legacy or central derogatory setup fields by feature state and are part of ITEM-010; the formatting-only final-blank-line deletions were reverted.

Validation (2026-08-10, AL MCP only):

- `al_compile` over W1 BaseApp, W1 Tests-Fixed Asset, FR BaseApp and FR Tests-Fixed Asset: zero diagnostics, both without CLEAN symbols and with the cumulative `CLEAN25`-`CLEAN29` symbols from `.github/AL-Go-Settings.json`.
- `al_build`: W1 BaseApp, W1 Tests-Fixed Asset, FR BaseApp and FR Tests-Fixed Asset succeed; FR Tests-Fixed Asset also succeeds with CLEAN25-CLEAN29.
- Runtime: French service `navagent2_FR` codeunit 134194 is 17/17 pass after the fixes (11 passed / 5 failed before them, with the four new regressions failing exactly on the reported defects); W1 service `Navision_navagent2` codeunit 134149 is 42/42 and codeunit 134166 is 24/24.
- Self-review of the committed work found one more defect in the reviewed staged code: the French salvage reversal path fetched `Source Code Setup` only when it opened a new FA register, so a tax-book salvage counterpart reversal was inserted with a blank source code. It is fixed and covered by `SalvageCounterpartReversalKeepsReversalSourceCode`.
- Correction (2026-08-10, second pass): the marker-gated legacy reversal fallback was changed in this range, not left untouched. `FindLegacyFADerogatoryEntry` and `FindLegacyMaintenanceDerogatoryEntry` lost their resolved-book parameter and now search every depreciation book other than the source book (`FR/.../FAInsertLedgerEntry.Codeunit.al:1025-1049`), and the callers take the counterpart book from the entry they find (`:919,:999`). That is the EPIC-002 W1 behaviour (`W1/.../FAInsertLedgerEntry.Codeunit.al:877-900`) that EPIC-003 compatibility relies on so a legacy reversal still resolves after the relationship is removed (AC-014/AC-019); it is traced parity work, not an untraced redesign. It does leave the following `TestField("Depreciation Book Code", ...)` vacuous, and that assertion is kept identical to W1 rather than diverging here.
- Known limitation: `al_build` of the FR base application with CLEAN25-CLEAN29 fails in package generation and the AL MCP tools expose no diagnostic for it (`al_compile` and `al_getdiagnostics` return none). Direct `altool`/dispatch builds were not substituted. The CLEAN29 evidence for the base application is therefore the zero-diagnostic `al_compile`; the packaged Clean build remains an ITEM-023 AL-Go release gate.
- Known gap outside EPIC-003: W1 codeunit 134149 does not pass inside the composed French test app while the French accelerated-depreciation feature is disabled, because the W1 suite configures `Integration G/L - Derogatory` while the disabled French layer reads the legacy `G/L Integration - Derogatory`. The French regression for the same invariant lives in codeunit 134194. Making the composed French run feature-aware belongs to EPIC-008 (ITEM-019/ITEM-021).

Second-pass remediation (2026-08-10) for the independent review of commit range `78759d0..b7b53617`:

- AutoCommit failure-path isolation: the nine `AutoCommit` tests of codeunit 134194 mutated company-wide French feature state and only restored it after their last assertion, so an assertion or runtime failure committed the toggled state and cascaded into later suites. Each test now runs its body inside `asserterror` - the only AL construct that catches a failing test body while still allowing the database writes these posting tests need - and `RestoreFeatureStateAfterTestBody` restores the captured state, commits it, and only then rethrows the body failure. `TryFunction` cannot be used here ("Call to the function 'MODIFY' is not allowed inside the call to 'RootMethodScope' when it is used as a TryFunction.") and `Codeunit.Run` of the test codeunit cannot either ("You cannot nest the execution of test codeunits."); both were measured on the French service before choosing `asserterror`.
- Failure-path regression: `FailedTestBodyRestoresFeatureState` pins the contract by committing a disabled baseline, failing a body that enables and commits the feature, and asserting the committed state after the rethrow. Without the commit in the guard - the pre-fix behaviour, where the restore never survives the failure - it fails with "Assert.IsFalse failed. The failed test body must not leave the toggled French feature state committed."; with it, codeunit 134194 is 18/18.
- Traceability: the automatic-only/salvage capture and the legacy-fallback alignment recorded above replace the earlier "not changed" statement.
- Diff hygiene: the two new blank lines at EOF that this range introduced in `FR/.../FAJnlPostBatch.Codeunit.al` and `FR/.../FAJnlPostLine.Codeunit.al` are removed, so both files keep the single trailing newline they had at `78759d0`. Markdown two-space hard breaks are left untouched.

Second-pass validation (2026-08-10, AL MCP only):

- `al_compile` over W1 BaseApp, W1 Tests-Fixed Asset, FR BaseApp and FR Tests-Fixed Asset: zero diagnostics; per-file `al_getdiagnostics` on `UTDerogatoryLinkageUpg.Codeunit.al`, `FAJnlPostLine.Codeunit.al` and `FAJnlPostBatch.Codeunit.al` returns nothing at any severity.
- `al_build` and `al_publish` of FR Tests-Fixed Asset against `navagent2_FR` succeed; `al_build` of FR BaseApp succeeds.
- `al_build` of FR Tests-Fixed Asset with the cumulative `CLEAN25`-`CLEAN29` symbols temporarily declared in the test `app.json` succeeds and produces a different package (165,318 against 165,386 bytes), which shows the symbols were applied; `app.json` was restored and the default package rebuilt and republished afterwards.
- Runtime: codeunit 134194 on `navagent2_FR` is 18/18 (17 test methods, one of them new; the runner also reports one aggregate entry). The pre-fix run of the same suite was 16 passed / 2 failed, failing only on the new failure-path regression.

- EPIC-004: Neutralize standard localization outer producers — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-012 | Using AL definition/reference results, remove or bypass the legacy outer producer after inherited central posting in ES and in APAC, BE, CH, FI, NA, and NO; remove now-unused `Is Derogatory` calls/declarations only when semantic references are zero. | DONE | `src/Layers/ES/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/APAC/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/BE/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/CH/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/FI/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/NA/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/NO/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al` |

Implementation and validation notes (2026-08-10): AL definition/reference analysis confirmed that ES, APAC, BE, CH, FI, NA, and NO inherit the W1 central `FA Jnl.-Post Line` producer, so their post-inheritance `Is Derogatory` producers were removed and their acquisition adapters aligned with W1. Compatibility declarations were retained because semantic references remain. The ES total-row regression was added first and failed against the old producers with a duplicate tax-book document; after the production changes, the focused AL MCP run passed 3/3. AL MCP compilation, build, and publish of the supported ES BaseApp and Tests-Fixed Asset projects succeeded with zero diagnostics; codeunit 134453 reported 36 passed and three unrelated pre-existing failures. Per the available-environment constraint, APAC, BE, CH, FI, NA, and NO source changes were completed but not compiled, published, or executed locally; their builds remain covered by the later localization release gate. Independent review returned PASS with no actionable findings.

- EPIC-005: Resolve divergent and declaration-only localizations — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-013 | In IT, remove the `Is Derogatory` producer gate, port W1 unconditional acquisition adapter calls plus role/context, counterpart recursion, persisted links, and automatic identity capture into the IT general-journal/FA posting overrides, and preserve IT batch behavior. IT MUST continue inheriting W1 insertion; no IT insertion override is created. | DONE | `src/Layers/IT/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/IT/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/IT/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al` |
| ITEM-026 | In RU, remove the `Is Derogatory` producer gate, port W1 role/context, counterpart recursion, and automatic identity capture into RU posting overrides, and add W1-compatible returning insertion/link validation and link-first reversal while preserving RU-specific logic. | DONE | `src/Layers/RU/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al`, `src/Layers/RU/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`, `src/Layers/RU/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`, `src/Layers/RU/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al`, `src/Layers/RU/BaseApp/FixedAssets/Maintenance/MaintenanceLedgerEntry.Table.al` |

Implementation and validation notes (2026-08-11): IT and RU `Is Derogatory` producer gates were removed and replaced with centralized `DerogatoryPostingMgt`-based acquisition adapter calls. IT `FAJnlPostLine` and `FAJnlPostBatch` were ported to the W1 `FAJnlPostLineWithContext`/`PostDerogatoryCounterpart` pattern with role/context, persisted links, returning insertion, and automatic identity capture; batch derogatory producer was removed since `FAJnlPostLine` now handles counterpart posting internally. RU `FAJnlPostLine` received the same port. RU `FAInsertLedgerEntry` was extended with returning `InsertFA`/`InsertMaintenance` overloads, `ValidateDerogatoryLink` calls, `InsertReverseEntryWithLink` for link-preserving reversal, `ReverseAutomaticSalvageEntries`/`IsAutomaticSalvageCompanion` for salvage companion reversal, and link-first `InsertFARevEntryForDerog`/`InsertMaintRevEntryForDerog` replacing the old setup-based lookup. RU `FALedgerEntry` and `MaintenanceLedgerEntry` tables required the `"Derogatory Source Entry No."` field and supporting key because RU has full authoritative table overrides. IT/RU regression tests (`AcquisitionCostWithDerogatoryBookCreatesSingleCounterpart`) were added to codeunit 134453. Per the available-environment constraint, IT and RU source changes were not compiled, published, or executed locally; their builds remain covered by the localization release gate (ITEM-028).

- EPIC-006: Verify declaration-only localizations — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-014 | Use AL semantic references to prove DACH, GB, NL, and SE have no active localization posting consumer; remove dormant declarations only if they have no remaining consumer, otherwise retain the declaration and prove inherited W1 posting ignores it. Posted-journal fields remain for compatibility unless their semantic reference count is zero. | DONE | `src/Layers/DACH/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/GB/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/NL/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/SE/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al`, `src/Layers/GB/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/NL/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/SE/BaseApp/Finance/GeneralLedger/Journal/PostedGenJournalLine.Table.al`, `src/Layers/NL/Tests/Fixed Asset/ERMDerogatoryDeclarationNL.Codeunit.al` |

Implementation and validation notes (2026-08-11): AL LSP definition/reference tracing on composed DACH, GB, NL, and SE BaseApp views found three references per general-journal `"Is Derogatory"` field: the declaration and two assignments inside `GetDerogatorySetup`; no posting codeunit references the field. Those declarations and procedures were therefore retained, while the NL regression sets the flag false and requires inherited W1 posting to create exactly one linked tax-book counterpart. DACH has no posted-journal override. The GB, NL, and SE posted-journal fields each had one reference including the declaration and therefore zero consumers; those three dormant declarations were removed. A post-change semantic sweep reports the retained general-journal counts unchanged and no posted-journal declaration in any of the four views.

The NL behavioral regression was added before the product edits. A red behavioral run was not applicable because ITEM-014 verifies already-correct inherited W1 behavior; pre-change AL LSP field presence established the schema assertion's expected failure and the test now pins removal of field 5865 from the NL posted journal. Independent post-change AL LSP sweeps on composed DACH, GB, NL, and SE views confirmed the three retained general-journal references and absence of every posted-journal declaration. The W1 and NL local-environment resolvers passed all pre-flight checks. After the AL MCP workspace was reconciled to NL BaseApp and Tests-Fixed Asset, both projects compiled with zero diagnostics, built, and published to `navagent2_NL`; focused codeunit 134160 passed 3/3. Publish validation first exposed collisions for candidate test codeunit IDs 134195 and 134196 with installed test apps, so the regression uses the verified-free ID 134160.

- EPIC-007: Make French historical migration safe — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-015 | Expose internal `RunAfterRelationshipTransfer(ForceCorrective: Boolean)` on the linkage codeunit. Call it with `false` immediately after feature-enable and CLEAN29 relationship copies in the same upgrade transaction; it MUST verify at least one transferred relationship before work and set the original linkage tag only after all writes and telemetry succeed. Document that the shim survives CLEAN29. | DONE | `src/Layers/FR/BaseApp/FixedAssets/Depreciation/AcceleratedDeprFeature.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeAcceleratedDepr.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`, `openspec/changes/redesign-derogatory-mirroring/design.md` |
| ITEM-016 | Replace greedy writes with complete FA/maintenance candidate graphs using relationship, asset/canceled-asset identity, posting type, amount, document/date/transaction identity, reversal chain, and maintenance code. Include an automatic FA source exactly when `Automatic Entry = true`, posting type is `Depreciation` or `Custom 1`, and an Acquisition Cost sibling exists for the same FA, source book, transaction number, document number, posting date, and document date; exclude entries already serving as counterparts. | DONE | `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al` |
| ITEM-017 | Before candidate selection, retain valid established links; write only mutually unique new links; mark multiple-candidate sources ambiguous; count no-candidate sources missing; ensure a repeated/partial pass changes no valid established outcome and never changes accounting amounts. | DONE | `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al` |
| ITEM-018 | Emit per-run FA and maintenance linked/ambiguous/missing counts through `Feature Telemetry.LogUsage`; include only aggregate dimensions and create no table. | DONE | `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al` |
| ITEM-025 | Add a forward corrective per-company upgrade guarded by tag `MS-581204-DerogatoryLinkageCorrectiveUpgradeTag-20260805`. Within one transaction it MUST select only FR source/counterpart entries in configured relationship pairs, clear only `"Derogatory Source Entry No."` and `"Legacy Derogatory Ambiguous"`, call `RunAfterRelationshipTransfer(true)` to rebuild from the complete graph, emit outcome telemetry, and set the corrective tag after success. Reversal fields, amounts, dates, document identity, and accounting entries MUST remain unchanged. Add before/after, failure rollback, and second-run tests. | DONE | `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/DerogLinkageCorrectiveRun.Codeunit.al`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgTagAcceleratedDepr.Codeunit.al`, `src/Layers/FR/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al` |

Implementation and validation notes (2026-08-11): The French linkage upgrade now exposes `RunAfterRelationshipTransfer`, invoked after both relationship transfers, and keeps the original tag unset until matching and six aggregate outcome telemetry dimensions complete. FA and maintenance pairs are collected into complete candidate graphs before writes; only mutually unique pairs are linked, while contested sources are marked ambiguous and unmatched sources are counted missing. The corrective per-company path is separately tag-gated, clears only link and ambiguity fields in configured pairs, and invokes the rebuild through the internal `Derog. Linkage Corrective Run` rollback boundary. It never changes accounting values, dates, document identities, or reversal fields. The focused French codeunit 134194 runtime suite passed 29/29 after AL MCP publication; AL MCP compile returned zero diagnostics. The AL MCP build operation returned `CompilationFailed` without diagnostics despite that successful compile, so the final packages used for runtime validation were the local final-check packages produced by the existing local build path.

- EPIC-008: Implement deterministic automated coverage — DONE

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-019 | Strengthen `VerifyLinkedCounterparts` to assert total tax-book row count equals expected and linked count, then add purchase/general/FA journal, maintenance, G/L on/off, no-asset-book, automatic-only, salvage, normal/final/negative/acquisition cases. | DONE | `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al` |
| ITEM-020 | Add setup ambiguity, link validation, generated-mirror containment, insertion compatibility, event ordering, link-first reversal, missing/multiple/already-reversed/setup-change/reversal-of-reversal tests. | DONE | `src/Layers/W1/Tests/Fixed Asset/UTTABFADerogatoryDepr.Codeunit.al`, `src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al` |
| ITEM-021 | Extend FR upgrade tests for prerequisite sequencing, true repeated execution, partial recovery, mutual uniqueness including unequal distance, missing, maintenance code, canceled assets, automatic Derogatory acquisition, reversed and reversal-of-reversal pairs, telemetry, and unchanged amounts. Also make the composed French run of W1 codeunit 134149 feature-aware. | DONE | `src/Layers/FR/Tests/Fixed Asset/UTDerogatoryLinkageUpg.Codeunit.al` |

Implementation and validation notes (2026-08-12): `VerifyLinkedCounterparts` now proves that every normal-book source has one link, that the total tax-book row count equals the source count, and that every tax-book row is linked. The W1 matrix adds explicit general-journal, maintenance, missing-tax-asset-book, configured-duplication, returning-insertion, and posting-event ordering cases, strengthens automatic-only and salvage total-row assertions, and applies the total-row invariant to normal, final, negative, and acquisition scenarios. Unit coverage now exercises missing, duplicate, and identity-invalid FA/maintenance links. Existing EPIC-001/EPIC-002 tests continue to cover setup ambiguity, compatibility, containment, link-first reversal, missing/multiple/already-reversed/setup-change, salvage, and reversal-of-reversal behavior.

The French suite adds a true second execution, all six linkage outcome counts passed to telemetry, and unchanged FA/maintenance amounts. Existing EPIC-007 coverage supplies prerequisite/tag sequencing, partial recovery, mutually unique and unequal-distance ambiguity, missing candidates, maintenance-code identity, canceled assets, automatic acquisition adjustments, and reversal chains. The composed French W1 suite detects the French legacy schema without a compile-time FR dependency and enables the centralized feature required by its linked-counterpart contract. Before that adjustment, the fresh composed run of codeunit 134149 reported 6 passed / 36 failed; after the tests were published but before the adjustment, the new focused group reported 2 passed / 6 failed, including expected linked count 1 versus actual 0. Coverage-only cases that codify already-correct behavior have no fabricated red phase.

Validation and review (2026-08-12, AL MCP and AL LSP): W1 and FR BaseApp plus Tests-Fixed Asset compiled with zero errors and both BaseApps and test apps built. The W1 and FR test apps were published; BaseApp publication was not required because EPIC-008 changes only test sources. Runtime passed W1 codeunits 134166 (27/27) and 134149 (48/48), composed FR codeunit 134149 (48/48), and FR codeunit 134194 (32/32). AL LSP references confirmed both `PostDerogatoryCounterpart` overloads are reached only from the source boundaries, returning and compatibility insertion overloads remain referenced, final FA/maintenance validation is called by insertion, the strengthened verifier has ten call sites, and `RunAfterRelationshipTransfer` feeds both linkage count procedures into the six-dimension telemetry call. Self-review found and fixed one coverage gap by applying the total-row verifier to the normal/final/negative/acquisition scenarios; the final targeted and full suites remained green.

Post-implementation review remediation (2026-08-12): The posting-event regression now corrupts the generated counterpart's FA identity after the event, expects final link validation to reject it, and proves the source/counterpart transaction rolls back; its test-first red run failed with `Entry 229 cannot be linked to depreciation book ...` before the harness expected the error. The composed-FR W1 suite now wraps all posting bodies with the proven `asserterror`/sentinel pattern, captures both feature-status row existence and value, and restores or deletes and commits before rethrowing a body failure. The isolation regression's red run reported 48 passed / 2 failed, including `ComposedFrenchFeatureStateIsRestoredBetweenTests`; the corrected suite passes both success and simulated-failure restoration. Automatic-only coverage now also invokes the unfiltered total-row/link verifier, returning insertion tests locate each inserted identity independently, and FR repeated/unchanged-amount tests preserve total FA and maintenance counts after every pass. AL LSP resolved the final validation call to `ValidateDerogatoryLink` and found its four declaration/call references; it also found 47 declaration/call references for the shared feature restore boundary, two for feature enablement, and two for the event-order body. Final AL MCP compile returned zero diagnostics for W1 and FR; both test apps built and published; W1 codeunit 134149 passed 50/50, composed FR codeunit 134149 passed 50/50, and FR codeunit 134194 passed 32/32. No product source changed.

Final isolation review fix (2026-08-12): Running `ComposedFrenchFeatureStateIsRestoredBetweenTests` alone on the composed FR environment failed with the preceding-test assertion (1 passed / 2 failed including runner entries). Its replacement captures the exact feature-status row existence and value, changes the status, executes the successful sentinel cleanup boundary, and asserts exact restoration or deletion in the same test. The order-dependent `WasLastFeatureStateRestored` API and shared flag were removed while the independent simulated-failure regression remained unchanged. AL LSP found the replacement symbol and no old API symbol. Final AL MCP compile returned zero diagnostics for W1 and FR; both test apps built and published; the replacement passed individually on FR (3/3 runner entries), W1 codeunits 134149 and 134166 passed 50/50 and 27/27, and composed FR codeunits 134149 and 134194 passed 50/50 and 32/32.

Remaining confirmed coverage-gap remediation (2026-08-12): The returning raw `InsertFA` and `InsertMaintenance` compatibility case now captures exact tax-book totals before each direct insertion, proves those totals do not change, and proves no ledger row in any book links to either returned identity. Generated-mirror containment now enables automatic insurance posting on the source book, supplies an insurance number, and requires exactly one source-side coverage entry with the source amount and document identity in addition to the existing duplicate-book assertion. FA and maintenance reversal fixtures now require one linked row rather than accepting `FindFirst`, assert one total tax-book row before reversal, and assert exactly two afterward. No product source changed.

The first targeted W1 run honestly reported 8 passed / 2 failed: the new insurance assertion read the cleared post-call FA journal amount as zero while the persisted source coverage entry had its correct nonzero amount, and the runner also reported a wrapper/sentinel result. Capturing the expected source amount/document before posting fixed only the test fixture; the targeted rerun passed 10/10. AL MCP then built and published Tests-Fixed Asset for W1 and FR; full W1 codeunit 134149 passed 50/50, composed FR codeunit 134149 passed 50/50, and FR codeunit 134194 passed 32/32. AL LSP resolved seven declaration/call references for the returning `InsertFA` overload, two for the FA-journal `PostDerogatoryCounterpart` overload (its source boundary and declaration), and nine for the strengthened `FindLinkedFAEntry` helper.

- EPIC-009: Complete semantic, build, and runtime release gates

| Task | Description | Status | Relevant Files |
|------|-------------|--------|----------------|
| ITEM-022 | Run AL semantic definition/reference tracing for `Is Derogatory`, relationship resolution, public compatibility procedures, and new-entry reversal lookup. Record, per APAC/BE/CH/DACH/ES/FI/FR/GB/IT/NA/NL/NO/RU/SE layer, zero dual-producer paths and zero unmarked heuristic callers in the implementation evidence. | Not Started | `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`, `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al` |
| ITEM-023 | After pushing the implementation branch, execute `$Branch = git branch --show-current; gh workflow run --repo microsoft/BCApps --ref $Branch CICD.yaml`. Require the `Apps W1` and `Apps FR` projects selected by their settings to compile BaseApp and Fixed Asset tests, and require the AL-Go `Clean` dimension to compile FR with `CLEAN29`. Record the concrete branch and workflow run URL in implementation evidence. | Not Started | `.github/workflows/CICD.yaml`, `.github/workflows/_BuildALGoProject.yaml`, `.github/AL-Go-Settings.json`, `build/projects/Apps W1/.AL-Go/settings.json`, `build/projects/Apps FR/.AL-Go/settings.json` |
| ITEM-027 | In the same AL-Go run, require successful project jobs for APAC, BE, CH, DACH, ES, FI, and GB; inherited W1 codeunit 134149 MUST execute in composed APAC/BE/CH/FI projects and the ES-local regression MUST execute. | Not Started | `build/projects/Apps APAC/.AL-Go/settings.json`, `build/projects/Apps BE/.AL-Go/settings.json`, `build/projects/Apps CH/.AL-Go/settings.json`, `build/projects/Apps DACH/.AL-Go/settings.json`, `build/projects/Apps ES/.AL-Go/settings.json`, `build/projects/Apps FI/.AL-Go/settings.json`, `build/projects/Apps GB/.AL-Go/settings.json` |
| ITEM-028 | In the same AL-Go run, require successful project jobs for IT, NA, NL, NO, RU, and SE; inherited W1 codeunit 134149 MUST execute in composed NA/NO projects and IT/RU-local regressions MUST execute. | Not Started | `build/projects/Apps IT/.AL-Go/settings.json`, `build/projects/Apps NA/.AL-Go/settings.json`, `build/projects/Apps NL/.AL-Go/settings.json`, `build/projects/Apps NO/.AL-Go/settings.json`, `build/projects/Apps RU/.AL-Go/settings.json`, `build/projects/Apps SE/.AL-Go/settings.json` |
| ITEM-024 | Publish the built apps, run all focused posting/setup/depreciation/maintenance/reversal/cancellation/purchase/FR-upgrade/localization suites with 100% pass, inspect representative FA/maintenance/G/L ledgers, and update OpenSpec tasks only after evidence confirms completion. | Not Started | `openspec/changes/redesign-derogatory-mirroring/tasks.md` |

## 15. Change Log

- 2026-08-12: Closed remaining EPIC-008 direct-insertion, generated-mirror insurance, and exact reversal-cardinality coverage gaps.
- 2026-08-12: Remediated EPIC-008 review findings for event-order validity, composed-FR feature isolation, unfiltered/row-count invariants, and returned insertion identity.
- 2026-08-12: Completed EPIC-008 deterministic W1/FR coverage, total-row/link invariants, link-validation/event/compatibility cases, upgrade idempotency/telemetry/amount assertions, and composed-French feature awareness.
- 2026-08-11: Completed EPIC-007 French historical linkage migration: transfer-sequenced matching, mutually unique FA/maintenance graph linking, aggregate telemetry, and the forward corrective rebuild/tag with focused upgrade regressions.
- 2026-08-11: Completed EPIC-006 semantic verification for DACH, GB, NL, and SE, retained consumed general-journal declarations, removed zero-consumer posted-journal declarations, and added the NL inherited-posting regression.
- 2026-08-11: Completed EPIC-005 IT/RU localization derogatory mirroring port with centralized posting, link-first reversal, and regression tests. IT/RU execution deferred to localization release gate.
- 2026-08-10: Remediated every actionable EPIC-003 review finding test-first, added French containment/ambiguity/disabled-reversal/book-value regressions, and re-verified the compile, build and runtime gates.
- 2026-08-06: Completed EPIC-003 French runtime routing and public API compatibility.
- 2026-08-06: Completed EPIC-002 link-authoritative FA/maintenance reversal and focused reversal coverage.
- 2026-08-05: Version 1.0 created from `redesign-derogatory-mirroring.req.md`, AL semantic research, current implementation evidence, and Octane PRD standards.
