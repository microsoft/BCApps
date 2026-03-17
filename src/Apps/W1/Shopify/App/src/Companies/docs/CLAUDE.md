# Companies

B2B company management for Shopify Plus stores. Companies are a separate entity model from customers in Shopify -- a company has one or more locations, each of which can map independently to BC customers. This module mirrors the customer sync pattern but adds the location dimension and tax registration matching.

## How it works

`ShpfySyncCompanies.Codeunit.al` follows the same bidirectional structure as customer sync. Import mode is controlled by `Company Import From Shopify` on the Shop (AllCompanies or WithOrderImport). Like customer sync, it retrieves a `Dictionary of [BigInteger, DateTime]` of company IDs, skips unchanged records by comparing `Updated At` vs `Last Updated by BC`, and feeds each into `ShpfyCompanyImport`. For export, `ShpfyCompanyExport` runs against BC Customer records.

The Shpfy Company table (ID 30150) links to a BC Customer via `Customer SystemId` and tracks its main contact through `Main Contact Customer Id` (the Shopify customer BigInteger) and `Main Contact Id`. Each company can have multiple locations stored in `ShpfyCompanyLocation.Table.al` (ID 30151), linked back to the company via `Company SystemId` (a Guid, not the Shopify BigInteger). Locations carry their own `Sell-to Customer No.` and `Bill-to Customer No.`, enabling org-based order routing where different locations map to different BC customers.

Mapping uses the `Shpfy ICompany Mapping` interface, selected by `Company Mapping Type` on the Shop. The `ByTaxId` strategy (`ShpfyCompByTaxId.Codeunit.al`) looks up a company location's `Tax Registration Id` against BC customers using a pluggable `Shpfy Tax Registration Id Mapping` interface -- the shop's `Shpfy Comp. Tax Id Mapping` field selects between VAT Registration No. and Tax Registration No. matchers. `CompanyMapping.FindMapping` has a fallback: if the selected strategy does not implement `IFindCompanyMapping`, it silently falls back to `CompByEmailPhone`.

## Things to know

- Company locations have a `Shpfy Payment Terms Id` that links to a Shopify payment terms table, enabling per-location payment terms mapping.
- The `Bill-to Customer No.` field on a location requires `Sell-to Customer No.` to be set first (enforced by a `TestField` in the validate trigger). Clearing sell-to also clears bill-to.
- Two reports provide manual push actions: `AddCompanyToShopify` and `AddCustasLocations` (the latter adds BC customers as locations under an existing company).
- Deleting a company record cascades to delete its locations via the `OnDelete` trigger.
- Unlike the Customer table which stores `Shop Id` as an Integer, the Company table also stores `Shop Code` as a Code[20] with a table relation to `Shpfy Shop` -- a structural inconsistency between the two modules.
- The `CompanyImportRange` enum has the same values as `CustomerImportRange` (None, WithOrderImport, AllCompanies) but is a separate enum.
