## MODIFIED Requirements

### Requirement: GB CSV export codeunit exists
The system SHALL provide a codeunit `Paym. Prac. GB CSV Export` (C684) that generates a CSV file in the **UK government flat columnar format** for the Dispute & Retention reporting scheme. The CSV SHALL contain a header row with all ~52 government column names followed by a single data row with mapped values.

#### Scenario: Export triggered from Payment Practice Card
- **WHEN** a user invokes the GB CSV export action on a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** a CSV file is generated in the government columnar format and downloaded

#### Scenario: Export blocked for wrong scheme
- **WHEN** a user attempts the GB CSV export on a Payment Practice Card with Reporting Scheme = Standard
- **THEN** the action is not available or an error is raised

### Requirement: CSV includes payment statistics
The export SHALL include: Report Id (from Header No.), company name and number (from Company Information), reporting period dates (from Starting/Ending Date formatted as M/D/YYYY), average time to pay (from Average Actual Payment Period), total value of overdue payments (from Total Amt. of Overdue Payments), percentage not paid within agreed terms (calculated as 100 - Pct Paid on Time), and percentage overdue due to dispute (from Pct Overdue Due to Dispute).

#### Scenario: Payment statistics in CSV
- **WHEN** a GB CSV export is generated for a header with Average Actual Payment Period = 25, Pct Paid on Time = 11, Total Amt. of Overdue Payments = 50000, Pct Overdue Due to Dispute = 5
- **THEN** the CSV row contains: Average time to pay = 25, % Invoices not paid within agreed terms = 89, Total value invoices paid later than agreed terms = 50000, % Invoices not paid due to dispute = 5

### Requirement: CSV includes payment policy tick-boxes
The export SHALL include payment policy Boolean fields mapped to "Yes"/"No" strings: Participates in payment codes (from Is Payment Code Member), E-Invoicing offered (from Offers E-Invoicing), Supply-chain financing offered (from Offers Supply Chain Finance), Policy covers charges for remaining on supplier list (from Policy Covers Deduct. Charges), Charges have been made for remaining on supplier list (from Has Deducted Charges in Period).

#### Scenario: Policy tick-boxes as Yes/No
- **WHEN** Offers E-Invoicing = true and Is Payment Code Member = false
- **THEN** the CSV contains "Yes" for "E-Invoicing offered" and "No" for "Participates in payment codes"

### Requirement: CSV includes construction retention data when applicable
When `Has Constr. Contract Retention = true`, the export SHALL include all retention-related columns mapped from header fields: retention clause usage booleans (formatted as TRUE/FALSE), conditional narrative fields, threshold values, standard retention percentage, terms fairness fields, release mechanism fields, and retention statistics percentages.

#### Scenario: Retention section included when gate is true
- **WHEN** Has Constr. Contract Retention = true
- **THEN** the CSV includes all construction contract retention field values in their corresponding government columns

#### Scenario: Retention section excluded when gate is false
- **WHEN** Has Constr. Contract Retention = false
- **THEN** the CSV retention columns contain empty values

### Requirement: CSV includes period-aggregated payment data
The export SHALL include period percentage data aggregated into 3 government columns: "% Invoices paid within 30 days" (from lines where Days From = 0..30), "% Invoices paid between 31 and 60 days" (from lines where Days From = 31..60), "% Invoices paid later than 60 days" (sum of all lines where Days From > 60).

#### Scenario: Period data in CSV from 4-bucket template
- **WHEN** a GB CSV export is generated with 4 period lines: (0-30, 34%), (31-60, 51%), (61-120, 10%), (121+, 5%)
- **THEN** the CSV contains: % within 30 days = 34, % between 31-60 = 51, % later than 60 = 15

### Requirement: CSV includes payment terms and narrative fields
The export SHALL include the new payment terms fields: Shortest/Longest standard payment period (integers), Standard payment terms (narrative), Payment terms have changed (TRUE/FALSE), Suppliers notified of changes (TRUE/FALSE), Maximum contractual payment period (integer), Maximum contractual payment period information (narrative), Other information payment terms (narrative), and Dispute resolution process (narrative).

#### Scenario: Narrative fields with special characters in CSV
- **WHEN** Standard Payment Terms Desc. contains commas and line breaks
- **THEN** the CSV value is RFC 4180 escaped (double-quote wrapped with internal quotes doubled)

### Requirement: CSV includes qualifying contract gate booleans
The export SHALL include the qualifying contract gate fields: Qualifying contracts in reporting period, Payments made in reporting period, Qualifying construction contracts in reporting period — formatted as TRUE/FALSE.

#### Scenario: Qualifying contract gates in CSV
- **WHEN** Qualifying Contracts in Period = true, Payments Made in Period = false
- **THEN** the CSV contains TRUE for "Qualifying contracts in reporting period" and FALSE for "Payments made in reporting period"
