# Order fulfillments

Shipment fulfillment tracking for Shopify orders. This module manages two tiers of fulfillment data: what needs to ship (fulfillment orders) and what actually shipped (fulfillments). It is separate from the Shipping module, which handles the export of BC shipments to Shopify -- this module focuses on the Shopify-side data model and import.

## How it works

The data model has two levels. `Shpfy FulFillment Order Header` (table 30143) and `Shpfy FulFillment Order Line` (table 30144) represent Shopify's fulfillment orders -- these are the "requests to ship" assigned to a location, with status, delivery method type, and request status. Each line tracks total quantity, remaining quantity, and quantity to fulfill. The second level is `Shpfy Order Fulfillment` (table 30111) and `Shpfy Fulfillment Line` (table 30139), representing actual completed shipments with tracking numbers, URLs, tracking companies, status, and per-line quantities.

`ShpfyOrderFulfillments.Codeunit.al` handles import of fulfillments from the Shopify API. The `GetFulfillments` method queries for an order's fulfillments via GraphQL and calls `ImportFulfillment` for each. Import processes tracking info (supporting multiple tracking numbers per fulfillment via comma-separated `Tracking Numbers`/`Tracking URLs`/`Tracking Companies` fields), creates fulfillment line records, and pages through results when line items exceed the initial batch. After import, it checks the `Contains Gift Cards` FlowField and triggers gift card retrieval when applicable.

`ShpfyFulfillmentOrdersAPI.Codeunit.al` manages the fulfillment orders side, including accepting pending fulfillment requests from third-party fulfillment services.

## Things to know

- The `Contains Gift Cards` FlowField on `OrderFulfillment` is a CalcFormula checking `Shpfy Fulfillment Line` for `Is Gift Card = true` -- gift card fulfillments trigger a separate API call to retrieve gift card codes.
- Fulfillment line import uses pagination: `ImportFulfillment` loops with `hasNextPage` / `endCursor` to handle large fulfillments.
- `FulFillmentOrderLine` has a `Quantity to Fulfill` decimal field (not integer) to support fractional quantities from UoM conversion during export.
- The `Delivery Method Type` enum covers shipping, pickup, local delivery, and other Shopify delivery methods.
- `FulFillmentOrderLine` has multiple key combinations for lookup by variant, by fulfillment status, and by line item ID.
- Data captures (raw JSON snapshots) are stored for both fulfillment order headers and order fulfillments, and cleaned up on delete.
