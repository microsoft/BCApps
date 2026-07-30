# Order Return Refund Processing

The strategy layer that controls how Shopify returns and refunds are processed in Business Central. This module does not hold the return/refund data model (that lives in `Order Refunds` and `Order Returns`). It holds the processing strategies and the interfaces for document creation.

## How it works

The `IReturnRefund Process` interface (implemented via the extensible enum `Shpfy ReturnRefund ProcessType`) defines three operations: whether import is needed for a given source document type, whether a sales document can be created, and the actual document creation. The enum has three implementations.

- **Default** (`ShpfyRetRefProcDefault`) -- does nothing. Import is not needed, documents cannot be created. This is the "disabled" state.
- **Import Only** (`ShpfyRetRefProcImportOnly`) -- returns and refunds are imported from Shopify (so they appear in staging tables and reduce order line quantities), but no credit memos are auto-created.
- **Auto Create Credit Memo** (`ShpfyRetRefProcCrMemo`) -- imports data and auto-creates sales credit memos (or return orders, depending on `Shop."Process Returns As"`). It validates preconditions: the refund must not already be processed, the parent order must exist and must itself be processed. Before running creation it also skips refunds with pending Shopify refund transactions, because the final refunded amount is not settled yet. On success, `ShpfyCreateSalesDocRefund` builds the credit memo with lines from refund lines, return lines, refund shipping lines, and a balance line for any remaining amount.

The `IDocument Source` interface (implemented via `Shpfy Source Document Type` enum) provides error reporting back to the source record. The Refund implementation (`ShpfyIDocSourceRefund`) writes errors to the refund header. The extended interface `Shpfy Extended IDocument Source` adds call stack capture for deeper diagnostics.

Return-with-exchange is handled as refund-line data, not as a separate processing strategy. The refund import creates negative-quantity `Shpfy Refund Line` rows for `Return.exchangeLineItems`; `CreateSalesLinesFromRefundLines` then creates ordinary item sales lines from them. If an exchange refund line has no `Location Id`, the creator resolves the location from the linked exchange `Shpfy Order Line` before applying the default return location fallback. This keeps the credit memo total aligned with `Refund.totalRefundedSet` and avoids an artificial `Refund Account` balancing line for the exchange value.

*Updated: 2026-07-29 -- pending transaction skip and exchange-item refund line processing*

## Things to know

- This module is separate from `Order Refunds` and `Order Returns` which hold the data tables. This module holds only the processing strategies and the credit memo creation logic.
- Non-restocked items get posted to a different G/L account (`Refund Acc. non-restock Items`) than restocked items (which are returned as inventory items). Cancelled restock types go to the general `Refund Account`.
- The balance line (`CreateSalesLinesFromRemainingAmount`) catches any difference between the sum of the created sales lines and the total refund amount, posting it to `Refund Account`. This handles adjustments, rounding, and partial refunds that do not fully decompose into line items. Return-with-exchange should normally be covered by the negative-quantity exchange refund lines instead of this balance line. You can skip auto-balancing via the `OnBeforeCreateSalesLinesFromRemainingAmount` event.
- Pending refund transactions are a soft skip in auto-create. The record remains unprocessed so a later order/refund sync can retry after Shopify updates the transaction status.
- `ShpfyProcessOrders` triggers refund processing after order processing, but only when the shop's strategy is "Auto Create Credit Memo".
- Currency handling for refund documents respects `Processed Currency Handling` from the original order, not the current shop setting. This ensures consistency if the shop's currency handling changed between order creation and refund.
