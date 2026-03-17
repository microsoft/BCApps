# Shopify Connector

Integrates Dynamics 365 Business Central with Shopify, synchronizing products, orders, customers, companies, inventory, and payments between the two systems.

## Quick reference

- **Tech stack**: AL (Business Central), Shopify Admin GraphQL API (version 2026-01)
- **Entry point(s)**: `App/src/Base/Codeunits/ShpfyCommunicationMgt.Codeunit.al` (API hub), `App/src/Base/Tables/ShpfyShop.Table.al` (shop configuration)
- **Key patterns**: SingleInstance communication codeunit, interface-driven GraphQL queries, enum-based extensibility, event subscribers for customization

## Structure

```
App/
  app.json                  -- App metadata (ID ranges 30100-30460)
  src/
    Base/                   -- Core tables (Shop, Tags, Cue), sync infrastructure, setup wizard
    Integration/            -- OAuth2 authentication against Shopify
    GraphQL/                -- IGraphQL interface, query enum, 145+ query implementations
    Helpers/                -- JSON helper, hash, filter utilities
    Products/               -- Bidirectional product/variant sync with item mapping
    Customers/              -- Customer import/export with configurable mapping
    Companies/              -- B2B company sync (Shopify Plus)
    Catalogs/               -- B2B catalog management
    Order handling/         -- Order import, mapping, and sales document creation
    Order Fulfillments/     -- Shipment tracking and fulfillment service
    Order Refunds/          -- Refund import and processing
    Order Returns/          -- Return request handling
    Order Return Refund Processing/ -- Credit memo auto-creation from returns/refunds
    Order Risks/            -- Fraud risk assessment data
    Inventory/              -- Stock level sync to Shopify locations
    Payments/               -- Payment transaction and payout tracking
    Transactions/           -- Financial transaction records
    Invoicing/              -- Posted invoice sync back to Shopify
    Shipping/               -- Shipping methods and cost mapping
    Gift Cards/             -- Gift card transaction handling
    Translations/           -- Product translation sync
    Metafields/             -- Custom metafield sync for products, customers, companies
    Document Links/         -- Links between BC documents and Shopify entities
    Webhooks/               -- Webhook registration and processing
    Bulk Operations/        -- Async bulk import/export via Shopify Bulk Operations API
    Logs/                   -- Request/response logging with retention policies
    PermissionSets/         -- Permission set definitions
    Staff/                  -- Shopify staff member mapping
Test/                       -- Test app (mirrors App/src/ module structure)
Shopify.code-workspace      -- VS Code workspace file
```

## Documentation

- [docs/architecture.md](docs/architecture.md) -- System design and data flow
- [docs/setup.md](docs/setup.md) -- Build, publish, and configuration
- [docs/features.md](docs/features.md) -- Module-by-module feature reference

## Key concepts

- **Shop record** (`Shpfy Shop` table 30102) is the central configuration entity -- one record per connected Shopify store, controlling all sync behavior via field settings
- **Communication is SingleInstance** -- `Shpfy Communication Mgt.` (codeunit 30103) is the single hub for all Shopify API calls, handling authentication, rate limiting, retries, and logging
- **GraphQL-first** -- Nearly all Shopify API interaction uses GraphQL via the `IGraphQL` interface; each query type is an enum value with its own implementation codeunit
- **Bidirectional sync** -- Products, customers, and companies can sync in either direction, controlled by shop-level settings like "Sync Item" (To Shopify / From Shopify)
- **Interface-driven extensibility** -- Key behaviors (product status, SKU mapping, customer mapping) are implemented as AL interfaces backed by enums, allowing extension via enum extensions
- **Event-based customization** -- Sync codeunits publish integration events (OnBefore/OnAfter patterns) so third-party extensions can hook into the sync pipeline
- **Namespace**: All objects use `Microsoft.Integration.Shopify` and the `Shpfy` prefix
