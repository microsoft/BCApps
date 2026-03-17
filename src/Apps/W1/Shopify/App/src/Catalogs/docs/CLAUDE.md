# Catalogs

Manages Shopify B2B catalogs (company-specific) and market catalogs, including catalog creation, price list management, price syncing, and market-catalog relationships.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyCatalogAPI.Codeunit.al`, `Codeunits/ShpfySyncCatalogPrices.Codeunit.al`
- **Key patterns**: GraphQL cursor-based pagination, two catalog types (Company, Market)

## Structure

- Codeunits (2): CatalogAPI (CRUD and import), SyncCatalogPrices (price sync orchestration)
- Tables (3): Catalog, CatalogPrice, MarketCatalogRelation
- Enums (1): CatalogType
- Pages (3): Catalogs, MarketCatalogRelations, MarketCatalogs
- Reports (2): SyncCatalogPrices, SyncCatalogs

## Key concepts

- Two catalog types: `Company` (B2B, linked to a Shopify company location) and `Market` (per-market pricing, linked to Shopify markets)
- Creating a company catalog also creates a publication and a price list in Shopify via separate GraphQL mutations
- `GetCatalogPrices` first fetches the product list included in a catalog, then retrieves per-variant prices with compare-at prices from the catalog's price list
- The `Catalog` table stores BC pricing configuration (Customer Price Group, Customer Discount Group, Gen. Bus. Posting Group, VAT settings) used when calculating prices to sync
- Market catalogs track associated markets via the `MarketCatalogRelation` table, supporting both unified and non-unified Shopify market configurations
