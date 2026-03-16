# Business logic

## Overview

The Shopify Connector orchestrates bidirectional synchronization through API-focused codeunits organized by business domain. All API communication flows through Shpfy Communication Mgt. (30103), which handles authentication, GraphQL execution, rate limiting, and error logging. Processing follows an import-map-create pattern: import Shopify entities, map to BC records via interfaces, create or update BC documents.

## Key codeunits by domain

### Core communication (Base)

**Shpfy Communication Mgt. (30103)** -- Central API gateway
- Manages GraphQL query execution via ExecuteGraphQL() methods
- Handles API authentication via Shpfy Authentication Mgt.
- Implements rate limiting and throttling (NextExecutionTime tracking)
- Provides CreateWebRequestURL() for REST endpoint construction
- Uses API version 2026-01 (VersionTok)
- SingleInstance codeunit to maintain state across calls

**Shpfy Authentication Mgt. (30146)** -- OAuth 2.0 flow
- InstallShopifyApp() - initiates OAuth authorization
- AccessTokenExist() - validates stored credentials
- AssertValidShopUrl() - validates shop URL format
- Token storage in isolated storage (not in DB)

**Shpfy Shop Mgt. (30100)** -- Shop configuration helpers
- GetShopSettings() - retrieves shop metadata (B2B enabled, weight unit)
- TestConnection() - validates API connectivity
- CheckApiVersionExpiryDate() - monitors API version lifecycle

**Shpfy Background Syncs (30188)** -- Async job scheduling
- Schedules product sync, customer sync, inventory sync, order sync as job queue entries
- Respects "Allow Background Syncs" shop setting

**Shpfy Initial Import (30189)** -- Guided import wizard
- Batch imports historical data (products, customers, orders) with date range filters
- Uses Shpfy Initial Import Line table for wizard state

**Shpfy Communication Events (30148)** -- Communication extensibility
- Events for before/after API calls for logging or modification

### Product synchronization (Products)

**Shpfy Product Export (30178)** -- BC Item → Shopify Product
- OnRun trigger: exports products with filter "Item SystemId" <> null
- UpdateProductData() - synchronizes product metadata and variants
- CreateProductBody() - builds HTML description from extended text, marketing text, attributes
- OnlyUpdatePrice mode for bulk price updates via Shpfy Bulk Operation Mgt.
- Checks "Can Update Shopify Products" before updating existing products
- Handles variant option creation from item attributes

**Shpfy Product Import (30175)** -- Shopify Product → BC Item
- RetrieveShopifyProduct() - fetches product via GraphQL
- CreateProduct() - creates new items using Shpfy Create Item (30176)
- UpdateProduct() - updates existing items using Shpfy Update Item (30179)
- Mapping via Item SystemId field
- Checks "Shopify Can Update Items" before updating BC items

**Shpfy Create Product (30174)** -- New product creation in Shopify
- AddProductVariantToExport() - queues products for export
- Uses Shpfy Product API (30172) to execute GraphQL mutations
- Applies "Status for Created Products" setting (Draft/Active)

**Shpfy Product API (30172)** -- GraphQL product operations
- AddProduct() - productCreate mutation
- UpdateProduct() - productUpdate mutation
- AddProductImage() - creates product images
- UpdateProductVariant() - variantUpdate mutation
- All methods use GraphQL queries from Shpfy GraphQL Queries (30154)

**Shpfy Variant API (30173)** -- Variant-specific operations
- UpdateProductPrice() - synchronizes pricing
- UpdateInventoryPolicy() - sets overselling behavior
- GetProductVariants() - retrieves variant list for a product

**Shpfy Product Price Calc. (30180)** -- Price calculation logic
- CalcPrice() - calculates selling price with events for customization
- Handles catalog-specific pricing for B2B
- Supports currency conversion

**Shpfy Product Mapping (30183)** -- Item to Product association
- FindMapping() - locates existing product for an item
- CreateMapping() - links new products to items via SystemId

**Shpfy Product Events (30177)** -- 35+ integration events
- OnAfterCreateItem, OnBeforeCreateItem
- OnAfterCreateProductBodyHtml
- OnBeforeUpdateProductMetafields
- OnAfterSetProductTitle
- Enables extensive product sync customization

**Shpfy Create Item (30176)** -- Shopify Product → new BC Item
- Run trigger: creates item from Shpfy Product record
- Applies item template from shop settings
- Creates item variants if product Has Variants = true
- Handles SKU, barcode, pricing, weight, images

**Shpfy Update Item (30179)** -- Updates existing BC items from Shopify
- Selective field updates based on hash change detection
- Respects "Shopify Can Update Items" flag

**Shpfy Sync Products (30181)** -- Orchestrates product sync
- SyncProducts() - imports products from Shopify to BC
- Handles bulk product retrieval via bulk operations
- Processes product collections (categories)

### Order processing (Order handling)

**Shpfy Process Orders (30167)** -- Order orchestration
- OnRun trigger: processes unprocessed orders for a shop
- ProcessShopifyOrder() - single order processing with error handling
- ProcessShopifyOrders() - batch processing with commit after each
- ProcessShopifyRefunds() - processes refunds after orders

**Shpfy Process Order (30168)** -- Single order processor
- Run trigger: creates BC sales document from Shpfy Order Header
- Executes order import, customer mapping, sales doc creation
- Handles both Sales Order and Sales Invoice creation based on fulfillment status
- Sets "Use Shopify Order No." if shop configured for manual numbering

**Shpfy Import Order (30169)** -- Shopify Order → Shpfy Order Header
- ImportOrder() - retrieves order from Shopify API via GraphQL
- ImportOrderLine() - creates order lines with product/variant linking
- ImportTaxLines() - imports tax details
- ImportTransactions() - imports payment transactions
- ImportRisks() - imports fraud analysis
- Handles dual currency (shop + presentment)

**Shpfy Order Mapping (30170)** -- Order to Sales Doc linking
- CreateSalesHeader() - creates Sales Header from Shpfy Order Header
- CreateSalesLine() - creates Sales Lines from Shpfy Order Lines
- MapCustomerAndAddress() - assigns customer and addresses
- MapShippingAgentAndMethod() - assigns shipping method
- MapPaymentTerms() - assigns payment terms for B2B orders
- Uses IsHandled pattern for extensibility (15 IsHandled checks)

**Shpfy Orders API (30171)** -- GraphQL order operations
- RetrieveOrders() - bulk order import with date filter
- GetOrdersToImport() - queries orders since last sync
- UpdateOrderAttributes() - sends BC document numbers back to Shopify

**Shpfy Orders (30165)** -- Order sync orchestrator
- SyncOrders() - imports orders with date range filter
- Uses webhooks for real-time import if "Order Created Webhooks" enabled
- Respects "Customer Import From Shopify" setting

**Shpfy Order Events (30166)** -- 19 integration events
- OnBeforeCreateSalesHeader, OnAfterCreateSalesHeader
- OnBeforeCreateSalesLine, OnAfterCreateSalesLine
- OnBeforeSendCreateSalesDocument
- OnAfterCalcSalesPrice
- Enables order processing customization

### Customer synchronization (Customers)

**Shpfy Customer Import (30117)** -- Shopify Customer → BC Customer
- OnRun trigger: imports customer and addresses from Shopify
- CustomerMapping.FindMapping() - locates existing customer
- CreateCustomer - creates new BC customer if auto-create enabled
- UpdateCustomer - updates existing customer if "Shopify Can Update Customer" enabled

**Shpfy Customer Mapping (30116)** -- Customer association logic
- FindMapping() - implements customer matching strategy via ICustomerMapping interface
- Direction parameter: To Shopify or From Shopify
- Strategies: By Email/Phone, By Bill-to Info, Always New, By Default Customer

**Shpfy Customer API (30118)** -- GraphQL customer operations
- RetrieveShopifyCustomer() - retrieves customer details
- GetCustomers() - bulk customer import
- UpdateCustomer() - sends customer updates to Shopify
- AddCustomer() - creates customer in Shopify

**Shpfy Create Customer (30119)** -- Shopify → new BC Customer
- Run trigger: creates BC customer from Shpfy Customer Address
- Applies customer template from shop settings or event
- Calls CustomerMapping to establish link via SystemId

**Shpfy Update Customer (30120)** -- Updates BC customer from Shopify
- Selective updates based on "Shopify Can Update Customer" setting

**Shpfy Sync Customers (30121)** -- Customer sync orchestrator
- SyncCustomers() - imports customers from Shopify
- Respects "Customer Import From Shopify" range setting

**Shpfy Customer Events (30115)** -- 7 integration events
- OnBeforeCreateCustomer, OnAfterCreateCustomer
- OnBeforeSendCreateShopifyCustomer
- OnBeforeFindCustomerTemplate
- OnBeforeFindMapping, OnAfterFindMapping

**Shpfy Cust By Email/Phone (30122)**, **Shpfy Cust By Bill-to (30123)**, **Shpfy Cust By Default (30124)** -- ICustomerMapping implementations

**Shpfy Name is Company Name (30125)**, **Shpfy Name is First+Last (30126)**, **Shpfy Name is Last+First (30127)** -- ICustomerName implementations for name parsing

**Shpfy County Code/Name (30128/30129)**, **Shpfy County From Json Code/Name (30130/30131)** -- ICounty and ICountyFromJson implementations for state/province handling

### Inventory synchronization (Inventory)

**Shpfy Sync Inventory (30197)** -- Stock level sync orchestrator
- OnRun trigger: syncs inventory levels bidirectionally
- ImportStock() - retrieves stock from Shopify
- ExportStock() - sends BC stock to Shopify per shop location
- Respects "Stock Calculation" setting on shop location

**Shpfy Inventory API (30198)** -- GraphQL inventory operations
- SetInventoryQuantities() - bulk inventory update mutation
- GetInventory() - retrieves current stock levels
- Uses inventorySetQuantities GraphQL mutation

**Shpfy Stock Calc. Default (30199)**, **Shpfy Stock Available (30200)** -- IStockCalculation and IStockAvailable interface implementations for available stock calculation

**Shpfy Inventory Events (30201)** -- 1 integration event
- OnAfterCalculateAvailableInventory

### Return and refund processing (Order Return Refund Processing)

**Shpfy Create Sales Doc Refund (30145)** -- Refund → BC Credit Memo
- CreateCreditMemo() - creates sales credit memo from Shpfy Refund Header
- ProcessRefundLines() - creates credit memo lines from refund lines
- ProcessRefundShipping() - handles shipping charge refunds
- Respects "Return and Refund Process" setting (Import Only vs Auto Create)

**Shpfy Refund Process Events (30146)** -- 6 integration events
- OnBeforeCreateCreditMemo, OnAfterCreateCreditMemo
- OnBeforeProcessRefundLine, OnAfterProcessRefundLine

**Shpfy Import Refund (30147)**, **Shpfy Only Refund (30148)**, **Shpfy Auto Cr.Memo Refund (30149)** -- IReturnRefundProcess implementations for different refund handling modes

**Document source implementations (30150-30154)** -- IDocumentSource and IExtendedDocumentSource for return source tracking

### Shipping and fulfillment (Shipping, Order Fulfillments)

**Shpfy Export Shipments (30122)** -- BC Shipment → Shopify Fulfillment
- ExportShipments() - creates fulfillments from posted sales shipments
- SendShippingConfirmation() - notifies customer via Shopify
- CreateFulfillmentFromShipment() - maps shipment to fulfillment

**Shpfy Fulfillment Orders Sync (30202)** -- Fulfillment order import
- ImportFulfillmentOrders() - retrieves fulfillment orders
- Handles third-party fulfillment service integration

**Shpfy Shipping Events (30123)** -- 2 integration events
- OnBeforeCreateFulfillment, OnAfterCreateFulfillment
- Enables shipping workflow customization

### Invoicing

**Shpfy Posted Invoice Sync (30202)** -- Posted Invoice → Shopify
- SyncPostedInvoice() - sends posted invoice details to Shopify for payment tracking
- Respects "Posted Invoice Sync" shop setting

### GraphQL infrastructure (GraphQL)

**Shpfy GraphQL Queries (30154)** -- Query template library
- GetGraphQLType() - returns query template for operation
- Contains 100+ pre-built GraphQL query templates
- Uses {{Parameters}} placeholder substitution
- IsHandled pattern for query customization (15 IsHandled)

**Shpfy GraphQL Rate Limit (30155)** -- Throttling management
- CheckRateLimit() - enforces Shopify rate limits
- Uses TryFunction to handle throttled requests
- Tracks throttle count and sleep duration

**IGraphQL Interface** -- Pluggable query provider
- GetGraphQL() - returns query text
- GetExpectedCost() - returns query cost estimate

### Bulk operations

**Shpfy Bulk Operation Mgt. (30156)** -- Async operation handler
- SendBulkMutation() - submits bulk GraphQL mutation
- GetBulkOperationResult() - retrieves operation status
- ProcessBulkOperationResult() - processes JSONL result file
- Used for product price updates, inventory sync

**Shpfy Bulk Operation API (30157)** -- Bulk operation GraphQL
- ExecuteBulkOperation() - submits bulkOperationRunQuery mutation
- PollBulkOperationStatus() - checks completion status

**Shpfy Bulk Update Product Image (30158)** -- IBulkOperation implementation for image updates

### Metafields

**Shpfy Metafield API (30159)** -- Metafield CRUD operations
- GetMetafields() - retrieves metafields for owner entity
- SetMetafield() - creates or updates metafield
- DeleteMetafield() - removes metafield
- Uses metafieldsSet mutation

**Shpfy Metafield Type implementations (30160-30180)** -- IMetafieldType implementations for 50+ Shopify metafield types (Money, Weight, Dimension, Volume, Date, etc.)

### Webhooks

**Shpfy Webhooks Mgt. (30203)** -- Webhook lifecycle management
- EnableOrderCreatedWebhook() - registers order/create webhook
- DisableOrderCreatedWebhook() - removes webhook
- EnableBulkOperationsWebhook() - registers bulk operation webhook
- ProcessWebhook() - handles incoming webhook POST

### Companies (B2B)

**Shpfy Company Mapping (30204)** -- Company association
- FindMapping() - implements company matching via ICompanyMapping interface
- Strategies: By Tax ID, By Email/Phone, By Default Company, None

**Shpfy Sync Companies (30205)** -- Company import
- SyncCompanies() - imports Shopify companies
- Respects "Company Import From Shopify" range setting

**Shpfy Comp By Tax ID (30206)**, **Shpfy Comp By Email/Phone (30207)**, **Shpfy Comp By Default (30208)** -- ICompanyMapping implementations

## Processing flows

### Product sync: BC Item → Shopify

1. User runs "Sync Item" action or background job executes
2. **Shpfy Sync Products** (30181) calls **Shpfy Product Export** (30178)
3. **Product Export** filters products with "Item SystemId" linked
4. For each product: **Product Export** → **Product API** (30172) → **Communication Mgt.** (30103)
5. **Communication Mgt.** executes GraphQL productUpdate or productCreate mutation
6. **Product API** processes response, updates Shpfy Product record
7. If OnlyUpdatePrice = true, uses bulk operations for 100+ variants
8. **Product Export** synchronizes images via **Product Image Export** (30181)
9. **Product Export** synchronizes metafields via **Metafield API** (30159)
10. Hash fields updated to track changes (Image Hash, Tags Hash, Description Html Hash)

### Product sync: Shopify → BC Item

1. User runs "Import Product" or sync from catalog
2. **Shpfy Sync Products** (30181) calls **Shpfy Product Import** (30175)
3. **Product Import** → **Product API** → **Communication Mgt.** for GraphQL product query
4. **Product Import** creates/updates Shpfy Product record
5. **Product Mapping** (30183) checks if Item exists via SystemId
6. If no item found and "Auto Create Unknown Items" = true:
   - **Create Item** (30176) creates BC Item from product
   - Applies item template, sets SKU, pricing, weight
   - Creates item variants if Has Variants = true
7. If item exists and "Shopify Can Update Items" = true:
   - **Update Item** (30179) updates BC Item fields
8. **Product Import** fires OnAfterCreateItem / OnAfterUpdateItem events

### Order sync: Shopify → BC Sales Document

1. Webhook triggers or user runs "Import Orders"
2. **Shpfy Orders** (30165) calls **Orders API** (30171) to retrieve orders
3. **Orders API** → **Communication Mgt.** executes GraphQL ordersQuery
4. **Import Order** (30169) creates Shpfy Order Header + Lines from JSON
5. **Import Order** calls ImportTaxLines, ImportTransactions, ImportRisks
6. **Process Orders** (30167) calls **Process Order** (30168) for each unprocessed order
7. **Process Order** → **Order Mapping** (30170) begins sales doc creation:
   a. MapCustomer: **Customer Mapping** (30116) finds/creates BC Customer
   b. CreateSalesHeader: Creates Sales Header with customer, addresses, dates
   c. CreateSalesLine: Creates Sales Lines from Order Lines
   d. MapShippingAgentAndMethod: Assigns shipping method
   e. MapPaymentTerms: Assigns payment terms (B2B)
8. **Order Mapping** fires OnBeforeCreateSalesHeader, OnAfterCreateSalesLine, etc.
9. **Process Order** sets Shpfy Order Header.Processed = true
10. If "Auto Release Sales Orders" = true, sales order is released
11. If fulfillment status = Fulfilled and "Create Invoices From Orders" = true, creates Sales Invoice instead of Sales Order

### Customer sync: Shopify → BC Customer

1. Order import triggers customer import, or user runs "Sync Customers"
2. **Shpfy Sync Customers** (30121) calls **Customer Import** (30117)
3. **Customer Import** → **Customer API** (30118) retrieves customer via GraphQL
4. **Customer API** creates Shpfy Customer + Customer Address records
5. **Customer Mapping** (30116) executes FindMapping with configured strategy:
   - By Email/Phone: Matches on email or phone number
   - By Bill-to Info: Matches on billing address
   - Always New: Never maps to existing
   - By Default: Uses default customer no.
6. If no mapping found and "Auto Create Unknown Customers" = true:
   - **Create Customer** (30119) creates BC Customer
   - Applies customer template via OnBeforeFindCustomerTemplate event
   - Links via Customer SystemId field
7. If mapping exists and "Shopify Can Update Customer" = true:
   - **Update Customer** (30120) updates BC Customer fields
8. **Customer Import** fires OnAfterCreateCustomer event

### Inventory sync: BC → Shopify

1. Background job or user runs "Sync Inventory"
2. **Shpfy Sync Inventory** (30197) processes each Shpfy Shop Location
3. For each location where "Stock Calculation" <> Disabled:
   a. **Inventory API** (30198) queries Shpfy Shop Inventory table
   b. For each variant, calculates available stock via IStockCalculation interface
   c. Groups stock updates by location
4. **Inventory API** executes inventorySetQuantities bulk mutation via **Communication Mgt.**
5. Shopify updates inventory levels for all variants in single request

### Return/Refund processing: Shopify → BC Credit Memo

1. **Import Order** (30169) imports Shpfy Return Header and Shpfy Refund Header
2. **Process Orders** (30167) calls ProcessShopifyRefunds() after order processing
3. If "Return and Refund Process" = "Auto Create Credit Memo":
   a. **Create Sales Doc Refund** (30145) creates Sales Credit Memo
   b. ProcessRefundLines creates credit memo lines from Shpfy Refund Lines
   c. ProcessRefundShipping adds shipping refund line if applicable
   d. Links credit memo to original sales document via Get Sales Document action
4. If "Return and Refund Process" = "Import Only":
   - Records imported but no BC document created
   - User manually processes returns

### Payment tracking: Order → Transactions

1. **Import Order** (30169) calls ImportTransactions()
2. **Orders API** (30171) retrieves transactions via GraphQL
3. Shpfy Order Transaction records created with Type (Authorization, Capture, Sale, Refund), Status, Gateway, Amount
4. Multiple transactions per order (auth + capture, partial payments)
5. Transactions visible on Shopify Order page for reconciliation

## Event architecture

The connector provides 70+ integration events across three event codeunits for customization without modifying base code.

### Shpfy Order Events (30166) -- 19 events
- **OnBeforeCreateSalesHeader** -- Modify sales header before creation
- **OnAfterCreateSalesHeader** -- Customize sales header after creation
- **OnBeforeCreateSalesLine** -- Modify sales line before creation
- **OnAfterCreateSalesLine** -- Customize sales line after creation
- **OnBeforeCalcSalesPrice** -- Override price calculation
- **OnAfterCalcSalesPrice** -- Adjust calculated price
- **OnBeforeSendCreateSalesDocument** -- Validate before document creation
- **OnAfterImportOrder** -- Post-import processing
- **OnBeforeMapCustomer** -- Custom customer mapping logic
- **OnAfterMapCustomer** -- Post-mapping adjustments
- **OnBeforeImportOrderLine** -- Filter or modify imported lines
- **OnAfterImportOrderLine** -- Line-level customization

### Shpfy Customer Events (30115) -- 7 events
- **OnBeforeCreateCustomer** -- Validate or prevent customer creation
- **OnAfterCreateCustomer** -- Customize created customer
- **OnBeforeSendCreateShopifyCustomer** -- Modify before sending to Shopify
- **OnBeforeSendUpdateShopifyCustomer** -- Modify before updating Shopify
- **OnBeforeFindCustomerTemplate** -- Custom template selection
- **OnBeforeFindMapping** -- Custom mapping logic
- **OnAfterFindMapping** -- Post-mapping processing

### Shpfy Product Events (30177) -- 35+ events
- **OnAfterCreateItem** -- Customize created item
- **OnBeforeCreateItem** -- Validate or prevent item creation
- **OnAfterCreateItemVariant** -- Customize created variant
- **OnAfterCreateProductBodyHtml** -- Modify product description HTML
- **OnAfterSetProductTitle** -- Customize product title
- **OnBeforeUpdateProductMetafields** -- Modify metafields before sync
- **OnAfterCreateTempShopifyProduct** -- Customize product before export
- **OnAfterFindItemTemplate** -- Custom template selection
- **OnAfterProductsToSynchronizeFiltersSet** -- Custom product filters

## Integration points

### To Business Central
- **Sales Documents**: Creates Sales Orders, Sales Invoices, Sales Credit Memos
- **Customers**: Creates/updates Customer records
- **Items**: Creates/updates Item and Item Variant records
- **Inventory**: Reads available inventory from Item Ledger Entries
- **General Ledger**: Posts via standard sales posting (sales invoices, credit memos)
- **Job Queue**: Schedules background sync tasks

### From Business Central
- **Sales Shipment**: Triggers fulfillment creation in Shopify
- **Posted Sales Invoice**: Optionally syncs to Shopify for payment tracking
- **Item Changes**: Triggers product update in Shopify
- **Inventory Changes**: Triggers stock level update in Shopify

### External (Shopify)
- **Admin GraphQL API**: All communication uses GraphQL (API version 2026-01)
- **Webhooks**: Receives order/create and bulk operation completion notifications
- **OAuth 2.0**: Handles app installation and token refresh
- **Carrier Service API**: Optional integration for calculated shipping rates
