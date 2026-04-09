## 1. Fix Test Library — Remove Deleted Object References

- [x] 1.1 Delete `FindDefaultPaymentPeriodCode()` procedure
- [x] 1.2 Delete `InsertDisputeRetData()` local procedure
- [x] 1.3 Delete `CreatePaymentPeriodTemplate()` procedure
- [x] 1.4 Delete `DeletePaymentPeriodTemplatesForScheme()` procedure
- [x] 1.5 Delete `GBCSVExport()` procedure
- [x] 1.6 Delete `GBCSVFormatDateGov()` procedure
- [x] 1.7 Delete `GBCSVEscapeCSVField()` procedure
- [x] 1.8 Delete `CreateFullyPopulatedGBHeader()` procedure
- [x] 1.9 Delete `CreateMockPeriodLine()` procedure

## 2. Fix Test Library — Update Surviving Helpers

- [x] 2.1 Rewrite `CreateDefaultPaymentPeriodTemplates()` to use `PaymentPeriod.DeleteAll(); PaymentPeriod.SetupDefaults()`
- [x] 2.2 Rewrite `InitializePaymentPeriods()` to read from `Payment Period` (T685) instead of T680/T681
- [x] 2.3 Rewrite `InitAndGetLastPaymentPeriod()` to read from `Payment Period` (T685)
- [x] 2.4 Update `CreatePaymentPracticeHeader` (4-param overload) — remove `FindDefaultPaymentPeriodCode` and `InsertDisputeRetData` calls
- [x] 2.5 Update `CreatePaymentPracticeHeader` (6-param overload with scheme) — remove `FindDefaultPaymentPeriodCode` and `InsertDisputeRetData` calls
- [x] 2.6 Update `CreatePaymentPracticeHeaderWithScheme()` — remove `FindDefaultPaymentPeriodCode` and `InsertDisputeRetData` calls
- [x] 2.7 Update `CleanupPaymentPracticeHeaders()` — remove `DisputeRetData.DeleteAll()` line
- [x] 2.8 Remove `using` statements for deleted objects (T680, T681, T689, C684)

## 3. Delete Tests — GB CSV Export (9 tests)

- [x] 3.1 Delete `GBCSVExportHeaderRowContainsAll52Columns`
- [x] 3.2 Delete `GBCSVExportDataRowFullyPopulated`
- [x] 3.3 Delete `GBCSVExportPeriodAggregation4BucketsTo3`
- [x] 3.4 Delete `GBCSVExportRFC4180Escaping`
- [x] 3.5 Delete `GBCSVExportRetentionColumnsBlankWhenGateFalse`
- [x] 3.6 Delete `GBCSVExportDateFormattingMDYYYY`
- [x] 3.7 Delete `GBCSVExportOverduePctFormula`
- [x] 3.8 Delete `GBCSVExportEmptyReport`
- [x] 3.9 Delete `GBCSVExportCardDisputeRetentionLinkVisible`

## 4. Delete Tests — D&R Data Lifecycle (7 tests)

- [x] 4.1 Delete `DisputeRetDataCopyFromPrevious`
- [x] 4.2 Delete `DisputeRetDataCopyFromPreviousFiltersToSameScheme`
- [x] 4.3 Delete `DisputeRetDataPreservedAfterGenerate`
- [x] 4.4 Delete `DisputeRetDataLifecycleCreateAndDelete`
- [x] 4.5 Delete `RetentionPctAutoCalculation`
- [x] 4.6 Delete `ChildToggleClearingHasConstrContractRetention`
- [x] 4.7 Delete `CopyFromPreviousNoPreviousHeader`

## 5. Delete Tests — Payment Period Templates (10 tests)

- [x] 5.1 Delete `PaymentPeriodTemplateDefaultMutualExclusion`
- [x] 5.2 Delete `GenerationGuardBlankPeriodCodeTemplatesExist`
- [x] 5.3 Delete `GenerationGuardBlankPeriodCodeNoTemplates`
- [x] 5.4 Delete `GenerateDefaultTemplateCreatesOnEmptyTable`
- [x] 5.5 Delete `GenerateDefaultTemplateErrorWhenAlreadyExists`
- [x] 5.6 Delete `PaymentPeriodTemplateDefaultCanBeUnchecked`
- [x] 5.7 Delete `CascadingAutoFillPicksDefaultTemplate`
- [x] 5.8 Delete `CascadingAutoFillPicksSoleTemplate`
- [x] 5.9 Delete `CascadingAutoFillBlankWhenMultipleNonDefault`
- [x] 5.10 Delete `PaymentPeriodCardSchemeNonEditableAfterInsert`

## 6. Delete Tests — Card Controls for Deleted UI (2 tests)

- [x] 6.1 Delete `DisputeRetentionLinkNotVisibleForStandardScheme`
- [x] 6.2 Delete `ReportingSchemeSwitchClearsLines`

## 7. Fix Test Codeunit — Globals and Helpers

- [x] 7.1 Change `PaymentPeriods: array[3] of Record "Payment Period Line"` to `Record "Payment Period"`
- [x] 7.2 Delete `ExportGBCSVAndGetLines()` local procedure
- [x] 7.3 Delete `VerifyCSVHeaderColumns()` local procedure
- [x] 7.4 Delete `SplitCSVRow()` local procedure
- [x] 7.5 Delete `RetentionColumnEmptyLbl` and `ColumnMismatchLbl` label vars
- [x] 7.6 Remove `using` statements for deleted objects

## 8. Fix Test Codeunit — Surviving Test Adjustments

- [x] 8.1 Fix `ReportDataSetForVendorsByPeriod_DaysToZero` — change local var `PaymentPeriodLine: Record "Payment Period Line"` to `Record "Payment Period"`
- [x] 8.2 Fix `CompanySizeGenerationSucceedsWithBlankPeriodCode` — remove `"Payment Period Code"` field reference
- [x] 8.3 Fix `CompanySizeStandardLeavesInvoiceCountAndValueZero` — remove scheme overload if needed
- [x] 8.4 Fix `ReportingSchemeAutoDetectionOnInsert` — verify the test body still works with simplified OnInsert
- [x] 8.5 Remove teardown calls to `CreateDefaultPaymentPeriodTemplates()` where they follow deleted template tests

## 9. Verification

- [x] 9.1 Confirm Test Library compiles with zero errors
- [x] 9.2 Confirm Test codeunit compiles with zero errors
- [x] 9.3 Verify no remaining references to T680, T681, T689, P690–693, C684
