# Catalogs

Part of [Shopify Connector](../../CLAUDE.md).

Manages Shopify catalogs for B2B pricing, enabling different price lists for different companies or markets.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Catalog (30152) | Stores catalog definitions with pricing and tax configuration |
| Table | Shpfy Catalog Price (30153) | Temporary table for catalog-specific product variant prices |
| Table | Shpfy Market Catalog Relation (30400) | Links catalogs to Shopify markets |
| Codeunit | Shpfy Sync Catalog Prices (30XXX) | Synchronizes prices to catalogs based on BC price lists |
| Codeunit | Shpfy Catalog API (30XXX) | GraphQL API calls for catalog operations |
| Report | Shpfy Sync Catalogs | Imports catalog definitions from Shopify |
| Report | Shpfy Sync Catalog Prices | Exports catalog prices to Shopify |
| Page | Shpfy Catalogs | List view of catalogs |
| Page | Shpfy Market Catalogs | View market-catalog relationships |
| Page | Shpfy Market Catalog Relations | List of market-catalog relations |
| Enum | Shpfy Catalog Type (30XXX) | Enumeration of catalog types |

## Key concepts

- Catalogs enable B2B pricing by linking Shopify companies to specific price lists
- Each catalog can have its own customer price group, discount group, and posting groups
- Catalog pricing can be based on a specific BC customer or use catalog-level settings
- Market catalog relations determine which catalogs are available in which Shopify markets
- Prices Including VAT setting controls whether catalog prices are tax-inclusive
- Customer No. assignment makes customer-specific settings override catalog settings
- Sync Prices flag controls whether prices are actively synchronized to Shopify
- Currency Code allows catalog-specific currency pricing
