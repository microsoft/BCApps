# Shipping

This module handles shipping method synchronization from Shopify to BC, shipping charge management on orders, and fulfillment export from BC back to Shopify. It is the bridge between Shopify's delivery profiles and BC's shipment method / shipping agent concepts.

## How it works

`ShpfyShippingMethods` syncs Shopify delivery profiles into the `ShpfyShipmentMethodMapping` table. It walks the GraphQL hierarchy of delivery profiles, location groups, and zones to extract method definition names. Each unique name becomes a mapping row that the user can link to a BC Shipment Method Code, Shipping Agent Code, Shipping Agent Service Code, and optionally a specific shipping charges type (G/L Account, Item, or Item Charge).

`ShpfyShippingCharges` runs during order import to populate `ShpfyOrderShippingCharges` records from the order's `shippingLines`. Each shipping line carries dual currency amounts (shop + presentment) and discount allocations. If a shipping line disappears from a re-imported order, it is deleted and the header amounts are adjusted down. New shipping line titles automatically create mapping rows if they do not already exist.

`ShpfyExportShipments` converts BC posted sales shipments into Shopify fulfillments. It matches shipment lines to fulfillment order lines by `Shpfy Order Line Id`, respects remaining quantities, builds a GraphQL `fulfillmentCreate` mutation with tracking info, and sends it. Tracking company comes from the shipping agent's `Shpfy Tracking Company` enum (or falls back to the agent name). The tracking URL is resolved from the shipping agent's internet address, with an `OnBeforeRetrieveTrackingUrl` event for custom logic.

## Things to know

- The mapping table (`ShpfyShipmentMethodMapping`) is keyed by shop code + shipping method name (the Shopify title). One Shopify shipping method maps to one BC shipment method, one shipping agent, and one shipping agent service.
- Shipping charges on orders can use a per-method type override. If the mapping row has a "Shipping Charges Type" of Item or Charge (Item), that is used instead of the shop's default Shipping Charges Account. Item Charges get auto-assigned equally across item lines.
- Fulfillment export batches lines into GraphQL requests of up to 250 fulfillment order lines each. Larger shipments produce multiple API calls.
- If a fulfillment order has a pending fulfillment request (status SUBMITTED), the export will attempt to accept it before fulfilling. Fulfillment orders assigned to third-party fulfillment services are skipped.
- `ShpfyShippingEvents` exposes two integration events: `OnBeforeRetrieveTrackingUrl` for custom tracking URL generation, and `OnGetNotifyCustomer` for controlling whether Shopify sends a shipping confirmation email.
- The `ShpfyUpdateSalesShipment` codeunit subscribes to the Posted Sales Shipment update page to allow editing the `Shpfy Fulfillment Id`, which can be used to re-trigger fulfillment export or clear a failed attempt.
