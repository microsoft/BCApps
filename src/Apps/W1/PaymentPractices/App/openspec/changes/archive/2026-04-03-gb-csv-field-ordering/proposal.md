## Why

The field declaration order in `Payment Practice Header` (Table 687) and the group/field layout on `Payment Practice Card` (Page 687) do not follow the column order of the UK government CSV export format (`check-payment-practices.service.gov.uk`). This makes it hard to visually verify that every CSV column maps to the correct table field, increases the risk of mapping errors in the export codeunit, and forces developers to jump back and forth between unrelated sections when reading the code. Aligning the source-code field order and page group order with the CSV column sequence improves readability and auditability while keeping logically related fields together.

## What Changes

- Reorder field declarations in `Payment Practice Header` (Table 687) so they appear in groups that follow the CSV column sequence. Field IDs are **not** changed — only source-code order.
- Reorder groups and fields on `Payment Practice Card` (Page 687) to match the CSV-implied section order:
  1. **General** (identity & dates) — CSV cols 1-8
  2. **Qualifying Contracts** — CSV cols 9-12 (new group; placed after Payment Statistics)
  3. **Payment Statistics** — CSV cols 13-22 (merge current Statistics + Payment Statistics groups)
  4. **Payment Terms** — CSV cols 23-30 (stays roughly in place)
  5. **Construction Contract Retention** — CSV cols 31-45 (stays roughly in place)
  6. **Dispute Resolution** — CSV col 46 (currently inside Payment Policies; becomes its own group or moves to precede policies)
  7. **Payment Policies** — CSV cols 47-51 (moves to bottom; reorder internal fields so Is Payment Code Member comes first)
- Within each group, preserve the current sub-grouping of related fields (e.g. retention clause booleans stay together, retention statistics stay together). Only adjust inter-group ordering and small intra-group swaps where the CSV order differs.

## Capabilities

### New Capabilities

_(none — this is a layout refactor, not a new feature)_

### Modified Capabilities

- `gb-csv-export`: Update the field-mapping narrative to reference the new field groups and source-code ordering so future readers see a 1-to-1 walk-down from CSV column to table field.
- `dispute-retention-handler`: Update the Payment Practice Card layout requirements to reflect the new group order and the separation of Dispute Resolution from Payment Policies.

## Impact

- **Table 687 source**: Field declaration order changes (no schema / field-ID change, no data migration).
- **Page 687 source**: Group order and field order within groups change.
- **GB CSV Export codeunit (C684)**: No logic change needed — field IDs are unchanged. Spec narrative is updated only for documentation alignment.
- **Tests**: No functional change; existing tests remain valid.
