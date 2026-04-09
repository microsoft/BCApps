## ADDED Requirements

### Requirement: Test library period initialization uses T685
The test library `CreateDefaultPaymentPeriodTemplates()` SHALL delete all `Payment Period` (T685) records and call `PaymentPeriod.SetupDefaults()`. It SHALL NOT reference `Payment Period Header` (T680), `Payment Period Line` (T681), or `PaymentPeriodMgt.InsertDefaultTemplate()`.

#### Scenario: Period initialization creates default periods
- **WHEN** `CreateDefaultPaymentPeriodTemplates()` is called
- **THEN** T685 `Payment Period` records exist with the default W1 period set (5 buckets: 0-30, 31-60, 61-90, 91-120, 121+)

### Requirement: Test library header creation omits deleted objects
All `CreatePaymentPracticeHeader` overloads and `CreatePaymentPracticeHeaderWithScheme` SHALL NOT call `FindDefaultPaymentPeriodCode()` or `InsertDisputeRetData()`. They SHALL insert the header without setting a `Payment Period Code` field.

#### Scenario: Header created without D&R companion record
- **WHEN** `CreatePaymentPracticeHeaderWithScheme` is called with any reporting scheme
- **THEN** a `Payment Practice Header` record is created
- **THEN** no `Paym. Prac. Dispute Ret. Data` record is created

### Requirement: Test codeunit PaymentPeriods variable uses T685
The global `PaymentPeriods: array[3] of Record "Payment Period Line"` SHALL be changed to `PaymentPeriods: array[3] of Record "Payment Period"`.

#### Scenario: Period-based tests read from T685
- **WHEN** `InitializePaymentPeriods` populates the `PaymentPeriods` array
- **THEN** each element references a `Payment Period` (T685) record with valid `Days From`, `Days To`, and `Description`

### Requirement: Tests for deleted objects are removed
The test codeunit SHALL NOT contain tests that reference `Paym. Prac. Dispute Ret. Data` (T689), `Paym. Prac. GB CSV Export` (C684), `Payment Period Header` (T680), `Payment Period Line` (T681), `Payment Period Card` (P690), `Payment Period List` (P691), or the `DisputeRetentionLink` page control.

#### Scenario: GB CSV export tests removed
- **WHEN** the test codeunit is compiled
- **THEN** no test procedures reference `GBCSVExport`, `ExportGBCSVAndGetLines`, `SplitCSVRow`, `VerifyCSVHeaderColumns`, `GBCSVFormatDateGov`, or `GBCSVEscapeCSVField`

#### Scenario: D&R data lifecycle tests removed
- **WHEN** the test codeunit is compiled
- **THEN** no test procedures reference `DisputeRetData`, `CopyFromPrevious`, or `Paym. Prac. Dispute Ret. Data`

#### Scenario: Payment Period Template tests removed
- **WHEN** the test codeunit is compiled
- **THEN** no test procedures reference `Payment Period Header`, `Payment Period List`, `PaymentPeriodCard`, `GenerateDefaultTemplate`, `CascadingAutoFill`, or `PaymentPeriodTemplateDefault`

### Requirement: D&R header calculation tests survive
The four `DisputeRetCalcHeaderTotals_*` tests SHALL remain. They validate `CalculateHeaderTotals` on C681 via `MockPaymentPracticeData` and do not depend on T689.

#### Scenario: D&R calc test compiles and runs
- **WHEN** `DisputeRetCalcHeaderTotals_AllPaidOnTime` executes
- **THEN** it creates a header via `CreatePaymentPracticeHeaderWithScheme`, mocks data via `MockPaymentPracticeData`, calls `DisputeRetCalcHeaderTotals`, and asserts header totals

### Requirement: Surviving tests compile without deleted object references
After all changes, the Test codeunit and Test Library SHALL compile with zero errors. No `using` statement, variable declaration, or procedure body SHALL reference any deleted object.

#### Scenario: Clean compilation
- **WHEN** the AL compiler runs on the Test and Test Library projects
- **THEN** zero compilation errors are produced

## REMOVED Requirements

### Requirement: Test library GB CSV helpers
**Reason**: `Paym. Prac. GB CSV Export` (C684) is deleted from the App layer.
**Migration**: Delete `GBCSVExport()`, `GBCSVFormatDateGov()`, `GBCSVEscapeCSVField()`, `CreateFullyPopulatedGBHeader()` from the test library.

### Requirement: Test library D&R data helpers
**Reason**: `Paym. Prac. Dispute Ret. Data` (T689) is deleted from the App layer.
**Migration**: Delete `InsertDisputeRetData()`. Remove `DisputeRetData.DeleteAll()` from `CleanupPaymentPracticeHeaders()`.

### Requirement: Test library Payment Period Template helpers
**Reason**: `Payment Period Header` (T680) and `Payment Period Line` (T681) are deleted from the App layer.
**Migration**: Delete `FindDefaultPaymentPeriodCode()`, `CreatePaymentPeriodTemplate()`, `DeletePaymentPeriodTemplatesForScheme()`. Rewrite `CreateDefaultPaymentPeriodTemplates()` to use T685. Rewrite `InitializePaymentPeriods()` and `InitAndGetLastPaymentPeriod()` to use T685.

### Requirement: Test codeunit CSV helper procedures
**Reason**: No GB CSV export functionality exists to test.
**Migration**: Delete `ExportGBCSVAndGetLines()`, `VerifyCSVHeaderColumns()`, `SplitCSVRow()`, and labels `RetentionColumnEmptyLbl`, `ColumnMismatchLbl`.
