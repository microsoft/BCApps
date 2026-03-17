# Payments

This module handles the import and tracking of Shopify Payments financial data: payment transactions (balance transactions from Shopify Payments), payouts (bank deposits), disputes (chargebacks), and payment terms mapping. It is a read-only sync from Shopify -- BC never creates or modifies payment data in Shopify, only imports it for reconciliation purposes.

## How it works

The sync is orchestrated by `ShpfyPayments.Codeunit.al`, which exposes two entry points: `SyncPayouts` and `SyncDisputes`. The `SyncPayouts` flow runs four steps in sequence: first, it finds any payment transactions with a zero `Payout Id` and queries Shopify to backfill those associations (batched in groups of 200 IDs per GraphQL call). Second, it checks payouts that are not yet in `Paid` or `Canceled` status and refreshes their status. Third, it imports new payment transactions since the last known ID. Fourth, it imports new payouts. The `SyncDisputes` flow first updates all disputes not in a terminal state (`Won` or `Lost`), then imports new disputes since the last known ID.

All API communication goes through `ShpfyPaymentsAPI.Codeunit.al`, which uses paginated GraphQL queries against the `shopifyPaymentsAccount` object. Payment transactions come from `balanceTransactions`, payouts from `payouts`, and disputes from `disputes`. The import pattern is the same for all three: records are inserted on first encounter, and only specific fields (status, payout ID) are updated on subsequent encounters. Raw JSON is captured to the `Shpfy Data Capture` table for every transaction and payout for audit purposes.

The data model has three core tables. `ShpfyPaymentTransaction.Table.al` stores individual balance transactions with amount/fee/net breakdowns, a `Source Order Id` linking to the Shopify order, and a `Payout Id` linking to the containing payout. It also has a computed `Invoice No.` FlowField that resolves the BC Sales Invoice for the linked order. `ShpfyPayout.Table.al` stores payout summaries with detailed fee/gross breakdowns for adjustments, charges, refunds, reserved funds, and retried payouts. `ShpfyDispute.Table.al` tracks chargebacks with reason, status, evidence deadlines, and order linkage. The `ShpfyPaymentTerms.Table.al` is a separate concern -- it maps Shopify payment term templates to BC Payment Terms codes for B2B company locations, synced via `ShpfyPaymentTermsAPI.Codeunit.al`.

## Things to know

- Payment transactions and payouts use a `SinceId` pattern (fetch everything with ID greater than the last known ID) rather than date-based filtering. This means the import is inherently incremental and idempotent.
- The payout ID backfill step exists because Shopify sometimes returns payment transactions before their associated payout exists. The code batches the lookup in groups of 200 IDs, joining them with ` OR ` into a GraphQL filter string.
- Payout amounts are net amounts (`net.amount`), not gross. The gross/fee breakdown is stored in separate fields for each transaction category (adjustments, charges, refunds, reserved funds, retried payouts).
- Disputes are linked to orders via `Source Order Id` but not directly to payment transactions. The dispute reason comes from Shopify's `reasonDetails.reason`, while the `Network Reason Code` is the card network's code.
- Enum conversion for status/type values uses `ConvertToCleanOptionValue` (from `Shpfy Communication Mgt.`) to normalize Shopify's SCREAMING_SNAKE_CASE into the enum name format, with an `Unknown` fallback for unrecognized values.
- The `Shpfy Sync Payments` report (`ShpfySyncPayments.Report.al`) and `Shpfy Sync Disputes` report are the user-facing entry points. They iterate over shops and call the codeunit methods. The payments report only syncs payouts, not disputes -- those have a separate report.
- Payment terms are a distinct concept from payment transactions. The `ShpfyPaymentTermsAPI.Codeunit.al` pulls payment term templates from Shopify and stores them locally with a BC `Payment Terms Code` mapping. Only one payment term can be marked `Is Primary`. These terms are used by the Companies module when exporting company locations.
