## 1. Core Infrastructure — Enum & Interfaces

- [x] 1.1 Create enum `Paym. Prac. Reporting Scheme` (ID 680) in `App/src/Core/Enums/PaymPracReportingScheme.Enum.al` with values Standard (0), Dispute & Retention (1), Small Business (2), implementing `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler` interfaces
- [x] 1.2 Create interface `PaymentPracticeDefaultPeriods` in `App/src/Core/Interfaces/PaymPracDefaultPeriods.Interface.al` with method `GetDefaultPaymentPeriods(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)`
- [x] 1.3 Create interface `PaymentPracticeSchemeHandler` in `App/src/Core/Interfaces/PaymPracSchemeHandler.Interface.al` with methods `ValidateHeader`, `UpdatePaymentPracData` (returns Boolean), `CalculateHeaderTotals`, `CalculateLineTotals`

## 2. Handler Implementations

- [x] 2.1 Create Standard handler codeunit (C680) in `App/src/Core/Implementations/PaymPracStandardHandler.Codeunit.al` — implements both interfaces; `GetDefaultPaymentPeriods` checks `GetApplicationFamily()` for FR vs W1 defaults; all `SchemeHandler` methods are pass-throughs
- [x] 2.2 Create Dispute & Retention handler codeunit (C681) in `App/src/Core/Implementations/PaymPracDisputeRetHandler.Codeunit.al` — implements both interfaces; GB period defaults; `UpdatePaymentPracData` copies dispute status and SCF payment date from VLE, recalculates Actual Payment Days when SCF date is populated; `CalculateHeaderTotals` populates payment statistics and dispute percentage
- [x] 2.3 Create Small Business handler codeunit (C682) in `App/src/Core/Implementations/PaymPracSmallBusHandler.Codeunit.al` — implements both interfaces; AU period defaults; `ValidateHeader` rejects Customer/Vendor+Customer; `UpdatePaymentPracData` returns false for non-small-business vendors; `CalculateHeaderTotals` populates total invoice count/value; `CalculateLineTotals` populates per-bucket invoice count/value

## 3. Payment Period Template Tables

- [x] 3.1 Create `Payment Period Header` table (T680) in `App/src/Tables/PaymentPeriodHeader.Table.al` — fields: Code (PK), Description, Reporting Scheme (non-editable after insert), Default (optional — scheme may have zero or one default; setting true silently clears other defaults for same scheme; setting false always allowed); OnDelete cascades lines and blocks if referenced
- [x] 3.2 Create `Payment Period Line` table (T681) in `App/src/Tables/PaymentPeriodLine.Table.al` — fields: Period Header Code (PK1), Line No. (PK2), Days From, Days To, Description (auto-generated)
- [x] 3.3 Create `Payment Period Card` page (P690) in `App/src/Pages/PaymentPeriodCard.Page.al` — ListPlus page with header fields + lines subpage; Reporting Scheme field editable only during insert (Editable = IsNewRecord), read-only after first save
- [x] 3.4 Create `Payment Period List` page (P691) in `App/src/Pages/PaymentPeriodList.Page.al` — browse/select period templates
- [x] 3.5 Create `Payment Period Subpage` page (P692) in `App/src/Pages/PaymentPeriodSubpage.Page.al` — ListPart for editing period lines

## 4. Data Model Extensions — Payment Practice Header

- [x] 4.1 Add `Reporting Scheme` (field 15) and `Payment Period Code` (field 16) to `Payment Practice Header` table (T687) with OnInsert auto-detection from GetApplicationFamily(); Payment Period Code auto-fill uses cascading logic: (1) default template for scheme, (2) sole template for scheme, (3) blank; TableRelation filtered by Reporting Scheme; OnValidate for Reporting Scheme applies same cascading logic, prompts to create default template if no templates exist for scheme
- [x] 4.2 Add GB payment statistics fields (20-23): Total Number of Payments, Total Amount of Payments, Total Amt. of Overdue Payments, Pct Overdue Due to Dispute (Editable = false)
- [x] 4.3 Add GB payment policy tick-box fields (30-35): Offers E-Invoicing, Offers Supply Chain Finance, Policy Covers Deduction Charges, Has Deducted Charges in Period, Is Payment Code Member, Payment Code Name
- [x] 4.4 Add construction contract retention fields (40-58): gate field, clause usage, contract sum threshold, standard retention pct, terms fairness, release mechanism, retention statistics amounts and auto-calculated percentages

## 5. Data Model Extensions — Payment Practice Data & Line

- [x] 5.1 Add GB fields to `Payment Practice Data` table (T686): Dispute Status (20, Boolean), Overdue Due to Dispute (21, Boolean, Editable=false), SCF Payment Date (22, Date, Editable=true)
- [x] 5.2 Add AU fields to `Payment Practice Line` table (T688): Invoice Count (14, Integer), Invoice Value (15, Decimal)

## 6. BaseApp Extensions

- [x] 6.1 Add `Small Business Supplier` field (136, Boolean) to Vendor table (T23) in BaseApp
- [x] 6.2 Add `Small Business Supplier` field to Vendor Card page in Payments group (same pattern as Exclude from Pmt. Practices)
- [x] 6.3 Add `SCF Payment Date` field (Date) to Vendor Ledger Entry table (T25) in BaseApp
- [x] 6.4 Add `SCF Payment Date` field to Vendor Ledger Entries page (P29) with Visible = false

## 7. Core Logic Integration

- [x] 7.1 Update `PaymentPractices.Codeunit.al` (C689): call `SchemeHandler.ValidateHeader()` before data generation; add generation guard for blank Payment Period Code; call `SchemeHandler.CalculateHeaderTotals()` after existing GenerateTotals(); call `SchemeHandler.CalculateLineTotals()` per generated line
- [x] 7.2 Update `PaymentPracticeBuilders.Codeunit.al` (C688): obtain scheme handler from header; in BuildPaymentPracticeDataForVendor, call `SchemeHandler.UpdatePaymentPracData()` before Insert, skip if returns false; extend CopyFromInvoiceVendLedgEntry to copy SCF Payment Date; same pattern for BuildPaymentPracticeDataForCustomer
- [x] 7.3 Update `PaymPracPeriodAggregator.Codeunit.al` (C685): read period buckets from `Payment Period Line` filtered by header's Payment Period Code instead of old global Payment Period table

## 8. Deprecation & Migration

- [x] 8.1 Mark old `Payment Period` table (T685) with ObsoleteState = Pending and ObsoleteReason
- [x] 8.2 Update `Payment Periods` page (P685) with obsolete warning or redirect to new Payment Period List
- [x] 8.3 Create upgrade codeunit (C683) in `App/src/Core/UpgradePaymentPractices.Codeunit.al`: compare old periods to defaults, create templates (default + MIGRATED if needed), backfill existing headers with Reporting Scheme and Payment Period Code
- [x] 8.4 Update `InstallPaymentPractices.Codeunit.al` (C687): on fresh install, seed one default Payment Period Header + Lines via GetDefaultPaymentPeriods() for detected scheme; register new tables for privacy classification

## 9. Page Updates

- [x] 9.1 Update `PaymentPracticeCard.Page.al` (P687): add Reporting Scheme and Payment Period Code (ShowMandatory = true) fields to General group; add Payment Policies group (visible for Dispute & Retention); add Payment Statistics group (visible for Dispute & Retention); add Construction Contract Retention group (visible for Dispute & Retention, sub-fields gated by Has Constr. Contract Retention)
- [x] 9.2 Update `PaymentPracticeLines.Page.al` (P688): add Invoice Count and Invoice Value columns with visibility for Small Business scheme
- [x] 9.3 Update `PaymentPracticeDataList.Page.al` (P686): add Dispute Status, Overdue Due to Dispute, SCF Payment Date columns with visibility for Dispute & Retention scheme

## 10. Export Codeunits

- [x] 10.1 Create GB CSV export codeunit (C684) in `App/src/Core/PaymPracGBCSVExport.Codeunit.al`: CSV generation for Dispute & Retention scheme with payment stats, policy tick-boxes, period data, and conditional retention section; action on Payment Practice Card gated by scheme
- [x] 10.2 Create AU CSV export codeunit (C694) in `App/src/Core/PaymPracAUCSVExport.Codeunit.al`: delimited text file generation for Small Business scheme with header totals and period-aggregated invoice data; action on Payment Practice Card gated by scheme
- [x] 10.3 Create AU declaration document (Report 680 or Word layout) with officer name, signature block, ABN fields

## 11. Tests

- [x] 11.1 Add test helpers to `PaymentPracticesLibrary.Codeunit.al`: helper functions for creating Payment Period templates, setting up GB/AU vendor data, creating headers with specific schemes
- [x] 11.2 Add Standard regression tests to `PaymentPracticesUT.Codeunit.al`: verify existing tests pass unchanged with Reporting Scheme = Standard; verify Generate produces same results as before
- [x] 11.3 Add Reporting Scheme switching tests: create header with each scheme, verify auto-detection; switch scheme, verify confirm dialog and lines cleared
- [x] 11.4 Add Dispute & Retention tests: dispute status flow from VLE, SCF Payment Date copy and override, SCF recalculates Actual Payment Days, payment statistics and dispute percentage, construction retention auto-calculated percentages
- [x] 11.5 Add Small Business tests: small business vendor filtering (non-small vendors produce zero rows), invoice count/value per period bucket, ValidateHeader rejects Customer/Vendor+Customer
- [x] 11.6 Add Payment Period template tests: create/edit templates, Default optional (uncheck allowed, silent mutual exclusion on set), cascading auto-fill (default → sole template → blank), scheme-filtered lookup on Payment Period Code, Reporting Scheme non-editable after insert, upgrade migration (default match + custom periods), generation guard on blank period code
- [x] 11.7 Add export tests: GB CSV includes correct fields and retention section when applicable; AU export includes invoice count/value per period

## 12. App Configuration

- [x] 12.1 Verify `app.json` idRanges cover 680–698 for all new object IDs

## 13. Improved Generation Guard Errors

- [x] 13.1 Update `PaymentPractices.Codeunit.al` (C689): replace single blank-period-code error with two context-dependent errors — if templates exist for the scheme, show 'You must select a Payment Period Code before generating.'; if no templates exist for the scheme, show actionable ErrorInfo with message 'No payment period templates exist for the selected reporting scheme. Create a template first.' and AddNavigationAction opening Payment Period List page (P691)
- [x] 13.2 Update generation guard tests in `PaymentPracticesUT.Codeunit.al`: split existing `GenerationGuard_BlankPeriodCode` into two tests — one with templates present (expects simple error), one with no templates (expects actionable error with navigation action text)
- [x] 13.3 Update XLIFF translations for new error label

## 14. Generate Default Template Action

- [x] 14.1 Add `Generate Default Template` action to `Payment Period List` page (P691): auto-detect reporting scheme from `GetApplicationFamily()`, call `PaymentPracticeDefaultPeriods.GetDefaultPaymentPeriods()` to get code/description/lines, `Error()` if template with that code already exists, otherwise insert header (Default=true) + lines, `CurrPage.Update(false)`
- [x] 14.2 Add test for Generate Default Template action: verify template created on empty table, verify Error when template already exists
