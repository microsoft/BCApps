# Payments

Shopify Payments account data -- payouts, balance transactions, disputes, and payment terms. This is separate from order-level transactions (in the Transactions folder); this folder tracks the money flow through Shopify's own payment processing system.

## How it works

`ShpfyPayments.Codeunit.al` orchestrates sync in a specific order: first it backfills payout IDs on payment transactions that were imported before their payout existed, then it updates statuses of non-terminal payouts, then it imports new payment transactions and payouts. This ordering matters because payment transactions arrive before their associated payout is created by Shopify. Disputes follow a similar pattern -- unfinished disputes are refreshed individually, then new disputes are imported in bulk.

`ShpfyPaymentsAPI.Codeunit.al` handles all GraphQL communication. Payment transactions are imported via cursor-based pagination on `shopifyPaymentsAccount.balanceTransactions`. Each transaction records the gross amount, fee, and net amount. Payouts store a summary breakdown (charges, refunds, adjustments, reserved funds, retried payouts) with separate fee and gross amounts for each category. The `ShpfyPaymentTermsAPI.Codeunit.al` pulls payment terms templates from Shopify and upserts them into `ShpfyPaymentTerms` -- these are used by the Invoicing module to set payment terms on draft orders.

## Things to know

- Payment transaction IDs are imported with `SinceId + 1` to avoid re-importing the last known record -- this is a Shopify REST-era pattern carried forward into GraphQL filter parameters.
- Payout ID backfill and payout status updates are batched in groups of 200 to stay within GraphQL query limits.
- Disputes track `Evidence Due By`, `Evidence Sent On`, and `Finalized On` timestamps. Only disputes not yet Won or Lost are refreshed during sync.
- `ShpfyPaymentTerms` supports exactly one "Is Primary" row, enforced by a validation trigger. The primary term acts as a fallback when the invoice's BC payment terms code has no explicit Shopify mapping.
- `ShpfyPaymentTransaction` links to its source order via `Source Order Id` and can be traced to a posted sales invoice through a FlowField.
