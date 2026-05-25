# New Test Scenarios for Payment Practices (OpenSpec)

Tests for new functionality introduced by OpenSpec specs. Excludes AU/Small Business and pre-existing legacy behavior.

## T689 — Dispute & Retention Detail Table

### 1. RetentionPctAutoCalculation
- **Spec**: `dispute-retention-detail-table` — `CalculateRetentionPercentages()` triggered by OnValidate
- **Scenario**: Validate retention value fields, verify auto-calculated percentages
- **Steps**:
  1. Create Payment Practice Header with D&R scheme
  2. Get T689 record, set `Gross Payments Constr. Contr.` = 200000, `Retent. Withheld from Suppls.` = 10000, `Retention Withheld by Clients` = 8000
  3. Validate each field (to trigger OnValidate)
- **Verify**: `Pct Retent. vs Gross Payments` = 10000/200000*100 = 5, `Pct Retention vs Client Ret.` = 10000/8000*100 = 125

### 2. ChildToggleClearing_HasConstrContractRetention
- **Spec**: `dispute-retention-detail-table` — "confirmation dialog when toggling gate false to clear retention detail fields (41-58)"
- **Scenario**: Toggle `Has Constr. Contract Retention` from true to false, sub-fields are cleared after confirmation
- **Steps**:
  1. Create Payment Practice Header with D&R scheme
  2. Get T689 record, populate retention sub-fields (Ret. Clause Used in Contracts, Std Retention Pct, Retention in Std Pmt. Terms, etc.)
  3. Set `Has Constr. Contract Retention` := false (with ConfirmHandler_Yes)
- **Verify**: All retention sub-fields (fields 41-58) are cleared/reset to default
- **Handler**: `ConfirmHandler_Yes`

### 3. CopyFromPrevious_NoPreviousHeader
- **Spec**: `dispute-retention-detail-table` — `CopyFromPrevious()` procedure
- **Scenario**: CopyFromPrevious when no previous header exists (first-ever report)
- **Steps**:
  1. Clean up all Payment Practice Headers
  2. Create single Payment Practice Header with D&R scheme
  3. Get T689 record, call `CopyFromPrevious()`
- **Verify**: No error occurs; T689 fields remain at defaults (empty/false/0)

## GB CSV Export — `gb-gov-csv-format` spec

### 4. GBCSVExport_OverduePctFormula
- **Spec**: `gb-gov-csv-format` — "Overdue percentage: 100 − Pct Paid on Time"
- **Scenario**: Verify the overdue percentage column in CSV equals 100 minus Pct Paid On Time
- **Steps**:
  1. Create fully populated GB header with `Pct Paid on Time` = 11
  2. Export GB CSV, parse data row
- **Verify**: Column 21 (`% Invoices not paid within agreed terms`) = 89 (i.e. 100 − 11)

### 5. GBCSVExport_EmptyReport
- **Spec**: `gb-gov-csv-format` — all columns defined; should produce valid CSV even without generated lines
- **Scenario**: Export CSV before calling Generate (no lines, no data)
- **Steps**:
  1. Create Payment Practice Header with D&R scheme (do NOT generate)
  2. Export GB CSV
- **Verify**: CSV has valid header row (52 columns); data row exists with zero/blank values; no runtime error

## Dispute & Retention Handler — `dispute-retention-handler` spec

### 6. DisputeRetentionLink_NotVisibleForStandardScheme
- **Spec**: `dispute-retention-handler` — "visible only when Scheme = Dispute & Retention"
- **Scenario**: D&R link is NOT visible on Payment Practice Card for Standard scheme
- **Steps**:
  1. Create Payment Practice Header with Standard scheme
  2. Open Payment Practice Card
- **Verify**: `DisputeRetentionLink.Visible()` = false
- **Note**: The positive case (visible for D&R) is already tested in `GBCSVExport_CardDisputeRetentionLinkVisible`

## Reporting Scheme — `reporting-scheme` spec

### 7. ReportingScheme_AutoDetectionOnInsert
- **Spec**: `reporting-scheme` — "T687 Field 15: auto-detection on insert (GB→D&R, AU/NZ→Small Business, others→Standard)"
- **Scenario**: Inserting a Payment Practice Header auto-detects the correct Reporting Scheme based on country
- **Steps**:
  1. Insert a new Payment Practice Header via `Insert(true)`
  2. Read back `Reporting Scheme`
- **Verify**: Value matches expected scheme for the current environment (likely Standard for W1)
- **Note**: Full country-based testing (GB, AU) may require environment mocking. At minimum, verify the auto-detection runs without error and produces a valid scheme value.
