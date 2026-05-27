# Payments

Handles Shopify Payments data -- payouts (bulk settlement transfers to the merchant's bank), payment transactions (individual movements within those payouts), B2B payment terms mapping, and chargeback disputes.

## How it works

`ShpfyPayments` coordinates two sync flows: payouts and disputes. Payout sync runs in four steps: update payout IDs on orphaned payment transactions, refresh pending payout statuses, import new payment transactions (from `shopifyPaymentsAccount.balanceTransactions`), and import new payouts. This incremental approach uses `SinceId` to avoid re-fetching old records, and processes transactions in batches of 200 when updating payout associations.

Disputes are synced similarly -- unfinished disputes (not Won/Lost) are polled for status updates, then new disputes are imported. Each dispute links to its source order and carries reason codes, evidence deadlines, and finalization dates.

The `Shpfy Payment Terms` table maps Shopify payment terms templates (NET, FIXED, etc.) to BC Payment Terms Codes. These are used by the Invoicing module when creating draft orders with B2B payment schedules. One payment term can be marked as primary to serve as a fallback.

## Things to know

- Payouts represent the actual bank transfers from Shopify. Payment transactions are the individual charges, refunds, and adjustments that compose a payout.
- Payout import captures detailed summaries: charges fee/gross, refunds fee/gross, reserved funds, retried payouts, and adjustments.
- Disputes track status (NeedsResponse, UnderReview, Won, Lost, etc.), type (chargeback, inquiry), and reason (Fraudulent, Unrecognized, etc.) with their own enum types.
- Payment term IDs in `Shpfy Payment Terms` correspond to Shopify's `PaymentTermsTemplate` GIDs -- these are used when constructing draft order mutations.
- Only one payment term can be marked as primary per shop.
