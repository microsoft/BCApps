## ADDED Requirements

### Requirement: Small Business handler implements both interfaces
Codeunit `Paym. Prac. Small Bus. Handler` (C682) SHALL implement `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler` for the `Small Business` enum value.

#### Scenario: Handler is invoked for AU scheme
- **WHEN** a Payment Practice Header has Reporting Scheme = Small Business
- **THEN** all generation-time calls dispatch to the Small Business handler

### Requirement: AU default payment periods
The handler's `GetDefaultPaymentPeriods()` SHALL return Code `'AU-DEFAULT'`, Description `'AU/NZ Payment Periods (0-30, 31-60, 61+)'`, and 3 line buckets: 0-30, 31-60, 61+ days per Payment Times Reporting Rules 2024 s13(2)(e).

#### Scenario: AU default periods are correct
- **WHEN** GetDefaultPaymentPeriods is called on the Small Business handler
- **THEN** it returns 3 period lines with Days From/To: (0,30), (31,60), (61,0)

### Requirement: Small Business Supplier field on Vendor
The `Vendor` table (BaseApp T23) SHALL have a field `Small Business Supplier` (field 136, Boolean) with ToolTip 'Specifies that this vendor is a small business supplier (annual turnover < AUD 10 million) for Payment Times Reporting.' The field SHALL appear on the Vendor Card page in the Payments group, following the same pattern as "Exclude from Pmt. Practices".

#### Scenario: Vendor marked as small business
- **WHEN** a user sets Small Business Supplier = true on a Vendor Card
- **THEN** the flag is saved and the vendor is included in Small Business scheme generation

#### Scenario: Vendor not marked as small business
- **WHEN** Small Business Supplier is false (default) on a vendor
- **THEN** the vendor is excluded from Small Business scheme generation

### Requirement: Non-small-business vendors excluded from data generation
The handler's `UpdatePaymentPracData()` SHALL check `Vendor."Small Business Supplier"`: return true for small-business vendors (include the row), return false for non-small-business vendors (skip the row, preventing insertion into Payment Practice Data).

#### Scenario: Small business vendor invoices included
- **WHEN** generating data for the Small Business scheme and the vendor has Small Business Supplier = true
- **THEN** the vendor's invoice rows are included in Payment Practice Data

#### Scenario: Non-small-business vendor invoices excluded
- **WHEN** generating data for the Small Business scheme and the vendor has Small Business Supplier = false
- **THEN** the vendor's invoice rows are NOT inserted into Payment Practice Data (zero rows for that vendor)

#### Scenario: All vendors included for Standard scheme
- **WHEN** generating data for the Standard scheme regardless of Small Business Supplier flag
- **THEN** all non-excluded vendor invoices are included (Small Business Supplier has no effect)

### Requirement: ValidateHeader rejects Customer and Vendor+Customer
The handler's `ValidateHeader()` SHALL error if `Header Type` is `Customer` or `Vendor+Customer`. AU legislation covers supplier (vendor) payments only.

#### Scenario: Vendor header type allowed
- **WHEN** Generate() is called on a Small Business header with Header Type = Vendor
- **THEN** validation passes

#### Scenario: Customer header type rejected
- **WHEN** Generate() is called on a Small Business header with Header Type = Customer
- **THEN** an error is raised before data generation

#### Scenario: Vendor+Customer header type rejected
- **WHEN** Generate() is called on a Small Business header with Header Type = Vendor+Customer
- **THEN** an error is raised before data generation

### Requirement: Invoice Count and Invoice Value on Payment Practice Line
The `Payment Practice Line` table SHALL have fields `Invoice Count` (field 14, Integer) and `Invoice Value` (field 15, Decimal). The handler's `CalculateLineTotals()` SHALL populate these fields for each period bucket by counting and summing the closed invoices whose Actual Payment Days fall within the bucket's range.

#### Scenario: Invoice count and value per period
- **WHEN** a Small Business header generates period lines with 3 buckets (0-30, 31-60, 61+) and there are 10 invoices paid within 0-30 days totaling $50,000
- **THEN** the 0-30 day line has Invoice Count = 10 and Invoice Value = 50000

#### Scenario: Open invoices not counted
- **WHEN** an invoice is still open (Invoice Is Open = true)
- **THEN** it is not included in Invoice Count or Invoice Value for any period bucket

### Requirement: CalculateHeaderTotals populates total invoice count and value
The handler's `CalculateHeaderTotals()` SHALL populate total number of invoices and total value of invoices on the Payment Practice Header.

#### Scenario: Header totals reflect all small business invoices
- **WHEN** generation completes for a Small Business header with 50 closed invoice data rows totaling $250,000
- **THEN** the header shows total number = 50 and total value = 250000

### Requirement: Payment Practice Lines page shows AU columns
The `Payment Practice Lines` page SHALL show Invoice Count and Invoice Value columns with visibility controlled by Reporting Scheme = Small Business.

#### Scenario: AU columns visible for Small Business scheme
- **WHEN** a user views Payment Practice Lines for a Small Business header
- **THEN** Invoice Count and Invoice Value columns are visible

#### Scenario: AU columns hidden for other schemes
- **WHEN** a user views Payment Practice Lines for a Standard or Dispute & Retention header
- **THEN** Invoice Count and Invoice Value columns are not visible
