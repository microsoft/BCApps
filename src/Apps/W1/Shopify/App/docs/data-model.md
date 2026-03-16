# Data model

## Overview

The Shopify Connector data model supports bidirectional synchronization between Shopify and Business Central. It uses SystemId-based linking rather than traditional No. field relationships, enabling flexible mapping between Shopify entities and BC master data. The model supports B2B commerce, multi-currency orders, and comprehensive order lifecycle tracking from creation through fulfillment and returns.

## Tables grouped by domain

### Shop configuration

**Shpfy Shop (30102)** -- Primary configuration table
- **Primary key**: Code (Code[20])
- **Key fields**: Shopify URL, Shop Id (hash of URL), Enabled
- **Relationships**: Referenced by all entity tables via "Shop Code" field
- **Purpose**: Stores all synchronization settings: import ranges, auto-creation flags, mapping types, currency handling, webhook configuration, B2B settings
- **Key settings**: Sync Item, Auto Create Orders, Customer/Company Mapping Type, Currency Code, Logging Mode, Allow Outgoing Requests

**Shpfy Synchronization Info (30163)** -- Last sync timestamp tracking
- **Primary key**: Shop Code, Synchronization Type
- **Purpose**: Tracks last sync time for Orders, Products, Customers, Companies to enable incremental synchronization

**Shpfy Shop Location (30113)** -- Shopify location to BC location mapping
- **Primary key**: Shop Code, Id
- **Relationships**: TableRelation to Shpfy Shop, Location Filter links to BC Location
- **Purpose**: Maps Shopify fulfillment locations to BC inventory locations for stock synchronization

### Product catalog

**Shpfy Product (30127)** -- Shopify product master
- **Primary key**: Id (BigInteger)
- **Key fields**: Item SystemId (Guid), Shop Code, Title, Status, Has Variants
- **Relationships**: Links to BC Item via SystemId, parent of Shpfy Variant
- **Change tracking**: Image Hash, Tags Hash, Description Html Hash, Last Updated by BC
- **Purpose**: Represents Shopify products with sync metadata

**Shpfy Variant (30129)** -- Product variants
- **Primary key**: Id (BigInteger)
- **Key fields**: Product Id, Item SystemId, Item Variant SystemId, SKU, Barcode
- **Relationships**: Parent Product Id → Shpfy Product, links to BC Item/Item Variant via SystemId
- **Pricing**: Price, Compare at Price, UoM, Tax Code
- **Purpose**: Represents sellable SKUs; one variant per product for non-variant products

**Shpfy Product Image (30130)** -- Product images
- **Primary key**: Id (BigInteger)
- **Relationships**: Product Id → Shpfy Product, Media Content → Blob
- **Purpose**: Stores product images for bidirectional sync

**Shpfy Catalog Price (30153)** -- B2B catalog pricing
- **Primary key**: Company Location Id, Variant Id
- **Purpose**: Context-specific pricing for B2B company locations

### Customer management

**Shpfy Customer (30105)** -- Shopify customer master
- **Primary key**: Id (BigInteger)
- **Key fields**: Customer SystemId (Guid), Shop Id, Email, Phone No., State
- **Relationships**: Links to BC Customer via SystemId
- **Purpose**: Shopify customer with marketing preferences, tax exemption, currency

**Shpfy Customer Address (30109)** -- Customer addresses
- **Primary key**: Customer Id, Id (BigInteger)
- **Relationships**: Customer Id → Shpfy Customer
- **Fields**: Standard address fields (Name, Address, City, Zip, Country/Region, County) plus Shopify Id for sync
- **Purpose**: Stores multiple addresses per customer; default address flagged

**Shpfy Tax Area (30147)** -- Tax jurisdiction mapping
- **Primary key**: Shop Code, Country/Region Code, County
- **Relationships**: TableRelation to Tax Area
- **Purpose**: Maps Shopify locations to BC tax areas for sales tax calculation

### B2B and company

**Shpfy Company (30150)** -- Shopify B2B companies
- **Primary key**: Id (BigInteger)
- **Key fields**: Customer SystemId (Guid), Shop Code, Shop Id, Name
- **Relationships**: Links to BC Customer via SystemId, Main Contact Customer Id links to Shpfy Customer
- **Purpose**: Represents B2B company entities for Shopify Plus

**Shpfy Company Location (30151)** -- Company billing/shipping addresses
- **Primary key**: Id (BigInteger)
- **Relationships**: Company Id → Shpfy Company
- **Fields**: Standard address fields, Tax Exemptions, Locale, Buyer Experience Config
- **Purpose**: Company-specific shipping and billing locations with tax settings

**Shpfy Market Catalog Relation (30400)** -- Market to catalog mapping
- **Primary key**: Shop Code, Market Id, Catalog Id
- **Purpose**: Links Shopify markets to catalogs for B2B pricing

### Order processing

**Shpfy Order Header (30118)** -- Order master
- **Primary key**: Shopify Order Id (BigInteger)
- **Key fields**: Shop Code, Shopify Order No., Customer Id, Company Id, Sell-to Customer No., Sales Order No., Processed
- **Dual currency**: Currency Code + amounts, Presentment Currency Code + Pres. amounts
- **Status tracking**: Financial Status, Fulfillment Status, Return Status, Confirmed, Closed
- **Relationships**: Customer Id → Shpfy Customer, Company Id → Shpfy Company, links to Sales Header via Sales Order No./Sales Invoice No.
- **Address sets**: Bill-to, Ship-to, Sell-to (First Name, Last Name, Address, City, Post Code, Country/Region, County)
- **Amounts**: Total Amount, Subtotal Amount, VAT Amount, Shipping Charges, Discount Amount, Total Tip Received (in both currencies)
- **B2B fields**: Company Id, Company Main Contact Id, PO Number, Due Date, Payment Terms Type/Name
- **Purpose**: Complete order header with all metadata needed for BC sales document creation

**Shpfy Order Line (30119)** -- Order line items
- **Primary key**: Shopify Order Id, Line Id (BigInteger)
- **Key fields**: Shopify Product Id, Shopify Variant Id, Quantity, Unit Price, Discount Amount
- **Relationships**: Parent order, product, and variant links; Location Id → Shpfy Shop Location
- **Special line types**: Gift Card (Boolean), Tip (Boolean), Taxable (Boolean)
- **Purpose**: Order line details for sales document creation

**Shpfy Order Tax Line (30135)** -- Tax line details
- **Primary key**: Parent Id, Line Id (BigInteger)
- **Relationships**: Parent Id can be Order Id or Order Line Id (header-level or line-level tax)
- **Fields**: Rate, Title, Tax Amount, Channel Liable (marketplace facilitator tax)
- **Purpose**: Detailed tax breakdown for order processing

**Shpfy Order Shipping Charges (30134)** -- Shipping cost breakdown
- **Primary key**: Shopify Order Id, Id (BigInteger)
- **Fields**: Title, Presentment Amount, Amount, Discounted Presentment Amount, Discounted Amount
- **Purpose**: Shipping charges to map to BC sales line

**Shpfy Order Risk (30136)** -- Fraud analysis
- **Primary key**: Order Id, Id (BigInteger)
- **Fields**: Level (enum: Low, Medium, High), Recommendation (enum: Accept, Investigate, Cancel), Message
- **Purpose**: Shopify fraud detection results for order review

### Fulfillment

**Shpfy Order Fulfillment (30120)** -- Fulfillment records
- **Primary key**: Shopify Fulfillment Id (BigInteger)
- **Relationships**: Shopify Order Id → Shpfy Order Header
- **Fields**: Status, Tracking Company, Tracking Numbers, Tracking Urls, Shipment Status
- **Purpose**: Tracks shipment status and tracking information

**Shpfy Fulfillment Order Header (30460)** -- Fulfillment orders
- **Primary key**: Shopify Fulfillment Order Id (BigInteger)
- **Relationships**: Shopify Order Id → Shpfy Order Header
- **Fields**: Status, Request Status, Assigned Location Id, Fulfill At
- **Purpose**: Shopify fulfillment order entity for third-party fulfillment

**Shpfy Fulfillment Order Line (30461)** -- Fulfillment line items
- **Primary key**: Id (BigInteger)
- **Relationships**: Fulfillment Order Id → parent header, Order Line Id → Shpfy Order Line
- **Fields**: Quantity, Remaining Quantity
- **Purpose**: Line-level fulfillment tracking

**Shpfy Fulfillment Line (30121)** -- Shipment line details
- **Primary key**: Shopify Fulfillment Id, Id (BigInteger)
- **Relationships**: Links fulfillment to order line
- **Purpose**: Connects fulfillment records to specific order lines

### Returns and refunds

**Shpfy Return Header (30140)** -- Return requests
- **Primary key**: Id (BigInteger)
- **Relationships**: Order Id → Shpfy Order Header
- **Status**: Return Status (Canceled, Closed, Open, Declined), Decline Reason
- **Fields**: Total Quantity, Total Return Line Price Amount, Name (return number)
- **Purpose**: Return authorization from customer

**Shpfy Return Line (30141)** -- Return line items
- **Primary key**: Return Id, Id (BigInteger)
- **Relationships**: Links to Order Line, Refund Line
- **Fields**: Quantity, Return Reason, Return Reason Note, Restock, Refund Price, Refund Tax
- **Purpose**: Specific items being returned with quantities and reasons

**Shpfy Refund Header (30142)** -- Refund records
- **Primary key**: Id (BigInteger)
- **Relationships**: Order Id → Shpfy Order Header, Return Id → Shpfy Return Header (optional)
- **Fields**: Total Refunded Amount (dual currency), Note, Restock
- **Purpose**: Financial refund issued for returns or order adjustments

**Shpfy Refund Line (30143)** -- Refund line items
- **Primary key**: Refund Id, Id (BigInteger)
- **Relationships**: Line Id → Shpfy Order Line, Location Id → Shpfy Shop Location
- **Fields**: Quantity, Subtotal, Total Tax, Restock Type
- **Purpose**: Line-level refund details for credit memo creation

**Shpfy Refund Shipping Line (30144)** -- Shipping refunds
- **Primary key**: Refund Id, Id (BigInteger)
- **Fields**: Amount, Maximum Refundable, Full Refund
- **Purpose**: Tracks refunded shipping charges

### Payments and financial

**Shpfy Order Transaction (30133)** -- Payment transactions
- **Primary key**: Shopify Transaction Id (BigInteger)
- **Relationships**: Shopify Order Id → Shpfy Order Header
- **Fields**: Amount, Type (enum: Authorization, Capture, Sale, Refund, Void), Status (enum: Pending, Success, Failure, Error), Gateway, Message, Authorization, Parent Id
- **Purpose**: Payment transaction history for reconciliation

**Shpfy Gift Card (30110)** -- Gift card usage
- **Primary key**: Id (BigInteger)
- **Relationships**: Order Id → Shpfy Order Header
- **Fields**: Amount, Last Characters, Line Item Id
- **Purpose**: Tracks gift card payments applied to orders

### Metadata and tags

**Shpfy Tag (30114)** -- Entity tags
- **Primary key**: Parent Table No., Parent Id, Tag
- **Relationships**: Polymorphic parent (Product, Customer, Order)
- **Purpose**: Stores Shopify tags for filtering and categorization

**Shpfy Metafield (30101)** -- Custom metadata
- **Primary key**: Id (BigInteger)
- **Key fields**: Parent Table No., Owner Id, Namespace, Name (key)
- **Relationships**: Polymorphic owner (Product, Variant, Customer, Company, Order)
- **Value fields**: Value (Text[2048]), Type (enum defining 50+ Shopify metafield types)
- **Purpose**: Stores custom fields from Shopify metafields for bidirectional sync

### System and infrastructure

**Shpfy Log Entry (30115)** -- Diagnostic logging
- **Primary key**: Id (BigInteger)
- **Fields**: Time, Message, Context, Severity, Area, Tag, User, Company, Linked To Table, Linked To Id
- **Purpose**: Detailed request/response logging when Logging Mode = All

**Shpfy Skipped Record (30159)** -- Failed sync tracking
- **Primary key**: Table ID, Shopify Id (BigInteger)
- **Fields**: Error, System Created At
- **Purpose**: Tracks records that failed to sync for later review

**Shpfy Data Capture (30162)** -- GraphQL response cache
- **Primary key**: Entry No. (BigInteger)
- **Relationships**: Linked To Table, Linked To Id (polymorphic)
- **Fields**: Request Id (Guid), Data (Blob), Captured At
- **Purpose**: Stores raw JSON responses for troubleshooting

**Shpfy Bulk Operation (30148)** -- Async operation tracking
- **Primary key**: Id (BigInteger)
- **Relationships**: Shop Code → Shpfy Shop
- **Fields**: Status (enum: Created, Running, Completed, Failed, Canceled), Type (enum), Error Code, Created At, Completed At, Object Count
- **Purpose**: Tracks long-running bulk mutations (e.g., updating 1000s of prices)

**Shpfy Initial Import Line (30164)** -- Import wizard state
- **Primary key**: Primary Key (Code[10])
- **Fields**: Entity Type, Action, Start Date, End Date, Import Range
- **Purpose**: Temporary table for guided initial data import

**Shpfy Shipment Method Mapping (30123)** -- Shipping method mapping
- **Primary key**: Shop Code, Name (Shopify shipping method name)
- **Relationships**: TableRelation to Shipment Method
- **Purpose**: Maps Shopify shipping methods to BC shipment methods

**Shpfy Province (30160)** -- Country/state reference data
- **Primary key**: Id (BigInteger)
- **Fields**: Code, Name, Country Code
- **Purpose**: Shopify province/state data for address validation

**Shpfy Registered Store New (30138)** -- OAuth registration
- **Primary key**: Shopify URL
- **Fields**: Secret, Scope, Settings
- **Purpose**: Stores OAuth configuration for shop authentication

**Shpfy Cue (30167)** -- Role center counters
- **Primary key**: Primary Key (Code[1])
- **FlowFields**: Count of unprocessed orders, products with errors, etc.
- **Purpose**: Drives role center KPIs and cues

**Shpfy Templates Warnings (30168)** -- Template validation
- **Primary key**: Id (Integer)
- **Fields**: Template Type, Template Code, Warning
- **Purpose**: Stores warnings about customer/item template configuration

## Table extensions

The app extends BC base tables to store Shopify-specific metadata:

**Sales Header (30100)** -- Shopify Order Id (BigInteger)
**Sales Header Archive (30101)** -- Shopify Order Id (BigInteger)
**Sales Line (30102)** -- Shopify Order Line Id, Product Id, Variant Id
**Sales Line Archive (30103)** -- Shopify Order Line Id, Product Id, Variant Id
**Sales Invoice Header (30104)** -- Shopify Order Id (BigInteger)
**Sales Invoice Line (30105)** -- Shopify Order Line Id, Product Id, Variant Id
**Sales Cr.Memo Header (30106)** -- Shopify Return Id, Refund Id
**Sales Cr.Memo Line (30107)** -- Shopify Refund Line Id
**Sales Shipment Header (30108)** -- Shopify Order Id, Fulfillment Id
**Sales Shipment Line (30109)** -- Shopify Order Line Id, Fulfillment Line Id
**Return Receipt Header (30110)** -- Shopify Return Id (BigInteger)
**Return Receipt Line (30111)** -- Shopify Return Line Id (BigInteger)
**Cust. Ledger Entry (30112)** -- Shopify Order Id (BigInteger)
**Gen. Journal Line (30113)** -- Shopify Order Id (BigInteger)
**Shipping Agent (30114)** -- Shopify Carrier Name (Text[100])
**Item Attribute (30115)** -- Shpfy Incl. in Product Sync (enum: No, As Variant, As Option)

Purpose: These extensions enable navigation from BC documents back to Shopify entities and support document link validation.

## Key enums

**Shpfy Customer Mapping** (30107) -- By Email/Phone, By Bill-to Info, Always Create New, By Default Customer
**Shpfy Company Mapping** (30162) -- By Tax ID, By Email/Phone, By Default Company, None
**Shpfy Name Source** (30108) -- None, Company Name, First+Last Name, Last+First Name
**Shpfy County Source** (30109) -- Code, Name
**Shpfy Customer Import Range** (30101) -- None, All, With Order Import
**Shpfy Company Import Range** (30158) -- None, All, With Order Import
**Shpfy SKU Mapping** (30114) -- Item No., Variant Code, Item No. + Variant Code, Barcode, Item Reference
**Shpfy Product Status** (30116) -- Active, Draft, Archived
**Shpfy Inventory Policy** (30115) -- Deny, Continue (allow overselling)
**Shpfy Financial Status** (30106) -- Pending, Authorized, Partially Paid, Paid, Partially Refunded, Refunded, Voided
**Shpfy Order Fulfill. Status** (30103) -- Unfulfilled, Partial, Fulfilled
**Shpfy ReturnRefund ProcessType** (30155) -- Import Only, Auto Create Credit Memo
**Shpfy Transaction Type** (30128) -- Authorization, Capture, Sale, Refund, Void
**Shpfy Transaction Status** (30129) -- Pending, Success, Failure, Error
**Shpfy Logging Mode** (30104) -- None, All, Errors Only
**Shpfy Synchronization Type** (30165) -- Products, Customers, Companies, Orders, Inventory
**Shpfy Currency Handling** (30176) -- Shop Currency, Presentment Currency

## Relationship diagram

```
Shpfy Shop (30102)
  ├─> Shpfy Shop Location (30113) [1:N]
  ├─> Shpfy Synchronization Info (30163) [1:N]
  ├─> Shpfy Product (30127) [1:N]
  │     ├─> Shpfy Variant (30129) [1:N]
  │     │     └─> Shpfy Catalog Price (30153) [1:N]
  │     ├─> Shpfy Product Image (30130) [1:N]
  │     ├─> Shpfy Tag (30114) [polymorphic]
  │     └─> Shpfy Metafield (30101) [polymorphic]
  ├─> Shpfy Customer (30105) [1:N]
  │     ├─> Shpfy Customer Address (30109) [1:N]
  │     ├─> Shpfy Tag (30114) [polymorphic]
  │     └─> Shpfy Metafield (30101) [polymorphic]
  ├─> Shpfy Company (30150) [1:N]
  │     ├─> Shpfy Company Location (30151) [1:N]
  │     ├─> Shpfy Tag (30114) [polymorphic]
  │     └─> Shpfy Metafield (30101) [polymorphic]
  ├─> Shpfy Order Header (30118) [1:N]
  │     ├─> Shpfy Order Line (30119) [1:N]
  │     │     └─> Shpfy Order Tax Line (30135) [1:N]
  │     ├─> Shpfy Order Tax Line (30135) [1:N] (header-level)
  │     ├─> Shpfy Order Shipping Charges (30134) [1:N]
  │     ├─> Shpfy Order Risk (30136) [1:N]
  │     ├─> Shpfy Order Transaction (30133) [1:N]
  │     ├─> Shpfy Gift Card (30110) [1:N]
  │     ├─> Shpfy Order Fulfillment (30120) [1:N]
  │     │     └─> Shpfy Fulfillment Line (30121) [1:N]
  │     ├─> Shpfy Fulfillment Order Header (30460) [1:N]
  │     │     └─> Shpfy Fulfillment Order Line (30461) [1:N]
  │     ├─> Shpfy Return Header (30140) [1:N]
  │     │     └─> Shpfy Return Line (30141) [1:N]
  │     ├─> Shpfy Refund Header (30142) [1:N]
  │     │     ├─> Shpfy Refund Line (30143) [1:N]
  │     │     └─> Shpfy Refund Shipping Line (30144) [1:N]
  │     ├─> Shpfy Tag (30114) [polymorphic]
  │     └─> Shpfy Metafield (30101) [polymorphic]
  ├─> Shpfy Bulk Operation (30148) [1:N]
  ├─> Shpfy Log Entry (30115) [1:N]
  └─> Shpfy Data Capture (30162) [1:N]

BC Entity Links (via SystemId):
  Item <─SystemId─ Shpfy Product.Item SystemId
  Item <─SystemId─ Shpfy Variant.Item SystemId
  Item Variant <─SystemId─ Shpfy Variant.Item Variant SystemId
  Customer <─SystemId─ Shpfy Customer.Customer SystemId
  Customer <─SystemId─ Shpfy Company.Customer SystemId
  Sales Header <─No.─ Shpfy Order Header.Sales Order No.
```

## Design patterns

### Header-line pattern
Order Header/Line, Return Header/Line, Refund Header/Line, Fulfillment Order Header/Line -- standard BC header-detail structure

### Dual currency tracking
Shpfy Order Header stores both Currency Code (shop currency) and Presentment Currency Code (customer's display currency) with parallel amount fields (Total Amount vs Presentment Total Amount)

### SystemId linking
Tables use Guid SystemId fields to reference BC entities instead of Code/No. fields, enabling more flexible mapping logic

### Hash-based change detection
Shpfy Product stores Image Hash, Tags Hash, Description Html Hash to detect changes without comparing full field values; "Last Updated by BC" timestamp tracks BC-initiated changes

### Polymorphic ownership
Shpfy Tag and Shpfy Metafield use "Parent Table No." + "Parent Id"/"Owner Id" to support multiple parent entity types (Product, Customer, Order, Company)
