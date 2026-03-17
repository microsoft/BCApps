# Payments

Shopify Payments account data -- payouts, balance transactions, disputes, and payment terms mapping. This is distinct from the `Transactions/` folder, which handles order-level transactions.

The `Shpfy Payments` codeunit (`ShpfyPayments.Codeunit.al`) orchestrates two sync flows. `SyncPayouts` first backfills payout IDs on orphaned payment transactions, updates pending payout statuses, then imports new transactions and payouts (all via `ShpfyPaymentsAPI`). `SyncDisputes` updates unfinished disputes, then imports new ones. Both are triggered by the reports `Shpfy Sync Payments` and `Shpfy Sync Disputes`.

`Shpfy Payment Transaction` (`ShpfyPaymentTransaction.Table.al`) represents a Shopify Payments balance transaction -- the line items that roll up into a payout. Each record has Amount, Fee, and Net Amount, plus links to the source order and payout. The `Shpfy Payment Trans. Type` enum is enormous (100+ values covering charges, refunds, chargebacks, adjustments, shipping labels, collective transactions, etc.) -- many older values are kept only for backward compatibility.

`Shpfy Payout` (`ShpfyPayout.Table.al`) is the actual bank transfer. It carries a detailed summary breakdown: adjustments, charges, refunds, reserved funds, and retried payouts, each split into fee and gross amounts. Status lifecycle is Scheduled -> In Transit -> Paid (or Failed/Canceled).

`Shpfy Dispute` (`ShpfyDispute.Table.al`) tracks chargebacks and inquiries. It has type (Inquiry/Chargeback), reason (13 values from Fraudulent to Subscription Cancelled), status (Needs Response -> Under Review -> Won/Lost), evidence deadlines, and a link back to the source order.

`Shpfy Payment Terms` (`ShpfyPaymentTerms.Table.al`) maps Shopify payment terms templates to BC payment terms codes. `ShpfyPaymentTermsAPI` pulls them via GraphQL. Only one can be marked `Is Primary`. The table stores name, due-in-days, description, and type from Shopify alongside the user-assigned BC `Payment Terms Code`.
