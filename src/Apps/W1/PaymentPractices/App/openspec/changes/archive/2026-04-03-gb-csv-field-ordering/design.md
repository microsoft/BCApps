## Context

The UK government's prompt-payment CSV download (`check-payment-practices.service.gov.uk`) defines a fixed 52-column schema. Our `Payment Practice Header` table (687) and `Payment Practice Card` page (687) were built incrementally across several OpenSpec changes — the current field/group order reflects implementation history, not the government schema order. This creates a cognitive gap when verifying CSV export mappings.

**Current page group order**: General → Statistics → Payment Statistics → Payment Terms → Payment Policies → Qualifying Contracts → Construction Contract Retention

**CSV column order implies**: General → Qualifying Contracts → Payment Statistics → Payment Terms → Construction Contract Retention → Dispute Resolution → Payment Policies

**Constraint**: Existing groups from the base branch (General, Statistics) SHALL NOT be moved. New groups are inserted after existing groups. The base branch has: General → Statistics → Lines.

## Goals / Non-Goals

**Goals:**

- Reorder field declarations in `Payment Practice Header` (Table 687) source code to follow CSV column order, grouped logically.
- Reorder page groups and fields on `Payment Practice Card` (Page 687) to match the same logical sequence.
- Within each group, match CSV column order but keep tightly-coupled fields adjacent (e.g. a Boolean gate and its dependent narrative field).
- Separate "Dispute Resolution Process" from "Payment Policies" — in the CSV it is column 46 (between retention and policies), not grouped with e-invoicing / supply-chain fields.
- Reorder Payment Policies fields so "Is Payment Code Member" appears first (CSV col 47), matching the government sequence.

**Non-Goals:**

- **No field-ID changes** — AL field IDs are permanent and used in upgrade codeunits; only source-code declaration order changes.
- **No functional/logic changes** — triggers, calculations, and export logic stay the same.
- **No new fields** — this change moves existing fields only.
- **No page personalization impact** — user-saved page personalizations reference field names, not positions, so reordering groups has no breaking effect.

## Decisions

### 1. Source-code order mirrors CSV column order (within groups)

**Decision**: Re-sequence field declarations in Table 687 and page groups/fields in Page 687 to follow the government CSV column sequence, with internal (non-CSV) fields placed at the beginning after identity fields.

**Rationale**: A developer should be able to read the table top-to-bottom and see the same order as the CSV header. This eliminates the need for a separate mapping document.

**Alternative considered**: Keep the current order and maintain a separate mapping table in the spec. Rejected because it duplicates information and will drift over time.

### 2. Merge "Statistics" and "Payment Statistics" into one group

**Decision**: Combine the current "Statistics" group (Average Agreed/Actual Payment Period, Pct Paid on Time) with the "Payment Statistics" group (Total Number/Amount of Payments, Overdue, Dispute %) into a single "Payment Statistics" group visible for all schemes. Standard-scheme-specific fields (Average Agreed/Actual, Pct Paid on Time) remain always visible; Dispute & Retention-only fields (totals, dispute %) are conditionally visible within the group.

**Rationale**: The CSV places "Average time to pay" (col 13) immediately before overdue/dispute stats (cols 20-22). Having two separate groups fragments this natural flow.

**Alternative considered**: Keep two groups but reorder them. Rejected because the fields belong to the same conceptual section (payment performance metrics).

### 3. "Dispute Resolution Process" moves out of "Payment Policies"

**Decision**: Move the Dispute Resolution Process field to a dedicated group (or the bottom of the Construction Contract Retention group) positioned between Retention and Payment Policies on the page.

**Rationale**: In the CSV, Dispute Resolution (col 46) sits between Retention (cols 31-45) and Payment Policies (cols 47-51). Grouping it with policies was a convenience that doesn't match the government schema's logical sectioning.

### 4. Table field declaration order

**Decision**: Reorder field declarations in following group sequence:

**Constraint**: Fields 1-12 are the original table fields and SHALL remain in their current declaration order (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12). Only fields 15+ are reordered.

| # | Group | Table Fields (by ID) | CSV cols |
|---|---|---|---|
| 1 | Original Fields (unchanged) | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 | 1, 4-5, 13, 20-22 |
| 2 | Reporting Config | 15, 16 | — |
| 3 | Qualifying Contracts & Stats | 20, 21, 22, 23 | 9-12, 20-22 |
| 4 | Payment Policies (tick-boxes) | 30, 31, 32, 33, 34 → reorder to 34, 30, 31, 32, 33 | 47-51 |
| 5 | Retention Gate + Clauses | 40, 41, 42, 43, 44, 45, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58 → reorder to 40, 41, 72, 42, 43, 44, 45, 73, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58 | 12, 31-45 |
| 6 | Qualifying Contracts | 60, 61, 62 → move before retention/policies | 9-11 |
| 7 | Payment Terms | 63, 64, 65, 66, 67, 68, 69, 70 | 23-30 |
| 8 | Dispute Resolution | 71 | 46 |
| 9 | Retention in Std Terms + Std Pct | 72, 73 → move into retention block | 32, 37 |

## Risks / Trade-offs

- **Code-review noise** — Reordering fields generates a large diff with no functional change. → Mitigation: Put this in a standalone commit with a clear commit message; reviewers verify via a diff of field-name lists rather than reading every moved block.
- **Merge conflicts** — Any parallel branch touching Table 687 or Page 687 will conflict. → Mitigation: Coordinate timing; merge this early or rebase affected branches.
- **Source-control blame** — `git blame` on every field line will show this commit. → Mitigation: Acceptable trade-off for long-term readability.
