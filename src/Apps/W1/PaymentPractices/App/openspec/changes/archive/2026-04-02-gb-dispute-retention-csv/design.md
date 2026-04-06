## Context

The UK government's check-payment-practices.service.gov.uk portal uses a flat columnar CSV format with ~52 columns per row for Prompt Payment Practices reporting. The current `Paym. Prac. GB CSV Export` codeunit (C684) writes a simple key-value format that does not match this schema. Additionally, several government-required fields are absent from the `Payment Practice Header` data model — narrative text fields (Standard Payment Terms, Dispute Resolution Process, etc.), qualifying-contract gate booleans, and payment terms change-tracking fields.

The current header table has fields 1–58. Fields 40–58 cover construction contract retention and are already implemented. Fields 30–34 cover payment policy tick-boxes. Fields 20–23 cover GB payment statistics. All of these map to government CSV columns but many government columns have no corresponding source yet.

**Removed fields** (not required for government CSV export):
- Field 35 `Payment Code Name` — government CSV only requires a Yes/No for payment code membership (field 34), not the code name.
- Field 46 `Contract Sum Threshold Pct` — no corresponding government CSV column.
- Field 48 `Half Retention Pct` — no corresponding government CSV column.

The government CSV uses **3 fixed period buckets** for the percentage columns (≤30 days, 31–60 days, >60 days), while the GB period template has **4 buckets** (0-30, 31-60, 61-120, 121+). The export must aggregate the last two buckets into one ">60 days" column.

## Goals / Non-Goals

**Goals:**
- Produce a CSV file byte-compatible with the UK government download format (same column order, same column names, same TRUE/FALSE boolean formatting, same date formatting)
- Add all missing header fields needed for government compliance
- Map every existing Dispute & Retention field to its corresponding government CSV column
- Source company metadata (name, registration number) from the Company Information table at export time

**Non-Goals:**
- Uploading to the government portal (manual user process)
- Auto-populating narrative fields from ledger entries (user-entered)
- Changing the data generation flow or period aggregation logic
- Supporting other CSV schemas (AU export is separate)
- Renaming existing fields for better alignment with government column names (too disruptive; mapping done at export time)

## Decisions

### D1: Flat columnar format with header row

The export writes a single header row with all ~52 column names, then one data row per Payment Practice Header. This matches the government download format exactly. Each column value is double-quote-wrapped when it contains commas, newlines, or double quotes (RFC 4180 CSV escaping).

**Alternative considered:** Keep key-value format — rejected because it doesn't match the government schema and requires manual reformatting.

### D2: New header fields numbered 60–75

New fields use the 60–75 range to avoid conflicts with existing 40–58 retention fields:

| Field # | Name | Type | Purpose |
|---------|------|------|---------|
| 60 | Qualifying Contracts in Period | Boolean | Gate: qualifying contracts exist |
| 61 | Payments Made in Period | Boolean | Gate: payments were made |
| 62 | Qual. Constr. Contracts in Period | Boolean | Gate: qualifying construction contracts exist |
| 63 | Shortest Standard Pmt. Period | Integer | Days (e.g., 30) |
| 64 | Longest Standard Pmt. Period | Integer | Days (e.g., 60). Blank when same as shortest |
| 65 | Standard Payment Terms Desc. | Text[2048] | Narrative describing standard terms |
| 66 | Payment Terms Have Changed | Boolean | Changed since last reporting period |
| 67 | Suppliers Notified of Changes | Boolean | Suppliers notified of changes. Editable only when 66=true |
| 68 | Max Contractual Pmt. Period | Integer | Days (e.g., 230) |
| 69 | Max Contractual Pmt. Period Info | Text[2048] | Narrative explaining max period |
| 70 | Other Pmt. Terms Information | Text[2048] | Freeform narrative |
| 71 | Dispute Resolution Process | Text[2048] | Narrative describing dispute handling |
| 72 | Retention in Std Pmt. Terms | Boolean | Retention clauses in standard payment terms (government column 32) |
| 73 | Std Retention Pct Used | Boolean | Gate for field 47 "Standard Retention Pct" (government column 37) |

Text[2048] is chosen for narrative fields because government entries frequently exceed 250 characters (the current limit for fields 43, 50, 51, 53).

**Alternative considered:** Reusing field numbers in gaps (e.g., between 35-40) — rejected to keep logical grouping clear and avoid future conflicts.

### D3: Period-to-CSV-column mapping

The government CSV has 3 fixed period columns. The export aggregates from Payment Practice Lines filtered by the header:

| Government Column | Source Lines (by Days From/To range) |
|---|---|
| "% Invoices paid within 30 days" | Line where Days From = 0, Days To = 30 |
| "% Invoices paid between 31 and 60 days" | Line where Days From = 31, Days To = 60 |
| "% Invoices paid later than 60 days" | Sum of all lines where Days From > 60 |

Same logic applies for "Total value" columns (using `Pct Paid in Period (Amount)` fields, when populated, or leaving blank like the government data).

This avoids depending on specific template codes or line ordering — it works regardless of which period template the user selected.

### D4: Company metadata sourced at export time

Company name and registration number are read from `Company Information` (BaseApp table 79) during export. No new fields on the header — this avoids data duplication and keeps company info always current.

### D5: Boolean formatting as TRUE/FALSE

The government CSV uses `TRUE`/`FALSE` (uppercase) for several boolean columns and `Yes`/`No` for others. The export maps each column to the correct format per the government schema. The existing `FormatBoolean` helper is extended with a parameter for format type.

### D6: Date formatting as M/D/YYYY

Government CSV dates use `M/D/YYYY` format (e.g., `4/29/2017`). The export formats all date columns accordingly, ignoring the user's local date format settings.

## Risks / Trade-offs

- **Narrative field length**: Text[2048] may still be insufficient for some entries (government examples show multi-paragraph narratives). → Mitigation: 2048 covers >99% of government examples; users can truncate if needed.
- **Period aggregation assumes standard GB buckets**: If a user selects a non-standard period template with different bucket boundaries, the "later than 60 days" column may not sum correctly. → Mitigation: The mapping logic uses Days From > 60 as the threshold, which works for any template. Lines that straddle the 60-day boundary will be assigned based on their Days From value.
- **Existing retention field names don't match government column names**: e.g., `"Withholds Retent. from Subcon"` maps to "Retention clauses used above a specific sum", `"Terms Fairness Practice"` maps to "Retention clauses have parity with client". → Mitigation: The column-name mapping is done purely in the export codeunit. No field renaming needed.
- **New narrative fields on existing Text[250] pages**: Fields like `Retention Circs. Desc.` (field 43) are Text[250] but government data suggests they need to be longer. → Non-goal for this change (would be a separate modification to widen existing fields).
