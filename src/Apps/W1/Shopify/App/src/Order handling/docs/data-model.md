# Order handling data model

Detailed schema for order-related tables in the Shopify Connector.

## Order Header table (30118)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Tables\ShpfyOrderHeader.Table.al`

**Primary key**: Shopify Order Id (BigInteger)

### Core order identification

- **Shopify Order Id**: Unique Shopify identifier (legacy resource ID)
- **Shopify Order No.**: Human-readable order number (e.g., "#1001")
- **Shop Code**: Links to Shpfy Shop configuration
- **Customer Id**: Shopify customer legacy ID

### Addresses

Three address groups (Sell-to, Ship-to, Bill-to), each with:

- First Name, Last Name, Name, Name 2
- Address, Address 2, City, Post Code, County
- Country/Region Code, Country/Region Name
- Contact Name, Contact No. (for integration with BC contacts)
- Ship-to also includes Latitude, Longitude

### Amounts and currency

All monetary fields auto-format using currency code expressions.

**Shop currency fields**:
- Total Amount, Subtotal Amount, VAT Amount
- Discount Amount, Shipping Charges Amount
- Total Tip Received, Total Items Amount
- Payment Rounding Amount, Refund Rounding Amount

**Presentment currency fields** (if shop uses presentment currency):
- Presentment Total Amount, Presentment Subtotal Amount
- Presentment VAT Amount, Presentment Discount Amount
- Pres. Shipping Charges Amount, Presentment Total Tip Received
- Pres. Payment Rounding Amount, Pres. Refund Rounding Amount

**Currency codes**:
- Currency Code (shop money, translated to BC currency)
- Presentment Currency Code (customer-facing currency)

### Status fields

- **Financial Status** (Enum): Pending, Authorized, Paid, Partially Paid, Refunded, Partially Refunded, Voided, Expired
- **Fulfillment Status** (Enum): (blank), Unfulfilled, Partial, Fulfilled
- **Return Status** (Enum): Return status tracking
- **Fully Paid** (Boolean): True when payment complete
- **Unpaid** (Boolean): True when not paid
- **Refundable** (Boolean): Can be refunded
- **Confirmed** (Boolean): Order confirmed by customer
- **Closed** (Boolean): Order archived
- **Cancelled At** (DateTime), **Cancel Reason** (Enum)
- **Closed At**, **Processed At**, **Created At**, **Updated At** (DateTime)

### Processing and mapping

- **Sell-to Customer No.**, **Bill-to Customer No.**: Mapped BC customers
- **Sales Order No.**, **Sales Invoice No.**: Created BC documents
- **Processed** (Boolean): True when converted to BC sales document
- **Has Error** (Boolean), **Error Message** (Text[2048])
- **Has Order State Error** (Boolean): Conflict between Shopify and BC state
- **Customer Templ. Code**: Template for auto-creating customers

### Shipping and payment

- **Shipping Method Code**, **Shipping Agent Code**, **Shipping Agent Service Code**
- **Payment Method Code**: Mapped to BC payment methods
- **Payment Terms Type**, **Payment Terms Name**: B2B payment terms
- **Gateway** (Text[50]): Payment gateway name (from transactions)

### B2B fields

- **B2B** (Boolean): True for company orders
- **Company Id**, **Company Location Id**: Shopify company identifiers
- **Company Main Contact Id**, **Company Main Contact Email**, **Company Main Contact Phone No.**
- **Company Main Contact Cust. Id**: BC customer for main contact
- **PO Number**: Purchase order number from company

### Additional fields

- **Document Date**, **Due Date**: BC document dates
- **Work Description** (Blob): Order notes
- **Test** (Boolean): Test order flag
- **Edited** (Boolean): Order was edited after creation
- **Total Weight** (Decimal): Sum of line weights
- **Discount Code**, **Discount Codes**: Applied discount codes
- **VAT Included** (Boolean): Prices include tax
- **Channel Name**, **App Name**: Source of order
- **Source Name**: Order source identifier
- **Retail Location Id**, **Retail Location Name**: Physical store location
- **Salesperson Code**: Assigned salesperson (from staff member)
- **Use Shopify Order No.** (Boolean): Use Shopify number as BC doc number
- **Processed Currency Handling** (Enum): Currency mode when processed
- **Current Total Amount**, **Current Total Items Quantity**: After refunds
- **Line Items Redundancy Code** (Integer): Hash for detecting line changes
- **High Risk** (FlowField): Calculated from risk assessments
- **Channel Liable Taxes** (FlowField): True if any tax is channel-liable

### FlowFields

- **Total Quantity of Items**: Sum of order line quantities (excluding gifts/tips)
- **Number of Lines**: Count of order lines

### Relationships

Deletes cascade to:
- Shpfy Order Line (30119)
- Shpfy Return Header (30147)
- Shpfy Refund Header (30142)
- Shpfy Data Capture (raw JSON)
- Shpfy FulFillment Order Header (30143)
- Shpfy Order Fulfillment (30144)

## Order Line table (30119)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Tables\ShpfyOrderLine.Table.al`

**Primary key**: Shopify Order Id, Line Id

### Core fields

- **Line Id** (BigInteger): Unique line identifier
- **Shopify Order Id** (BigInteger): Parent order
- **Shopify Product Id**, **Shopify Variant Id**: Product references
- **Description** (Text[100]): Line description
- **Variant Description** (Text[50]): Variant title

### Quantity and pricing

- **Quantity** (Decimal, 0:5): Ordered quantity
- **Unit Price** (Decimal): Price in shop currency
- **Presentment Unit Price** (Decimal): Price in presentment currency
- **Discount Amount** (Decimal): Shop currency discount
- **Presentment Discount Amount** (Decimal): Presentment currency discount
- **Fulfillable Quantity** (Decimal): Remaining to fulfill
- **Weight** (Decimal): Line item weight

### Flags

- **Taxable** (Boolean): Line is taxable
- **Gift Card** (Boolean): Line is a gift card
- **Tip** (Boolean): Line is a tip
- **Product Exists** (Boolean): Product exists in Shopify

### Mapping

- **Item No.** (Code[20]): BC item
- **Variant Code** (Code[10]): BC item variant
- **Unit of Measure Code** (Code[10]): BC UOM

### Additional

- **Fulfillment Service** (Text[100]): Service handling fulfillment
- **Location Id** (BigInteger): Shopify location
- **Delivery Method Type** (Enum): Shipping, pickup, etc.

**Keys**:
- Primary: Shopify Order Id, Line Id
- SumIndex: Shopify Order Id, Gift Card, Tip (for quantity sums)

## Order Attribute table (30116)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Tables\ShpfyOrderAttribute.Table.al`

**Primary key**: Order Id, Key

- **Order Id** (BigInteger)
- **Key** (Text[100]): Attribute name
- **Attribute Value** (Text[2048]): Attribute value

Custom attributes are key-value pairs attached to the order (e.g., gift message, special instructions).

## Order Line Attribute table (30149)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Tables\ShpfyOrderLineAttribute.Table.al`

**Primary key**: Order Id, Order Line Id, Key

- **Order Id** (BigInteger)
- **Order Line Id** (Guid): SystemId of order line
- **Key** (Text[100]): Attribute name
- **Value** (Text[250]): Attribute value

Custom attributes at line level (e.g., engraving text, color preference).

## Order Tax Line table (30122)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Tables\ShpfyOrderTaxLine.Table.al`

**Primary key**: Parent Id, Line No.

**Parent Id** can be:
- Order header ID (for order-level taxes)
- Order line ID (for line-level taxes)

Fields:
- **Title** (Code[20]): Tax name (e.g., "VAT", "GST")
- **Rate** (Decimal): Tax rate as decimal (e.g., 0.25)
- **Rate %** (Decimal): Tax rate as percentage (e.g., 25)
- **Amount** (Decimal): Tax amount in shop currency
- **Presentment Amount** (Decimal): Tax amount in presentment currency
- **Channel Liable** (Boolean): Marketplace is responsible for tax

Line No. auto-increments on insert.

## Order Discount Application table (30117)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Tables\ShpfyOrderDiscAppl.Table.al`

**Primary key**: Order Id, Line No.

Describes discount rules applied to the order (not final amounts -- those are in header/line discount fields).

Fields:
- **Type** (Text[50]): Discount type (e.g., "DiscountCodeApplication")
- **Code** (Text[50]): Discount code used
- **Allocation Method** (Enum): How discount is distributed (Across, Each, One)
- **Target Selection** (Enum): What is targeted (All, Entitled, Explicit)
- **Target Type** (Enum): Line item or shipping line
- **Value Type** (Enum): Fixed amount or percentage
- **Value** (Decimal): Discount value

## Enums

### Shpfy Financial Status (30117)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Enums\ShpfyFinancialStatus.Enum.al`

Values: (blank), Pending, Authorized, Partially Paid, Paid, Partially Refunded, Refunded, Voided, Expired, Unknown

### Shpfy Order Fulfill. Status (30118)

Values: (blank), Unfulfilled, Partial, Fulfilled, Restocked

### Shpfy Cancel Reason (30116)

Values: (blank), Customer, Declined, Fraud, Inventory, Other, Staff

### Shpfy Shipment Status (30119)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Enums\ShpfyShipmentStatus.Enum.al`

Values: (blank), Label Printed, Label Purchased, Ready for Pickup, Confirmed, In Transit, Out for Delivery, Delivered, Failure, Attempted Delivery

### Shpfy Currency Handling (30122)

Values: Shop Currency, Presentment Currency

Determines which currency fields are used when creating BC sales documents.
