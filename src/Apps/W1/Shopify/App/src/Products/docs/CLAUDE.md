# Products

Part of [Shopify Connector](../../CLAUDE.md).

Handles product and variant synchronization between Business Central items and Shopify products, including mapping, price calculation, and image sync.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Product (30127) | Stores Shopify product data with BC item mapping |
| Table | Shpfy Variant (30129) | Stores Shopify variant data with BC item variant mapping |
| Table | Shpfy Inventory Item (30126) | Inventory tracking metadata for variants |
| Table | Shpfy Sales Channel (30125) | Product publication channels in Shopify |
| Table | Shpfy Product Collection (30128) | Product collections (grouped products) |
| Codeunit | Shpfy Sync Products (30185) | Orchestrates bidirectional product sync |
| Codeunit | Shpfy Product Import (30180) | Imports products from Shopify to BC |
| Codeunit | Shpfy Product Export (30178) | Exports BC items to Shopify products |
| Codeunit | Shpfy Product Mapping (30181) | Maps Shopify products/variants to BC items |
| Codeunit | Shpfy Product Price Calc. (30182) | Calculates prices using BC sales pricing |
| Codeunit | Shpfy Create Product (30177) | Creates new products in Shopify from items |
| Codeunit | Shpfy Product API (30176) | GraphQL API calls for products |
| Codeunit | Shpfy Variant API (30179) | GraphQL API calls for variants |
| Codeunit | Shpfy Product Events (30183) | Event publishers for extensibility |
| Codeunit | Shpfy Sync Product Image (30184) | Synchronizes product images |
| Codeunit | Shpfy Create Item (30175) | Creates BC items from Shopify products |
| Codeunit | Shpfy Update Item (30174) | Updates BC items from Shopify data |
| Enum | Shpfy Product Status (30130) | Active, Archived, Draft |
| Enum | Shpfy SKU Mapping (30132) | How SKU maps to BC (Item No., Variant Code, etc.) |
| Enum | Shpfy Variant Create Strategy (30165) | DEFAULT or REMOVE_STANDALONE_VARIANT |
| Enum | Shpfy Remove Product Action (30131) | Status change when product removed |
| Report | Shpfy Sync Products (30104) | Manual product sync report |
| Report | Shpfy Add Item to Shopify (30105) | Add BC items to Shopify |
| Page | Shpfy Products (30122) | Product list page |
| Page | Shpfy Variants (30123) | Variant list page |

## Key concepts

- Product-variant hierarchy: Shopify products contain one or more variants; BC items can map to products or variants
- SKU mapping strategies: Configurable mapping from Shopify SKU to BC Item No., Variant Code, Barcode, or Vendor Item No.
- Bidirectional sync: "To Shopify" exports BC items; "From Shopify" imports and creates/updates BC items
- Price calculation: Uses BC sales pricing engine (customer price groups, discounts) to calculate Shopify prices
- Image synchronization: Separate sync for product and variant images via Shpfy Sync Product Image
- Hash tracking: Image Hash, Tags Hash, Description Html Hash track changes for incremental updates
- UoM as Variant: Option to represent BC units of measure as Shopify variants
- Product status: Controls whether products are Active (published), Draft (unpublished), or Archived
