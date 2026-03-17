# Order return refund processing

This module handles returns and refunds as separate but related concepts. A return tracks the physical flow of goods back from the customer. A refund tracks the monetary flow back to the customer. They can occur independently -- a refund without a return (e.g., a price adjustment), a return without a refund (e.g., an exchange), or together.

## How it works

The shop's "Return and Refund Process" setting, defined by the `ShpfyReturnRefundProcessType` enum, controls all behavior through the `ShpfyIReturnRefundProcess` interface. Three implementations exist: `ShpfyRetRefProcDefault` (the blank option -- skips all import and processing), `ShpfyRetRefProcImportOnly` (imports return and refund data but creates no BC documents), and `ShpfyRetRefProcCrMemo` (imports data and auto-creates credit memos from refunds).

When "Auto Create Credit Memo" is active, `ShpfyProcessOrders` iterates unprocessed refund headers after order processing and calls `CreateSalesDocument` for each. `ShpfyRetRefProcCrMemo` validates preconditions -- the refund must not already be processed, the parent order must exist and be processed, and no refund lines can have `Can Create Credit Memo` = false. It then delegates to `ShpfyCreateSalesDocRefund`, which builds a credit memo from the order header's address and customer data.

Sales lines on the credit memo are created differently based on the refund line's restock type. Return and Legacy Restock lines become Item lines at the refund location. No Restock lines become G/L account lines against "Refund Acc. non-restock Items". Cancel lines go to the "Refund Account" as a flat amount. After item lines, shipping refund lines and a balancing G/L line for any remaining amount difference are added to ensure the credit memo total matches the Shopify refund total.

## Things to know

- The `ShpfySourceDocumentType` enum distinguishes Order, Return, and Refund as source document types. Each has its own `ShpfyIDocumentSource` implementation for error tracking.
- Restock type (`NoRestock`, `Cancel`, `Return`, `LegacyRestock`) determines how credit memo lines are created. Only Return and Legacy Restock create Item-type lines that affect BC inventory.
- If a refund has no refund lines but has a linked return with return lines, the credit memo is built from return lines instead (see `CreateSalesLinesFromReturnLines` in `ShpfyCreateSalesDocRefund`).
- The balancing line in `CreateSalesLinesFromRemainingAmount` catches rounding differences, refund adjustments, and any amounts not covered by the line-level refund data. It posts to the shop's "Refund Account" G/L.
- Credit memos use the order's `Processed Currency Handling` rather than the shop's current setting, so currency handling remains consistent even if the shop setting changes after the order was originally processed.
- Refund quantities are also netted against order lines during import (in `ShpfyImportOrder.ConsiderRefundsInQuantityAndAmounts`), so the order and refund processing are tightly coupled.
- Integration events on `ShpfyRefundProcessEvents` allow customizing header creation, line creation, and the balancing calculation.
