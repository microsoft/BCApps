# Companies extensibility

## Interfaces

**ICompanyMapping** -- the strategy interface for resolving a Shopify company
to a BC Customer. Selected via the extensible `Shpfy Company Mapping` enum
(value 0 = By Email/Phone, 2 = Default Company, 3 = By Tax Id). The
`DoMapping` procedure receives CompanyId, ShopCode, TemplateCode, and
AllowCreate, and returns a Customer No.

To add a custom B2B company resolution strategy, extend the enum and implement
`ICompanyMapping`. If your strategy also supports the Shopify-to-BC import
direction (not just order-time mapping), implement `IFindCompanyMapping` as
well.

**IFindCompanyMapping** -- extends `ICompanyMapping` with `FindMapping`, which
receives the Shpfy Company record and a temporary Shpfy Customer record (the
company's main contact). The mapping codeunit (`ShpfyCompanyMapping`)
runtime-checks whether the active implementation supports this interface. If
it does not, it falls back to `ShpfyCompByEmailPhone.FindMapping`. This means
custom mapping implementations that only implement `ICompanyMapping` will get
email/phone matching for import and their custom logic for order-time
resolution.

**Shpfy Tax Registration Id Mapping** -- controls how tax registration IDs
are matched and updated on BC Customers. Three methods:

- `GetTaxRegistrationId` -- returns the tax ID from a BC Customer
- `SetMappingFiltersForCustomers` -- sets filters on the Customer table to
  find a customer by tax ID from a Company Location
- `UpdateTaxRegistrationId` -- writes a new tax ID to a BC Customer during
  company creation

The base app provides `ShpfyTaxRegistrationNo` (uses
Customer."Registration Number") and `ShpfyVATRegistrationNo` (uses
Customer."VAT Registration No."). Selected via the extensible
"Shpfy Comp. Tax Id Mapping" enum on the Shop.

*Updated: 2026-07-29 -- tax ID mapping can be extended by localizations such
as the Belgian Enterprise No. mapping*

Add another country-specific tax ID strategy by extending
`Shpfy Comp. Tax Id Mapping` and implementing
`Shpfy Tax Registration Id Mapping`. The same implementation is used when
matching a Shopify Company Location to an existing BC Customer, creating or
updating the BC Customer from Shopify, and exporting a BC Customer's tax ID
back to the Shopify Company Location. This keeps localization-specific fields
out of the company import/export code.

## Customizing company import

Company import reuses the customer events infrastructure. When a company is
auto-created, `ShpfyCreateCustomer.CreateCustomerFromCompany` is called
directly (not through the `OnRun` trigger), so `OnBeforeCreateCustomer` and
`OnAfterCreateCustomer` do not fire for company-created customers. To
customize company-to-customer creation, implement a custom
`IFindCompanyMapping` that intercepts before creation, or subscribe to
`OnBeforeFindCustomerTemplate` to control the template selection.

## Customizing company export

`ShpfyCompanyExport` pushes BC Customer data to existing Shopify companies.
There are no company-specific events -- the export uses the same field-diff
pattern as customer export. It resolves `Country/Region`.`ISO Code` before
filtering `Shpfy Tax Area`, so custom county or tax-area data must use
Shopify's ISO country code. Customization is through the interfaces above or
by modifying the company/location data after API retrieval.

*Updated: 2026-07-29 -- company export tax-area filtering now uses ISO country
codes*
