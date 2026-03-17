# Transactions

Order-level payment transactions imported from Shopify, plus a "Suggest Payments" report that generates cash receipt journal lines to reconcile them against BC invoices and credit memos.

## How it works

`ShpfyTransactions.Codeunit.al` pulls transaction data via the `GetOrderTransactions` GraphQL query for a given order. Each transaction is upserted into `ShpfyOrderTransaction.Table.al`, keyed by `Shopify Transaction Id`. During import, the codeunit auto-populates three side tables -- `ShpfyTransactionGateway`, `ShpfyCreditCardCompany`, and `ShpfyPaymentMethodMapping` -- by inserting any gateway or card company name it has not seen before. This means the payment method mapping table grows organically from real transaction data rather than being manually configured upfront.

The `ShpfySuggestPayments.Report.al` report iterates over successful Capture, Sale, and Refund transactions and matches them to open customer ledger entries. It respects the order's `Processed Currency Handling` to decide whether to use shop currency or presentment currency amounts. For captures/sales it applies against posted invoices; for refunds it applies against credit memos. Any leftover amount after application creates a balancing G/L account line. The `ShpfySuggestPayments.Codeunit.al` handles the event subscriber plumbing that stamps `Shpfy Transaction Id` onto `Cust. Ledger Entry` during posting, and clears it on reversal.

## Things to know

- The `Payment Method` field on `ShpfyOrderTransaction` is a FlowField that looks up `ShpfyPaymentMethodMapping` using a composite key of Shop + Gateway + Credit Card Company -- if the mapping row has no `Payment Method Code` filled in, the FlowField returns blank and the journal line gets no bal. account.
- Transactions carry both shop-currency and presentment-currency amounts, plus separate rounding fields for each. The Suggest Payments report picks the right pair based on how the order was originally processed.
- The `Used` FlowField checks `Cust. Ledger Entry` for a matching `Shpfy Transaction Id`, preventing duplicate journal creation unless `IgnorePostedTransactions` is explicitly set.
- Currency codes from Shopify are translated through `ImportOrder.TranslateCurrencyCode` after the initial RecordRef insert, because the translation cannot happen within the RecordRef flow.
- The `Gift Card Id` is parsed from the transaction's `receiptJson` field, not from the main GraphQL response body.
