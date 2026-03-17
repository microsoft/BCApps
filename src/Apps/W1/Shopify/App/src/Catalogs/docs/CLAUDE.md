# Catalogs

B2B catalog management -- links Shopify catalogs (both company and market types) to BC pricing parameters so per-catalog variant prices can be synced.

## How it works

`ShpfyCatalog.Table.al` stores catalogs with a composite key of `(Id, Company SystemId)`. Each catalog carries its own pricing configuration: customer price group, customer discount group, posting groups, VAT settings, tax area, and an optional `Customer No.` whose pricing settings take precedence over catalog-level settings. Catalogs come in two types via `ShpfyCatalogType`: Company catalogs are tied to a specific Shopify company, while Market catalogs apply to geographic markets.

`ShpfyCatalogAPI.Codeunit.al` handles both import and creation. For company catalogs, it queries by company ID and creates new catalogs with an associated publication and price list. For market catalogs, it imports all market-type catalogs and resolves their linked markets into `ShpfyMarketCatalogRelation` records. Price sync works by first fetching the list of products included in a catalog's publication, then retrieving the catalog's price list prices for those products. Prices are compared locally and only changed variants are pushed back via `UpdateCatalogPrices`. The URL generation for catalog admin links handles both unified markets and legacy market structures differently.

## Things to know

- When creating a company catalog, three Shopify resources are created in sequence: the catalog itself, a publication (to make products visible), and a price list (to hold custom prices). Missing any step means the catalog exists but cannot function.
- The catalog currency is validated against Shopify during product sync in `ExtractShopifyCatalogProducts` -- a mismatch between the local `Currency Code` and Shopify's `priceList.currency` causes the sync to be skipped with a logged skipped record telling the user to reimport.
- `CatalogPrice` records use a `Compare at Price` field to support Shopify's "was/now" pricing. The comparison price is cleared (set to null in GraphQL) if it would be less than or equal to the actual price.
- Market catalog relations are fully rebuilt on each sync -- existing relations for a catalog are deleted before re-importing from Shopify.
- The `Sync Prices` boolean on the catalog controls whether the price sync report processes that catalog at all.
