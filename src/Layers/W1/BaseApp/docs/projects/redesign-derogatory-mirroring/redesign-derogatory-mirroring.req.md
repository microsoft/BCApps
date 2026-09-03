---
goal: Deterministic Derogatory Depreciation Mirroring for Business Central Fixed Assets (W1 core with French historical upgrade)
version: 1.0
date_created: 2026-08-05
last_updated: 2026-08-05
owner: Business Central Fixed Assets (BCApps) - SddPlanner
tags: [fixed-assets, depreciation, derogatory, mirroring, posting, reversal, upgrade, localization, W1, FR, ES, requirements]
---

# Introduction

Requirements Document for the following initiative: "Review (1) `openspec/changes/redesign-derogatory-mirroring/tasks.md` (initial implementation tracking) and (2) `openspec/changes/redesign-derogatory-mirroring/redesign-derogatory-mirroring.review.md` (Octane code-review outcome). Infer and propose comprehensive, deterministic requirements for the Business Central derogatory depreciation feature that describe intended behavior and address every material review issue/gap. Deeply inspect relevant W1, FR, ES, tests, upgrade, posting, reversal, ledger, and setup implementation as needed to ground requirements in current behavior/dependencies/affected modules."

This document specifies the intended behavior of the redesigned derogatory (French "amortissement derogatoire") depreciation-book mirroring capability. Derogatory depreciation posts a fixed-asset (FA) or maintenance entry to a normal depreciation book and "mirrors" a linked counterpart into a related derogatory (tax) depreciation book. The capability was ported from the French localization into W1 core and is being redesigned to make mirror eligibility, forward posting, and reversal deterministic through explicit persisted ledger links, replacing mutable journal flags, duplicated relationship lookups, distributed mirror producers, and heuristic reversal matching. The requirements below reconcile the OpenSpec proposal, design, and specification with the Octane code-review outcome (verdict NOT READY, 25% strictly accepted) and its twelve confirmed defects/drawbacks (C-01 through C-12) and seven unfinished tasks.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Cross-reference conventions**: Functional requirements use the `FR-` prefix, non-functional requirements use `NFR-`, failure modes use `FM-`, and acceptance criteria use `AC-`. These prefixes enable traceability across sections and into the PRD. Source-specification requirement identifiers `DM-R1` through `DM-R6` and scenario identifiers `DM-Rn-Sn` are the OpenSpec specification identifiers (`openspec/changes/redesign-derogatory-mirroring/specs/derogatory-book-mirroring/spec.md`); review-defect identifiers `C-01` through `C-12` and native task identifiers `1.1` through `8.6` are those of `redesign-derogatory-mirroring.review.md` and `tasks.md`. Absolute file paths in this document are relative to the repository root `C:\Enlist\navagent2\App\BCApps` unless otherwise stated; product source lives under `src/Layers/<country>/BaseApp` and tests under `src/Layers/<country>/Tests` (the `src/Views/...` trees are generated, merged, read-only views).

## 1. Terminology

| Term | Definition |
|------|------------|
| Normal (source) depreciation book | The depreciation book to which a user-originated FA or maintenance entry is posted (for example an accounting book). Represented by `Depreciation Book` (table 5611). |
| Derogatory (tax) depreciation book | A depreciation book that references a normal book through `Depreciation Book."Derogatory Calc."` (field 5865, W1 `src/Layers/W1/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al:370`) and receives mirrored counterpart entries. |
| Mirror / counterpart | A ledger entry created in the derogatory book that corresponds to an eligible source entry in the normal book. |
| Source posting | A user-originated or calculation-originated FA/maintenance posting eligible to produce a counterpart; posting role `Source` (`Derogatory Posting Role` enum 5869, value 0). |
| Generated mirror | A counterpart entry produced by the centralized workflow; posting role `Generated Mirror` (enum value 1). A generated mirror MUST NOT itself produce another mirror. |
| Derogatory Source Entry No. | Integer link field persisted on the counterpart entry that stores the normal-book source entry number. FA Ledger Entry field 5866 (`FALedgerEntry.Table.al:511`); Maintenance Ledger Entry field 5865 (`MaintenanceLedgerEntry.Table.al:383`). Zero on source entries. |
| Legacy Derogatory Ambiguous | Boolean marker persisted on a source entry indicating that historical French data could not be uniquely linked and MAY use the heuristic reversal fallback. FA Ledger Entry field 5867 (`FALedgerEntry.Table.al:517`); Maintenance Ledger Entry field 5866 (`MaintenanceLedgerEntry.Table.al:389`). |
| Derogatory Excluded | Pre-existing Boolean on FA Ledger Entry field 5865 (`FALedgerEntry.Table.al:506`) indicating a derogatory-book entry excluded from certain calculations. Distinct from the two new link fields. |
| Derogatory Posting Mgt. | Internal codeunit 5869 (`src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al`) that is the single authority for relationship resolution, eligibility, mirror-line construction, acquisition-cost adjustment preparation, and link validation. |
| FA Jnl.-Post Line | Codeunit 5632 (`src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`); the shared FA posting boundary reached by both general-journal and FA-journal posting. |
| FA Insert Ledger Entry | Codeunit 5802 (`src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al`); performs raw FA/maintenance ledger insertion and reversal-entry insertion. |
| Automatic entry | A system-generated FA/maintenance ledger entry (for example catch-up depreciation, acquisition-cost depreciation, salvage value) flagged `Automatic Entry` = true, as opposed to a primary user-originated entry. |
| Acquisition-cost depreciation | Depreciation of acquisition cost requested on an acquisition posting (`Depr. Acquisition Cost` = true), which for G/L-integrated derogatory books must re-enter the general-journal posting pipeline. |
| Is Derogatory | The removed W1 journal-coordination flag: `Gen. Journal Line`/`Posted Gen. Journal Line` field 5865 `Is Derogatory`, introduced by an unshipped W1 feature commit and removed from W1 and FR by this redesign, but still declared in other localization layers and actively consumed by a subset of those layers (see FR-013). |
| Derogatory Line | The French-native journal-coordination flag `Gen. Journal Line` field 10861 (`src/Layers/FR/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al:3871`), retained under `#if not CLEAN30` for feature-disabled French companies. Distinct from `Is Derogatory`. |
| Accelerated Depreciation feature | The French feature flag (`Accelerated Depr. Feature`, `src/Layers/FR/BaseApp/FixedAssets/Depreciation/AcceleratedDeprFeature.Codeunit.al`) that gates whether a French company uses legacy or centralized derogatory behavior. |
| CLEAN30 | Compilation symbol marking the cleanup boundary after which the superseded French legacy implementation is excluded and only the centralized W1 workflow remains. |
| Upgrade tag | Per-company idempotency marker (`System.Upgrade."Upgrade Tag"`). This capability uses `AcceleratedDepreciationUpgradeTag` (field/relationship transfer) and `DerogatoryLinkageUpgradeTag` (historical linkage), both defined in `Upg. Tag Accelerated Depr.` (codeunit 5867). |
| RFC 2119 | IETF Best Current Practice 14 defining the normative interpretation of MUST/SHOULD/MAY keywords used throughout this document. |

## 2. Scope

This change delivers one authoritative, deterministic derogatory-book mirroring workflow for FA and maintenance postings in W1 core, persisted source-entry links on mirrored ledger entries, link-owned reversal, a safe French historical-data upgrade, and consistent removal of the legacy distributed mirror producers, together with the verification required to prove accounting correctness.

### In Scope

- One-to-one normal-to-derogatory depreciation-book relationship enforcement at setup time and at posting time (DM-R1; tasks 1.4, 1.5).
- Persisted derogatory source-link and legacy-ambiguity schema (fields and keys) on FA Ledger Entry and Maintenance Ledger Entry (tasks 1.2, 1.3).
- A single authoritative derogatory posting policy service owning resolution, eligibility, mirror-line construction, acquisition-cost adjustment preparation, and link-consistency validation (DM-R2; tasks 2.1-2.4).
- Centralized forward mirroring at the shared FA posting boundary for general-journal and FA-journal inputs, producing exactly one linked counterpart per eligible source (DM-R2, DM-R3, DM-R4; tasks 3.1-3.3, 4.1-4.5).
- Correct containment and linkage of generated mirrors, automatic-only depreciation, and automatic companion entries including salvage value (DM-R2-S4, DM-R4-S1; C-07, C-09, C-10).
- Deterministic, link-owned reversal and reversal-of-reversal for FA and maintenance counterparts, with explicit consistency errors (DM-R5; tasks 6.1-6.5).
- Removal or neutralization of the legacy `Is Derogatory`-driven distributed mirror producers across all affected localization layers so that no path can duplicate or omit a counterpart (DM-R2; tasks 5.1-5.7; C-01).
- French per-company historical linkage upgrade that links only uniquely identifiable pairs, marks ambiguous sources, is prerequisite-aware and idempotent, and records outcomes (DM-R6; tasks 7.1-7.6; C-02, C-03, C-04, C-06).
- CLEAN30 scoping of the retained French legacy implementation and the upgrade shim, with reconciled documentation (tasks 7.7, 7.8; C-12).
- Public API/source compatibility preservation or explicit documented removal for changed FA posting and reversal signatures (C-11; tasks 3.1, 5.6).
- Verification adequacy and completion: total-tax-row assertions, posting-path and reversal-edge matrices, localization regression, upgrade edge cases, multi-project plus CLEAN30 compilation, focused runtime suites, and ledger/G/L inspection (tasks 3.4, 4.6, 5.7, 6.7, 8.1-8.6).

### Out of Scope (deferred)

- Mapping one normal depreciation book to multiple derogatory books - explicitly unsupported by design (`design.md` Non-Goals); the `Derogatory Book Code` FlowField (`DepreciationBook.Table.al:413`) remains a single lookup.
- Replacing or extending the user-configurable `Duplicate Depr. Book` feature (`DuplicateDeprBook.Codeunit.al`) - only its unintended interaction with generated mirrors is addressed (FR-005).
- Changing accelerated-depreciation formulas, posting-account selection, report results, or the set of supported FA posting types (`design.md` Non-Goals).
- Providing heuristic reversal compatibility for new W1 entries - the heuristic is confined to explicitly marked legacy French data (FR-019).
- Redesigning unrelated FA cancellation, disposal, or automatic-entry behavior beyond what deterministic linkage requires (`design.md` Non-Goals).
- Introducing a new application table for upgrade counters - migration outcomes are emitted through telemetry (FR-022; `design.md` Open Questions).
- Physical relocation of the acquisition-cost G/L execution into `FA Jnl.-Post Line` - two thin execution adapters are retained by design because AL cannot pass the required posting operation and transaction state as a safe callback (FR-011; ASM-011).
- Any modification to product code as part of producing this requirements artifact; this document is analysis only.

## 3. Functional Requirements

- **FR-001**: One-to-one derogatory-book relationship enforcement (setup time)
    - **Description**: The system MUST allow a normal depreciation book to be referenced as a derogatory source by no more than one derogatory depreciation book. Validation of `Depreciation Book."Derogatory Calc."` (`src/Layers/W1/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al:379` OnValidate) MUST reject, whenever the value changes (including changing an already-linked derogatory book to another normal book): (a) a self-reference where `"Derogatory Calc." = Code` (error `Text10801`, line 382); (b) assigning a normal book already referenced by a different derogatory book (uniqueness error `Text10802`, line 397); (c) chaining, where the chosen normal book is itself a derogatory book (`Text10804`, line 401); and (d) making a book that is already a derogatory source into a derogatory book (`Text10800`, line 407). The equivalent FR validation (`src/Layers/FR/BaseApp/FixedAssets/Depreciation/DepreciationBook.Table.al`) MUST enforce the same rules.
    - **Acceptance Criteria**:
        - Configuring the first derogatory book for a normal book that has none succeeds (DM-R1-S1).
        - Configuring a second derogatory book for the same normal book fails with an error identifying the existing relationship (DM-R1-S2).
        - Changing an already-linked derogatory book to a normal book that already has a derogatory book fails (DM-R1-S3).
        - Self-reference, chaining, and reverse-direction assignments each fail with their specific errors.
    - **Priority**: High
    - **Dependencies**: FR-002, FR-003, FR-004

- **FR-002**: Runtime rejection of ambiguous relationship data
    - **Description**: When resolving the derogatory book for a source posting, the system MUST require zero or one derogatory book referencing the source normal book and MUST stop with an actionable consistency error instead of silently selecting the first record when multiple derogatory books reference the same normal book. Resolution MUST be performed by `Derogatory Posting Mgt.".GetDerogatoryBookCode"` (`src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingMgt.Codeunit.al:17`), which errors with `AmbiguousDerogatoryBookErr` when a second matching record exists. This runtime check MUST NOT be bypassed by imported or historically invalid data.
    - **Acceptance Criteria**:
        - Posting a source whose normal book is referenced by two or more derogatory books stops with `AmbiguousDerogatoryBookErr` and posts no counterpart (DM-R1-S4).
        - A single valid relationship resolves to exactly the configured derogatory book code.
    - **Priority**: High
    - **Dependencies**: FR-001, FR-004

- **FR-003**: Persistent derogatory source-link and legacy-ambiguity schema
    - **Description**: FA Ledger Entry and Maintenance Ledger Entry MUST persist the derogatory linkage. FA Ledger Entry MUST expose field 5866 `"Derogatory Source Entry No."` (Integer, `FALedgerEntry.Table.al:511`), field 5867 `"Legacy Derogatory Ambiguous"` (Boolean, line 517), and a key on (`"Derogatory Source Entry No."`, `"Depreciation Book Code"`) for indexed counterpart lookup (Key13, line 573). Maintenance Ledger Entry MUST expose field 5865 `"Derogatory Source Entry No."` (Integer, `MaintenanceLedgerEntry.Table.al:383`), field 5866 `"Legacy Derogatory Ambiguous"` (Boolean, line 389), and the equivalent key (Key10, line 430). The pre-existing `"Derogatory Excluded"` field (FA Ledger Entry 5865) MUST remain distinct and unchanged. The normal-book source entry MUST keep `"Derogatory Source Entry No." = 0`; the counterpart MUST store the source entry number. The equivalent FR ledger fields (`src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FALedgerEntry.Table.al`) MUST be present with the same numbers, table relations, and keys.
    - **Acceptance Criteria**:
        - The two link fields and their supporting keys exist on both tables at the stated numbers and are `Editable = false` where appropriate.
        - A counterpart entry stores the source entry number; the source entry stores zero.
        - Lookups by `"Derogatory Source Entry No."` use the dedicated key (no full-table scan).
    - **Priority**: High
    - **Dependencies**: FR-007, FR-014, FR-016

- **FR-004**: Authoritative derogatory posting policy service
    - **Description**: A single internal codeunit `Derogatory Posting Mgt.` (5869) MUST be the sole authority for: relationship resolution (`GetDerogatoryBookCode`), posting eligibility (`IsEligible`, which returns true only when the posting role is `Source`, a unique derogatory book resolves, and the fixed asset has an `FA Depreciation Book` record for that derogatory book), derogatory journal-line construction from an FA journal line or a general-journal line (`MakeDerogatoryJournalLine` overloads), acquisition-cost adjustment preparation (`PrepareAcquisitionCostAdjustment` overloads), and link-consistency validation (`ValidateDerogatoryLink` overloads for FA and maintenance entries). All callers MUST use this service rather than filtering `Depreciation Book` directly or re-deriving eligibility. `ValidateDerogatoryLink` MUST error when the referenced source entry does not exist (`SourceEntryDoesNotExistErr`), when FA identity or expected book do not match (`InvalidDerogatoryLinkErr`, honoring canceled-asset identity via `"Canceled from FA No."`), or when a counterpart already exists for the source in the target book (`DuplicateDerogatoryLinkErr`).
    - **Acceptance Criteria**:
        - Eligibility returns false for any posting role other than `Source`, when no unique derogatory book resolves, or when the asset has no `FA Depreciation Book` record for the derogatory book (DM-R2-S5, DM-R3-S4).
        - Inserting a counterpart whose source entry does not exist, whose asset/book identity is inconsistent, or that duplicates an existing counterpart is rejected with the corresponding error (DM-R3-S3).
        - No posting or reversal path resolves the relationship by directly filtering `Depreciation Book` outside this service.
    - **Priority**: High
    - **Dependencies**: FR-001, FR-002, FR-005, FR-006, FR-007

- **FR-005**: Posting-role classification and generated-mirror containment
    - **Description**: The centralized workflow MUST classify each posting with a `Derogatory Posting Role` (`src/Layers/W1/BaseApp/FixedAssets/FixedAsset/DerogatoryPostingRole.Enum.al`). A `Generated Mirror` posting MUST NOT initiate another mirror (non-recursion) and MUST NOT trigger configurable `Duplicate Depr. Book` duplication or insurance side effects. Because `DuplicateDeprBook.DuplicateFAJnlLine` currently runs for all roles before the role-specific counterpart guard (`FAJnlPostLine.Codeunit.al:100`, guard at line 119), the system MUST bypass or neutralize configurable duplication and other generated-entry side effects for the `Generated Mirror` role (for example by clearing the relevant control fields before recursion), correcting C-10. The counterpart-posting continuation MUST run only for the `Source` role (`FAJnlPostLine.Codeunit.al:119`).
    - **Acceptance Criteria**:
        - Posting a generated derogatory counterpart creates no further mirror (DM-R2-S4).
        - A generated mirror for an asset that has `Duplicate Depr. Book` configured does not create additional duplicate-book journal lines or insurance side effects.
        - Only `Source`-role postings invoke counterpart production.
    - **Priority**: Medium
    - **Dependencies**: FR-004, FR-006

- **FR-006**: Centralized forward mirroring at the shared FA posting boundary
    - **Description**: Forward mirror creation MUST occur only in the shared FA posting workflow `FA Jnl.-Post Line` (codeunit 5632), which both general-journal posting and FA-journal posting already converge upon. The workflow MUST post the source, obtain its inserted ledger identity, and then ask `Derogatory Posting Mgt.` to post the counterpart, using an internal role/context parameter to distinguish an ordinary source from a generated mirror (`FAJnlPostLineWithContext`, `FAJnlPostLine.Codeunit.al:81`; `PostDerogatoryCounterpart` overloads at lines 281 and 301). Raw ledger insertion in `FA Insert Ledger Entry` MUST NOT independently initiate mirroring for balance, automatic, error, cancellation, disposal-internal, or reversal entries.
    - **Acceptance Criteria**:
        - An eligible acquisition through a purchase invoice, a general journal, and an FA journal each produce one counterpart via the same policy (DM-R2-S1, DM-R2-S2, DM-R2-S3).
        - Inserting a balance/automatic/error/cancellation/disposal-internal/reversal entry outside an eligible source context creates no mirror (DM-R2-S5).
        - No forward mirror is produced outside `FA Jnl.-Post Line`.
    - **Priority**: High
    - **Dependencies**: FR-004, FR-007, FR-013

- **FR-007**: Exactly one linked counterpart per eligible source with duplicate rejection
    - **Description**: For every eligible new source posting the system MUST create exactly one counterpart in the expected derogatory book and MUST persist the source ledger entry number on that counterpart via `"Derogatory Source Entry No."`. Before insertion the system MUST validate (through `ValidateDerogatoryLink`, `DerogatoryPostingMgt.Codeunit.al:172` FA / line 199 maintenance) that the source exists and that no second counterpart already references the source in the target book, rejecting duplicates. "Exactly one counterpart" means exactly one total tax-book row per eligible source line, not merely one linked row (see NFR-004).
    - **Acceptance Criteria**:
        - An eligible FA source produces exactly one FA ledger entry in the derogatory book storing the source FA ledger entry number (DM-R3-S1).
        - An eligible maintenance source produces exactly one maintenance ledger entry in the derogatory book storing the source maintenance ledger entry number (DM-R3-S2).
        - A second counterpart insertion for a source that already has one in the expected book is rejected (DM-R3-S3, FM-002).
        - The total count of tax-book rows for the source equals the count of linked rows (no unlinked extra row) (FM-005).
    - **Priority**: High
    - **Dependencies**: FR-004, FR-006, FR-008, FR-013

- **FR-008**: Returning insertion overloads with preserved caller compatibility
    - **Description**: `FA Insert Ledger Entry` MUST provide overloads that return the inserted FA ledger entry and the inserted maintenance ledger entry (`FAInsertLedgerEntry.Codeunit.al:86` FA, line 186 maintenance), so the centralized workflow can capture the source entry identity for linking. The pre-existing public procedures (`InsertFA(var FALedgEntry3)` at line 79, `InsertMaintenance(var MaintenanceLedgEntry2)` at line 179) MUST remain available and MUST delegate to the returning overloads so unrelated callers are not forced to change. The equivalent FR overloads MUST be provided.
    - **Acceptance Criteria**:
        - Existing single-parameter callers compile and behave unchanged.
        - The returning overloads yield the actual inserted entry identity (non-zero `"Entry No."`) used for linking.
    - **Priority**: High
    - **Dependencies**: FR-006, FR-007

- **FR-009**: Complete automatic-companion identity capture and linkage
    - **Description**: The system MUST capture the identities of all automatic companion entries produced for a source posting - catch-up depreciation, acquisition-cost depreciation, custom depreciation, and salvage-value entries - and MUST link each corresponding generated-mirror automatic entry to the correct captured source identity. `PostDeprUntilDate` (`FAJnlPostLine.Codeunit.al:442`) already captures depreciation/custom automatic identities (via `SetSourceAutomaticEntryNo`, line 516) and links generated-mirror automatic entries (lines 474-475, 486-487); this MUST be extended so salvage-value companions are also captured and linked rather than posted through the no-result insertion overload with the link cleared (correcting C-09 at `FAJnlPostLine.Codeunit.al:237-238` and `PostSalvageValue` at line 544).
    - **Acceptance Criteria**:
        - A generated-mirror salvage-value entry stores the `"Derogatory Source Entry No."` of the corresponding source salvage entry (DM-R5-S3).
        - Every automatic companion entry on the source side has exactly one linked automatic companion on the mirror side.
        - Reversal locates and reverses automatic salvage companions through the explicit link (FM-009).
    - **Priority**: High
    - **Dependencies**: FR-006, FR-007, FR-014

- **FR-010**: Automatic-only depreciation produces a counterpart
    - **Description**: When a depreciation posting produces only automatic entries and suppresses the zero-value primary entry (the `DeprLine()` shape: `Amount2 = 0`, posting type `Depreciation`, `Depr. until FA Posting Date` = true, `FAJnlPostLine.Codeunit.al:687`), the counterpart workflow MUST still produce and link the corresponding tax-book entries. The current counterpart paths exit when the primary `InsertedFALedgEntry."Entry No."` is zero (`FAJnlPostLine.Codeunit.al:288` and line 308), which omits mirroring for this supported shape (C-07). The workflow MUST continue counterpart processing when either the primary source entry or captured automatic source entries exist, and MUST link generated automatic entries by their corresponding captured identities.
    - **Acceptance Criteria**:
        - A depreciation run that inserts only automatic depreciation/custom entries (no primary entry) produces linked tax-book entries for each automatic source entry (DM-R4-S1).
        - No eligible depreciation shape results in a missing tax-book entry.
    - **Priority**: High
    - **Dependencies**: FR-009, FR-006, FR-012

- **FR-011**: Acquisition-cost derogatory adjustment centralization with thin execution adapters
    - **Description**: Eligibility, amount calculation, and construction of the primary derogatory acquisition-cost adjustment MUST be owned by `Derogatory Posting Mgt."PrepareAcquisitionCostAdjustment"` (`DerogatoryPostingMgt.Codeunit.al` FA and gen-journal overloads). Only thin execution adapters may remain: `Gen. Jnl.-Post Line."CreateAndPostDerogEntry"` (`src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al:7804`) executes a prepared general-journal adjustment when G/L integration is enabled (re-entering the pipeline via `GenJnlPostLineContinue` and capturing identity via `GetLastSourceFALedgerEntry`) or converts it to FA-journal execution when integration is disabled; `FA Jnl.-Post Batch."CreateAndPostDerogEntry"` (`src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostBatch.Codeunit.al:265`) executes a prepared FA-journal adjustment and retains the existing error for unsupported G/L integration. Both adapters MUST retain `REVIEW(redesign-derogatory-mirroring)` markers. Each calculated acquisition-cost Derogatory source line MUST receive exactly one tax-book counterpart (no double posting).
    - **Acceptance Criteria**:
        - An acquisition posting requesting depreciation of acquisition cost posts the calculated Derogatory source entry and its tax-book counterpart exactly once, with G/L integration on and off (DM-R4-S3).
        - The adapters contain no relationship resolution or amount calculation of their own; those are obtained from `Derogatory Posting Mgt.`.
    - **Priority**: High
    - **Dependencies**: FR-004, FR-007, FR-012, FR-013

- **FR-012**: Depreciation calculation ownership boundary
    - **Description**: `Calculate Depreciation` and `Calculate Normal Depreciation` MUST remain the sole producers of calculated normal depreciation amounts and derogatory adjustment amounts (the normal-book Depreciation line and the normal-book Derogatory line). The posting workflow MUST be the sole producer of their secondary-book counterparts, creating at most one linked derogatory-book counterpart per eligible source line. Calculated Depreciation and Derogatory source lines MUST each route through the centralized policy so that neither overlaps the other and each receives at most one counterpart (task 4.5).
    - **Acceptance Criteria**:
        - Calculate Depreciation producing a normal-book Depreciation line and a normal-book Derogatory adjustment line results in no more than one linked derogatory-book counterpart per eligible source line (DM-R4-S1).
        - Final or negative derogatory adjustments preserve calculated amounts and produce no duplicate counterparts (DM-R4-S2).
        - Depreciation and Derogatory source lines never both produce a counterpart for the same underlying amount.
    - **Priority**: High
    - **Dependencies**: FR-007, FR-010, FR-011

- **FR-013**: Localization-independent single counterpart production
    - **Description**: An eligible source posting MUST produce exactly one counterpart regardless of localization layer, journal-buffer validation order, copied buffers, or posting subscribers. The system MUST NOT run both the centralized `FA Jnl.-Post Line` counterpart workflow and a legacy `Is Derogatory`-driven outer mirror producer for the same source posting. The redesign MUST remove the W1 flag `Is Derogatory` (`Gen. Journal Line`/`Posted Gen. Journal Line` field 5865) and its producers - `GetDerogatorySetup`, field/account validation calls, the purchase-invoice preparation producer (`src/Layers/W1/BaseApp/Purchases/Posting/PurchPostInvoice.Codeunit.al`, already removed), the `Gen. Jnl.-Post Line` flag consumer, and the `FA Jnl.-Post Batch` mirror builder - and MUST ensure that no localization layer that inherits the centralized W1 workflow retains an active `Is Derogatory` outer producer. The committed ES double producer MUST be corrected: `src/Layers/ES/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al` currently calls the centralized W1 workflow (`FAJnlPostLine.GenJnlPostLine`, lines 1883-1884), then refreshes mutable state via `GenJnlLine.GetDerogatorySetup()` (line 1886), and runs the legacy producer plus `CreateAndPostDerogEntry` (lines 1887-1893, 9320), producing a duplicate (C-01). The same neutralization MUST be verified for the other localization layers with an active `Gen. Jnl.-Post Line` consumer: APAC, BE, CH, FI, IT, NA, NO, and RU. DACH, GB, NL, and SE declare field 5865 and `GetDerogatorySetup` but have no localization `GenJnlPostLine.Codeunit.al`; each MUST be verified semantically to ensure the inherited W1 path leaves the flag dormant after removal of the W1 consumer. French companies remain governed by FR-020.
    - **Acceptance Criteria**:
        - A localization posting that previously set `Is Derogatory` produces exactly one total tax-book counterpart, not two (DM-R2-S1, DM-R3-S1; C-01).
        - No product code path both invokes the centralized counterpart workflow and an `Is Derogatory` outer producer for the same source line.
        - A regression test proves journal subscribers and copied purchase buffers cannot suppress or duplicate mirroring (task 5.7).
    - **Priority**: High
    - **Dependencies**: FR-006, FR-007, NFR-001, NFR-008

- **FR-014**: Deterministic link-owned reversal with authoritative persisted link
    - **Description**: Reversal of a new derogatory counterpart MUST be driven by the persisted `"Derogatory Source Entry No."` link, not by re-derived mutable setup. When reversing a normal-book source, the system MUST first create the normal-book reversing entry, obtain its entry number, locate the original mirror by `"Derogatory Source Entry No."` = the reversed entry number in the derogatory book, reverse it exactly once, and set the resulting tax-book reversal's source to the new normal-book reversal (`InsertFARevEntryForDerog`, `FAInsertLedgerEntry.Codeunit.al:715`; `InsertMaintRevEntryForDerog`, line 755; link applied via `InsertReverseEntryWithLink`, line 482). The persisted link MUST be the primary locator: the current implementation resolves current setup (`GetDerogatoryBookCode`, line 726) and asset-book eligibility (`FADepreciationBook.Get`, line 728) before the keyed link lookup (lines 731-732) and exits early when setup is cleared or changed, which allows reversal of already-linked history to be silently bypassed or redirected (C-08). Current setup MAY be consulted only for new posting and for the explicitly marked legacy fallback (FR-019), not to gate reversal of an already-linked entry.
    - **Acceptance Criteria**:
        - Reversing a linked normal-book FA entry reverses its single linked derogatory counterpart exactly once (DM-R5-S1).
        - Reversing a linked normal-book maintenance entry reverses its single linked derogatory counterpart exactly once (DM-R5-S2).
        - Clearing or changing `Depreciation Book."Derogatory Calc."` after linking does not prevent or redirect reversal of an already-linked counterpart (FM-010).
    - **Priority**: High
    - **Dependencies**: FR-003, FR-007, FR-015

- **FR-015**: Reversal consistency errors and reversal-of-reversal linkage
    - **Description**: For a new (non-legacy) source entry requiring a linked counterpart, the system MUST raise an explicit consistency error rather than silently selecting a candidate when the counterpart is missing (`MissingDerogatoryCounterpartErr`, `FAInsertLedgerEntry.Codeunit.al:76`, raised at line 743) or when more than one counterpart references the same source (`MultipleDerogatoryCounterpartsErr`, line 77, raised at line 746). Reversal MUST preserve the `Reversed Entry No.` / `Reversed by Entry No.` lifecycle and the derogatory link across reversal-of-reversal so that a reversed reversing entry is located through the explicit link and reversed once, and existing reversal marks and links are preserved.
    - **Acceptance Criteria**:
        - A new source entry that requires a counterpart but has none stops reversal with `MissingDerogatoryCounterpartErr` (DM-R5-S5, FM-003).
        - More than one counterpart referencing one source stops reversal with `MultipleDerogatoryCounterpartsErr` (DM-R5-S6, FM-004).
        - Reversing a reversal locates the corresponding derogatory reversing entry through the link and reverses it once, preserving prior marks (DM-R5-S4).
        - The derogatory reversing entry stores the normal-book reversing entry number as its source (DM-R5-S3).
    - **Priority**: High
    - **Dependencies**: FR-003, FR-014

- **FR-016**: French per-company idempotent, prerequisite-aware linkage upgrade
    - **Description**: The French historical linkage upgrade (`src/Layers/FR/BaseApp/FixedAssets/Depreciation/UpgradeDerogatoryLinkage.Codeunit.al`, codeunit 104103) MUST treat availability of the new `"Derogatory Calc."` relationship as a prerequisite and MUST set its `DerogatoryLinkageUpgradeTag` (`Upg. Tag Accelerated Depr.`, codeunit 5867, tag `MS-581204-DerogatoryLinkageUpgradeTag-20260730`) only after that prerequisite is satisfied and all writes succeed. The current entry point unconditionally sets the tag after scanning (`UpgradeDerogatoryLinkage.Codeunit.al:59`) while its resolver depends on the new relationship (line 71 onward), so a feature-disabled company completes a zero-work pass and never relinks history after the relationship is later copied (C-02). Relationship migration MUST be a prerequisite, and linkage MUST be invoked (or re-armed) immediately after the relationship is transferred during: French feature enablement (`AcceleratedDeprFeature.Codeunit.al` `UpgradeAcceleratedDepreciation`, line 120, which copies `"Derogatory Calc." := "Derogatory Calculation"` at line 132) and the CLEAN30 transfer (`UpgradeAcceleratedDepr.Codeunit.al` `TransferFields(Database::"Depreciation Book", 10800, 5865)`, line 41). The upgrade MUST remain idempotent: re-invoking it after data is processed MUST NOT duplicate or alter established links.
    - **Acceptance Criteria**:
        - A feature-disabled company that later enables the feature (or reaches CLEAN30) has its historical entries linked after the relationship becomes available, not stranded (DM-R6-S7; C-02).
        - The linkage tag is set only after the relationship prerequisite and all link writes succeed.
        - Re-running the upgrade after completion changes no established link (DM-R6-S7, FM-006).
    - **Priority**: High
    - **Dependencies**: FR-017, FR-018, FR-020

- **FR-017**: Globally-unique historical matching with complete identity
    - **Description**: The upgrade MUST build the complete source-to-candidate relationship before writing any link and MUST link a historical pair only when the counterpart is uniquely identifiable in both directions (mutual one-to-one), rather than mutating one source at a time and greedily selecting the closest candidate. The current algorithm links immediately per source (`UpgradeDerogatoryLinkage.Codeunit.al` `LinkFAEntry`/`LinkMaintenanceEntry`) and selects the entry-number-closest candidate, marking ambiguity only on equal-distance ties (`SelectUniqueClosestFAEntry`), which can persist objectively false links (C-03). Candidate identity MUST include: derogatory relationship, asset identity including canceled-asset identity (`"Canceled from FA No."`, consistent with `DerogatoryPostingMgt.Codeunit.al` `ValidateDerogatoryLink`), FA posting type, amount, document identity, posting/document dates, transaction number, full reversal-chain consistency (`Reversed`, `Reversed Entry No.`, `Reversed by Entry No.`), and, for maintenance, the `"Maintenance Code"` (currently omitted from `FindMaintenanceCandidates`). The migration source set MUST NOT blanket-exclude automatic entries: it currently sets `SetRange("Automatic Entry", false)` (line 71 FA, line 177 maintenance), which excludes legacy G/L-integrated system-created `Derogatory` acquisition adjustments that become automatic entries and still require a counterpart at reversal (C-06); classification MUST be by posting role/type so primary system-created `Derogatory` adjustments are included.
    - **Acceptance Criteria**:
        - A source with exactly one uniquely identifiable counterpart is linked; a source with multiple valid candidates (including unequal-distance) is left unlinked and marked ambiguous (DM-R6-S1, DM-R6-S3; C-03).
        - Maintenance matching distinguishes entries by `"Maintenance Code"`.
        - Reversed and reversal-of-reversal historical pairs are matched with reversal-chain consistency and linked while preserving reversal state (DM-R6-S2).
        - Historical primary system-created `Derogatory` acquisition adjustments are eligible for linking, not excluded (C-06, FM-012).
    - **Priority**: High
    - **Dependencies**: FR-016, FR-018, FR-019

- **FR-018**: Idempotent partial-link retry
    - **Description**: The upgrade MUST validate whether a source already has an established counterpart before selecting candidates, so a retry or partial-recovery pass cannot link a second matching unlinked candidate to a source that is already linked. The current candidate query filters out already-linked candidates (`SetRange("Derogatory Source Entry No.", 0)`) but does not first check the source for an existing counterpart (C-04).
    - **Acceptance Criteria**:
        - A second upgrade pass over a source that already has one linked counterpart plus an additional matching unlinked candidate does not create a duplicate link (DM-R6-S7, FM-008).
        - Repeated upgrade execution is safe for FA and maintenance sources.
    - **Priority**: High
    - **Dependencies**: FR-016, FR-017

- **FR-019**: Legacy ambiguity marker and scoped heuristic reversal fallback
    - **Description**: When no unique historical partner can be selected, the upgrade MUST set the `"Legacy Derogatory Ambiguous"` marker on the source entry and MUST NOT fabricate a link. Only entries carrying this marker MAY use the heuristic reversal fallback (`FindLegacyFADerogatoryEntry`/`FindLegacyMaintenanceDerogatoryEntry`, `FAInsertLedgerEntry.Codeunit.al:791`/`803`), which is gated by `"Legacy Derogatory Ambiguous"` (line 738 FA / line 774 maintenance). New W1 source entries MUST NOT set the marker and therefore MUST NOT use the heuristic; a new W1 source without an explicit counterpart link MUST NOT be reversed by amount/document/type matching.
    - **Acceptance Criteria**:
        - An upgraded French source with multiple valid candidates is marked ambiguous and left unlinked (DM-R6-S3).
        - A marked ambiguous source, when reversed, may use the historical matching heuristic (DM-R6-S5).
        - A new W1 source with no explicit counterpart link never uses the historical heuristic (DM-R6-S6).
    - **Priority**: High
    - **Dependencies**: FR-014, FR-015, FR-017

- **FR-020**: CLEAN30 scoping, French legacy retention, and shim documentation reconciliation
    - **Description**: The superseded French pre-feature implementation - `"Derogatory Line"` (`Gen. Journal Line` field 10861), `GetDerogatorySetup` (`GenJournalLine.Table.al:5973`), subscribers, reports, posting producers, and legacy tests - MUST remain only inside `#if not CLEAN30` guards and MUST continue to serve feature-disabled French companies. Feature-enabled companies and CLEAN30 builds MUST use the centralized W1 workflow. The feature-disabled FR FA-journal path MUST use only the legacy builder/producer and MUST NOT additionally require the new `"Derogatory Calc."` relationship builder: `FA Jnl.-Post Batch.PostLines` currently nests legacy `MakeDerogFAJnlLine` (reads `"Derogatory Calculation"`, `FAJnlPostBatch.Codeunit.al:275`) with new `MakeDerogatoryFAJnlLine` (reads `"Derogatory Calc."`, line 333) requiring both (lines 408-409), so a disabled company with only legacy fields omits the mirror (C-05); this MUST be corrected to use only the legacy builder when disabled and only the centralized workflow when enabled or CLEAN30 (consistent with `FA Jnl.-Post Line.PostDerogatoryCounterpart` exiting while disabled, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al:286`). The upgrade shim `Upgrade Derogatory Linkage` MUST be retained beyond CLEAN30 until its separately documented cleanup version because upgraded databases can still contain ambiguous legacy entries requiring the scoped fallback; the shim's in-code documentation MUST be reconciled with the design so it no longer states the shim is removed with CLEAN30 (C-12; `UpgradeDerogatoryLinkage.Codeunit.al` header comment versus `design.md`).
    - **Acceptance Criteria**:
        - A feature-disabled French company with only legacy `"Derogatory Calculation"` populated posts its mirror through the legacy producer (DM-R2-S3; C-05).
        - A feature-enabled or CLEAN30 build posts only through the centralized workflow with no legacy double production.
        - The CLEAN30 build compiles with the guarded legacy implementation excluded (NFR-005).
        - The shim documentation matches the design decision to retain it beyond CLEAN30 (C-12).
    - **Priority**: High
    - **Dependencies**: FR-013, FR-016, FR-021

- **FR-021**: Public API compatibility preservation or documented removal
    - **Description**: Changes to public FA posting and reversal APIs MUST either preserve source compatibility through overloads/delegates or be explicitly versioned and documented after semantic consumer analysis. The proposal identifies only `Is Derogatory` as breaking (`proposal.md`), but the redesign also removed the public W1 `MakeDerogatoryFAJnlLine` from `FA Jnl.-Post Batch` (no compatibility delegate at HEAD) and changed the FR reversal methods from three parameters to two (`InsertFARevEntryForDerog`/`InsertMaintRevEntryForDerog`, `src/Layers/FR/BaseApp/FixedAssets/FixedAsset/FAInsertLedgerEntry.Codeunit.al:748`/`807`) (C-11). Each such change MUST be either restored as a compatibility overload/delegate or documented as an intentional breaking change with consumer-impact rationale.
    - **Acceptance Criteria**:
        - Every removed or signature-changed public procedure is either restored via a compatible overload/delegate or listed as a documented breaking change with rationale.
        - The set of documented breaking changes is consistent between `proposal.md` and the implementation.
    - **Priority**: Medium
    - **Dependencies**: FR-008, FR-020, NFR-007

- **FR-022**: Upgrade outcome telemetry
    - **Description**: The French per-company upgrade MUST record, per run, the counts of linked, ambiguous, and missing pairs for FA and maintenance, distinguishing the three outcomes, and MUST emit them through upgrade/feature telemetry rather than a new application table (`UpgradeDerogatoryLinkage.Codeunit.al` `Feature Telemetry.LogUsage` with dimensions `FALinked`, `FAAmbiguous`, `FAMissing`, `MaintenanceLinked`, `MaintenanceAmbiguous`, `MaintenanceMissing`).
    - **Acceptance Criteria**:
        - A completed upgrade emits telemetry containing the six outcome counts.
        - Linked, ambiguous, and missing outcomes are counted distinctly and match the ledger result.
    - **Priority**: Low
    - **Dependencies**: FR-016, FR-017, FR-019

## 4. Non-Functional Requirements

- **NFR-001**: Determinism and posting-path independence
    - **Metric:** For an identical eligible source posting, the number and linkage of derogatory counterparts MUST be exactly one linked counterpart per eligible source line and MUST be invariant across posting path (purchase invoice, general journal, FA journal), journal validation order, copied buffers, and localization subscribers (0 variance across all paths).
    - **Rationale:** The redesign exists to remove correctness dependencies on mutable journal flags, copied buffers, and localization subscribers (`design.md` Goals); non-determinism causes missing or duplicate tax-book entries.
    - **Testing Approach:** Post the same asset/amount through each path and assert equal total tax-book row counts and identical linkage; localization regression suite (task 5.7) including the ES C-01 scenario.

- **NFR-002**: Keyed-lookup performance
    - **Metric:** Counterpart and reversal lookups MUST use the dedicated indexed key on (`"Derogatory Source Entry No."`, `"Depreciation Book Code"`) (FA Ledger Entry Key13; Maintenance Ledger Entry Key10) and MUST NOT perform broad document/amount table scans for new (non-legacy) entries; lookup cost is one indexed read per source.
    - **Rationale:** Additional per-posting and per-reversal lookups must not degrade posting throughput; the one-way indexed link avoids bidirectional field synchronization (`design.md` Risks/Trade-offs).
    - **Testing Approach:** Code inspection confirming keyed `SetRange` on the link key; verify no `FindLast`/broad-scan matching is used for new-entry counterpart resolution; representative-volume posting timing sanity check.

- **NFR-003**: Upgrade data safety and idempotency
    - **Metric:** The French upgrade MUST NOT alter any accounting amount; it MUST only add links and legacy-ambiguity markers. Re-running the upgrade MUST produce zero additional or altered links (fully idempotent). A forward corrective upgrade MUST be able to clear or rebuild linkage.
    - **Rationale:** Rollback before production deployment is limited to reverting the application package and restoring the database; the upgrade must be safely repeatable and non-destructive (`design.md` Migration Plan).
    - **Testing Approach:** Compare ledger amounts before/after upgrade for equality; run the tagged upgrade twice and assert no new/changed links; verify corrective clear/rebuild path.

- **NFR-004**: Verification adequacy (total-row and matrix coverage)
    - **Metric:** Automated verification MUST assert the total count of tax-book rows per eligible source (not only linked rows), so an extra unlinked counterpart is detected. The existing `VerifyLinkedCounterparts` helper (`src/Layers/W1/Tests/Fixed Asset/ERMDerogatoryDeprPosting.Codeunit.al:961`) counts only linked rows and MUST be strengthened. Test coverage MUST include: insertion/link-integrity tests (task 3.4); a posting-path matrix covering purchase, general journal, FA journal, maintenance, G/L integration on/off, no-asset-book, and ES/FR variants (task 4.6); reversal-edge tests covering FA/maintenance, two-step, reversal-of-reversal, missing/duplicate/already-reversed counterpart, setup change, and salvage (task 6.7); depreciation variants normal/final/negative/acquisition and automatic-only counting all tax-book rows (task 8.2); and FR upgrade tests for unique, reversed, reversal-of-reversal, ambiguous (including unequal-distance), missing, maintenance-code, canceled-asset, disabled-to-enabled sequencing, partial-link retry, and true repeated-tag execution (tasks 7.6, and cases behind C-02/C-03/C-04/C-06).
    - **Rationale:** Static/linked-row checks cannot detect the confirmed duplicate/omission defects (C-01, C-07); the review found the reopened and unfinished test tasks are release-blocking.
    - **Testing Approach:** Extend and add the listed AL test codeunits (`ERM Derogatory Depr. Posting` 134149, `UT TAB FA Derogatory Depr.` 134166, FR `UT Derogatory Linkage Upg.` 134167) and assert total tax-book row counts and explicit links.

- **NFR-005**: Multi-project and CLEAN30 build integrity
    - **Metric:** The affected projects MUST compile with zero errors: W1 BaseApp, W1 Fixed Asset tests, FR BaseApp, FR Fixed Asset tests (task 8.3), and additionally a dedicated CLEAN30 build MUST compile with the guarded French legacy implementation excluded.
    - **Rationale:** Compilation is necessary (not sufficient) for correctness; CLEAN30 guarded branches (`FAJnlPostLine`/`FAJnlPostBatch` FR) were not part of the four standard compiles and must be validated (review 4.1).
    - **Testing Approach:** Run the standard four-project compile plus the repository CLEAN-build workflow for CLEAN30; require zero errors.

- **NFR-006**: Runtime validation completion
    - **Metric:** Before readiness, focused runtime suites MUST be published and executed (derogatory posting, setup, depreciation, maintenance, reversal, cancellation, purchase posting, and FR upgrade) with 100% pass, and representative FA and maintenance ledgers plus G/L MUST be inspected for link integrity, reversal links, book values, G/L counts, and absence of duplicate mirrors (tasks 8.4, 8.5).
    - **Rationale:** The review recorded zero runtime tests executed; accounting correctness cannot be established by static analysis alone (review Sections 10.3, 14).
    - **Testing Approach:** Publish to a test environment; run the focused codeunits; capture and inspect ledger/G/L snapshots against expected link and count invariants.

- **NFR-007**: Extensibility-surface stability
    - **Metric:** The centralized boundary MUST expose integration events only where an extension can safely influence counterpart construction, and MUST NOT rely on the removed `Is Derogatory` flag or removed outer-producer subscribers. Any change to integration-event ordering (for example recursive mirror posting relative to source `OnAfter...` events) MUST be validated by subscriber/state-order regression tests.
    - **Rationale:** Existing extensions read `Is Derogatory` or subscribe around the removed journal-driven behavior and must be migrated to the ledger-boundary behavior (`proposal.md` Impact); event-order changes can break subscribers (review 4.1).
    - **Testing Approach:** Enumerate retained/added events at the centralized boundary; subscriber/state-order regression tests; semantic reference sweep for removed-flag consumers.

- **NFR-008**: Cross-localization safety sweep
    - **Metric:** Every localization layer that still declares `Is Derogatory` (field 5865) MUST be swept semantically. Active `Gen. Jnl.-Post Line` consumers in APAC, BE, CH, ES, FI, IT, NA, NO, and RU MUST also be tested at runtime to prove they cannot suppress or duplicate mirroring when combined with the centralized W1 workflow. Declare-only layers DACH, GB, NL, and SE MUST be verified to have no localization `GenJnlPostLine.Codeunit.al` consumer and to leave the flag dormant after removal of the inherited W1 consumer.
    - **Rationale:** Binding must not be inferred from text alone; the ES defect (C-01) is one confirmed instance of a lexical pattern present across many layers (review 4.1).
    - **Testing Approach:** AL semantic definition/reference tracing per layer plus a per-layer posting regression asserting exactly one total tax-book counterpart.

## 5. Failure Modes and Recovery

| ID | Failure | Detection | Recovery |
|----|---------|-----------|----------|
| FM-001 | Ambiguous derogatory setup: more than one derogatory book references a single normal book (imported or historical data). | `Derogatory Posting Mgt."GetDerogatoryBookCode"` finds a second record (`DerogatoryPostingMgt.Codeunit.al:26`). | Stop posting with `AmbiguousDerogatoryBookErr` identifying the source book; require the administrator to correct depreciation-book setup before posting (FR-002). |
| FM-002 | Duplicate counterpart: posting attempts a second counterpart for a source that already has one in the target book. | `ValidateDerogatoryLink` detects an existing counterpart by the link key (`DerogatoryPostingMgt.Codeunit.al` FA line 172 / maintenance line 199). | Reject insertion with `DuplicateDerogatoryLinkErr`; no second row is written (FR-007). |
| FM-003 | Missing counterpart at reversal for a new source entry that requires one. | Keyed link lookup returns empty for a non-legacy entry (`FAInsertLedgerEntry.Codeunit.al:743`). | Stop reversal with `MissingDerogatoryCounterpartErr`; operator must investigate/repair linkage rather than proceed (FR-015). |
| FM-004 | Multiple counterparts reference one source entry. | Keyed link lookup returns more than one row (`FAInsertLedgerEntry.Codeunit.al:746`). | Stop reversal with `MultipleDerogatoryCounterpartsErr`; operator must resolve the duplicate before reversal (FR-015). |
| FM-005 | Localization double production: a legacy `Is Derogatory` outer producer runs alongside the centralized workflow, creating an extra unlinked tax-book row. | Total tax-book row count exceeds linked-row count for a source (NFR-004 total-row assertion); ES committed path `GenJnlPostLine.Codeunit.al:1885-1893`. | Remove/neutralize the legacy producer in the affected layer (FR-013); regression asserts one total counterpart (task 5.7, NFR-008). |
| FM-006 | Upgrade tag set before the derogatory relationship exists, stranding history. | Feature-disabled company completes a zero-work upgrade then enables the feature; historical entries remain unlinked and later reversal fails (FM-003). | Make relationship migration a prerequisite; invoke/re-arm linkage after transfer; set the tag only after success (FR-016). A forward corrective upgrade can rebuild linkage (NFR-003). |
| FM-007 | Greedy or non-mutual historical match persists an objectively false link. | Migration links a source to a closest-by-distance candidate without proving both-direction uniqueness (C-03). | Build the full candidate graph before writing; require mutual one-to-one uniqueness; otherwise mark ambiguous and leave unlinked (FR-017, FR-019). |
| FM-008 | Partial-link retry links a second candidate to an already-linked source. | Second upgrade pass over a source with one linked plus one unlinked matching candidate creates a duplicate (C-04). | Validate the source for an existing counterpart before candidate selection; idempotent retry (FR-018). |
| FM-009 | Automatic companion (for example salvage) is unlinked and skipped on reversal. | Reversal silently skips an automatic non-`Derogatory` companion lacking a link (C-09). | Capture and link all automatic companion identities including salvage; reversal follows the explicit link (FR-009). |
| FM-010 | Reversal after setup cleared/changed bypasses or redirects reversal of already-linked history. | Reversal resolves current setup and asset-book eligibility before the keyed link lookup and exits early (`FAInsertLedgerEntry.Codeunit.al:726-728`). | Locate linked counterparts globally by the persisted link first; use current setup only for new posting and the marked legacy fallback (FR-014). |
| FM-011 | Link references a non-existent or inconsistent source entry. | `ValidateDerogatoryLink` cannot `Get` the source, or FA/book identity mismatch (`DerogatoryPostingMgt.Codeunit.al`). | Reject with `SourceEntryDoesNotExistErr` or `InvalidDerogatoryLinkErr`; no inconsistent link is written (FR-004). |
| FM-012 | Historical G/L-integrated system-created `Derogatory` acquisition adjustment excluded from migration. | Blanket `SetRange("Automatic Entry", false)` excludes it (`UpgradeDerogatoryLinkage.Codeunit.al:71,177`); reversal later expects a counterpart. | Classify migration sources by posting role/type and include primary system-created `Derogatory` adjustments (FR-017). |
| FM-013 | Removed/changed public API breaks an extension or country consumer. | Compilation failure or runtime error in a dependent app referencing `MakeDerogatoryFAJnlLine` or the former three-parameter FR reversal methods (C-11). | Restore a compatibility overload/delegate, or document the intentional breaking change with consumer-impact rationale and version notes (FR-021, NFR-007). |

## 6. Assumptions and Interpretations

### Assumptions

| ID | Assumption | Confidence | Impact if Wrong | Traces To |
|----|-----------|------------|-----------------|-----------|
| ASM-001 | The intended behavior is defined jointly by the OpenSpec proposal/design/specification and the review's "Required improvement" statements; each of the review's confirmed defects (C-01..C-12) represents a deviation from intended behavior to be corrected, not a new design choice. | High | If the review's improvements are not the intended target, some FRs (notably FR-005, FR-009, FR-010, FR-013..FR-020) could over-specify corrections the team does not want. | FR-005, FR-009, FR-010, FR-013, FR-014, FR-016, FR-017 |
| ASM-002 | The final schema is FA Ledger Entry field 5866 `Derogatory Source Entry No.` and 5867 `Legacy Derogatory Ambiguous`, and Maintenance Ledger Entry field 5865 `Derogatory Source Entry No.` and 5866 `Legacy Derogatory Ambiguous`, with `Derogatory Excluded` remaining FA Ledger Entry 5865 (per `design.md` Open Questions and verified table sources). | High | If field numbers change, FR-003, NFR-002 keys, and every link reference require renumbering. | FR-003, NFR-002 |
| ASM-003 | Active `Is Derogatory` consumers in APAC, BE, CH, FI, IT, NA, NO, and RU may exhibit the same double-production risk as the confirmed ES defect until semantic tracing and runtime tests prove otherwise. DACH, GB, NL, and SE are assumed to be declare-only layers whose inherited flag becomes dormant when the W1 consumer is removed. | Medium | If an active layer does not reach the centralized workflow, its runtime scope may be reduced; if a declare-only layer has an indirect consumer, FR-013/NFR-008 must add that path to active neutralization and runtime coverage. | FR-013, NFR-008, FM-005 |
| ASM-004 | A normal depreciation book maps to at most one derogatory book; one-to-many is explicitly unsupported and the `Derogatory Book Code` FlowField remains a single lookup. | High | If one-to-many is later required, FR-001/FR-002 uniqueness enforcement and the FlowField model must be redesigned. | FR-001, FR-002 |
| ASM-005 | Feature-disabled French companies retain legacy derogatory behavior until CLEAN30; feature-enabled and CLEAN30 builds use the centralized W1 workflow exclusively. | High | If disabled companies must also use the centralized workflow immediately, FR-020's dual-path retention and the `#if not CLEAN30` guards are wrong. | FR-020, FR-013 |
| ASM-006 | `AcceleratedDepreciationUpgradeTag` (field/relationship transfer) and `DerogatoryLinkageUpgradeTag` (historical linkage) are distinct per-company tags, and linkage depends on the relationship transfer having completed. | High | If a single combined tag is intended, FR-016's prerequisite-sequencing and re-arm mechanics change. | FR-016 |
| ASM-007 | Requirements target the redesign branch `private/algladkov/FR-Derogatory-Depreciation-redesign`; line numbers reference the current working-tree state of the cited files (which includes an uncommitted worktree edit to `src/Layers/W1/BaseApp/FixedAssets/FixedAsset/FAJnlPostLine.Codeunit.al`), while object/procedure/field identifiers are the stable anchors. | High | If a different baseline is authoritative, cited line numbers may drift; identifiers remain valid. | FR-006, FR-009, FR-010 |
| ASM-008 | "Exactly one counterpart" is interpreted as exactly one total tax-book row per eligible source line (linked-row count equals total-row count), because the confirmed duplicate defect produces an extra unlinked row that a linked-row-only assertion cannot detect. | High | If only "one linked row" is required, an extra unlinked duplicate (C-01) would pass and correctness would not be proven. | FR-007, FR-013, NFR-004 |
| ASM-009 | Feature/upgrade telemetry (`Feature Telemetry.LogUsage`) is the accepted channel for upgrade outcome counts; no new application table is introduced. | High | If persisted counters are required, FR-022 must add a table and the "Out of Scope" deferral is wrong. | FR-022 |
| ASM-010 | Maintenance derogatory identity includes `Maintenance Code` both for forward posting semantics and for historical matching. | High | If maintenance mirrors ignore maintenance code, FR-017's maintenance identity is over-constrained and could mark valid pairs ambiguous. | FR-017 |
| ASM-011 | The acquisition-cost G/L execution legitimately remains in `Gen. Jnl.-Post Line`/`FA Jnl.-Post Batch` as two thin adapters because AL cannot pass the required posting operation and transaction state as a safe callback; centralization applies to policy, amount, and line construction only. | High | If full physical centralization is required, FR-011's retained-adapter model is incorrect and a larger refactor is needed. | FR-011 |
| ASM-012 | No accelerated-depreciation formula, posting-account selection, report result, or supported posting type changes as part of this redesign (design Non-Goals). | High | If accounting outputs are expected to change, several "preserve calculated amounts" acceptance criteria (FR-011, FR-012, NFR-003) are wrong. | FR-011, FR-012, NFR-003 |
| ASM-013 | The declaration-only `Reversal` and `Internal` posting roles (`DerogatoryPostingRole.Enum.al`) are acceptable to leave unwired for this change unless a concrete context requires them; they are not required by any FR here. | Low | If these roles must carry real context flow, an additional FR is needed; leaving them unused is a minor latent-code concern only. | FR-005 |

### Alternative Interpretations

| ID | Ambiguity | Chosen Interpretation | Alternatives Considered | Rationale |
|----|-----------|----------------------|------------------------|-----------|
| ALT-001 | "Address every material review issue/gap" - which issues become requirements. | All twelve confirmed defects (C-01..C-12), all seven unfinished tasks, and the reopened checked tasks are converted into FR/NFR/FM/AC coverage. | Cover only Priority-0 defects; cover only unfinished tasks. | The purpose explicitly requests comprehensive coverage of every material issue and every pertinent task; partial coverage would leave release-blocking defects unspecified. |
| ALT-002 | How to treat the `Is Derogatory` residue in non-ES localizations. | Require removal/neutralization across all carrying layers OR a proven semantic-plus-runtime sweep (FR-013, NFR-008). | Fix only the committed ES change; treat other layers as out of scope. | Determinism (NFR-001) requires that no path double-produces; the review flagged the pattern across many layers as a risk needing a sweep, so scoping to ES alone would leave the invariant unproven. |
| ALT-003 | Whether test/validation gaps are functional requirements or non-functional. | Expressed as NFRs (verification adequacy, build integrity, runtime completion) plus acceptance criteria, keeping FRs behavioral. | Model each unfinished test task as its own FR. | The authoring standard restricts content to functional and non-functional behavior; test execution is verification, best expressed as NFR-004..NFR-006 with ACs, while the behavior under test is captured by the FRs. |
| ALT-004 | Where to place salvage/automatic-only companion linkage (posting vs reversal). | A single behavioral FR (FR-009) for automatic-companion identity capture and linkage that spans posting and reversal, with FR-010 isolating the automatic-only-depreciation counterpart case. | Fold C-07 and C-09 into the reversal FRs; or fold both into one FR. | C-07 (missing counterpart) and C-09 (unlinked salvage) are distinct testable behaviors originating in posting but observed at reversal; separating capture/linkage (FR-009) from the automatic-only shape (FR-010) preserves precise traceability. |
| ALT-005 | Artifact component name and path. | `redesign-derogatory-mirroring/redesign-derogatory-mirroring.req.md` under the configured requirements directory. | `derogatory-depreciation-mirroring`; `fixed-assets-derogatory`. | Matching the existing OpenSpec change name maximizes traceability between the review artifacts, tasks, and these requirements. |
| ALT-006 | Whether preserving removed public APIs is mandatory or discretionary. | Require either a compatibility overload/delegate or an explicit documented breaking change after consumer analysis (FR-021). | Treat all removals as acceptable because objects are internal; require full restoration of every signature. | The manager codeunit is internal, but `FA Jnl.-Post Batch`/`FA Insert Ledger Entry` procedures were public and the proposal documents only `Is Derogatory` as breaking; a decision-with-rationale gate balances compatibility against intentional cleanup. |

## 7. Acceptance Criteria

| ID | Criterion | Verification | Traces To |
|----|-----------|--------------|-----------|
| AC-001 | Configuring the first derogatory book for a normal book with none succeeds. | Automated test (`UT TAB FA Derogatory Depr.` 134166, `OnValidateDerogatoryCalcFirstAssignmentSucceeds`) | FR-001 |
| AC-002 | Configuring a second derogatory book for the same normal book fails with an error naming the existing relationship. | Automated test | FR-001, FM-001 |
| AC-003 | Changing an already-linked derogatory book to a normal book that already has one fails; self-reference, chaining, and reverse assignment each error. | Automated test | FR-001 |
| AC-004 | Posting a source whose normal book is referenced by two or more derogatory books stops with `AmbiguousDerogatoryBookErr` and posts no counterpart. | Automated test | FR-002, FM-001 |
| AC-005 | FA Ledger Entry fields 5866/5867 with Key13 and Maintenance Ledger Entry fields 5865/5866 with Key10 exist on W1 and FR tables. | Schema validation | FR-003 |
| AC-006 | A counterpart entry stores the source entry number; the source entry stores zero. | Automated test / Manual ledger inspection | FR-003, FR-007 |
| AC-007 | Eligibility returns false for any non-`Source` role, when no unique derogatory book resolves, or when the asset lacks the derogatory-book `FA Depreciation Book` record. | Automated test | FR-004, FR-005 |
| AC-008 | Counterpart insertion is rejected when the source does not exist (`SourceEntryDoesNotExistErr`), identity/book are inconsistent (`InvalidDerogatoryLinkErr`), or a counterpart already exists (`DuplicateDerogatoryLinkErr`). | Automated test | FR-004, FM-002, FM-011 |
| AC-009 | A generated derogatory counterpart creates no further mirror and triggers no configurable duplicate-book or insurance side effects. | Automated test | FR-005 |
| AC-010 | An eligible acquisition through purchase invoice, general journal, and FA journal each produce one counterpart via the same policy. | Automated test (posting-path matrix, task 4.6) | FR-006, NFR-001 |
| AC-011 | Inserting a balance/automatic/error/cancellation/disposal-internal/reversal entry outside an eligible source context creates no mirror. | Automated test | FR-006 |
| AC-012 | An eligible FA source produces exactly one FA ledger entry in the derogatory book storing the source entry number. | Automated test | FR-007 |
| AC-013 | An eligible maintenance source produces exactly one maintenance ledger entry in the derogatory book storing the source entry number. | Automated test | FR-007 |
| AC-014 | For every eligible source, the total count of tax-book rows equals the count of linked rows (no unlinked extra row). | Automated test (strengthened total-row verifier) | FR-007, FR-013, NFR-004, FM-005 |
| AC-015 | Existing single-parameter `InsertFA`/`InsertMaintenance` callers compile unchanged and delegate to returning overloads that yield non-zero inserted identities. | Automated test / Compilation | FR-008 |
| AC-016 | A generated-mirror salvage-value companion is linked and is reversed through the explicit link (not skipped). | Automated test (reversal-edge matrix, task 6.7) | FR-009, FM-009 |
| AC-017 | A depreciation run producing only automatic entries (suppressed primary) produces linked tax-book entries for each automatic source entry. | Automated test (task 8.2 automatic-only) | FR-010 |
| AC-018 | An acquisition posting depreciating acquisition cost posts the Derogatory source and its counterpart exactly once with G/L integration on and off. | Automated test | FR-011 |
| AC-019 | Calculate Depreciation producing Depreciation and Derogatory lines yields at most one linked counterpart per source line; final/negative adjustments preserve amounts with no duplicates. | Automated test | FR-012 |
| AC-020 | A localization posting that previously set `Is Derogatory` produces exactly one total tax-book counterpart (ES C-01 corrected). | Automated test (localization regression, task 5.7) | FR-013, FM-005, NFR-008 |
| AC-021 | Reversing a linked normal-book FA or maintenance entry reverses its single linked derogatory counterpart exactly once. | Automated test | FR-014 |
| AC-022 | Clearing or changing `Derogatory Calc.` after linking does not prevent or redirect reversal of an already-linked counterpart. | Automated test | FR-014, FM-010 |
| AC-023 | Missing counterpart raises `MissingDerogatoryCounterpartErr`; multiple counterparts raise `MultipleDerogatoryCounterpartsErr`. | Automated test | FR-015, FM-003, FM-004 |
| AC-024 | Reversing a reversal locates the derogatory reversing entry through the link, reverses it once, and preserves prior reversal marks and links; the derogatory reversing entry stores the normal reversing entry number. | Automated test | FR-015 |
| AC-025 | A feature-disabled company that later enables the feature or reaches CLEAN30 has its history linked; the linkage tag is set only after success; re-running changes no established link. | Automated test (disabled-to-enabled sequencing; repeated-tag) | FR-016, FM-006, NFR-003 |
| AC-026 | Historical matching links only mutually unique pairs; maintenance uses `Maintenance Code`; canceled-asset identity and reversal-chain consistency are honored; primary system-created `Derogatory` adjustments are included. | Automated test (FR upgrade suite 134167) | FR-017, FM-007, FM-012 |
| AC-027 | A retry pass over a source with one linked plus one matching unlinked candidate creates no duplicate link. | Automated test | FR-018, FM-008 |
| AC-028 | Multiple-candidate sources are marked ambiguous and left unlinked; only marked sources use the heuristic on reversal; new W1 sources never use the heuristic. | Automated test | FR-019 |
| AC-029 | A disabled FR company posts its mirror via the legacy-only builder; enabled/CLEAN30 builds post only centrally; the CLEAN30 build compiles with legacy excluded; shim documentation matches the design retention decision. | Automated test / Compilation / Manual doc review | FR-020, NFR-005 |
| AC-030 | Every removed or signature-changed public procedure is restored via a compatible overload/delegate or documented as an intentional breaking change with rationale, consistent with `proposal.md`. | Manual review / Compilation | FR-021, FM-013, NFR-007 |
| AC-031 | A completed upgrade emits telemetry containing the six FA/maintenance linked/ambiguous/missing counts matching the ledger result. | Automated test / Telemetry inspection | FR-022 |
| AC-032 | Counterpart and reversal lookups use the dedicated link key with no broad document/amount scan for new entries. | Code inspection | NFR-002 |
| AC-033 | The verification suite asserts total tax-book rows and includes the insertion, posting-path, reversal-edge, depreciation-variant, and FR-upgrade matrices (tasks 3.4, 4.6, 5.7, 6.7, 8.1, 8.2). | Test-suite review | NFR-004 |
| AC-034 | W1 BaseApp, W1 Fixed Asset tests, FR BaseApp, FR Fixed Asset tests, and a dedicated CLEAN30 build all compile with zero errors. | Compilation (four standard projects plus CLEAN build) | NFR-005 |
| AC-035 | Focused runtime suites are published and pass, and representative FA/maintenance ledgers plus G/L are inspected for links, reversal chains, book values, counts, and absence of duplicate mirrors (tasks 8.4, 8.5). | Runtime test execution / Manual ledger inspection | NFR-006 |
| AC-036 | Each localization declaring `Is Derogatory` (APAC, BE, CH, DACH, ES, FI, GB, IT, NA, NL, NO, RU, SE) is swept semantically and at runtime to prove exactly one total counterpart. | Semantic trace / Runtime regression | NFR-008 |
| AC-037 | The same eligible posting produces identical counterpart count and linkage across all posting paths (zero variance). | Automated test (determinism matrix) | NFR-001 |
