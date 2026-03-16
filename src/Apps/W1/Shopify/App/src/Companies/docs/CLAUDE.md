# Companies

Part of [Shopify Connector](../../CLAUDE.md).

Handles B2B company and company location synchronization between Business Central customers and Shopify B2B companies, supporting multi-location B2B scenarios.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Company (30150) | Stores Shopify B2B company data with BC customer mapping |
| Table | Shpfy Company Location (30151) | Stores company locations (ship-to addresses) |
| Codeunit | Shpfy Sync Companies (30153) | Orchestrates bidirectional company sync |
| Codeunit | Shpfy Company Import (30154) | Imports companies from Shopify to BC |
| Codeunit | Shpfy Company Export (30155) | Exports BC customers to Shopify companies |
| Codeunit | Shpfy Company Mapping (30156) | Maps Shopify companies to BC customers |
| Codeunit | Shpfy Company API (30157) | GraphQL API calls for companies |
| Codeunit | Shpfy Comp. By Email/Phone (30158) | Mapping by email or phone |
| Codeunit | Shpfy Comp. By Tax Id (30159) | Mapping by tax registration ID |
| Codeunit | Shpfy Comp. By Default Comp. (30160) | Always use default company |
| Codeunit | Shpfy Tax Registration No. (30161) | Tax ID mapping via Tax Registration No. |
| Codeunit | Shpfy VAT Registration No. (30162) | Tax ID mapping via VAT Registration No. |
| Enum | Shpfy Company Mapping (30151) | By Email/Phone, By Tax Id, DefaultCompany |
| Enum | Shpfy Company Import Range (30152) | AllCompanies, WithOrderImport, None |
| Enum | Shpfy Comp Tax Id Mapping (30153) | Tax Registration No., VAT Registration No. |
| Enum | Shpfy Default Cont Permission (30154) | Location permissions for default contact |
| Report | Shpfy Sync Companies (30115) | Manual company sync |
| Report | Shpfy Add Company to Shopify (30116) | Export BC customer as company |
| Report | Shpfy Add Cust as Locations (30117) | Add BC customers as locations |
| Page | Shpfy Companies (30140) | Company list page |
| Page | Shpfy Company Card (30141) | Company detail page |
| Page | Shpfy Comp Locations (30142) | Company locations page |

## Key concepts

- B2B support: Companies represent B2B customers in Shopify, distinct from regular customers
- Company locations: Each company can have multiple locations (ship-to addresses) with separate billing/shipping
- Location-to-customer mapping: Company locations can map to separate BC customers for sell-to/bill-to
- Main contact: Each company has a main contact (Shopify customer) for login
- Tax ID mapping: Map companies by Tax Registration No. or VAT Registration No.
- Payment terms: Company locations can have Shopify-specific payment terms
- Extensible mapping: Interface-based mapping supports custom strategies
