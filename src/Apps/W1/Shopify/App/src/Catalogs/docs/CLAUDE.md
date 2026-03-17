# Catalogs

B2B and market-based catalog model for per-audience pricing in Shopify.

The `Shpfy Catalog` table (`ShpfyCatalog.Table.al`) represents a Shopify catalog, with `Catalog Type` distinguishing Company catalogs (B2B, linked to a `Shpfy Company` via `Company SystemId`) from Market catalogs (linked to Shopify markets). The table is heavily configured for pricing: it holds Customer Price Group, Customer Discount Group, Gen. Bus. Posting Group, VAT Bus. Posting Group, Tax Area Code, Tax Liable, VAT Country/Region Code, Prices Including VAT, Allow Line Disc., and a Customer No. When a customer number is set, its discount/price group settings take precedence over the catalog-level fields.

`Shpfy Market Catalog Relation` (`ShpfyMarketCatalogRelation.Table.al`) is the junction table between markets and catalogs, keyed by Market Id + Catalog Id. `ShpfyCatalogAPI` fetches these relations via `GetCatalogMarkets` GraphQL queries and rebuilds them on each sync.

Price sync works through `ShpfySyncCatalogPrices.Codeunit.al`. For each catalog with `Sync Prices = true`, it fetches current Shopify prices into the temporary `Shpfy Catalog Price` table, then walks every variant, calculates the BC price using `Shpfy Product Price Calc.`, and batches `UpdateCatalogPrices` GraphQL mutations in groups of 250. The compare-at-price is only sent when it exceeds the actual price; otherwise it is nulled out.

`ShpfyCatalogAPI.Codeunit.al` handles catalog CRUD. Creating a company catalog also creates a publication and a price list in Shopify. Market catalogs are imported via `GetMarketCatalogs`. The API also validates currency consistency -- if the catalog's stored currency doesn't match Shopify's price list currency, the sync is skipped and logged as a skipped record.

The `Shpfy Sync Catalogs` report syncs catalog metadata (both company and market types), while `Shpfy Sync Catalog Prices` handles price export. Both can be scoped by catalog type and, for company catalogs, by company ID.
