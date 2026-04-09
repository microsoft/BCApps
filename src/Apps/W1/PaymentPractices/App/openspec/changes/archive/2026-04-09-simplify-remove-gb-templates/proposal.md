## Why

The payment period templates (Header/Line tables) over-engineer for a scenario that doesn't exist in practice — one BC tenant has one AppFamily, so there's never a need for multiple scheme-specific period configurations simultaneously. The GB CSV export and ~40 manual qualitative fields are being descoped from this deliverable. Removing these reduces complexity significantly while keeping all meaningful GB runtime behavior (SCF date enrichment, header totals, dispute tracking).

## What Changes

- **Remove payment period template tables**: Drop `Payment Period Header` (T680), `Payment Period Line` (T681), and all associated pages (P690, P691, P692)
- **Revert `Payment Period` table (T685)**: Remove obsolete marking, keep the flat table as the single source for period definitions — unchanged from baseline
- **Remove `PaymentPracticeDefaultPeriods` interface**: Period seeding remains in `SetupDefaults()` on T685 (existing code, no change)
- **Slim down codeunit 695**: Keep only `DetectReportingScheme()` with a new `OnBeforeDetectReportingScheme` integration event; remove template insertion logic
- **Remove `Payment Period Code` field (16) from Payment Practice Header**: Period aggregation reads directly from T685
- **Remove GB CSV export**: Drop `Paym. Prac. GB CSV Export` (C684)
- **Remove GB manual fields table**: Drop `Paym. Prac. Dispute Ret. Data` (T689) and `Paym. Prac. Dispute Ret. Card` (P693)
- **Keep fields 20-23 on Payment Practice Header**: Total Number of Payments, Total Amount of Payments, Total Amt. of Overdue Payments, Pct Overdue Due to Dispute — populated by D&R handler
- **Keep D&R handler (C681)**: SCF Payment Date enrichment, header totals calculation, dispute status tracking all remain
- **Reporting Scheme field**: Auto-detected on insert, not user-editable; `Visible = false` on the Payment Practice Card
- **Revert period aggregator**: Read from `Payment Period` (T685) instead of `Payment Period Line`

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `reporting-scheme`: Remove `PaymentPracticeDefaultPeriods` from enum implements clause; Reporting Scheme field becomes non-editable with `Visible = false`; remove `Payment Period Code` field and related lookup/validation logic; add `OnBeforeDetectReportingScheme` event
- `payment-period-templates`: **REMOVE** — entire capability deleted (T680, T681, P690, P691, P692, and related install/permission logic)
- `gb-csv-export`: **REMOVE** — entire capability deleted (C684)
- `dispute-retention-detail-table`: **REMOVE** — entire capability deleted (T689)
- `dispute-retention-detail-page`: **REMOVE** — entire capability deleted (P693, drilldown link on Payment Practice Card)
- `dispute-retention-handler`: Remove `PaymentPracticeDefaultPeriods` implementation and `GetDefaultPaymentPeriods()`; keep `PaymentPracticeSchemeHandler` implementation unchanged
- `gb-gov-csv-format`: **REMOVE** — entire capability deleted (no CSV to format)

## Impact

- **Tables**: Remove T680, T681, T689. Revert T685 (remove obsolete marking). Modify T687 (remove fields 16; keep 15, 20-23).
- **Pages**: Remove P690, P691, P692, P693. Modify P687 (remove Payment Period Code, D&R drilldown, GB CSV action; set Reporting Scheme `Visible = false`).
- **Codeunits**: Remove C684. Slim C695 (keep DetectReportingScheme + event only). Modify C681 (remove interface, keep handler). Modify C680 (remove interface). Revert period aggregator.
- **Interfaces**: Remove `PaymentPracticeDefaultPeriods`. Keep `PaymentPracticeSchemeHandler`.
- **Enum**: Remove `PaymentPracticeDefaultPeriods` from implements clause on enum 680.
- **Install/Upgrade**: Remove template creation, remove T680/T681/T689 data classification. Revert to original `SetupDefaults()` call.
- **Permissions**: Remove T680, T681, T689 from permission sets.
