## MODIFIED Requirements

### Requirement: Reporting Scheme enum exists
The system SHALL provide an extensible enum `Paym. Prac. Reporting Scheme` (ID 680) with values: `Standard` (0), `Dispute & Retention` (1), `Small Business` (2). The enum SHALL implement one interface: `PaymentPracticeSchemeHandler`.

#### Scenario: Enum values are available
- **WHEN** an AL developer references enum `Paym. Prac. Reporting Scheme`
- **THEN** the values Standard, Dispute & Retention, and Small Business are available

#### Scenario: Enum is extensible
- **WHEN** a partner creates an enum extension for `Paym. Prac. Reporting Scheme`
- **THEN** the extension compiles and the new value implements the `PaymentPracticeSchemeHandler` interface

### Requirement: Reporting Scheme field on Payment Practice Header
The `Payment Practice Header` table SHALL have a field `Reporting Scheme` (field 15, Enum `Paym. Prac. Reporting Scheme`). The field SHALL be auto-detected on insert via `DetectReportingScheme()` and SHALL NOT be user-editable. On the `Payment Practice Card` page, the field SHALL be present with `Visible = false` and `Editable = false`.

#### Scenario: Auto-detection on insert for GB environment
- **WHEN** a new Payment Practice Header is inserted on a GB environment
- **THEN** the Reporting Scheme is set to `Dispute & Retention`

#### Scenario: Auto-detection on insert for AU environment
- **WHEN** a new Payment Practice Header is inserted on an AU or NZ environment
- **THEN** the Reporting Scheme is set to `Small Business`

#### Scenario: Auto-detection on insert for W1/FR environment
- **WHEN** a new Payment Practice Header is inserted on any non-GB, non-AU/NZ environment
- **THEN** the Reporting Scheme is set to `Standard`

#### Scenario: Reporting Scheme not visible on card
- **WHEN** a user opens the Payment Practice Card page
- **THEN** the Reporting Scheme field is not visible by default

#### Scenario: Reporting Scheme not editable
- **WHEN** a user personalizes the Payment Practice Card to show Reporting Scheme
- **THEN** the field is not editable

### Requirement: Scheme handler integrated into Generate flow
The `Generate()` procedure SHALL call `SchemeHandler.ValidateHeader()` before data generation and `SchemeHandler.CalculateHeaderTotals()` after existing `GenerateTotals()`. The Builders SHALL call `SchemeHandler.UpdatePaymentPracData()` before inserting each data row, skipping the insert if it returns false. The line generation SHALL call `SchemeHandler.CalculateLineTotals()` for each generated line. Period aggregation SHALL read buckets from the `Payment Period` table (T685).

#### Scenario: Scheme validation prevents incompatible generation
- **WHEN** Generate() is called on a header whose Reporting Scheme handler rejects the Header Type via ValidateHeader
- **THEN** an error is raised before any data is generated

#### Scenario: Scheme handler filters data rows
- **WHEN** Generate() processes vendor invoices and the scheme handler's UpdatePaymentPracData returns false for a row
- **THEN** that row is not inserted into Payment Practice Data

#### Scenario: Scheme handler enriches data rows
- **WHEN** Generate() processes vendor invoices and the scheme handler's UpdatePaymentPracData modifies fields on a data row and returns true
- **THEN** the enriched row is inserted into Payment Practice Data with the modified field values

## ADDED Requirements

### Requirement: DetectReportingScheme extensibility event
Codeunit 695 `Payment Period Mgt.` SHALL expose an integration event `OnBeforeDetectReportingScheme(var ReportingScheme: Enum "Paym. Prac. Reporting Scheme"; var IsHandled: Boolean)` that fires before the AppFamily-based detection. If `IsHandled` is set to true by a subscriber, the returned `ReportingScheme` value SHALL be used.

#### Scenario: Partner overrides scheme detection
- **WHEN** a partner subscribes to `OnBeforeDetectReportingScheme` and sets `IsHandled = true` with a custom scheme value
- **THEN** `DetectReportingScheme()` returns the partner-provided scheme instead of the AppFamily-based default

#### Scenario: Default detection unchanged when no subscriber
- **WHEN** no subscriber sets `IsHandled` on `OnBeforeDetectReportingScheme`
- **THEN** `DetectReportingScheme()` uses the standard AppFamily → Scheme mapping

## REMOVED Requirements

### Requirement: PaymentPracticeDefaultPeriods interface provides period template
**Reason**: Payment period templates are removed. Period seeding is handled by `SetupDefaults()` on table 685 with per-AppFamily branching. The interface has no remaining purpose.
**Migration**: Partners who extended `PaymentPracticeDefaultPeriods` should use the `OnBeforeSetupDefaults` integration event on table 685 to seed custom periods.

### Requirement: User changes Reporting Scheme with existing lines
**Reason**: Reporting Scheme is auto-detected and not user-editable. The OnValidate confirmation dialog is no longer needed.
**Migration**: No action required. The field is set once on insert and cannot be changed.

### Requirement: Period aggregation requires Payment Period Code
**Reason**: `Payment Period Code` field removed from header. Period aggregation reads directly from table 685.
**Migration**: No action required.

### Requirement: Company Size aggregation does not require Payment Period Code
**Reason**: `Payment Period Code` field removed from header. This guard is no longer applicable.
**Migration**: No action required.
