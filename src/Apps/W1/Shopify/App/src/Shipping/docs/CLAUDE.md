# Shipping

Maps BC sales shipments to Shopify fulfillments and syncs shipping method configuration between the two systems. This is the outbound side of shipping -- when BC posts a sales shipment, this module creates the corresponding Shopify fulfillment via GraphQL.

## How it works

The `Shpfy Sync Shipm. to Shopify` report drives the process. It finds unsynced Sales Shipment Headers (those with a Shopify Order Id but no Fulfillment Id), fetches the fulfillment orders from Shopify, then calls `ShpfyExportShipments` to build and send `fulfillmentCreate` GraphQL mutations. The mutation is batched by location -- each Shopify location gets its own fulfillment request, with a hard cap of 250 line items per request.

Tracking information is assembled from the BC Shipping Agent record. The `Shpfy Tracking Company` enum on the Shipping Agent table extension maps BC agents to Shopify-recognized carriers. If the agent has an Internet Address, the tracking URL is resolved from it; otherwise, subscribers can override via `OnBeforeRetrieveTrackingUrl`. The `ShpfyShipmentMethodMapping` table maps Shopify delivery method names to BC Shipment Method Codes, Shipping Agents, and shipping charge G/L accounts or items.

Shipping charges are imported on the order side by `ShpfyShippingCharges`, which pulls `shippingLines` from the order and populates `Shpfy Order Shipping Charges`. Any new shipping method title seen during import is auto-created as an unmapped entry in the mapping table.

## Things to know

- Fulfillments are grouped by Shopify Location Id. If an order spans multiple locations, multiple `fulfillmentCreate` mutations are sent.
- The module auto-accepts pending fulfillment requests for orders assigned to BC's fulfillment service before creating the fulfillment.
- Fulfillment orders from third-party fulfillment services (not BC's own) are skipped -- they cannot be fulfilled by BC.
- The `Shpfy Tracking Company` enum on Shipping Agent controls whether Shopify gets a recognized carrier name or the free-text agent name.
- A Fulfillment Id of -1 on the Sales Shipment Header means the export failed; -2 means no applicable lines.
- `ShpfyShippingEvents` exposes two integration events: `OnBeforeRetrieveTrackingUrl` and `OnGetNotifyCustomer` for extensibility.
