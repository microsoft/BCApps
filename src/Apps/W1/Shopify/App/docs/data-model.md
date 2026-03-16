# Data model

## Core configuration

The `Shpfy Shop` table (30102) is the central configuration hub. Every sync behavior, mapping strategy, template selection, G/L account assignment, and feature toggle lives here. It has over 80 fields spanning product sync direction, customer/company mapping types, order processing options, B2B settings, metafield sync toggles, webhook configuration, and more. Two mutual-exclusion field pairs enforce single-direction sync: "Shopify Can Update Items" vs "Can Update Shopify Products", and equivalents for customers and companies. Validating one to `true` forces the other to `false`.

The `Shpfy Synchronization Info` table tracks the last sync timestamp per shop and sync type (Products, Orders, Customers, etc.). Orders are special -- they key on `Shop Id` (a hash of the Shopify URL) rather than the `Code` field, so renaming a shop code preserves order sync state. The `GetLastSyncTime` / `SetLastSyncTime` methods on the Shop table manage this transparently.

The `Shpfy Registered Store New` table holds OAuth access tokens per store, keyed by store name. `CommunicationMgt.GetAccessToken()` validates that the stored scope matches the current expected scope before returning the token.

## Product catalog

Products follow a three-level hierarchy: `Shpfy Product` (30127) owns `Shpfy Variant` (30129), each variant owns `Shpfy Inventory Item` records. The Product holds title, description, vendor, status, and image metadata. The Variant holds SKU, price, compare-at-price, barcode, weight, up to three option name/value pairs, and inventory policy.

Both Product and Variant link to BC via `Item SystemId` (a Guid). The Variant additionally has `Item Variant SystemId` for BC Item Variants and `Mapped By Item` to indicate a variant mapped at the item level without a specific variant code. These SystemId links survive BC item renumbering -- the connector never stores `Item."No."` as a foreign key; it uses FlowFields (`CalcFormula = lookup`) to resolve the display number from the SystemId on demand.

Change detection uses integer hash fields: `Image Hash`, `Tags Hash`, and `Description Html Hash` on the Product, plus `Image Hash` on the Variant. The `Shpfy Hash` codeunit generates these. During export, the connector compares the current hash to the stored one to skip unchanged data without expensive string comparisons.

Products also carry dual timestamps: `Updated At` (from Shopify) and `Last Updated by BC` (set locally on export). The import loop in `ShpfySyncProducts.ImportProductsFromShopify` skips a product if both timestamps are older than Shopify's `UpdatedAt` for that product ID, which prevents circular updates.

The `Shpfy Product Collection` and `Shpfy Shop Collection Map` tables handle Shopify's Smart/Custom collections, mapped from BC Tax Groups or VAT Product Posting Groups via the Shop's `Product Collection` setting.

## Customer and company (B2B)

The `Shpfy Customer` table stores Shopify customer data with a `Customer SystemId` linking to BC's Customer table. The `Shpfy Customer Address` table holds address details. The `Shpfy Customer Template` table provides country-specific overrides -- keyed by Shop Code and Country/Region Code, it can set a per-country Default Customer No. and Customer Template Code. During order mapping, if a template exists for the ship-to country, its default customer takes precedence over the shop-level default.

The `Shpfy Tax Area` table maps Shopify country/province combinations to BC Tax Area Codes. The Shop's `Tax Area Priority` enum controls the lookup order: ship-to country first, then bill-to, or vice versa.

For B2B, the `Shpfy Company` table links to a BC Customer via `Customer SystemId` (again, a Guid, resolved through a FlowField). The `Shpfy Company Location` table represents billing/shipping locations within a company, each with optional `Sell-to Customer No.` and `Bill-to Customer No.` overrides. The order mapping in `ShpfyOrderMapping.MapSellToBillToCustomersFromCompanyLocation` checks the location first, then falls back to the company-level customer.

## Order lifecycle

Orders arrive through a two-stage pipeline. Stage one: the `Shpfy Orders to Import` table (30121) acts as a lightweight staging area populated by scheduled sync or webhook. Each row holds the Shopify order ID, order number, timestamps, and basic status flags (test, confirmed, fully paid, financial/fulfillment status). The `Shop Id` field (not `Shop Code`) links to the shop, which allows webhook-delivered orders to find their shop without knowing the BC code.

Stage two: `ShpfyImportOrder` reads the staging row, calls GraphQL to get the full order JSON, and writes into `Shpfy Order Header` (30118) and `Shpfy Order Line` (30119). The header carries three complete address blocks -- Sell-to, Ship-to, and Bill-to -- each with first name, last name, company name, address lines, city, country, county, and post code. It also stores dual-currency amounts everywhere: `Total Amount` / `Presentment Total Amount`, `Subtotal Amount` / `Presentment Subtotal Amount`, `VAT Amount` / `Presentment VAT Amount`, `Discount Amount` / `Presentment Discount Amount`, and so on.

The `Line Items Redundancy Code` on the header is a hash of all line IDs (pipe-separated, sorted ascending). When an order is re-imported after processing, the connector compares the new redundancy code to the stored one. A mismatch -- meaning Shopify edits added, removed, or changed lines -- sets `Has Order State Error` to flag the conflict for manual resolution.

Related tables include `Shpfy Order Attribute` (custom attributes), `Shpfy Order Line Attribute`, `Shpfy Order Tax Line` (per-line and per-order tax breakdowns), `Shpfy Order Shipping Charges`, and `Shpfy Order Payment Gateway`.

## Fulfillments

Fulfillments have two distinct models. `Shpfy Fulfillment Order Header` / `Shpfy Fulfillment Order Line` represent Shopify's FulfillmentOrder concept -- the *intent* to fulfill from a specific location. These are fetched per-order during import and used to determine `Location Id` and `Delivery Method Type` on order lines.

`Shpfy Order Fulfillment` / `Shpfy Fulfillment Line` represent actual fulfillments -- shipments that have been made. These track tracking numbers, carriers, and which line items were shipped. The connector creates fulfillments in Shopify when BC posts a Sales Shipment, if `Send Shipping Confirmation` is enabled.

## Returns and refunds

Returns and refunds are separate concepts. A `Shpfy Return Header` / `Shpfy Return Line` represents the physical return of goods -- what items the customer is sending back. A `Shpfy Refund Header` / `Shpfy Refund Line` represents the money side -- what amounts were refunded to the customer. A single order can have returns without refunds, refunds without returns, or both.

The `Shpfy Refund Shipping Line` tracks shipping cost refunds separately. Refund lines link back to order lines via `Order Line Id`, and the import process in `ShpfyImportOrder.ConsiderRefundsInQuantityAndAmounts` subtracts refunded quantities and amounts directly from the order lines before processing.

The `Return and Refund Process` enum on the Shop controls behavior: `Import Only` just stores the data, while `Auto Create Credit Memo` creates BC Sales Credit Memos from refunds via the `IReturnRefund Process` interface.

## Payments and transactions

The `Shpfy Order Transaction` table (30133) stores payment transactions per order -- gateway name, type (Sale/Capture/Authorization/Refund), status (Pending/Success/Failure/Error), amount, and currency. Transactions have parent linking via `Parent Id` for chained operations (e.g., an authorization followed by a capture).

The `Shpfy Payment Method Mapping` table (30134) maps the combination of gateway name + credit card company to a BC Payment Method Code. Its primary key is `(Shop Code, Gateway, Credit Card Company)`, so you can map "shopify_payments" + "Visa" differently from "shopify_payments" + "Mastercard". The `Shpfy Transaction Gateway` and `Shpfy Credit Card Company` tables serve as lookup masters populated from observed transactions.

The `Shpfy Payment Transaction` and `Shpfy Payout` tables handle Shopify Payments-specific data: individual payment transactions and bank deposit payouts. The `Shpfy Dispute` table tracks payment disputes.

## Catalogs and pricing (B2B)

The `Shpfy Catalog` table represents B2B catalogs. `Shpfy Catalog Price` holds per-catalog price overrides. `Shpfy Market Catalog Relation` links catalogs to markets. Catalog sync supports creating price lists via `GQLCreatePriceList` and updating prices via `GQLUpdateCatalogPrices`.

## Cross-cutting patterns

**Metafields** use a polymorphic design. The `Shpfy Metafield` table (30101) stores metafields for products, variants, customers, and companies in a single table. The `Owner Type` enum determines the entity type, and `Parent Table No.` (an integer) stores the AL database table number. The `Owner Id` (BigInteger) holds the Shopify entity ID. On insert, new metafields get negative IDs (starting at -1, decrementing) to avoid collisions with Shopify-assigned IDs until the first sync pushes them.

**Tags** follow the same polymorphic pattern. The `Shpfy Tag` table uses `Parent Table No.` + parent ID to associate comma-separated tags with any entity.

**DocLinkToDoc** provides many-to-many linking between Shopify documents (orders, returns, refunds) and BC documents (Sales Orders, Invoices, Credit Memos). It uses `Shpfy Document Type` + `Shopify Document Id` on one side and `Document Type` + `Document No.` on the other.

**LogEntry** stores API request/response data in Blob fields, with a configurable `Logging Mode` (All, Error Only, or disabled). A retention policy setup auto-enables when logging is turned on.

**DataCapture** (30114) is the audit trail. Every API response for orders, products, etc. gets stored with a hash. The `Add()` method checks if the hash matches the last capture for the same record and skips the insert if so, preventing unbounded table growth for unchanging data.

**SkippedRecord** tracks records that could not be synced, with the reason.

**BulkOperation** (in the Bulk Operations folder) tracks asynchronous Shopify bulk operations -- their status, result URLs, and request data.
