# Inventory

Part of [Shopify Connector](../../CLAUDE.md).

Synchronizes inventory levels between Business Central and Shopify, supporting multiple stock calculation strategies and location mappings.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Shop Inventory (30114) | Stores inventory levels per product variant and location |
| Table | Shpfy Shop Location (30113) | Maps Shopify locations to BC locations with stock calculation settings |
| Interface | Shpfy IStock Available | Determines if location can have stock |
| Interface | Shpfy Stock Calculation | Calculates available stock for an item |
| Interface | Shpfy Extended Stock Calculation | Extended calculation with location parameter |
| Enum | Shpfy Stock Calculation | Stock calculation strategies: Disabled, Projected Available Balance Today, Non-reserved Inventory |
| Codeunit | Shpfy Sync Inventory (30197) | Orchestrates import and export of stock levels |
| Codeunit | Shpfy Inventory API (30195) | GraphQL-based stock retrieval and update operations |
| Codeunit | Shpfy Balance Today (30212) | Calculates projected available balance |
| Codeunit | Shpfy Free Inventory (stock calc) | Calculates non-reserved inventory |
| Codeunit | Shpfy Can Have Stock (30271) | IStockAvailable implementation (returns true) |
| Codeunit | Shpfy Can Not Have Stock | IStockAvailable implementation (returns false) |

## Key concepts

- Each Shopify location mapped to BC location filter and stock calculation method
- Stock calculation strategies implemented as interface-based plugins
- Inventory sync is bidirectional: import from Shopify (current levels) and export to Shopify (calculated BC stock)
- Unit of measure conversions applied when variant option specifies UOM
- Rate limiting handled via batch updates (max 250 inventory items per mutation)
- Non-inventory and service items excluded from sync
