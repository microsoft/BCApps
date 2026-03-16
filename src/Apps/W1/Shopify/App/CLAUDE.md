# Shopify Connector

Bidirectional synchronization between Shopify and Business Central for orders, products, customers, inventory, and B2B companies.

## Quick reference

- **Runtime**: 29.0.0.0
- **Dependencies**: None
- **ID range**: 30100-30460
- **Object count**: 65 tables, 329 codeunits, 76 pages, 22 interfaces, 74 enums, 18 table extensions

## Structure

- **Base** -- Core shop configuration (Shpfy Shop table 30102), authentication, tags, logging mode, synchronization tracking
- **Bulk Operations** -- Asynchronous GraphQL bulk mutation processing for high-volume operations like product price updates
- **Catalogs** -- B2B catalog pricing and market-to-catalog relationship management
- **Companies** -- B2B company entities, company locations, contact permissions, and company-to-customer mapping
- **Customers** -- Customer import/export, address management, tax exemptions, and customer-to-BC customer mapping
- **Document Links** -- Navigation between Shopify and BC documents (orders, invoices, returns, shipments)
- **Gift Cards** -- Gift card tracking and sales order line handling
- **GraphQL** -- GraphQL query templates, rate limiting, API versioning (2026-01), and query cost management
- **Helpers** -- Utility codeunits for JSON, math, hash calculation, and string manipulation
- **Integration** -- OAuth 2.0 authentication, registered store management, and API communication
- **Inventory** -- Stock level synchronization, inventory policies, stock calculation interfaces
- **Invoicing** -- Posted invoice synchronization to Shopify for payment tracking
- **Logs** -- Diagnostic logging (requests, responses, errors), skipped records, retention policies
- **Metafields** -- Custom metadata synchronization for products, variants, customers, companies (namespace/key/value)
- **Order Fulfillments** -- Fulfillment creation, tracking numbers, fulfillment service integration
- **Order handling** -- Order import, sales document creation, order-to-sales mapping, risk assessment
- **Order Refunds** -- Refund header/lines, refund transactions, restocking logic
- **Order Return Refund Processing** -- Business logic for processing returns and refunds into BC credit memos
- **Order Returns** -- Return header/lines, return reasons, approve/decline workflow
- **Order Risks** -- Fraud analysis results (risk level, recommendation, message) from Shopify
- **Payments** -- Payment gateway tracking, order transactions, payment method mapping
- **PermissionSets** -- Security permissions for Shopify connector users
- **Products** -- Product/variant export and import, SKU mapping, image sync, status management
- **Shipping** -- Shipment export to Shopify, fulfillment creation, tracking number sync, shipping agent mapping
- **Staff** -- Shopify staff member tracking (currently minimal implementation)
- **Transactions** -- Payment transaction history, transaction type/status tracking
- **Translations** -- Product and variant name translations for multi-language shops
- **Webhooks** -- Webhook registration for order creation and bulk operation completion events

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Table relationships and data structure
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and event architecture
- [docs/patterns.md](docs/patterns.md) -- Code patterns used in this app

## Key concepts

- **Shop as configuration root** -- All synchronization settings live in the Shpfy Shop table (30102), which controls import ranges, auto-creation flags, mapping types, and currency handling
- **SystemId-based linking** -- Tables use SystemId (Guid) fields to link Shopify records to BC records (e.g., "Item SystemId" links Shpfy Product to Item) rather than traditional No. fields
- **Dual currency support** -- Orders track both shop currency (Currency Code) and customer presentment currency (Presentment Currency Code) with separate amount fields for each
- **Interface-driven extensibility** -- 22 interfaces enable pluggable behavior for customer mapping, county parsing, product status, stock calculation, and document source handling
- **Hash-based change detection** -- Products, variants, and metafields use hash codes ("Image Hash", "Tags Hash", "Description Html Hash") to detect changes and avoid unnecessary API calls
- **GraphQL-first API** -- All communication uses Shopify's GraphQL Admin API with bulk operations for high-volume scenarios and rate limit tracking
- **Event-driven synchronization** -- Three event codeunits (Order Events, Customer Events, Product Events) provide 70+ integration events for extending sync behavior
- **Webhook automation** -- Optional webhooks trigger automatic order import when orders are created in Shopify and notify when bulk operations complete
- **B2B commerce support** -- Full support for Shopify Plus B2B features: companies, company locations, catalogs, payment terms, purchase orders
- **Bidirectional sync control** -- Separate flags control each direction: "Can Update Shopify Products" vs "Shopify Can Update Items", preventing sync conflicts
