# Transactions

Tracks Shopify payment transactions and maps them to BC payment methods. Extends BC's Cust. Ledger Entry and Gen. Journal Line with a Shopify Transaction Id to enable end-to-end payment tracing from Shopify gateway through to BC ledger entries.

## How it works

`ShpfyTransactions` (30194) fetches transaction data via GraphQL and populates `Shpfy Order Transaction` (30133). Each transaction carries gateway, credit card company, amount in both shop and presentment currencies, and status. During import, new `Shpfy Transaction Gateway` and `Shpfy Credit Card Company` lookup records are auto-created, and a `Shpfy Payment Method Mapping` record is inserted for each unique (Shop, Gateway, Credit Card Company) combination. The mapping table links Shopify gateways to BC `Payment Method` codes.

`ShpfySuggestPayments` (30311) subscribes to posting events to transfer the `Shpfy Transaction Id` from `Gen. Journal Line` to `Cust. Ledger Entry` during posting, and clears it during reversal. The `Used` FlowField on the transaction table checks whether any Cust. Ledger Entry references the transaction, preventing double-application.

## Things to know

- The `Payment Method` field on `Shpfy Order Transaction` is a FlowField that looks up the mapping by (Shop, Gateway, Credit Card Company) -- if the mapping is not configured, the field is blank and the payment method won't appear on created sales documents.
- Transactions carry dual currency amounts: `Amount`/`Currency` (shop money) and `Presentment Amount`/`Presentment Currency`, plus separate rounding fields for each. The currency used depends on the Shop's `Currency Handling` setting.
- The `Shpfy Suggest Payments` report (30109) generates journal lines from unprocessed transactions, usable from the Cash Receipt Journal page extension.
- The `Refund Id` field on the transaction table links refund-type transactions back to the originating refund, enabling credit memo payment method resolution.
- Manual payment gateways (e.g., cash, check) are flagged via `Manual Payment Gateway` to distinguish them from automated payment processor transactions.
