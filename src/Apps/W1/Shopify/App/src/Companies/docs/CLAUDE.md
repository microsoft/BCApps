# Companies

B2B company management for the Shopify Connector. This module handles the bidirectional sync of Shopify companies to BC customers, separate from the individual-customer (B2C) flow in the adjacent Customers module. The key distinction is that a company has multiple locations, each of which can map to a different sell-to/bill-to customer.

## How it works

The data model is `Shpfy Company` (table 30150) -> `Shpfy Company Location` (table 30151) -> main contact (`Shpfy Customer`). A company stores the Shopify ID, a link to a BC customer via `Customer SystemId`, and a reference to a main contact customer. Each `CompanyLocation` carries its own address, tax registration ID, payment terms, and separate `Sell-to Customer No.` / `Bill-to Customer No.` fields -- so a single Shopify company can route different locations to different BC customers.

Company-to-customer matching is driven by the `Shpfy ICompany Mapping` interface (`ShpfyICompanyMapping.Interface.al`). The shop's `Company Mapping Type` setting selects the strategy: `ShpfyCompByTaxId.Codeunit.al` matches on tax registration ID via a secondary `Shpfy Tax Registration Id Mapping` interface, `ShpfyCompByEmailPhone.Codeunit.al` matches on the main contact's email or phone, and `ShpfyCompByDefaultComp.Codeunit.al` always returns the shop's default company. All three implement both `ICompany Mapping` and `IFind Company Mapping` (the latter adds a `FindMapping` method that checks whether a mapping already exists before creating one).

Import flows through `ShpfyCompanyImport.Codeunit.al` -- it retrieves the company from the Shopify API, updates locations, then calls `FindMapping`. If no match is found and auto-create is enabled, it creates a new BC customer. Export flows through `ShpfyCompanyExport.Codeunit.al`, which iterates BC customers and either creates or updates Shopify companies, including auto-creating catalogs when `Auto Create Catalog` is enabled on the shop.

## Things to know

- The `Bill-to Customer No.` on `CompanyLocation` requires `Sell-to Customer No.` to be set first -- clearing sell-to clears bill-to automatically.
- `FindMapping` has a self-healing pattern: if `Customer SystemId` points to a deleted customer, it clears the GUID and retries matching.
- `ShpfyCompanyExport` uses a generic `HasDiff` helper that compares all fields via `RecordRef` to decide whether an API update is needed.
- Export requires a non-empty email on the BC customer; missing email logs a skipped record rather than erroring.
- Payment terms mapping is per-location: `ShpfyCompanyLocation` stores a `Shpfy Payment Terms Id` that links to the shop-specific `Shpfy Payment Terms` table.
- Tax registration ID mapping is itself interface-driven (`ShpfyTaxRegistrationIdMapping.Interface.al`) with implementations for VAT Registration No. and Tax Registration No.
- When exporting, the module checks for duplicate `External Id` (set to `Customer."No."`) to avoid creating duplicate companies in Shopify.
