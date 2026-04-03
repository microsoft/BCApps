## ADDED Requirements

### Requirement: Dispute & Retention detail table exists
The system SHALL provide a table `Paym. Prac. Dispute Ret. Data` (T689) with primary key `Header No.` (Integer) and a `TableRelation` to `Payment Practice Header.No.`. The table SHALL hold all Dispute & Retention qualitative fields extracted from the Payment Practice Header.

#### Scenario: Table structure
- **WHEN** a developer inspects table T689
- **THEN** it has primary key `Header No.` linking to T687, DataClassification = CustomerContent

### Requirement: Detail table contains payment policy fields
The table SHALL have fields: `Offers E-Invoicing` (Boolean), `Offers Supply Chain Finance` (Boolean), `Policy Covers Deduct. Charges` (Boolean), `Is Payment Code Member` (Boolean).

#### Scenario: User sets payment policy fields
- **WHEN** a user sets Offers E-Invoicing = true and Is Payment Code Member = false on a T689 record
- **THEN** the values are persisted

### Requirement: Detail table contains qualifying contract fields
The table SHALL have fields: `Qualifying Contracts in Period` (Boolean), `Payments Made in Period` (Boolean), `Qual. Constr. Contr. in Period` (Boolean).

#### Scenario: User fills qualifying contract gates
- **WHEN** a user sets Qualifying Contracts in Period = true
- **THEN** the value is persisted on the T689 record

### Requirement: Detail table contains payment terms fields
The table SHALL have fields: `Shortest Standard Pmt. Period` (Integer), `Longest Standard Pmt. Period` (Integer), `Standard Payment Terms Desc.` (Text[2048]), `Payment Terms Have Changed` (Boolean), `Suppliers Notified of Changes` (Boolean), `Max Contractual Pmt. Period` (Integer), `Max Contr. Pmt. Period Info` (Text[2048]), `Other Pmt. Terms Information` (Text[2048]).

#### Scenario: Suppliers Notified conditional on Payment Terms Changed
- **WHEN** Payment Terms Have Changed = false
- **THEN** Suppliers Notified of Changes is reset to false

#### Scenario: Payment terms narrative saved
- **WHEN** a user enters Standard Payment Terms Desc. = "30 days from invoice date"
- **THEN** the value is persisted

### Requirement: Detail table contains construction retention fields
The table SHALL have a gate field `Has Constr. Contract Retention` (Boolean). When true, the following sub-fields SHALL be available: `Ret. Clause Used in Contracts` (Boolean), `Retention in Std Pmt. Terms` (Boolean), `Retention in Specific Circs.` (Boolean), `Retention Circs. Desc.` (Text[250]), `Withholds Retent. from Subcon` (Boolean), `Contract Sum Threshold` (Decimal), `Std Retention Pct Used` (Boolean), `Standard Retention Pct` (Decimal), `Terms Fairness Practice` (Boolean), `Terms Fairness Desc.` (Text[250]), `Release Mechanism Desc.` (Text[250]), `Release Within Prescribed Days` (Boolean), `Prescribed Days Desc.` (Text[250]).

#### Scenario: Retention Circs. Desc. cleared when gate is false
- **WHEN** Retention in Specific Circs. is set to false
- **THEN** Retention Circs. Desc. is cleared

#### Scenario: Standard Retention Pct cleared when not used
- **WHEN** Std Retention Pct Used is set to false
- **THEN** Standard Retention Pct is reset to 0

### Requirement: Detail table contains retention statistics fields
The table SHALL have user-entered fields: `Retent. Withheld from Suppls.` (Decimal), `Retention Withheld by Clients` (Decimal), `Gross Payments Constr. Contr.` (Decimal). It SHALL have auto-calculated fields (Editable = false): `Pct Retention vs Client Ret.` (Decimal), `Pct Retent. vs Gross Payments` (Decimal).

#### Scenario: Retention percentages auto-calculated
- **WHEN** Retent. Withheld from Suppls. = 50000, Retention Withheld by Clients = 200000, Gross Payments Constr. Contr. = 1000000
- **THEN** Pct Retention vs Client Ret. = 25, Pct Retent. vs Gross Payments = 5

#### Scenario: Division by zero protection
- **WHEN** Retention Withheld by Clients = 0
- **THEN** Pct Retention vs Client Ret. = 0

### Requirement: Detail table contains dispute resolution field
The table SHALL have field `Dispute Resolution Process` (Text[2048]).

#### Scenario: Narrative field saves long text
- **WHEN** a user enters a 500-character dispute resolution description
- **THEN** the value is persisted

### Requirement: Detail table contains deduction charges field
The table SHALL have field `Has Deducted Charges in Period` (Boolean).

#### Scenario: Deduction charge field persisted
- **WHEN** a user sets Has Deducted Charges in Period = true
- **THEN** the value is persisted on T689

### Requirement: Detail record created on header insert
When a `Payment Practice Header` record is inserted, a corresponding `Paym. Prac. Dispute Ret. Data` record SHALL be created with `Header No.` matching the header's `No.`.

#### Scenario: Header insert creates detail record
- **WHEN** a new Payment Practice Header with No. = 1001 is inserted
- **THEN** a Paym. Prac. Dispute Ret. Data record with Header No. = 1001 exists

#### Scenario: Detail record exists for all schemes
- **WHEN** a Payment Practice Header with Reporting Scheme = Standard is inserted
- **THEN** a corresponding T689 record is created (empty but present)

### Requirement: Detail record deleted with header
When a `Payment Practice Header` record is deleted, its corresponding `Paym. Prac. Dispute Ret. Data` record SHALL be deleted.

#### Scenario: Header delete cascades to detail
- **WHEN** Payment Practice Header No. = 1001 is deleted
- **THEN** Paym. Prac. Dispute Ret. Data with Header No. = 1001 no longer exists

### Requirement: Copy from previous period
The table SHALL provide a procedure `CopyFromPrevious()` that finds the most recent `Paym. Prac. Dispute Ret. Data` record (by the linked header's Ending Date, excluding the current record) and copies standing-policy fields to the current record. Period-specific fields SHALL be cleared after copy.

#### Scenario: Copy standing-policy fields from previous period
- **WHEN** a user invokes Copy from Previous on a T689 record for header with Ending Date = 2026-03-31
- **AND** a previous T689 record exists for a header with Ending Date = 2025-09-30, with Dispute Resolution Process = "Mediation first", Offers E-Invoicing = true, Has Constr. Contract Retention = true, Ret. Clause Used in Contracts = true
- **THEN** the current record has Dispute Resolution Process = "Mediation first", Offers E-Invoicing = true, Has Constr. Contract Retention = true, Ret. Clause Used in Contracts = true

#### Scenario: Period-specific fields cleared after copy
- **WHEN** Copy from Previous copies from a record where Retent. Withheld from Suppls. = 50000, Payment Terms Have Changed = true, Suppliers Notified of Changes = true, Has Deducted Charges in Period = true, Payments Made in Period = true
- **THEN** the current record has Retent. Withheld from Suppls. = 0, Retention Withheld by Clients = 0, Gross Payments Constr. Contr. = 0, Pct Retention vs Client Ret. = 0, Pct Retent. vs Gross Payments = 0, Payment Terms Have Changed = false, Suppliers Notified of Changes = false, Has Deducted Charges in Period = false, Payments Made in Period = false

#### Scenario: No previous period exists
- **WHEN** a user invokes Copy from Previous and no other T689 record exists
- **THEN** the system shows a message that no previous period was found and makes no changes

### Requirement: CalculateRetentionPercentages on detail table
The table SHALL have a local procedure `CalculateRetentionPercentages()` triggered by OnValidate of `Retent. Withheld from Suppls.`, `Retention Withheld by Clients`, and `Gross Payments Constr. Contr.`. It SHALL calculate `Pct Retention vs Client Ret.` = Retent. Withheld from Suppls. / Retention Withheld by Clients × 100 (0 if denominator is 0) and `Pct Retent. vs Gross Payments` = Retent. Withheld from Suppls. / Gross Payments Constr. Contr. × 100 (0 if denominator is 0).

#### Scenario: Both percentages calculated
- **WHEN** Retent. Withheld from Suppls. = 30000, Retention Withheld by Clients = 120000, Gross Payments Constr. Contr. = 600000
- **THEN** Pct Retention vs Client Ret. = 25, Pct Retent. vs Gross Payments = 5
