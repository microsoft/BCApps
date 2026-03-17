# Business logic

## Product sync

Product sync is bidirectional, controlled by the `Sync Item` field on the Shop: "To Shopify" exports BC items as Shopify products, "From Shopify" imports Shopify products as BC items, and blank disables sync.

**BC to Shopify**: The `Shpfy Sync Products` report iterates over `Shpfy Product` records linked to the shop. For each product, it builds a temporary product and variant from the linked BC Item, calculates prices (delegating to `OnBeforeCalculateUnitPrice` / `OnAfterCalculateUnitPrice` events in `ShpfyProductEvents`), generates the body HTML from extended text or marketing text, collects tags, and compares the result against the stored Shopify product data. If there are differences -- detected by comparing individual fields and content hashes -- it issues GraphQL mutations to update the product. New items that don't yet have a Shopify product mapping are created via `productCreate` mutations.

Price sync can be run independently of full product sync (the `OnlySyncPrices` parameter on the report). For shops with many products, price updates use bulk operations -- the connector builds a JSONL payload of price list entries and submits it as a Shopify bulk mutation, which processes asynchronously.

**Shopify to BC**: Products fetched from Shopify are matched to existing BC Items using the product mapping logic in `ShpfyProductMapping`. The SKU Mapping field on the Shop controls how Shopify SKUs are parsed to find BC items (by Item No., Vendor Item No., or a compound field separated by the SKU Field Separator). When `Auto Create Unknown Items` is enabled and no match is found, the connector creates a new BC Item using the configured `Item Templ. Code`.

Image sync direction is controlled separately from product sync by the `Sync Item Images` field. Images synced from Shopify to BC are downloaded and stored on the Item card. Images synced to Shopify use either direct upload or bulk operations depending on volume.

## Order import

Order import is strictly Shopify-to-BC. It happens in two phases, both triggered by the `Shpfy Sync Orders from Shopify` report.

**Phase 1 -- Scan and stage**: The connector queries Shopify for orders updated since the last sync time (stored in `Shpfy Synchronization Info`). It creates or updates lightweight `Shpfy Orders to Import` records. This phase is fast -- it only fetches the order list, not full order details. The user can review orders on the "Shopify Orders to Import" page and decide which to process.

**Phase 2 -- Full import and document creation**: For each selected order (or all orders if `Auto Create Orders` is enabled), the connector fetches complete order details from Shopify -- line items, shipping addresses, transactions, fulfillments, returns, refunds, risk assessments. It populates the `Shpfy Order Header` and `Shpfy Order Line` tables.

Then the document creation logic kicks in. It maps the Shopify customer to a BC customer (using the configured mapping strategy), maps each order line to a BC Item (using product mappings), maps the shipment method and shipping agent, and creates a BC Sales Header and Sales Lines. Shipping costs become G/L account lines using the `Shipping Charges Account` from the Shop. Tips go to the `Tip Account`. Gift card payments go to the `Sold Gift Card Account`.

If `Auto Create Orders` is on and an order fails to process, the error is captured on the `Shpfy Orders to Import` record (via `Has Error` and the `Error Message` blob) -- it does not fail the entire batch. This per-entity error handling is a deliberate design choice.

Fully fulfilled orders can be created as Sales Invoices instead of Sales Orders when `Create Invoices From Orders` is enabled. The connector also supports auto-releasing sales orders via `Auto Release Sales Orders`.

After a BC document is created from a Shopify order, the connector can optionally write the BC document number back to Shopify as an order attribute (`Order Attributes To Shopify`) and archive the Shopify order (`Archive Processed Orders`).

## Customer sync

Customer sync is bidirectional. Import direction is controlled by `Customer Import From Shopify` (None, With Order Import, All Customers). Export is triggered manually via the "Add Customer to Shopify" action.

**Shopify to BC**: During import, the connector queries Shopify for customer records and runs them through the mapping strategy selected on the Shop. The `Customer Mapping Type` enum implements `Shpfy ICustomer Mapping`:

- **By Email/Phone** (`ShpfyCustByEmailPhone`): Searches BC customers by email, then phone number
- **By Bill-to Info** (`ShpfyCustByBillto`): Matches on billing address details
- **By Default Customer** (`ShpfyCustByDefaultCust`): Always uses the `Default Customer No.` from the Shop

When no match is found and `Auto Create Unknown Customers` is enabled, the connector creates a new BC Customer using the `Customer Templ. Code` from the Shop. Customer name formatting is controlled by the `Name Source`, `Name 2 Source`, and `Contact Source` fields, each delegating to `Shpfy ICustomer Name` implementations.

Update direction is mutually exclusive: either `Shopify Can Update Customer` or `Can Update Shopify Customer` can be true, never both. This prevents circular update loops.

**BC to Shopify**: When exporting, the connector creates or updates Shopify customer records from BC customer data, including address information and metafields.

## Company sync (B2B)

Company sync follows the same pattern as customer sync but operates on Shopify B2B companies. It requires `B2B Enabled` on the Shop (auto-detected from the Shopify plan). The `Company Mapping Type` enum controls matching strategy (by email/phone, by default company, by tax ID via `ShpfyCompByTaxId`). Company locations are first-class entities -- each location can map to a different BC customer for billing and shipping.

When a B2B order is imported, the connector maps both the customer and the company. The `Purchasing Entity` field on the order indicates whether it was a D2C (direct-to-consumer) or B2B purchase.

## Inventory sync

Inventory sync is BC-to-Shopify only. The `Shpfy Sync Stock to Shopify` report iterates over `Shpfy Shop Inventory` records (which map BC Locations to Shopify Locations) and for each mapped product variant, calculates the available stock using the configured `Shpfy Stock Calculation` interface.

Stock calculation strategies include standard BC inventory calculations (on-hand minus reserved, etc.). The `Shpfy Inventory Events` codeunit raises `OnAfterCalculationStock` to allow subscribers to adjust the calculated quantity -- for example, to subtract safety stock or include quantities from external warehouses.

The connector pushes stock levels to Shopify via the `inventorySetQuantities` mutation, targeting each Shopify location individually.

## Payment and payout processing

The `Shpfy Sync Payments` report imports payout and transaction data from Shopify. Payouts represent the actual disbursements from Shopify to the merchant's bank account. Each payout contains multiple payment transactions (individual charges, refunds, adjustments, etc.).

Dispute sync (`Shpfy Sync Disputes` report) imports chargeback and inquiry records. These are informational only -- the connector does not take automated action on disputes.

## Return and refund processing

Returns and refunds can be handled in three ways, controlled by the `Return and Refund Process` field on the Shop:

- **Import Only**: The connector imports return and refund data into `Shpfy Return Header/Line` and `Shpfy Refund Header/Line` tables but takes no further action. The user manually creates credit memos if needed.
- **Auto Create Credit Memo**: The connector automatically creates BC Sales Credit Memos from refund data. This requires `Auto Create Orders` to also be enabled (validated at the field level). The document source -- whether to base the credit memo on the posted invoice or the posted shipment -- is determined by the `Shpfy IDocument Source` interface.

Refund lines distinguish between restocked items (which get credited as item lines) and non-restocked items (which get credited against the `Refund Acc. non-restock Items` G/L account).

Return location selection follows the `Return Location Priority` setting: either prioritize the Shopify return location (mapped to a BC location) or always use the `Return Location` configured on the Shop.

## Webhooks

The connector supports two types of webhooks:

- **Order Created**: When enabled, Shopify sends a webhook notification whenever a new order is created, allowing near-real-time order import instead of waiting for the next scheduled sync. The webhook user context (who the sync runs as) is stored on the Shop.
- **Bulk Operation**: Used for async bulk operation completion notifications. When a bulk price or image update finishes processing on Shopify's side, the webhook triggers the connector to poll for results.

Webhooks are registered and deregistered via GraphQL mutations in `ShpfyWebhooksMgt`. Disabling the Shop automatically deregisters its webhooks.
