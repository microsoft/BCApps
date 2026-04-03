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

### Requirement: Detail table field declaration order follows CSV column sequence
The `Paym. Prac. Dispute Ret. Data` table (T689) SHALL declare fields in groups that follow the CSV column sequence:

1. **Payment Policies**: Is Payment Code Member (34) first, followed by Offers E-Invoicing (30), Offers Supply Chain Finance (31), Policy Covers Deduct. Charges (32), Has Deducted Charges in Period (33)
2. **Retention Gate & Clauses**: Has Constr. Contract Retention (40), Ret. Clause Used in Contracts (41), Retention in Specific Circs. (42), Retention Circs. Desc. (43), Withholds Retent. from Subcon (44), Contract Sum Threshold (45), Standard Retention Pct (47), Terms Fairness Practice (49), Terms Fairness Desc. (50), Release Mechanism Desc. (51), Release Within Prescribed Days (52), Prescribed Days Desc. (53), Retent. Withheld from Suppls. (54), Retention Withheld by Clients (55), Gross Payments Constr. Contr. (56), Pct Retention vs Client Ret. (57), Pct Retent. vs Gross Payments (58)
3. **Qualifying Contracts**: Qualifying Contracts in Period (60), Payments Made in Period (61), Qual. Constr. Contr. in Period (62)
4. **Payment Terms**: Shortest Standard Pmt. Period (63), Longest Standard Pmt. Period (64), Standard Payment Terms Desc. (65), Payment Terms Have Changed (66), Suppliers Notified of Changes (67), Max Contractual Pmt. Period (68), Max Contr. Pmt. Period Info (69), Other Pmt. Terms Information (70)
5. **Dispute Resolution**: Dispute Resolution Process (71)
6. **Retention in Std Terms Fields**: Retention in Std Pmt. Terms (72), Std Retention Pct Used (73)

Field IDs SHALL NOT change — only the order of declarations in the source file.

#### Scenario: Is Payment Code Member appears first in Payment Policies group
- **WHEN** a developer reads the detail table source code
- **THEN** Is Payment Code Member (field 34) is declared before fields 30-33 in the payment policies group

#### Scenario: Fields declared in CSV-aligned groups
- **WHEN** a developer reads the detail table source
- **THEN** field declarations appear grouped by CSV section as listed above
