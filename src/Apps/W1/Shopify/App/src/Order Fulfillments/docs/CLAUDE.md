# Order Fulfillments

Two distinct but related concepts live here: fulfillment orders (Shopify's plan for what should ship from where) and order fulfillments (actual shipments with tracking). A single Shopify order can have multiple fulfillment orders when items are allocated to different locations, and each fulfillment order can produce multiple fulfillments for partial shipping.

## How it works

`ShpfyFulfillmentOrdersAPI.Codeunit.al` manages the fulfillment order lifecycle. It fetches fulfillment orders from Shopify via GraphQL, creates local `Shpfy FulFillment Order Header` and `Shpfy FulFillment Order Line` records, and handles the fulfillment service registration that BC needs to accept and process fulfillment requests. The API supports accepting pending fulfillment requests (SUBMITTED status) before creating actual fulfillments.

`ShpfyExportShipments.Codeunit.al` drives the outbound flow -- when a BC Sales Shipment is posted, it builds a GraphQL `fulfillmentCreate` mutation. The logic matches shipment lines to open fulfillment order lines by `Line Item Id`, distributing quantities across fulfillment orders when needed. It batches up to 250 line items per mutation. If fulfillment order lines are assigned to a third-party fulfillment service (not the BC service), they are skipped. Tracking info from the BC Shipping Agent maps to Shopify's tracking company via the `Shpfy Tracking Companies` enum.

`ShpfyOrderFulfillments.Codeunit.al` handles the inbound side, importing actual fulfillment records with tracking numbers, URLs, and fulfillment line items, including gift card detection.

## Things to know

- Fulfillment Order Lines track `Remaining Quantity`, `Total Quantity`, and `Quantity to Fulfill` -- the last one is a working field used during export to accumulate how much to include in the current mutation.
- `ShpfyExportShipments` sets `Shpfy Fulfillment Id` to -1 on the Sales Shipment Header when no matching fulfillment lines are found or when Shopify rejects the request, preventing repeated attempts.
- The fulfillment service is auto-registered on first outbound request if `Allow Outgoing Requests` is enabled but `Fulfillment Service Activated` is false.
- Fulfillment Order Header carries `Request Status` (UNSUBMITTED, SUBMITTED, ACCEPTED, etc.) which gates whether BC can create fulfillments -- assigned orders with SUBMITTED status must be accepted first via `AcceptFulfillmentRequest`.
