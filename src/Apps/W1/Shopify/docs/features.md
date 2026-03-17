# Features

Module-by-module reference for the Shopify Connector. All paths are relative to `App/src/`.

## Core infrastructure

### Base

- **Path**: `Base/`
- **Files**: 39
- **Purpose**: Central configuration and sync orchestration. Contains the `Shpfy Shop` table (30102) which holds all shop-level settings, the `Shpfy Communication Mgt.` codeunit (30103) which is the single hub for all API calls, background sync scheduling, the setup wizard, the installer/upgrade codeunits, and the shop card page.

### Integration

- **Path**: `Integration/`
- **Files**: 3
- **Purpose**: OAuth2 authentication with Shopify. `Shpfy Authentication Mgt.` handles app installation, access token exchange, scope validation, and store URL verification. Tokens are stored in `Shpfy Registered Store New` with isolated storage.

### GraphQL

- **Path**: `GraphQL/`
- **Files**: 147
- **Purpose**: GraphQL query infrastructure. Defines the `Shpfy IGraphQL` interface and the `Shpfy GraphQL Type` enum with 145+ query implementations. Each query is a codeunit that returns a parameterized GraphQL string and its expected API cost. The `Shpfy GraphQL Queries` codeunit resolves enum values to interface implementations. Also includes `Shpfy GraphQL Rate Limit` for cost-based throttle management.

### Helpers

- **Path**: `Helpers/`
- **Files**: 4
- **Purpose**: Shared utility codeunits -- `Shpfy Json Helper` for JSON parsing, `Shpfy Hash` for hash calculations, and filter management utilities.

### Webhooks

- **Path**: `Webhooks/`
- **Files**: 5
- **Purpose**: Webhook lifecycle management. `Shpfy Webhooks Mgt.` registers and unregisters webhooks for order creation and bulk operation completion. Webhook subscriptions are tied to specific user IDs for security context.

### Bulk Operations

- **Path**: `Bulk Operations/`
- **Files**: 9
- **Purpose**: Asynchronous bulk import/export using Shopify's Bulk Operations API. Submits GraphQL mutations that run server-side on Shopify, tracks operation status in the `Shpfy Bulk Operation` table, processes JSONL result files on completion (notified via webhook).

### Logs

- **Path**: `Logs/`
- **Files**: 10
- **Purpose**: API request/response logging. `Shpfy Log Entry` table stores URL, method, status code, request/response bodies, query cost, and Shopify request IDs. Logging mode is configurable per shop (All, Error Only, or disabled). Integrates with BC's retention policy framework for automatic cleanup.

### PermissionSets

- **Path**: `PermissionSets/`
- **Files**: 6
- **Purpose**: Permission set definitions controlling access to Shopify Connector tables and codeunits.

## Data sync

### Products

- **Path**: `Products/`
- **Files**: 54
- **Purpose**: Bidirectional product synchronization. Imports Shopify products/variants to `Shpfy Product` and `Shpfy Variant` tables, maps them to BC Items. Exports BC Items as Shopify products with configurable status (Active/Draft). Handles images, extended text, marketing text, item attributes (as metafields or variant options), SKU mapping, UoM-as-variant, product collections, and price sync. Key interfaces: `ICreateProductStatusValue`, `IRemoveProductAction`.

### Customers

- **Path**: `Customers/`
- **Files**: 44
- **Purpose**: Customer import and export with flexible mapping. Imports Shopify customers and maps to BC Customer records using configurable strategies (by email, phone, name, etc. via `Shpfy Customer Mapping` enum). Supports auto-creation of unknown customers from templates, configurable name/contact field sources, and bidirectional update control.

### Companies

- **Path**: `Companies/`
- **Files**: 27
- **Purpose**: B2B company sync (requires Shopify Plus). Imports/exports companies and company locations, maps to BC customers. Supports company contact permissions, tax ID mapping, and bidirectional update control. Enabled via the "B2B Enabled" shop setting.

### Catalogs

- **Path**: `Catalogs/`
- **Files**: 11
- **Purpose**: B2B catalog management. Creates and syncs Shopify catalogs tied to companies, controlling which products and prices are visible to B2B customers. Supports auto-creation when companies are exported.

### Inventory

- **Path**: `Inventory/`
- **Files**: 21
- **Purpose**: Stock level synchronization from BC to Shopify. Syncs available inventory quantities to Shopify locations with configurable inventory policies (Continue selling when out of stock vs. Deny). Maps BC locations to Shopify locations.

### Translations

- **Path**: `Translations/`
- **Files**: 8
- **Purpose**: Product translation sync. Exports translated product titles and descriptions from BC's language system to Shopify's translation resources.

### Metafields

- **Path**: `Metafields/`
- **Files**: 43
- **Purpose**: Custom metafield synchronization for products, variants, customers, and companies. Manages metafield definitions and values. Configurable per entity type on the shop card (e.g., "Sync Product/Variant Metafields to Shopify").

## Order processing

### Order handling

- **Path**: `Order handling/`
- **Files**: 58
- **Purpose**: Core order import and processing. Imports Shopify orders via GraphQL, stores them in `Shpfy Order Header` / `Shpfy Order Line` staging tables, then creates BC sales orders or invoices. Supports auto-creation, order attribute sync (BC document numbers back to Shopify), configurable tax mapping, and Shopify order number usage. Orders from B2B contexts are linked to companies.

### Order Fulfillments

- **Path**: `Order Fulfillments/`
- **Files**: 16
- **Purpose**: Fulfillment tracking. Syncs BC shipment information back to Shopify as fulfillments. Supports the Shopify Fulfillment Service (fulfillment-as-a-service), shipping confirmation notifications, and tracking number/URL updates.

### Order Refunds

- **Path**: `Order Refunds/`
- **Files**: 10
- **Purpose**: Refund data import. Downloads refund information from Shopify orders including refunded line items, amounts, and restock decisions.

### Order Returns

- **Path**: `Order Returns/`
- **Files**: 12
- **Purpose**: Return request handling. Imports Shopify return requests with return line items, reasons, and status tracking.

### Order Return Refund Processing

- **Path**: `Order Return Refund Processing/`
- **Files**: 19
- **Purpose**: Automated credit memo creation from imported returns and refunds. When "Return and Refund Process" is set to "Auto Create Credit Memo", this module creates BC sales credit memos from Shopify return/refund data. Handles configurable return locations and refund accounts for non-restocked items.

### Order Risks

- **Path**: `Order Risks/`
- **Files**: 5
- **Purpose**: Fraud risk data import. Stores Shopify's risk assessment information for orders (risk level, message, recommendation).

## Financial

### Payments

- **Path**: `Payments/`
- **Files**: 19
- **Purpose**: Shopify Payments data sync. Imports payment transactions, payouts, and disputes from Shopify Payments. Tracks payout status and dispute resolution.

### Transactions

- **Path**: `Transactions/`
- **Files**: 18
- **Purpose**: Order transaction records. Imports detailed financial transactions per order including gateway, amount, currency, and authorization information.

### Invoicing

- **Path**: `Invoicing/`
- **Files**: 7
- **Purpose**: Posted invoice sync. When "Posted Invoice Sync" is enabled, syncs BC posted sales invoice information back to Shopify orders. Also supports creating fulfilled orders directly as invoices via "Create Fulfilled Orders as Invoices".

### Shipping

- **Path**: `Shipping/`
- **Files**: 15
- **Purpose**: Shipping method and cost mapping. Maps Shopify shipping lines to BC shipping agents and services. Handles shipping charges posting to the configured G/L account.

### Gift Cards

- **Path**: `Gift Cards/`
- **Files**: 4
- **Purpose**: Gift card transaction handling. Manages gift card payments on orders, posting to the configured "Sold Gift Card Account" G/L account.

## Other

### Document Links

- **Path**: `Document Links/`
- **Files**: 21
- **Purpose**: Maintains links between BC documents (sales orders, invoices, credit memos, shipments) and their corresponding Shopify entities (orders, fulfillments, refunds). Provides navigation between linked records.

### Staff

- **Path**: `Staff/`
- **Files**: 4
- **Purpose**: Shopify staff member import. Maps Shopify staff/users to records within BC for order attribution and audit trails.
