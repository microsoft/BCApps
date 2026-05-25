## ADDED Requirements

### Requirement: Dispute & Retention detail card page exists
The system SHALL provide a page `Paym. Prac. Dispute Ret. Card` (P693) of type Card with SourceTable = `Paym. Prac. Dispute Ret. Data`. The page SHALL display all D&R qualitative fields organized in logical groups.

#### Scenario: Page opens for a D&R record
- **WHEN** a user opens P693 for Header No. = 1001
- **THEN** the page displays the D&R fields for that record

### Requirement: Page organized in FastTab groups
The page SHALL have the following groups: `Qualifying Contracts` (fields 60-62), `Payment Terms` (fields 63-70), `Construction Contract Retention` (fields 40-58 with gate on Has Constr. Contract Retention), `Dispute Resolution` (field 71), `Payment Policies` (fields 30-34).

#### Scenario: Construction retention details visible when gate is true
- **WHEN** Has Constr. Contract Retention = true
- **THEN** all retention sub-fields (41-58) are visible in the Construction Contract Retention group

#### Scenario: Construction retention details hidden when gate is false
- **WHEN** Has Constr. Contract Retention = false
- **THEN** retention sub-fields are not visible

#### Scenario: Conditional field editability
- **WHEN** Payment Terms Have Changed = false
- **THEN** Suppliers Notified of Changes is not editable
- **WHEN** Retention in Specific Circs. = false
- **THEN** Retention Circs. Desc. is not editable
- **WHEN** Std Retention Pct Used = false
- **THEN** Standard Retention Pct is not editable
- **WHEN** Terms Fairness Practice = false
- **THEN** Terms Fairness Desc. is not editable
- **WHEN** Release Within Prescribed Days = false
- **THEN** Prescribed Days Desc. is not editable

### Requirement: Copy from Previous action on the page
The page SHALL have an action `Copy from Previous Period` that invokes `CopyFromPrevious()` on the current record. Before copying, it SHALL show a confirmation dialog. After successful copy, the page SHALL update to reflect the copied values.

#### Scenario: User confirms copy from previous
- **WHEN** a user clicks "Copy from Previous Period" and confirms
- **THEN** standing-policy fields are populated from the most recent previous record and period-specific fields are cleared

#### Scenario: User cancels copy from previous
- **WHEN** a user clicks "Copy from Previous Period" and declines the confirmation
- **THEN** no changes are made

### Requirement: Clickable link on Payment Practice Card opens D&R page
The `Payment Practice Card` page (P687) SHALL display a non-editable text field with `Style = StandardAccent` and an `OnDrillDown` trigger that opens P693 for the current header's D&R record. The field and its containing group SHALL be visible only when Reporting Scheme = Dispute & Retention.

#### Scenario: Link visible for Dispute & Retention scheme
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** a clickable "Dispute & Retention Details" link is visible

#### Scenario: Link hidden for other schemes
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Standard
- **THEN** the "Dispute & Retention Details" link is not visible

#### Scenario: Clicking the link opens the D&R card
- **WHEN** a user clicks the "Dispute & Retention Details" link on header No. = 1001
- **THEN** P693 opens showing the D&R data for Header No. = 1001

### Requirement: D&R field groups removed from Payment Practice Card
The Payment Practice Card (P687) SHALL no longer contain the following field groups: `Qualifying Contracts`, `Payment Terms`, `Construction Contract Retention`, `Dispute Resolution`, `Payment Policies`. These groups are replaced by the link field.

#### Scenario: GB-specific groups no longer on main card
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the card does not show Qualifying Contracts, Payment Terms, Construction Contract Retention, Dispute Resolution, or Payment Policies groups directly; instead it shows the link to P693
