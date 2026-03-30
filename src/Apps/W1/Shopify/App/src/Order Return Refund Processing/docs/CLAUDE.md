# Order Return Refund Processing

The strategy layer that controls how Shopify returns and refunds are processed in Business Central. This module does not hold the return/refund data model (that lives in `Order Refunds` and `Order Returns`). It holds the processing strategies and the interfaces for document creation.

## How it works

The `IReturnRefund Process` interface (implemented via the extensible enum `Shpfy ReturnRefund ProcessType`) defines three operations: whether import is needed for a given source document type, whether a sales document can be created, and the actual document creation. The enum has three implementations.

- **Default** (`ShpfyRetRefProcDefault`) -- does nothing. Import is not needed, documents cannot be created. This is the "disabled" state.
- **Import Only** (`ShpfyRetRefProcImportOnly`) -- returns and refunds are imported from Shopify (so they appear in staging tables and reduce order line quantities), but no credit memos are auto-created.
- **Auto Create Credit Memo** (`ShpfyRetRefProcCrMemo`) -- imports data and auto-creates sales credit memos (or return orders, depending on `Shop."Process Returns As"`). It validates preconditions: the refund must not already be processed, the parent order must exist and must itself be processed. On success, `ShpfyCreateSalesDocRefund` builds the credit memo with lines from refund lines, return lines, refund shipping lines, and a balance line for any remaining amount.

The `IDocument Source` interface (implemented via `Shpfy Source Document Type` enum) provides error reporting back to the source record. The Refund implementation (`ShpfyIDocSourceRefund`) writes errors to the refund header. The extended interface `Shpfy Extended IDocument Source` adds call stack capture for deeper diagnostics.

## Things to know

- This module is separate from `Order Refunds` and `Order Returns` which hold the data tables. This module holds only the processing strategies and the credit memo creation logic.
- Non-restocked items get posted to a different G/L account (`Refund Acc. non-restock Items`) than restocked items (which are returned as inventory items). Cancelled restock types go to the general `Refund Account`.
- The balance line (`CreateSalesLinesFromRemainingAmount`) catches any difference between the sum of the created sales lines and the total refund amount, posting it to `Refund Account`. This handles adjustments, rounding, and partial refunds that do not fully decompose into line items. You can skip this auto-balancing via the `OnBeforeCreateSalesLinesFromRemainingAmount` event.
- `ShpfyProcessOrders` triggers refund processing after order processing, but only when the shop's strategy is "Auto Create Credit Memo".
- Currency handling for refund documents respects `Processed Currency Handling` from the original order, not the current shop setting. This ensures consistency if the shop's currency handling changed between order creation and refund.
