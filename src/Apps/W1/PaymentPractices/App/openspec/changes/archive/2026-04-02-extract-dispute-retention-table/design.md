## Context

The `Payment Practice Header` table (T687) currently holds ~50 fields. Of these, ~31 fields (IDs 30-34, 40-58, 60-73) are exclusively used by the Dispute & Retention (GB) reporting scheme. These fields represent UK government-mandated qualitative reporting data: payment terms narratives, construction contract retention details, dispute resolution processes, and payment policy declarations. They are blank and irrelevant for Standard and Small Business schemes.

The existing architecture uses a `Paym. Prac. Reporting Scheme` enum (ID 680) implementing two interfaces (`PaymentPracticeDefaultPeriods`, `PaymentPracticeSchemeHandler`). The Dispute & Retention handler (C681) only writes to header fields 20-23 (payment statistics) during generation. All other D&R fields are user-entered.

UK companies report twice per year. Research of real government data shows ~80% of D&R fields are standing-policy data (narratives, boolean declarations) that rarely change between periods. A copy-from-previous mechanism is needed.

## Goals / Non-Goals

**Goals:**
- Extract D&R qualitative fields from T687 into a 1:1 supplementary table (T689)
- Keep T687 clean with only scheme-agnostic fields + shared statistics (fields 20-23)
- Provide a dedicated page (P693) for editing D&R data, opened from the header card via a clickable link
- Enable "Copy from Previous Period" to reduce repetitive data entry
- Update GB CSV export (C684) to read from the new table

**Non-Goals:**
- Template/master-data approach for D&R fields (rejected: historical snapshot integrity for regulatory reporting)
- Changing the `PaymentPracticeSchemeHandler` interface
- Moving fields 20-23 out of the header (used by Small Business handler too)
- Table extension approach (same-app tableextension is non-standard and doesn't reduce SQL column count)

## Decisions

### Decision 1: Single 1:1 supplementary table, not multiple domain tables

All ~31 D&R fields go into one table `Paym. Prac. Dispute Ret. Data` (T689) rather than splitting into per-domain tables (Payment Terms, Retention, Policies).

**Rationale**: The fields all belong to a single regulatory scheme. They always appear together, are exported together, and have no independent reuse. Multiple tiny tables would add lifecycle wiring and join complexity for no benefit.

**Alternative rejected**: 3-4 domain-specific tables — over-engineered for a single-scheme use case.

### Decision 2: Eager creation on header insert, not lazy

The T689 record is created immediately in `OnInsert` of T687, regardless of whether the scheme is Dispute & Retention.

**Rationale**: Simplicity. No null-checking or "ensure exists" logic throughout the codebase. The record is tiny (1 row, mostly empty for non-GB). Deletion is already handled by `DeleteLinkedRecords()`.

**Alternative rejected**: Lazy creation (create on first access) — adds guard logic in every consumer and the page `OnAfterGetRecord`.

### Decision 3: Standalone Card page with clickable link, not CardPart

The D&R fields are shown on a standalone `Paym. Prac. Dispute Ret. Card` page (P693), opened from the main card via a `Style = StandardAccent` / `OnDrillDown` link field.

**Rationale**: 31 fields with 5 groups need full page real estate. A CardPart would cram them inside the header card, making the GB card excessively long while non-GB cards see nothing. The standalone page mirrors the UK government portal's separate form model. Standard BC pattern (e.g., Data Subject page uses the same link style).

**Alternative rejected**: Embedded CardPart — too many fields, makes the main card layout awkward for all schemes.

### Decision 4: Copy-from-previous as explicit action, not auto-populate on insert

A "Copy from Previous Period" action on P693 finds the most recent T689 record (by header Ending Date) and copies standing-policy fields, clearing period-specific ones.

**Rationale**: Explicit is safer for regulatory data. Users see what they're getting and can choose not to copy. Auto-populate on insert would silently pre-fill data that the user must legally verify per period.

**Fields copied** (standing-policy): All boolean policy declarations (30-34), construction retention structure (40-53), standard retention percentage (47, 73), narrative fields (43, 50, 51, 53, 65, 69-71), payment period fields (63-64, 68), qualifying contract gates (60-62).

**Fields cleared** (period-specific): Payment Terms Have Changed (66), Suppliers Notified (67), Has Deducted Charges in Period (33), Retent. Withheld from Suppls. (54), Retention Withheld by Clients (55), Gross Payments Constr. Contr. (56), Pct Retention vs Client Ret. (57), Pct Retent. vs Gross Payments (58), Payments Made in Period (61).

### Decision 5: Fields 20-23 stay on Payment Practice Header

`Total Number of Payments` (20), `Total Amount of Payments` (21), `Total Amt. of Overdue Payments` (22), `Pct Overdue Due to Dispute` (23) remain on T687.

**Rationale**: Field 20 is also written by the Small Business handler. Fields 20-23 are auto-calculated by `CalculateHeaderTotals()` during generation. They are payment statistics, not qualitative policy data. Moving them would require the handler interface to know about T689.

## Risks / Trade-offs

- **[Risk] Upgrade migration**: Existing T687 records will have D&R fields populated. New T689 records won't exist for historical data → **Mitigation**: Upgrade codeunit that migrates existing field values from T687 to T689 for all existing headers, then the fields can be removed from T687. Out of scope for this change — handled separately as a data migration.
- **[Risk] GB CSV export reads two tables**: C684 now does `Header.Get()` + `DisputeRetData.Get()` instead of just `Header` → **Mitigation**: Single additional `Get` call, negligible performance impact. The export already does multiple reads (lines, company info).
- **[Trade-off] Eager insert creates T689 for non-GB headers**: Wastes one empty row per Standard/SmallBusiness header → **Accepted**: Negligible storage cost. Eliminates null-check complexity everywhere.
- **[Trade-off] Copy-from-previous requires user action**: Not automatic → **Accepted**: Correct behavior for regulatory reporting where each period's data must be independently verified.
