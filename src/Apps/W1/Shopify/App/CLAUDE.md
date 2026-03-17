# Shopify Connector

Bidirectional sync between Shopify stores and Business Central. Imports orders, customers, and companies from Shopify; exports products, inventory, and shipments to Shopify. All API communication uses Shopify's GraphQL Admin API, not REST. The connector supports multiple Shopify stores per BC company, each configured independently through the Shpfy Shop table (30102).

## Quick reference

- **ID range**: 30100--30460
- **Dependencies**: none (zero entries in `app.json`)

## How it works

Everything flows through the Shop record. Each Shop represents one Shopify store connection and carries 60+ configuration fields that control sync direction, customer mapping strategy, product status rules, inventory calculation method, return/refund processing, and more. The Shop is the god object -- nearly every codeunit takes a Shop record as its entry point, and most design decisions are Shop-level settings rather than per-entity configuration.

The sync model is asymmetric by design. Products flow primarily BC-to-Shopify (items are the source of truth), while orders flow Shopify-to-BC (Shopify is the order capture system). Customer sync supports both directions but import is automatic while export requires manual "Add to Shopify" actions. Inventory is export-only: BC calculates stock using a pluggable strategy interface and pushes adjustments to Shopify locations.

All Shopify API calls are GraphQL, encapsulated through the `Shpfy IGraphQL` interface. The `ShpfyGraphQLType` enum (30111) defines 143 query types, each implemented by a dedicated `Shpfy GQL *` codeunit. The `ShpfyGraphQLQueries` codeunit (30154) resolves enum values to query text via interface dispatch, with template parameter replacement (`{{param}}`). This design means you can override any GraphQL query by subscribing to events on `ShpfyGraphQLQueries` without touching the original codeunit.

The connector does not attempt real-time sync. It uses batch pulls (cursor-based pagination over GraphQL connections) and optional webhooks for order notifications. There is no message queue, no retry infrastructure beyond the standard BC job queue, and no conflict resolution beyond hash-based detection that flags orders for manual review.

## Structure

- `src/Base/` -- Shop table, installer, shared enums, cue/activities for role centers
- `src/GraphQL/` -- IGraphQL interface, 143 GQL codeunits (one per query), rate limiter
- `src/Products/` -- Product/Variant tables, import/export codeunits, price calculation
- `src/Order handling/` -- Order header/line tables, import, mapping, create sales document
- `src/Order Fulfillments/` -- Fulfillment orders (modern per-location API) and actual shipments
- `src/Order Returns/` and `src/Order Refunds/` -- Separate return and refund models
- `src/Order Return Refund Processing/` -- IReturnRefundProcess interface and strategy implementations
- `src/Customers/` -- Customer table, mapping interfaces (email/phone, bill-to, default)
- `src/Companies/` -- B2B company and company location tables, separate mapping strategies
- `src/Inventory/` -- Shop locations, stock calculation interfaces, inventory sync
- `src/Transactions/` -- Payment transactions and gateway mappings
- `src/Payments/` -- Payouts for bank reconciliation
- `src/Gift Cards/` -- Gift card tracking (product when sold, payment method when redeemed)
- `src/Metafields/` -- Typed custom fields with namespace and owner-type polymorphism
- `src/Document Links/` -- N:M junction between Shopify documents and BC documents
- `src/Logs/` -- Data capture (raw JSON), skipped records, communication events
- `src/Bulk Operations/` -- Bulk mutation support for high-volume price updates
- `src/Catalogs/` -- B2B catalog and market-specific pricing
- `src/Webhooks/` -- Webhook subscription management for order notifications

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- Products link to BC Items via `Item SystemId` (a Guid), not Item No. This survives item renumbering. The `Item No.` field on the Product table is a FlowField that looks up through SystemId.
- The Variant table (30129) has three pairs of option name/value fields (`Option 1 Name`/`Option 1 Value` through 3). Shopify's 3-option limit is a hard constraint reflected in the schema.
- Order import always creates the header first, then retrieves and inserts lines, related records (tax, shipping, transactions, fulfillment orders, returns, refunds), and finally adjusts line quantities for refunds. The sequence matters because refund line quantities are subtracted from order line quantities in place.
- The `Line Items Redundancy Code` on the order header is a hash of concatenated line IDs. It is used for conflict detection when re-importing an already-processed order -- if the hash changes, the order is flagged as conflicting.
- Customer mapping uses interface dispatch: the Shop's `Customer Mapping Type` enum selects which `ICustomerMapping` implementation runs. But there is a fallback -- if both Name and Name2 are empty, it always falls back to "By EMail/Phone" regardless of the setting.
- `Shpfy Data Capture` (30114) stores raw JSON blobs linked to any record via table ID and SystemId. This is the primary debugging tool -- when something goes wrong with an import, look at the captured JSON.
- The `Shpfy Skipped Record` table (30159) logs every record the connector deliberately skipped during sync, with a reason. Check this before assuming a sync bug.
- Negative IDs on `Shpfy Customer Address` indicate addresses created by BC (not imported from Shopify). This convention prevents ID collisions.
- The `Return and Refund Process` field on the Shop controls whether returns and refunds are imported at all, and whether credit memos are auto-created. The `IReturnRefundProcess` interface routes to different implementations based on this enum.
- Bulk operations (used for price-only sync) attempt to use Shopify's bulk mutation API first, then fall back to individual GraphQL calls if the bulk operation fails.
