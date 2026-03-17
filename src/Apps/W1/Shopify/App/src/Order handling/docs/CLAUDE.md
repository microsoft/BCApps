# Order handling

This module imports Shopify orders via GraphQL and converts them into BC Sales Orders or Sales Invoices. It is the most complex business domain in the connector -- an import touches header parsing, paginated line retrieval, fulfillment orders, tax lines, shipping charges, transactions, returns, refunds, customer/company mapping, and conflict detection, all before a BC document is created.

## How it works

The entry point is `ShpfySyncOrdersfromShopify.Report.al`, which calls `ShpfyOrdersAPI` to retrieve a lightweight list of candidate orders into the `Shpfy Orders to Import` staging table (30121). Each row in that staging table is then processed by `ShpfyImportOrder.Codeunit.al`, which fetches the full order via GraphQL, populates the `Shpfy Order Header` (30118) and `Shpfy Order Line` (30119) records, and pulls in related data -- tax lines, shipping charges, fulfillment orders, transactions, returns, and refunds. When an already-processed order is re-imported, `IsImportedOrderConflictingExistingOrder` compares three things: the current items quantity, a hash of pipe-separated line IDs ("Line Items Redundancy Code"), and shipping charges amount. A mismatch sets `Has Order State Error` and blocks further processing until resolved.

The second phase runs through `ShpfyCreateSalesOrders.Report.al`, which delegates to `ShpfyProcessOrders` and ultimately `ShpfyProcessOrder.Codeunit.al`. This codeunit first calls `ShpfyOrderMapping` to resolve customer/company and line-item mappings, then builds a Sales Header and Sales Lines. If `Fulfillment Status = Fulfilled` and the shop has `Create Invoices From Orders` enabled, an Invoice is created instead of an Order. Tip lines route to the shop's Tip Account G/L, gift card lines to the Sold Gift Card Account, and shipping charges become either a G/L line or an item charge depending on the `Shpfy Shipment Method Mapping` configuration. After lines are created, global discounts (the portion of order discount not already allocated to individual lines or shipping) are applied via `SalesCalcDiscountByType`. If `Auto Release Sales Orders` is on, the document is released automatically.

## Things to know

- Amounts exist in two currencies: shop currency (`Currency Code`, `Total Amount`) and presentment currency (`Presentment Currency Code`, `Presentment Total Amount`). The shop's `Currency Handling` setting controls which set flows into BC sales documents -- see the `case ShopifyShop."Currency Handling"` blocks in `ShpfyProcessOrder`.
- `Location Id` on order lines comes from fulfillment order lines (`ShpfyFulFillmentOrderLine`), not directly from the Shopify order line JSON. See `UpdateLocationIdAndDeliveryMethodOnOrderLine` in `ShpfyImportOrder`.
- Refund quantities are subtracted from order line quantities in `ConsiderRefundsInQuantityAndAmounts`. Lines that reach zero quantity are then deleted. A refund line with `Can Create Credit Memo = false` on a processed order triggers a conflict error.
- B2B orders (`B2B = true`) take a separate mapping path through `MapB2BHeaderFields` in `ShpfyOrderMapping`, which resolves company and company location to sell-to/bill-to customers.
- The `Use Shopify Order No.` flag lets a specific order use the Shopify order number as the BC document number, but validation in `ShpfyProcessOrder` rejects any order number starting with `@`.
- Order line pagination is handled inside `RetrieveAndSetOrderLines` -- it loops on `hasNextPage` / `endCursor` from the GraphQL response, so orders with many lines are not truncated.
- Conflict detection is deliberately conservative: once `Has Order State Error` is set, re-import will not clear it. Manual resolution or calling `MarkOrderConflictAsResolved` is required.
