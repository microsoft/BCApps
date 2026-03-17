# Base

Base is the foundational infrastructure layer of the Shopify Connector. It owns the Shop configuration table (the "god object" that every other module depends on), the HTTP communication layer for all Shopify API calls, the background sync orchestration, the polymorphic Tag system, and the installation/upgrade machinery. No business-domain sync logic lives here -- this module provides the platform that Products, Orders, Customers, and other modules build on.

## How it works

The `Shpfy Shop` table (`ShpfyShop.Table.al`) is the central configuration record. It stores the Shopify URL, authentication state, and dozens of behavioral settings: sync directions for items/customers, SKU mapping strategy, customer mapping type, name source interfaces, currency handling mode, inventory policy defaults, and account mappings for shipping charges, tips, gift cards, and cash rounding. Nearly every codeunit in the connector accepts a Shop record or Shop Code and reads its settings to control behavior. The Shop table also tracks last sync times per synchronization type via the `Shpfy Synchronization Info` table.

`ShpfyCommunicationMgt.Codeunit.al` is the single point of contact for all Shopify API communication. It is a `SingleInstance` codeunit that constructs URLs (including the API version, currently `2026-01`), executes GraphQL queries with parameter substitution, handles rate limiting by tracking `NextExecutionTime`, and validates that the API version has not expired via Azure Key Vault lookup. Every API call in every module routes through this codeunit's `ExecuteGraphQL` method. It also fires `CommunicationEvents` that enable test mocking by intercepting requests before they reach Shopify.

`ShpfyBackgroundSyncs.Codeunit.al` is the orchestrator for all sync operations. It provides typed methods for each sync domain (CustomerSync, ProductsSync, OrderSync, InventorySync, PayoutsSync, ProductImagesSync, etc.). Each method constructs XML report parameters, checks whether background execution is allowed, and either enqueues a Job Queue Entry or runs the report synchronously. The background/foreground decision is per-shop via the `Allow Background Syncs` flag.

The `Shpfy Tag` table is a polymorphic store used by Products, Orders, and Customers. It is keyed by `(Parent Id, Tag)` with a `Parent Table No.` field that identifies which entity type owns the tag. The `UpdateTags` procedure replaces all tags for a parent by deleting existing ones and re-inserting from a comma-separated string. A hard limit of 250 tags per parent is enforced on insert.

## Things to know

- The Shop table has over 100 fields spanning configuration for every module. When reading code in other modules that accesses `Shop."Some Setting"`, the field definition is almost certainly in `ShpfyShop.Table.al`. The Shop table also uses many enum fields backed by interfaces (e.g., `Customer Mapping Type`, `Name Source`, `County Source`, `Status for Created Products`, `Action for Removed Products`), making it the dispatch point for all strategy patterns.

- `CommunicationMgt` enforces Shopify's rate limits by sleeping until `NextExecutionTime` before each request. If a GraphQL response indicates throttling, it logs telemetry and retries. The query parameter length is capped at 50,000 characters with a specific error for product creation (which can exceed this due to marketing text or embedded images).

- The `Shpfy Initial Import` wizard (`ShpfyInitialImport.Page.al` + `ShpfyInitialImport.Codeunit.al`) provides a guided first-time setup that imports countries, customers, products, and images in sequence. It uses `ShpfyInitialImportLine.Table.al` to track which steps have completed.

- `ShpfyInstaller.Codeunit.al` handles first-time installation by registering guided experience items and the Shopify checklist. `ShpfyUpgradeMgt.Codeunit.al` runs data migrations between versions, typically moving data from obsoleted fields to their replacements.

- The `Shpfy Cue` table powers the Role Center activity tiles showing counts of unmapped products, orders with errors, etc. The `Shpfy Synchronization Info` table stores per-shop, per-sync-type timestamps to implement incremental synchronization.

- `ShpfyFilterMgt.Codeunit.al` provides utility functions for building filter strings from Shopify data, used across modules when constructing table views.

- The page extensions on Business Manager, Order Processor, and Sales Relationship Manager Role Centers (`ShpfyBusinessManagerRC`, `ShpfyOrderProcessorRC`, `ShpfySalesRelMgrRC`) embed the Shopify Activities part to surface sync status directly in the user's home page.
