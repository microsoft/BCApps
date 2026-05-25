## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Page organized in FastTab groups
The page SHALL have the following groups: `Qualifying Contracts` (fields 60-62), `Payment Terms` (fields 63-70), `Construction Contract Retention` (fields 40-58 with editability gate on Has Constr. Contract Retention), `Dispute Resolution` (field 71), `Payment Policies` (fields 30-34). Retention detail fields SHALL be placed directly in the Construction Contract Retention group without a nested sub-group.

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
