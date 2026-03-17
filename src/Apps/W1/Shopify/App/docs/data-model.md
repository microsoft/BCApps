# Data model

## Product catalog

The product data model mirrors Shopify's own hierarchy: a `Shpfy Product` (30127) has one or more `Shpfy Variant` records. Products link to BC Items via `Item SystemId` (a GUID), not via Item No. This means renumbering items in BC does not orphan the mapping. Variants similarly link to BC Item Variants via `Item Variant SystemId`. When the connector syncs "To Shopify", it builds temporary product and variant records from the BC Item, fills in Shopify-specific fields (title, body HTML, SEO, tags, product type, vendor), and then creates or updates via GraphQL mutations.

Product images live in a `Shpfy Product Image` table and are linked to products by Product Id. Each image tracks its Shopify-assigned Id and a hash of the image content. The hash is critical -- during sync, the connector compares the local hash against the stored hash to avoid re-uploading unchanged images. Bulk image updates use the `Shpfy IBulk Operation` interface for efficiency.

Tags are polymorphic. The `Shpfy Tag` table (30150) uses a `Parent Table No.` + `Parent Id` pattern, so the same table stores tags for products, orders, or any other tagged entity. This means you cannot just filter by parent Id -- you must also filter by parent table number.

Product metafields use a similar polymorphic approach via the `Shpfy Metafield` table and the `Shpfy IMetafield Owner Type` / `Shpfy IMetafield Type` interfaces for type-driven validation.

## Order lifecycle

Orders pass through three distinct stages, each in its own table.

**Stage 1 -- Orders to Import** (`Shpfy Orders to Import`, 30121): During order sync, the connector queries Shopify for orders updated since the last sync time. It writes lightweight records into this staging table containing just the essentials -- order ID, shop code, financial status, fulfillment status, amount, tags, and risk level. The user (or automation) then decides which orders to actually import. Each record tracks errors at the individual order level via `Has Error` and `Error Message` blob fields.

**Stage 2 -- Order Header and Lines** (`Shpfy Order Header`, 30118; `Shpfy Order Line`, 30119): When an order is selected for import, the connector fetches full details from Shopify and populates these tables. The Order Header contains all address information (sell-to, ship-to, bill-to), financial totals in both shop currency and presentment currency, customer/company mappings, and processing state. Order lines track individual products with their quantities, prices, discount allocations, tax amounts, and the mapping to BC Items.

**Stage 3 -- BC Sales Documents**: The order processing logic in `ShpfyProcessOrders` creates a BC Sales Header and Sales Lines from the Shopify order data. The connector extends the standard `Sales Header` and `Sales Line` tables with fields like `Shpfy Order Id` and `Shpfy Order No.` to maintain traceability. Fully fulfilled orders can optionally be created as Sales Invoices rather than Sales Orders (controlled by `Create Invoices From Orders` on the Shop).

Dual currency is pervasive. The Order Header stores `Total Amount`, `Subtotal Amount`, `Total Tax Amount` alongside their `Presentment *` counterparts. The `Currency Handling` field on the Shop determines which set of amounts the connector uses when creating BC documents -- shop currency (what the merchant receives) or presentment currency (what the customer paid).

## Customer and company

The `Shpfy Customer` table stores Shopify customer data and maps to BC Customers via `Customer SystemId`. Customer addresses live in a separate `Shpfy Customer Address` table. The mapping strategy -- how to find or create a BC customer from a Shopify customer -- is selected on the Shop via the `Customer Mapping Type` field, which delegates to implementations of `Shpfy ICustomer Mapping` (by email/phone, by bill-to info, or by default customer number).

For B2B, `Shpfy Company` and `Shpfy Company Location` tables model the Shopify company hierarchy. A company can have multiple locations, each potentially mapped to a different BC customer for billing vs. shipping purposes. Companies link to BC Customers via `Customer SystemId` on the company location, not on the company itself. The `Company Mapping Type` field on the Shop controls how companies are matched to BC customers (by email/phone, by default company, by tax ID).

## Returns and refunds

Returns and refunds are separate concepts that arrived in the data model at different times. `Shpfy Return Header` and `Shpfy Return Line` track Shopify return requests (items the customer wants to send back). `Shpfy Refund Header` and `Shpfy Refund Line` track monetary adjustments (amounts refunded to the customer).

The `Return and Refund Process` field on the Shop controls what happens: "Import Only" just stores the data, while "Auto Create Credit Memo" processes returns into BC Sales Credit Memos. The document source interface (`Shpfy IDocument Source` / `Shpfy Extended IDocument Source`) determines whether the credit memo is created from the posted sales invoice or the posted sales shipment. Return location priority can be set to use the Shopify return location or the BC default return location.

## Payments and transactions

Payment data flows from Shopify's payment provider. `Shpfy Payment Transaction` records individual charges and refund transactions. `Shpfy Payout` records aggregated payment disbursements. `Shpfy Dispute` tracks payment chargebacks. These are all read-only imports -- the connector never writes payment data back to Shopify.

Transaction amounts follow the dual-currency pattern. Each transaction stores amounts in both the shop's settlement currency and the presentment currency.

## Inventory

Inventory is BC-to-Shopify only. The `Shpfy Shop Inventory` table maps BC Locations to Shopify Locations. The `Shpfy Shop Location` table stores Shopify location metadata. During inventory sync, the connector calculates available stock for each product at each mapped location using the selected `Shpfy Stock Calculation` strategy (an interface), then pushes the quantities to Shopify via the `inventorySetQuantities` mutation.

## Supporting systems

The `Shpfy Log Entry` table stores API request/response logs when logging is enabled on the Shop (`Logging Mode` = All or Error Only). Retention policies auto-clean old entries.

`Shpfy Synchronization Info` tracks the last sync time per shop and sync type. The order sync uses `Shop Id` (an integer hash) as the key rather than Shop Code, which means order sync times survive shop renames.

The `Shpfy Bulk Operation` table tracks async bulk mutation jobs. Each bulk operation record stores its Shopify-assigned ID, status (Created, Running, Completed, Failed, Canceled), and links to the shop. A webhook notifies the connector when the bulk operation completes.

`Shpfy Sales Channel` tracks which Shopify sales channels (Online Store, POS, etc.) orders originate from, enabling filtering during order import.
