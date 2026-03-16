# Shipping

Part of [Shopify Connector](../../CLAUDE.md).

Manages shipment export to Shopify, shipping method mappings, and shipping charge handling for orders.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Shipment Method Mapping (30131) | Maps Shopify shipping methods to BC shipment methods and shipping agents |
| Table | Shpfy Order Shipping Charges (30130) | Stores shipping line items from Shopify orders with amounts and discounts |
| Codeunit | Shpfy Export Shipments (30190) | Creates fulfillments in Shopify from posted sales shipments |
| Codeunit | Shpfy Shipping Methods (30XXX) | Manages shipping method mapping and synchronization |
| Codeunit | Shpfy Shipping Charges (30XXX) | Processes shipping charges from orders |
| Codeunit | Shpfy Shipping Events (30XXX) | Event publisher for shipping-related integration events |
| Codeunit | Shpfy Update Sales Shipment (30XXX) | Updates sales shipment headers with Shopify tracking info |
| Report | Shpfy Sync Shipm. to Shopify | Exports posted sales shipments to Shopify as fulfillments |
| Page | Shpfy Shipment Methods Mapping | Configure shipment method mappings |
| Page | Shpfy Order Shipping Charges | View shipping charges for orders |
| TableExt | Shpfy Sales Shipment Header | Extends Sales Shipment Header with Shpfy Order Id and Shpfy Fulfillment Id |
| TableExt | Shpfy Sales Shipment Line | Extends Sales Shipment Line with Shpfy Order Line Id |
| TableExt | Shpfy Shipping Agent | Extends Shipping Agent with Shopify Tracking Company enum |
| PageExt | Shpfy Sales Shipment Update | Adds Shopify sync action to posted sales shipment |
| PageExt | Shpfy Shipping Agents | Adds Shopify Tracking Company field to shipping agents page |

## Key concepts

- Shipment export creates fulfillments in Shopify when BC sales shipments are posted
- Shipment method mapping connects Shopify shipping method names to BC shipment methods
- Shipping charges can be mapped to G/L accounts, items, or item charges for order processing
- Shipping agent tracking company enum maps BC shipping agents to Shopify's predefined tracking companies
- Fulfillment orders are created per shipment, with tracking information included
- Shipping lines support both shop currency and presentment currency amounts
- Partial fulfillments are supported when shipments don't include all order lines
