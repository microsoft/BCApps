# Companies

The Companies folder handles Shopify B2B company/location import and export. It mirrors the Customers folder's architecture but targets Shopify's company model, where a company has locations and a main contact (who is a Shopify customer).

## Sync flow

`ShpfySyncCompanies.Codeunit.al` orchestrates bidirectional sync, controlled by `Company Import From Shopify` and `Can Update Shopify Companies` on the Shop card. Import fetches company IDs from Shopify, filters by `Updated At` / `Last Updated by BC` timestamps, then runs `ShpfyCompanyImport.Codeunit.al` per company. The import codeunit retrieves the company, updates its locations via the API, then attempts mapping -- falling back to customer creation if `Auto Create Unknown Companies` is enabled.

## Mapping strategies

The `Shpfy ICompany Mapping` interface dispatches via the `Shpfy Company Mapping` enum. Three implementations:

- **By Email/Phone** (`ShpfyCompByEmailPhone.Codeunit.al`) -- finds a BC Customer by the main contact's email or phone. Reuses `CreatePhoneFilter` from the customer mapping codeunit for phone normalization.
- **Default Company** (`ShpfyCompByDefaultComp.Codeunit.al`) -- always returns `Shop."Default Company No."`.
- **By Tax Id** (`ShpfyCompByTaxId.Codeunit.al`) -- looks up the company's location, reads its `Tax Registration Id`, and matches via the `Shpfy Tax Registration Id Mapping` interface.

A key design point: `Shpfy IFind Company Mapping` extends `Shpfy ICompany Mapping` with `FindMapping`. In `ShpfyCompanyMapping.Codeunit.al`, if the active mapping implements `IFind Company Mapping`, it's used directly; otherwise the code falls back to `Comp. By Email/Phone`. This means all three implementations actually implement `IFind Company Mapping`, making the fallback a safety net rather than a common path.

## Tax registration ID mapping

The `Shpfy Tax Registration Id Mapping` interface (with `Shpfy Comp. Tax Id Mapping` enum) provides two implementations: `Registration No.` and `VAT Registration No.`. These control which BC customer field is matched against and updated from the Shopify company location's `Tax Registration Id`. The interface has three methods: `GetTaxRegistrationId`, `SetMappingFiltersForCustomers`, and `UpdateTaxRegistrationId`.

## Company location model

`Shpfy Company Location` (`ShpfyCompanyLocation.Table.al`) stores address data per Shopify location. Notable fields include `Sell-to Customer No.` and `Bill-to Customer No.` which allow per-location override of which BC customer is used for order processing -- `Bill-to` requires `Sell-to` to be set first (enforced by OnValidate). The `Customer Id` Guid field links the location to a specific BC customer for multi-location export scenarios.

## Default contact permission

The `Shpfy Default Cont. Permission` enum defines three levels: `No permission`, `Ordering only`, `Location admin`. This controls what access the main contact gets when a company is created in Shopify.

## Export

`ShpfyCompanyExport.Codeunit.al` exports BC customers as Shopify companies. It first creates the customer as a Shopify contact (via `Shpfy Customer Export`), then creates the company with its location. Duplicate detection uses `External Id` (set to the BC customer number). When `Auto Create Catalog` is enabled on the shop, a catalog is automatically created for new companies.
