# Order Fulfillments

Manages the fulfillment lifecycle for Shopify orders -- importing fulfillment status from Shopify and exporting BC sales shipments as Shopify fulfillments. Two distinct models coexist: the legacy `Order Fulfillment` and the modern `Fulfillment Order` (multi-location aware).

## How it works

The legacy model uses `Shpfy Order Fulfillment` (30111) and `Shpfy Fulfillment Line` (30139). These are read from Shopify via GraphQL in `ShpfyOrderFulfillments` (30160), which imports fulfillment details including tracking info and line quantities. The modern model uses `Shpfy FulFillment Order Header` (30143) and `Shpfy FulFillment Order Line` (30144), managed by `ShpfyFulfillmentOrdersAPI` (30238). Fulfillment orders are location-aware -- each header carries a `Shopify Location Id` and tracks `Remaining Quantity` per line for partial fulfillment support.

The export side (in the Shipping folder) creates Shopify fulfillments from BC shipments by matching `Sales Shipment Line` records to `FulFillment Order Line` records via `Shpfy Order Line Id`. The API codeunit also handles fulfillment service registration and acceptance of fulfillment requests for third-party logistics workflows.

## Things to know

- Fulfillment Order Lines track `Remaining Quantity` and `Quantity to Fulfill` separately, enabling partial fulfillments where a single order line ships across multiple locations or shipments.
- The `Request Status` field on `FulFillment Order Header` uses the `Shpfy FF Request Status` enum (SUBMITTED, ACCEPTED, etc.) -- fulfillment requests from third-party services must be accepted before they can be fulfilled.
- Gift card detection flows through fulfillment lines: the `Contains Gift Cards` FlowField on `Order Fulfillment` checks `Shpfy Fulfillment Line."Is Gift Card"`, and triggers gift card processing when true.
- The `Delivery Method Type` enum (SHIPPING, PICK_UP, LOCAL, NONE, RETAIL) propagates from header to lines and determines how the fulfillment is handled on the Shopify side.
- Both models store raw JSON via `DataCapture.Add()` for every imported record, enabling debugging without re-querying Shopify.
