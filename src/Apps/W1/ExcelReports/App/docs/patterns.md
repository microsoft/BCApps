# Patterns

The Excel Reports app uses several architectural patterns to optimize performance and maintainability:

## Temporary Buffer Tables

All four data tables are `TableType=Temporary` with `ReplicateData=false`:
- `ExcelReportsAgedAccRec` (table 4401)
- `ExcelReportsAgedAccPay` (table 4402)
- `ExcelReportsTopCustomer` (table 4403)
- `ExcelReportsTopVendor` (table 4404)

No persistent storage is used. Each report run creates a fresh buffer, loaded from queries or loops, then cleared when the report completes.

## Query-Based Aggregation

Seven queries offload `GROUP BY` and `SUM` operations to SQL:
- `ExcelReportsAgedAccRecQry` (query 4401)
- `ExcelReportsAgedAccPayQry` (query 4402)
- `ExcelReportsTopCustQry` (query 4403)
- `ExcelReportsTopVendorQry` (query 4404)
- `ExcelReportsTopCustSalesQry` (query 4405)
- `ExcelReportsTopVendorPurchQry` (query 4406)
- `ExcelReportsTrialBalanceQry` (query 4407)

Queries use `TopNumberOfRows` to limit result sets at the database level. Top Customer and Top Vendor reports implement a two-pass pattern: first query ranks by one metric, second query retrieves additional metrics for the ranked set.

## Feature Flag Gating

`#if not CLEAN27` pragmas control code paths for the legacy vs query-based trial balance implementation. Feature management allows runtime toggle between implementations without redeployment. The legacy looping code will be removed in release 27.

## Debit/Credit Auto-Split

`ExcelReportsTrialBalance` (table 4400) uses validation triggers to automatically split amounts:
- Positive amounts go to the `"Debit Amount"` field
- Negative amounts go to the `"Credit Amount"` field

This prevents manual splitting logic scattered across codeunits. The validation trigger enforces the convention in one location.

## Manual Event Subscription

Caption handler codeunits use `EventSubscriberInstance=Manual`:
- `ExcelReportsTopCustCaption` (codeunit 4403)
- `ExcelReportsTopVendorCaption` (codeunit 4404)

Reports call `BindSubscription()` in `OnPreReport` and pass state via `SetRankingBasedOn()`. This implements a closure-like pattern using a static variable to communicate context to the event subscriber.

## CaptionClass for Dynamic Dimensions

Trial Balance Buffer fields use `CaptionClass='1,2,1'` and `CaptionClass='1,2,2'` to resolve dimension names at runtime from `GLSetup."Global Dimension 1 Code"` and `GLSetup."Global Dimension 2 Code"`.

## Multi-Currency Parallel Tracking

`ExcelReportsTrialBalance` (table 4400) maintains parallel LCY and ACY fields for every amount:
- `"Net Change"` / `"Net Change (ACY)"`
- `"Balance at Date"` / `"Balance at Date (ACY)"`
- `"Starting Balance"` / `"Starting Balance (ACY)"`
- `"Budgeted Amount"` / `"Budgeted Amount (ACY)"`

ACY fields use `AutoFormatType=1` and `AutoFormatExpr=GetAdditionalReportingCurrencyCode()` to format amounts in the additional reporting currency when configured.

## Legacy Patterns

The following patterns exist in legacy code paths (CLEAN27) and will be removed:

### Triple-Nested Looping

The legacy trial balance implementation in `ExcelReportsTrialBalProc` (codeunit 4400) uses three nested loops:
- Outer loop: Dimension 1 values
- Middle loop: Dimension 2 values
- Inner loop: Business Units

This creates O(n^3) complexity. The query-based implementation (query 4407) eliminates this by offloading aggregation to SQL.

### Unbounded Temporary Table Memory

Large general ledgers with many dimension combinations can exhaust session memory because all rows are loaded into a temporary table with no paging. The query-based approach limits this by using `TopNumberOfRows` and filtering at the database level, but the fundamental architecture still loads all result rows into memory.
