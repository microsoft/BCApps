# Companies -- implementation details

## B2B company management

Shopify's B2B model uses companies as the top-level entity for business customers. Each company has:

- A name and optional external ID (mapped to BC customer number on export)
- A main contact (linked to a Shopify customer record)
- One or more locations with addresses, tax registration IDs, and payment terms
- Notes and metafields

In BC, a Shopify company maps to a single BC Customer record via `Company."Customer SystemId"`. The company's main contact is tracked separately via `Main Contact Customer Id` (linking to a `Shpfy Customer` record).

## Import flow (Shopify to BC)

Orchestrated by `ShpfySyncCompanies` (codeunit 30285), triggered against a `Shpfy Shop` record.

1. **Retrieve IDs** -- `ShpfyCompanyAPI.RetrieveShopifyCompanyIds` fetches company IDs modified since last sync via paginated GraphQL (`GetCompanyIds` / `GetNextCompanyIds`)

2. **Filter changed records** -- only companies with `updatedAt` newer than local `Updated At` and `Last Updated by BC` are queued

3. **Per-company import** -- `ShpfyCompanyImport` (codeunit 30301) runs for each queued company:
   - `CompanyAPI.RetrieveShopifyCompany` fetches full company data including main contact customer info (stored in a temporary `Shpfy Customer` record)
   - `CompanyAPI.UpdateShopifyCompanyLocations` fetches all locations via paginated GraphQL (`GetCompanyLocations` / `GetNextCompanyLocations`)
   - Each location's billing address, tax registration ID, payment terms, and province data are stored in `Shpfy Company Location` records
   - `CompanyMapping.FindMapping` attempts to match to a BC customer
   - If mapped and `Shopify Can Update Companies` is enabled, runs `UpdateCustomer.UpdateCustomerFromCompany`
   - If unmapped and `Auto Create Unknown Companies` is enabled, runs `CreateCustomer.CreateCustomerFromCompany`

4. **Customer creation from company** -- `ShpfyCreateCustomer.CreateCustomerFromCompany`:
   - Resolves the company's default location (errors if missing)
   - Maps country code from ISO to BC format via `Country/Region` table
   - Creates BC customer from template
   - Applies: company name, email (from main contact), location address, county (via `ICounty` interface), phone, tax area, payment terms
   - Maps tax registration ID via `Shpfy Tax Registration Id Mapping` interface
   - Links BC customer to both the `Shpfy Company` and the `Shpfy Customer` (main contact)

5. **Customer update from company** -- `ShpfyUpdateCustomer.UpdateCustomerFromCompany`:
   - Updates the linked BC customer with current company name and default location address
   - Applies county, tax area, payment terms, and tax registration ID mapping

## Export flow (BC to Shopify)

Triggered by `ShpfySyncCompanies` when `Can Update Shopify Companies` is enabled.

1. `ShpfyCompanyExport` iterates BC Customer records
2. For each customer, checks if a `Shpfy Company` with matching `Customer SystemId` and `Shop Code` exists
3. **Create** -- if no mapping exists and create is enabled:
   - Requires non-empty email (skips with log otherwise)
   - Checks for duplicate `External Id` (customer number)
   - Creates a Shopify customer first via `CreateCompanyContact` (reuses customer export logic)
   - `FillInShopifyCompany` sets company name and external ID
   - `FillInShopifyCompanyLocation` maps address, county (via Tax Area), country (ISO), phone, tax registration ID, payment terms
   - `CompanyAPI.CreateCompany` sends `companyCreate` GraphQL mutation
   - Assigns main contact and contact roles
   - Optionally creates a catalog via `CatalogAPI.CreateCatalog`

4. **Update** -- if mapped:
   - `FillInShopifyCompany` checks for name/external ID changes
   - `CompanyAPI.UpdateCompany` sends `companyUpdate` mutation (only changed fields)
   - Iterates all company locations, updating each via `CompanyAPI.UpdateCompanyLocation` (sends `companyLocationAssignAddress` mutation for address changes, plus separate mutations for tax ID and payment terms)
   - Syncs metafields if `Company Metafields To Shopify` is enabled

## Company-to-customer mapping

### `ICompanyMapping` interface

The `Shpfy Company Mapping` enum (30151) is extensible and implements `ICompanyMapping`:

- **By Email/Phone** (`ShpfyCompByEmailPhone`) -- matches BC customers by the main contact's email or phone
- **Default Company** (`ShpfyCompByDefaultComp`) -- always returns the configured default company/customer
- **By Tax Id** (`ShpfyCompByTaxId`) -- matches BC customers by tax registration ID from the company location

### `IFindCompanyMapping` interface

Extends `ICompanyMapping` with a `FindMapping` procedure that accepts both the company and its main contact customer. The `ShpfyCompanyMapping` codeunit checks if the mapping implementation supports this extended interface; if not, it falls back to `CompByEmailPhone.FindMapping`.

## Location handling

Each Shopify company can have multiple locations stored in `Shpfy Company Location` (table 30151).

Key fields per location:

| Field | Purpose |
|-------|---------|
| `Id` | Shopify location ID |
| `Company SystemId` | Link to parent `Shpfy Company` |
| `Address`, `Address 2`, `City`, `Zip` | Physical address |
| `Country/Region Code` | ISO 2-letter code |
| `Province Code`, `Province Name` | State/province |
| `Tax Registration Id` | Tax ID for this location |
| `Shpfy Payment Terms Id` | Linked Shopify payment terms |
| `Sell-to Customer No.`, `Bill-to Customer No.` | BC customer links for order processing |
| `Customer Id` | BC customer SystemId for location-specific customer mapping |
| `Default` | Whether this is the company's default location |
| `Recipient` | Company/attention name |

During import, the first location retrieved is flagged as default and its ID is stored in `Company."Location Id"`. During export, all locations linked to the company are updated.

### Adding customers as locations

The `CompanyAPI.CreateCompanyLocation` procedure allows adding a BC customer as a new location to an existing Shopify company. This:

- Validates the customer is not already exported as a company or location
- Creates a Shopify customer contact
- Sends a `companyLocationCreate` GraphQL mutation
- Assigns contact roles and optionally creates a catalog

## Tax registration

The `Shpfy Tax Registration Id Mapping` interface (in `Interfaces/ShpfyTaxRegistrationIdMapping.Interface.al`) provides three operations:

- `GetTaxRegistrationId` -- reads the tax ID from a BC customer for export
- `UpdateTaxRegistrationId` -- writes a Shopify tax ID to a BC customer during import
- `SetMappingFiltersForCustomers` -- sets customer filters for finding matches by tax ID

The `Shpfy Comp. Tax Id Mapping` enum (30166) provides two implementations:

- **Registration No.** (`ShpfyTaxRegistrationNo`) -- maps to BC's `Registration No.` field
- **VAT Registration No.** (`ShpfyVATRegistrationNo`) -- maps to BC's `VAT Registration No.` field

Tax registration ID is updated via a separate GraphQL call (`CreateCompanyLocationTaxId`) during location export.

## Multi-shop scenarios

Companies are scoped to a specific shop via `Shop Id` and `Shop Code` fields on the `Shpfy Company` table. The `Customer SystemId` index allows finding which BC customer a Shopify company maps to, while the `Shop Code` filter ensures a BC customer can be linked to different Shopify companies across different shops.

## Tables

| Table | ID | Purpose |
|-------|-----|---------|
| `Shpfy Company` | 30150 | Shopify company record with link to BC Customer via `Customer SystemId` |
| `Shpfy Company Location` | 30151 | Company locations with address, tax, payment terms, and BC customer links |

## Key enums

| Enum | ID | Values |
|------|----|--------|
| `Shpfy Company Mapping` | 30151 | By Email/Phone, Default Company, By Tax Id |
| `Shpfy Company Import Range` | 30149 | None, With Order Import, All Companies |
| `Shpfy Default Cont. Permission` | 30148 | No Permission, Ordering Only, Location Admin |
| `Shpfy Comp. Tax Id Mapping` | 30166 | Registration No., VAT Registration No. |
