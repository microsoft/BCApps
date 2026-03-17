# Companies

Bidirectional synchronization of B2B company records between Shopify and Business Central, with support for multi-location companies, tax registration mapping, contact role assignment, and catalog auto-creation.

## Quick reference

| Task | Entry point |
|------|-------------|
| Full company sync | `ShpfySyncCompanies` (codeunit 30285) |
| Import single company | `ShpfyCompanyImport` (codeunit 30301) |
| Export BC customers as companies | `ShpfyCompanyExport` (codeunit 30284) |
| Map Shopify company to BC | `ShpfyCompanyMapping` (codeunit 30303) |
| GraphQL API operations | `ShpfyCompanyAPI` (codeunit 30286) |

## Structure

- `Codeunits/` -- sync orchestration, API communication, mapping strategies, tax registration implementations
- `Tables/` -- Shopify company, company location
- `Interfaces/` -- `ICompanyMapping`, `IFindCompanyMapping`, `TaxRegistrationIdMapping`
- `Enums/` -- company mapping, import range, default contact permission, tax ID mapping
- `Pages/` -- company list/card, location subforms, main contact factbox
- `Reports/` -- sync companies, add company/customer-as-location to Shopify

## Documentation

- [docs/implementation.md](docs/implementation.md) -- B2B company management, company-to-customer mapping, location handling, tax registration, multi-shop scenarios

## Key concepts

- **B2B model** -- Shopify companies represent business customers; each company has one or more locations with addresses, tax IDs, and payment terms
- **Company-to-customer mapping** -- interface-driven via `ICompanyMapping` with strategies: By Email/Phone, Default Company, By Tax Id
- **Multi-location support** -- each company can have multiple `Shpfy Company Location` records; the first location is flagged as default and stored in `Company."Location Id"`
- **Tax registration** -- the `Shpfy Tax Registration Id Mapping` interface maps between BC customer tax fields (Registration No. or VAT Registration No.) and Shopify location tax IDs
- **Contact role assignment** -- when creating companies, the main contact is assigned from the linked Shopify customer, with configurable default contact permissions (No Permission, Ordering Only, Location Admin)
- **Catalog auto-creation** -- optionally creates a Shopify catalog for the company location upon export
