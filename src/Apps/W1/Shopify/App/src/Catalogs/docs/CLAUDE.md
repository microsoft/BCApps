# Catalogs

Manages B2B and market-specific pricing through Shopify catalogs. Each catalog contains a full BC price calculation setup (customer price group, discount group, VAT posting groups) that determines how prices are calculated and synced to Shopify price lists.

## How it works

`Shpfy Catalog` (30152) holds the catalog's pricing configuration: Customer Price Group, Customer Discount Group, Gen. Bus. Posting Group, VAT Bus. Posting Group, Tax Area Code, Prices Including VAT, and optionally a Customer No. whose settings take precedence. Catalogs link to Shopify companies via `Company SystemId` and can be typed as B2B or Market catalogs via the `Shpfy Catalog Type` enum.

`Shpfy Catalog Price` (30153) is a **temporary table** (`TableType = Temporary`) used only during sync to hold calculated variant prices in memory before submitting them to Shopify. It carries Variant Id, Price List Id, Price, Compare at Price, and Price List Currency.

`Shpfy Market Catalog Relation` links catalogs to Shopify markets for multi-market pricing. The `Shpfy Sync Catalog Prices` report orchestrates the price sync, while `ShpfyCatalogAPI` handles GraphQL communication. The `Shpfy Sync Catalogs` report imports catalog definitions from Shopify.

## Things to know

- The `Shpfy Catalog Price` table is temporary -- it exists only in memory during a sync run. Prices are calculated in BC, held in this table, then pushed to Shopify as bulk mutations. No catalog prices are persisted in BC.
- When a `Customer No.` is set on the catalog, it overrides the catalog's own `Customer Discount Group`, `Customer Price Group`, and `Allow Line Disc.` settings with the customer's values.
- Catalogs require Shopify Plus (B2B support). The connector auto-detects plan eligibility during shop settings retrieval.
- The primary key on `Shpfy Catalog` is (Id, Company SystemId), meaning the same Shopify catalog ID can appear multiple times when associated with different companies.
- Deleting a catalog cascades to remove all its `Shpfy Market Catalog Relation` records.
