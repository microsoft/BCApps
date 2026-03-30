# VAT Product Posting Group Auto-Resolution

**Date:** 2026-03-30
**Status:** Draft
**Author:** Artur Ventsel

## Problem

The Payables Agent (E-Document import pipeline) extracts VAT information from scanned invoices but does not apply the correct VAT Product Posting Group per purchase line. All lines default to the VAT Prod. Posting Group inherited from the G/L Account or Item card, regardless of the actual VAT rate on the source invoice.

This causes incorrect VAT amounts on posted invoices, wrong VAT reporting, and mismatched totals when an invoice contains lines with mixed VAT rates (e.g., standard 20% and zero-rated 0% items).

### Root Cause

1. **ADI handler stores wrong data type:** The ADI handler maps the `tax` field (a monetary amount per line, e.g., `$6.00`) into the `"VAT Rate"` field on `E-Document Purchase Line`. The PEPPOL and MLLM handlers correctly populate `"VAT Rate"` with a percentage. This inconsistency means downstream code cannot reliably interpret the field.

2. **No resolution logic exists:** The `"VAT Rate"` field is populated but never consumed. Neither the Prepare Draft nor Finish Draft stages use it to look up or override the VAT Product Posting Group.

## Design

### 1. ADI Handler Normalization

**File:** `EDocumentADIHandler.Codeunit.al` — `PopulateEDocumentPurchaseLine`

**Change:** Replace the current `tax` → `"VAT Rate"` mapping (which stores a monetary amount) with a computation that produces a percentage:

1. Read ADI's `tax` field into a local decimal variable (tax amount).
2. If the line has both a tax amount > 0 and `Sub Total` > 0, compute: `VAT Rate = (tax amount / Sub Total) * 100`.
3. If tax amount = 0, set `VAT Rate = 0` (zero-rated — valid and useful).
4. If `Sub Total` = 0, skip — leave `VAT Rate` as 0.

After this change, all three handlers (ADI, PEPPOL, MLLM) consistently populate `"VAT Rate"` as a percentage.

### 2. New Field on E-Document Purchase Line

**File:** `EDocumentPurchaseLine.Table.al`

Add a new field in the `[BC]` validated fields range (101-200):

- **Field 110:** `[BC] VAT Prod. Posting Group` (Code[20])

This follows the existing pattern where `[BC]`-prefixed fields hold BC-resolved values that the user can review and edit on the draft page.

### 3. Draft Subform Page Column

**File:** `EDocPurchaseDraftSubform.Page.al`

Add an editable column for `[BC] VAT Prod. Posting Group` with lookup support, positioned after the existing line type/number columns. The user can manually correct the posting group if auto-resolution fails or picks the wrong group.

### 4. VAT Posting Group Resolution in Prepare Draft

**File:** `PreparePurchaseEDocDraft.Codeunit.al` — `PrepareDraft`

After `IPurchaseLineProvider.GetPurchaseLine` resolves the line type/number (inside the existing line loop at lines 68-74), add VAT Posting Group resolution:

```
For each line:
  1. Get the vendor's VAT Bus. Posting Group.
  2. Determine the VAT rate to match:
     a. If line "VAT Rate" > 0 → use it directly.
     b. If line "VAT Rate" = 0 AND this is the only line
        AND header "Total VAT" > 0 AND header "Sub Total" > 0:
        → compute rate = (Total VAT / Sub Total) * 100.
     c. Otherwise → skip (no data to work with).
  3. Query VAT Posting Setup where:
     - VAT Bus. Posting Group = vendor's group
     - VAT % = determined rate (with rounding tolerance ~0.01)
  4. If exactly one match → set [BC] VAT Prod. Posting Group.
  5. If zero or multiple matches → leave blank (default applies at finalization).
```

**Rounding tolerance:** VAT rates computed from amounts may not be exact (e.g., `3.64 / 18.20 * 100 = 20.0` but edge cases exist). A tolerance of ~0.01 on the VAT % comparison avoids false mismatches.

### 5. Finish Draft — Apply Resolved Posting Group

**File:** `EDocCreatePurchaseInvoice.Codeunit.al` — `CreatePurchaseInvoiceLine`

After `PurchaseLine.Validate("No.", ...)` (line 216) sets the default VAT Prod. Posting Group from the G/L Account/Item, check if the draft line has a resolved value:

```al
if EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" <> '' then
    PurchaseLine.Validate("VAT Prod. Posting Group",
        EDocumentPurchaseLine."[BC] VAT Prod. Posting Group");
```

If the field is blank (resolution failed or user didn't set it), do nothing — the default from the G/L Account/Item applies (current behavior preserved).

### 6. Notification for Failed Resolution

**Files:** `EDocumentNotification.Codeunit.al`, `E-Document Notification Type` enum

**New notification type:** `"VAT Rate Mismatch"`

**Trigger:** After the Prepare Draft line loop completes, if any line has a non-zero `"VAT Rate"` but a blank `[BC] VAT Prod. Posting Group` (meaning lookup was attempted but found zero or multiple matches).

**Message:** "VAT Product Posting Groups could not be automatically determined for one or more lines. Please review before creating the invoice."

**Behavior:** Shown as a banner notification on the draft page, following the same pattern as the existing "Vendor matched by name but not by address" notification. Includes Dismiss and Don't show again actions.

## Explicitly Out of Scope

- **Combinatorial solving** — No attempt to find posting group combinations that make line VATs add up to the header total for multi-line invoices without per-line VAT data.
- **Blocking finalization** — VAT mismatch is informational, not a hard block. The existing document totals validation at posting time remains the enforcement mechanism.
- **ADI `taxRate` field** — The ADI invoice model may provide a `taxRate` string field. This design computes the rate from `tax / amount` instead, which works regardless of whether ADI provides `taxRate`. Adding direct `taxRate` extraction can be done as a follow-up.

## Key Files

| File | Role |
|---|---|
| `EDocumentADIHandler.Codeunit.al` | ADI data extraction — normalize tax amount to rate |
| `EDocumentPurchaseLine.Table.al` | Add `[BC] VAT Prod. Posting Group` field |
| `EDocPurchaseDraftSubform.Page.al` | Add editable column for new field |
| `PreparePurchaseEDocDraft.Codeunit.al` | VAT Posting Setup lookup logic |
| `EDocCreatePurchaseInvoice.Codeunit.al` | Apply resolved posting group to purchase line |
| `EDocumentNotification.Codeunit.al` | New VAT Rate Mismatch notification type |
| `E-Document Notification Type` enum | New enum value |
