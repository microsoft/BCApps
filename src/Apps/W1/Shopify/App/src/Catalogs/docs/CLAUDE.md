# Catalogs

B2B catalog pricing contexts -- not product groupings. Each catalog defines a pricing configuration (Customer Price Group, Customer Discount Group, posting groups, currency, VAT settings) that determines how BC calculates prices for a Shopify B2B company or market.

## How it works

`ShpfyCatalog.Table.al` is the central record, keyed by (Id, Company SystemId). It holds a full pricing context: `Customer Price Group`, `Customer Discount Group`, `Gen. Bus. Posting Group`, `VAT Bus. Posting Group`, `Tax Area Code`, `Customer Posting Group`, plus `Prices Including VAT`, `Allow Line Disc.`, and `Currency Code`. When a `Customer No.` is assigned, its discount and price group settings take precedence over the catalog-level settings.

`ShpfySyncCatalogPrices.Codeunit.al` drives the price sync. It iterates all catalogs with `Sync Prices = true`, retrieves existing Shopify prices into a temporary `Shpfy Catalog Price` table, recalculates each variant's price from BC using `Shpfy Product Price Calc.`, and pushes updates back via GraphQL in batches of 250 variants. The `Shpfy Catalog Price` table is `TableType = Temporary` -- it exists only during calculation and is never persisted.

The `Shpfy Market Catalog Relation` table links catalogs to Shopify markets, enabling multi-market pricing where different markets can have different catalog configurations.

## Things to know

- The catalog primary key includes `Company SystemId`, meaning the same Shopify catalog Id can appear multiple times if it's associated with different companies (though in practice this reflects B2B company-catalog relationships).
- `Shpfy Catalog Price` is explicitly `TableType = Temporary`. If you see code reading from it, it was populated earlier in the same process -- there is no persistent price cache.
- The `Catalog Type` enum (`ShpfyCatalogType.Enum.al`) distinguishes catalog kinds and can be used to filter sync operations via `SetCatalogType`.
- Price sync respects `Item.Blocked` and `Item."Sales Blocked"` -- blocked items are silently skipped, not errored.
- `ShpfySyncCatalogs.Report.al` and `ShpfySyncCatalogPrices.Report.al` are the user-facing entry points, following the connector's report-as-batch-job pattern.
