## Why

The `Paym. Prac. Dispute Ret. Data` table uses `Text[2048]` for all four narrative text fields. Analysis of 2,284 real UK government reports shows two fields rarely exceed 1,000 characters (P99 = 611 and 1,009 respectively), making 2048 unnecessarily large. Reducing these avoids over-allocation while keeping the two fields that do reach 2,000+ chars at their current size.

## What Changes

- Reduce `"Max Contr. Pmt. Period Info"` (field 69) from `Text[2048]` to `Text[1024]` — real-world max is 802 chars, P99 = 611.
- Reduce `"Other Pmt. Terms Information"` (field 70) from `Text[2048]` to `Text[1024]` — real-world max is 1,680 chars, P99 = 1,009.
- Keep `"Standard Payment Terms Desc."` (field 65) at `Text[2048]` — real-world max is 3,021 chars.
- Keep `"Dispute Resolution Process"` (field 71) at `Text[2048]` — real-world max is 3,507 chars.
- Increase retention-related `Text[250]` fields to `Text[1024]` — these are new 2025 requirements with no historical data, but the guidance asks for potentially detailed narrative descriptions.

## Capabilities

### New Capabilities

- `text-field-sizing`: Right-size text field lengths in the dispute & retention data table based on empirical data analysis.

### Modified Capabilities

- `dispute-retention-detail-table`: Field length changes to the `Paym. Prac. Dispute Ret. Data` table definition.

## Impact

- **Table**: `Paym. Prac. Dispute Ret. Data` (table 689) — field type length changes.
- **Page**: `Paym. Prac. Dispute Ret. Card` (page 693) — no code changes needed, page binds to same fields.
- **CSV Export**: `Paym. Prac. GB CSV Export` (codeunit 684) — no code changes needed, reads the same fields.
- **CopyFromPrevious**: Same procedure, same field assignments — no code changes.
- **Breaking**: None. Only shrinking two fields (2048→1024) and growing six fields (250→1024). No external API surface affected.
