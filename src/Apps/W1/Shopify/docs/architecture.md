# Architecture

## Overview

The Shopify Connector follows a three-tier architecture:

1. **API layer** -- Handles authentication, HTTP communication, rate limiting, and GraphQL query dispatch
2. **Sync layer** -- Orchestrates import/export operations between Shopify and BC tables
3. **Business logic layer** -- Maps Shopify entities to BC documents (sales orders, invoices, credit memos)

## Core components

### Communication hub

`Shpfy Communication Mgt.` (codeunit 30103) is a **SingleInstance** codeunit that serves as the single entry point for all Shopify API calls.

- Constructs URLs against the configured Shopify Admin API version (currently `2026-01`)
- Manages OAuth2 access tokens (stored in `Shpfy Registered Store New`)
- Implements retry logic with exponential backoff for HTTP 429 (throttled) and 5xx errors
- Enforces GraphQL rate limiting via `Shpfy GraphQL Rate Limit` using Shopify's cost-based throttle status
- Logs all requests/responses to `Shpfy Log Entry` based on the shop's logging mode
- Checks API version expiry dates cached from Azure Key Vault

### GraphQL query system

All Shopify API interactions use GraphQL, organized through an interface pattern:

- `Shpfy IGraphQL` interface defines `GetGraphQL()` and `GetExpectedCost()`
- `Shpfy GraphQL Type` enum lists all query types (145+ implementations across modules)
- Each query type maps to a codeunit that implements the interface
- `Shpfy GraphQL Queries` (codeunit 30154) resolves enum to interface, substitutes parameters, and returns the query text
- Extensible via `OnBeforeSetInterfaceCodeunit` and `OnBeforeGetGrapQLInfo` events

### Authentication

`Shpfy Authentication Mgt.` (codeunit 30199) handles OAuth2 app installation:

- Redirects to Shopify's OAuth authorize endpoint with the required scopes
- Exchanges the authorization code for an access token
- Stores tokens in `Shpfy Registered Store New` with scope tracking
- Detects scope changes and prompts re-authentication
- API keys are sourced from Azure Key Vault in SaaS, hardcoded fallbacks for on-prem

## Key design decisions

### GraphQL-first

The connector uses Shopify's Admin GraphQL API exclusively (no REST). This enables:

- Cost-based rate limit management (each query declares its expected cost)
- Efficient nested data retrieval in single requests
- Cursor-based pagination for large datasets

### Enum-based configuration

Behavioral choices are implemented as AL enums backed by interfaces:

- `Shpfy Customer Mapping` -- how Shopify customers map to BC customers
- `Shpfy SKU Mapping` -- how SKUs resolve to items/variants
- `Shpfy Cr. Prod. Status Value` -- what status new products get in Shopify
- `Shpfy Remove Product Action` -- what happens when a product is removed

This pattern allows third-party extensions to add new mapping strategies by extending the enum.

### Bidirectional sync with conflict avoidance

Sync direction is configured per entity type on the shop card. For products:

- "Shopify Can Update Items" and "Can Update Shopify Products" are mutually exclusive
- Same pattern for customers and companies
- This prevents circular updates

### Bulk operations for large datasets

For high-volume scenarios, the connector uses Shopify's Bulk Operations API:

- Submits a GraphQL mutation that runs asynchronously on Shopify's side
- Receives completion via webhook
- Downloads results as JSONL from a temporary URL
- Managed by `Shpfy Bulk Operation Mgt.` with status tracking in `Shpfy Bulk Operation` table

## Data flow

### Import flow (Shopify to BC)

```
Shopify Store
  -> GraphQL queries (paginated)
    -> Shpfy Communication Mgt. (HTTP + rate limiting)
      -> Sync codeunits parse JSON responses
        -> Shopify staging tables (Shpfy Product, Shpfy Order Header, etc.)
          -> Process codeunits create BC documents (Sales Orders, Invoices)
```

### Export flow (BC to Shopify)

```
BC records (Items, Customers)
  -> Sync codeunits build GraphQL mutations
    -> Shpfy Communication Mgt. (HTTP + rate limiting)
      -> Shopify Store
        -> Response updates Shopify IDs in staging tables
```

## Data model

### Core tables

| Table | ID | Purpose |
|-------|-----|---------|
| Shpfy Shop | 30102 | Shop configuration (one per Shopify store) |
| Shpfy Synchronization Info | 30103 | Last sync timestamps per entity type |
| Shpfy Registered Store New | -- | OAuth tokens and scope (isolated storage) |
| Shpfy Log Entry | -- | API request/response log |

### Product tables

| Table | Purpose |
|-------|---------|
| Shpfy Product | Shopify product header with mapping to BC Item |
| Shpfy Variant | Product variants with SKU, price, inventory |
| Shpfy Tag | Tags associated with products |

### Order tables

| Table | Purpose |
|-------|---------|
| Shpfy Order Header | Imported order header |
| Shpfy Order Line | Order line items |
| Shpfy Order Tax Line | Tax breakdown per line |
| Shpfy Order Fulfillment | Fulfillment records |
| Shpfy Refund Header / Line | Refund data |
| Shpfy Return Header / Line | Return requests |

### Customer/company tables

| Table | Purpose |
|-------|---------|
| Shpfy Customer | Shopify customer with BC customer mapping |
| Shpfy Customer Address | Customer address records |
| Shpfy Company | B2B company (Shopify Plus) |
| Shpfy Company Location | Company billing/shipping locations |
| Shpfy Catalog | B2B product catalogs |

### Financial tables

| Table | Purpose |
|-------|---------|
| Shpfy Payment Transaction | Payment records per order |
| Shpfy Order Transaction | Detailed transaction log |
| Shpfy Dispute | Shopify Payments disputes |
| Shpfy Payout | Shopify Payments payouts |

## Patterns in use

### Event subscribers

Sync codeunits publish integration events following the `OnBefore`/`OnAfter` convention:

- `OnBeforeCreateItem` / `OnAfterCreateItem`
- `OnBeforeCreateSalesHeader` / `OnAfterCreateSalesHeader`
- Events allow third-party extensions to modify data during sync without touching core code

### Background syncs

When "Run Syncs in Background" is enabled on the shop card, sync operations run as job queue entries rather than blocking the UI. The `Shpfy Background Syncs` codeunit manages this.

### Webhook processing

The connector registers webhooks for:

- Order creation (`orders/create`) -- triggers immediate order import
- Bulk operation completion (`bulk_operations/finish`) -- triggers result download

Webhooks are managed by `Shpfy Webhooks Mgt.` and tied to specific user IDs for security context.

### Test isolation

Tests mock all Shopify API calls using two mechanisms:

- **HttpClientHandler** (correct approach for new tests) -- test codeunits set `TestHttpRequestPolicy = BlockOutboundRequests` and declare `[HttpClientHandler]` procedures that intercept HTTP at the framework level. See `Test/docs/testing.md` for the full guide.
- **IsTestInProgress events** (legacy) -- `Shpfy Communication Mgt.` has a `SetTestInProgress` flag that redirects HTTP calls to `Shpfy Communication Events`, where test subscriber codeunits provide mock responses. This pattern exists in many older tests but should not be used for new ones.
