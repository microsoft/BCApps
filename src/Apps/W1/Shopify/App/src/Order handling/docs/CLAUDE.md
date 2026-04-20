# Order handling

Imports Shopify orders into Business Central, maps them to customers and items, and creates sales orders or invoices.

## How it works

The pipeline has three stages.

- **Discovery**: `ShpfyOrdersAPI` queries the Shopify GraphQL API for orders updated since the last sync. It writes lightweight rows into the `Orders to Import` queue table, not full order data. The query distinguishes first-time sync (open orders only) from incremental sync (all orders by updated-at).

- **Import**: `ShpfyImportOrder` fetches the full order JSON for each queued entry, populates `Order Header` and `Order Line` records, and pulls in related data (tax lines, attributes, risks, shipping charges, transactions, fulfillment orders, returns, refunds). It detects conflicts when a previously processed order is edited in Shopify and flags them with `Has Order State Error`. Staff member retrieval in the GraphQL query and salesperson assignment during header population are conditional on `Shop."Advanced Shopify Plan"` (requires Plus/Advanced plans).

*Updated: 2026-04-08 -- staff member gating changed from B2B Enabled to Advanced Shopify Plan*

- **Processing**: `ShpfyProcessOrder` runs mapping then document creation. `ShpfyOrderMapping.DoMapping` resolves Shopify customers to BC customer numbers (with B2B company mapping as a separate path) and maps each order line's variant to an item/variant/UoM. `ShpfyProcessOrder.CreateHeaderFromShopifyOrder` builds a Sales Header with all three address contexts (sell-to, ship-to, bill-to), then `CreateLinesFromShopifyOrder` adds item lines, tip lines (G/L), gift card lines (G/L), shipping charge lines, and a cash rounding line. Global discounts that were not allocated to individual lines are applied as invoice discount. If the shop has "Auto Release Sales Orders" enabled, the document is released immediately.

## Things to know

- Every monetary field exists in two flavours: shop currency (`Currency Code`) and presentment currency (`Presentment Currency Code`). Which one flows to the sales document depends on the shop's `Currency Handling` setting.
- `Orders to Import` is a queue, not a mirror. It is populated during discovery and consumed during import. It carries summary data and error tracking (`Has Error`, blob `Error Message` and `Error Call Stack`).
- The `Processed` flag on `Order Header` prevents re-processing. `IsProcessed()` also checks `Doc. Link To Doc.` so that orders linked to BC documents through any path are considered processed.
- `Document Date` has a validation trigger that calls `TestField("Sales Order No.", '')`, which prevents changes after a sales order has been created.
- The Shopify Order page (`ShpfyOrder.Page.al`) exposes contact lookup fields (`Sell-to Contact No.`, `Ship-to Contact No.`, `Bill-to Contact No.`) with `OnLookup` triggers that call `LookupContactForCustomer` to filter contacts by the related customer's company contact. The `OnValidate` triggers on these fields call `CheckContactRelatedToCustomer` to ensure the selected contact belongs to the correct customer. These fields are hidden by default (`Visible = false`).

*Updated: 2026-04-08 -- contact lookup/validation added to Shopify Order page (PR #7525)*

- Fulfilled orders become invoices instead of sales orders when `Create Invoices From Orders` is enabled on the shop.
- `ShpfyProcessOrders` (plural) is the batch entry point. After processing orders it also processes refunds if the shop uses the "Auto Create Credit Memo" strategy.
- `ShpfyOrders` (public API codeunit) exposes `MarkAsPaid` and `CancelOrder` for external callers.
