# Shopify Connector

The Shopify Connector bridges Shopify e-commerce with Business Central ERP, bi-directionally synchronizing products, customers, companies, orders, inventory, and fulfillments. It uses Shopify's GraphQL Admin API exclusively -- there is no REST API usage. The connector enables merchants to manage their online storefront from within Business Central, treating Shopify as the storefront and BC as the system of record for inventory, pricing, and financials.

## Quick reference

- **ID range**: 30100--30460
- **Namespace**: Microsoft.Integration.Shopify

## How it works

The Shop table (`ShpfyShop.Table.al`, ID 30102) is the god object. Nearly every configuration setting lives there: sync directions for items/customers/companies, mapping strategies, customer/item template codes, G/L account mappings for shipping/tips/gift cards/refunds, plan-based feature flags, currency handling, webhook settings, and fulfillment service configuration. A single BC company can connect to multiple Shopify shops (each with its own Shop Code), and each shop gets its own set of configuration.

The `"Advanced Shopify Plan"` boolean field (207) on the Shop table gates features that require Plus, Plus Trial, Development, or Advanced plans. `GetShopSettings()` reads the Shopify plan and sets this flag automatically. B2B features (companies, catalogs, company sync) are now unconditionally available on all Shopify plans -- the old `"B2B Enabled"` field (117) has been obsoleted (CLEAN29/CLEANSCHEMA32 guards).

*Updated: 2026-04-08 -- B2B Enabled obsoleted, Advanced Shopify Plan added*

All Shopify API communication goes through GraphQL. The `ShpfyCommunicationMgt.Codeunit.al` is the single entry point for API calls. It constructs URLs using a versioned API path (currently `2026-01`), handles authentication, rate limiting, and retry logic. GraphQL queries are stored as `.graphql` resource files under `.resources/graphql/{Area}/`, loaded at runtime via `NavApp.GetResourceAsText()`. The `ShpfyGraphQLType` enum maps each query to its resource file using `{Area}_{QueryName}` naming, and the dispatcher loads the corresponding file instead of calling interface methods. The `ShpfyGraphQLRateLimit` codeunit (singleton) tracks Shopify's cost-based throttle -- it reads `restoreRate` and `currentlyAvailable` from responses and sleeps before issuing requests that would exceed the budget.

*Updated: 2026-03-24 -- GraphQL resource file refactoring*

Mapping strategies are interface-driven throughout. Customer mapping (`ICustomerMapping`) selects between by-email/phone, by-bill-to, or default-customer strategies. Company mapping (`ICompanyMapping`) can match by email/phone or tax ID. Stock calculation uses `IStockAvailable` and `IStockCalculation` interfaces. Product status on creation, removal actions for blocked items, county resolution, and customer name formatting are all interface-backed enums. The Shop record's enum fields (e.g., `"Customer Mapping Type"`, `"Stock Calculation"`, `"Status for Created Products"`) select which implementation to use at runtime.

Sync is incremental via the Synchronization Info table (`ShpfySynchronizationInfo.Table.al`), which stores the last sync timestamp per shop and sync type. An empty/zero date falls back to a sentinel value of `2004-01-01` (see `GetEmptySyncTime()`). Products use hash-based change detection -- the Product table stores `"Image Hash"`, `"Tags Hash"`, and `"Description Html Hash"` fields, computed via a custom hash algorithm in `ShpfyHash`, to avoid unnecessary API calls when nothing has actually changed.

Records link to BC entities via SystemId (GUID), not Code/No. For example, `Shpfy Product` has an `"Item SystemId"` field linking to BC Items, with `"Item No."` as a FlowField that looks up the human-readable code. This means renumbering items in BC does not break Shopify links. The same pattern applies to variants (`"Item Variant SystemId"`) and customers. B2B support adds companies, company locations, and catalogs with company-specific pricing, all orchestrated through the `src/Companies/` and `src/Catalogs/` modules.

## Structure

- `src/Base/` -- Shop configuration, installer, sync info, tags, communication infrastructure, guided experience
- `src/Products/` -- Product/variant sync (both directions), image sync, collections, price calculation, SKU mapping
- `src/Order handling/` -- Order import from Shopify, customer/item mapping, sales document creation, order attributes
- `src/Customers/` -- Customer sync, mapping strategies (by email/phone, bill-to, default), name formatting, country/province data
- `src/Companies/` -- B2B company and company location management, company mapping strategies, tax ID mapping
- `src/Catalogs/` -- B2B catalog and catalog pricing management
- `src/Inventory/` -- Stock level sync to Shopify, location mapping, stock calculation strategies
- `src/GraphQL/` -- GraphQL dispatcher, rate limiting, query enum; queries live as .graphql resource files in `.resources/graphql/{Area}/`
- `src/Metafields/` -- Extensible custom field system with polymorphic owners and typed values
- `src/Order Fulfillments/` -- Fulfillment order headers/lines and actual fulfillment records
- `src/Order Returns/` -- Return headers and lines from Shopify
- `src/Order Refunds/` -- Refund headers, lines, and shipping lines
- `src/Order Return Refund Processing/` -- Processing strategies (import only, auto-create credit memo) with IReturnRefundProcess interface
- `src/Payments/` -- Payouts and disputes
- `src/Transactions/` -- Order transactions (payment events)
- `src/Gift Cards/` -- Gift card handling
- `src/Document Links/` -- Bidirectional links between Shopify documents and BC documents
- `src/Webhooks/` -- Webhook subscription management and notification processing
- `src/Bulk Operations/` -- Async bulk mutation framework with webhook callback
- `src/Logs/` -- Activity log entries for debugging
- `src/Shipping/` -- Shipping method mapping
- `src/Invoicing/` -- Posted invoice sync
- `src/Helpers/` -- JSON helper, hash algorithm, skipped record tracking

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The Shop table is the god object -- nearly every configuration setting lives there, with over 100 fields controlling sync directions, mapping strategies, account mappings, plan-based feature flags, webhook config, and more. The `"Advanced Shopify Plan"` field gates features requiring Plus/Advanced plans (currently staff members). B2B features are now unconditionally available on all plans.
- All API calls go through GraphQL, never REST. Queries are `.graphql` resource files in `.resources/graphql/{Area}/`, loaded via `NavApp.GetResourceAsText()` and dispatched through the `ShpfyGraphQLType` enum.
- Products use hash-based change detection (`"Image Hash"`, `"Tags Hash"`, `"Description Html Hash"`) via a custom hash algorithm to skip unnecessary API calls when nothing has changed.
- Records link to BC entities via SystemId (GUID), not Code/No. -- FlowFields like `"Item No."` display the human-readable values via CalcFormula lookup. Renumbering BC items does not break Shopify links.
- Orders store every monetary amount in dual currency: shop currency fields (`"Total Amount"`, `"VAT Amount"`) and presentment/customer-facing currency fields (`"Presentment Total Amount"`, `"Presentment VAT Amount"`). The `"Currency Handling"` setting on Shop controls which is used for BC documents.
- Returns and refunds are independent concepts in Shopify's model -- a refund can exist without a return and vice versa. The connector has three processing modes: import only, auto-create credit memo, and manual.
- Fulfillment Orders (requests assigned to a location) are different from Fulfillments (actual shipments). Both have their own header/line tables.
- Negative IDs on records (metafields, addresses) indicate BC-created records not yet synced to Shopify. The OnInsert trigger assigns `Id := -1` (or decrements from the current minimum).
- Webhooks fan out to multiple BC companies -- the `ShpfyWebhookNotification` codeunit iterates all shops matching the webhook's Shopify URL, processing the notification once per shop/company.
- Metafields use a polymorphic owner pattern (`"Parent Table No."` + `"Owner Id"`) to attach to products, variants, customers, or companies. The `IMetafieldOwnerType` interface resolves the table and shop code.
- Gift cards appear as both an order line type (when purchased) and a payment method (when redeemed). They have a dedicated G/L account (`"Sold Gift Card Account"`) on the Shop table.
- Bulk operations use async GraphQL mutations with webhook callback -- `IBulkOperation` implementations provide the mutation, input JSONL, and revert logic for failures.
- The empty sync time sentinel is `2004-01-01` (the `GetEmptySyncTime()` method), not `0DT`. Order sync uses the Shop's `"Shop Id"` hash as the sync key (not the Shop Code) so that multiple BC companies connected to the same Shopify shop share the same sync cursor.
