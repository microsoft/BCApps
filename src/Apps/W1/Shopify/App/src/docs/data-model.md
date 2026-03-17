# Data model

## Shop configuration

`Shpfy Shop` (30102) is the central configuration hub and the closest thing this app has to a settings table. Every sync codeunit, every API call, and every mapping decision reads from it. It stores sync direction flags (e.g. `Sync Item` = "To Shopify" or "From Shopify"), customer and company mapping strategy enums, template codes for auto-creation, currency handling, tax area configuration, G/L accounts for shipping charges and tips, and webhook state. The Shop also holds `B2B Enabled`, which is derived from the Shopify plan (Plus or Development) rather than being user-configured.

Each shop tracks its last sync time per sync type via the `Shpfy Synchronization Info` table, keyed by Shop Code (or Shop Id for orders). The Shop Id is a hash of the Shopify URL, not the Shopify internal shop id -- this is important because order sync uses it as a cross-company identifier to prevent duplicate imports when the same Shopify store is connected to multiple BC companies.

`Shpfy Shop Location` maps Shopify locations to BC locations and controls the stock calculation method per location via an extensible enum that resolves to a `Shpfy Stock Calculation` interface implementation.

## Product catalog

The product hierarchy is Product -> Variant -> InventoryItem. `Shpfy Product` (30127) is the parent, linked to a BC Item via `Item SystemId` (Guid). `Shpfy Variant` (30129) belongs to a Product and is linked to both a BC Item (`Item SystemId`) and optionally a BC Item Variant (`Item Variant SystemId`). `Shpfy Inventory Item` (30126) is the physical-inventory counterpart of a variant, carrying country of origin and tracking settings.

Products support up to three option dimensions (Option 1/2/3 Name + Value on the variant), which Shopify uses for things like size/color. The `UoM as Variant` feature on the Shop table repurposes one of these option slots to represent BC units of measure as Shopify variants -- an unusual mapping that means a single BC item with multiple UoMs becomes a single Shopify product with multiple variants.

Change detection uses integer hashes stored on the Product table: `Image Hash`, `Tags Hash`, and `Description Html Hash`. During export, BC computes the hash of the current state and compares it to the stored value. If unchanged, the API call is skipped. This is a performance optimization, not a conflict resolution mechanism.

Products also participate in `Shpfy Product Collection` and `Shpfy Shop Collection Map` for managing Shopify collections (analogous to item categories), and `Shpfy Sales Channel` for controlling product visibility.

## Customer management

`Shpfy Customer` (30105) stores Shopify customer data and links to a BC Customer via `Customer SystemId`. The `Customer No.` field is a FlowField that resolves through the Guid. Customers have child `Shpfy Customer Address` records. The `Shpfy Customer Template` table allows mapping Shopify customers to different BC customer templates based on country.

The customer mapping strategy is driven by the `Customer Mapping Type` enum on the Shop table, which resolves to an `ICustomerMapping` interface implementation. Strategies include: by email, by phone, by bill-to info, always use a default customer, or by email/phone combined. The mapping decision happens during order processing, not customer sync -- this matters because a customer might exist in Shopify but not yet be linked in BC when an order arrives.

Name resolution is separately configurable: `Name Source`, `Name 2 Source`, and `Contact Source` fields on the Shop table control how Shopify's first/last name and company name are mapped to BC's Name, Name 2, and Contact fields using the `ICustomerName` interface.

`Shpfy Tax Area` maps Shopify province/country combinations to BC tax areas, with a configurable priority (`Tax Area Priority` on Shop) for which geographic dimension takes precedence.

## B2B (companies)

`Shpfy Company` (30150) represents a Shopify B2B company and links to a BC Customer via `Customer SystemId` (same pattern as customers). `Shpfy Company Location` (30151) represents the company's locations in Shopify and maps to the same BC customer. Companies have a main contact that links back to a `Shpfy Customer`.

`Shpfy Catalog` (30152) enables per-company pricing. Each catalog is linked to a company via `Company SystemId` and can have its own Customer Price Group and Customer Discount Group, overriding the shop-level defaults. `Shpfy Catalog Price` stores the actual price list entries synced to Shopify. `Shpfy Market Catalog Relation` tracks which Shopify markets a catalog is published to.

Company mapping is controlled by `Company Mapping Type` on the Shop table, using the `ICompanyMapping` interface. Tax registration ID mapping is handled by a separate `Shpfy Comp. Tax Id Mapping` interface.

## Order lifecycle

`Shpfy Order Header` (30118) is the richest table in the app. It carries triple-address (sell-to, bill-to, ship-to), dual-currency amounts (shop currency and presentment currency for every monetary field), B2B fields (Company Id, Company Location Id, PO Number, Due Date, Payment Terms), financial and fulfillment status enums, and linked BC document numbers (Sales Order No., Sales Invoice No.).

`Shpfy Order Line` (30119) carries the line-level detail with Shopify Product/Variant Ids, quantities, prices, discount amounts, and a `Gift Card` and `Tip` boolean for special line handling. Lines also have presentment-currency counterparts for amounts.

Supporting tables include `Shpfy Order Attribute` (key-value pairs from Shopify's note attributes), `Shpfy Order Tax Line` (with channel-liable flag), `Shpfy Order Shipping Charges`, `Shpfy Order Disc. Appl.` (discount applications recording which discounts applied to which lines), and `Shpfy Order Line Attribute`.

`Shpfy Orders to Import` is a staging table used during webhook-driven or manual import. Records enter here first with minimal data, then the full import fills out the Order Header.

## Fulfillment

Two parallel systems coexist. `Shpfy FulFillment Order Header` (30143) and `Shpfy FulFillment Order Line` (30144) represent Shopify's fulfillment orders -- the intent to fulfill specific line items from a specific location. These are imported from Shopify and represent what needs to be shipped.

`Shpfy Order Fulfillment` (30111) and `Shpfy Fulfillment Line` represent actual shipments -- what has been shipped, with tracking numbers and carrier info. The connector exports BC sales shipments as Shopify fulfillments. These two hierarchies are not parent-child; they represent different stages of the fulfillment lifecycle.

## Returns and refunds

Returns and refunds are intentionally separate. `Shpfy Return Header` (30147) and `Shpfy Return Line` represent the customer's return request, with status tracking, decline reasons, and a `Restock Type` enum on the line level (Return, Cancel, NoRestock). Returns have a `Discounted Total Amount` and its presentment counterpart.

`Shpfy Refund Header` (30142) and `Shpfy Refund Line` represent the financial reversal. A refund may link to a return via `Return Id`, but can exist independently (e.g. for an appeasement refund without a physical return). `Shpfy Refund Shipping Line` handles shipping cost refunds separately.

The `Return and Refund Process` enum on the Shop table controls processing strategy: "Import Only" (just store the data) or "Auto Create Credit Memo" (automatically generate a BC sales credit memo). This is implemented via the `IReturnRefundProcess` interface.

## Payments and transactions

`Shpfy Order Transaction` (30117) records payment transactions against orders -- authorization, capture, refund. It links to `Shpfy Transaction Gateway` and `Shpfy Credit Card Company` for payment method identification. `Shpfy Payment Method Mapping` maps Shopify gateways to BC payment methods. `Shpfy Suggest Payment` is a helper for suggesting payment applications.

`Shpfy Payout` and `Shpfy Payment Transaction` support payout reconciliation -- matching Shopify's periodic payouts to individual order transactions. `Shpfy Dispute` tracks payment disputes/chargebacks.

`Shpfy Payment Terms` maps Shopify payment terms to BC payment terms, used primarily for B2B orders with net terms.

## Cross-cutting patterns

**SystemId linking** -- Every entity link (Product->Item, Variant->Item Variant, Customer->Customer, Company->Customer) uses a Guid `SystemId` field with a FlowField for the human-readable Code/No. This survives renumbering and works across companies.

**Dual currency** -- Orders, refunds, and returns all carry amounts in both shop currency and presentment currency. The Shop's `Currency Handling` enum determines which is used for BC document creation.

**Negative auto-incrementing IDs** -- Staging records (like orders to import) use negative BigInteger IDs as temporary placeholders before real Shopify IDs are assigned.

**Document Link traceability** -- `Shpfy Doc. Link To Doc.` (30146) provides a generic many-to-many link between Shopify document types and BC document types, with interface-based navigation in both directions.

**Metafields** -- `Shpfy Metafield` (30101) is a generic key-value store keyed by `Parent Table No.` and `Owner Id`, supporting products, variants, customers, and companies. Metafield definitions and types are handled via `IMetafieldOwnerType` and `IMetafieldType` interfaces.

**Tags** -- `Shpfy Tag` is a generic tag table shared across entity types, keyed by Parent Id.

**Data capture** -- The logging system (`Shpfy Log Entry`) records API requests and responses when enabled, with configurable logging mode (errors only vs. all) and automatic retention policy integration.
