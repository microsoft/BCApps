# Dynamics BC Excel Reports

Provides Excel-based financial and analytics reports for Business Central -- trial
balance, aged receivables/payables, fixed asset analysis, and customer/vendor ranking.
All reports use Excel layouts with multiple data sheets for rich formatting and pivot
table support.

## Quick reference

| Object type | Count | Purpose |
|-------------|-------|---------|
| Reports | 12 | Excel report definitions with request pages |
| Queries | 7 | SQL aggregation for GL entries, customer/vendor ledger |
| Codeunits | 5 | Trial Balance engine, caption handlers, telemetry |
| Tables | 4 | Temporary buffers (Trial Balance, Aging, Top Customer/Vendor) |
| Page extensions | 37 | Add report actions to role centers and list pages |
| Permissions | 6 | Permission set extensions for D365 roles |

ID range: 4400-4445
Dependencies: None
Target: Cloud
Platform: 29.0.0.0

## How it works

### Report execution model

All reports use `ExcelLayoutMultipleDataSheets=true` and generate temporary buffer
tables during `OnPreReport`. The Excel layouts read from these buffers, which are
discarded after rendering. No persistent storage -- reports are fully stateless.

Excel layout files live in `ReportLayouts/Excel/` and define formatting, pivot tables,
and formulas. The AL code only populates raw data tables.

### Trial Balance engine (codeunit 4410)

The most complex component. Supports two execution paths:

1. **Query-based (modern, v28+)**: Uses `EXR Trial Balance` query and related budget/BU
   queries for efficient SQL aggregation. Fast, performant, preferred path.
2. **Looping-based (legacy, #if not CLEAN27)**: Iterates over GL entries in AL. Used
   when performant feature flag is off. Slower but backward compatible.

Multi-currency: Tracks both LCY (local currency) and ACY (Additional Reporting Currency)
amounts in parallel. Budget support optional via `IncludeBudgetData` parameter.

Five trial balance report variants:
- Standard Trial Balance (4401)
- Trial Balance Budget (4402) -- includes budget vs actual
- Trial Balance by Period (4403) -- monthly columns
- Trial Balance Previous Year (4404) -- current year vs prior year
- Consolidated Trial Balance (4405) -- breakdown by business unit

### Aging reports (4406, 4407)

Aged Accounts Receivable and Aged Accounts Payable use query-based aggregation to
group customer/vendor ledger entries into aging buckets (0-30, 31-60, 61-90, 90+ days).

Supports three "Aged By" date bases:
- Due Date (default)
- Posting Date
- Document Date

User selects via option field on request page. Caption handlers dynamically update
column headings based on selection.

### Top Customer/Vendor lists (4410, 4415)

Two-pass query pattern:
1. First pass: Get top N entities by primary metric (e.g., top 10 by sales)
2. Second pass: Fill alternate metric (e.g., balance for those same 10 customers)

Uses temporary buffer tables (`EXR Top Customer Report Buffer`, `EXR Top Vendor Report
Buffer`) to hold combined results.

### Fixed Asset reports (4408, 4409, 4411)

Three reports:
- Fixed Asset Analysis (4408) -- depreciation book analysis
- Fixed Asset Details (4409) -- detailed asset listing
- Fixed Asset Projected (4411) -- projected depreciation

All query-based, no looping. Use standard FA ledger entry aggregation.

### Caption handlers

Three caption handler codeunits (4430, 4431, 4432) use manual event subscription
(`EventSubscriberInstance=Manual`) to dynamically set report column captions based on
request page options. Reports call `BindSubscription` in `OnPreReport` to activate
handlers for that run only.

### Page extensions and role center integration

37 page extensions add "Excel Reports" actions to role centers (17 extensions) and
entity list pages (20 extensions). Actions launch reports with context filters
pre-applied (e.g., customer list passes customer filter to Top Customer report).

Role centers touched: Accountant, Accounting Manager, Accounts Payable Coordinator,
Accounts Receivable Administrator, Bookkeeper, CEO, Finance, Business Manager, Order
Processor, Purchasing Agent/Manager, Sales Manager/Marketing/Relationship Manager,
Small Business Owner.

## Structure

```
src/
  Customer/              Top customer ranking report and queries
  Financials/            Trial balance, aging, fixed asset reports
    PageExtensions/      Extensions to GL-related list pages
  Vendor/                Top vendor ranking report and queries
  RoleCenters/           Extensions to 17 role center pages
  permissions/           6 permission set extensions
  ExcelReportsTelemetry.Codeunit.al  Telemetry logging

ReportLayouts/
  Excel/                 Excel layout files (.xlsx)
```

## Documentation

No dedicated external docs. Context-sensitive help URL: https://go.microsoft.com/fwlink/?linkid=2204541

Internal telemetry uses `Session.LogMessage` with category "Excel Reports" to track
report start/end for trial balance data collection.

## Things to know

- **All data tables are temporary** (TableType=Temporary) -- reports populate these
  buffers on every run. No schema upgrades needed for data changes.
- **Query-based vs looping**: In v28+ (`CLEAN27` defined), only the query path compiles.
  Pre-v28, a feature flag (`EXRPerformantTrialBalance`) switched between paths. The
  looping code (`#if not CLEAN27`) is still in source but no longer compiles.
- **Manual event subscription**: Caption handlers require explicit `BindSubscription` in
  OnPreReport. They do not auto-subscribe globally.
- **Multi-currency throughout**: Trial Balance tracks LCY and ACY in parallel. Other
  reports may use single currency or user-selected currency via request page.
- **Date filters matter**: All reports require date filters on request page. Trial
  Balance uses "Date Filter" on GL Account. Aging uses period end date. Top Customer/
  Vendor use date range filters.
- **No dependencies**: This app stands alone. It does not extend or depend on other
  BCApps extensions.
- **Excel layout changes**: Modifying report data structure requires updating both AL
  buffer table definitions and Excel layout files. Layouts are versioned with reports.
- **Permission model**: Objects permission set (4400) defines RIMD rights. Five D365
  role extensions (BASIC ISV, BUS FULL ACCESS, BUS PREMIUM, FULL ACCESS, READ) extend
  standard permission sets to include Excel Reports objects.
