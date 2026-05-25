## Context

Commit `260ce28` on `features/629871-master-Payment-Practices-W1-GB-Simple` contains the full W1 + GB + AU Payment Practices prototype as a single staged changeset against `main`. The AU (Small Business) portion will be implemented by a colleague on a separate branch (`au-prototype`) forked from that commit. This change strips AU-specific runtime objects from the W1/GB branch while preserving shared infrastructure that supports AU re-integration.

The current branch has all changes staged (33 files modified/added vs `main`), with no commits ahead of `main` except `260ce28`. The AU code is interleaved with W1/GB code in several shared files.

## Goals / Non-Goals

**Goals:**
- Remove all AU-specific runtime objects (handler implementation, CSV export, declaration report, vendor extensions)
- Ensure the W1/GB branch compiles cleanly without AU runtime dependencies
- Preserve shared W1 infrastructure (CalculateLineTotals, Invoice Count/Value fields, enum value 2, page visibility plumbing) so the colleague touches fewer files when re-adding AU
- Remove AU/NZ-specific period defaults and scheme detection branches

**Non-Goals:**
- Removing the `CalculateLineTotals` method from the `PaymentPracticeSchemeHandler` interface (kept as W1 infrastructure)
- Removing fields 15-16 (Invoice Count/Value) from `Payment Practice Line` table (kept for AU re-integration)
- Removing `IsSmallBusiness` visibility logic from `PaymentPracticeLines` page (kept — columns simply stay hidden)
- Changing any W1 or GB functionality
- Modifying BaseApp tables

## Decisions

### 1. Keep enum value 2 "Small Business" with a stub handler

**Decision**: Keep `value(2; "Small Business")` in the enum, but replace C682's implementation with an empty pass-through handler (same pattern as C680 Standard Handler).

**Rationale**: Removing the enum value would require removing all references to `"Small Business"` from pages (`IsSmallBusiness` visibility), the `UpdateVisibility` 3-param signature, and column visibility expressions — cascading into 4+ more file edits. The stub compiles, is harmless at runtime, and the colleague simply replaces the stub body.

**Alternative considered**: Delete enum value 2 entirely and revert to 2-param `UpdateVisibility`. Rejected — doubles the edit count and forces the colleague to re-add the enum value, re-wire page visibility, and change the `UpdateVisibility` signature across card + lines pages.

### 2. Remove `InsertDefaultPeriods_AUNZ()` and its case branch

**Decision**: Remove the `'AU', 'NZ'` case from `PaymentPeriod.SetupDefaults()` and delete the `InsertDefaultPeriods_AUNZ()` method.

**Rationale**: User explicitly requested this removal. The method is dead code on non-AU environments. The colleague re-adds it from the spec (section 13).

**Alternative considered**: Keep it as harmless dead code. Rejected per user decision.

### 3. Remove `'AU', 'NZ'` from `DetectReportingScheme()`

**Decision**: Remove the `'AU', 'NZ'` case so it falls through to `else → Standard`.

**Rationale**: With the handler stubbed, returning "Small Business" for AU/NZ would auto-detect a scheme whose handler does nothing meaningful. Better to return Standard until the real handler is in place. The colleague re-adds the case when they implement C682.

### 4. Delete pure-AU objects rather than stub them

**Decision**: Delete C694 (AU CSV Export), R680 (AU Declaration), TE680 (Vendor extension), PE680 (Vendor Card extension) outright.

**Rationale**: These objects have no W1/GB consumers. Stubbing them would add dead code with no compilation benefit — nothing references them after the `ExportAUCSV` action is removed from the card.

### 5. Keep `CalculateLineTotals` in aggregators

**Decision**: Keep `SchemeHandler.CalculateLineTotals()` calls in both `PaymPracPeriodAggregator` and `PaymPracSizeAggregator`, along with the `Invoice Count`/`Invoice Value` conditional Modify.

**Rationale**: Both Standard and D&R handlers already have empty `CalculateLineTotals` bodies, so these calls are no-ops for W1/GB at runtime. Keeping them avoids editing both aggregators now and again when AU is re-added. The colleague only needs to add logic to C682's `CalculateLineTotals` — no aggregator changes needed.

## Risks / Trade-offs

- **[Trade-off] AU scaffolding in W1/GB**: Enum value 2, fields 15-16, page visibility plumbing remain. This is intentional — it reduces the colleague's future delta from ~14 files to ~7.
- **[Risk] Stub handler dispatched at runtime**: If someone manually sets Reporting Scheme = "Small Business" (field is hidden + non-editable, but accessible via AL code), the stub handler silently does nothing. Mitigation: The field is auto-detected and non-editable. No UI path to select "Small Business" on non-AU environments.
- **[Risk] Tests reference "Small Business" enum value**: The 4 removed tests are the only ones that exercise AU-specific handler behavior. The remaining tests (`CompanySizeStandardLeavesInvoiceCountAndValueZero`, `StandardSchemeGenerateProducesSameResults`) use `Standard` or explicit scheme parameters and don't depend on AU objects.
