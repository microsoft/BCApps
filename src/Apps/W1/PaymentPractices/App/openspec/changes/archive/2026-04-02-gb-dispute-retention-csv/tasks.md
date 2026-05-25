## 1. New Header Fields (Data Model)

- [x] 1.1 Add qualifying contract gate fields (60–62) to Payment Practice Header table: `Qualifying Contracts in Period` (Boolean), `Payments Made in Period` (Boolean), `Qual. Constr. Contracts in Period` (Boolean)
- [x] 1.2 Add payment terms fields (63–70) to Payment Practice Header table: `Shortest Standard Pmt. Period` (Integer), `Longest Standard Pmt. Period` (Integer), `Standard Payment Terms Desc.` (Text[2048]), `Payment Terms Have Changed` (Boolean), `Suppliers Notified of Changes` (Boolean), `Max Contractual Pmt. Period` (Integer), `Max Contractual Pmt. Period Info` (Text[2048]), `Other Pmt. Terms Information` (Text[2048])
- [x] 1.3 Add dispute resolution field (71) to Payment Practice Header table: `Dispute Resolution Process` (Text[2048])
- [x] 1.4 Add retention supplementary fields (72–73) to Payment Practice Header table: `Retention in Std Pmt. Terms` (Boolean), `Std Retention Pct Used` (Boolean)
- [x] 1.5 Add OnValidate triggers: `Payment Terms Have Changed` clears `Suppliers Notified of Changes` when set to false; `Std Retention Pct Used` clears `Standard Retention Pct` when set to false

## 2. Payment Practice Card Page Updates

- [x] 2.1 Add "Qualifying Contracts" group (fields 60–62) to Payment Practice Card, visible only when Reporting Scheme = Dispute & Retention, positioned before Payment Statistics group
- [x] 2.2 Add "Payment Terms" group (fields 63–70) to Payment Practice Card, visible only when Reporting Scheme = Dispute & Retention, positioned between Payment Statistics and Payment Policies groups. Set `Suppliers Notified of Changes` Editable = `Rec."Payment Terms Have Changed"`
- [x] 2.3 Add `Dispute Resolution Process` field to Payment Policies group on Payment Practice Card
- [x] 2.4 Add `Retention in Std Pmt. Terms` field to Construction Contract Retention group (after `Ret. Clause Used in Contracts`)
- [x] 2.5 Add `Std Retention Pct Used` field to Construction Contract Retention group (before `Standard Retention Pct`). Set `Standard Retention Pct` Editable = `Rec."Std Retention Pct Used"`

## 3. Rewrite GB CSV Export Codeunit

- [x] 3.1 Add local helper `FormatBoolTrueFalse(Value: Boolean): Text` returning 'TRUE'/'FALSE'
- [x] 3.2 Add local helper `FormatDateGov(Value: Date): Text` returning M/D/YYYY format (no leading zeros)
- [x] 3.3 Add local helper `EscapeCSVField(Value: Text): Text` implementing RFC 4180 escaping (double-quote wrap when value contains comma, quote, or newline; double internal quotes)
- [x] 3.4 Rewrite `Export` procedure: write header row with all ~52 government column names in exact order
- [x] 3.5 Build data row: map header fields 1–12 (Report Id, Policy Regime = "Regime-1", Financial period start date = "None", Start/End date, Filing date from Generated On, Company/Company number from Company Information)
- [x] 3.6 Build data row: map qualifying contract gates (fields 60–62) and construction contract retention gate (field 40) as TRUE/FALSE
- [x] 3.7 Build data row: map payment statistics (Average time to pay, period value/percentage columns from Payment Practice Lines aggregated to 3 buckets, overdue totals, dispute percentage)
- [x] 3.8 Build data row: map payment terms fields (63–70) — integers as-is, narratives RFC 4180 escaped, booleans as TRUE/FALSE
- [x] 3.9 Build data row: map retention fields (41–58, 72–73) — booleans as TRUE/FALSE, decimals as-is, narratives escaped. Output empty values when Has Constr. Contract Retention = false
- [x] 3.10 Build data row: map payment policy tick-boxes (30–35) as Yes/No and Dispute Resolution Process (71) escaped. URL column = empty
- [x] 3.11 Join all column values with comma separator and write as second CSV line

## 4. Period Line Aggregation Logic

- [x] 4.1 Implement `GetPeriodPercentages` helper that reads Payment Practice Lines for a header and aggregates Pct Paid in Period into 3 government buckets: ≤30 days, 31–60 days, >60 days (using Days From threshold from Payment Period Line definitions)
- [x] 4.2 Implement corresponding aggregation for Pct Paid in Period (Amount) into 3 value columns (output blank if no amount data exists, matching government examples)

## 5. Tests

- [x] 5.1 Add test: CSV export produces correct header row with all 52 column names
- [x] 5.2 Add test: CSV data row has correct values for a fully populated Payment Practice Header (payment stats, policy tick-boxes, narrative fields, retention fields)
- [x] 5.3 Add test: period percentage aggregation from 4-bucket template to 3 CSV columns
- [x] 5.4 Add test: RFC 4180 escaping for narrative fields with commas, quotes, newlines
- [x] 5.5 Add test: retention columns blank when Has Constr. Contract Retention = false
- [x] 5.6 Add test: date formatting as M/D/YYYY
- [x] 5.7 Add test: new header fields visible/editable conditions on Payment Practice Card
