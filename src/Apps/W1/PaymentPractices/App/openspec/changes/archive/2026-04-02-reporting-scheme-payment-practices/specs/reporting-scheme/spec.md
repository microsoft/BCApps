## ADDED Requirements

### Requirement: Reporting Scheme enum exists
The system SHALL provide an extensible enum `Paym. Prac. Reporting Scheme` (ID 680) with values: `Standard` (0), `Dispute & Retention` (1), `Small Business` (2). The enum SHALL implement two interfaces: `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler`.

#### Scenario: Enum values are available
- **WHEN** an AL developer references enum `Paym. Prac. Reporting Scheme`
- **THEN** the values Standard, Dispute & Retention, and Small Business are available

#### Scenario: Enum is extensible
- **WHEN** a partner creates an enum extension for `Paym. Prac. Reporting Scheme`
- **THEN** the extension compiles and the new value implements both interfaces

### Requirement: PaymentPracticeDefaultPeriods interface provides period template
The `PaymentPracticeDefaultPeriods` interface SHALL define a method `GetDefaultPaymentPeriods(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)` that returns the default period template code, description, and line buckets for a given scheme.

#### Scenario: Standard handler returns W1 defaults
- **WHEN** the Standard handler's `GetDefaultPaymentPeriods` is called on a non-FR environment
- **THEN** it returns code `'W1-DEFAULT'` with 5 period buckets: 0-30, 31-60, 61-90, 91-120, 121+ days

#### Scenario: Standard handler returns FR defaults
- **WHEN** the Standard handler's `GetDefaultPaymentPeriods` is called on an FR environment (GetApplicationFamily = 'FR')
- **THEN** it returns code `'FR-DEFAULT'` with 4 period buckets: 0-30, 31-60, 61-90, 91+ days

### Requirement: PaymentPracticeSchemeHandler interface controls generation behavior
The `PaymentPracticeSchemeHandler` interface SHALL define methods:
- `ValidateHeader(var PaymentPracticeHeader)` — validates header before generation
- `UpdatePaymentPracData(var PaymentPracticeData): Boolean` — enriches/filters data rows; returns true to include, false to skip
- `CalculateHeaderTotals(var PaymentPracticeHeader; var PaymentPracticeData)` — scheme-specific header aggregations
- `CalculateLineTotals(var PaymentPracticeLine; var PaymentPracticeData)` — scheme-specific line aggregations

#### Scenario: Standard handler is a pass-through
- **WHEN** a Payment Practice Header with Reporting Scheme = Standard generates data
- **THEN** ValidateHeader does nothing, UpdatePaymentPracData returns true for all rows, CalculateHeaderTotals and CalculateLineTotals are no-ops, and the result is identical to the pre-change behavior

### Requirement: Reporting Scheme field on Payment Practice Header
The `Payment Practice Header` table SHALL have a field `Reporting Scheme` (field 15, Enum `Paym. Prac. Reporting Scheme`).

#### Scenario: Auto-detection on insert for GB environment
- **WHEN** a new Payment Practice Header is inserted on a GB environment
- **THEN** the Reporting Scheme is set to `Dispute & Retention`

#### Scenario: Auto-detection on insert for AU environment
- **WHEN** a new Payment Practice Header is inserted on an AU or NZ environment
- **THEN** the Reporting Scheme is set to `Small Business`

#### Scenario: Auto-detection on insert for W1/FR environment
- **WHEN** a new Payment Practice Header is inserted on any non-GB, non-AU/NZ environment
- **THEN** the Reporting Scheme is set to `Standard`

#### Scenario: User changes Reporting Scheme with existing lines
- **WHEN** the user changes the Reporting Scheme on a header that has generated lines
- **THEN** the system shows a confirmation dialog; if confirmed, lines and data are cleared and the scheme is updated; if declined, the scheme reverts to the previous value

### Requirement: Scheme handler integrated into Generate flow
The `Generate()` procedure SHALL call `SchemeHandler.ValidateHeader()` before data generation and `SchemeHandler.CalculateHeaderTotals()` after existing `GenerateTotals()`. The Builders SHALL call `SchemeHandler.UpdatePaymentPracData()` before inserting each data row, skipping the insert if it returns false. The line generation SHALL call `SchemeHandler.CalculateLineTotals()` for each generated line.

#### Scenario: Scheme validation prevents incompatible generation
- **WHEN** Generate() is called on a header whose Reporting Scheme handler rejects the Header Type via ValidateHeader
- **THEN** an error is raised before any data is generated

#### Scenario: Scheme handler filters data rows
- **WHEN** Generate() processes vendor invoices and the scheme handler's UpdatePaymentPracData returns false for a row
- **THEN** that row is not inserted into Payment Practice Data

#### Scenario: Scheme handler enriches data rows
- **WHEN** Generate() processes vendor invoices and the scheme handler's UpdatePaymentPracData modifies fields on a data row and returns true
- **THEN** the enriched row is inserted into Payment Practice Data with the modified field values
