## Context

The W1 Payment Practices app (AppSource, namespace `Microsoft.Finance.Analysis`) provides payment practice reporting for BC. It currently supports a single reporting flow: invoices from vendor/customer ledger entries are aggregated by time period or company size. The data model is:

- **Payment Practice Header** (T687) — one report per period, with `Header Type` (Vendor/Customer/Both) and `Aggregation Type` (Period/Company Size) controlling generation
- **Payment Practice Data** (T686) — one row per invoice, populated from VLE/CLE
- **Payment Practice Line** (T688) — aggregated results per period bucket or company size
- **Payment Period** (T685) — global period buckets (e.g., 0-30, 31-60), seeded on install per app family (W1/FR/GB)

The architecture uses AL enum-driven polymorphism: `Aggregation Type` enum implements `PaymentPracticeLinesAggregator` interface, `Header Type` enum implements `PaymentPracticeDataGenerator` interface. Handlers (Period Aggregator, Size Aggregator, Vendor/Customer/CV Generators) implement the interfaces.

Three regulatory regimes need support:
1. **Standard** (W1/FR) — existing behavior, no changes needed
2. **Dispute & Retention** (GB) — UK SI 2017/395 + 2025 Amendment: dispute tracking, SCF payment date, construction contract retention statistics, payment policy tick-boxes
3. **Small Business** (AU/NZ) — Payment Times Reporting Act 2020: small business supplier filtering, invoice count/value per period

## Goals / Non-Goals

**Goals:**
- Introduce an extensible `Reporting Scheme` enum controlling field visibility, data enrichment/filtering, and calculations without breaking existing behavior
- Replace the global `Payment Period` table with a named template pattern (header + lines), enabling user-editable period configurations with scheme-scoped defaults and cascading auto-fill (default template → sole template → blank)
- Support GB-specific data: dispute status from VLE, SCF payment date (dual-source: VLE auto-populated + manual override), construction contract retention (user-entered amounts + auto-calculated percentages), payment policy declarations (6 Boolean tick-boxes + conditional narratives)
- Support AU-specific data: small business supplier filtering (exclude non-small vendors entirely), invoice count/value aggregation per period bucket
- Produce CSV exports gated by reporting scheme (GB and AU formats)
- Ensure Standard scheme = zero regression on existing tests and behavior

**Non-Goals:**
- Real-time SCF integration (SCF Payment Date is a plain data field set manually or by external integration)
- Automatic small business classification (user must flag vendors manually)
- Localized UI translations beyond English in this change
- Full/partial SCF distinction (treated as a single effective date per the regulation)
- Auto-calculation of construction retention monetary amounts (user-entered per UK regulation — retention is not a discrete ledger entry type)

## Decisions

### D1: Single extensible enum + dual interface over per-country app splits

The `Paym. Prac. Reporting Scheme` enum (ID 680) implements two interfaces: `PaymentPracticeDefaultPeriods` (setup-time: returns default period template) and `PaymentPracticeSchemeHandler` (generation-time: validate, filter/enrich data, calculate totals). Each enum value maps to a handler codeunit.

**Rationale:** Follows the existing `Aggregation Type → PaymentPracticeLinesAggregator` pattern already proven in this app. Per-country app splits would duplicate shared code and complicate maintenance. The `Extensible = true` property allows partners to add country-specific schemes without modifying the base app.

**Alternatives considered:**
- Event subscribers per country: would scatter logic across codeunits, harder to discover and test
- Separate W1-GB / W1-AU apps: higher maintenance cost, shared code duplication

### D2: Scheme handler called at three integration points in existing flow

1. `ValidateHeader()` — called before data generation, same position as existing `SizeAggregator.ValidateHeader()`
2. `UpdatePaymentPracData()` — called in Builders after `CopyFromInvoiceVendLedgEntry()` and before `Insert()`, returning Boolean (true = include, false = skip). This is the single point for both data enrichment (GB: dispute, SCF) and data filtering (AU: non-small-business skip)
3. `CalculateHeaderTotals()` + `CalculateLineTotals()` — called after existing `GenerateTotals()` / per-line generation

**Rationale:** Minimal changes to existing flow. The `UpdatePaymentPracData` Boolean return follows the existing `Exclude from Pmt. Practices` skip pattern. Standard handler is a pass-through (returns `true`, no-ops for calculations), so existing behavior is unchanged.

### D3: Payment Period Header + Line template tables (SAF-T pattern)

Replace the global `Payment Period` table (T685) with `Payment Period Header` (T680) + `Payment Period Line` (T681). Each header is a named template (e.g., "W1-DEFAULT", "GB-DEFAULT") with child line rows. The `Payment Practice Header` references a template via `Payment Period Code` (TableRelation filtered by Reporting Scheme, displayed with `ShowMandatory = true`).

The `Default` flag on Payment Period Header is optional — a scheme may have zero or one default. Setting `Default = true` silently clears the flag on other templates for the same scheme (mutual exclusion). Users can freely uncheck Default. The Reporting Scheme field is non-editable after insert; users select it when creating a new template.

On `Payment Practice Header` insert (and on Reporting Scheme change), the `Payment Period Code` auto-fills using cascading logic: (1) the default template for the scheme, (2) the sole template if only one exists, (3) blank if multiple non-default templates or none exist. If no templates exist for a scheme, a confirmation dialog offers to create the default template from `GetDefaultPaymentPeriods()`.

**Rationale:** The current global table allows only one period configuration system-wide. Different schemes need different default buckets (W1: 5 buckets, FR: 4, GB: 4 different, AU: 3). The template pattern (proven in SAF-T's G/L Account Mapping) lets users create custom period configurations and select them per report. The optional Default flag provides convenience without enforcement — simpler than the Document Sending Profile pattern and better suited to a multi-scheme context where templates are scheme-scoped.

### D4: Auto-detection with user override for Reporting Scheme

On `Payment Practice Header` insert, `Reporting Scheme` is auto-detected from `GetApplicationFamily()` (GB → Dispute & Retention, AU/NZ → Small Business, all others → Standard). Users can change it on the card, triggering the same confirm-and-clear pattern as `Aggregation Type`.

**Rationale:** Reduces setup friction for the primary markets. User override supports edge cases (e.g., UK company wanting Standard-only reporting, or testing different schemes).

### D5: SCF Payment Date as dual-source field

`VLE."SCF Payment Date"` is the primary source (set at payment time by user/integration). During data generation, it's copied to `Payment Practice Data."SCF Payment Date"`. Users can also manually enter/override the date on the Payment Practice Data page. When populated, `Actual Payment Days = SCF Payment Date - Invoice Received Date` replaces the default `Pmt. Posting Date - Invoice Received Date`.

**Rationale:** UK SI 2017/395 Schedule para 5 & 14 requires reporting on when the supplier received payment under SCF. The VLE is the natural home for payment-time data. Manual override on the data record supports corrections without re-generating.

### D6: Small business filtering at insert time (not post-generation)

The AU handler's `UpdatePaymentPracData()` returns `false` for non-small-business vendors, preventing the row from being inserted into Payment Practice Data. This follows the existing `Exclude from Pmt. Practices` pattern.

**Rationale:** Cleaner than inserting all rows and filtering afterward. Reduces data volume. The `Is Small Business Supplier` flag on Vendor is the single source of truth — no need to duplicate it onto the data record.

### D7: Construction retention as user-entered amounts with auto-calculated percentages

The 4 monetary amounts (retention withheld from suppliers, retention withheld by clients, gross payments under construction contracts) are user-entered on the Payment Practice Header. The 2 percentages are auto-calculated. All retention narrative/tick-box fields are user-entered.

**Rationale:** BC cannot auto-calculate retention from transaction data — retention is not a discrete ledger entry type, and the receivables-side amount ("Sum B" — money withheld from the company by its clients) is not visible from purchase ledgers. The UK regulation explicitly requires these as declared values.

## Risks / Trade-offs

- **[Upgrade complexity]** Migrating old Payment Period data to new template tables requires careful comparison logic. → Mitigation: conservative upgrade — if old rows match defaults, just create default template; if different, create both "MIGRATED" and default templates. Existing headers backfilled.
- **[BaseApp changes required]** Adding fields to Vendor (T23) and Vendor Ledger Entry (T25) crosses app boundaries. → Mitigation: fields are simple data fields with no triggers or business logic in BaseApp. Vendor field follows existing "Exclude from Pmt. Practices" pattern. VLE field is `Visible = false` by default (SCF is niche/UK-specific).
- **[Export format uncertainty]** GB CSV and AU CSV exact column schemas are not yet confirmed. → Mitigation: export codeunits are Phase 5 (last before tests). Core data model and calculations do not depend on export format. Export implementation deferred until schemas are specified.
- **[Field count on Payment Practice Header]** GB adds ~40 fields (policy tick-boxes, retention, statistics). → Mitigation: all GB fields are conditionally visible only when `Reporting Scheme = Dispute & Retention`. Page layout uses grouped FastTabs. No impact on Standard/AU users.
- **[No automatic small business classification]** Users must manually flag vendors as small business. → Mitigation: follows existing `Exclude from Pmt. Practices` pattern. AU regulation requires entity-level determination that cannot be automated (based on vendor's annual turnover < AUD 10M).

## Migration Plan

1. **Upgrade codeunit** (C683) runs on app update:
   - Compares old `Payment Period` rows against scheme defaults
   - Creates appropriate Payment Period Header/Line templates
   - Backfills existing `Payment Practice Header` records with detected `Reporting Scheme` and `Payment Period Code`
2. **Old table T685** marked `ObsoleteState = Pending` with obsolete reason
3. **Rollback:** Old table data is preserved (not deleted during upgrade). Reverting the app version restores the old flow. The "MIGRATED" template preserves any custom period configurations.

## Open Questions

1. **GB CSV column schema** — exact column order, headers, date/number formatting, encoding need to be specified from the UK government portal's import schema
2. **AU CSV column schema** — exact delimited file format, column mapping, and declaration document Word layout need to be specified from the AU government schema
