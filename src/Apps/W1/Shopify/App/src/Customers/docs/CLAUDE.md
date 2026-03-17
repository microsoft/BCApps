# Customers

Customers handles the bidirectional synchronization of customer records between Shopify and BC, including the resolution of which BC Customer corresponds to a Shopify customer during order processing. This module is heavily strategy-driven: four separate interfaces allow pluggable behavior for customer lookup, name composition, and county/province handling.

## How it works

The sync is orchestrated by `ShpfySyncCustomers.Codeunit.al`, which respects the Shop's customer sync direction. Inbound sync pulls customer records from Shopify via `ShpfyCustomerAPI.Codeunit.al`, creates or updates `Shpfy Customer` records, and optionally maps them to BC Customers. Outbound sync finds BC Customers linked to Shopify customers and pushes updates via `ShpfyCustomerExport.Codeunit.al`. New BC customers can be pushed to Shopify through `ShpfyCreateCustomer.Codeunit.al`.

The critical path is customer mapping during order import, handled by `ShpfyCustomerMapping.Codeunit.al`. The mapping codeunit supports two contexts: finding a BC Customer for a Shopify customer (ShopifyToBC direction) and finding a Shopify customer for a BC Customer (BCToShopify direction). For ShopifyToBC, it first checks if the `Customer SystemId` on the Shpfy Customer record still points to a valid BC Customer. If not, it falls back to `DoFindMapping`, which searches by email (case-insensitive) and then by phone number using a digit-only wildcard filter (`CreatePhoneFilter` strips everything except digits and builds a `*1*2*3...` pattern).

The order-processing mapping path is different: it goes through the `ICustomerMapping` interface. The Shop's `Customer Mapping Type` setting selects one of three implementations: `ShpfyCustByEmailPhone.Codeunit.al` (searches by email then phone, creates if allowed), `ShpfyCustByBillto.Codeunit.al` (matches by bill-to address fields), or `ShpfyCustByDefaultCust.Codeunit.al` (always returns the Shop's default customer). If the incoming order has no name, the mapping always falls back to email/phone regardless of the configured strategy.

Name composition is controlled by the `ICustomerName` interface with four implementations: `ShpfyNameisFirstLastName` ("John Smith"), `ShpfyNameisLastFirstName` ("Smith John"), `ShpfyNameisCompanyName` (company name only), and `ShpfyNameisEmpty` (returns blank). The Shop has separate name source settings for Name, Name 2, and Contact, each selecting one of these implementations.

County handling uses two interface pairs: `ICounty` (for reading county from a BC address: code vs. name) and `ICountyFromJson` (for parsing county from Shopify JSON: province code vs. province name).

## Things to know

- The `Shpfy Customer Address` table uses negative auto-incrementing IDs for addresses created from the BC side. The `OnInsert` trigger sets `Id := Math.Min(-1, CustomerAddress.Id - 1)` when no Shopify ID is provided, creating a descending negative sequence. This prevents collisions with Shopify-assigned positive IDs while allowing addresses to exist before they are synced to Shopify.

- The `Shpfy Customer` table links to BC via `Customer SystemId` (a Guid), not by Customer No. The `Customer No.` is a FlowField calculated from the SystemId. This design survives customer renumbering.

- The `Shop Id` field on Shpfy Customer scopes the customer to a specific shop. A single Shopify customer (same email) can appear as separate Shpfy Customer records for different shops if they are configured independently.

- The `ShpfyCustomerTemplate.Table.al` stores per-country customer templates. When creating a new BC Customer from a Shopify customer, the system looks up the template by the customer's country/region code, allowing different default settings (posting groups, payment terms, etc.) per country.

- The phone filter construction in `CreatePhoneFilter` is deliberately loose: it strips all non-digit characters from both the Shopify phone number and creates a wildcard pattern. This means "+1 (555) 123-4567" matches a BC customer with phone "5551234567" or "001-555-123-4567". This flexibility can cause false positive matches when phone numbers share digit subsequences.

- The `ShpfySyncCountries.Codeunit.al` and `ShpfyProvince.Table.al` handle syncing Shopify's country/province reference data, which feeds into the county handling strategies. This is a prerequisite for correct address mapping.

- Customer creation on the Shopify side (`ShpfyCustomerExport`) and on the BC side (`ShpfyCreateCustomer`) both fire events (`OnBeforeCreateCustomer`, `OnAfterCreateCustomer`) that allow partners to inject custom logic for fields the connector does not map by default.
