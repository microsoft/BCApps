## ADDED Requirements

### Requirement: Dispute & Retention detail card page exists
The system SHALL provide a page `Paym. Prac. Dispute Ret. Card` (P693) of type Card with SourceTable = `Paym. Prac. Dispute Ret. Data`. The page SHALL display all D&R qualitative fields organized in logical groups.

#### Scenario: Page opens for a D&R record
- **WHEN** a user opens P693 for Header No. = 1001
- **THEN** the page displays the D&R fields for that record

### Requirement: Single-column grid layout on FastTab groups
Each FastTab group on P693 (except Dispute Resolution) SHALL wrap its fields inside a `grid > group` control with `ShowCaption = false` on the inner group, forcing single-column layout regardless of viewport width.

#### Scenario: Fields render in single column on wide viewport
- **WHEN** a user opens P693 on a wide viewport
- **THEN** all fields in Qualifying Contracts, Payment Terms, Construction Contract Retention, and Payment Policies groups render one field per row with full caption text visible

#### Scenario: Dispute Resolution group is not wrapped in grid
- **WHEN** a user opens P693
- **THEN** the Dispute Resolution group renders its single field without a grid wrapper

### Requirement: Confirmation and clearing when retention toggle is switched off
When `Has Constr. Contract Retention` is toggled from true to false, the system SHALL show a confirmation dialog warning that retention detail fields will be cleared. If the user confirms, all retention child fields (41-58) SHALL be reset to their default values. If the user declines, the toggle SHALL revert to true.

#### Scenario: User confirms clearing retention fields
- **WHEN** Has Constr. Contract Retention is changed from true to false
- **AND** the user confirms the dialog
- **THEN** all retention child fields (Ret. Clause Used in Contracts, Retention in Std Pmt. Terms, Retention in Specific Circs., Retention Circs. Desc., Withholds Retent. from Subcon, Contract Sum Threshold, Std Retention Pct Used, Standard Retention Pct, Terms Fairness Practice, Terms Fairness Desc., Release Mechanism Desc., Release Within Prescribed Days, Prescribed Days Desc., Retent. Withheld from Suppls., Retention Withheld by Clients, Gross Payments Constr. Contr., Pct Retention vs Client Ret., Pct Retent. vs Gross Payments) are cleared to default values

#### Scenario: User cancels clearing retention fields
- **WHEN** Has Constr. Contract Retention is changed from true to false
- **AND** the user declines the dialog
- **THEN** Has Constr. Contract Retention remains true and no fields are cleared

### Requirement: MultiLine on text fields
Text fields with length 250 or greater on P693 SHALL have `MultiLine = true` on the page field control to support paragraph-style content entry.

#### Scenario: Long text fields display as multiline
- **WHEN** a user opens P693
- **THEN** fields Standard Payment Terms Desc., Max Contr. Pmt. Period Info, Other Pmt. Terms Information, Dispute Resolution Process, Retention Circs. Desc., Terms Fairness Desc., Release Mechanism Desc., and Prescribed Days Desc. render as multiline text areas

### Requirement: Page organized in FastTab groups
The page SHALL have the following groups: `Qualifying Contracts` (fields 60-62), `Payment Terms` (fields 63-70), `Construction Contract Retention` (fields 40-58 with editability gate on Has Constr. Contract Retention), `Dispute Resolution` (field 71), `Payment Policies` (fields 30-34). Retention detail fields SHALL be placed directly in the Construction Contract Retention group without a nested sub-group. Each field control on the page SHALL have a human-readable `Caption` property that expands ambiguous abbreviations from the underlying table field names. The following caption mappings SHALL apply:

| Table Field Name | Page Caption |
|---|---|
| Qual. Constr. Contr. in Period | Qual. Construction Contracts in Period |
| Standard Payment Terms Desc. | Standard Payment Terms Description |
| Max Contr. Pmt. Period Info | Max Contractual Pmt. Period Info |
| Has Constr. Contract Retention | Has Construction Contract Retention |
| Ret. Clause Used in Contracts | Retention Clause Used in Contracts |
| Retention in Std Pmt. Terms | Retention in Standard Pmt. Terms |
| Retention in Specific Circs. | Retention in Specific Circumstances |
| Retention Circs. Desc. | Retention Circumstances Description |
| Withholds Retent. from Subcon | Withholds Retention from Subcontractors |
| Std Retention Pct Used | Standard Retention Pct. Used |
| Standard Retention Pct | Standard Retention % |
| Terms Fairness Desc. | Terms Fairness Description |
| Release Mechanism Desc. | Release Mechanism Description |
| Prescribed Days Desc. | Prescribed Days Description |
| Retent. Withheld from Suppls. | Retention Withheld from Suppliers |
| Gross Payments Constr. Contr. | Gross Construction Contract Payments |
| Pct Retention vs Client Ret. | % Retention vs Client Retention |
| Pct Retent. vs Gross Payments | % Retention vs Gross Payments |
| Policy Covers Deduct. Charges | Policy Covers Deduction Charges |

Fields with already-clear names (e.g., Qualifying Contracts in Period, Payment Terms Have Changed, Contract Sum Threshold) SHALL NOT receive a Caption override and SHALL continue inheriting the table field name.

#### Scenario: Page displays expanded captions for abbreviated fields
- **WHEN** a user opens P693 for any D&R record
- **THEN** each of the 19 abbreviated fields displays its expanded caption as specified in the mapping table above

#### Scenario: Clear field names retain original captions
- **WHEN** a user opens P693 for any D&R record
- **THEN** fields with unambiguous names (e.g., "Qualifying Contracts in Period", "Payments Made in Period", "Contract Sum Threshold") display their table field name as the caption without override

#### Scenario: Construction retention details editable when gate is true
- **WHEN** Has Constr. Contract Retention = true
- **THEN** all retention detail fields (41-58) are editable in the Construction Contract Retention group

#### Scenario: Construction retention details not editable when gate is false
- **WHEN** Has Constr. Contract Retention = false
- **THEN** all retention detail fields (41-58) are visible but not editable

#### Scenario: Conditional field editability
- **WHEN** Payment Terms Have Changed = false
- **THEN** Suppliers Notified of Changes is not editable
- **WHEN** Has Constr. Contract Retention = true AND Retention in Specific Circs. = false
- **THEN** Retention Circs. Desc. is not editable
- **WHEN** Has Constr. Contract Retention = true AND Std Retention Pct Used = false
- **THEN** Standard Retention Pct is not editable
- **WHEN** Has Constr. Contract Retention = true AND Terms Fairness Practice = false
- **THEN** Terms Fairness Desc. is not editable
- **WHEN** Has Constr. Contract Retention = true AND Release Within Prescribed Days = false
- **THEN** Prescribed Days Desc. is not editable
- **WHEN** Has Constr. Contract Retention = false
- **THEN** Retention Circs. Desc., Standard Retention Pct, Terms Fairness Desc., and Prescribed Days Desc. are not editable (parent gate overrides child toggles)

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
