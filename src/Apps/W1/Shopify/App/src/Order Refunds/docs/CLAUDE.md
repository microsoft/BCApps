# Order refunds

Imports refund data from Shopify -- headers, line items, and shipping line refunds. This module is purely a data model and import layer; the actual processing of refunds into BC credit memos lives in the Order Return Refund Processing module.

## How it works

`ShpfyRefundsAPI` imports refunds by ID. For each refund, it fetches the header (total refunded amount, note, associated return ID, dual-currency amounts), the refund lines (with quantities, restock types, and per-line amounts in both shop and presentment currencies), and refund shipping lines (shipping refund amounts). All amounts are stored in both the shop's base currency and the presentment currency.

Refund lines are linked back to order lines via `Order Line Id` and carry a `Restock Type` (NoRestock, Cancel, Return, LegacyRestock) that indicates what happened to the inventory. The `Can Create Credit Memo` flag is calculated based on whether the refund has a non-zero total or is linked to a return -- refunds that were already factored into order import (quantity reductions) cannot produce credit memos.

If the refund is associated with a return, the module collects return locations from the Returns API to populate the `Location Id` on refund lines, since Shopify does not always include location data directly on the refund.

Return-with-exchange needs a separate import path. Shopify puts the new exchange item on `Refund.return.exchangeLineItems`, not in `Refund.refundLineItems`. `ShpfyRefundsAPI` reads those exchange line items with `Refunds/GetRefundExchangeLines.graphql` and `Refunds/GetNextRefundExchangeLines.graphql`, then creates synthetic `Shpfy Refund Line` rows with a refund line id that is the negated order line id, negative quantity, negative subtotal and tax amounts, `Restock Type = Return`, and `"Is Exchange Item" = true`. Those rows let the credit memo offset the value of the exchange item without relying on the remaining-amount G/L balance line.

The matching order lines are flagged by order import from `Order.returns.exchangeLineItems` through `Orders/GetOrderExchangeLineItems.graphql`. That keeps exchange items out of the BC sales invoice while the synthetic refund lines put the inventory and refund total back in balance during credit memo creation.

The refund header stores `Shop Code` directly (populated from the communication manager's current shop during import), enabling shop-level filtering without joining through the order header. Currency codes (`Currency Code` and `Presentment Currency Code`) are also stored on the header and translated via `ImportOrder.TranslateCurrencyCode`. Error tracking fields (`Has Processing Error`, `Last Error Description`, `Last Error Call Stack`) support retry/debugging workflows. The `CheckCanCreateDocument` method prevents duplicate processing by checking whether a `Shpfy Doc. Link To Doc.` already exists for the refund.

*Updated: 2026-04-08 -- Shop Code, currency codes, error tracking, and CheckCanCreateDocument on refund header*

*Updated: 2026-07-29 -- return-with-exchange refund lines and pending transaction guard*

## Things to know

- A refund can exist without a return -- for example, an appeasement refund or a partial amount adjustment.
- The `Can Create Credit Memo` flag prevents double-processing: refunds that reduced order quantities during import are flagged as non-processable.
- The `Return Id` on the refund header links to the `Shpfy Return Header` if the refund was created from a return flow.
- Refund transactions are cross-updated -- `UpdateTransactions` stamps the `Refund Id` onto the corresponding `Shpfy Order Transaction` records.
- Credit memo creation is blocked while a linked refund transaction is still `Pending`. `HasPendingRefundTransactions` checks `Shpfy Order Transaction` by refund id, type `Refund`, and status `Pending`; manual creation raises an error, and auto-create exits without building the document.
- Refund lines reference order lines, not products directly -- item details come from FlowFields that look up the original order line.
- The Refund page has a Transactions action filtered by `Refund Id`; use it to see whether a refund is still pending before retrying credit memo creation.
- The `Note` field is stored as a BLOB to accommodate long refund notes.
