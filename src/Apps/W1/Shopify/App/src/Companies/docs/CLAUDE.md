# Companies

The Companies module handles B2B company management for Shopify Plus stores. A Company in Shopify is an organization that places orders -- distinct from a Customer, which represents an individual person. This module maps Shopify Companies to BC Customers at the company level, with per-location sell-to/bill-to configuration.

## How it works

`ShpfySyncCompanies` orchestrates bidirectional sync using the same UpdatedAt-comparison pattern as the Customers module. On import, it retrieves company IDs from Shopify, filters to those that have changed, and runs `ShpfyCompanyImport` for each. The import codeunit fetches the company details and its locations via `ShpfyCompanyAPI`, then delegates to `ShpfyCompanyMapping.FindMapping` to link the company to a BC Customer.

The mapping architecture has two layers. `ICompanyMapping` is the base interface with a single `DoMapping` method that takes a company ID and returns a customer number. `IFindCompanyMapping` extends it with a `FindMapping` method that also receives the company's main contact as a temp `Shpfy Customer` record. The `ShpfyCompanyMapping` codeunit checks at runtime whether the selected strategy implements the extended interface; if not, it falls back to the `ByEmailPhone` implementation for `FindMapping`.

Three mapping strategies are available: `ByEmailPhone` matches the company's main contact email/phone against BC Customer email/phone (reusing the same digit-wildcard phone filter from the customer module). `ByDefaultComp` always returns the shop's default customer. `ByTaxId` matches the company location's tax registration ID against BC Customer VAT/tax registration numbers. The enum is extensible for partner customization.

On export, `ShpfyCompanyExport` pushes BC Customer data to Shopify as companies. Company locations are updated by the API layer during import and carry their own sell-to and bill-to customer numbers that override the defaults for order processing.

## Things to know

- Company is not Customer. A Shopify Company has a `Main Contact Customer Id` linking to a `Shpfy Customer` record, but the company itself maps to a BC Customer via its own `Customer SystemId`. The main contact is used for mapping (email/phone lookup) but the BC Customer record belongs to the company.
- `Shpfy Company Location` carries `Sell-to Customer No.` and `Bill-to Customer No.` fields. When orders arrive from a company location, these override the company-level customer mapping, enabling different billing arrangements per location.
- Company locations also carry `Tax Registration Id` and `Shpfy Payment Terms Id`, bridging Shopify payment terms and tax registration to BC's equivalents.
- The `IFindCompanyMapping` interface extends `ICompanyMapping`. This means strategies can implement just the base create-or-map method, or the full find+map method. The runtime type check `if IMapping is "Shpfy IFind Company Mapping"` in `ShpfyCompanyMapping.FindMapping` handles this gracefully.
- Companies require Shopify Plus. The module will not be exercised on standard Shopify plans.
- Cascade deletes: deleting a `Shpfy Company` deletes all its `Shpfy Company Location` rows (filtered by `Company SystemId`).
- The `ShpfyTaxRegistrationNo` and `ShpfyVATRegistrationNo` codeunits implement the `ShpfyTaxRegistrationIdMapping` interface, providing different strategies for matching tax IDs depending on the country's tax system.
