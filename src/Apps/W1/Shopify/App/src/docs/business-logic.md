# Business logic

## Product synchronization

Product sync is bidirectional, controlled by `Shop."Sync Item"` ("To Shopify" or "From Shopify"). The entry point is `Shpfy Sync Products` (30185).

**Import (Shopify to BC)** starts with `ProductApi.RetrieveShopifyProductIds`, which fetches product IDs updated since the last sync time. For each ID, the full product data is fetched and written to the `Shpfy Product` and `Shpfy Variant` tables. If the product is already linked to a BC Item (via `Item SystemId`), the existing link is preserved. If not, and `Auto Create Unknown Items` is enabled on the Shop, a new Item is created from the configured item template. The sync records the timestamp so subsequent runs are incremental.

**Export (BC to Shopify)** is driven by `Shpfy Product Export`, which iterates BC Items and matches them to existing Shopify products via the SystemId link. Hash-based change detection (`Image Hash`, `Tags Hash`, `Description Html Hash`) prevents unnecessary API calls. New items that have no Shopify counterpart are created via the `productCreate` mutation. Price sync can run independently of full product sync via the `OnlySyncPrice` flag, which is also exposed through the Bulk Operations system for better throughput.

A subtle gotcha: product images and product data are synced by separate codeunits (`Shpfy Sync Product Image` vs `Shpfy Sync Products`). Image sync runs after product sync and uses the `Image Hash` to detect changes. Image uploads go through Shopify's staged upload mechanism (create upload URL, upload to staging, then attach to product).

## Order import and processing

Order processing is a three-phase pipeline: Import -> Mapping -> Processing.

**Import** (`Shpfy Import Order`, `Shpfy Orders API`) fetches orders from Shopify that have been updated since the last sync. The import writes raw Shopify data to `Shpfy Order Header` and `Shpfy Order Line`. This phase also imports associated data: tax lines, shipping charges, discount applications, attributes, and refunds. The import deducts refund quantities from order line quantities -- this is the "refund netting" behavior, and it means that by the time an order reaches BC, the quantities already reflect any partial refunds. There is an event (`OnAfterDeductRefundedQuantity`) that fires after this netting for extensions that need to react.

**Mapping** (`Shpfy Order Mapping`) resolves Shopify entities to BC entities: customer mapping (via the configurable `ICustomerMapping` strategy), shipment method mapping, shipping agent mapping, and payment method mapping. Each mapping step has Before/After integration events. If the order is B2B, company mapping runs instead of (or in addition to) customer mapping. Mapping can fail if a required entity cannot be resolved and auto-creation is disabled.

**Processing** (`Shpfy Process Order`, 30166) creates the BC sales document. The document type is determined by fulfillment status: if the order is fully fulfilled and `Create Invoices From Orders` is enabled, a Sales Invoice is created; otherwise, a Sales Order. The codeunit copies all three address sets (sell-to, bill-to, ship-to) from the order header, handles currency selection based on the Shop's `Currency Handling` setting, and creates lines for items, shipping charges, and tips. Gift card lines are handled specially -- they go to the `Sold Gift Card Account` G/L account. Auto-release is configurable via `Auto Release Sales Orders`.

A non-obvious detail: the `Use Shopify Order No.` setting causes the BC document to use the Shopify order number (e.g. "#1001") as its document No., which requires the number series to have `Allow Manual Nos.` enabled.

## Customer synchronization

Customer sync is more nuanced than product sync because of the mapping strategies. The `Customer Import From Shopify` enum controls when customers are imported: "All Customers" fetches everyone, "With Order Import" only imports customers referenced by orders.

The mapping strategy (`Customer Mapping Type` on Shop) determines how a Shopify customer is matched to a BC customer. The `ICustomerMapping` interface has implementations for email-based, phone-based, bill-to-based, and default-customer strategies. Each strategy attempts to find an existing BC customer; if none is found and `Auto Create Unknown Customers` is enabled, a new customer is created from the template specified on the Shop.

Name resolution is a separate concern from mapping. The `Name Source`, `Name 2 Source`, and `Contact Source` settings on the Shop table control how Shopify's first name, last name, and company name are assembled into BC's Name, Name 2, and Contact fields. The `County Source` setting controls whether the province code or name is used for the BC county field.

Update direction is bidirectional but exclusive: `Shopify Can Update Customer` and `Can Update Shopify Customer` are mutually exclusive flags on the Shop.

## Inventory synchronization

`Shpfy Sync Inventory` (30197) runs in two phases: import current stock levels from Shopify, then export calculated BC stock levels back to Shopify.

The import phase iterates `Shpfy Shop Location` records that have a non-disabled `Stock Calculation` method, calling `InventoryApi.ImportStock` for each. The export phase uses the `Shpfy Stock Calculation` interface to compute available stock. Built-in implementations include "Free Inventory" (on hand minus reserved) and "Balance Today" (projected balance as of today). Extensions can add custom calculations.

Location mapping is critical: each `Shpfy Shop Location` maps a Shopify location to a BC location and specifies the stock calculation method to use. The `Shpfy Inventory Item` table tracks which Shopify inventory items exist and their tracking settings.

The inventory API uses `inventorySetQuantities` mutations to push stock levels, which is an absolute-set operation (not a delta). The connector also supports activating inventory tracking on Shopify items via `inventoryItemUpdate`.

## Return and refund processing

Returns and refunds are imported as part of order sync. The `Return and Refund Process` setting on the Shop controls what happens after import.

With "Import Only", return and refund data is stored in `Shpfy Return Header/Line` and `Shpfy Refund Header/Line` but no BC documents are created. This is the default and safest option.

With "Auto Create Credit Memo", the `IReturnRefundProcess` interface implementation creates a BC Sales Credit Memo from the refund data. The credit memo uses the refund lines to determine quantities and amounts. The `Refund Account` and `Refund Acc. non-restock Items` G/L accounts on the Shop control where non-item refund amounts are posted.

The `Return Location Priority` setting determines which BC location is used for the credit memo: the return location configured on the Shop, or the location from the original order.

A key distinction: refund netting (deducting refund quantities from order lines) happens during order import regardless of the `Return and Refund Process` setting. The processing setting only controls whether a separate credit memo is created.

## Fulfillment export

When a BC sales shipment is posted, the connector can export it as a Shopify fulfillment. The `Shpfy Order Fulfillments` codeunit handles this, creating fulfillments via the `fulfillmentCreate` mutation. Tracking information (number, URL, company) from the BC shipment is included.

The `Send Shipping Confirmation` flag on the Shop controls whether Shopify sends a shipping notification email to the customer when the fulfillment is created.

Fulfillment orders (the intent side) are imported from Shopify for visibility but are not directly created or modified by the connector. The connector works with the actual fulfillment API.

## Background sync

Background sync is managed through BC's Job Queue infrastructure. Each sync type (products, customers, orders, inventory, companies) can be scheduled as a recurring job queue entry. The `Allow Background Syncs` flag on the Shop enables this.

Webhook-driven order import is an alternative to polling. When `Order Created Webhooks` is enabled on the Shop, a Shopify webhook subscription is created. When an order is created in Shopify, the webhook fires, BC's webhook infrastructure receives it, and `Shpfy Webhook Notification` (30363) processes it. The handler is multi-company aware: it looks up the Shop by URL across all companies with that Shop enabled and schedules a task in each matching company.

Bulk operations (e.g. bulk product price updates) use Shopify's async bulk mutation API. The connector submits a JSONL payload via `bulkOperationRunMutation`, then polls or receives a webhook when the operation completes. The `Shpfy Bulk Operation` table tracks the operation status and the `IBulk Operation` interface handles revert logic for failed requests.
