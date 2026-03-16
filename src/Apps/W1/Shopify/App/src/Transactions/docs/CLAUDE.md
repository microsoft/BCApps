# Transactions

Part of [Shopify Connector](../../CLAUDE.md).

Manages Shopify order transactions and payment method mappings for processing customer payments.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Order Transaction (30133) | Stores transaction details from Shopify orders including payment gateway, status, amounts, and credit card info |
| Table | Shpfy Payment Method Mapping (30134) | Maps Shopify payment gateways and credit card companies to Business Central payment methods |
| Table | Shpfy Suggest Payment (30154) | Temporary table for suggesting payment journal entries based on transactions |
| Table | Shpfy Credit Card Company (30132) | Lookup table of credit card companies extracted from transactions |
| Table | Shpfy Transaction Gateway (30135) | Lookup table of payment gateways extracted from transactions |
| Codeunit | Shpfy Transactions (30194) | Retrieves and imports transaction data from Shopify GraphQL API |
| Codeunit | Shpfy Suggest Payments (30311) | Event subscriber for transferring transaction IDs to customer ledger entries |
| Report | Shpfy Suggest Payments | Generates payment journal suggestions from order transactions |
| Page | Shpfy Order Transactions | List view of order transactions |
| Page | Shpfy Payment Methods Mapping | Configure payment method mappings |
| Page | Shpfy Credit Card Companies | Lookup page for credit card companies |
| Page | Shpfy Transaction Gateways | Lookup page for transaction gateways |
| Enum | Shpfy Transaction Type (30134) | Authorization, Capture, Sale, Void, Refund |
| Enum | Shpfy Transaction Status (30133) | Pending, Failure, Success, Error, Awaiting Response, Unknown |

## Key concepts

- Order transactions represent individual payment activities (authorization, capture, refund) on Shopify orders
- Payment method mapping connects Shopify gateway and credit card company combinations to BC payment methods
- Transactions include both shop currency and presentment currency amounts for multi-currency support
- Gift card transactions are tracked via Gift Card Id field
- Transaction gateway and credit card company tables are auto-populated when importing transactions
- Suggest Payment functionality creates payment journal entries linked to specific transactions
- Customer ledger entries track which transaction was used via Shpfy Transaction Id field
