## 1. Remove Payment Period Template Objects

- [x] 1.1 Delete file `PaymentPeriodHeader.Table.al` (T680)
- [x] 1.2 Delete file `PaymentPeriodLine.Table.al` (T681)
- [x] 1.3 Delete file `PaymentPeriodCard.Page.al` (P690)
- [x] 1.4 Delete file `PaymentPeriodList.Page.al` (P691)
- [x] 1.5 Delete file `PaymentPeriodSubpage.Page.al` (P692)
- [x] 1.6 Delete file `PaymentPracticeDefaultPeriods.Interface.al`

## 2. Remove GB CSV Export and Manual Fields Objects

- [x] 2.1 Delete file `PaymPracGBCSVExport.Codeunit.al` (C684)
- [x] 2.2 Delete file `PaymPracDisputeRetData.Table.al` (T689)
- [x] 2.3 Delete file `PaymPracDisputeRetCard.Page.al` (P693)

## 3. Slim Down Codeunit 695 (Payment Period Mgt.)

- [x] 3.1 Remove `InsertDefaultTemplate()` overloads and `GetDefaultTemplateCode()` from C695
- [x] 3.2 Add `OnBeforeDetectReportingScheme(var ReportingScheme; var IsHandled)` integration event to `DetectReportingScheme()`
- [x] 3.3 Remove references to `Payment Period Header`, `Payment Period Line`, and `PaymentPracticeDefaultPeriods` from C695

## 4. Update Enum 680 (Reporting Scheme)

- [x] 4.1 Remove `PaymentPracticeDefaultPeriods` from the `implements` clause on enum 680
- [x] 4.2 Update each enum value's `Implementation` mapping to reference only `PaymentPracticeSchemeHandler`

## 5. Update Scheme Handler Codeunits

- [x] 5.1 Remove `implements PaymentPracticeDefaultPeriods` and `GetDefaultPaymentPeriods()` from `Paym. Prac. Standard Handler` (C680)
- [x] 5.2 Remove `implements PaymentPracticeDefaultPeriods` and `GetDefaultPaymentPeriods()` from `Paym. Prac. Dispute Ret. Hdlr` (C681); remove `InsertTempLine()` helper
- [x] 5.3 Remove `implements PaymentPracticeDefaultPeriods` and `GetDefaultPaymentPeriods()` from `Paym. Prac. Small Bus. Handler` (C682)

## 6. Update Payment Practice Header (T687)

- [x] 6.1 Remove field 16 `Payment Period Code` and its table relation
- [x] 6.2 Remove `Reporting Scheme` OnValidate trigger (confirmation dialog, ClearHeader, UpdatePaymentPeriodCodeForScheme)
- [x] 6.3 Remove `UpdatePaymentPeriodCodeForScheme()` procedure
- [x] 6.4 Remove `DisputeRetData` creation from OnInsert trigger
- [x] 6.5 Remove `DisputeRetData` deletion from DeleteLinkedRecords procedure
- [x] 6.6 Keep field 15 `Reporting Scheme` and `DetectReportingScheme()` call on insert
- [x] 6.7 Keep fields 20-23 (payment statistics) unchanged

## 7. Update Payment Practice Card (P687)

- [x] 7.1 Set `Reporting Scheme` field to `Visible = false` and `Editable = false`
- [x] 7.2 Remove `Payment Period Code` field
- [x] 7.3 Remove "Dispute & Retention" group and drilldown link
- [x] 7.4 Remove `ExportGBCSV` action and promoted reference
- [x] 7.5 Remove `IsDisputeRetention` variable and `DisputeRetentionLinkTxt` label
- [x] 7.6 Update `UpdateVisibility()` to remove `IsDisputeRetention` logic (keep `IsSmallBusiness`)

## 8. Revert Payment Period Table (T685)

- [x] 8.1 Remove `#if not CLEANSCHEMA32` wrapper
- [x] 8.2 Remove `ObsoleteState`, `ObsoleteReason`, `ObsoleteTag` attributes
- [x] 8.3 Ensure `SetupDefaults()` and all `InsertDefaultPeriods_*` methods are unchanged from HEAD

## 9. Revert Period Aggregator

- [x] 9.1 Update `Paym. Prac. Period Aggregator` to read from `Payment Period` (T685) instead of `Payment Period Line` (T681)

## 10. Update Install and Permissions

- [x] 10.1 Remove `CreateDefaultPaymentPeriodTemplate()` call from install codeunit
- [x] 10.2 Remove `#pragma warning disable/restore AL0432` around `SetupDefaults()` call
- [x] 10.3 Remove `DataClassificationMgt.SetTableFieldsToNormal` for T680, T681, T689
- [x] 10.4 Remove T680, T681, T689 from permission sets (`PaymPracEdit`, `PaymPracObjects`, `PaymPracRead`)

## 11. Update Translations

- [x] 11.1 Regenerate `Payment Practices.g.xlf` to remove labels/captions from deleted objects

## 12. Verification

- [x] 12.1 Confirm AL compilation succeeds with no errors
- [x] 12.2 Verify no remaining references to deleted objects (T680, T681, T689, P690-693, C684, PaymentPracticeDefaultPeriods)
