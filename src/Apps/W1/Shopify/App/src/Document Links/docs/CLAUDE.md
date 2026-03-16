# Document Links

Part of [Shopify Connector](../../CLAUDE.md).

Tracks bidirectional links between Shopify documents (orders, returns, refunds) and Business Central sales documents throughout the posting lifecycle.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Doc. Link To Doc. (30146) | Stores links between Shopify and BC documents |
| Interface | Shpfy IOpenBCDocument | Opens a BC document by number |
| Interface | Shpfy IOpenShopifyDocument | Opens a Shopify document by ID |
| Enum | Shpfy Document Type | BC document types with open implementations |
| Enum | Shpfy Shop Document Type | Shopify document types (Order, Return, Refund) |
| Codeunit | Shpfy Document Link Mgt. (30262) | Event subscribers for posting lifecycle |
| Codeunit | Shpfy BC Document Type Convert (30259) | Converts between Sales and Shpfy enums |

## Key concepts

- Links are created when Shopify documents are imported to BC sales documents
- Links are automatically updated when BC documents are posted or deleted
- Event subscribers track posting lifecycle: Sales Order -> Posted Shipment, Posted Invoice
- Interface-based opening allows navigating from either side (BC to Shopify or Shopify to BC)
- Document type conversion handles mapping between Sales Document Type enum and Shpfy Document Type enum
