# Business logic

This document describes the core business logic for the Excel Reports app, covering the major report engines and their execution patterns.

## Trial balance (most complex)

The Trial Balance engine (codeunit 4410, 20+ procedures) is the most sophisticated component in this app. It supports two distinct execution paths:

### Modern path (query-based, v28+)

This is the only path in v28+ where `CLEAN27` is defined. In pre-v28 builds, this path was active when the `EXRPerformantTrialBalance` feature flag was enabled. It uses SQL queries for efficient aggregation.

**Key procedure:** `InsertTrialBalanceReportDataFromQueries()`

**Execution flow:**

```
┌─────────────────────────────────────────────────────────────┐
│ InsertTrialBalanceReportDataFromQueries                     │
│ - Extract date range from GL Account filter                 │
│ - Determine if Business Unit breakdown is needed            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─ YES (BU breakdown) ──> InsertTrialBalanceFromBUQuery
                  │                          (uses EXR Trial Balance BU query)
                  │
                  └─ NO (standard) ──────> InsertTrialBalanceFromQuery
                                           (uses EXR Trial Balance query)
                  │
                  │ Both query paths follow same two-pass pattern:
                  │
                  ▼
        ┌─────────────────────────┐
        │ First pass:             │
        │ Query GL entries        │
        │ with filter: ..EndDate  │
        │                         │
        │ -> Insert records with: │
        │   Balance = Amount      │
        │   Net Change = Amount   │
        └────────┬────────────────┘
                 │
                 ▼
        ┌─────────────────────────┐
        │ Second pass:            │
        │ Query GL entries        │
        │ with filter:            │
        │   ..(StartDate-1)       │
        │                         │
        │ -> Modify records:      │
        │   Starting Balance =    │
        │     Amount from query   │
        │   Net Change =          │
        │     Balance -           │
        │     Starting Balance    │
        └────────┬────────────────┘
                 │
                 ▼
        ┌─────────────────────────┐
        │ Budget overlay          │
        │ (if IncludeBudget)      │
        │                         │
        │ InsertBudgetDataFrom    │
        │ Query():                │
        │ - Read budget entries   │
        │   for date range        │
        │ - Attach to matching    │
        │   GL accounts           │
        └────────┬────────────────┘
                 │
                 ▼
        ┌─────────────────────────┐
        │ Total accounts          │
        │ aggregation             │
        │                         │
        │ InsertTotalAccountsFrom │
        │ Buffer():               │
        │ - Filter buffer by      │
        │   GL Account Totaling   │
        │ - Group by Dim1, Dim2,  │
        │   Business Unit         │
        │ - CalcSums() for all    │
        │   amount fields         │
        │ - Insert aggregated     │
        │   records               │
        └─────────────────────────┘
```

**Result:** Net Change = Balance at EndDate - Balance at (StartDate-1)

**Budget handling:** `InsertBudgetDataFromQuery()` runs in a separate pass after main data collection. It reads budget entries and updates existing buffer records with budget amounts. Budget comparisons are calculated via `CalculateBudgetComparisons()`.

**Total accounts aggregation:** `InsertTotalAccountsFromBuffer()` handles End-Total and Total type GL accounts. Queries only return Posting accounts, so totals must be computed in memory by filtering the buffer on the Totaling range and summing child account amounts grouped by dimension combinations.

### Legacy path (looping-based, #if not CLEAN27)

This path exists in the source only for pre-v28 builds (`#if not CLEAN27`). It runs when the feature flag is disabled. It uses triple-nested loops:

```
For each GL Account
  For each Dimension 1 value
    For each Dimension 2 value
      For each Business Unit (if BreakdownByBU)
        - Apply filters to GL Account
        - CalcFields (Net Change, Balance at Date, etc.)
        - Insert buffer record if not all zero
```

**Complexity:** O(Accounts × Dim1 × Dim2 × BU), potentially hundreds of thousands of iterations for large datasets.

**Gated by:** Feature flag `EXRPerformantTrialBalance` (checked via `IsPerformantTrialBalanceFeatureActive()`).

**Removal:** `CLEAN27` is defined from v28+; this code no longer compiles in current builds and will be physically deleted in a future cleanup pass.

### Configuration

`ConfigureTrialBalance(BreakdownByBU, IncludeBudget)` sets execution mode:
- `BreakdownByBU` -- use Business Unit query vs standard query
- `IncludeBudget` -- run budget overlay pass after main data collection

### All Zero suppression

`CheckAllZero()` marks records where all amount fields are zero. These records are skipped during insertion to reduce dataset size and improve Excel rendering performance.

## Aging reports (AR/AP)

Aged Accounts Receivable (4402) and Aged Accounts Payable (4403) use a similar aging bucket calculation pattern.

### Initialization: `InitReport()`

Creates period boundary lists from user-specified `DateFormula` (e.g., "-1M" for one month intervals):

```
EndingDate = user-specified aged-as-of date
WorkingEndDate = EndingDate
WorkingStartDate = CalcDate(PeriodLength, WorkingEndDate)

Repeat PeriodCount times:
  - Add (WorkingStartDate, WorkingEndDate) to lists
  - Shift both dates backward by PeriodLength

Result: Lists of period start/end dates for buckets
```

Example with EndingDate = 2024-12-31, PeriodLength = "-1M", PeriodCount = 5:
- Bucket 1: 2024-12-01 to 2024-12-31
- Bucket 2: 2024-11-01 to 2024-11-30
- Bucket 3: 2024-10-01 to 2024-10-31
- Bucket 4: 2024-09-01 to 2024-09-30
- Bucket 5: 2024-08-01 to 2024-08-31

### Per-entity aging calculation

For each customer/vendor:
1. Load all open ledger entries (Remaining Amt LCY <> 0) posted up to EndingDate
2. Set "Aged By" date (due date, posting date, or document date -- user choice)
3. Call `SetPeriodStartAndEndDate(PeriodStarts, PeriodEnds)` to map entry to correct bucket
4. Calculate Reporting Date month/quarter/year for Excel pivot table grouping
5. Insert buffer record with amounts and dimension codes

### Aged By override integration event

`OnOverrideAgedBy` is an integration event that allows subscribers to change the aging method dynamically. Called in `GetReportingDateCaption()` when determining which date field to use for aging calculations. Subscribers can replace the standard "Due Date", "Posting Date", or "Document Date" logic with custom rules (e.g., "earliest of due date or document date").

### Reporting date fields

The buffer table includes four reporting date fields:
- `Reporting Date` -- the base date for aging (after override logic)
- `Reporting Date Month` -- month number for pivot grouping
- `Reporting Date Quarter` -- quarter number for pivot grouping
- `Reporting Date Year` -- year for pivot grouping

Excel layouts use these fields to create month/quarter/year slicers without Excel formulas.

## Top customer/vendor ranking

Customer Top List (4409) and Vendor Top List (4415) use a two-pass query pattern to retrieve multiple metrics for the same set of entities.

### Two-pass execution

**Pass 1:** Run primary query with `TopNumberOfRows` limit
- For "Sales (LCY)" mode: Run `TopCustomerSales` query aggregating sales ledger entries
- For "Balance (LCY)" mode: Run `TopCustomerBalance` query aggregating customer ledger balances

Result: Top N entity IDs and Amount 1 (primary metric)

**Pass 2:** Run alternate query on filtered entity set
- For "Sales (LCY)" mode: Run `TopCustomerBalance` query with Customer No. filter from Pass 1
- For "Balance (LCY)" mode: Run `TopCustomerSales` query with Customer No. filter from Pass 1

Result: Amount 2 (alternate metric) for the same N entities

**Customer names:** Looked up separately from Customer table in Pass 2 loop.

### Why two passes?

SQL query objects do not support multiple aggregations with different filters in a single pass. The first query must return the entity IDs, then the second query can filter on those IDs to compute the alternate metric. This pattern avoids loading all entities into memory and filtering in AL.

## Report rendering

All reports follow a common rendering pattern:

### OnPreReport trigger

```
1. Log telemetry (Session.LogMessage with category "Excel Reports")
2. BindSubscription(captionHandler) -- activate dynamic caption logic
3. Build dataset -- populate temporary buffer tables
4. Excel layout renders from buffer
```

### Report properties

All reports share these settings:
- `DataAccessIntent=ReadOnly` -- query optimization hint (run against read-only replica)
- `MaximumDatasetSize=1000000` -- fail if dataset exceeds 1M rows (prevents runaway reports)
- `ExcelLayoutMultipleDataSheets=true` -- Excel file contains multiple worksheets
- `DefaultRenderingLayout` -- points to Excel file in `ReportLayouts/Excel/` subdirectory

### Layout structure

Excel layouts typically contain:
- Print sheet -- formatted for PDF printing with company header
- Analysis sheet (LCY) -- raw data with pivot tables for local currency
- Analysis sheet (ACY/FCY) -- raw data with pivot tables for additional/foreign currency
- About the Report sheet -- metadata (environment, company, user, run date, documentation link)

Reports use Excel's Query Connections feature to bind dataset tables to Excel tables, enabling rich formatting and pivot table support without AL code changes.
