# Transactions

Order-level payment transactions imported from Shopify, plus the "Suggest Payments" machinery that generates cash receipt journal lines.

`Shpfy Order Transaction` (`ShpfyOrderTransaction.Table.al`) is the core table -- one record per Shopify transaction, keyed by `Shopify Transaction Id`. It stores amount in both shop currency and presentment currency (including rounding amounts), the gateway name, credit card details (company, BIN, AVS/CVV codes), type (Authorization/Capture/Sale/Void/Refund), and status. FlowFields link to the sales document, posted invoice, and the mapped BC payment method.

`ShpfyTransactions.Codeunit.al` pulls transactions via GraphQL (`GetOrderTransactions`) and auto-populates three lookup tables as side effects: `Shpfy Transaction Gateway` (distinct gateway names), `Shpfy Credit Card Company` (distinct card brands), and `Shpfy Payment Method Mapping` (shop + gateway + card company -> BC payment method code). This auto-creation means new gateways appear in the mapping table with a blank payment method code, waiting for the user to assign one.

The `Suggest Payments` report (`ShpfySuggestPayments.Report.al`) is the bridge to BC's cash receipt journal. It iterates successful Capture/Sale/Refund transactions, matches them to open customer ledger entries via posted invoices or credit memos, and generates journal lines with the correct applies-to document. The temporary `Shpfy Suggest Payment` table accumulates matches before flushing to `Gen. Journal Line`. Rounding amounts are included in the applied amount. Gift card transactions get special description formatting.

Table extensions on `Cust. Ledger Entry` and `Gen. Journal Line` add a `Shpfy Transaction Id` field. The `ShpfySuggestPayments.Codeunit.al` event subscribers ensure this ID flows through posting and gets cleared on reversal -- this is how the `Used` FlowField on the transaction knows whether a journal line has already been posted for a given transaction.
