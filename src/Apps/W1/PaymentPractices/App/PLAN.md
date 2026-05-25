# Plan: Reporting Scheme Driven Payment Practices

## TL;DR

Extend the W1 Payment Practices app with an extensible Reporting Scheme enum + interface to support GB and AU regulatory requirements in a single app. The enum controls which fields are visible, which calculations run, and which exports are generated. Standard value = zero regression. Payment periods become user-editable for all schemes.

## Scope

**In scope:** Reporting Scheme enum + interface, editable payment periods, Dispute & Retention fields/calculations/export (GB, including construction contract retention), Small Business fields/calculations/export (AU/NZ), tests.

---

## Phase 1: Core Infrastructure

### Step 1. New enum `Paym. Prac. Reporting Scheme` (ID 680)
- File: `App/src/Core/Enums/PaymPracReportingScheme.Enum.al` (new)
- Extensible = true
- Implements two interfaces: `PaymentPracticeDefaultPeriods`, `PaymentPracticeSchemeHandler`
- Values: `Standard` (0, default), `Dispute & Retention` (1), `Small Business` (2)
- `Standard` covers W1 and FR — the handler checks `GetApplicationFamily()` internally to return FR-specific period defaults (0-30, 31-60, 61-90, 91+) vs W1 defaults (0-30, 31-60, 61-90, 91-120, 121+)
- `Dispute & Retention` = GB: dispute tracking, SCF, construction retention
- `Small Business` = AU/NZ: small business supplier filtering, invoice count/value
- Reference pattern: existing `PaymPracAggregationType.Enum.al` (enum 685) and `PaymPracHeaderType.Enum.al` (enum 686)

### Step 2a. New interface `PaymentPracticeDefaultPeriods` (setup-time)
- File: `App/src/Core/Interfaces/PaymPracDefaultPeriods.Interface.al` (new)
- Method:
  - `procedure GetDefaultPaymentPeriods(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)` — returns the default period template Code, Description, and line buckets for this scheme
- Called during install (to seed defaults) and on Reporting Scheme OnValidate (to auto-create if no matching template exists)

### Step 2b. New interface `PaymentPracticeSchemeHandler` (generation-time)
- File: `App/src/Core/Interfaces/PaymPracSchemeHandler.Interface.al` (new)
- Methods:
  - `procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean` — scheme-specific data update during generation, called **before** `Insert()`. Returns `true` to include the row, `false` to skip it (e.g., Small Business handler returns `false` for non-small-business vendors). Handler looks up source ledger entry via `PaymentPracticeData."Invoice Entry No."` + `"Source Type"`.
  - `procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")` — validates that the header's `Header Type` is allowed for this scheme. Called from `Generate()` before data generation. Same pattern as the existing `PaymPracSizeAggregator.ValidateHeader()` that errors on Customer/Vendor+Customer.
  - `procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")` — scheme-specific header-level aggregations beyond the Standard defaults
  - `procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")` — scheme-specific line-level aggregations

### Step 3. Standard handler implementation
- File: `App/src/Core/Implementations/PaymPracStandardHandler.Codeunit.al` (new)
- Implements both `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler`
- `GetDefaultPaymentPeriods()` — checks `GetApplicationFamily()`: returns Code `'FR-DEFAULT'` + FR defaults (0-30, 31-60, 61-90, 91+) for FR, Code `'W1-DEFAULT'` + W1 defaults (0-30, 31-60, 61-90, 91-120, 121+) for all others
- `ValidateHeader()` — no-op (all header types allowed)
- `UpdatePaymentPracData()` — returns `true` (always include)
- `CalculateHeaderTotals()` / `CalculateLineTotals()` — no-op (existing Math codeunit handles Standard calculations)
- Note: Standard scheme relies entirely on existing core logic; `UpdatePaymentPracData` is a pass-through

### Step 4. Dispute & Retention handler implementation
- File: `App/src/Core/Implementations/PaymPracDisputeRetHandler.Codeunit.al` (new)
- Implements both `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler`
- `GetDefaultPaymentPeriods()` — returns Code `'GB-DEFAULT'`, Description `'UK Payment Periods (0-30, 31-60, 61-120, 121+)'`, and GB line defaults (0-30, 31-60, 61-120, 121+)
- `ValidateHeader()` — no-op (all header types allowed; dispute % applies to both vendor and customer sides)
- `UpdatePaymentPracData()` — copies `Dispute Status` from Vendor/Cust Ledger Entry (via BaseApp field), sets `Overdue Due to Dispute`, applies SCF Payment Date logic (see below). Returns `true` (always include)
- **SCF Payment Date logic (resolved):**
  - SCF (Supply Chain Finance / reverse factoring) is a **vendor-side** arrangement: a finance provider pays the supplier early, the buyer pays the finance provider later. The UK regulation (SI 2017/395, Schedule para 5 & 14) requires disclosing SCF usage and reporting payment days based on when the **supplier received payment**.
  - `SCF Payment Date` can be populated from **two sources**: (a) copied from `Vendor Ledger Entry."SCF Payment Date"` during data generation (auto-populated if the user or an integration filled it at payment time), or (b) manually entered on the Payment Practice Data record before generating totals.
  - The VLE value takes priority during `CopyFromInvoiceVendLedgEntry()`. The user can override it on the Payment Practice Data page afterward.
  - When `SCF Payment Date <> 0D`, the handler recalculates: `"Actual Payment Days" := "SCF Payment Date" - "Invoice Received Date"`. This replaces the default calculation that uses `Pmt. Posting Date`.
  - Full vs. partial SCF: not distinguished automatically. If `SCF Payment Date` is populated, the system treats it as the effective payment date regardless. The user is responsible for entering the correct date per the regulation (date supplier received payment for full SCF; date buyer paid the finance provider for partial/deducted SCF).
- `CalculateHeaderTotals()` — populates Total Number of Payments, Total Amount of Payments, Total Amt. of Overdue Payments, Pct Overdue Due to Dispute, and construction contract retention statistics (retention payment terms, retention payment performance)
- `CalculateLineTotals()` — no-op (GB uses standard period aggregation)

### ~~Step 5a. FR handler implementation~~
- Removed: FR period defaults are now handled by the Standard handler (Step 3), which checks `GetApplicationFamily()` to return FR-specific or W1 defaults.

### Step 5b. Small Business handler implementation
- File: `App/src/Core/Implementations/PaymPracSmallBusHandler.Codeunit.al` (new)
- Implements both `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler`
- `GetDefaultPaymentPeriods()` — returns Code `'AU-DEFAULT'`, Description `'AU/NZ Payment Periods (0-30, 31-60, 61+)'`, and AU line defaults (0-30, 31-60, 61+ days) per Payment Times Reporting Rules 2024 s13(2)(e)
- `ValidateHeader()` — errors if `Header Type` is `Customer` or `Vendor+Customer`. AU legislation covers supplier payments only; same pattern as `PaymPracSizeAggregator.ValidateHeader()`.
- `UpdatePaymentPracData()` — checks `Vendor."Small Business Supplier"`: returns `true` for small-business vendors (include), `false` otherwise (skip). Same pattern as `Exclude from Pmt. Practices` — non-small-business vendors are never inserted into the data set.
- `CalculateHeaderTotals()` — populates total number and value of invoices
- `CalculateLineTotals()` — populates per-bucket invoice count and value

### Step 6. Add `Reporting Scheme` and `Payment Period Code` fields to Payment Practice Header (table 687)
- Field: `field(15; "Reporting Scheme"; Enum "Paym. Prac. Reporting Scheme")`
- **OnInsert** (silent, no `Validate()` call — same pattern as `Aggregation Type` which uses `InitValue`):
  1. `"Reporting Scheme" := DetectSchemeFromAppFamily()` (GB → `Dispute & Retention`, AU/NZ → `Small Business`, all others → `Standard`)
  2. `"Payment Period Code" := FindDefaultPeriodCode("Reporting Scheme")` — looks up `Payment Period Header` where `Reporting Scheme` matches and `Default = true`; blank if none found
- **OnValidate** (user-initiated change only):
  1. Same confirm-and-clear pattern as `Aggregation Type` field (warns if lines exist)
  2. Look for an existing `Payment Period Header` where `"Reporting Scheme" = SelectedScheme AND Default = true`
  3. **Found** → set `Payment Period Code` to it
  4. **Not found** → show confirm dialog: *"Default payment period template for scheme [Scheme Name] does not exist. Do you want to create it?"*
     - **Yes** → create `Payment Period Header` + Lines from `GetDefaultPaymentPeriods()` with `Default = true`, set `Payment Period Code`
     - **No** → leave `Payment Period Code` blank. User must pick one manually before generation.
- Field: `field(16; "Payment Period Code"; Code[20])` — `TableRelation = "Payment Period Header"`, lets user pick **any** period template regardless of scheme (e.g., GB scheme with AU periods is allowed)
- **Generation guard:** `Generate()` must error if `Payment Period Code` is blank: *"You must select a Payment Period Code before generating."*
- In `PaymentPracticeCard.Page.al`: add Reporting Scheme to General group (above Aggregation Type), add Payment Period Code (below Reporting Scheme)

### Step 7. New Payment Period Header + Line tables (template pattern, replaces old Payment Period table)
- **Pattern:** Same as SAF-T's G/L Account Mapping Header + Lines — a reusable "template" that Payment Practice Header references
- **New table: `Payment Period Header`** (ID 680)
  - `field(1; Code; Code[20])` — PK, e.g. "W1-DEFAULT", "FR-DEFAULT", "GB-DEFAULT", "AU-DEFAULT"
  - `field(2; Description; Text[250])` — e.g. "UK Payment Periods (0-30, 31-60, 61-120, 121+)"
  - `field(3; "Reporting Scheme"; Enum "Paym. Prac. Reporting Scheme")` — which reporting scheme this template was designed for (informational; does not restrict usage — any Payment Practice Header can reference any template)
  - `field(4; Default; Boolean)` — marks this template as the default for its `Reporting Scheme`. OnValidate enforces mutual exclusion: when set to `true`, clear `Default` on any other `Payment Period Header` with the same `Reporting Scheme`. At most one template per scheme can be default. Users can toggle this on the Payment Period Card to designate their own custom template as the default for a scheme.
  - OnDelete: cascade-delete child lines; block if referenced by any Payment Practice Header
- **New table: `Payment Period Line`** (ID 681)
  - `field(1; "Period Header Code"; Code[20])` — PK1, `TableRelation = "Payment Period Header"`
  - `field(2; "Line No."; Integer)` — PK2
  - `field(3; "Days From"; Integer)` — MinValue = 0, same validation as old table
  - `field(4; "Days To"; Integer)` — MinValue = 0, 0 = unlimited
  - `field(5; Description; Text[250])` — auto-generated ("0 to 30 days.", "More than 121 days.")
- **New page: `Payment Period Card`** (ID 690, PageType = ListPlus, like SAF-T's G/L Acc. Mapping Card)
  - Header fields (Code, Description, Reporting Scheme, Default) + subpage with lines
- **New page: `Payment Period List`** (ID 691) — browse/select period templates
- **New page: `Payment Period Subpage`** (ID 692, PageType = ListPart) — lines grid
- **Deprecate old table 685 `Payment Period`:**
  - Mark with `ObsoleteState = Pending`, `ObsoleteReason = 'Replaced by Payment Period Header + Payment Period Line tables.'`
  - **Upgrade codeunit:**
    1. Determine the environment's default template by calling `GetDefaultPaymentPeriods()` for the detected `GetApplicationFamily()` scheme.
    2. Compare old `Payment Period` rows against the new defaults: if the row count matches AND every row has the same `Days From` and `Days To` values, the user never customized periods → delete old rows, create the new default template (e.g., `GB-DEFAULT`) with `Default = true`. No "MIGRATED" template needed.
    3. If the old rows differ from the defaults (different count, or any `Days From`/`Days To` mismatch), the user had custom periods → create **both** templates:
       - `"MIGRATED"` — lines copied as-is from old table data, `Default = false`
       - The scheme's default template (e.g., `AU-DEFAULT`, `GB-DEFAULT`) — created from `GetDefaultPaymentPeriods()`, `Default = true`
       This ensures the legislatively correct template is always available for new headers, while existing data is preserved in MIGRATED. Users on the old period structure can continue using MIGRATED by selecting it explicitly.
    4. **Fix GB period code mismatch:** existing `InsertDefaultPeriods_GB()` uses code `'P61_90'` for the range 61–120 days. When comparing, treat `P61_90` with `Days From=61, Days To=120` as matching the new GB default. New template uses correct labels from the start.
  - Update old page 685 `Payment Periods` to show ObsoleteState warning or redirect to new list
  - **Backfill existing Payment Practice Headers:** After creating templates, the upgrade codeunit sets `"Reporting Scheme"` (auto-detected from `GetApplicationFamily()`) and `"Payment Period Code"` on all existing `Payment Practice Header` records where `"Payment Period Code"` is blank. When MIGRATED exists, existing headers are backfilled with `"MIGRATED"` (preserving their period structure). When only the default template exists (no customization detected), existing headers get the default template code. This ensures existing headers remain functional with the new generation guard that errors on blank `Payment Period Code`.
- **Install codeunit:** On fresh install, seed **one** default Payment Period Header by calling `GetDefaultPaymentPeriods()` for the detected `GetApplicationFamily()` scheme only: GB → `GB-DEFAULT`, FR → `FR-DEFAULT`, AU/NZ → `AU-DEFAULT`, all others → `W1-DEFAULT`. Only one template is created with `Default = true`. Additional templates for other schemes are auto-created on demand (with `Default = true`) when a user selects a Reporting Scheme whose default template doesn't exist yet (see Step 6 OnValidate).
- **Period Aggregator:** Update `PaymPracPeriodAggregator.Codeunit.al` to read lines from `Payment Period Line` filtered by the header's `Payment Period Code` instead of the old global `Payment Period` table
- **Usage flow:** User creates Payment Practice Header → Reporting Scheme auto-detects → OnValidate finds `Payment Period Header` where `Reporting Scheme` matches and `Default = true` → Payment Period Code auto-fills → user can change to **any** period template regardless of scheme, or edit the template's lines. To make a custom template the default: open Payment Period Card, set `Default = true` (automatically unsets the previous default for that scheme).

---

## Phase 2: Data Model Extensions

### Step 8. Extend Payment Practice Header (table 687) — GB fields

Fields are organized into logical groups matching the UK government reporting form sections and the page layout in Step 16.

#### Group A: Payment Statistics (calculated, Editable=false)
- field(20; "Total Number of Payments"; Integer) — ToolTip 'Specifies the total number of payments made during the reporting period.'
- field(21; "Total Amount of Payments"; Decimal) — ToolTip 'Specifies the total value of payments made during the reporting period.'
- field(22; "Total Amt. of Overdue Payments"; Decimal) — ToolTip 'Specifies the total value of payments not made within the agreed payment terms.'
- field(23; "Pct Overdue Due to Dispute"; Decimal) — ToolTip 'Specifies the percentage of payments not made within agreed terms due to disputes.'
- Note: field 15 is Reporting Scheme, field 16 is Payment Period Code (Step 6)

#### Group B: Payment Policies — Tick-Box Statements (fields 30–35, user-entered, per SI 2017/395 Schedule paras 5–8, 11)
- field(30; "Offers E-Invoicing"; Boolean) — ToolTip 'Specifies whether the company''s payment practices provide for electronic submission and tracking of invoices.' (para 6)
- field(31; "Offers Supply Chain Finance"; Boolean) — ToolTip 'Specifies whether the company''s payment practices include an arrangement under which a supplier can receive early payment from a finance provider.' (para 5)
- field(32; "Policy Covers Deduction Charges"; Boolean) — ToolTip 'Specifies whether the company''s practices and policies cover deducting sums from payments as a charge for remaining on a supplier list.' (para 8)
- field(33; "Has Deducted Charges in Period"; Boolean) — ToolTip 'Specifies whether the company has deducted sums from payments as a charge for remaining on a supplier list in this reporting period.' (para 11)
- field(34; "Is Payment Code Member"; Boolean) — ToolTip 'Specifies whether the company is a signatory to a code of conduct or standards on payment practices.' (para 7)
- field(35; "Payment Code Name"; Text[250]) — ToolTip 'Specifies the name of the payment code the company is a signatory to, e.g. Prompt Payment Code.' Editable only when `Is Payment Code Member` = true.

#### Group C: Construction Contract Retention (per 2025 Amendment Regulations)

**C.1 — Retention gate** (top-level tick-box):
- field(40; "Has Constr. Contract Retention"; Boolean) — ToolTip 'Specifies whether retention clauses are included in qualifying construction contracts during the reporting period.'
- All sub-groups below are visible only when `Has Constr. Contract Retention` = true.

**C.2 — Retention clause usage** (tick-box + conditional narrative):
- field(41; "Retention in All Contracts"; Boolean) — ToolTip 'Specifies whether all qualifying construction contracts with suppliers include retention clauses.'
- field(42; "Retention in Std Payment Terms"; Boolean) — ToolTip 'Specifies whether standard payment terms include retention clauses.'
- field(43; "Retention in Specific Circumstances"; Boolean) — ToolTip 'Specifies whether retention clauses are included only in specific circumstances.'
- field(44; "Retention Circumstances Desc."; Text[1024]) — ToolTip 'Describes the specific circumstances under which retention clauses are used.' Editable only when `Retention in Specific Circumstances` = true.

**C.3 — Contract sum threshold** (tick-box + conditional value):
- field(45; "Retention Above Contract Sum Only"; Boolean) — ToolTip 'Specifies whether retention clauses are only used above a specific contract sum.'
- field(46; "Retention Min Contract Sum"; Decimal) — ToolTip 'Specifies the minimum contract sum (£) above which retention clauses apply.' Editable only when `Retention Above Contract Sum Only` = true.

**C.4 — Standard retention percentage** (tick-box + conditional value):
- field(47; "Std Retention Pct Used"; Boolean) — ToolTip 'Specifies whether a standard percentage rate is used in retention clauses.'
- field(48; "Std Retention Pct"; Decimal) — ToolTip 'Specifies the standard retention percentage rate.' Editable only when `Std Retention Pct Used` = true.

**C.5 — Terms fairness practice** (tick-box + conditional narrative):
- field(49; "Retention Terms No More Onerous"; Boolean) — ToolTip 'Specifies whether there is a practice ensuring retention terms with suppliers are no more onerous than those applied to the company by its clients.'
- field(50; "Retention Terms Practice Desc."; Text[1024]) — ToolTip 'Describes the practice ensuring retention terms are no more onerous.' Editable only when `Retention Terms No More Onerous` = true.

**C.6 — Release mechanism** (narrative + tick-box + conditional narrative):
- field(51; "Release Mechanism Desc."; Text[1024]) — ToolTip 'Describes the standard mechanism for releasing retained amounts to suppliers.'
- field(52; "Retention Released in Stages"; Boolean) — ToolTip 'Specifies whether retention money is released in stages.'
- field(53; "Retention Stage Desc."; Text[1024]) — ToolTip 'Describes the stages at which retained amounts are released.' Editable only when `Retention Released in Stages` = true.

**C.7 — Retention statistics** (user-entered amounts + auto-calculated percentages, per Schedule 2 paras 10–11):
- Per the legislation, the two retention percentages require four underlying monetary amounts. BC cannot auto-calculate these from transaction data (retention is not a discrete ledger entry type, and "Sum B" is the receivables side — money withheld from the company by its clients — which is not visible from purchase ledgers). Therefore all amounts are user-entered, and the percentages are auto-calculated.
- field(54; "Retention Withheld from Suppliers"; Decimal) — ToolTip 'Specifies the overall value of monies deducted or retained from suppliers under retention clauses in qualifying construction contracts (Sum A/C per Schedule 2 paras 10–11).' (user-entered)
- field(55; "Retention Withheld by Clients"; Decimal) — ToolTip 'Specifies the overall value of monies deducted or retained by the company''s clients under retention clauses in qualifying construction contracts (Sum B per Schedule 2 para 10).' (user-entered)
- field(56; "Gross Payments Under Constr. Contracts"; Decimal) — ToolTip 'Specifies the overall value of payments made to suppliers under all qualifying construction contracts (Sum D per Schedule 2 para 11).' (user-entered)
- field(57; "Pct Retention vs Client Retention"; Decimal) — Editable=false, ToolTip 'Specifies the amount of retention withheld from suppliers as a percentage of the amount withheld against the company by its clients under qualifying construction contracts. Calculated as (Sum A / Sum B) × 100 per Schedule 2 para 10.'
- field(58; "Pct Retention vs Gross Payments"; Decimal) — Editable=false, ToolTip 'Specifies the amount of retention withheld from suppliers as a percentage of gross payments made to suppliers under qualifying construction contracts. Calculated as (Sum C / Sum D) × 100 per Schedule 2 para 11.'

### Step 9. Extend Payment Practice Data (table 686) — GB fields
- field(20; "Dispute Status"; Boolean) — ToolTip 'Specifies whether the invoice is flagged as disputed.'
- field(21; "Overdue Due to Dispute"; Boolean) — Editable=false, ToolTip 'Specifies whether the payment is overdue due to a dispute.'
- field(22; "SCF Payment Date"; Date) — Editable=true, ToolTip 'Specifies the date the supplier received payment under a supply chain finance (SCF) arrangement. When populated, this date is used instead of the payment posting date to calculate actual payment days.' — Auto-populated from VLE during data generation; user can override on Payment Practice Data page.

### Step 10. ~~Extend Payment Practice Data (table 686) — AU fields~~
- Removed: `Is Small Business Supplier` field is not needed — non-small-business vendors are excluded from data generation entirely for AU/NZ (same pattern as `Exclude from Pmt. Practices`).

### Step 11. Extend Payment Practice Line (table 688) — AU fields
- field(14; "Invoice Count"; Integer) — ToolTip 'Specifies the total number of invoices in this period.'
- field(15; "Invoice Value"; Decimal) — ToolTip 'Specifies the total value of invoices in this period.'

### Step 12a. Extend Vendor Ledger Entry table (BaseApp, table 25) — GB field
- field(xxx; "SCF Payment Date"; Date) — ToolTip 'Specifies the date the supplier received payment under a supply chain finance (SCF) arrangement. Used by Payment Practices reporting to calculate actual payment days.'
- This is the primary source: users or SCF integrations set this date on the VLE when the finance provider pays the supplier. During Payment Practice data generation, the value is copied to Payment Practice Data."SCF Payment Date".
- Add to Vendor Ledger Entries page (P29), Applied Vendor Entries page, and relevant payment journal pages with `Visible = false` (users can unhide via Personalize when needed; SCF is niche/UK-specific).
- No OnValidate sync — changes to `SCF Payment Date` on VLE are picked up on the next `Generate()` run. The VLE field is a plain data field with no triggers.

### Step 12b. Extend Vendor table (BaseApp, table 23) — AU field
- field(136; "Small Business Supplier"; Boolean) — ToolTip 'Specifies that this vendor is a small business supplier (annual turnover < AUD 10 million) for Payment Times Reporting.'
- Add to Vendor Card page in Payments group (same pattern as "Exclude from Pmt. Practices")

---

## Phase 3: Core Logic Integration

### Step 13. Update `PaymentPractices.Codeunit.al` (C689)
- In `Generate()`: call `SchemeHandler.ValidateHeader()` **before** data generation (same position as the existing `AggregationLinesAggregator.ValidateHeader()` call). After existing `GenerateTotals()`, call `SchemeHandler.CalculateHeaderTotals()`
- `UpdatePaymentPracData()` is **not** called here — it is called in Builders before `Insert()` (see Step 14)
- In `GenerateLines()`: after `PaymentPracticeLinesAggregator.GenerateLines()`, call `SchemeHandler.CalculateLineTotals()` for each line

### Step 14. Update `PaymentPracticeBuilders.Codeunit.al` (C688)
- Obtain the scheme handler from the header's `Reporting Scheme` enum field (`SchemeHandler := PaymentPracticeHeader."Reporting Scheme"`) — the header is already passed to Builders, so no new parameters or interface changes needed
- In `BuildPaymentPracticeDataForVendor()`: after `CopyFromInvoiceVendLedgEntry()` and before `Insert()`, call `if SchemeHandler.UpdatePaymentPracData(PaymentPracticeData) then PaymentPracticeData.Insert()`. This handles both enrichment (Dispute Status, SCF) and filtering (Small Business) in a single call — same skip-before-Insert pattern as the existing `Exclude from Pmt. Practices` check
- `CopyFromInvoiceVendLedgEntry()` extended to also copy `VendorLedgerEntry."SCF Payment Date"` → `PaymentPracticeData."SCF Payment Date"`. When populated, `UpdatePaymentPracData()` recalculates `"Actual Payment Days" := "SCF Payment Date" - "Invoice Received Date"`.
- In `BuildPaymentPracticeDataForCustomer()`: same pattern — `if SchemeHandler.UpdatePaymentPracData(PaymentPracticeData) then Insert()`. No SCF logic — SCF is a vendor-only arrangement

### ~~Step 15. Update `PaymentPracticeMath.Codeunit.al` (C693)~~
- Removed: The new calculation procedures (total payments, overdue amounts, dispute %, invoice count/value) are trivial single-use operations (SETRANGE + COUNT/CALCSUMS). They belong directly in the handler codeunits that call them (`PaymPracDisputeRetHandler` and `PaymPracSmallBusHandler`), not routed through a shared Math codeunit. No changes to `PaymentPracticeMath.Codeunit.al` — existing procedures remain as-is.

---

## Phase 4: Page Updates

### Step 16. Update `PaymentPracticeCard.Page.al` (P687)
- Add `Reporting Scheme` field to General group
- Add **Payment Policies** group (visible when `Reporting Scheme = Dispute & Retention`):
  - `Offers E-Invoicing` (Boolean tick-box)
  - `Offers Supply Chain Finance` (Boolean tick-box)
  - `Policy Covers Deduction Charges` (Boolean tick-box)
  - `Has Deducted Charges in Period` (Boolean tick-box)
  - `Is Payment Code Member` (Boolean tick-box)
  - `Payment Code Name` (Text, enabled only when `Is Payment Code Member` = true)
- Add **Payment Statistics** group (visible when `Reporting Scheme = Dispute & Retention`):
  - Total Number of Payments, Total Amount of Payments, Total Amt. of Overdue Payments, Pct Overdue Due to Dispute — all Editable=false
- Add **Construction Contract Retention** group (visible when `Reporting Scheme = Dispute & Retention`):
  - `Has Constr. Contract Retention` (user tick-box)
  - Sub-fields visible only when `Has Constr. Contract Retention` = true:
    - Retention in All Contracts, Retention in Std Payment Terms, Retention in Specific Circumstances + Circumstances Desc.
    - Retention Above Contract Sum Only + Min Contract Sum
    - Std Retention Pct Used + Std Retention Pct
    - Retention Terms No More Onerous + Practice Desc.
    - Retention Released in Stages + Release Mechanism Desc. + Stage Desc.
    - Retention Withheld from Suppliers, Retention Withheld by Clients, Gross Payments Under Constr. Contracts (user-entered amounts)
    - Pct Retention vs Client Retention (auto-calculated), Pct Retention vs Gross Payments (auto-calculated)
- Add trigger `OnAfterGetRecord` or use page variables to set visibility booleans based on Reporting Scheme

### Step 17. Update `PaymentPracticeLines.Page.al` (P688)
- Add Invoice Count, Invoice Value columns — visibility controlled by `Reporting Scheme = Small Business`

### Step 18. Update `PaymentPracticeDataList.Page.al` (P686)
- Add Dispute Status, Overdue Due to Dispute, SCF Payment Date columns — visibility controlled by Reporting Scheme
- Add Is Small Business Supplier column — ~~visible for AU~~ removed (non-small vendors excluded from data entirely)

### Step 19. Update Vendor Card (BaseApp)
- Add Small Business Supplier field in Payments group, after "Exclude from Pmt. Practices"

---

## Phase 5: Report & Export

### Step 20. GB CSV export
- New codeunit or report extension for CSV generation per UK government format
- Triggered from Payment Practice Card action, gated by Reporting Scheme = Dispute & Retention
- Fields: company name/number, reporting period, payment statistics, tick-box policy statements, construction contract retention data
- **Tick-box policy statements (resolved):** Per SI 2017/395 Schedule paras 5–8 & 11 and the 2025 Amendment, the GB report requires 6 Yes/No tick-box fields and 1 conditional text field on Payment Practice Header (fields 30–35): Offers E-Invoicing, Offers Supply Chain Finance, Policy Covers Deduction Charges, Has Deducted Charges in Period, Is Payment Code Member, Payment Code Name. These are all user-entered policy declarations — not auto-calculated from data.
- **Construction retention section** (conditional on `Has Constr. Contract Retention` = true): additional tick-box + narrative fields (fields 40–53) for retention clause usage, contract sum thresholds, standard retention percentage, terms fairness practice, and release mechanism. Retention statistics (fields 57–58) are auto-calculated from user-entered amounts (fields 54–56).
- CSV mapping: each Boolean → "Yes"/"No" string, each Text → value, each Decimal → formatted number. Column layout matches the UK government's CSV export schema from check-payment-practices.service.gov.uk.
- **⚠️ Needs design before implementation:** Exact CSV column order, column headers, date/number formatting rules, file encoding (UTF-8 with/without BOM), and line endings need to be specified based on the UK government portal's actual import schema. Field-to-column mapping table to be added.

### Step 21. AU CSV export + Declaration document
- New codeunit or report for delimited text file per AU government schema (per 31072025-Payment-Times-Reports-Register.xlsx, "Standard Report" tab)
- Declaration document (Word layout) with officer name, signature block, ABN
- Triggered from Payment Practice Card action, gated by Reporting Scheme = Small Business
- **⚠️ Needs design before implementation:** Exact delimited file format (delimiter, quoting, encoding), column mapping from Payment Practice Header/Line fields to AU government schema columns, declaration document Word layout fields, and ABN source field to be specified.

---

## Phase 6: Tests

### Step 22. Standard regression tests
- Ensure all existing tests pass unchanged when Reporting Scheme = Standard
- Verify that Generate produces same results as before

### Step 23. Reporting Scheme switching tests
- Create header with Dispute & Retention → verify dispute/retention fields populated
- Create header with Small Business → verify small business fields populated
- Switch Reporting Scheme → verify confirm dialog, lines cleared

### Step 24. Dispute & Retention-specific tests
- Dispute Status flows from VLE to PaymentPracticeData
- SCF Payment Date copied from VLE to PaymentPracticeData during generation
- SCF Payment Date manually entered on PaymentPracticeData overrides VLE value
- When SCF Payment Date is populated, Actual Payment Days = SCF Payment Date - Invoice Received Date (not Pmt. Posting Date)
- When SCF Payment Date is blank, Actual Payment Days uses Pmt. Posting Date as before
- Total Number/Amount of Payments calculated correctly
- Pct Overdue Due to Dispute calculated correctly
- Construction contract retention: all header-level user-entered fields + auto-calculated retention percentages from user-entered amounts
- CSV export includes retention fields when `Has Constr. Contract Retention` = true

### Step 25. Small Business-specific tests
- Small Business Supplier flag flows from Vendor to PaymentPracticeData
- Invoice Count and Invoice Value per period bucket calculated correctly
- Only small business vendors included in AU generation (non-small vendors produce zero data rows)

---

## Relevant Files

### New files to create (10+):

#### Object ID Assignments
| Type | ID | Object |
|------|----|--------|
| Enum | 680 | Paym. Prac. Reporting Scheme |
| Table | 680 | Payment Period Header |
| Table | 681 | Payment Period Line |
| Page | 690 | Payment Period Card |
| Page | 691 | Payment Period List |
| Page | 692 | Payment Period Subpage |
| Codeunit | 680 | Paym. Prac. Standard Handler |
| Codeunit | 681 | Paym. Prac. Dispute & Ret. Handler |
| Codeunit | 682 | Paym. Prac. Small Bus. Handler |
| Codeunit | 683 | Upgrade Payment Practices |
| Codeunit | 684 | Paym. Prac. GB CSV Export |
| Codeunit | 694 | Paym. Prac. AU CSV Export |
| Report | 680 | AU Declaration (if Word layout needed) |

#### New files:
- `App/src/Core/Enums/PaymPracReportingScheme.Enum.al` — Reporting Scheme enum (680)
- `App/src/Core/Interfaces/PaymPracDefaultPeriods.Interface.al` — Default periods interface (setup-time)
- `App/src/Core/Interfaces/PaymPracSchemeHandler.Interface.al` — Scheme handler interface (generation-time)
- `App/src/Core/Implementations/PaymPracStandardHandler.Codeunit.al` — Standard handler, W1/FR (C680)
- `App/src/Core/Implementations/PaymPracDisputeRetHandler.Codeunit.al` — Dispute & Retention handler, GB (C681)
- `App/src/Core/Implementations/PaymPracSmallBusHandler.Codeunit.al` — Small Business handler, AU/NZ (C682)
- `App/src/Tables/PaymentPeriodHeader.Table.al` — Payment Period Header (T680)
- `App/src/Tables/PaymentPeriodLine.Table.al` — Payment Period Line (T681)
- `App/src/Pages/PaymentPeriodCard.Page.al` — Card page, ListPlus (P690)
- `App/src/Pages/PaymentPeriodList.Page.al` — List page (P691)
- `App/src/Pages/PaymentPeriodSubpage.Page.al` — ListPart subpage (P692)

### Existing files to modify (14):
- `App/src/Tables/PaymentPracticeHeader.Table.al` — add Reporting Scheme + Dispute & Retention header fields
- `App/src/Tables/PaymentPracticeData.Table.al` — add Dispute & Retention data fields
- `App/src/Tables/PaymentPracticeLine.Table.al` — add Small Business line fields
- `App/src/Tables/PaymentPeriod.Table.al` — deprecate (ObsoleteState = Pending)
- `App/src/Pages/PaymentPeriods.Page.al` — deprecate or redirect to new list
- `App/src/Core/Implementations/PaymPracPeriodAggregator.Codeunit.al` — read from Payment Period Line via header's Payment Period Code
- `App/src/Core/PaymentPractices.Codeunit.al` — integrate scheme handler into Generate flow
- `App/src/Core/PaymentPracticeBuilders.Codeunit.al` — call handler's `UpdatePaymentPracData()`
- `App/src/Core/InstallPaymentPractices.Codeunit.al` — use reporting scheme for period defaults
- `App/src/Pages/PaymentPracticeCard.Page.al` — Reporting Scheme field + conditional visibility
- `App/src/Pages/PaymentPracticeLines.Page.al` — Small Business-specific columns
- `App/src/Pages/PaymentPracticeDataList.Page.al` — Dispute & Retention / Small Business-specific columns
- `App/app.json` — idRanges expanded to 680–698 ✓
- `Test/src/PaymentPracticesUT.Codeunit.al` — new test scenarios
- `Test/src/PaymentPracticesLibrary.Codeunit.al` — new test helpers

### BaseApp files to modify (4):
- `W1/BaseApp/Purchases/Vendor/Vendor.Table.al` — add field(136; "Small Business Supplier"; Boolean)
- `W1/BaseApp/Purchases/Vendor/VendorCard.Page.al` — show Small Business Supplier field
- `W1/BaseApp/Purchases/Payables/VendorLedgerEntry.Table.al` — add field(xxx; "SCF Payment Date"; Date)
- `W1/BaseApp/Purchases/Payables/VendorLedgerEntries.Page.al` — show SCF Payment Date field

---

## Decisions

- **Reporting Scheme auto-detection:** Default from `GetApplicationFamily()` but user-editable on each header (GB → `Dispute & Retention`, AU/NZ → `Small Business`, all others → `Standard`)
- **Backward compatibility:** Standard enum value = existing behavior, no regression
- **Single app:** Everything stays in W1 Payment Practices app, enum-driven branching
- **Editable periods:** Old `Payment Period` table (685) deprecated. New `Payment Period Header` + `Payment Period Line` template tables (SAF-T pattern). Users create named period configurations with line rows, select them on Payment Practice Header. Defaults seeded per reporting scheme on install.
- **Small Business Supplier:** New Boolean field on Vendor (field 136), follows "Exclude from Pmt. Practices" pattern
- **SCF Payment Date:** Dual-source approach — primary source is a new Date field on Vendor Ledger Entry (set by user or SCF integration at payment time), copied to Payment Practice Data during generation. User can also manually enter/override on the Payment Practice Data page before generating totals. When populated, replaces `Pmt. Posting Date` in `Actual Payment Days` calculation. SCF is vendor-only (buyer pays finance provider, finance provider pays supplier early) — no SCF logic on the customer side.

---

## Dependencies & Sequencing

- **PR 230768** (Dispute Status on Purchase) — merged ✓
- Phase 1 (infrastructure) can start immediately — no external dependencies
- Phase 2 (data model) can run parallel with Phase 1
- Phase 3 (logic) depends on Phase 1 + 2
- Phase 4 (pages) depends on Phase 1 + 2
- Phase 5 (exports) depends on Phase 3
- Phase 6 (tests) depends on all above
- Steps within the same phase can run in parallel

---

## Open Questions for PM

1. ~~**FR period defaults** (Step 3)~~ — **Resolved.** French regulation (Article D441-4, Code de Commerce, Décret 2016-645) requires a table with exactly 4 aging brackets: 1–30, 31–60, 61–90, 91+ days. The existing `InsertDefaultPeriods_FR()` already uses these correct buckets. France has fewer buckets than W1 because the legal maximum payment term is 60 days from invoice (Art. L441-10), so anything beyond 90 days is deeply overdue. The Standard handler checking `GetApplicationFamily()` to return FR-specific defaults is sufficient — FR does not need its own reporting scheme.

2. ~~**SCF Payment Date logic** (Step 4)~~ — **Resolved.** SCF (reverse factoring) is a vendor-side arrangement where a finance provider pays the supplier early. `SCF Payment Date` is a dual-source field: auto-populated from a new VLE field during data generation, and user-editable on Payment Practice Data. When populated, it replaces `Pmt. Posting Date` in `Actual Payment Days` calculation. Full vs. partial SCF is not auto-distinguished; user enters the correct date per UK regulation guidance. See Step 4, Step 9, Step 12a, Step 14, and Decisions section for details.

3. ~~**GB tick-box policy statements** (Step 20)~~ — **Resolved.** Per UK SI 2017/395 Schedule (paras 5–8, 11) and the Reporting on Payment Practices and Performance (Amendment) Regulations 2025, the exact list of tick-box policy statements is: (1) Offers E-Invoicing, (2) Offers Supply Chain Finance, (3) Policy Covers Deduction Charges, (4) Has Deducted Charges in Period, (5) Is Payment Code Member + Payment Code Name, (6) Has Constr. Contract Retention (already planned). When retention = Yes, additional sub-questions: retention in all contracts vs. specific circumstances, contract sum threshold, standard retention %, terms fairness practice, and release mechanism — each a Boolean + conditional narrative text. All fields are **Boolean fields on Payment Practice Header** (not a separate table), because they are 1:1 with a single report — the UK gov portal collects them as flat form fields on a single report page. Fields 30–58 added to Step 8. See Step 8, Step 16, and Step 20 for details.

4. ~~**AU period boundaries** (Step 5b)~~ — **Resolved.** Payment Times Reporting Rules 2024 (F2024L01148, compiled 25 Feb 2025 as F2025C00169), Section 13(2)(e) requires only **3 statutory period buckets**: ≤30 days, 31–60 days, >60 days (plus a "paid on time" % where payment time ≤ payment term). The old 5/6-bucket schemes in existing code and ADO originate from the pre-reform Payment Times Reporting Rules 2020, which only apply to reporting periods that began before 1 July 2024 (Section 100). The 20-day threshold is for "Fast Small Business Payer" recognition (Section 20), not a period bucket. No 2025/2026 amendments change report content. The new handler defaults use the 3 statutory buckets: 0-30, 31-60, 61+.

5. **GB-only fields on Payment Practice Header (Step 8)** — Step 8 adds 30+ fields (IDs 20–58) to the shared Payment Practice Header table, but almost all are only relevant when Reporting Scheme = `Dispute & Retention`. For `Standard` and `Small Business` headers these are dead columns. Should we move the GB-specific fields (Groups B and C: fields 30–58) to a separate 1:1 linked table (e.g. `Payment Practice GB Details`) to keep the header table clean? Trade-off: cleaner data model vs. extra join and slightly more complex page logic.
