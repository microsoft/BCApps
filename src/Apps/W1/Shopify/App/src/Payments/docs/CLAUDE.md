# Payments

Shopify Payments account data -- payouts, payment transactions, disputes, and payment terms. This is about the money moving between Shopify and the merchant's bank, not order-level transactions (those live in `Transactions`).

## How it works

`ShpfyPayments.Codeunit.al` orchestrates the sync in a deliberate sequence: first backfill Payout Id on orphaned transactions, then update statuses of non-terminal payouts, then pull new transactions, and finally pull new payouts. This ordering matters because transactions arrive before the payout that groups them, so the backfill step patches up the relationship retroactively. Transactions and payouts are both fetched via cursor-based GraphQL pagination through `ShpfyPaymentsAPI.Codeunit.al`, with batched ID lookups capped at 200 records per call.

Disputes follow a similar pattern -- `SyncDisputes` first refreshes all non-terminal disputes (neither Won nor Lost), then imports new ones since the last known Id. Payment terms are a separate concern handled by `ShpfyPaymentTermsAPI.Codeunit.al`, which pulls payment terms templates from Shopify and maps them to BC Payment Terms codes via `ShpfyPaymentTerms.Table.al`.

## Things to know

- The Payout table (`ShpfyPayout.Table.al`) carries a detailed fee/gross breakdown across six categories: adjustments, charges, refunds, reserved funds, retried payouts, plus External Trace Id for bank reconciliation.
- Payment transactions link to payouts via `Payout Id` and to orders via `Source Order Id`. The `Invoice No.` FlowField resolves through Sales Invoice Header using the Shopify Order Id.
- Dispute records (`ShpfyDispute.Table.al`) are `Access = Internal` and reference the originating order via `Source Order Id` with a direct TableRelation to `Shpfy Order Header`.
- Payment terms enforce a single-primary constraint -- the `Is Primary` validation on `ShpfyPaymentTerms.Table.al` errors if another primary already exists.
- All enum conversions in the API codeunit fall back to `Unknown` when Shopify sends an unrecognized value, avoiding import failures from new upstream statuses.
