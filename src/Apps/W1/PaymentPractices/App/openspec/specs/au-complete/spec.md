# AU / Small Business — Complete Specification

> **Audience:** Developer implementing the AU portion of Payment Practices.
> **Status:** Specification — not yet implemented.
> **Branch context:** The W1/GB branch (`features/629871-master-Payment-Practices-W1-GB`) already contains a working prototype of AU code. That prototype code will be **removed** from the branch. This spec describes everything the AU implementor must build from scratch, including shared-file modifications.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Object ID Assignments](#2-object-id-assignments)
3. [Enum: Add Small Business Value](#3-enum-add-small-business-value)
4. [Small Business Handler Codeunit](#4-small-business-handler-codeunit)
5. [Vendor Extension: Small Business Supplier Field](#5-vendor-extension-small-business-supplier-field)
6. [Payment Practice Line: Invoice Count & Invoice Value](#6-payment-practice-line-invoice-count--invoice-value)
7. [Core Logic Integration](#7-core-logic-integration)
8. [Page Modifications](#8-page-modifications)
9. [AU CSV Export](#9-au-csv-export)
10. [AU Declaration Report](#10-au-declaration-report)
11. [Install Codeunit Changes](#11-install-codeunit-changes)
12. [Upgrade Codeunit Changes](#12-upgrade-codeunit-changes)
13. [Legacy Payment Period Table: AU/NZ Defaults](#13-legacy-payment-period-table-aunz-defaults)
14. [Tests](#14-tests)
15. [Open Design Questions](#15-open-design-questions)
16. [File Inventory](#16-file-inventory)

---

## 1. Architecture Overview

The Payment Practices app uses a **Reporting Scheme** enum (ID 680) that implements one interface:
- `PaymentPracticeSchemeHandler` — controls generation behavior (generation-time)

Payment period defaults are managed by the legacy `Payment Period` table (T685) with its `SetupDefaults()` method, which branches by `GetApplicationFamily()`. There is no template/header system — just a single set of period rows.

```
┌──────────────────────────────────────────────────────────────────┐
│              Enum 680: Paym. Prac. Reporting Scheme              │
│                  Extensible = true                               │
│                  Implements: PaymentPracticeSchemeHandler         │
├────────────────┬─────────────────────┬───────────────────────────┤
│ Standard (0)   │ Dispute & Ret. (1)  │ Small Business (2)        │
│ W1/FR          │ GB/UK               │ AU/NZ                     │
│ C680 handler   │ C681 handler        │ C682 handler ← YOU BUILD  │
└────────────────┴─────────────────────┴───────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Generate() │
                    │  C689       │
                    └──────┬──────┘
                           │
              ┌────────────▼────────────┐
              │ PaymentPracticeBuilders │
              │ C688                    │
              │                        │
              │ For each vendor invoice:│
              │  SchemeHandler          │
              │   .UpdatePaymentPrac   │
              │   Data(row)            │
              │  → true = insert       │
              │  → false = skip        │
              └────────────┬───────────┘
                           │
              ┌────────────▼────────────┐
              │ Period/Size Aggregator  │
              │  For each line:         │
              │   SchemeHandler         │
              │    .CalculateLineTotals │
              └─────────────────────────┘

  Period buckets come from Payment Period table (T685)
  — one global set of rows, seeded per ApplicationFamily
  — no user-editable templates
```

### Interface: PaymentPracticeSchemeHandler

```al
interface PaymentPracticeSchemeHandler
{
    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header");
    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean;
    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data");
    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data");
}
```

### Key Shared Objects (already exist, you modify)

| Object | ID | Purpose |
|---|---|---|
| Paym. Prac. Reporting Scheme | Enum 680 | Add value `"Small Business" (2)` |
| Payment Practice Header | Table 687 | Has field 15 `"Reporting Scheme"` — auto-detects from ApplicationFamily |
| Payment Practice Line | Table 688 | Add fields 15-16 for Invoice Count/Value |
| Payment Practice Builders | Codeunit 688 | Already calls `SchemeHandler.UpdatePaymentPracData()` — no change needed |
| Paym. Prac. Period Aggregator | Codeunit 685 | Already calls `SchemeHandler.CalculateLineTotals()` + Invoice Count/Value Modify — no change needed |
| Paym. Prac. Size Aggregator | Codeunit 686 | Same — already has CalculateLineTotals + Invoice Count/Value Modify — no change needed |
| Payment Period Mgt. | Codeunit 695 | `DetectReportingScheme()` — already has AU/NZ case + integration event — no change needed |
| Install Payment Practices | Codeunit 687 | Calls `PaymentPeriod.SetupDefaults()` — no change needed |
| Upgrade Payment Practices | Codeunit 683 | Backfills Reporting Scheme via `DetectReportingScheme()` — no change needed |
| Payment Period | Table 685 | Add `InsertDefaultPeriods_AUNZ()` |
| Payment Practice Card | Page 687 | Already has AU CSV export action + IsSmallBusiness visibility — no change needed |
| Payment Practice Lines | Page 688 | Already has Invoice Count/Value columns + IsSmallBusiness visibility — no change needed |

---

## 2. Object ID Assignments

| Type | ID | Name | Status |
|---|---|---|---|
| Enum value | 680 value 2 | "Small Business" | Add to existing enum |
| Codeunit | 682 | Paym. Prac. Small Bus. Handler | **New** |
| Codeunit | 694 | Paym. Prac. AU CSV Export | **New** |
| Report | 680 | Paym. Prac. AU Declaration | **New** |
| Table Extension | 680 | Paym. Prac. Vendor (extends Vendor) | **New** |
| Page Extension | 680 | Paym. Prac. Vendor Card | **New** |

---

## 3. Enum: Add Small Business Value

### Requirement: Small Business enum value exists
The enum `Paym. Prac. Reporting Scheme` (ID 680) SHALL have a value `"Small Business"` (ordinal 2) that maps `PaymentPracticeSchemeHandler` to `"Paym. Prac. Small Bus. Handler"` (C682).

**NOTE:** This value already exists in the current branch. If the AU prototype code is stripped, this value will be removed and the colleague must re-add it.

#### Scenario: Enum value dispatches to AU handler
- **WHEN** a Payment Practice Header has Reporting Scheme = Small Business
- **THEN** `PaymentPracticeSchemeHandler` dispatches to C682

### File to modify
`App/src/Core/Enums/PaymPracReportingScheme.Enum.al`

Add after the `"Dispute & Retention"` value block:
```al
value(2; "Small Business")
{
    Implementation = PaymentPracticeSchemeHandler = "Paym. Prac. Small Bus. Handler";
}
```

---

## 4. Small Business Handler Codeunit

### Requirement: Handler implements PaymentPracticeSchemeHandler
Codeunit `Paym. Prac. Small Bus. Handler` (C682) SHALL implement `PaymentPracticeSchemeHandler` for the `Small Business` enum value. It has 4 methods: `ValidateHeader`, `UpdatePaymentPracData`, `CalculateHeaderTotals`, `CalculateLineTotals`.

### Requirement: ValidateHeader rejects Customer and Vendor+Customer
AU legislation covers supplier (vendor) payments only.

#### Scenario: Vendor header type allowed
- **WHEN** Header Type = Vendor → validation passes

#### Scenario: Customer header type rejected
- **WHEN** Header Type = Customer → error raised

#### Scenario: Vendor+Customer header type rejected
- **WHEN** Header Type = Vendor+Customer → error raised

### Requirement: Non-small-business vendors excluded from data generation
`UpdatePaymentPracData()` SHALL check `Vendor."Small Business Supplier"`:
- `true` → return `true` (include the row)
- `false` → return `false` (skip the row)

#### Scenario: Small business vendor included
- **WHEN** vendor has Small Business Supplier = true → row included in Payment Practice Data

#### Scenario: Non-small-business vendor excluded
- **WHEN** vendor has Small Business Supplier = false → row NOT inserted

### Requirement: CalculateHeaderTotals populates total invoice count and value
The handler SHALL count and sum closed invoices (Invoice Is Open = false) from Payment Practice Data.

#### Scenario: Header totals
- **WHEN** generation completes with 50 closed invoices totaling $250,000
- **THEN** header shows Total Number of Payments = 50, Total Amount of Payments = 250000

### Requirement: CalculateLineTotals populates per-bucket invoice count and value
The handler SHALL populate `Invoice Count` and `Invoice Value` on each Payment Practice Line by counting and summing closed invoices within the line's scope.

#### Scenario: Invoice count and value per period
- **WHEN** Small Business header generates period lines and 10 invoices totaling $50,000 fall in the 0-30 bucket
- **THEN** the 0-30 line has Invoice Count = 10, Invoice Value = 50000

#### Scenario: Invoice count and value per company size
- **WHEN** Small Business header generates company size lines and 5 invoices totaling $25,000 belong to a size code
- **THEN** the size line has Invoice Count = 5, Invoice Value = 25000

#### Scenario: Open invoices not counted
- **WHEN** an invoice has Invoice Is Open = true
- **THEN** not included in Invoice Count or Invoice Value

### File to create
`App/src/Core/Implementations/PaymPracSmallBusHandler.Codeunit.al`

---

## 5. Vendor Extension: Small Business Supplier Field

### Requirement: Small Business Supplier field on Vendor
A table extension SHALL add field `"Small Business Supplier"` (Boolean, field ID 680) to the Vendor table. DataClassification = CustomerContent.

#### Scenario: Vendor marked as small business
- **WHEN** user sets Small Business Supplier = true on a Vendor Card
- **THEN** the vendor is included in Small Business scheme generation

#### Scenario: Default is false
- **WHEN** Small Business Supplier is not set (default = false)
- **THEN** the vendor is excluded from Small Business scheme generation

### Requirement: Field visible on Vendor Card
A page extension SHALL add the field to the Vendor Card page in the Payments group, after "Block Payment Tolerance" (same pattern as "Exclude from Pmt. Practices").

### Files to create
- `App/src/Tables/PaymPracVendor.TableExt.al` (table extension 680)
- `App/src/Pages/PaymPracVendorCard.PageExt.al` (page extension 680)

---

## 6. Payment Practice Line: Invoice Count & Invoice Value

### Requirement: Invoice Count and Invoice Value fields exist
Table `Payment Practice Line` (T688) SHALL have:
- `field(15; "Invoice Count"; Integer)` — ToolTip: 'Specifies the number of invoices in this period.'
- `field(16; "Invoice Value"; Decimal)` — AutoFormatType = 1, ToolTip: 'Specifies the total value of invoices in this period.'

These fields are populated by `CalculateLineTotals()` in the Small Business handler and are only meaningful for the Small Business scheme.

### File to modify
`App/src/Tables/PaymentPracticeLine.Table.al` — add fields 15 and 16.

---

## 7. Core Logic Integration

### 7.1 Period Aggregator

#### Already done — no changes needed
The `Paym. Prac. Period Aggregator` (C685) already calls `SchemeHandler.CalculateLineTotals()` for each generated line and persists via Modify if Invoice Count or Invoice Value is non-zero. This code reads from the `Payment Period` table (T685) directly — there are no template tables.

### 7.2 Size Aggregator

#### Already done — no changes needed
The `Paym. Prac. Size Aggregator` (C686) already has the same pattern — CalculateLineTotals + conditional Modify for Invoice Count/Value.

### 7.3 Builders

#### Requirement: SchemeHandler.UpdatePaymentPracData called before Insert
The `Payment Practice Builders` (C688) already has the integration point:
```al
SchemeHandler := PaymentPracticeHeader."Reporting Scheme";
...
if SchemeHandler.UpdatePaymentPracData(PaymentPracticeData) then
    PaymentPracticeData.Insert();
```
**No changes needed** in Builders — the Small Business handler's `UpdatePaymentPracData()` will automatically be dispatched when Reporting Scheme = Small Business.

### 7.4 PaymentPeriodMgt — Reporting Scheme Detection

#### Already done — no changes needed
`PaymentPeriodMgt.DetectReportingScheme()` (C695) already returns `"Small Business"` for AU/NZ. It also has an `OnBeforeDetectReportingScheme` integration event for partner overrides.

Current code:
```al
case EnvironmentInformation.GetApplicationFamily() of
    'GB':
        exit("Paym. Prac. Reporting Scheme"::"Dispute & Retention");
    'AU', 'NZ':
        exit("Paym. Prac. Reporting Scheme"::"Small Business");
    else
        exit("Paym. Prac. Reporting Scheme"::Standard);
end;
```

---

## 8. Page Modifications

### 8.1 Payment Practice Card — AU Export Action

#### Already done — no changes needed
The Payment Practice Card (P687) already has an `ExportAUCSV` action with `Visible = IsSmallBusiness`, the `IsSmallBusiness` boolean variable, and `UpdateVisibility()` logic. The action calls `PaymPracAUCSVExport.Export(Rec)` — the colleague just needs to create the codeunit it references (C694).

### 8.2 Payment Practice Lines — Invoice Count/Value Columns

#### Already done — no changes needed
The Payment Practice Lines page (P688) already has Invoice Count and Invoice Value field controls with `Visible = IsSmallBusiness`, and the `UpdateVisibility` procedure already accepts `newReportingScheme` and sets `IsSmallBusiness`.

---

## 9. AU CSV Export

### Requirement: AU CSV export codeunit exists
Codeunit `Paym. Prac. AU CSV Export` (C694) SHALL generate a delimited text file per the AU government Payment Times Reports Register format.

#### Scenario: Export triggered from Payment Practice Card
- **WHEN** user invokes AU CSV export on a Small Business card
- **THEN** a delimited text file is generated and downloaded

#### Scenario: Export blocked for wrong scheme
- **WHEN** user attempts AU CSV export on a non-Small Business card
- **THEN** error is raised

### Requirement: Export includes header-level totals
The export SHALL include total number of invoices and total value of invoices from the Payment Practice Header.

### Requirement: Export includes period-aggregated invoice data
The export SHALL include per-period Invoice Count, Invoice Value, and payment timing percentages from Payment Practice Lines.

### ⚠️ Requirement: Export format details — NEEDS DESIGN
The exact delimited file format (delimiter, quoting, encoding), column mapping to AU government schema (per Payment Times Reporting Rules 2024 and the "Standard Report" tab of the Payment Times Reports Register spreadsheet), and field ordering SHALL be specified before implementation begins.

**Research needed:**
- Download the current AU government template from the Payment Times Reporting portal
- Map each BC field to the government column
- Determine delimiter (comma/tab/pipe), quoting rules, encoding (UTF-8 with/without BOM)
- Determine whether the export is a flat columnar format (like GB) or key-value pairs

### File to create
`App/src/Core/PaymPracAUCSVExport.Codeunit.al`

---

## 10. AU Declaration Report

### Requirement: AU declaration document
Report `Paym. Prac. AU Declaration` (R680) SHALL provide a Word-layout declaration document with:
- Payment Practice Header data: No., Starting Date, Ending Date, Total Number of Payments, Total Amount of Payments
- Request page fields: Officer Name, ABN (Australian Business Number)
- Statutory declaration text as required by Payment Times Reporting Rules 2024

#### Scenario: Declaration generated for Small Business scheme
- **WHEN** user invokes AU declaration on a Small Business card
- **THEN** a declaration document is generated

### ⚠️ Requirement: Declaration layout — NEEDS DESIGN
The Word layout must include proper statutory text per AU regulations. The exact text, formatting, and signature block design need to be confirmed against the Payment Times Reporting portal's requirements.

### Files to create
- `App/src/Reports/PaymPracAUDeclaration.Report.al`
- `App/src/Reports/PaymPracAUDeclaration.docx` (Word layout)

---

## 11. Install Codeunit Changes

### Already done — no changes needed
On fresh install, `InstallPaymentPractices.SetupPaymentPractices()` calls `PaymentPeriod.SetupDefaults()`. This branches by `GetApplicationFamily()` inside the Payment Period table and seeds the correct period rows. For AU/NZ, it will call `InsertDefaultPeriods_AUNZ()` (which must exist in T685 — see section 13).

The install codeunit itself needs no AU-specific changes.

---

## 12. Upgrade Codeunit Changes

### Already done — no changes needed
The upgrade codeunit (C683) simply backfills `Reporting Scheme` on existing Payment Practice Headers by calling `DetectReportingScheme()`. For AU/NZ, this sets `Reporting Scheme = Small Business`. There is no period template migration — period rows live in the simple `Payment Period` table (T685).

Current upgrade logic:
```al
local procedure BackfillReportingScheme()
var
    PaymentPracticeHeader: Record "Payment Practice Header";
    PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
    ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
begin
    ReportingScheme := PaymentPeriodMgt.DetectReportingScheme();
    PaymentPracticeHeader.SetRange("Reporting Scheme", 0);
    if PaymentPracticeHeader.FindSet() then
        repeat
            PaymentPracticeHeader."Reporting Scheme" := ReportingScheme;
            PaymentPracticeHeader.Modify();
        until PaymentPracticeHeader.Next() = 0;
end;
```

No AU-specific changes needed.

---

## 13. Payment Period Table: AU/NZ Defaults

### Already done — AU/NZ defaults exist
The `Payment Period` table (T685) already has AU/NZ support. The `SetupDefaults()` method branches by `GetApplicationFamily()` and calls `InsertDefaultPeriods_AUNZ()` for 'AU' and 'NZ'.

Current AU/NZ defaults:
```
P0_21:   0 to 21 days
P22_30: 22 to 30 days
P31_60: 31 to 60 days
P61_90: 61 to 120 days
P121+: 121+ days
```

These are 5 finer-grained buckets. The Period Aggregator uses these rows directly for bucketing during generation.

**No changes needed** — this code is already in place.

### Open question: Are 5 buckets correct for AU?
The 2024 legislation (Payment Times Reporting Rules 2024 s13(2)(e)) specifies 3 buckets (0-30, 31-60, 61+). The current code has 5 buckets (0-21, 22-30, 31-60, 61-120, 121+). Confirm the bucket definitions match current AU regulatory requirements. If they need changing, modify `InsertDefaultPeriods_AUNZ()` in T685.

---

## 14. Tests

### Requirements

#### Test: Small Business ValidateHeader rejects Customer
- Create header with Small Business scheme + Customer type
- Call Generate() → expect error

#### Test: Small Business ValidateHeader rejects Vendor+Customer
- Create header with Small Business scheme + Vendor+Customer type
- Call Generate() → expect error

#### Test: Non-small-business vendor excluded
- Create vendor without Small Business Supplier flag
- Create invoice, generate with Small Business scheme
- Verify 0 data rows

#### Test: Small business vendor included
- Create vendor with Small Business Supplier = true
- Create invoice, generate with Small Business scheme
- Verify 1 data row

#### Test: Invoice Count and Value per period bucket
- Create small business vendor with multiple invoices in different payment day ranges
- Generate with Small Business scheme + Period aggregation
- Verify each Payment Practice Line has correct Invoice Count and Invoice Value

#### Test: Invoice Count and Value per company size
- Create small business vendor with company size, create invoices
- Generate with Small Business scheme + Company Size aggregation
- Verify Invoice Count and Invoice Value on size lines

#### Test: Header totals reflect all small business invoices
- Generate and verify Total Number of Payments and Total Amount of Payments on header

#### Test: AU CSV export (once format is finalized)
- Generate, export, verify file contents match expected format

#### Test: AU Declaration report (once layout is finalized)
- Generate, run report, verify dataset includes correct fields

### Test library helpers needed
- `CreateSmallBusinessVendor()` — creates vendor with Small Business Supplier = true
- `CreatePaymentPracticeHeaderWithScheme()` — creates header with specified scheme (may already exist in library)

### Files to modify
- `Test/src/PaymentPracticesUT.Codeunit.al`
- `Test Library/src/PaymentPracticesLibrary.Codeunit.al`

---

## 15. Open Design Questions

### ⚠️ AU Government CSV Format
The exact format for the AU Payment Times Reports Register export has not been finalized:
- What is the delimiter (comma, tab, pipe)?
- What quoting/escaping rules apply?
- What encoding (UTF-8 with or without BOM)?
- What is the exact column order and column header names?
- Is the format a flat columnar CSV (like GB) or structured differently?
- Where is the authoritative schema? (Payment Times Reporting portal / published spreadsheet template)

### ⚠️ AU Declaration Document
- What statutory text must appear in the declaration?
- What is the required format for the officer's name, signature block, and ABN?
- Does the declaration need to reference specific sections of the Payment Times Reporting Act 2020?
- Is this a PDF-style document or a fillable form?

### Period Buckets: 5 Buckets vs 3 Buckets
The Payment Period table currently seeds 5 buckets for AU/NZ (0-21, 22-30, 31-60, 61-120, 121+). The 2024 legislation seems to require 3 buckets (0-30, 31-60, 61+). Confirm the correct bucket definitions and update `InsertDefaultPeriods_AUNZ()` in T685 if needed.

---

## 16. File Inventory

### New files to create (5)

| File | Object |
|---|---|
| `App/src/Core/Implementations/PaymPracSmallBusHandler.Codeunit.al` | C682 — AU handler |
| `App/src/Core/PaymPracAUCSVExport.Codeunit.al` | C694 — AU CSV export |
| `App/src/Reports/PaymPracAUDeclaration.Report.al` | R680 — AU declaration |
| `App/src/Tables/PaymPracVendor.TableExt.al` | TE680 — Vendor extension |
| `App/src/Pages/PaymPracVendorCard.PageExt.al` | PE680 — Vendor Card extension |

### Existing files to modify (2)

| File | What to add |
|---|---|
| `App/src/Core/Enums/PaymPracReportingScheme.Enum.al` | `value(2; "Small Business")` with `PaymentPracticeSchemeHandler` mapping |
| `App/src/Tables/PaymentPracticeLine.Table.al` | Fields 15 (Invoice Count) and 16 (Invoice Value) |

### Test files to modify (2)

| File | What to add |
|---|---|
| `Test/src/PaymentPracticesUT.Codeunit.al` | All AU test procedures |
| `Test Library/src/PaymentPracticesLibrary.Codeunit.al` | AU test helpers |

### Files that already have AU support (no changes needed)

| File | Why no change needed |
|---|---|
| `App/src/Core/PaymentPeriodMgt.Codeunit.al` | Already has AU/NZ case in `DetectReportingScheme()` + integration event |
| `App/src/Core/InstallPaymentPractices.Codeunit.al` | Calls `PaymentPeriod.SetupDefaults()` which already branches for AU/NZ |
| `App/src/Core/UpgradePaymentPractices.Codeunit.al` | Backfills Reporting Scheme via `DetectReportingScheme()` — already handles AU/NZ |
| `App/src/Core/PaymentPracticeBuilders.Codeunit.al` | Already calls `SchemeHandler.UpdatePaymentPracData()` before Insert |
| `App/src/Core/PaymentPractices.Codeunit.al` | Already calls `SchemeHandler.ValidateHeader()` and `CalculateHeaderTotals()` |
| `App/src/Tables/PaymentPracticeHeader.Table.al` | OnInsert already calls `DetectReportingScheme()` from PaymentPeriodMgt |
| `App/src/Tables/PaymentPeriod.Table.al` | Already has `InsertDefaultPeriods_AUNZ()` and AU/NZ case in `SetupDefaults()` |
| `App/src/Core/Implementations/PaymPracPeriodAggregator.Codeunit.al` | Already has CalculateLineTotals + Invoice Count/Value Modify |
| `App/src/Core/Implementations/PaymPracSizeAggregator.Codeunit.al` | Already has CalculateLineTotals + Invoice Count/Value Modify |
| `App/src/Pages/PaymentPracticeCard.Page.al` | Already has ExportAUCSV action + IsSmallBusiness visibility |
| `App/src/Pages/PaymentPracticeLines.Page.al` | Already has Invoice Count/Value columns + IsSmallBusiness visibility |

---

## Implementation Order

Recommended sequence:

1. **Enum value** (section 3) — everything else depends on this
2. **Handler codeunit** (section 4) — core AU logic
3. **Vendor extension** (section 5) — handler depends on this field
4. **Payment Practice Line fields** (section 6) — handler populates these
5. **CSV Export** (section 9) — requires format design first
6. **Declaration Report** (section 10) — requires layout design first
7. **Tests** (section 14) — can start after step 4, CSV/Declaration tests after steps 5-6

Note: Most shared infrastructure (DetectReportingScheme, aggregators, page visibility, install, upgrade, period defaults) is already in place. The colleague only needs to create the new objects and modify the enum + line table.
