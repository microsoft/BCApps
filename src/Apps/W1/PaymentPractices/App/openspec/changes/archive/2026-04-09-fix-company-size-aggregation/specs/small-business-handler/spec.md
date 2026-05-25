## MODIFIED Requirements

### Requirement: Invoice Count and Invoice Value on Payment Practice Line
The `Payment Practice Line` table SHALL have fields `Invoice Count` (field 15, Integer) and `Invoice Value` (field 16, Decimal). The handler's `CalculateLineTotals()` SHALL populate these fields for each generated line — both Period and Company Size aggregation types — by counting and summing the closed invoices whose data falls within the line's scope.

#### Scenario: Invoice count and value per period
- **WHEN** a Small Business header generates period lines with 3 buckets (0-30, 31-60, 61+) and there are 10 invoices paid within 0-30 days totaling $50,000
- **THEN** the 0-30 day line has Invoice Count = 10 and Invoice Value = 50000

#### Scenario: Invoice count and value per company size
- **WHEN** a Small Business header generates company size lines and a company size code has 5 closed invoices totaling $25,000
- **THEN** the company size line has Invoice Count = 5 and Invoice Value = 25000

#### Scenario: Open invoices not counted
- **WHEN** an invoice is still open (Invoice Is Open = true)
- **THEN** it is not included in Invoice Count or Invoice Value for any line
