# Catalogs

B2B catalog pricing for Shopify. This module manages price lists that are tied to specific companies or markets, allowing different customers to see different prices for the same products. It is separate from the Products module (which handles base product data) because catalogs layer company-specific or market-specific pricing on top.

## How it works

The `Shpfy Catalog` table (30152) represents a Shopify catalog, linked to a company via `Company SystemId` and to a shop. Each catalog carries pricing configuration: `Customer Price Group`, `Customer Discount Group`, `Gen. Bus. Posting Group`, `VAT Bus. Posting Group`, `Tax Area Code`, `Prices Including VAT`, `Allow Line Disc.`, and a `Customer No.` override. When a `Customer No.` is set, its discount and price group settings take precedence over the catalog-level fields. The `Sync Prices` flag controls whether price sync is active, and `Catalog Type` (from `ShpfyCatalogType.Enum.al`) distinguishes catalog categories.

`Shpfy Catalog Price` (table 30153) is a temporary table that holds pre-calculated prices per variant and price list. It stores the computed `Price` and `Compare at Price` along with the price list currency. `ShpfySyncCatalogPrices.Codeunit.al` calculates these prices using BC's pricing engine with the catalog's posting group and pricing configuration, then pushes them to Shopify.

`Shpfy Market Catalog Relation` (table 30400) is a many-to-many junction between markets and catalogs, storing the market name and catalog title. This supports Shopify's market-based catalog assignment, where a single catalog can serve multiple markets. `ShpfyCatalogAPI.Codeunit.al` handles the API interactions for creating and syncing catalogs.

## Things to know

- The `Catalog Price` table is `TableType = Temporary` -- prices are calculated on the fly and never persisted in BC.
- Catalog creation can be triggered automatically during company export when the shop's `Auto Create Catalog` flag is set.
- The catalog primary key is composite (`Id`, `Company SystemId`), so the same Shopify catalog ID can appear with different company associations.
- Deleting a catalog automatically clears its `MarketCatalogRelation` records via the `OnDelete` trigger.
- Market catalog relations are imported from Shopify and displayed on the `ShpfyMarketCatalogs.Page.al` and `ShpfyMarketCatalogRelations.Page.al` pages.
- The `Currency Code` field on the catalog allows overriding the price list currency independently of the shop currency.
