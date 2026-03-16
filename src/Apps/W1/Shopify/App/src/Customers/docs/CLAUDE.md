# Customers

Part of [Shopify Connector](../../CLAUDE.md).

Handles customer and address synchronization between Business Central customers and Shopify customers, including mapping strategies and county/tax area resolution.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Customer (30105) | Stores Shopify customer data with BC customer mapping |
| Table | Shpfy Customer Address (30106) | Stores customer addresses from Shopify |
| Table | Shpfy Tax Area (30109) | Maps country/county to BC tax area and VAT groups |
| Codeunit | Shpfy Sync Customers (30123) | Orchestrates bidirectional customer sync |
| Codeunit | Shpfy Customer Import (30117) | Imports customers from Shopify to BC |
| Codeunit | Shpfy Customer Export (30119) | Exports BC customers to Shopify |
| Codeunit | Shpfy Customer Mapping (30118) | Maps Shopify customers to BC customers |
| Codeunit | Shpfy Customer API (30120) | GraphQL API calls for customers |
| Codeunit | Shpfy Customer Events (30121) | Event publishers for extensibility |
| Codeunit | Shpfy Create Customer (30122) | Creates BC customers from Shopify |
| Codeunit | Shpfy Update Customer (30116) | Updates BC customers from Shopify data |
| Codeunit | Shpfy Cust. By Email/Phone (30112) | Mapping by email or phone |
| Codeunit | Shpfy Cust. By Bill-to (30113) | Mapping by bill-to customer |
| Codeunit | Shpfy Cust. By Default Cust. (30114) | Always use default customer |
| Codeunit | Shpfy County Code (30124) | County resolution by code |
| Codeunit | Shpfy County Name (30125) | County resolution by name |
| Codeunit | Shpfy County From Json Code/Name (30126/30127) | JSON-based county parsing |
| Codeunit | Shpfy Sync Countries (30128) | Syncs countries and provinces |
| Enum | Shpfy Customer Mapping (30106) | By Email/Phone, By Bill-to Info, DefaultCustomer |
| Enum | Shpfy Customer Import Range (30107) | AllCustomers, WithOrderImport, None |
| Enum | Shpfy Customer State (30108) | Disabled, Invited, Enabled, Declined |
| Enum | Shpfy Name Source (30109) | How to derive customer name |
| Enum | Shpfy County Source (30110) | Code or Name |
| Enum | Shpfy Tax By (30111) | Tax or VAT |
| Report | Shpfy Sync Customers (30110) | Manual customer sync |
| Report | Shpfy Sync Countries (30111) | Sync country/province data |
| Page | Shpfy Customers (30107) | Customer list page |
| Page | Shpfy Customer Card (30108) | Customer detail page |
| Page | Shpfy Tax Areas (30109) | Tax area mapping page |

## Key concepts

- Bidirectional sync: Import from Shopify or export to Shopify based on shop settings
- Mapping strategies: Match by email/phone, by bill-to info, or always use default customer (extensible via interface)
- County resolution: Maps Shopify province code/name to BC county for tax calculations
- Tax area mapping: Shpfy Tax Area table maps country/county to Tax Area Code and VAT Bus. Posting Group
- Name derivation: Configurable rules for deriving BC customer Name, Name 2, Contact from Shopify First/Last Name and Company
- Address synchronization: Imports all customer addresses; default address used for BC customer
- Customer state: Tracks whether customer is Enabled, Invited, Disabled, or Declined in Shopify
- Template-based creation: Uses Customer Template for creating new BC customers
