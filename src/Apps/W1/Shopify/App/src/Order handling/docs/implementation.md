# Order handling module -- implementation details

## Order import pipeline

The pipeline has three stages: fetch, import, and process.

### Stage 1: Fetch orders to import

`Shpfy Orders API` (codeunit 30165) runs against all enabled shops:

1. Reads last sync time from `Shop.GetLastSyncTime("Shpfy Synchronization Type"::Orders)`.
2. If this is the first sync (empty sync time), queries only open orders (`GetOpenOrdersToImport`). Otherwise, queries all orders updated since last sync (`GetOrdersToImport`).
3. Pages through GraphQL results, extracting each order into `Shpfy Orders to Import` (table 30121) with lightweight fields: order no., amounts, financial/fulfillment status, tags, risk level, purchasing entity, country codes.
4. Sets `"Import Action"` to `New` or `Update` depending on whether an `Shpfy Order Header` already exists.
5. Closed orders that are new (not yet imported) are excluded from the import queue.
6. Updates the shop's last sync time.

### Stage 2: Import full order details

`Shpfy Import Order` (codeunit 30161) runs for each `Shpfy Orders to Import` record:

1. Calls Shopify GraphQL to retrieve the full order JSON.
2. Creates or updates `Shpfy Order Header` with all address fields (sell-to, bill-to, ship-to), financial data, currency codes, discount codes, PO number, and B2B company info.
3. Creates `Shpfy Order Line` records for each line item with product/variant IDs, quantities, prices (both shop and presentment currency), discount amounts, and special flags (tip, gift card).
4. Creates `Shpfy Order Tax Line` records with tax title, rate, amount, and channel-liable flag.
5. Creates order attributes, shipping charges, discount applications, and payment gateway records.
6. Handles order risks and refund adjustments.
7. Fires `OnAfterImportShopifyOrderHeader` and `OnAfterCreateShopifyOrderAndLines` events.

### Stage 3: Process to BC documents

`Shpfy Process Orders` (codeunit 30167) iterates unprocessed orders for a shop:

1. For each order, calls `Shpfy Process Order` (codeunit 30166).
2. `Process Order` first runs `Shpfy Order Mapping.DoMapping` to resolve all references.
3. Creates the BC Sales Header and Sales Lines.
4. On success, marks the order as `Processed = true` and records the Sales Order/Invoice No.
5. On failure, sets `"Has Error" = true` with the error message and cleans up the partially created document.
6. After all orders, processes any unprocessed refunds (auto-creates credit memos if configured).

## Order data model

### Shpfy Order Header (table 30118)

Primary key: `"Shopify Order Id"` (BigInteger).

Key field groups:

- **Identity**: `"Shopify Order Id"`, `"Shopify Order No."`, `"Shop Code"`
- **Sell-to address**: First Name, Last Name, Customer Name, Address, City, Post Code, County, Country/Region Code
- **Bill-to address**: Name, Address, City, Post Code, County, Country/Region Code
- **Ship-to address**: Name, Address, City, Post Code, County, Country/Region Code, Latitude, Longitude
- **Financial**: `"Total Amount"`, `"Subtotal Amount"`, `"VAT Amount"`, `"VAT Included"`, `"Discount Amount"`, `"Shipping Charges Amount"`, `"Total Tip Received"`, `"Currency Code"`
- **Presentment amounts**: Parallel set of amount fields in presentment currency (`"Presentment Total Amount"`, etc.)
- **Status**: `"Financial Status"` (enum), `"Fulfillment Status"` (enum), `Confirmed`, `Closed`, `"Cancelled At"`, `"Cancel Reason"` (enum), `"Return Status"` (enum)
- **BC mapping**: `"Sell-to Customer No."`, `"Bill-to Customer No."`, `"Sales Order No."`, `"Sales Invoice No."`, `Processed`, `"Has Error"`, `"Error Message"`
- **B2B**: `B2B`, `"Company Id"`, `"Company Location Id"`, `"Company Main Contact Id/Email/Phone"`
- **Payment**: `Gateway`, `"Payment Method Code"`, `"Payment Terms Type/Name"`, `"Payment Rounding Amount"`
- **Shipping**: `"Shipping Method Code"`, `"Shipping Agent Code"`, `"Shipping Agent Service Code"`

FlowFields: `"Total Quantity of Items"` (sum from lines), `"Number of Lines"` (count), `"High Risk"` (exists from risk table), `"Channel Liable Taxes"` (exists from tax lines).

### Shpfy Order Line (table 30119)

Primary key: `"Shopify Order Id"` + `"Line Id"`.

Fields: `"Shopify Product Id"`, `"Shopify Variant Id"`, `Description`, `Quantity`, `"Unit Price"`, `"Discount Amount"`, presentment price/discount, `Taxable`, `"Gift Card"`, `Tip`, `"Location Id"`, `"Delivery Method Type"`, `Weight`.

BC mapping fields: `"Item No."`, `"Variant Code"`, `"Unit of Measure Code"`.

### Shpfy Order Tax Line (table 30122)

Primary key: `"Parent Id"` + `"Line No."` (auto-incremented).

The `"Parent Id"` references a line ID (not an order ID) -- tax lines are associated with order lines. Fields: `Title`, `Rate`, `"Rate %"`, `Amount`, `"Presentment Amount"`, `"Channel Liable"`.

### Shpfy Orders to Import (table 30121)

Lightweight queue table with `"Entry No."` (auto-increment PK). Indexed by `Id` + `"Shop Id"`. Contains summary data for the orders-to-import list page: order no., amounts, statuses, tags, risk, country codes, and an `"Import Action"` enum (New/Update).

### Supporting tables

- **Shpfy Order Attribute** -- Key/value pairs per order (e.g., custom checkout fields)
- **Shpfy Order Line Attribute** -- Key/value pairs per order line
- **Shpfy Order Disc. Appl.** -- Discount application details
- **Shpfy Order Payment Gateway** -- Payment gateway information

## Status tracking and financial status enums

### Shpfy Financial Status (enum 30117)

Values: (blank), Pending, Authorized, Partially Paid, Paid, Partially Refunded, Refunded, Voided, Expired, Unknown.

### Shpfy Cancel Reason (enum 30116)

Values: (blank), Customer, Fraud, Inventory, Other, Staff, Declined, Unknown.

### Shpfy Currency Handling (enum 30171)

Controls which currency is used for BC document amounts:

- **Shop Currency** -- uses `Shop."Currency Code"` and shop-currency amount fields
- **Presentment Currency** -- uses `"Presentment Currency Code"` and presentment amount fields

The `"Processed Currency Handling"` field on the order header records which mode was used when the order was processed, ensuring consistent display after processing.

## Tax line handling

Tax lines are imported per order line (keyed by `"Parent Id"` = line ID). Each tax line captures:

- `Title` -- tax name (e.g., "GST", "State Tax")
- `Rate` / `"Rate %"` -- the tax rate
- `Amount` / `"Presentment Amount"` -- amounts in both currencies
- `"Channel Liable"` -- whether the sales channel (marketplace) is liable for collecting the tax

The order header has a `"Channel Liable Taxes"` FlowField that checks if any tax line has `"Channel Liable" = true`.

## Order processing flow

`Shpfy Process Order` (codeunit 30166) creates BC sales documents:

### Header creation (`CreateHeaderFromShopifyOrder`)

1. If fulfillment status is Fulfilled and `Shop."Create Invoices From Orders"` is enabled, creates a Sales Invoice; otherwise creates a Sales Order.
2. Optionally uses the Shopify order number as the BC document number (`"Use Shopify Order No."`).
3. Populates sell-to, bill-to, and ship-to addresses from the staging header.
4. Sets currency based on `Shop."Currency Handling"`.
5. Applies tax area (via `OrderMgt.FindTaxArea` using configurable address priority), shipping method, shipping agent, payment method, and payment terms.
6. If `Shop."Order Attributes To Shopify"` is enabled, writes the BC document number back as an order attribute.
7. Creates a `Shpfy Doc. Link To Doc.` record linking the Shopify order to the BC document.

### Line creation (`CreateLinesFromShopifyOrder`)

1. Optionally adds a comment line with the Shopify order number.
2. For each `Shpfy Order Line`:
   - Tips -> G/L Account line using `Shop."Tip Account"`
   - Gift Cards -> G/L Account line using `Shop."Sold Gift Card Account"`
   - Regular items -> Item line with Item No., Variant Code, UoM, Quantity, and prices
   - Location code is set from `Shpfy Shop Location` mapping when available
3. Shipping charges create additional G/L Account lines (or item charge lines via shipment method mapping).
4. A cash rounding line is added if `"Payment Rounding Amount"` is non-zero.
5. Global discounts (order-level minus line-level minus shipping-level) are applied via `SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt`.

### Post-processing

- If `Shop."Auto Release Sales Orders"` is enabled, the sales document is released.
- `OnAfterProcessSalesDocument` event fires with both the Sales Header and Order Header.

## Order mapping (`Shpfy Order Mapping`)

`DoMapping` performs these mapping steps:

### Customer mapping

- For B2C: Uses `Shpfy Customer Template` by ship-to country, falling back to `Shop."Default Customer No."` or creating via `Shpfy Customer Mapping`.
- For B2B: Uses `Shpfy Company Mapping`, with support for company location-level sell-to/bill-to overrides.
- Contact matching: Finds BC Contact records by name under the mapped customer's company contact.

### Item/variant mapping

For each non-tip, non-gift-card order line:

1. Looks up `Shpfy Variant` by the line's `"Shopify Variant Id"`.
2. If the variant isn't mapped to a BC item, triggers a product import (`Shpfy Product Import`) to fetch and map the product.
3. Sets `"Item No."`, `"Variant Code"`, and `"Unit of Measure Code"` on the order line from the variant's BC linkage.

### Shipping/payment mapping

- `MapShippingMethodCode` -- looks up `Shpfy Shipment Method Mapping` by shipping charge title
- `MapShippingAgent` -- same mapping table, for shipping agent code and service code
- `MapPaymentMethodCode` -- resolves from `Shpfy Order Transaction` records (successful sale/capture/authorization transactions)

## Event subscribers and extensibility

`Shpfy Order Events` (codeunit 30162) provides these integration events:

### Import events

- `OnAfterImportShopifyOrderHeader` -- after order header is imported/updated
- `OnAfterCreateShopifyOrderAndLines` -- after full order with lines is created

### Mapping events

- `OnBeforeMapCustomer` / `OnAfterMapCustomer` -- override or augment customer resolution
- `OnBeforeMapCompany` / `OnAfterMapCompany` -- override or augment B2B company resolution
- `OnBeforeMapShipmentMethod` / `OnAfterMapShipmentMethod`
- `OnBeforeMapShipmentAgent` / `OnAfterMapShipmentAgent`
- `OnBeforeMapPaymentMethod` / `OnAfterMapPaymentMethod`

### Processing events

- `OnBeforeProcessSalesDocument` -- modify the order header before document creation
- `OnAfterProcessSalesDocument` -- post-processing after document is created
- `OnBeforeCreateSalesHeader` -- override header creation entirely (set `Handled = true`)
- `OnAfterCreateSalesHeader` -- modify the created Sales Header
- `OnBeforeCreateItemSalesLine` / `OnAfterCreateItemSalesLine` -- intercept line creation
- `OnBeforeCreateShippingCostSalesLine` / `OnAfterCreateShippingCostSalesLine` -- intercept shipping line creation

### Status conversion events

- `OnBeforeConvertToFinancialStatus` -- override financial status parsing
- `OnBeforeConvertToFulfillmentStatus` -- override fulfillment status parsing
- `OnBeforeConvertToOrderReturnStatus` -- override return status parsing

### Refund events

- `OnAfterConsiderRefundsInQuantityAndAmounts` -- adjust after refund deductions are applied

## Page extensions to BC standard pages

`Shpfy Process Order` includes event subscribers that extend BC standard tables:

- `TransferShopifyOrderNoToShipmentHeader` -- copies `"Shpfy Order No."` from Sales Header to Sales Shipment Header during posting
- `TransferShopifyValuesOnBeforeSalesLineInsert` -- preserves Shopify order no., line ID, refund ID, and refund line ID when BC copies sales lines

The `Shpfy Order Mgt.` codeunit provides `ShowShopifyOrder` which navigates from any BC record containing a `"Shpfy Order No."` field to the corresponding Shopify order page.

## POS considerations

Orders from Shopify POS flow through the same import pipeline but have specific behaviors:

- **Immediate fulfillment** -- POS orders are typically already fulfilled by Shopify at the time of import. When `Shop."Create Invoices From Orders"` is enabled, these create Sales Invoices instead of Sales Orders. Because invoices don't reduce inventory levels, consider posting them immediately or via a scheduled job queue (Report 297 "Batch Post Sales Invoices").
- **Cash rounding** -- Cash transactions on POS automatically round to the nearest denomination in countries that don't use small coins. The rounding adjustment is imported into `"Payment Rounding Amount"` on the order header and posted to the G/L account defined in `Shop."TIP/Cash Rounding Account No."`. Only cash payments are rounded; non-cash payments are not.
- **Archive setting** -- The Shopify Admin setting "Automatically archive the order" must be disabled, because archived orders cannot be imported by the connector.
- **Missing addresses** -- POS orders often lack detailed address information. When using "By EMail/Phone" or "By Bill-to Info" customer mapping, POS orders may fall back to the default customer.

## Key tables and relationships

```
Shpfy Shop (1) ----< Shpfy Order Header (N)
                         |
                         |--- "Sell-to Customer No." --> Customer (BC)
                         |--- "Sales Order No." --> Sales Header (BC)
                         |--- "Sales Invoice No." --> Sales Header (BC)
                         |
                         +----< Shpfy Order Line (N)
                         |        |--- "Shopify Product Id" --> Shpfy Product
                         |        |--- "Shopify Variant Id" --> Shpfy Variant
                         |        |--- "Item No." --> Item (BC)
                         |        +----< Shpfy Order Tax Line (N)
                         |
                         +----< Shpfy Order Attribute (N)
                         +----< Shpfy Order Shipping Charges (N)

Shpfy Orders to Import (queue) --> Shpfy Order Header (staging)
                                      --> Sales Header (BC document)
```
