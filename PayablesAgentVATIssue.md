# Payables Agent - VAT Product Posting Group Not Applied Per Line

## Summary

The Payables Agent (Purchase Draft) correctly extracts VAT information from scanned invoices but fails to apply the correct VAT Product Posting Groups to individual purchase invoice lines. All lines default to "STANDARD" regardless of the actual VAT rate on the source invoice.

## Reproduction

**Invoice:** 164452 from Viking Direct Ltd (Vendor 10317), GBP
**Lines:**

| Description | G/L Account | Expected VAT |
|---|---|---|
| PK 4 KITCHEN ROLL WHITE 10... | 640300 | Standard (20%) |
| COFFEE ORIGINAL 750G TIN N... | 630800 | Zero-rated (0%) |
| PK1100 BLACK TEA 800337 PG... | 630800 | Zero-rated (0%) |
| PK12 UHT SEM SKIMMED MILK... | 630800 | Zero-rated (0%) |
| DIVIDER EXACOMPTA ECO 12 T... | 630100 | Standard (20%) |

**Totals:** Amount Excl. VAT = 110.55, Total VAT = 3.64, Amount Incl. VAT = 114.19

The total VAT of 3.64 on 110.55 net (~3.3%) proves a mix of zero-rated and standard-rated lines. UK VAT rules zero-rate most food items (coffee, tea, milk).

## Current Behavior

- The Purchase Draft accurately breaks down the invoice with correct net, VAT, and gross amounts per line and overall totals.
- When transferred into the Purchase Invoice, **all lines receive VAT Prod. Posting Group = "STANDARD"**.
- The VAT rate differences from the source invoice are lost.

## Expected Behavior

The agent should use the VAT rate information it already extracts from the scanned invoice to assign the **correct VAT Prod. Posting Group** per line (e.g., "ZERO" for zero-rated food items, "STANDARD" for taxable items).

## Impact

- Incorrect VAT amounts on posted invoices
- Wrong VAT reporting/returns
- Posted totals won't match the actual supplier invoice

## Internal Discussion

### Proposed Fix (Artur Ventsel)

We have the VAT rate from ADI (Azure Document Intelligence). When we create a purchase line, we only consider the item or G/L account — whatever VAT Product Posting Group comes as default from those tables ends up on the purchase line, which is exactly what the customer is reporting.

**Suggestion:** If we have the VAT rate from ADI, try to find the VAT Posting Setup for the vendor's VAT Business Posting Group and, if a matching setup exists, switch the VAT Product Posting Group on the line accordingly.

### Concerns (Joshua Martínez Pineda)

1. **Document totals validation exists** — the "Document totals" section should show the value as read from the invoice, and if totals don't match, posting is blocked. But we don't automatically change VAT Product Posting Groups to make lines add up to the correct VAT total.

2. **VAT data availability varies** — PDF invoices may have the VAT rate per line, per document, or both (see ADI docs). Even if we move away from ADI, this variability remains.

3. **Combinatorial complexity** — If only the document's total VAT is available and it doesn't match for N lines, the approach would require trying all combinations of VAT Product Posting Groups (N^K) to find one that adds up to the total. Multiple combinations could produce the same total but only one may be correct for reporting purposes.

4. **Historical decision** — Due to these complexities, the team previously decided not to guess and instead rely on document totals validation.

5. **Possible middle ground** — A warning that something is off with VAT early in the draft page would help. The fix could be scoped to cases where the tax amount is specified per line on the invoice, which is more deterministic. However, the ambiguity problem (concern #3) can still apply even with per-line amounts.

## Design Decision

Design spec: [2026-03-30-vat-posting-group-resolution-design.md](src/Apps/W1/EDocument/App/src/Processing/Import/docs/2026-03-30-vat-posting-group-resolution-design.md)

Key decisions:
1. **Normalize ADI handler** — compute VAT percentage from `tax / Sub Total * 100` instead of storing the raw tax amount
2. **New `[BC] VAT Prod. Posting Group` field** (field 110) on E-Document Purchase Line, resolved during Prepare Draft
3. **Lookup in Prepare Draft** — query VAT Posting Setup by vendor's VAT Bus. Posting Group + extracted VAT %. Single match → set. Zero/multiple → leave blank.
4. **Single-line fallback** — if no per-line VAT data but only one line, compute rate from header Total VAT
5. **Notification banner** — new "VAT Rate Mismatch" notification when resolution fails (line has VAT Rate but no match found)
6. **No combinatorial solving** — explicitly out of scope for multi-line invoices without per-line VAT data

## Notes

- Continia (competing product) handles this correctly — it can post by line item and apply a VAT posting group per item type.
- If only capturing balances and not items, zero-rated lines are missed entirely.
