# Shipping

Shipping method mapping and shipment export from BC to Shopify. This module handles the outbound fulfillment flow -- when a BC sales shipment is posted, it creates Shopify fulfillments with tracking information. It is separate from Order Fulfillments (which imports fulfillment data from Shopify) because this module drives the BC-to-Shopify direction.

## How it works

The `Shpfy Shipment Method Mapping` table (30131) maps a Shopify shipping method name to a BC `Shipment Method Code`, shipping charges type/number (G/L Account, Item, or Charge), and a shipping agent with service code. This mapping is used during order import to set the correct shipment method on sales documents, and during export to identify the tracking company.

`ShpfyExportShipments.Codeunit.al` is the core export engine. For each posted sales shipment with a `Shpfy Order Id` and no existing `Shpfy Fulfillment Id`, it builds a GraphQL `fulfillmentCreate` mutation. The process matches sales shipment lines to `Shpfy FulFillment Order Line` records by `Line Item Id`, distributing shipped quantities across fulfillment order lines and respecting remaining quantities. It constructs the mutation with tracking info from the sales shipment header (tracking number, shipping agent mapped to a `Shpfy Tracking Company` enum, and tracking URL from `ShippingAgent.GetTrackingInternetAddr`). Results up to 250 line items per request, splitting into multiple mutations if needed.

The `Shpfy Order Shipping Charges` table (30130) stores per-shipping-line details from the order (title, amount, discount, code, and presentment currency equivalents). The shipping agent table extension (`ShpfyShippingAgent.TableExt.al`) adds a `Shpfy Tracking Company` enum field that maps BC shipping agents to Shopify's known tracking company list.

## Things to know

- A fulfillment ID of `-1` on a sales shipment header means the export was attempted but failed -- it prevents repeated retries.
- The export handles third-party fulfillment services: fulfillment orders assigned to non-BC fulfillment services are skipped, and pending fulfillment requests are auto-accepted before fulfilling.
- Tracking URL retrieval can be overridden via the `OnBeforeRetrieveTrackingUrl` event in `ShpfyShippingEvents.Codeunit.al`.
- Customer notification on fulfillment is controlled by the shop's `Send Shipping Confirmation` setting, overridable via the `OnGetNotifyCustomer` event.
- `ShpfyUpdateSalesShipment.Codeunit.al` and the `ShpfySalesShipmentUpdate.PageExt.al` allow manual updates to shipment Shopify fields.
- Shipping charges on the mapping can be G/L Account, Item, or Item Charge -- the G/L account is validated against the shop's allowed account rules.
