# Transactions

Per-order payment transaction handling. This module imports and manages the individual payment transactions attached to Shopify orders -- authorizations, captures, refunds, voids -- and maps Shopify payment gateways to BC payment methods. It is separate from Payments (which deals with shop-level payouts) because transactions are order-scoped and drive the payment method on sales documents.

## How it works

`ShpfyTransactions.Codeunit.al` fetches transactions for an order via the `GetOrderTransactions` GraphQL query and upserts them into `Shpfy Order Transaction` (table 30133). Each transaction has a type (Sale, Authorization, Capture, Refund, Void, etc. from `ShpfyTransactionType.Enum.al`), a status, dual currency amounts (`Amount`/`Currency` for shop money, `Presentment Amount`/`Presentment Currency` for customer-facing), and a `Parent Id` for parent-child linking (e.g., a Capture is a child of an Authorization). The `Refund Id` field links refund-type transactions back to the Order Refunds module.

Payment method resolution works through the `Shpfy Payment Method Mapping` table (30134), keyed on (`Shop Code`, `Gateway`, `Credit Card Company`). When a new transaction is imported, `ExtractShopifyOrderTransaction` auto-creates entries in `Shpfy Transaction Gateway` and `Shpfy Credit Card Company` lookup tables, then ensures a mapping row exists. The `Payment Method` FlowField on `OrderTransaction` resolves through this mapping to a BC `Payment Method Code`. The `Manual Payment Gateway` flag distinguishes gateways like COD or bank transfer from automated processors.

The module also extends `Cust. Ledger Entry` and `Gen. Journal Line` with Shopify transaction fields, and provides `ShpfySuggestPayments.Codeunit.al` with its companion report for suggesting payment journal lines from Shopify transactions.

## Things to know

- Currency codes are translated via `ImportOrder.TranslateCurrencyCode` after insertion -- the raw Shopify codes may not match BC currency codes directly.
- The `Used` FlowField checks whether a `Cust. Ledger Entry` with the transaction ID exists, preventing double application.
- Transaction gateway and credit card company tables are auto-populated as new values appear -- they serve as lookup lists, not configuration.
- `DataCapture.Add` is called for every transaction to store the raw JSON snapshot for diagnostics.
- Rounding amounts (`Rounding Amount`, `Rounding Currency`, and presentment equivalents) are separate fields to handle Shopify's cash rounding on orders.
- The `Gift Card Id` is extracted from the transaction's `receiptJson`, not from the main transaction payload.
- The `ShpfyCashReceiptJournal.PageExt.al` adds Shopify columns to the Cash Receipt Journal for payment reconciliation.
