## MODIFIED Requirements

### Requirement: Scheme handler integrated into Generate flow
The `Generate()` procedure SHALL call `SchemeHandler.ValidateHeader()` before data generation and `SchemeHandler.CalculateHeaderTotals()` after existing `GenerateTotals()`. The Builders SHALL call `SchemeHandler.UpdatePaymentPracData()` before inserting each data row, skipping the insert if it returns false. The line generation SHALL call `SchemeHandler.CalculateLineTotals()` for each generated line. The `Payment Period Code` validation SHALL only fire when `Aggregation Type = Period`; Company Size aggregation SHALL NOT require a payment period code.

#### Scenario: Scheme validation prevents incompatible generation
- **WHEN** Generate() is called on a header whose Reporting Scheme handler rejects the Header Type via ValidateHeader
- **THEN** an error is raised before any data is generated

#### Scenario: Scheme handler filters data rows
- **WHEN** Generate() processes vendor invoices and the scheme handler's UpdatePaymentPracData returns false for a row
- **THEN** that row is not inserted into Payment Practice Data

#### Scenario: Scheme handler enriches data rows
- **WHEN** Generate() processes vendor invoices and the scheme handler's UpdatePaymentPracData modifies fields on a data row and returns true
- **THEN** the enriched row is inserted into Payment Practice Data with the modified field values

#### Scenario: Period aggregation requires Payment Period Code
- **WHEN** Generate() is called with Aggregation Type = Period and Payment Period Code is blank
- **THEN** validation errors that a Payment Period Code must be selected

#### Scenario: Company Size aggregation does not require Payment Period Code
- **WHEN** Generate() is called with Aggregation Type = Company Size and Payment Period Code is blank
- **THEN** validation passes and generation proceeds without error
