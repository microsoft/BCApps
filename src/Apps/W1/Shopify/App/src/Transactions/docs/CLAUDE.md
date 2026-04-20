# Transactions

Tracks individual payment transactions on Shopify orders -- captures, authorizations, refunds, and voids. Maps Shopify payment gateways and credit card companies to BC payment methods, and bridges transaction data into BC Customer Ledger Entries.

## How it works

`ShpfyTransactions.UpdateTransactionInfos` fetches all transactions for a given order via the `GetOrderTransactions` GraphQL query and upserts them into the `Shpfy Order Transaction` table. Each transaction record captures the type (Sale, Authorization, Capture, Void, Refund), status, gateway name, credit card details, dual-currency amounts (shop money and presentment money), and rounding amounts. The gateway and credit card company are auto-registered in their respective lookup tables (`Shpfy Transaction Gateway`, `Shpfy Credit Card Company`), and a `Shpfy Payment Method Mapping` entry is auto-created keyed on shop + gateway + credit card company.

The `Shpfy Suggest Payments` codeunit hooks into BC's general journal posting to stamp Shopify Transaction IDs onto Customer Ledger Entries. This creates a traceable link from Shopify payment captures to BC accounting entries. The `Used` FlowField on the transaction table checks whether a CLE with that transaction ID exists. On journal reversal, the transaction ID is cleared from both the original and reversal entries.

The `Shpfy Payment Method Mapping` table is the central configuration point -- users map each gateway + credit card company combination to a BC Payment Method Code, which controls how the order is processed in the cash receipt journal.

## Things to know

- The `Shop` field (108) is a direct Code[20] field with TableRelation to `Shpfy Shop`, populated via an upgrade DataTransfer from the order header's `Shop Code`. This replaces the old `Shop Code` FlowField (103), which is now obsoleted (CLEAN28/CLEANSCHEMA31). The `Payment Method` FlowField uses the `Shop` field for its lookup key.
- The `Shpfy Order No.` FlowField (109) provides a quick lookup to the Shopify order number from the order header.
- The `Parent Id` field on `Shpfy Order Transaction` links refund transactions back to their original charge, enabling refund-to-charge tracing.
- Payment method mapping is keyed on shop + gateway + credit card company -- the same gateway can map to different BC payment methods depending on the card brand.
- The `Gift Card Id` is extracted from the transaction's receipt JSON, not from a direct GraphQL field.
- Transaction amounts include both shop money and presentment money, plus separate rounding amounts for each currency.
- The `Manual Payment Gateway` boolean distinguishes manual payment methods (like COD or bank transfer) from automated gateways.
- FlowFields on the transaction table provide quick lookups to Sales Document No., Posted Invoice No., and Shopify Order No. for the related order.

*Updated: 2026-04-08 -- New Shop field (direct, via DataTransfer upgrade) replaces obsoleted Shop Code FlowField; Shpfy Order No. FlowField added*
