## Requirements

### Requirement: GB CSV export produces government columnar format
The `Paym. Prac. GB CSV Export` codeunit (C684) SHALL produce a CSV file with a header row containing all government column names and a single data row with values, matching the UK government check-payment-practices.service.gov.uk download format.

#### Scenario: CSV file has correct header row
- **WHEN** a GB CSV export is generated
- **THEN** the first line of the CSV file contains exactly the government column names in order: "Report Id,Policy Regime,Financial period start date,Start date,End date,Filing date,Company,Company number,Qualifying contracts in reporting period,Payments made in reporting period,Qualifying construction contracts in reporting period,Construction contracts have retention clauses,Average time to pay,Total value invoices paid within 30 days,Total value invoices paid between 31 and 60 days,Total value invoices paid later than 60 days,% Invoices paid within 30 days,% Invoices paid between 31 and 60 days,% Invoices paid later than 60 days,Total value invoices paid later than agreed terms,% Invoices not paid within agreed terms,% Invoices not paid due to dispute,Shortest (or only) standard payment period,Longest standard payment period,Standard payment terms,Payment terms have changed,Suppliers notified of changes,Maximum contractual payment period,Maximum contractual payment period information,Other information payment terms,Retention clauses included in all construction contracts,Retention clauses included in standard payment terms,Retention clauses are used in specific circumstances,Description of specific circumstances for retention clauses,Retention clauses used above a specific sum,Value above which retention clauses are used,Retention clauses are at a standard rate,Retention clauses standard rate percentage,Retention clauses have parity with client,Description of parity policy,Retention clause money release description,Retention clause money release is staged,Description of stages for money release,Retention value compared to client retentions as %,Retention value compared to total payments as %,Dispute resolution process,Participates in payment codes,E-Invoicing offered,Supply-chain financing offered,Policy covers charges for remaining on supplier list,Charges have been made for remaining on supplier list,URL"

#### Scenario: CSV file has one data row
- **WHEN** a GB CSV export is generated for a single Payment Practice Header
- **THEN** the CSV file contains exactly two lines: the header row and one data row

### Requirement: CSV values are properly escaped per RFC 4180
The export SHALL wrap field values in double quotes when the value contains commas, double quotes, or newline characters. Double quotes within values SHALL be escaped by doubling them.

#### Scenario: Narrative field with commas
- **WHEN** the Standard Payment Terms Desc. contains "Payment terms are 30 days, net"
- **THEN** the CSV value is enclosed in double quotes: `"Payment terms are 30 days, net"`

#### Scenario: Narrative field with double quotes
- **WHEN** the Dispute Resolution Process contains: The supplier must provide a "valid" invoice
- **THEN** the CSV value has escaped quotes: `"The supplier must provide a ""valid"" invoice"`

#### Scenario: Narrative field with newlines
- **WHEN** the Standard Payment Terms Desc. contains a line break
- **THEN** the CSV value is enclosed in double quotes preserving the line break

### Requirement: Dates formatted as M/D/YYYY
The export SHALL format all date columns using M/D/YYYY format (no leading zeros on month or day).

#### Scenario: Start date formatting
- **WHEN** the Starting Date is April 29, 2017
- **THEN** the CSV Start date column contains `4/29/2017`

### Requirement: Boolean fields formatted as TRUE/FALSE
The export SHALL format Boolean fields as `TRUE` or `FALSE` (uppercase) for government-schema boolean columns (Qualifying contracts, Payments made, Qualifying construction contracts, Construction contracts have retention clauses, Payment terms have changed, Suppliers notified of changes, and all retention clause boolean columns).

#### Scenario: Boolean gate field is true
- **WHEN** Qualifying Contracts in Period = true
- **THEN** the CSV "Qualifying contracts in reporting period" column contains `TRUE`

#### Scenario: Boolean gate field is false
- **WHEN** Qualifying Contracts in Period = false
- **THEN** the CSV "Qualifying contracts in reporting period" column contains `FALSE`

### Requirement: Policy tick-box fields formatted as Yes/No
The export SHALL format payment policy Boolean fields as `Yes` or `No` for: Participates in payment codes, E-Invoicing offered, Supply-chain financing offered, Policy covers charges, Charges have been made.

#### Scenario: E-Invoicing offered is true
- **WHEN** Offers E-Invoicing = true
- **THEN** the CSV "E-Invoicing offered" column contains `Yes`

### Requirement: Company metadata sourced from Company Information
The export SHALL read Company Name from `Company Information.Name` and Company Number from `Company Information."Registration No."` at export time.

#### Scenario: Company info in CSV
- **WHEN** Company Information has Name = "ACME LIMITED" and Registration No. = "01234567"
- **THEN** the CSV Company column = "ACME LIMITED" and Company number column = "01234567"

### Requirement: Period percentages aggregated to 3 government columns
The export SHALL map Payment Practice Lines to 3 fixed percentage columns by aggregating based on Days From thresholds: lines with Days From 0–30 → "within 30 days", lines with Days From 31–60 → "between 31 and 60 days", lines with Days From > 60 → "later than 60 days" (sum of all such lines' Pct Paid in Period).

#### Scenario: Four-bucket periods mapped to three columns
- **WHEN** the Payment Practice Header has 4 period lines: (0-30, 77%), (31-60, 20%), (61-120, 2%), (121+, 1%)
- **THEN** the CSV contains: % Invoices paid within 30 days = 77, % between 31 and 60 = 20, % later than 60 = 3

#### Scenario: Three-bucket periods mapped directly
- **WHEN** the Payment Practice Header has 3 period lines: (0-30, 80%), (31-60, 15%), (61+, 5%)
- **THEN** the CSV contains: % Invoices paid within 30 days = 80, % between 31 and 60 = 15, % later than 60 = 5

### Requirement: Overdue percentage derived from Pct Paid on Time
The export SHALL calculate "% Invoices not paid within agreed terms" as `100 - "Pct Paid on Time"` from the Payment Practice Header.

#### Scenario: 89% paid on time
- **WHEN** the header has Pct Paid on Time = 11
- **THEN** the CSV "% Invoices not paid within agreed terms" column = 89

### Requirement: Policy Regime is constant
The export SHALL write "Regime-1" for the Policy Regime column.

#### Scenario: Policy Regime value
- **WHEN** a GB CSV export is generated
- **THEN** the CSV Policy Regime column contains "Regime-1"

### Requirement: Financial period start date is "None"
The export SHALL write "None" for the Financial period start date column.

#### Scenario: Financial period start date
- **WHEN** a GB CSV export is generated
- **THEN** the CSV "Financial period start date" column contains "None"

### Requirement: Retention fields blank when gate is false
When `Has Constr. Contract Retention` = false, the export SHALL write empty values for all retention-specific columns (columns 31–45 in the government schema).

#### Scenario: No construction contract retention
- **WHEN** Has Constr. Contract Retention = false
- **THEN** retention columns (31–45) are empty in the CSV output

### Requirement: Filing date defaults to Generated On date
The export SHALL use the date portion of `Generated On` as the Filing date column value. If Generated On is blank, the export SHALL use today's date.

#### Scenario: Filing date from Generated On
- **WHEN** Generated On = 11/7/2017 14:30
- **THEN** the CSV Filing date column = "11/7/2017"

### Requirement: URL column is blank
The export SHALL write an empty value for the URL column. The URL is assigned by the government portal after submission and is not known at export time.

#### Scenario: URL column is empty
- **WHEN** a GB CSV export is generated
- **THEN** the CSV URL column is empty
