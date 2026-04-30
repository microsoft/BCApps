# Catalogs

Manages Shopify catalogs -- both B2B company catalogs (per-company price lists) and market catalogs (per-market pricing). Each catalog has its own price list in Shopify, and this module syncs BC-calculated prices into those price lists.

## How it works

There are two catalog types: Company and Market. Company catalogs are tied to a Shopify Company via `Company SystemId` and are created automatically when setting up B2B companies. Market catalogs are linked to Shopify markets through the `Shpfy Market Catalog Relation` table. The `ShpfyCatalogAPI` codeunit handles CRUD operations -- creating catalogs with associated publications and price lists, and importing existing catalogs from Shopify.

Price sync is driven by `ShpfySyncCatalogPrices`. For each catalog with `Sync Prices` enabled, it fetches current Shopify prices via the catalog's price list, then recalculates prices using BC's `Shpfy Product Price Calc.` with the catalog's Customer Price Group, Customer Discount Group, and posting groups. Changed prices are pushed back in batches of 250 via the `UpdateCatalogPrices` GraphQL mutation. The `Shpfy Catalog Price` table is temporary -- used only during sync to compare current vs. calculated values.

The `Shpfy Catalog` table carries full pricing context: Customer Price Group, Customer Discount Group, Gen. Bus. Posting Group, VAT settings, and an optional Customer No. that overrides catalog-level settings with the customer's own price/discount groups.

## Things to know

- `Shpfy Catalog Price` is a temporary table -- it holds the Shopify-side prices just long enough to diff against BC calculations during sync.
- If a catalog's currency code does not match what Shopify reports, the sync is skipped and a skipped record is logged.
- Company catalogs get their own publication and price list created automatically via separate GraphQL calls.
- Market catalogs track which Shopify markets they serve through `Shpfy Market Catalog Relation`, which is refreshed on every import.
- Price updates are batched at 250 variants per GraphQL call to stay within Shopify limits.
- The catalog URL construction differs between unified and non-unified Shopify markets.
