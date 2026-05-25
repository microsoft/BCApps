## ADDED Requirements

### Requirement: GB CSV export codeunit exists
The system SHALL provide a codeunit `Paym. Prac. GB CSV Export` (C684) that generates a CSV file per the UK government format for the Dispute & Retention reporting scheme.

#### Scenario: Export triggered from Payment Practice Card
- **WHEN** a user invokes the GB CSV export action on a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** a CSV file is generated and downloaded

#### Scenario: Export blocked for wrong scheme
- **WHEN** a user attempts the GB CSV export on a Payment Practice Card with Reporting Scheme = Standard
- **THEN** the action is not available or an error is raised

### Requirement: CSV includes payment statistics
The export SHALL include company name, company number, reporting period dates, average agreed payment period, average actual payment period, percentage paid on time, total number of payments, total amount of payments, total amount of overdue payments, and percentage overdue due to dispute.

#### Scenario: Payment statistics in CSV
- **WHEN** a GB CSV export is generated for a header with calculated payment statistics
- **THEN** the CSV contains all payment statistic values formatted as specified

### Requirement: CSV includes payment policy tick-boxes
The export SHALL include all 6 payment policy Boolean fields mapped to "Yes"/"No" strings and the Payment Code Name text field.

#### Scenario: Policy tick-boxes as Yes/No
- **WHEN** Offers E-Invoicing = true and Is Payment Code Member = false
- **THEN** the CSV contains "Yes" for Offers E-Invoicing and "No" for Is Payment Code Member

### Requirement: CSV includes construction retention data when applicable
When `Has Constr. Contract Retention = true`, the export SHALL include retention clause usage fields, contract sum threshold, standard retention percentage, terms fairness practice, release mechanism fields, and retention statistics (both user-entered amounts and auto-calculated percentages).

#### Scenario: Retention section included when gate is true
- **WHEN** Has Constr. Contract Retention = true
- **THEN** the CSV includes all construction contract retention fields

#### Scenario: Retention section excluded when gate is false
- **WHEN** Has Constr. Contract Retention = false
- **THEN** the CSV omits construction contract retention fields or includes empty/default values per the government schema

### Requirement: CSV includes period-aggregated payment data
The export SHALL include the payment period breakdown from Payment Practice Lines — percentage paid by number and by amount for each period bucket.

#### Scenario: Period data in CSV
- **WHEN** a GB CSV export is generated with 4 period lines
- **THEN** the CSV contains period bucket descriptions and their corresponding percentages
