## Why

The current GB CSV export (`Paym. Prac. GB CSV Export`, C684) writes a simple key-value format, but the UK government's check-payment-practices.service.gov.uk portal uses a **flat columnar CSV** with ~50 columns per row. The export must match this exact schema so that companies can upload or reconcile data against the government format. Additionally, several government-required fields are missing from the data model — narrative fields (Standard Payment Terms, Dispute Resolution Process, Maximum Contractual Payment Period Information), company metadata, and qualifying-contract gate booleans.

## What Changes

- **Rewrite the GB CSV export** to produce the exact government columnar CSV format with a header row and one data row per report, matching all ~50 column names from the UK government download schema.
- **Add missing header fields** to `Payment Practice Header` (table 687): narrative text fields (Standard Payment Terms, Dispute Resolution Process, Max Contractual Payment Period Info, Other Information Payment Terms), qualifying-contract gate booleans (Qualifying Contracts, Payments Made, Qualifying Construction Contracts), payment terms change tracking (Payment Terms Have Changed, Suppliers Notified of Changes), Shortest/Longest Standard Payment Period (Integer), and Maximum Contractual Payment Period (Integer).
- **Map existing fields** (payment statistics, policy tick-boxes, retention fields) to their exact government CSV column names.
- **Source company metadata** (Company Name, Company Registration No.) from the Company Information table at export time — no new fields on the header.
- **Add period-level value columns** to the export: the government CSV includes "Total value invoices paid within 30 days / 31-60 / later than 60 days" which must come from Payment Practice Line amount aggregations.

## Capabilities

### New Capabilities
- `gb-gov-csv-format`: Rewrite of C684 to produce the exact UK government flat-columnar CSV format with all ~50 columns, header row, and proper value formatting (TRUE/FALSE for booleans, comma-escaped text fields, date formatting).

### Modified Capabilities
- `dispute-retention-handler`: Add missing narrative and gate fields to the Payment Practice Header data model (fields 60–75+) and expose them on the Payment Practice Card page for user entry before export.
- `gb-csv-export`: Replace existing requirements with the full government-format column mapping, including period-level value breakdowns and company metadata sourcing.

## Impact

- **Payment Practice Header table (687)**: ~12 new fields (narrative texts, gate booleans, integer periods).
- **Payment Practice Card page**: New "Payment Terms" and "Dispute Resolution" groups visible for Dispute & Retention scheme.
- **Paym. Prac. GB CSV Export codeunit (684)**: Full rewrite of the `Export` procedure.
- **Payment Practice Line / Period Aggregator**: May need to expose per-period amount totals (existing `Pct Paid in Period (Amount)` values may suffice, or absolute amounts may be needed).
- **Company Information table**: Read-only dependency for company name and registration number at export time.
