# Payments

Part of [Shopify Connector](../../CLAUDE.md).

Manages Shopify Payments data including payment transactions, payouts, disputes, and payment terms for B2B orders.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Payment Transaction (30124) | Stores individual payment transaction records associated with payouts |
| Table | Shpfy Payout (30125) | Stores payout records from Shopify Payments with summary amounts |
| Table | Shpfy Dispute (30155) | Stores payment dispute records (chargebacks and inquiries) |
| Table | Shpfy Payment Terms (30158) | Stores payment terms from Shopify for B2B orders with mapping to BC payment terms |
| Codeunit | Shpfy Payments (30XXX) | Processes payment data from Shopify |
| Codeunit | Shpfy Payments API (30XXX) | GraphQL API calls for payment transactions and payouts |
| Codeunit | Shpfy Payment Terms API (30XXX) | GraphQL API calls for payment terms |
| Report | Shpfy Sync Payments | Synchronizes payment transactions and payouts from Shopify |
| Report | Shpfy Sync Disputes | Synchronizes dispute records from Shopify |
| Page | Shpfy Payment Transactions | List view of payment transactions |
| Page | Shpfy Payouts | List view of payouts |
| Page | Shpfy Disputes | List view of disputes |
| Page | Shpfy Payment Terms Mapping | Configure payment terms mappings |
| Enum | Shpfy Payment Trans. Type (30127) | Charge, Refund, Adjustment, and 100+ other transaction types |
| Enum | Shpfy Payout Status (30128) | Scheduled, In Transit, Paid, Failed, Canceled |
| Enum | Shpfy Dispute Type (30155) | Inquiry, Chargeback |
| Enum | Shpfy Dispute Reason | Reason codes for disputes |
| Enum | Shpfy Dispute Status | Status of dispute resolution |

## Key concepts

- Payment transactions are individual line items within payouts, showing fees and amounts
- Payouts aggregate multiple payment transactions into a single bank transfer
- Each payout includes breakdown of charges, refunds, adjustments, and fees
- Disputes track chargebacks and inquiries with deadlines for evidence submission
- Payment terms support Shopify B2B functionality, mapping to BC payment terms
- Payment Transaction Source Type and Source Id link back to orders or other entities
- Multiple currency support via Currency field on transactions and payouts
