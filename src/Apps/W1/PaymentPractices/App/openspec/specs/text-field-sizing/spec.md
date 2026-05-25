## ADDED Requirements

### Requirement: Text fields are right-sized for their content domain
Each narrative text field in the `Paym. Prac. Dispute Ret. Data` table SHALL have a length appropriate to its real-world content domain, based on empirical analysis of 2,284 UK government payment practice reports.

#### Scenario: Large narrative fields at Text[2048]
- **WHEN** a developer inspects the table definition
- **THEN** `Standard Payment Terms Desc.` (field 65) SHALL be `Text[2048]`
- **AND** `Dispute Resolution Process` (field 71) SHALL be `Text[2048]`

#### Scenario: Medium narrative fields at Text[1024]
- **WHEN** a developer inspects the table definition
- **THEN** `Max Contr. Pmt. Period Info` (field 69) SHALL be `Text[1024]`
- **AND** `Other Pmt. Terms Information` (field 70) SHALL be `Text[1024]`

#### Scenario: Retention description fields at Text[1024]
- **WHEN** a developer inspects the table definition
- **THEN** `Retention Circs. Desc.` (field 43) SHALL be `Text[1024]`
- **AND** `Terms Fairness Desc.` (field 50) SHALL be `Text[1024]`
- **AND** `Release Mechanism Desc.` (field 51) SHALL be `Text[1024]`
- **AND** `Prescribed Days Desc.` (field 53) SHALL be `Text[1024]`
