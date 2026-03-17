# Customers

Bidirectional synchronization of customer records between Shopify and Business Central, with interface-driven strategies for name mapping, customer matching, and county/region resolution.

## Quick reference

| Task | Entry point |
|------|-------------|
| Full customer sync | `ShpfySyncCustomers` (codeunit 30123) |
| Import single customer | `ShpfyCustomerImport` (codeunit 30117) |
| Export BC customers to Shopify | `ShpfyCustomerExport` (codeunit 30116) |
| Map Shopify customer to BC | `ShpfyCustomerMapping` (codeunit 30118) |
| GraphQL API operations | `ShpfyCustomerAPI` (codeunit 30114) |

## Structure

- `Codeunits/` -- sync orchestration, API communication, mapping strategies, create/update logic
- `Tables/` -- Shopify customer, address, tax area, customer template, province (obsolete)
- `Interfaces/` -- `ICustomerMapping`, `ICustomerName`, `ICounty`, `ICountyFromJson`
- `Enums/` -- strategy selectors for mapping, name source, county source, import range, tax, customer state
- `Pages/` -- customer list/card, addresses, templates, tax areas
- `Reports/` -- sync and add-customer-to-Shopify reports

## Documentation

- [docs/implementation.md](docs/implementation.md) -- import/export flows, address mapping, interface-driven strategies, county handling, tax area resolution

## Key concepts

- **Interface-driven mapping** -- the `Shpfy Customer Mapping` enum implements `ICustomerMapping` with three strategies: By Email/Phone, By Bill-to Info, and Default Customer
- **Name source** -- the `Shpfy Name Source` enum implements `ICustomerName` with four strategies: CompanyName, FirstAndLastName, LastAndFirstName, None
- **County source** -- the `Shpfy County Source` enum implements both `ICounty` and `ICountyFromJson` with Code and Name strategies
- **Bidirectional sync** -- import direction creates/updates BC customers from Shopify; export direction creates/updates Shopify customers from BC
- **Template-based creation** -- new BC customers are created using customer templates resolved by country/region code
- **Shop-scoped** -- all operations are scoped to a specific Shopify Shop record, which stores configuration for mapping strategies, name sources, and sync preferences
