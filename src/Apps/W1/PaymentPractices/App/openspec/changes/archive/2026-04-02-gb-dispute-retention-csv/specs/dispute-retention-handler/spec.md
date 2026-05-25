## ADDED Requirements

### Requirement: Qualifying contract gate fields on Payment Practice Header
The `Payment Practice Header` table SHALL have Boolean fields: `Qualifying Contracts in Period` (field 60), `Payments Made in Period` (field 61), `Qual. Constr. Contracts in Period` (field 62). These are user-entered gate fields visible only when Reporting Scheme = Dispute & Retention.

#### Scenario: User sets qualifying contract gates
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the Qualifying Contracts in Period, Payments Made in Period, and Qual. Constr. Contracts in Period fields are visible and editable

#### Scenario: Gate fields hidden for other schemes
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Standard
- **THEN** the qualifying contract gate fields are not visible

### Requirement: Payment terms description fields on Payment Practice Header
The `Payment Practice Header` table SHALL have fields: `Shortest Standard Pmt. Period` (field 63, Integer), `Longest Standard Pmt. Period` (field 64, Integer), `Standard Payment Terms Desc.` (field 65, Text[2048]), `Payment Terms Have Changed` (field 66, Boolean), `Suppliers Notified of Changes` (field 67, Boolean, editable only when field 66 = true), `Max Contractual Pmt. Period` (field 68, Integer), `Max Contractual Pmt. Period Info` (field 69, Text[2048]), `Other Pmt. Terms Information` (field 70, Text[2048]). These are user-entered fields visible only when Reporting Scheme = Dispute & Retention.

#### Scenario: Payment terms fields visible for GB scheme
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** all payment terms description fields (63–70) are visible in a Payment Terms group

#### Scenario: Suppliers Notified only editable when terms changed
- **WHEN** Payment Terms Have Changed = false
- **THEN** Suppliers Notified of Changes is not editable

#### Scenario: Suppliers Notified editable when terms changed
- **WHEN** Payment Terms Have Changed = true
- **THEN** Suppliers Notified of Changes is editable

### Requirement: Dispute resolution process field on Payment Practice Header
The `Payment Practice Header` table SHALL have a field `Dispute Resolution Process` (field 71, Text[2048]). This is a user-entered narrative field visible only when Reporting Scheme = Dispute & Retention.

#### Scenario: Dispute resolution field visible for GB scheme
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the Dispute Resolution Process field is visible in the Payment Policies group

### Requirement: Retention in standard payment terms field
The `Payment Practice Header` table SHALL have a field `Retention in Std Pmt. Terms` (field 72, Boolean). This tracks whether retention clauses are included in standard payment terms, visible only when Has Constr. Contract Retention = true.

#### Scenario: Retention in standard payment terms visible
- **WHEN** Has Constr. Contract Retention = true
- **THEN** the Retention in Std Pmt. Terms field is visible alongside other retention clause usage fields

### Requirement: Standard retention percentage gate field
The `Payment Practice Header` table SHALL have a field `Std Retention Pct Used` (field 73, Boolean). When false, `Standard Retention Pct` (field 47) SHALL not be editable. This is the gate boolean for whether a standard percentage rate is used in retention clauses.

#### Scenario: Standard retention percentage editable when gate is true
- **WHEN** Std Retention Pct Used = true
- **THEN** Standard Retention Pct is editable

#### Scenario: Standard retention percentage not editable when gate is false
- **WHEN** Std Retention Pct Used = false
- **THEN** Standard Retention Pct is not editable and is cleared to 0

### Requirement: Payment Practice Card shows Payment Terms group
The `Payment Practice Card` page SHALL show a "Payment Terms" group containing fields 63–70 only when Reporting Scheme = Dispute & Retention. The group appears between the Payment Statistics and Payment Policies groups.

#### Scenario: Payment Terms group layout
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the Payment Terms group shows: Shortest Standard Pmt. Period, Longest Standard Pmt. Period, Standard Payment Terms Desc., Payment Terms Have Changed, Suppliers Notified of Changes, Max Contractual Pmt. Period, Max Contractual Pmt. Period Info, Other Pmt. Terms Information

### Requirement: Payment Practice Card shows Dispute Resolution field
The `Payment Practice Card` page SHALL show the Dispute Resolution Process field in the Payment Policies group only when Reporting Scheme = Dispute & Retention.

#### Scenario: Dispute resolution in Payment Policies group
- **WHEN** a user views the Payment Policies group on a Dispute & Retention card
- **THEN** the Dispute Resolution Process field is visible after the Payment Code Name field
