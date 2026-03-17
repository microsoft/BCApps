# Shipping

Maps shipping methods and agents between Shopify and BC, exports BC sales shipments as Shopify fulfillments with tracking information, and imports shipping cost details from Shopify orders.

## How it works

`Shpfy Shipment Method Mapping` (30131) maps Shopify shipping line titles to BC Shipment Method Codes, Shipping Agent Codes, and configurable shipping charge accounts (G/L Account, Item, or Item Charge). The `Shpfy Shipping Agent` table extension adds a `Shpfy Tracking Company` enum to BC's Shipping Agent, allowing the connector to send Shopify-recognized carrier names (e.g., "DHL", "FedEx") instead of free-text.

Shipment export is driven by the `Shpfy Sync Shipm. to Shopify` report (30109), which iterates over Sales Shipment Headers with a Shopify Order Id but no Fulfillment Id. For each shipment, it retrieves the latest fulfillment orders from Shopify, then `ShpfyExportShipments` (30190) builds a `fulfillmentCreate` GraphQL mutation that groups fulfillment order lines by fulfillment order. Tracking numbers and URLs from the BC shipment header are included in the mutation.

`ShpfyShippingCharges` (30191) imports shipping line costs from Shopify orders, including discount allocations, into `Shpfy Order Shipping Charges` and auto-creates shipment method mappings for new shipping titles.

## Things to know

- The export batches fulfillment order lines into groups of 250 per GraphQL mutation to stay within Shopify's line limit per `fulfillmentCreate` call.
- Fulfillment orders assigned to third-party fulfillment services are skipped during export unless they belong to the connector's own registered service -- the `CanFulfillOrder` check validates this.
- Pending fulfillment requests (Status = OPEN, Request Status = SUBMITTED) are automatically accepted via `AcceptFulfillmentRequest` before fulfillment, enabling the BC-to-Shopify flow for fulfillment service integrations.
- The `ShpfyShippingEvents` codeunit exposes `OnBeforeRetrieveTrackingUrl` and `OnGetNotifyCustomer` integration events, letting extensions customize tracking URLs and email notification behavior per shipment.
- A Fulfillment Id of -1 on a Sales Shipment Header means fulfillment creation failed; -2 means no applicable lines were found. Both are sentinel values that prevent re-processing.
