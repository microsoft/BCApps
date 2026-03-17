# Shopify Connector

The Shopify Connector synchronizes products, customers, orders, inventory, and payments between Shopify online stores and Business Central. It is the bridge that lets merchants manage their e-commerce operations from within BC -- importing Shopify orders as sales documents, pushing BC inventory levels to Shopify, and keeping customer records in sync across both systems. The connector supports multiple Shopify shops per BC company, multi-currency, B2B (company) sales, and multi-location fulfillment.

## Quick reference

- **ID range**: 30100--30460
- **API version**: Shopify Admin API 2026-01 (GraphQL only, set in `ShpfyCommunicationMgt.Codeunit.al`)
- **Entry point**: The `Shpfy Shop` table (30102) is the god object -- nearly every setting lives there

## How it works

All Shopify API communication flows through a single codeunit, `ShpfyCommunicationMgt` (30103). It is a `SingleInstance` codeunit that holds the current shop context, builds authenticated GraphQL requests, handles retries for HTTP 429/5xx errors, and enforces rate limiting via `ShpfyGraphQLRateLimit` (30153). Every GraphQL query or mutation in the connector is wrapped in its own codeunit under the `GraphQL/Codeunits/` folder -- there are roughly 100+ of them, each implementing the `Shpfy IGraphQL` interface to provide the query text and expected cost.

Syncs are orchestrated by `ShpfyBackgroundSyncs` (30101), which enqueues BC Job Queue entries for each sync type (products, customers, companies, orders, inventory, payments, disputes). If a shop has "Allow Background Syncs" enabled, the sync runs as a background job; otherwise it runs inline. Each sync type is implemented as a Report object (e.g., `Shpfy Sync Products`, `Shpfy Sync Orders from Shopify`) that iterates over shops and delegates to domain-specific codeunits.

The connector is heavily extensible via interfaces and events. Business logic that varies by configuration -- customer mapping strategy, stock calculation method, product status on creation, return/refund processing -- is implemented through enums that implement interfaces. The Shop table's option fields select which strategy to use at runtime. Domain-specific event codeunits (`ShpfyProductEvents`, `ShpfyOrderEvents`, `ShpfyCustomerEvents`, `ShpfyInventoryEvents`) expose `OnBefore*`/`OnAfter*` integration events with an `IsHandled` pattern that lets subscribers override default behavior without modifying the connector.

The connector does not sync everything bidirectionally. Products and customers can flow both directions (controlled by Shop settings), but orders are Shopify-to-BC only, and inventory is BC-to-Shopify only. Payments, payouts, and disputes are read-only imports from Shopify. Returns and refunds can optionally create BC credit memos automatically.

## Structure

- `Base/` -- Shop table, communication layer, background sync orchestration, tags, installer
- `Products/` -- Product/variant sync, mapping, price calculation, image handling
- `Customers/` -- Customer sync, mapping strategies (by email/phone, bill-to, default), name formatting
- `Companies/` -- B2B company sync, company-location mapping, tax ID handling
- `Order handling/` -- Order import pipeline (Orders to Import -> Order Header -> Sales Document), line creation, table extensions on Sales Header/Line
- `Order Fulfillments/` -- Fulfillment creation and tracking, fulfillment service integration
- `Order Returns/` -- Return import from Shopify
- `Order Refunds/` -- Refund line import, restocking logic
- `Order Return Refund Processing/` -- Credit memo creation, document source interfaces
- `Order Risks/` -- Risk level assessment for imported orders
- `Inventory/` -- Stock calculation, inventory sync to Shopify locations
- `Payments/` -- Payout and payment transaction import
- `Transactions/` -- Transaction details import
- `GraphQL/` -- 100+ codeunits wrapping individual queries/mutations, rate limiting, query builder
- `Bulk Operations/` -- Async bulk mutation support (prices, images) with webhook-based status polling
- `Catalogs/` -- B2B catalog and market-specific pricing
- `Metafields/` -- Polymorphic metafield sync with type-driven validation
- `Translations/` -- Multi-language product translation sync
- `Webhooks/` -- Order created and bulk operation webhooks
- `Helpers/` -- JSON helpers, hash calculation, utility functions

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The Shop table is the god object. Almost every sync behavior, mapping strategy, template, GL account, and feature toggle is a field on `Shpfy Shop` (30102). When you need to understand why something behaves a certain way, start there.

- Orders flow through three tables: `Shpfy Orders to Import` (30121) is a lightweight staging table populated during the initial order scan. Selected orders get imported into `Shpfy Order Header` (30118) with full details. Finally, `Shpfy Order Header` records are processed into BC Sales Orders or Sales Invoices. These are separate tables, not status fields on a single table.

- The API version (`VersionTok` in `ShpfyCommunicationMgt`) is checked against an expiry date stored in Azure Key Vault. If the version expires, all API calls are blocked with a hard error. On-prem installations bypass this check and get a rolling +1 month grace period.

- All GraphQL queries have an expected cost declared in their `GetExpectedCost()` method. The rate limiter uses this to preemptively wait before sending requests that would exceed the available token bucket, rather than always hitting 429s and retrying.

- The `Allow Outgoing Requests` field on the Shop controls whether the connector can write data to Shopify. It defaults to true, but when false, only read queries (not mutations) are permitted. This is a safety mechanism, not an auth boundary.

- Hash-based change detection is used throughout the product sync. Product descriptions, images, tags, and variant data are hashed and compared before syncing. This avoids unnecessary API calls when nothing has changed.

- B2B support (companies, catalogs, catalog-specific pricing) requires a Shopify Plus plan. The connector auto-detects this by querying the shop plan during `GetShopSettings()` and sets `B2B Enabled` accordingly.

- Bulk operations (via `Shpfy IBulk Operation` interface) are used for price syncs and image updates where the number of mutations would exceed practical limits. They are async -- the connector submits a JSONL payload, Shopify processes it, and a webhook notifies BC when it completes.

- The connector extends several standard BC tables -- Sales Header, Sales Line, Sales Invoice Header/Line, Sales Shipment Header/Line, Return Receipt Header/Line, Sales Cr.Memo Header/Line, Cust. Ledger Entry, Gen. Journal Line, Shipping Agent, Item Attribute -- adding Shopify-specific fields like Order Id, Fulfillment Id, and Transaction Id.

- Two fulfillment models coexist: the legacy `Order Fulfillment` table and the modern `Fulfillment Order` model (multi-location aware). The modern model uses fulfillment orders assigned to specific locations, while the legacy model tracks fulfillments directly on the order.
