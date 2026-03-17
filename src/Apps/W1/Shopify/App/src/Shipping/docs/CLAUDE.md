# Shipping

Handles shipping method sync from Shopify, maps Shopify delivery methods to BC shipment methods and shipping agents, and exports sales shipments as Shopify fulfillments with tracking info.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyExportShipments.Codeunit.al`, `Codeunits/ShpfyShippingMethods.Codeunit.al`
- **Key patterns**: GraphQL mutation construction for fulfillment creation, event-driven extensibility for tracking URLs and notifications

## Structure

- Codeunits (5): ExportShipments, ShippingCharges, ShippingEvents, ShippingMethods, UpdateSalesShipment
- Tables (2): OrderShippingCharges, ShipmentMethodMapping
- Table Extensions (3): SalesShipmentHeader, SalesShipmentLine, ShippingAgent (adds Shpfy Tracking Company)
- Pages (2): OrderShippingCharges, ShipmentMethodsMapping
- Page Extensions (2): SalesShipmentUpdate, ShippingAgents
- Reports (1): SyncShipmToShopify

## Key concepts

- `ExportShipments` builds GraphQL `fulfillmentCreate` mutations that include tracking info (number, company, URL) from the BC shipping agent and package tracking number
- Fulfillment orders are matched to sales shipment lines by order line ID, respecting remaining quantities across multiple partial shipments
- `ShippingMethods` imports Shopify delivery profiles and their method definitions to auto-create shipment method mappings per shop
- The `ShipmentMethodMapping` table maps Shopify shipping method names to BC shipment method codes, shipping charges (G/L Account, Item, or Item Charge), and shipping agent codes
- Fulfillment requests in SUBMITTED status are auto-accepted before fulfillment creation; lines at third-party fulfillment service locations are skipped
