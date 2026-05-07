# Order fulfillments

Manages two distinct Shopify concepts: Fulfillment Orders (Shopify's plan for how an order should be shipped) and Fulfillments (the actual shipment records). Fulfillment Orders are created by Shopify per location; Fulfillments are created by BC when posting sales shipments.

## How it works

When an order is imported, `ShpfyFulfillmentOrdersAPI.GetShopifyFulfillmentOrdersFromShopifyOrder` fetches the fulfillment orders for that order. Each fulfillment order has a header (`Shpfy FulFillment Order Header`) with status, location, delivery method type, and request status, plus line items (`Shpfy FulFillment Order Line`) with remaining quantities. These are the "work items" that tell the Shipping module which items at which location still need to be shipped.

Fulfillments (actual shipments) are tracked in `Shpfy Order Fulfillment` and `Shpfy Fulfillment Line`. The `ShpfyOrderFulfillments` codeunit imports fulfillment data from Shopify, including tracking info (numbers, URLs, companies) and line-level quantities. It handles pagination for fulfillments with many line items and detects gift card fulfillments to trigger gift card retrieval.

The module also manages BC's fulfillment service registration. On first outgoing request, it registers a fulfillment service with Shopify (`CreateFulfillmentService`), which allows BC to appear as a fulfillment location. Before fetching assigned fulfillment orders, `GetAssignedFulfillmentOrders` validates that the fulfillment service still exists in Shopify via `HasFulfillmentService` -- if the service was deleted from Shopify, it automatically deactivates the `Fulfillment Service Activated` flag on the shop and exits early. Assigned fulfillment orders (where Shopify has routed work to BC's service) must be accepted via `AcceptFulfillmentRequest` before they can be fulfilled; this sends a GraphQL mutation and updates the request status to ACCEPTED on success.

*Updated: 2026-04-08 -- HasFulfillmentService validation and AcceptFulfillmentRequest details*

## Things to know

- Fulfillment order headers store `Shop Id` and `Shop Code` directly (populated from the shop record during extraction), enabling direct shop-level filtering without joining through the order.
- Fulfillment Orders are Shopify's concept -- they represent "what needs to ship from where." Fulfillments are the actual shipment records.
- The `Request Status` enum (SUBMITTED, ACCEPTED, etc.) tracks the fulfillment service handshake -- BC must accept assigned requests before creating fulfillments.
- Fulfillment order lines carry `Remaining Quantity` and `Quantity to Fulfill` -- the Shipping module uses these to match BC shipment lines to Shopify fulfillment order lines.
- `Delivery Method Type` distinguishes shipping, pickup, local delivery, and other methods.
- The fulfillment service is auto-registered on first outgoing sync if `Allow Outgoing Requests` is enabled.
- Multiple tracking numbers per fulfillment are supported -- they are stored as comma-separated values.
- Fulfillment line items are paginated -- `ImportFulfillment` in `ShpfyOrderFulfillments` follows `hasNextPage`/`endCursor` to fetch all lines when a fulfillment has many items.
