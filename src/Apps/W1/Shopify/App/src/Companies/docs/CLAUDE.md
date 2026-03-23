# Companies

B2B company management -- separate from D2C customer sync.

## What it does

Imports Shopify companies (a Shopify Plus feature) and maps them to BC Customers.
Each company has locations with billing addresses, tax registration IDs, and
payment terms. The company's main contact is a Shopify Customer used for email
and phone-based matching.

## How it works

`ShpfyCompanyImport` retrieves the company and its main contact from the API,
updates locations, then delegates to `ShpfyCompanyMapping.FindMapping`. The
mapping resolves through the `ICompanyMapping` interface, selected by the Shop's
"Company Mapping Type" enum. If no match is found and auto-create is on,
`ShpfyCreateCustomer.CreateCustomerFromCompany` builds a BC Customer from the
company's location data (address, phone, tax ID, payment terms).

## Things to know

- Requires Shopify Plus. Without it, the companies API is unavailable.
- The relationship chain is Company -> Location -> Customer. A company has
  locations (physical addresses), and each company has a main contact who is a
  Shopify Customer record. The `Main Contact Customer Id` on the Company
  links to `Shpfy Customer`.
- `Customer SystemId` on Company links to the BC Customer, same pattern as
  Customers and Products.
- Company Locations can override the default customer mapping for order
  processing via `Sell-to Customer No.` and `Bill-to Customer No.` fields.
- Three mapping strategies exist: By Email/Phone (matches main contact's
  email/phone to BC Customer), By Tax Id (matches location's tax registration
  ID to BC Customer via the `Tax Registration Id Mapping` interface), and
  Default Company (always returns a configured default).
- `IFindCompanyMapping` extends `ICompanyMapping` with a `FindMapping` method.
  The mapping codeunit checks at runtime whether the selected implementation
  supports `IFindCompanyMapping` and falls back to `CompByEmailPhone` if not.
- Tax registration ID mapping is itself pluggable via
  `Shpfy Tax Registration Id Mapping` interface with two implementations:
  `ShpfyTaxRegistrationNo` (matches Registration No.) and
  `ShpfyVATRegistrationNo` (matches VAT Registration No.).
- When creating customers from companies, the county is resolved through the
  same `ICounty` interface used by the Customers module.
