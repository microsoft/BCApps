# Shopify Connector

The Shopify Connector synchronizes products, orders, customers, companies, inventory, payments, fulfillments, returns, and refunds between Business Central and Shopify. It treats Shopify as the storefront and BC as the ERP -- orders flow in, products and inventory flow out, and customers are mapped between the two systems. The connector uses Shopify's GraphQL Admin API exclusively, with interface-based strategy patterns for every configurable behavior.

## Quick reference

- **ID range**: 30100--30460
- **API version**: `2026-01` (hardcoded in `ShpfyCommunicationMgt`, with Azure Key Vault-driven expiry checking)
- **Dependencies**: None (self-contained on the base application platform)

## How it works

The `Shpfy Shop` table (30102) is the god object. Every shop record holds configuration for products, customers, companies, orders, inventory, returns, metafields, and more. Most boolean pairs follow a mutual-exclusion pattern -- "Shopify Can Update Items" disables "Can Update Shopify Products" and vice versa -- which enforces a single source of truth per entity type.

Synchronization runs as background job queue entries or manually from the Shop Card. Each sync type (products, orders, customers, companies, inventory) has its own `Shpfy Sync*` codeunit that orchestrates the flow. Products sync bidirectionally -- import retrieves product IDs from Shopify, skips unchanged ones via `UpdatedAt`/`LastUpdatedByBC` timestamp comparison, and creates or updates BC Items. Export reads the product table filtered to items with a mapped `Item SystemId` and pushes changes back, using bulk operations for large price updates. Orders flow inbound only: a scheduled poll (or webhook) populates `OrdersToImport`, then `ImportOrder` fetches full details via GraphQL and writes `OrderHeader`/`OrderLine`, then `ProcessOrder` maps everything and creates a Sales Order or Sales Invoice in BC.

The connector never syncs directly between BC and Shopify entities. Every Shopify entity is first stored in a connector-owned staging table (Shpfy Product, Shpfy Customer, Shpfy Order Header, etc.), and the connector manages the link between those staging records and BC master data via `SystemId` fields. This two-step approach means the connector can operate with delayed or partial connectivity and provides a full audit trail through `DataCapture` records.

The connector does not manage Shopify store settings, themes, or checkout configuration. It does not handle B2C marketing, analytics, or multi-storefront content management. It does not sync BC purchase orders, production orders, or warehouse documents. Returns and refunds are import-only from Shopify -- BC never pushes return/refund data back.

## Structure

- `src/Base/` -- Shop table, CommunicationMgt, background sync scheduler, installer, upgrade
- `src/Products/` -- Product/Variant/InventoryItem tables, import/export/mapping, price calculation, image sync
- `src/Order handling/` -- OrdersToImport staging, OrderHeader/Line, import, mapping, processing into Sales documents
- `src/Customers/` -- Customer table, mapping strategies (ByEmail, ByBillto, ByDefault), import/export, name formatting
- `src/Companies/` -- B2B company/location tables, mapping strategies, company export
- `src/Inventory/` -- Stock calculation interfaces, location mapping, inventory sync (BC to Shopify only)
- `src/Order Fulfillments/` -- FulfillmentOrderHeader/Line, fulfillment creation, shipping confirmation
- `src/Order Returns/` -- Return header/line, return API
- `src/Order Refunds/` -- Refund header/line, refund shipping lines, refund API
- `src/Order Return Refund Processing/` -- IReturnRefund Process interface, credit memo creation
- `src/Transactions/` -- OrderTransaction, PaymentMethodMapping, gateway/card brand resolution
- `src/Payments/` -- Disputes, payment transactions, payouts (bank deposits)
- `src/Bulk Operations/` -- JSONL-based bulk mutations for large batches (price updates, image updates)
- `src/GraphQL/` -- 130+ GraphQL query codeunits, rate limit management, query builder
- `src/Metafields/` -- Polymorphic metafield storage with type validation
- `src/Catalogs/` -- B2B catalog/price list management
- `src/Logs/` -- LogEntry, DataCapture (audit trail with hash dedup), SkippedRecord
- `src/Document Links/` -- DocLinkToDoc many-to-many between Shopify docs and BC docs

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns

## Things to know

- The Shop table uses a hash-based `Shop Id` derived from the URL, not the Code field, for order sync timing. Orders use `Shop Id` as the `SynchronizationInfo` key so that renaming a shop code doesn't lose sync state.
- `CommunicationMgt` is a SingleInstance codeunit -- it holds the current shop context across the entire session. You must call `SetShop()` before any API call.
- The GraphQL rate limiter (`ShpfyGraphQLRateLimit`) is also SingleInstance. It dynamically calculates wait times from Shopify's `extensions.cost.throttleStatus` response, using `(ExpectedCost - Available) / RestoreRate` to avoid throttling. If throttled anyway, the main loop retries until the `THROTTLED` error clears.
- Bulk operations have a 100-item threshold (`GetBulkOperationThreshold`). Below that, the connector uses individual GraphQL mutations. Above it, it uploads JSONL to Shopify's staged upload URL and runs `bulkOperationRunMutation`.
- New metafield records get negative IDs (starting at -1, decrementing). This prevents collisions with Shopify-assigned IDs before the first sync.
- `DataCapture.Add()` uses hash dedup -- if the hash of the new data matches the last capture for the same record, it skips the insert. This keeps audit trails manageable.
- Every amount field has a dual-currency pair: `"Amount"` (shop currency) and `"Presentment Amount"` (customer-facing currency). The Shop's `"Currency Handling"` setting determines which one feeds into BC Sales documents.
- The `ProcessOrders` codeunit does `Commit()` between each order so that one failed order doesn't roll back the entire batch. On failure, it cleans up the partially created Sales document via `CleanUpLastCreatedDocument()`.
- Order conflict detection uses `LineItemsRedundancyCode` -- a hash of all line IDs. If a re-imported order has different line IDs or quantities than the already-processed version, it flags the order as conflicting rather than silently overwriting.
- The connector uses `#region` / `#endregion` to organize the three address blocks (Sell-to, Ship-to, Bill-to) in `ShpfyImportOrder`, which is unusual for AL code but makes the 900+ line codeunit navigable.
