## Context

The Payment Practices app on branch `features/629871-master-Payment-Practices-W1-GB` has accumulated several GB-specific features (CSV export, 40+ manual qualitative fields, payment period templates) that are being descoped. The staged code introduces tables, pages, interfaces, and codeunits that need to be removed or reverted while preserving the meaningful GB runtime behavior: SCF payment date enrichment, header-level payment statistics (fields 20-23), and dispute status tracking on data rows.

The original codebase (HEAD on main) has a flat `Payment Period` table (T685) with `SetupDefaults()` seeding per-AppFamily periods. The staged changes replaced this with a Header/Line template model. We are reverting to the original flat model.

## Goals / Non-Goals

**Goals:**
- Remove all payment period template infrastructure (T680, T681, P690-P692, interface, template insertion logic)
- Remove GB CSV export (C684) and GB manual qualitative fields (T689, P693)
- Keep the Reporting Scheme enum and handler pattern — D&R handler retains real behavior
- Keep fields 20-23 on Payment Practice Header (populated by D&R handler)
- Make Reporting Scheme auto-detected and non-editable (`Visible = false` on card)
- Keep codeunit 695 with `DetectReportingScheme()` + extensibility event
- Revert period aggregator to read from flat T685

**Non-Goals:**
- Changing the existing AU/Small Business handler or its behavior
- Modifying the Vendor Card extension or VLE page extension (SCF Payment Date stays)
- Altering any core generation logic beyond reverting the period source table
- Removing the Reporting Scheme enum or collapsing D&R into Standard

## Decisions

### 1. Revert to flat Payment Period table (T685) — no templates

**Decision**: Remove Header/Line template tables. Period aggregation reads from T685 directly.

**Rationale**: One tenant = one AppFamily = one set of periods. The template model solved for multi-scheme-within-one-tenant which cannot occur. `SetupDefaults()` already branches per AppFamily.

**Alternative considered**: Keep templates but make them auto-selected. Rejected — adds complexity for no user-facing value.

### 2. Keep D&R enum value and handler (not collapse to Standard)

**Decision**: Keep `"Dispute & Retention"` (value 1) in the enum with its handler codeunit C681.

**Rationale**: The handler has real behavior — SCF date enrichment, header totals (fields 20-23), dispute status tracking. These are meaningfully different from the Standard pass-through handler.

**Alternative considered**: Collapse GB → Standard since most GB-specific UI is removed. Rejected — the handler does real computation and the enum value provides a clean extensibility point.

### 3. Reporting Scheme field: present but not visible

**Decision**: Field 15 stays on T687. On the Practice Card page it is `Visible = false, Editable = false`. Partners can make it visible via page customization.

**Rationale**: The field drives handler dispatch and is needed internally. Hiding it avoids confusing end users who cannot change it. Keeping it in the page definition allows partners to surface it.

### 4. Drop PaymentPracticeDefaultPeriods interface entirely

**Decision**: Remove the interface. Each handler's `GetDefaultPaymentPeriods()` is removed.

**Rationale**: Period seeding is handled by `SetupDefaults()` on T685 with `OnBeforeSetupDefaults` for partner extensibility. The interface only existed for template insertion — no longer needed.

### 5. Add OnBeforeDetectReportingScheme event in C695

**Decision**: `DetectReportingScheme()` gets an `OnBeforeDetectReportingScheme(var ReportingScheme; var IsHandled)` integration event.

**Rationale**: Partners adding a custom enum value for their AppFamily need a hook to map AppFamily → Scheme. Follows the same pattern as `OnBeforeSetupDefaults` on T685.

### 6. Remove T689, P693, C684 entirely

**Decision**: Delete the GB manual qualitative fields table, its card page, and the GB CSV export codeunit.

**Rationale**: Descoped from this deliverable. No consumer remains for these objects.

## Risks / Trade-offs

- **[Risk] Object IDs consumed but removed** → IDs T680, T681, T689, P690-693, C684 become available. If these were ever deployed to production, removal needs schema migration. Mitigation: these objects only exist on the feature branch, never shipped.
- **[Risk] Enum value "Dispute & Retention" exists with reduced surface** → Keeping the enum value with a handler that does real work is defensible. If the enum value were completely no-op, it would be dead code. Mitigation: handler has three concrete behaviors (SCF, totals, dispute tracking).
- **[Trade-off] Losing partner-facing template extensibility** → Payment period templates allowed partners to define custom period buckets per scheme. The flat table still allows editing periods but without scheme-specific templates. Mitigation: `OnBeforeSetupDefaults` event allows partners to seed custom periods.
