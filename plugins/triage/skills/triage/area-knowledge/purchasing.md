# Purchasing Domain Knowledge

## Procure-to-Pay Flow

- **Full flow**: Purchase Quote -> Purchase Order -> Warehouse Receipt -> Purchase Invoice -> Payment -> Vendor Ledger Entry -> G/L Entry
- **Status transitions**: Open -> Released -> Pending Prepayment -> Pending Approval. Only Released documents can be posted.
- **Posting options**: Receive only, Invoice only, or Receive and Invoice simultaneously. This flexibility is a frequent source of complexity.

## Partial Receiving and Invoicing

- **Qty. to Receive** and **Qty. to Invoice** on purchase lines control partial operations.
- Multiple receipts can be posted against a single order, each creating a **Purch. Rcpt. Header/Line** (T120/T121).
- **Get Receipt Lines** on a purchase invoice allows invoicing receipts from multiple orders in one invoice.
- Partial posting updates **Quantity Received** and **Quantity Invoiced** fields; the order remains open until fully invoiced.

## Prepayments

- Prepayment percentage is set on the order or line level, generating a prepayment invoice before shipment.
- The prepayment amount is posted to a **Prepayment G/L Account** and then reversed when the final invoice posts.
- **Rounding issues** are common when the prepayment percentage does not divide evenly across lines.

## Item Charges and Landed Cost

- **Item Charges** (T5800) distribute costs like freight, insurance, and customs duties across received items.
- Distribution methods: Equally, By Amount, By Weight, By Volume, or manual assignment.
- Item charges create **Value Entries** that adjust the item cost without creating item ledger entries.

## Purchase Prices and Discounts

- **Price Lists** (T7000+) are the modern mechanism — they support multiple price types, date ranges, and currency-specific prices.
- Legacy tables (T7012 Purchase Price, T7014 Purchase Line Discount) are still supported but deprecated.
- **Best Price** calculation selects the lowest unit cost from applicable price list lines.

## Key Tables

- **Purchase Header** (T38) — document header with Buy-from/Pay-to vendor, dates, currency, dimensions
- **Purchase Line** (T39) — line details with item/G-L/charge, quantities, amounts, dimensions
- **Purch. Rcpt. Header** (T120) / **Purch. Rcpt. Line** (T121) — posted receipt records
- **Purch. Inv. Header** (T122) / **Purch. Inv. Line** (T123) — posted invoice records
- **Purch. Cr. Memo Hdr.** (T124) / **Purch. Cr. Memo Line** (T125) — posted credit memos

## Common Issues

- Posting errors on partially received orders when dimensions or accounts change between receipt and invoice
- Prepayment rounding when lines have different prepayment percentages
- Vendor ledger entry application failures when applying payments across currencies
- Item charge assignment errors when the source receipt line has been fully invoiced
- Over-receipt tolerance configuration not being respected during warehouse receipt posting
