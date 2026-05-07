# Customers

Bi-directional D2C customer sync between BC Customers and Shopify Customers.

## What it does

Import pulls Shopify customers, maps them to BC Customers using a configurable
strategy, and optionally auto-creates new customers via templates. Export pushes
BC Customer changes (name, address, email, phone) to Shopify, creating or
updating Shopify customer records.

## How it works

The Shop's "Customer Mapping Type" selects a strategy via the `ICustomerMapping`
interface. Three built-in options exist: By Email/Phone (matches on email then
phone), By Bill-to Info (matches on name/address fields), and Default Customer
(always returns a single configured customer). The mapping codeunit
(`ShpfyCustomerMapping`) has its own `DoFindMapping` that tries email then
phone filter matching for the ShopifyToBC direction.

Customer name formatting is pluggable through `ICustomerName` -- implementations
produce the BC customer Name field from Shopify first/last/company name in
different orderings (FirstLast, LastFirst, CompanyName, Empty). County resolution
uses `ICounty` (for records) and `ICountyFromJson` (for API responses) to
convert between province codes and names.

## Things to know

- `Customer SystemId` on `Shpfy Customer` links to the BC Customer, same
  pattern as Products. The FlowField `Customer No.` resolves it.
- `Shop Id` is a hash-based identifier used to scope customer queries to a
  specific shop. Indexed for fast lookups. `CustomerAPI.FillInMissingShopIds`
  backfills this for older records.
- Customer creation uses country-specific templates. `ShpfyCreateCustomer`
  looks up the `Shpfy Customer Template` table by Shop Code + Country Code,
  falling back to the Shop's default template.
- Export (`ShpfyCustomerExport`) splits the BC Customer name back into
  first/last using the Shop's "Name Source" config. It handles multi-email
  fields by taking the first email before any semicolon or comma.
- Phone number matching strips all non-digit characters and builds a wildcard
  filter (`*1*2*3*...`) to handle format differences.
- The `Shpfy Customer Address` table stores Shopify addresses. Addresses
  created from BC get negative IDs (not from Shopify API).
- County export validates province code length and errors if it exceeds the
  Shopify field limit.
