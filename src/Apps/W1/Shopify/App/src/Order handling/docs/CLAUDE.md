# Order handling

Part of [Shopify Connector](../../CLAUDE.md).

Manages the import and processing of Shopify orders into Business Central sales documents (orders or invoices).

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Order Header (30118) | Header-level order data including customer, addresses, amounts, status |
| Table | Shpfy Order Line (30119) | Line items within orders (products, variants, quantities, prices) |
| Table | Shpfy Order Attribute (30116) | Custom attributes attached to orders |
| Table | Shpfy Order Line Attribute (30149) | Custom attributes attached to order lines |
| Table | Shpfy Order Tax Line (30122) | Tax breakdown per line and header |
| Table | Shpfy Order Disc.Appl. (30117) | Discount applications on orders |
| Table | Shpfy Order Payment Gateway (30120) | Payment gateway information |
| Table | Shpfy Orders to Import (30120) | Queue of orders to import |
| Codeunit | Shpfy Process Orders (30167) | Entry point for processing multiple orders |
| Codeunit | Shpfy Process Order (30166) | Creates sales header and lines from a single order |
| Codeunit | Shpfy Import Order (30161) | Retrieves order data from Shopify API via GraphQL |
| Codeunit | Shpfy Order Mapping (30163) | Maps Shopify customers, items, variants to BC entities |
| Codeunit | Shpfy Order Mgt. (30165) | Helper functions for order processing |
| Codeunit | Shpfy Orders API (30164) | GraphQL operations on orders |
| Codeunit | Shpfy Order Events (30160) | Integration events for customization |
| Enum | Shpfy Financial Status (30117) | Payment status (Pending, Paid, Refunded, etc.) |
| Enum | Shpfy Order Fulfill. Status (30118) | Fulfillment status (Unfulfilled, Partial, Fulfilled) |
| Enum | Shpfy Cancel Reason (30116) | Reason for order cancellation |
| Enum | Shpfy Processing Method (30121) | How Shopify processes the order |
| Enum | Shpfy Currency Handling (30122) | Shop vs. presentment currency |
| Page | Shpfy Orders (30119) | List page for imported orders |
| Page | Shpfy Order (30118) | Card page for single order |

## Key concepts

- **Import flow**: Orders are retrieved from Shopify via GraphQL (see `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyImportOrder.Codeunit.al`), parsed into header and line records, then queued for processing.
- **Processing flow**: `ShpfyProcessOrders` iterates unprocessed orders; for each, `ShpfyProcessOrder` maps customers/items, creates sales header, lines, applies discounts, and optionally releases the document (see `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyProcessOrder.Codeunit.al`).
- **Mapping**: `ShpfyOrderMapping` resolves Shopify customer IDs to BC customers, variant IDs to items, shipping methods to BC codes (see `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyOrderMapping.Codeunit.al`).
- **Currency handling**: Supports shop currency or presentment currency based on configuration (field `Currency Handling` in shop setup).
- **B2B orders**: Separate processing path for company orders using company location and main contact mapping.
- **Fulfillment and financial status**: Enums track payment and shipment state; when fulfilled and paid, orders can be auto-closed.
- **Attributes and tags**: Custom key-value pairs from Shopify are stored in separate tables and can be synced back to Shopify.
