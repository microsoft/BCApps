## MODIFIED Requirements

### Requirement: CSV includes payment policy tick-boxes
The export SHALL include payment policy Boolean fields mapped to "Yes"/"No" strings: Participates in payment codes (from `Paym. Prac. Dispute Ret. Data`."Is Payment Code Member"), E-Invoicing offered (from `Paym. Prac. Dispute Ret. Data`."Offers E-Invoicing"), Supply-chain financing offered (from `Paym. Prac. Dispute Ret. Data`."Offers Supply Chain Finance"), Policy covers charges for remaining on supplier list (from `Paym. Prac. Dispute Ret. Data`."Policy Covers Deduct. Charges"), Charges have been made for remaining on supplier list (from `Paym. Prac. Dispute Ret. Data`."Has Deducted Charges in Period").

#### Scenario: Policy tick-boxes read from detail table
- **WHEN** a GB CSV export is generated and the D&R detail record has Offers E-Invoicing = true and Is Payment Code Member = false
- **THEN** the CSV contains "Yes" for "E-Invoicing offered" and "No" for "Participates in payment codes"

### Requirement: CSV includes construction retention data when applicable
When `Paym. Prac. Dispute Ret. Data`."Has Constr. Contract Retention" = true, the export SHALL include all retention-related columns mapped from the detail table: retention clause usage booleans (formatted as TRUE/FALSE), conditional narrative fields, threshold values, standard retention percentage, terms fairness fields, release mechanism fields, and retention statistics percentages.

#### Scenario: Retention section read from detail table when gate is true
- **WHEN** the D&R detail record has Has Constr. Contract Retention = true
- **THEN** the CSV includes all construction contract retention field values from the detail table

#### Scenario: Retention section excluded when gate is false
- **WHEN** the D&R detail record has Has Constr. Contract Retention = false
- **THEN** the CSV retention columns contain empty values

### Requirement: CSV includes payment terms and narrative fields
The export SHALL include the payment terms fields read from `Paym. Prac. Dispute Ret. Data`: Shortest/Longest standard payment period (integers), Standard payment terms (narrative), Payment terms have changed (TRUE/FALSE), Suppliers notified of changes (TRUE/FALSE), Maximum contractual payment period (integer), Maximum contractual payment period information (narrative), Other information payment terms (narrative), and Dispute resolution process (narrative).

#### Scenario: Narrative fields read from detail table
- **WHEN** a GB CSV export is generated
- **THEN** payment terms and dispute resolution narrative values are read from the D&R detail record, not from the Payment Practice Header

### Requirement: CSV includes qualifying contract gate booleans
The export SHALL include the qualifying contract gate fields read from `Paym. Prac. Dispute Ret. Data`: Qualifying contracts in reporting period, Payments made in reporting period, Qualifying construction contracts in reporting period — formatted as TRUE/FALSE.

#### Scenario: Qualifying contract gates read from detail table
- **WHEN** the D&R detail record has Qualifying Contracts in Period = true, Payments Made in Period = false
- **THEN** the CSV contains TRUE for "Qualifying contracts in reporting period" and FALSE for "Payments made in reporting period"

### Requirement: GB CSV export reads from detail table
The `Paym. Prac. GB CSV Export` codeunit (C684) SHALL read D&R qualitative fields from `Paym. Prac. Dispute Ret. Data` (T689) by performing a `Get` using the header's `No.` field. Payment statistics fields (20-23) SHALL continue to be read from the `Payment Practice Header`.

#### Scenario: Export reads both tables
- **WHEN** a GB CSV export is generated for header No. = 1001
- **THEN** C684 reads statistics (fields 20-23) from T687 and all qualitative D&R fields from T689 where Header No. = 1001
