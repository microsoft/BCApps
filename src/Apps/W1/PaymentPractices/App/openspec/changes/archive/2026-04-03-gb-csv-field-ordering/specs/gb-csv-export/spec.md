## MODIFIED Requirements

### Requirement: CSV includes payment statistics
The export SHALL include payment statistics fields in the following CSV-column order: Average time to pay (from Average Actual Payment Period), period-aggregated value and percentage columns (from Payment Practice Lines), Total value invoices paid later than agreed terms (from Total Amt. of Overdue Payments), percentage not paid within agreed terms (calculated as 100 − Pct Paid on Time), and percentage overdue due to dispute (from Pct Overdue Due to Dispute). The source table fields for this group SHALL be declared in the same order: fields 6, 7, 8 (averages and Pct Paid on Time), followed by fields 20-23 (totals and dispute percentage).

#### Scenario: Payment statistics appear in CSV column order
- **WHEN** a GB CSV export is generated for a header with Average Actual Payment Period = 25, Pct Paid on Time = 11, Total Amt. of Overdue Payments = 50000, Pct Overdue Due to Dispute = 5
- **THEN** the CSV row contains these values in columns 13, 20, 21, 22 respectively: Average time to pay = 25, Total value invoices paid later than agreed terms = 50000, % Invoices not paid within agreed terms = 89, % Invoices not paid due to dispute = 5

### Requirement: CSV includes payment policy tick-boxes
The export SHALL include payment policy Boolean fields in CSV-column order (columns 47-51): Participates in payment codes (from Is Payment Code Member), E-Invoicing offered (from Offers E-Invoicing), Supply-chain financing offered (from Offers Supply Chain Finance), Policy covers charges for remaining on supplier list (from Policy Covers Deduct. Charges), Charges have been made for remaining on supplier list (from Has Deducted Charges in Period). The source table fields for this group SHALL be declared with Is Payment Code Member (field 34) first, followed by fields 30-33.

#### Scenario: Policy tick-boxes follow CSV column order
- **WHEN** Is Payment Code Member = false, Offers E-Invoicing = true, Offers Supply Chain Finance = false, Policy Covers Deduct. Charges = false, Has Deducted Charges in Period = false
- **THEN** the CSV contains in columns 47-51: "No", "Yes", "No", "No", "No"

### Requirement: CSV includes qualifying contract gate booleans
The export SHALL include the qualifying contract gate fields in CSV-column order (columns 9-12): Qualifying contracts in reporting period (from Qualifying Contracts in Period), Payments made in reporting period (from Payments Made in Period), Qualifying construction contracts in reporting period (from Qual. Constr. Contr. in Period), Construction contracts have retention clauses (from Has Constr. Contract Retention). The source table fields for this group SHALL be declared together: fields 60, 61, 62, then field 40.

#### Scenario: Qualifying contract gates follow CSV column order
- **WHEN** Qualifying Contracts in Period = true, Payments Made in Period = false, Qual. Constr. Contr. in Period = false, Has Constr. Contract Retention = false
- **THEN** the CSV columns 9-12 contain: TRUE, FALSE, FALSE, FALSE

### Requirement: CSV includes payment terms and narrative fields
The export SHALL include the payment terms fields in CSV-column order (columns 23-30): Shortest (or only) standard payment period (from Shortest Standard Pmt. Period), Longest standard payment period (from Longest Standard Pmt. Period), Standard payment terms (from Standard Payment Terms Desc.), Payment terms have changed (from Payment Terms Have Changed), Suppliers notified of changes (from Suppliers Notified of Changes), Maximum contractual payment period (from Max Contractual Pmt. Period), Maximum contractual payment period information (from Max Contr. Pmt. Period Info), Other information payment terms (from Other Pmt. Terms Information). The source table fields for this group SHALL be declared in the same order (fields 63-70).

#### Scenario: Payment terms fields follow CSV column order
- **WHEN** Shortest Standard Pmt. Period = 30, Longest Standard Pmt. Period = 60, Payment Terms Have Changed = false
- **THEN** the CSV columns 23-27 contain: 30, 60, (narrative), FALSE, (empty since changed=false)

### Requirement: CSV includes construction retention data when applicable
When `Has Constr. Contract Retention = true`, the export SHALL include retention columns in CSV-column order (columns 31-45): Retention clauses included in all construction contracts (from Ret. Clause Used in Contracts), Retention clauses included in standard payment terms (from Retention in Std Pmt. Terms), Retention clauses are used in specific circumstances (from Retention in Specific Circs.), Description of specific circumstances (from Retention Circs. Desc.), Retention clauses used above a specific sum (from Withholds Retent. from Subcon), Value above which retention clauses are used (from Contract Sum Threshold), Retention clauses are at a standard rate (from Std Retention Pct Used), Retention clauses standard rate percentage (from Standard Retention Pct), Retention clauses have parity with client (from Terms Fairness Practice), Description of parity policy (from Terms Fairness Desc.), Retention clause money release description (from Release Mechanism Desc.), Retention clause money release is staged (from Release Within Prescribed Days), Description of stages for money release (from Prescribed Days Desc.), Retention value compared to client retentions as % (from Pct Retention vs Client Ret.), Retention value compared to total payments as % (from Pct Retent. vs Gross Payments). The source table fields for this group SHALL be declared in the same CSV-column order: fields 41, 72, 42, 43, 44, 45, 73, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58.

#### Scenario: Retention fields follow CSV column order
- **WHEN** Has Constr. Contract Retention = true, Ret. Clause Used in Contracts = false, Retention in Std Pmt. Terms = false, Retention in Specific Circs. = false
- **THEN** the CSV columns 31-33 contain: FALSE, FALSE, FALSE

### Requirement: Dispute Resolution Process is a separate CSV section
The export SHALL place Dispute resolution process (from Dispute Resolution Process, field 71) at CSV column 46, between the retention block (cols 31-45) and the payment policy block (cols 47-51). The source table field SHALL be declared after retention fields and before payment policy fields.

#### Scenario: Dispute resolution follows retention in CSV
- **WHEN** Dispute Resolution Process = "Disputes are resolved by negotiation"
- **THEN** the CSV column 46 contains "Disputes are resolved by negotiation", positioned after retention columns and before payment policy columns
