# Payments

Tracks Shopify payment transactions, payouts, disputes, and payment terms mappings. Syncs financial data from Shopify Payments into BC for reconciliation.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyPayments.Codeunit.al`, `Codeunits/ShpfyPaymentsAPI.Codeunit.al`
- **Key patterns**: Incremental sync using SinceId, batch processing (200 records per API call)

## Structure

- Codeunits (3): Payments (orchestration), PaymentsAPI (Shopify calls), PaymentTermsAPI
- Tables (4): PaymentTransaction, Payout, Dispute, PaymentTerms
- Enums (6): DisputeReason, DisputeStatus, DisputeType, PaymentTransSource, PaymentTransType, PayoutStatus
- Pages (4): Disputes, PaymentTermsMapping, PaymentTransactions, Payouts
- Reports (2): SyncDisputes, SyncPayments

## Key concepts

- `SyncPayouts` follows a four-step process: update payout IDs on existing transactions, update pending payout statuses, import new transactions, then import new payouts
- `SyncDisputes` first updates unfinished disputes (not Won/Lost), then imports new disputes
- Payment transactions link to sales invoices via FlowField on Source Order Id
- Payment terms are mapped per shop and can designate a primary mapping as fallback
- All sync operations are incremental -- they track the last imported ID and only fetch newer records
