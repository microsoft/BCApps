# Shopify Connector

The Shopify Connector synchronizes products, customers, orders, inventory, and fulfillments between Shopify stores and Business Central. It is a zero-dependency first-party app that maps Shopify's e-commerce domain model onto BC's sales and inventory domain, handling the impedance mismatch between Shopify's GraphQL API and BC's relational tables. Think of it as a bidirectional bridge where the Shop table is the control panel and each sync direction is independently configurable.

## Quick reference

- **ID range**: 30100--30460
- **API version**: 2026-01 (pinned in CommunicationMgt)
- **Namespace**: Microsoft.Integration.Shopify

## How it works

The app's core loop is: poll Shopify for changes since last sync, import them into staging tables, then map them to BC entities. The reverse direction (BC to Shopify) works the same way but in the opposite direction. Each sync type -- products, customers, inventory, orders, companies -- is an independent codeunit triggered either manually, by job queue, or by webhook. The Shop table stores a per-sync-type "last sync time" that drives incremental fetches. Order sync is special: its last-sync key is the Shop Id (an integer hash) rather than the Shop Code, which matters in multi-company setups where the same Shopify store is connected to multiple BC companies.

All communication with Shopify goes through `Shpfy Communication Mgt.` (codeunit 30103), a SingleInstance codeunit that owns the HTTP client, API versioning, and rate limiting. Every GraphQL query is encapsulated in its own codeunit implementing the `Shpfy IGraphQL` interface, which returns the query text and its expected cost. The GraphQL module alone accounts for roughly 145 codeunits -- about 25% of all files -- because each query variant (initial fetch, pagination, mutation) gets its own implementation. This looks like overkill but makes rate-limit cost tracking precise and keeps query strings out of business logic.

Entity linking between Shopify and BC is always done via SystemId (Guid), never by Code or No. The Shopify Customer, Product, Variant, and Company tables each carry a "Customer SystemId" or "Item SystemId" field, and the corresponding "Customer No." or "Item No." is a FlowField that looks up through that Guid. This means renumbering BC entities does not break the link. The app does not own any BC master data -- it creates and links to it, but never modifies it outside of the fields it controls.

The app deliberately does not handle payment capture, Shopify POS, multi-location inventory routing, or complex discount rule authoring. It imports what Shopify provides and maps it to BC's sales document model. Pricing export to Shopify is supported (including B2B catalog pricing), but discount rules are Shopify-side only.

## Structure

- `Base/` -- Shop table, CommunicationMgt, authentication, and the shared helpers (JsonHelper, Hash, events)
- `GraphQL/` -- One codeunit per query implementing IGraphQL; the rate limiter; the query dispatcher
- `Products/` -- Product/Variant/InventoryItem tables, sync codeunits for import and export, image sync
- `Customers/` -- Customer table with addresses, mapping strategy interfaces (by email, phone, bill-to, etc.)
- `Companies/` -- B2B company and company location tables, mapping interfaces, tax ID handling
- `Catalogs/` -- Per-company pricing catalogs for B2B, linked to Shopify price lists
- `Order handling/` -- OrderHeader, OrderLine, order import/mapping/processing pipeline, order events
- `Order Fulfillments/` -- Two parallel table hierarchies: FulfillmentOrderHeader (intent) and OrderFulfillment (actual shipment)
- `Order Returns/` -- Return headers and lines (customer intent to return)
- `Order Refunds/` -- Refund headers and lines (money movement, may or may not have a return)
- `Order Return Refund Processing/` -- Interface-based processing strategies (import only vs. auto credit memo)
- `Inventory/` -- Stock calculation interfaces, location mapping, sync codeunit
- `Transactions/` -- Order transactions, payment method mapping, gateway tracking
- `Payments/` -- Payouts, payment transactions, disputes, payment terms
- `Webhooks/` -- Webhook subscription management, notification handler (multi-company aware)
- `Bulk Operations/` -- Async bulk mutation support (product images, prices) via Shopify's bulk API
- `Metafields/` -- Generic metafield storage keyed by owner type and owner id
- `Document Links/` -- Traceability table linking Shopify documents to BC documents with interface-based navigation

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The Shop table (`Shpfy Shop`, 30102) is the god object. Nearly every sync codeunit starts by reading it. It controls sync direction, mapping strategy, currency handling, template codes, auto-creation flags, and webhook state. If something behaves unexpectedly, check the Shop settings first.

- Orders carry dual currency: `Currency Code` (shop currency) and `Presentment Currency Code` (what the buyer saw). The `Currency Handling` enum on the Shop table determines which one is used when creating BC sales documents. Every monetary field on orders, refunds, and returns has a presentment counterpart.

- Returns and refunds are separate concepts with separate tables. A Return is a customer's intent to send items back (with decline reason, restock type). A Refund is a financial reversal (with refund lines referencing specific order lines). They may be linked by `Return Id` on the refund, but a refund can exist without a return and vice versa.

- Fulfillment has two parallel systems: `Shpfy FulFillment Order Header/Line` represents Shopify's "fulfillment orders" (the intent to fulfill from a location), while `Shpfy Order Fulfillment` and `Shpfy Fulfillment Line` represent actual shipments with tracking numbers. The connector exports from BC shipments to Shopify fulfillments, not fulfillment orders.

- Hash-based change detection on products (`Image Hash`, `Tags Hash`, `Description Html Hash` on the Product table) avoids re-syncing unchanged data. These are integer hashes, not cryptographic -- used purely for "did it change?" checks.

- Negative auto-incrementing IDs are used for pre-sync staging records. The `Shpfy Orders to Import` table and similar staging constructs use negative BigInteger IDs that are replaced with real Shopify IDs after the API call succeeds.

- The `Shpfy Communication Mgt.` codeunit is SingleInstance and manages rate limiting via `Shpfy GraphQL Rate Limit`. Each IGraphQL implementation declares its expected cost, and the rate limiter uses Shopify's `currentlyAvailable` and `restoreRate` response fields to calculate wait times. If you add a new query, you must provide an accurate `GetExpectedCost()` or you risk throttling.

- Webhooks are multi-company aware. The `Shpfy Webhook Notification` codeunit (30363) receives notifications via BC's webhook infrastructure and iterates all companies that have a matching enabled Shop, scheduling tasks via TaskScheduler in each. The webhook subscription is tied to a specific user whose credentials are used for the background task.

- The `Shpfy Doc. Link To Doc.` table provides bidirectional navigation between Shopify entities and BC documents using interface-based dispatch (`IOpenShopifyDocument`, `IOpenBCDocument`). This is how the UI lets you jump from a Shopify order to the corresponding sales order and back.

- B2B support requires Shopify Plus. The Shop table's `B2B Enabled` flag is set by querying Shopify's plan info. B2B orders carry Company Id, Company Location Id, PO Number, and payment terms. Catalogs provide per-company pricing via Shopify price lists.
