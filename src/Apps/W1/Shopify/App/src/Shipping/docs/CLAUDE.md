# Shipping

Shipment method mapping, shipping charges import, and fulfillment export to Shopify. This area bridges BC's shipping agents and shipment methods with Shopify's shipping lines, and pushes tracking information back to Shopify when orders are shipped.

## How it works

`ShpfyShippingCharges.Codeunit.al` pulls shipping lines from Shopify orders via GraphQL and populates `Shpfy Order Shipping Charges` records. For each shipping line, it auto-creates a `Shpfy Shipment Method Mapping` row keyed by (Shop Code, Title) if one doesn't exist, mirroring how the Transactions area auto-creates gateway mappings. The mapping table (`ShpfyShipmentMethodMapping.Table.al`) lets the user configure a BC Shipment Method Code, a Shipping Agent + Service Code, and a Shipping Charges account (G/L Account, Item, or Item Charge) per Shopify shipping method.

The export side is handled by `ShpfyExportShipments.Codeunit.al` (covered in Order Fulfillments), which reads the Shipping Agent from the Sales Shipment Header to determine the tracking company and URL. `ShpfyShippingEvents.Codeunit.al` provides the `OnBeforeRetrieveTrackingUrl` and `OnGetNotifyCustomer` integration events for partners to override tracking URL generation and customer notification behavior.

## Things to know

- Shipping charges carry dual-currency amounts (shop money and presentment money) with discount amounts tracked separately, resolved through the order header's currency codes.
- The `Shpfy Shipping Agent` table extension adds a `Shpfy Tracking Company` enum field to BC's Shipping Agent, mapping to Shopify's known carrier names. When the enum is blank, the agent's Name (or Code) is sent as a custom tracking company.
- `ShpfySyncShipmToShopify.Report.al` is the user-facing entry point for pushing shipments to Shopify -- it is a report object (not a codeunit), following the connector's pattern of using reports as batch job wrappers.
- When shipping lines are removed from a Shopify order, `DeleteRemovedShippingLines` adjusts the order header's `Shipping Charges Amount` and `Total Amount` to keep them consistent.
- The `Sales Shipment Header` and `Sales Shipment Line` table extensions add Shopify Order Id and Fulfillment Id fields that link BC shipments to Shopify fulfillments.
