# Transactions

Order-level payment transactions -- the individual authorization, capture, sale, void, and refund events on a Shopify order. This is where the gateway + credit card company composite key determines the BC payment method, and where the connector decides whether a Cust. Ledger Entry has consumed a transaction.

## How it works

`ShpfyTransactions.Codeunit.al` fetches all transactions for an order via `GetOrderTransactions` GraphQL and processes each one through `ExtractShopifyOrderTransaction`. For every transaction, it auto-creates lookup records in `Shpfy Transaction Gateway` and `Shpfy Credit Card Company` if they don't exist, and ensures a `Shpfy Payment Method Mapping` row is present for the (Shop Code, Gateway, Credit Card Company) triple. This means the mapping table grows organically as new gateways and card types appear in orders.

The `ShpfyOrderTransaction.Table.al` carries dual-currency amounts (`Amount` / `Currency` in shop money, `Presentment Amount` / `Presentment Currency` in buyer money) plus rounding amounts in both currencies. Parent-child relationships between transactions are tracked via `Parent Id` (a capture links to its auth, a refund links to its capture). The `Used` FlowField checks `Cust. Ledger Entry` for a matching `Shpfy Transaction Id`, and `Manual Payment Gateway` flags cash/bank transfer transactions.

## Things to know

- The payment method mapping key is the triple (Shop Code, Gateway, Credit Card Company) in `ShpfyPaymentMethodMapping.Table.al`. The `Payment Method` FlowField on the transaction resolves through this mapping.
- `ShpfySuggestPayments.Codeunit.al` transfers the `Shpfy Transaction Id` to Cust. Ledger Entry during journal posting, and clears it on reversal. This is how the `Used` FlowField works.
- The `Gift Card Id` field is extracted from `receiptJson` (not from the main GraphQL fields) in `ExtractShopifyOrderTransaction`, which is easy to miss if reading the code quickly.
- Credit card detail fields (`Credit Card Bin`, `AVS Result Code`, `CVV Result Code`) are `Access = Internal`, so they exist for data capture but are not exposed to extensions.
- The `Priority` field on the mapping table and the `Source Name` field on the transaction table have been removed (ObsoleteState = Removed, tag 28.0).
