## ADDED Requirements

### Requirement: Dispute & Retention handler implements both interfaces
Codeunit `Paym. Prac. Dispute & Ret. Handler` (C681) SHALL implement `PaymentPracticeDefaultPeriods` and `PaymentPracticeSchemeHandler` for the `Dispute & Retention` enum value.

#### Scenario: Handler is invoked for GB scheme
- **WHEN** a Payment Practice Header has Reporting Scheme = Dispute & Retention
- **THEN** all generation-time calls dispatch to the Dispute & Retention handler

### Requirement: GB default payment periods
The handler's `GetDefaultPaymentPeriods()` SHALL return Code `'GB-DEFAULT'`, Description `'UK Payment Periods (0-30, 31-60, 61-120, 121+)'`, and 4 line buckets: 0-30, 31-60, 61-120, 121+ days.

#### Scenario: GB default periods are correct
- **WHEN** GetDefaultPaymentPeriods is called on the Dispute & Retention handler
- **THEN** it returns 4 period lines with Days From/To: (0,30), (31,60), (61,120), (121,0)

### Requirement: Dispute Status flows from VLE to Payment Practice Data
The `Payment Practice Data` table SHALL have a field `Dispute Status` (field 20, Boolean). During data generation, the handler's `UpdatePaymentPracData()` SHALL copy the dispute status from the source Vendor Ledger Entry to `PaymentPracticeData."Dispute Status"`.

#### Scenario: Invoice marked as disputed in VLE
- **WHEN** generating data for a vendor invoice where the VLE has dispute status = true
- **THEN** the Payment Practice Data row has Dispute Status = true

#### Scenario: Invoice not disputed
- **WHEN** generating data for a vendor invoice where the VLE has dispute status = false
- **THEN** the Payment Practice Data row has Dispute Status = false

### Requirement: Overdue Due to Dispute is calculated
The `Payment Practice Data` table SHALL have a field `Overdue Due to Dispute` (field 21, Boolean, Editable = false). The handler SHALL set this to true when the data row is both overdue (Actual Payment Days > Agreed Payment Days) and disputed (Dispute Status = true).

#### Scenario: Overdue and disputed
- **WHEN** a data row has Actual Payment Days > Agreed Payment Days and Dispute Status = true
- **THEN** Overdue Due to Dispute is set to true

#### Scenario: Overdue but not disputed
- **WHEN** a data row has Actual Payment Days > Agreed Payment Days and Dispute Status = false
- **THEN** Overdue Due to Dispute is set to false

#### Scenario: Not overdue
- **WHEN** a data row has Actual Payment Days <= Agreed Payment Days regardless of Dispute Status
- **THEN** Overdue Due to Dispute is set to false

### Requirement: SCF Payment Date field on Vendor Ledger Entry
The `Vendor Ledger Entry` table (BaseApp T25) SHALL have a field `SCF Payment Date` (Date). This field is the primary source for SCF dates, set by users or SCF integrations at payment time. It SHALL be visible on the Vendor Ledger Entries page (P29) with `Visible = false` (user can unhide via Personalize).

#### Scenario: SCF Payment Date is set on VLE
- **WHEN** a user or integration sets SCF Payment Date on a Vendor Ledger Entry
- **THEN** the date is stored and available for Payment Practice data generation

### Requirement: SCF Payment Date flows from VLE to Payment Practice Data
The `Payment Practice Data` table SHALL have a field `SCF Payment Date` (field 22, Date, Editable = true). During data generation, `CopyFromInvoiceVendLedgEntry()` SHALL copy `VLE."SCF Payment Date"` to `PaymentPracticeData."SCF Payment Date"`. The user can also manually enter or override the date on the Payment Practice Data page.

#### Scenario: SCF date copied from VLE during generation
- **WHEN** generating data for a vendor invoice where VLE."SCF Payment Date" = 2025-03-15
- **THEN** PaymentPracticeData."SCF Payment Date" = 2025-03-15

#### Scenario: SCF date manually entered on data record
- **WHEN** a user manually sets SCF Payment Date = 2025-04-01 on a Payment Practice Data row
- **THEN** the value is saved and used for subsequent calculations

### Requirement: SCF Payment Date recalculates Actual Payment Days
When `PaymentPracticeData."SCF Payment Date" <> 0D`, the handler SHALL recalculate `"Actual Payment Days" := "SCF Payment Date" - "Invoice Received Date"`. When `SCF Payment Date` is blank (0D), the default calculation using `Pmt. Posting Date` SHALL be used.

#### Scenario: SCF date overrides payment days calculation
- **WHEN** a data row has SCF Payment Date = 2025-03-15 and Invoice Received Date = 2025-02-15
- **THEN** Actual Payment Days = 28 (not based on Pmt. Posting Date)

#### Scenario: No SCF date uses default calculation
- **WHEN** a data row has SCF Payment Date = 0D and Pmt. Posting Date = 2025-04-01 and Invoice Received Date = 2025-02-15
- **THEN** Actual Payment Days = 45 (based on Pmt. Posting Date - Invoice Received Date)

### Requirement: GB payment statistics on Payment Practice Header
The `Payment Practice Header` SHALL have calculated fields (Editable = false): `Total Number of Payments` (field 20, Integer), `Total Amount of Payments` (field 21, Decimal), `Total Amt. of Overdue Payments` (field 22, Decimal), `Pct Overdue Due to Dispute` (field 23, Decimal). These are populated by `CalculateHeaderTotals()` from Payment Practice Data.

#### Scenario: Payment statistics populated after generation
- **WHEN** Generate() completes for a Dispute & Retention header with 100 data rows, 20 of which are overdue, 5 overdue due to dispute
- **THEN** Total Number of Payments = 100, Pct Overdue Due to Dispute = 25% (5/20)

### Requirement: GB payment policy tick-box fields
The `Payment Practice Header` SHALL have user-entered Boolean fields: `Offers E-Invoicing` (30), `Offers Supply Chain Finance` (31), `Policy Covers Deduction Charges` (32), `Has Deducted Charges in Period` (33), `Is Payment Code Member` (34), and `Payment Code Name` (35, Text[250], editable only when Is Payment Code Member = true).

#### Scenario: User fills payment policy fields
- **WHEN** a user sets Offers E-Invoicing = true, Is Payment Code Member = true, Payment Code Name = 'Prompt Payment Code'
- **THEN** the values are saved on the Payment Practice Header

#### Scenario: Payment Code Name editable only when member
- **WHEN** Is Payment Code Member = false
- **THEN** Payment Code Name is not editable

### Requirement: Construction contract retention fields
The `Payment Practice Header` SHALL have a gate field `Has Constr. Contract Retention` (40, Boolean). When true, sub-fields SHALL be available: retention clause usage fields (41-44), contract sum threshold (45-46), standard retention percentage (47-48), terms fairness practice (49-50), release mechanism (51-53), and retention statistics — user-entered amounts (54-56) and auto-calculated percentages (57-58).

#### Scenario: Retention fields visible when gate is true
- **WHEN** Has Constr. Contract Retention = true
- **THEN** all retention sub-fields (41-58) are visible/editable on the Payment Practice Card

#### Scenario: Retention fields hidden when gate is false
- **WHEN** Has Constr. Contract Retention = false
- **THEN** retention sub-fields are not visible on the Payment Practice Card

#### Scenario: Retention percentage auto-calculated
- **WHEN** Retention Withheld from Suppliers = 50000, Retention Withheld by Clients = 200000, Gross Payments Under Constr. Contracts = 1000000
- **THEN** Pct Retention vs Client Retention = 25% (50000/200000 × 100), Pct Retention vs Gross Payments = 5% (50000/1000000 × 100)

#### Scenario: Conditional narrative fields
- **WHEN** Retention in Specific Circumstances = true
- **THEN** Retention Circumstances Desc. is editable
- **WHEN** Retention in Specific Circumstances = false
- **THEN** Retention Circumstances Desc. is not editable

### Requirement: Payment Practice Card shows GB-specific groups
The `Payment Practice Card` page SHALL show Payment Policies, Payment Statistics, and Construction Contract Retention groups only when Reporting Scheme = Dispute & Retention.

#### Scenario: GB card layout
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the Payment Policies, Payment Statistics, and Construction Contract Retention groups are visible

#### Scenario: Standard card layout hides GB groups
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Standard
- **THEN** the Payment Policies, Payment Statistics, and Construction Contract Retention groups are not visible

### Requirement: Payment Practice Data List shows dispute columns
The `Payment Practice Data List` page SHALL show Dispute Status, Overdue Due to Dispute, and SCF Payment Date columns with visibility controlled by Reporting Scheme.

#### Scenario: Dispute columns visible for GB scheme
- **WHEN** a user opens Payment Practice Data List for a Dispute & Retention header
- **THEN** Dispute Status, Overdue Due to Dispute, and SCF Payment Date columns are visible
