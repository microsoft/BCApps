# Base

Foundational infrastructure for the Shopify Connector: the shop configuration hub, HTTP communication, installation, synchronization orchestration, and shared primitives used across all other modules.

## How it works

The `Shpfy Shop` table (30102) is the central configuration record. Almost every setting -- customer mapping type, name sources, sync directions, logging mode, default customer, item templates, currency -- lives as a field on this table. Other modules receive a Shop record and read their configuration from it rather than maintaining their own settings tables.

`ShpfyCommunicationMgt` is the single HTTP gateway to Shopify's Admin API. It is a `SingleInstance` codeunit that constructs URLs from `Shop."Shopify URL"` + the API version (a `Label` constant, currently `2026-01`), manages OAuth authentication, executes GraphQL queries (delegating query text resolution to `ShpfyGraphQLQueries` in the GraphQL module), and handles response parsing, logging, and retry. It also enforces API version expiry by checking against a Key Vault secret.

Synchronization timing is tracked per shop per entity type in `ShpfySynchronizationInfo` (keyed on shop code + `SynchronizationType` enum: Products, Orders, Customers, Companies). Each sync writes its start time via `Shop.SetLastSyncTime` and reads it back on the next run to do delta queries. `ShpfyBackgroundSyncs` orchestrates all sync jobs -- products, orders, customers, companies, inventory, payouts, images -- by constructing XML parameters and enqueuing `Job Queue Entry` records.

`ShpfyInstaller` runs on app install to register retention policies for log entries, data captures, and skipped records (all defaulting to 1-month retention, disabled), and sets up cue thresholds. It also subscribes to company-copy and environment-cleanup events to auto-disable shops in non-production environments.

## Things to know

- `ShpfyTag` uses a generic `Parent Table No.` + `Parent Id` pattern so the same tag table serves customers, products, orders, and any future entity. Maximum 250 tags per parent, enforced in `OnInsert`.
- `ShpfyFilterMgt.CleanFilterValue` escapes AL filter metacharacters (`(`, `)`, `*`, `.`, `<`, `>`, `=`) with `?` wildcards and prepends `@` for case-insensitive matching. This is used throughout the connector when building record filters from Shopify data.
- `ShpfyInitialImportLine` tracks the wizard-driven first-time import with job queue integration. It shifts `Job Queue Entry.Status` option values by +1 to accommodate a leading blank state.
- The `LoggingMode` enum has three values: `Error Only` (default), `All`, and `Disabled`. This controls what `ShpfyCommunicationMgt` logs to the `Shpfy Log Entry` table.
- `ShpfyBackgroundSyncs` splits each sync into two passes: one for shops with `"Allow Background Syncs" = true` (enqueued as job queue entries) and one for shops with it false (run inline via `Report.Execute`).
- The `MappingDirection` enum (`ShopifyToBC`, `BCToShopify`) is consumed by customer and company mapping to determine which direction a find-mapping operation is running.
