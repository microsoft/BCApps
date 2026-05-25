## MODIFIED Requirements

### Requirement: GB payment policy tick-box fields
The `Payment Practice Header` SHALL no longer contain user-entered Boolean fields for payment policies. These fields are moved to `Paym. Prac. Dispute Ret. Data` (T689): `Offers E-Invoicing` (30), `Offers Supply Chain Finance` (31), `Policy Covers Deduction Charges` (32), `Has Deducted Charges in Period` (33), `Is Payment Code Member` (34).

#### Scenario: Policy fields no longer on header
- **WHEN** a developer inspects Payment Practice Header (T687)
- **THEN** fields 30-34 do not exist on the table

#### Scenario: Policy fields available on detail table
- **WHEN** a developer inspects Paym. Prac. Dispute Ret. Data (T689)
- **THEN** the payment policy Boolean fields are present and editable

### Requirement: Construction contract retention fields
The `Payment Practice Header` SHALL no longer contain construction contract retention fields. All retention fields (40-58, 72-73) are moved to `Paym. Prac. Dispute Ret. Data` (T689), maintaining the same gate logic (`Has Constr. Contract Retention`) and `CalculateRetentionPercentages()` behavior.

#### Scenario: Retention fields no longer on header
- **WHEN** a developer inspects Payment Practice Header (T687)
- **THEN** fields 40-58 and 72-73 do not exist on the table

#### Scenario: Retention calculation on detail table
- **WHEN** a user changes Retent. Withheld from Suppls. on T689
- **THEN** CalculateRetentionPercentages() runs on T689 and updates Pct Retention vs Client Ret. and Pct Retent. vs Gross Payments

### Requirement: Payment Practice Card shows GB-specific groups
The `Payment Practice Card` page SHALL no longer show Payment Policies, Qualifying Contracts, Payment Terms, Construction Contract Retention, or Dispute Resolution groups. Instead, it SHALL show a clickable link to the `Paym. Prac. Dispute Ret. Card` page when Reporting Scheme = Dispute & Retention. The Payment Statistics group (fields 20-23) SHALL remain on the card.

#### Scenario: GB card layout with link
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the card shows a clickable link to D&R details instead of inline D&R field groups
- **AND** the Payment Statistics group (Total Number of Payments, Total Amount of Payments, Total Amt. of Overdue Payments, Pct Overdue Due to Dispute) remains visible on the card

#### Scenario: Non-GB card unaffected
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Standard
- **THEN** no D&R link is visible, and the card layout is unchanged

### Requirement: GB payment statistics on Payment Practice Header
The `Payment Practice Header` SHALL retain calculated fields (Editable = false): `Total Number of Payments` (field 20, Integer), `Total Amount of Payments` (field 21, Decimal), `Total Amt. of Overdue Payments` (field 22, Decimal), `Pct Overdue Due to Dispute` (field 23, Decimal). These remain populated by `CalculateHeaderTotals()` from Payment Practice Data. No change to field location or handler behavior.

#### Scenario: Payment statistics unchanged
- **WHEN** Generate() completes for a Dispute & Retention header
- **THEN** fields 20-23 are populated on the Payment Practice Header as before
