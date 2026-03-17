# Order handling

Order handling manages the one-way flow of Shopify orders into Business Central sales documents. It covers the entire lifecycle from initial discovery of new orders through Shopify's API, through staging and enrichment, to final creation of BC Sales Orders or Sales Invoices. This module deliberately does not export orders back to Shopify -- the flow is strictly inbound, with the only outbound calls being order attribute updates, order cancellation, and order closure.

## How it works

The order pipeline has three distinct stages. First, `ShpfyOrdersAPI.Codeunit.al` polls Shopify for orders updated since the last sync time, creating lightweight "Orders to Import" staging records (`ShpfyOrdersToImport.Table.al`) with summary data (amount, status, tags, risk level). These staging records appear on the "Orders to Import" page where users can review and select which orders to pull in.

Second, `ShpfyImportOrder.Codeunit.al` fetches the full order JSON via GraphQL, parses it into an `Shpfy Order Header` record with all three denormalized address blocks (sell-to, ship-to, bill-to), and creates `Shpfy Order Line` records for each line item. This stage also imports related records: tax lines, custom attributes (both order-level and line-level), shipping charges, fulfillment orders, risks, returns, and refunds. The import handles edited orders by computing a "Line Items Redundancy Code" hash of line IDs and comparing it on re-import to detect order edits that conflict with already-processed orders.

Third, `ShpfyProcessOrder.Codeunit.al` converts the enriched Shopify order into a BC Sales Header and Sales Lines. It runs order mapping first (`ShpfyOrderMapping`) to resolve item/customer references, then creates the sales document. The document type depends on fulfillment status: fully fulfilled orders create Sales Invoices (if the Shop setting allows), otherwise Sales Orders. Line creation respects the Shop's "Currency Handling" setting to pick between shop currency and presentment currency amounts. Shipping charges become separate G/L Account lines (or Item Charge lines if configured via shipment method mapping). Global discounts that exceed per-line discounts are applied as invoice discounts.

## Things to know

- Every monetary field on the Order Header and Order Line exists in duplicate: one in shop currency (the Shopify store's base currency) and one in presentment currency (what the customer actually paid in). The `Currency Handling` enum on the Shop controls which set of amounts flows to the BC sales document. This is not a simple toggle -- changing it after orders have been processed will not retroactively fix previously created documents.

- The Order Header stores three complete address blocks inline (sell-to, ship-to, bill-to) with first name, last name, name, address lines, city, post code, country/region code, county, and latitude/longitude. The name composition uses the Shop's `ICustomerName` interface (from the Customers module) to derive Name, Name 2, and Contact Name from first/last/company inputs.

- The `Processed` flag on Order Header is the gate that prevents re-processing. Once set, the order will not generate another sales document. The `Has Order State Error` flag indicates that a processed order was re-imported and found to have changed (edited, cancelled, or refunded in Shopify after processing in BC). This is a conflict state that requires manual resolution.

- Refund handling modifies order line quantities and header amounts in-place. `ConsiderRefundsInQuantityAndAmounts` subtracts refund line quantities and amounts directly from order lines and header totals before the order is processed into a sales document. Zero-quantity lines are deleted after this adjustment.

- Table extensions on BC Sales Header, Sales Line, Sales Invoice Header, Sales Invoice Line, Sales Shipment Header, and archive tables carry `Shpfy Order Id`, `Shpfy Order No.`, `Shpfy Order Line Id`, and `Shpfy Refund Id` fields. These link BC documents back to their Shopify origin and propagate through posting via event subscribers in `ShpfyProcessOrder.Codeunit.al`.

- The `ShpfyOrdersAPI.Codeunit.al` uses two different GraphQL query types depending on whether it is the first sync (GetOpenOrdersToImport -- only open orders) or subsequent syncs (GetOrdersToImport -- by updated_at time). New closed orders are deliberately excluded from the first sync to avoid importing historical orders.

- Cash rounding is handled via a dedicated `Cash Roundings Account` G/L setting on the Shop. If Shopify's `totalCashRoundingAdjustment` is non-zero, a separate sales line is created with that amount.
