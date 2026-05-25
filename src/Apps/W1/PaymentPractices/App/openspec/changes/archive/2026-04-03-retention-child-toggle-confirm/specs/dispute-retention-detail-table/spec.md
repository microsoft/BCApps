## MODIFIED Requirements

### Requirement: Detail table contains construction retention fields
The table SHALL have a gate field `Has Constr. Contract Retention` (Boolean). When true, the following sub-fields SHALL be available: `Ret. Clause Used in Contracts` (Boolean), `Retention in Std Pmt. Terms` (Boolean), `Retention in Specific Circs.` (Boolean), `Retention Circs. Desc.` (Text[250]), `Withholds Retent. from Subcon` (Boolean), `Contract Sum Threshold` (Decimal), `Std Retention Pct Used` (Boolean), `Standard Retention Pct` (Decimal), `Terms Fairness Practice` (Boolean), `Terms Fairness Desc.` (Text[250]), `Release Mechanism Desc.` (Text[250]), `Release Within Prescribed Days` (Boolean), `Prescribed Days Desc.` (Text[250]).

When a child boolean toggle that gates a text field is set to false, the system SHALL show a confirmation dialog before clearing the dependent text field. If the user declines, the toggle SHALL revert to true. The affected toggles and their dependent fields are:

| Toggle Field | Dependent Field Cleared |
|---|---|
| Retention in Specific Circs. | Retention Circs. Desc. → '' |
| Terms Fairness Practice | Terms Fairness Desc. → '' |
| Release Within Prescribed Days | Prescribed Days Desc. → '' |

#### Scenario: Retention Circs. Desc. cleared with confirmation
- **WHEN** Retention in Specific Circs. is set to false
- **AND** the user confirms the dialog
- **THEN** Retention Circs. Desc. is cleared

#### Scenario: Retention in Specific Circs. revert on cancel
- **WHEN** Retention in Specific Circs. is set to false
- **AND** the user declines the dialog
- **THEN** Retention in Specific Circs. remains true and Retention Circs. Desc. is unchanged

#### Scenario: Terms Fairness Desc. cleared with confirmation
- **WHEN** Terms Fairness Practice is set to false
- **AND** the user confirms the dialog
- **THEN** Terms Fairness Desc. is cleared

#### Scenario: Terms Fairness Practice revert on cancel
- **WHEN** Terms Fairness Practice is set to false
- **AND** the user declines the dialog
- **THEN** Terms Fairness Practice remains true and Terms Fairness Desc. is unchanged

#### Scenario: Prescribed Days Desc. cleared with confirmation
- **WHEN** Release Within Prescribed Days is set to false
- **AND** the user confirms the dialog
- **THEN** Prescribed Days Desc. is cleared

#### Scenario: Release Within Prescribed Days revert on cancel
- **WHEN** Release Within Prescribed Days is set to false
- **AND** the user declines the dialog
- **THEN** Release Within Prescribed Days remains true and Prescribed Days Desc. is unchanged

#### Scenario: No confirmation when dependent field is already empty
- **WHEN** Retention in Specific Circs. is set to false
- **AND** Retention Circs. Desc. is already empty
- **THEN** no confirmation dialog is shown and the toggle is set to false
