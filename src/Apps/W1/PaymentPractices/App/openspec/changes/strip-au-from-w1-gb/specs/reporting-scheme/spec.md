## MODIFIED Requirements

### Requirement: Reporting Scheme field on Payment Practice Header
The `Payment Practice Header` table SHALL have a field `Reporting Scheme` (field 15, Enum `Paym. Prac. Reporting Scheme`). The field SHALL be auto-detected on insert via `DetectReportingScheme()` and SHALL NOT be user-editable. On the `Payment Practice Card` page, the field SHALL be present with `Visible = false` and `Editable = false`.

#### Scenario: Auto-detection on insert for GB environment
- **WHEN** a new Payment Practice Header is inserted on a GB environment
- **THEN** the Reporting Scheme is set to `Dispute & Retention`

#### Scenario: Auto-detection on insert for AU/NZ environment
- **WHEN** a new Payment Practice Header is inserted on an AU or NZ environment
- **THEN** the Reporting Scheme is set to `Standard` (AU/NZ case removed — falls to default)

#### Scenario: Auto-detection on insert for W1/FR environment
- **WHEN** a new Payment Practice Header is inserted on any non-GB environment
- **THEN** the Reporting Scheme is set to `Standard`

#### Scenario: Reporting Scheme not visible on card
- **WHEN** a user opens the Payment Practice Card page
- **THEN** the Reporting Scheme field is not visible by default

#### Scenario: Reporting Scheme not editable
- **WHEN** a user personalizes the Payment Practice Card to show Reporting Scheme
- **THEN** the field is not editable
