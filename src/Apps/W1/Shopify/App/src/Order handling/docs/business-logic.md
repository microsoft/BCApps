# Order handling business logic

Describes the order import and processing flows.

## Order import flow

Entry point: `Shpfy Import Order` codeunit (30161)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyImportOrder.Codeunit.al`

### Import steps

1. **Retrieve order header JSON** via GraphQL query `GetOrderHeader`:
   - Fetches order metadata (customer, addresses, totals, status)
   - Stores raw JSON in `Shpfy Data Capture` table for audit

2. **Retrieve order lines JSON** via paginated GraphQL query `GetOrderLines`:
   - Fetches line items with product/variant IDs, quantities, prices, discounts
   - May require multiple API calls if order has many lines (pagination via `After` cursor)

3. **Parse and insert order header**:
   - Call `SetNewOrderHeaderValuesFromJson` to populate Shpfy Order Header fields
   - Call `SetEditableOrderHeaderValuesFromJson` for status/amount fields
   - Create record if new, update if existing

4. **Parse and insert order lines**:
   - Call `SetOrderLineValuesFromJson` for each line
   - Insert into Shpfy Order Line table
   - Calculate `Line Items Redundancy Code` (hash of line IDs) to detect changes

5. **Create related records**:
   - Tax lines (header and line-level)
   - Custom attributes (order and line-level)
   - Shipping charges (separate table)
   - Payment gateway transactions
   - Tags
   - Risk assessments
   - Fulfillment orders
   - Returns and refunds (if enabled)

6. **Adjust for refunds**:
   - Call `ConsiderRefundsInQuantityAndAmounts` to subtract refunded quantities and amounts from order totals
   - Delete zero-quantity lines

7. **Detect conflicts**:
   - If order is already processed in BC and Shopify data changed, set `Has Order State Error`
   - Prevents overwriting BC documents with stale Shopify data

8. **Auto-close if configured**:
   - If order is fulfilled, paid, and shop setting `Archive Processed Orders` is enabled, close order in Shopify

### Currency translation

Function `TranslateCurrencyCode` (line 646):
- Maps Shopify ISO code (e.g., "USD") to BC currency code
- Returns blank if currency matches LCY
- Uses Currency table field "ISO Code"

### Customer name construction

Functions `GetName`, `GetName2`, `GetContactName` (lines 824-859):
- Use shop configuration interfaces `ICustomer Name` to derive Name, Name 2, Contact Name
- Can use FirstName + LastName, CompanyName, or combination
- Ensures BC customer record has correct display name

## Order processing flow

Entry point: `Shpfy Process Orders` codeunit (30167)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyProcessOrders.Codeunit.al`

### Processing steps

1. **Filter orders**: Set filter for Shop Code, Processed = false
2. **Loop through orders**: For each unprocessed order, call `ProcessShopifyOrder`
3. **Single order processing** (`Shpfy Process Order` codeunit 30166):
   - Map customers, items, variants (see Mapping section below)
   - Create sales header
   - Create sales lines
   - Apply global discounts
   - Optionally release document
4. **Mark as processed** or capture error
5. **Process refunds** (if shop setting is "Auto Create Credit Memo")

## Mapping flow

Entry point: `Shpfy Order Mapping` codeunit (30163)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyOrderMapping.Codeunit.al`

### Header mapping

Function `DoMapping` (line 29):
1. **Customer mapping**:
   - For B2C: Call `MapHeaderFields` which uses `Shpfy Customer Mapping` to resolve Shopify customer ID to BC customer
   - For B2B: Call `MapB2BHeaderFields` which uses `Shpfy Company Mapping` to resolve company ID/location to BC customer
   - Falls back to default customer if mapping fails
   - Creates customer if `Auto Create Unknown Customers` is enabled

2. **Contact mapping**:
   - Call `FindContactNo` to link BC contact to customer using contact name
   - Separate contacts for Sell-to, Bill-to, Ship-to

3. **Shipping method mapping**:
   - `MapShippingMethodCode`: Maps Shopify shipping title to BC shipment method code

4. **Shipping agent mapping**:
   - `MapShippingAgent`: Maps to BC shipping agent and service code

5. **Payment method mapping**:
   - `MapPaymentMethodCode`: Maps Shopify gateway to BC payment method code

### Line mapping

Function `MapVariant` (line 191):
1. **Lookup Shpfy Variant** record by Shopify Variant Id
2. If variant not found or not linked to BC item:
   - Call `Shpfy Product Import` to import/sync product from Shopify
   - Retry variant lookup
3. **Get BC item and variant**:
   - Read `Item SystemId` from Shpfy Variant
   - Read `Item Variant SystemId` from Shpfy Variant
   - Populate order line fields: Item No., Variant Code, Unit of Measure Code

### Customer mapping details

Function `MapHeaderFields` (line 86):
1. Build JSON object with Sell-to address fields
2. Call `Shpfy Customer Mapping.DoMapping(CustomerId, JAddress, ShopCode, TemplateCode, AllowCreate)`
3. Repeat for Bill-to address
4. If Sell-to customer is blank, use Bill-to customer
5. Events `OnBeforeMapCustomer` and `OnAfterMapCustomer` allow customization

### B2B mapping details

Function `MapB2BHeaderFields` (line 141):
1. If `Company Location Id` exists, call `MapSellToBillToCustomersFromCompanyLocation` to use location-specific customer
2. Otherwise, call `Shpfy Company Mapping.DoMapping(CompanyId, TemplateCode, AllowCreate)`
3. Use same customer for both Sell-to and Bill-to
4. Map location code for inventory purposes

## Sales document creation

Entry point: `Shpfy Process Order` codeunit (30166)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyProcessOrder.Codeunit.al`

### Create sales header

Function `CreateHeaderFromShopifyOrder` (line 65):

1. **Determine document type**:
   - If order is fulfilled and shop setting `Create Invoices From Orders` is enabled: Create invoice
   - Otherwise: Create sales order

2. **Initialize sales header**:
   - Insert with `SetHideValidationDialog(true)` to skip UI prompts
   - Optionally use Shopify order number as BC document number (if `Use Shopify Order No.` is true)

3. **Populate header fields**:
   - Sell-to Customer No., Name, Address, City, Country/Region Code, etc.
   - Bill-to Customer No., Name, Address, etc.
   - Ship-to Name, Address, etc.
   - Prices Including VAT (from order `VAT Included`)
   - Currency Code (based on `Currency Handling` setting)
   - Document Date (from order `Document Date`)
   - External Document No. (from order `PO Number`)
   - Due Date (from payment terms)
   - Tax Area Code (if tax area mapping exists)
   - Shipment Method Code, Shipping Agent Code, Payment Method Code
   - Payment Terms Code (mapped from payment terms type/name)
   - Salesperson Code (from staff member)

4. **Set work description**: Copy order notes (blob field)

5. **Track in link table**: Insert `Shpfy Doc. Link To Doc.` to relate Shopify order to BC document

6. **Trigger events**: `OnBeforeCreateSalesHeader`, `OnAfterCreateSalesHeader`

### Create sales lines

Function `CreateLinesFromShopifyOrder` (line 208):

1. **Optional info line**: If shop setting `Shopify Order No. on Doc. Line` is enabled, insert description-only line with Shopify order number

2. **Loop through order lines**:
   - Create sales line for each order line
   - Set type based on flags:
     - Tip → G/L Account (shop field `Tip Account`)
     - Gift Card → G/L Account (shop field `Sold Gift Card Account`)
     - Regular item → Type = Item, No. = mapped item
   - Validate Unit of Measure Code, Variant Code
   - Validate Quantity
   - Validate Unit Price and Line Discount Amount (use shop or presentment currency based on setting)
   - Store Shopify Line Id in `Shpfy Order Line Id` field
   - Auto-reserve if item and reservation policy is Always

3. **Shipping charge lines**:
   - Loop through `Shpfy Order Shipping Charges` records
   - Create line with Type = G/L Account or Charge (Item) based on shipment method mapping
   - Set quantity = 1, unit price = shipping amount
   - If Type = Charge (Item), call `AssignItemCharges` to allocate charge to item lines equally

4. **Rounding line**:
   - If `Payment Rounding Amount` or `Pres. Payment Rounding Amount` is non-zero:
     - Create line with Type = G/L Account (shop field `Cash Roundings Account`)
     - Quantity = 1, Unit Price = rounding amount
     - Description = "Cash rounding"

5. **Trigger events**: `OnBeforeCreateItemSalesLine`, `OnAfterCreateItemSalesLine`, `OnBeforeCreateShippingCostSalesLine`, `OnAfterCreateShippingCostSalesLine`

### Apply global discounts

Function `ApplyGlobalDiscounts` (line 185):
1. Calculate order-level discount: `Order.Discount Amount - Sum(Line.Discount Amount) - Sum(Shipping.Discount Amount)`
2. If positive, call `Sales - Calc Discount By Type.ApplyInvDiscBasedOnAmt` to create invoice discount on sales header

### Item charge assignment

Functions `AssignItemCharges`, `PrepareAssignItemChargesLines`, `GetItemChargeAssgntLineAmt`, `GetAssignableQty` (lines 351-432):
1. Calculate assignable quantity and line amount for shipping charge
2. Call `Item Charge Assgnt. (Sales).AssignItemCharges` with "Assign Equally" option
3. Creates `Item Charge Assignment (Sales)` records linking shipping charge to all item lines proportionally

## Order state conflict detection

Function `IsImportedOrderConflictingExistingOrder` (line 236 in ShpfyImportOrder):

Conflict occurs when order is already processed in BC and Shopify data changed:
1. **Quantity change**: `Current Total Items Quantity` increased
2. **Line change**: Hash of line IDs changed (new lines added, lines removed)
3. **Shipping change**: `Shipping Charges Amount` changed

When conflict detected:
- Set `Has Order State Error` = true
- Set `Error Message` = "The order has already been processed..."
- User must manually reconcile BC document with Shopify changes

## Events for customization

Codeunit `Shpfy Order Events` (30160) exposes integration events:

- `OnBeforeProcessSalesDocument`: Before mapping and creating sales document
- `OnAfterProcessSalesDocument`: After sales document created
- `OnBeforeCreateSalesHeader`: Before sales header insert
- `OnAfterCreateSalesHeader`: After sales header created
- `OnBeforeCreateItemSalesLine`: Before each item line insert
- `OnAfterCreateItemSalesLine`: After each item line created
- `OnBeforeCreateShippingCostSalesLine`: Before shipping line insert
- `OnAfterCreateShippingCostSalesLine`: After shipping line created
- `OnBeforeMapCustomer`: Before customer mapping
- `OnAfterMapCustomer`: After customer mapped
- `OnBeforeMapCompany`: Before B2B company mapping
- `OnAfterMapCompany`: After company mapped
- `OnAfterImportShopifyOrderHeader`: After order header imported from Shopify
- `OnAfterCreateShopifyOrderAndLines`: After complete order import
- `OnAfterConsiderRefundsInQuantityAndAmounts`: After refund adjustments
- `OnBeforeConvertToFinancialStatus`, `OnBeforeConvertToFulfillmentStatus`, `OnBeforeConvertToOrderReturnStatus`: Custom enum conversion

## Payment gateway and transactions

Table `Shpfy Order Payment Gateway` stores gateway information.

Codeunit `Shpfy Transactions` imports transaction records (authorization, capture, sale, refund) and populates the `Gateway` field on order header with the gateway name from the first successful transaction.

## Auto-release

If shop setting `Auto Release Sales Orders` is enabled:
- Call `Release Sales Document.Run(SalesHeader)` after creating lines (line 51 in ShpfyProcessOrder)
- Released orders can be posted immediately
