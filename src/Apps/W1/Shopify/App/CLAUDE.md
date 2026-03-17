# Shopify Connector

The Shopify Connector provides bidirectional synchronization between Shopify stores and Business Central. It imports orders, products, customers, and companies from Shopify, converts them into BC sales documents, and pushes inventory levels, product updates, and shipment fulfillments back. It uses the Shopify GraphQL Admin API exclusively -- there is no REST API usage.

## Quick reference

- **ID range**: 30100--30460
- **Dependencies**: None (zero-dependency app, only references the BC base application)

## How it works

Everything flows through the **Shop table** (`Shpfy Shop`, table 30102). This is the god object -- a single record controls which direction products sync, how customers map, whether orders auto-create, what currency model to use, which GL accounts receive tips and gift cards, and dozens more settings. Every sync operation starts by reading its Shop record and branching on its configuration fields.

The core sync loop is timestamp-based. The connector fetches ID+UpdatedAt pairs from Shopify via GraphQL, compares them against stored `Updated At` and `Last Updated by BC` timestamps, and only processes records that changed since the last sync. The `Last Updated by BC` field prevents ping-pong: when BC pushes an update to Shopify, it stamps this field so the next import cycle skips the record Shopify just confirmed. Each entity domain (products, customers, companies, orders) follows this same pattern.

Records that need importing are collected into a **temporary record set**, then processed one at a time inside a `Commit(); ClearLastError(); if not Codeunit.Run() then ...` loop. This isolates failures per record -- if one product fails to import, the error is captured and the loop continues. The Commit before Run ensures prior successful work is saved. This is the connector's primary error isolation strategy.

The connector links Shopify entities to BC records using **SystemId (GUID) fields** rather than Code fields. For example, `Shpfy Product."Item SystemId"` points to the Item's SystemId, and a CalcFormula FlowField derives the readable Item No. This means renumbering items in BC does not break the link. The same pattern applies to customers, companies, and variants.

The connector does NOT run Shopify operations in real-time from BC UI transactions. All syncs are batch operations, typically run via Job Queue entries through the `Shpfy Background Syncs` codeunit. It does not support real-time webhooks for all entity types -- only order creation and bulk operations have webhook support.

## Structure

- **Base/** -- Shop table (the config god object), background sync orchestration, communication layer, hashing, tags, cue table
- **GraphQL/** -- IGraphQL interface and 145+ query/mutation codeunits, rate limit management, query registry
- **Products/** -- Product/variant tables, import/export/sync codeunits, product events, SKU mapping, image sync
- **Customers/** -- Customer/address tables, customer mapping interfaces (by email, phone, name+address), sync and export
- **Companies/** -- B2B company/location tables, company mapping interfaces, tax registration ID mapping
- **Order handling/** -- Order header/line tables, order import from Shopify, order-to-sales-document processing, order mapping
- **Order Fulfillments/** -- Fulfillment order/line tables, shipment export to Shopify
- **Order Returns/** -- Return header/line tables imported from Shopify
- **Order Refunds/** -- Refund header/line tables, refund shipping lines
- **Order Return Refund Processing/** -- IReturnRefundProcess interface, credit memo auto-creation from refunds
- **Inventory/** -- Shop location mapping, stock calculation interfaces, inventory sync to Shopify
- **Payments/** -- Payout, dispute, and payment terms tables
- **Transactions/** -- Order transaction tables, payment method mapping, credit card companies
- **Metafields/** -- Generic metafield table with IMetafieldType and IMetafieldOwnerType interfaces
- **Catalogs/** -- B2B catalog/price list tables for company-specific pricing
- **Bulk Operations/** -- Async bulk operation support with webhook callbacks
- **Document Links/** -- Shpfy Doc. Link To Doc. table connecting Shopify documents to BC documents
- **Shipping/** -- Shipment method mapping, shipping charges, shipping events
- **Translations/** -- Language/translation tables for multi-language product sync
- **Webhooks/** -- Webhook subscription management for order creation and bulk operations

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The Shop table has ~100+ fields and controls ALL sync behavior. When debugging, always start there.
- Every monetary field in the order hierarchy exists in TWO versions: shop currency (e.g. `Total Amount`) and presentment currency (e.g. `Presentment Total Amount`). The `Currency Handling` field on Shop determines which set feeds into BC sales documents.
- Shopify IDs are `BigInteger` everywhere. New metafields created locally get negative IDs (starting at -1, decrementing) until Shopify assigns real IDs.
- The `Shpfy Tag` table is a generic many-to-many using `Parent Table No.` + `Parent Id` -- shared by products, orders, and customers. Maximum 250 tags per entity, enforced in the OnInsert trigger.
- The `Shpfy Doc. Link To Doc.` table is the central place linking Shopify documents (orders, refunds) to BC documents (sales orders, credit memos). Check `Is Processed` FlowFields on refund/order headers -- they CalcFormula against this table.
- `Order Created Webhooks` on the Shop table enables push-based order notification, but it requires a specific user context (`Order Created Webhook User Id`). If the user is deleted, the webhook silently stops working.
- The `Fulfillment Service Activated` field on Shop enables BC as a Shopify fulfillment service, which means Shopify sends fulfillment requests TO BC rather than BC polling for them.
- Product sync direction is controlled by `Sync Item` (To Shopify / From Shopify). Setting it to "To Shopify" runs `ProductExport`; "From Shopify" runs `ProductImport`. They never run both directions in one sync.
- The app uses `internal` access on almost all procedures and events. Extensions must subscribe to `[IntegrationEvent]` publishers (not `[InternalEvent]`). Check the event attribute before assuming you can subscribe from an external app.
- The `Return and Refund Process` field controls whether refunds are import-only or auto-create credit memos. Auto-creating credit memos requires `Auto Create Orders` to be enabled -- this is enforced bidirectionally in field validation triggers.
