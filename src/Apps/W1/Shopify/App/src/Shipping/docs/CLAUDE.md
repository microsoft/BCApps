# Shipping

This folder handles the mapping between Shopify shipping methods and BC shipment methods / shipping agents, plus the export of BC shipments as Shopify fulfillments.

## Shipping method mapping

`Shpfy Shipment Method Mapping` (table 30131) is keyed on (Shop Code, Name) where Name is the Shopify shipping rate title (e.g. "Standard Shipping"). It maps to:

- **Shipment Method Code** -- a BC `Shipment Method` used on the Sales Header.
- **Shipping Agent Code** / **Shipping Agent Service Code** -- used both on the Sales Header and on individual shipping charge sales lines.
- **Shipping Charges Type** / **Shipping Charges No.** -- optionally overrides the shop-level `"Shipping Charges Account"`. Can be G/L Account, Item, or Charge (Item). When set to Charge (Item), the connector auto-assigns the item charge equally across shipment lines.

The mapping is consumed during order processing in `ShpfyOrderMapping.MapShippingMethodCode` and `MapShippingAgent`, and again in `ShpfyProcessOrder.CreateLinesFromShopifyOrder` when creating shipping charge sales lines.

## Shipping agent -> Shopify carrier

The `Shpfy Shipping Agent` table extension adds a `"Shpfy Tracking Company"` enum field to BC's Shipping Agent table. During shipment export (`ShpfyExportShipments`), the connector uses this to tell Shopify which carrier the tracking number belongs to. If the tracking company is blank, it falls back to the agent's Name or Code.

## Fulfillment location mapping

During order import, fulfillment order lines carry a `Shopify Location Id`. This is matched to `Shpfy Shop Location` records to determine the BC `"Default Location Code"` for the sales line. The location on the fulfillment order line is propagated to the order line only when the total quantity across fulfillment order lines matches the order line quantity.

## Shipment export flow

`ShpfyExportShipments.CreateShopifyFulfillment` is the entry point. It:

1. Finds the Shopify order header from the Sales Shipment's `"Shpfy Order Id"`.
2. Matches shipment lines to fulfillment order lines by `Line Item Id`, splitting quantities across multiple fulfillment orders if needed.
3. Auto-accepts pending fulfillment requests (SUBMITTED status) before fulfilling.
4. Skips fulfillment orders assigned to third-party fulfillment services.
5. Builds one or more `fulfillmentCreate` GraphQL mutations (batching at 250 lines per request).
6. Includes tracking info from the Shipment Header and Shipping Agent.
7. Writes the Shopify fulfillment ID back to the Sales Shipment Header.

The `ShpfySyncShipmToShopify.Report.al` report drives the batch export flow.
