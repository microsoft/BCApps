# Payments

Payout, payment transaction, and dispute management for Shopify Payments. This module handles the financial reconciliation layer -- payouts that Shopify deposits into the merchant's bank account, the individual transactions that compose each payout, and any chargebacks or disputes. It is separate from Transactions (which handles per-order payment transactions) because payouts and disputes operate at the shop level, days after orders are placed.

## How it works

The sync orchestrator is `ShpfyPayments.Codeunit.al`, which exposes two main flows: `SyncPayouts` and `SyncDisputes`. Payout sync runs four steps in sequence: (1) update `Payout Id` on payment transactions that were imported before their payout existed, (2) refresh statuses of pending/in-transit payouts, (3) import new payment transactions since the last known ID, and (4) import new payouts since the last known ID. Dispute sync similarly updates unfinished disputes (those not Won or Lost) and imports new ones.

The `Shpfy Payout` table (30125) is a financial summary record with breakdowns for charges, refunds, adjustments, reserved funds, and retried payouts -- each split into fee and gross amounts. Every payout has a status (Scheduled, InTransit, Paid, Failed, Canceled) and an `External Trace Id` for bank reconciliation. The `Shpfy Payment Transaction` table (30124) links each transaction to a payout via `Payout Id` and to the source order via `Source Order Id`. It carries amount, fee, and net amount, plus a `Source Order Transaction Id` for cross-referencing with the Transactions module.

The `Shpfy Dispute` table (30155) tracks chargebacks with type (Chargeback, Inquiry, etc.), reason, status, evidence deadlines, and amounts. The `ShpfyPaymentTerms` table and `ShpfyPaymentTermsAPI.Codeunit.al` handle payment terms mapping for B2B scenarios.

## Things to know

- Payout ID assignment is retroactive -- payment transactions are imported before their payout exists, then patched up in `UpdatePaymentTransactionPayoutIds`.
- Payment transaction updates are batched in groups of 200 IDs to avoid oversized API calls.
- Pending payout statuses are refreshed every sync to detect transitions from Scheduled to InTransit to Paid.
- The `Shpfy Payment Transaction` has a FlowField `Invoice No.` that looks up the posted sales invoice via the source order ID.
- Disputes are only updated while unfinalized (not Won/Lost) -- once a dispute reaches a terminal state, it is no longer polled.
- The module includes `ShpfySyncPayments.Report.al` and `ShpfySyncDisputes.Report.al` as entry points for scheduled sync.
